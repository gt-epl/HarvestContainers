#define _GNU_SOURCE
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>
#include <stdint.h>
#include <stdlib.h>
#include <sched.h>
#include <limits.h>
#include <signal.h>
#include <string.h>

#include "taskinfo.h"
#include "balancer.h"
#include "logger.h"
#include "interrupts.h"

#define VERSION "two_phase_affinity"

#define LOGGING
#define DEVICE_FILENAME "/dev/qidlecpu"

#define DEFICIT_SURPLUS_METHOD
#define DYNAMIC_ENABLED
//#define ADDITIVE_INCREASE
//#define MULTIPLICATIVE_DECREASE
//#define VERBOSE
//#define BALANCE_INTERRUPTS // TODO: Update getInterruptWeights() logic before re-enabling

int lastIdleCount;
unsigned long long lastIdleMask;

unsigned long long getTimeElapsed(struct timespec *prev_time)
{
    struct timespec curr_time;
    unsigned long long elapsed;
    clock_gettime(CLOCK_MONOTONIC_RAW, &curr_time);
    elapsed = (1000*1000*1000) * 
    (curr_time.tv_sec - prev_time->tv_sec) + 
    (curr_time.tv_nsec - prev_time->tv_nsec);
    return elapsed;
}

void trigger_cleanup(int signum)
{
    if (signum == SIGUSR1) {
        printf("[!] Caught signal. Cleaning up.\n");
        idleCpuStats->balancerControl = -1;
    }
}

int evaluatePrimaryContainer(struct ctr_info *c) 
{
    c->prev_idleCoresCount = c->idleCoresCount;
    c->idleCoresCount = 0;
    for (int i = 0; i < c->NUMCPUS; i++) {
        if (!CoreIsActive(c->cpuList[i], currIdleMask)) {
            c->idleCoresCount++;
        }
    }

    c->coreDifference = c->idleCoresCount - c->targetIdleCores;

#ifdef DYNAMIC_ENABLED
    /* BEGIN DYNAMIC EXPERIMENT */
    c->this_sample_time = getTimeElapsed(&c->prev_sample_timestamp);
    c->total_sample_time += c->this_sample_time;
    c->surplus_sample_time += c->this_sample_time;
    c->deficit_sample_time += c->this_sample_time;
    /* These vars have confusing names. To clarify: they are not tracking
     * the number of surplus/deficit cores but rather gathering aggregate
     * idle core samples to determine surplus/deficit later. */
    c->deficit_aggIdleCoresCount += c->prev_idleCoresCount * c->this_sample_time;
    c->surplus_aggIdleCoresCount += c->prev_idleCoresCount * c->this_sample_time;

    if (c->prev_idleCoresCount <= 1) {
        c->lowIdleFreq += c->this_sample_time;
    }

    if (c->idleCoresCount >= c->targetIdleCores) { //Surplus
        c->num_surplus_observed += 1;
        c->time_spent_surplus += c->this_sample_time;
    }
    if (c->idleCoresCount < c->targetIdleCores) {
        c->num_deficit_observed += 1;
        c->time_spent_deficit += c->this_sample_time;
    }
    c->num_samples_taken += 1;

    /* If we saw enough deficits during the last sample period AND we were 
     * looking for deficits, then increase buffer cores */
    if (c->deficit_sample_time >= DEFICIT_BUFFER_SAMPLE_RATE) {
        c->deficit_weight = c->time_spent_deficit / (c->deficit_sample_time * 1.0);
        if (c->lowIdleFreq / (c->deficit_sample_time * 1.0) >= c->LOWIDLEFREQ_THRESHOLD ) {
            c->prev_targetIdleCores = c->targetIdleCores;
            c->targetIdleCores += 1;
            if (c->targetIdleCores >= c->totalEligibleCores) c->targetIdleCores = c->totalEligibleCores - 1;
            if (c->targetIdleCores > c->static_targetIdleCores) c->targetIdleCores = c->static_targetIdleCores;
            if (c->targetIdleCores < c->LOW_TIC) c->targetIdleCores = c->LOW_TIC;
            if (c->targetIdleCores != c->prev_targetIdleCores) {
                logDynamicEvent(&c->prev_sample_timestamp, c->deficit_sample_time, 
                    c->idleCoresCount, c->prev_targetIdleCores, c->targetIdleCores, 
                    0, c->time_spent_deficit, 0,
                    c->lowIdleFreq / (c->deficit_sample_time * 1.0), 100);
            }
            c->SAMPLE_TYPE = 1; // Next sample cycle we look for surplus events
        }
        else c->SAMPLE_TYPE = 0;
        c->deficit_sample_time = 0;
        c->deficit_aggIdleCoresCount = 0;
        c->time_spent_deficit = 0;
        c->lowIdleFreq = 0;
    }
    if (c->surplus_sample_time >= SURPLUS_BUFFER_SAMPLE_RATE) {
        c->surplus_weight = c->time_spent_surplus / (c->surplus_sample_time * 1.0);
        c->aggIdleCoresCount = c->surplus_aggIdleCoresCount / (c->surplus_sample_time * 1.0);
        
        /* aggIdle / threshold method */
        if ((c->aggIdleCoresCount >= (c->targetIdleCores * 1.0)) && (c->SAMPLE_TYPE == 0)) {
            c->prev_targetIdleCores = c->targetIdleCores;
            c->targetIdleCores -= 1;
            if (c->targetIdleCores < 1) c->targetIdleCores = 1;
            if (c->targetIdleCores != c->prev_targetIdleCores) {
                logDynamicEvent(&c->prev_sample_timestamp, c->surplus_sample_time, 
                    c->idleCoresCount, c->prev_targetIdleCores, c->targetIdleCores, 
                    c->time_spent_surplus, 0, c->surplus_weight,
                    c->aggIdleCoresCount, 200);
                //printf("   -> [Balancer] DECREASING BUFFER (targetIdleCores=%d; surplus=%.2f (%llu/%llu))\n", targetIdleCores, surplus_weight, time_spent_surplus, sample_time_elapsed);
                //printf("   -> [Balancer] DECREASING BUFFER (prev_targetIdleCores=%d; targetIdleCores=%d; surplus=%.2f (%llu/%llu)\n", prev_targetIdleCores, targetIdleCores, aggIdleCoresCount, surplus_aggIdleCoresCount, surplus_sample_time);
            }
        }
        c->surplus_sample_time = 0;
        c->surplus_aggIdleCoresCount = 0;
        c->aggIdleCoresCount = 0;
        c->time_spent_surplus = 0;
    }
    /* We updated targetIdleCores, so recalculate coreDifference */
    c->coreDifference = c->idleCoresCount - c->targetIdleCores;
    c->maxSecondaryCores = c->totalEligibleCores - c->targetIdleCores;

    clock_gettime(CLOCK_MONOTONIC_RAW, &c->prev_sample_timestamp);

    /* END DYNAMIC EXPERIMENT   */
#endif
    /* If we have surplus idle cores but we've already allocated
     * everything possible to Secondary, skip rebalance */
    if (c->coreDifference > 0 && c->CoresAllocatedToSecondary == c->maxSecondaryCores) return 0;

    /* If we have a deficit of idle cores but we've already limited
     * Secondary to its minimum, skip rebalance */
    if (c->coreDifference < 0 && c->CoresAllocatedToSecondary == c->minSecondaryCores) return 0;

    #ifdef ADDITIVE_INCREASE
    /* Grow in small steps regardless of the surplus */
    if (c->coreDifference > 0) {
        c->coreDifference = 1;
    } 
    #endif

    #ifdef MULTIPLICATIVE_DECREASE
    /* Begin Experimental */
    /* If we're at a deficit, multiplicatively increase it
     * so that Secondary shrinks in bigger leaps */
    if (c->coreDifference < 0) {
        c->coreDifference *= 20; // Evict all Secondary threads when any deficit happens
    }
    /* End Experimental */
    #endif

    c->SpareCoresToAllocate = c->CoresAllocatedToSecondary + c->coreDifference;

    if (c->SpareCoresToAllocate <= 0) c->SpareCoresToAllocate = 0;
    if (c->SpareCoresToAllocate > c->maxSecondaryCores) c->SpareCoresToAllocate = c->maxSecondaryCores;

    #ifdef BALANCE_INTERRUPTS
    /* If time between last sample and this sample > IRQ_SAMPLE_RATE */
    if (getTimeElapsed(&c->irq_sample_time) > IRQ_SAMPLE_RATE) {
        /* Timestamp the new sample */
        clock_gettime(CLOCK_MONOTONIC_RAW, &c->irq_sample_time);
        
        /* Get interrupt weights from Monitor and sort cores based on
         * recent and history interrupt handing time. If cores
         * are reordered, need to rebalance Secondary */
        int needs_rebalance = getInterruptWeights();
        /* TODO: This part needs to be updated to rebalance the
         * current Primary container's cpuList based on IRQ weights */

        /* Begin Experimental */
        if (needs_rebalance) {
            interruptRebalanceCount++;
            // printHarvestCores();
        } 
        /* End Experimental */
    }
    #endif
    coreDifference += c->coreDifference;
    idleCoresCount += c->idleCoresCount;
    if (c->coreDifference != 0) return 1;
    return 0;
}

void pollIdleCPU(void)
{
    if (idleCpuStats->balancerControl == 0) {
        printf("[!] [Balancer] Paused. (balancerControl == 0)\n");
    }
    while (idleCpuStats->balancerControl == 0) {
        continue;
    }
    printf("[!] [Balancer] Active. (balancerControl == 1)\n");

    /* Tracks whether a rebalance was triggered.
     * This happens if SpareCorestoAllocate > 0 */
    int setAffinityStatus;
    /* Tracks the idle mask we recorded last sample */
    lastIdleMask = 0;
    lastAffinityMask = 0;
    /* Tracks how many times we've seen idle mask change */
    idleMaskChangeCount = 0;
    int needs_rebalance = 0;
    
    #ifdef BALANCE_INTERRUPTS
    /* Perform initial reordering of harvest cores based on interrupt
     * handling activity */
    printf("[+] [Balancer] Performing initial IRQ reorder\n");
    clock_gettime(CLOCK_MONOTONIC_RAW, &irq_sample_time);
    getInterruptWeights();
    #endif

    /* Perform initial rebalance event to allocate a starting set
     * of cores to the Secondary */
    printf("[+] [Balancer] Performing initial rebalance.\n");
    AllocateCoresToSecondary();

    printf("[+] [Balancer] Starting main polling loop.\n");

    clock_gettime(CLOCK_MONOTONIC_RAW, &prev_sample_timestamp); //DYNAMIC VAR

    /* TODO: Need to initialize timestamps in ALL Primary containers. For now
     * we have hardcoded container c1-c3, so we'll just init those */
    clock_gettime(CLOCK_MONOTONIC_RAW, &c1->prev_sample_timestamp);
    clock_gettime(CLOCK_MONOTONIC_RAW, &c2->prev_sample_timestamp);
    clock_gettime(CLOCK_MONOTONIC_RAW, &c3->prev_sample_timestamp);

    /* Begin main sample/balance loop */
    while (1) {
        // Balancer is paused. Do nothing.
        if (idleCpuStats->balancerControl == 0) continue;
        // Balancer exit triggered. Return + clean up.
        if (idleCpuStats->balancerControl == -1) return;

        iterationsCount++;
        
        currIdleMask = idleCpuStats->mask;

        /* Log changes to Idle CPUs mask; otherwise, skip rebalance and 
         * continue loop from top since nothing changed */
        if (currIdleMask != lastIdleMask) {
            clock_gettime(CLOCK_MONOTONIC_RAW, &idleMaskChangeTS);
            idleMaskChanges[idleMaskChangeCount].ts_sec = idleMaskChangeTS.tv_sec;
            idleMaskChanges[idleMaskChangeCount].ts_nsec = idleMaskChangeTS.tv_nsec;
            idleMaskChanges[idleMaskChangeCount].oldMask = lastIdleMask;
            idleMaskChanges[idleMaskChangeCount].newMask = currIdleMask;
            lastIdleMask = currIdleMask;
            idleMaskChangeCount++;
        } else continue;

        needs_rebalance += evaluatePrimaryContainer(c1);
        needs_rebalance += evaluatePrimaryContainer(c2);
        needs_rebalance += evaluatePrimaryContainer(c3);

        /* Evaluate this for each Primary container. We need to set the affinity
         * mask from each Primary's pool of cores, but not apply that mask until
         * every Primary has been evaluated here.
         * Otherwise we have a deficit or surplus of cores and must rebalance. */
        if (coreDifference != 0 || needs_rebalance) {
            needs_rebalance = 0;
            clock_gettime(CLOCK_MONOTONIC_RAW, &eventStart);
            setAffinityStatus = AllocateCoresToSecondary();
            clock_gettime(CLOCK_MONOTONIC_RAW, &eventEnd);
            addLogEvent(&eventStart, &eventEnd, coreDifference, 
                    setAffinityStatus, currIdleMask, idleCoresCount, setAffinityMask,
                    currSecondaryCoreCount);
        }
        lastAffinityMask = setAffinityMask;
        coreDifference = 0;
        idleCoresCount = 0;
    }
}

void cleanup(void)
{
    writeLog();
    free(events);
    free(idleMaskChanges);
    free(dynamicEvents);
    munmap(idle_shm, 4096);
    close(shm_fd);
    return;
}

unsigned long long getIdleMask(void)
{
    unsigned long long mask = idleCpuStats->mask;
    return mask;
}

int parseCpuList(char *cpuListString) 
{
    char *token;
    int curr_cpu = 0;
    while ((token = strsep(&cpuListString, ",")) != NULL) {
      sscanf(token, "%d", &cpuList[curr_cpu]);
      curr_cpu++;
    }
    NUMCPUS = curr_cpu;
    return 0;
}

int parseSecondaryCpuList(char *cpuListString) 
{
    printf("\n[+] [Balancer] Parsing SECONDARY DEDICATED CPULIST\n");
    char *token;
    int curr_cpu = 0;
    int curr_cpuid;
    while ((token = strsep(&cpuListString, ",")) != NULL) {
      sscanf(token, "%d", &curr_cpuid);
      idleCpuStats->secondary_cores_list[curr_cpu] = curr_cpuid;
      curr_cpu++;
      printf("  -> Added cpu%d to Dedicated Secondary list (count: %d)\n", curr_cpuid, curr_cpu);
    }
    idleCpuStats->num_secondary_cores = curr_cpu;
    return 0;
}

int initializeCtrInfo()
{
    c1->NUMCPUS = 8;
    c1->cpuList[0] = 2;
    c1->cpuList[1] = 4;
    c1->cpuList[2] = 6;
    c1->cpuList[3] = 8;
    c1->cpuList[4] = 10;
    c1->cpuList[5] = 12;
    c1->cpuList[6] = 14;
    c1->cpuList[7] = 16;
    c1->LOWIDLEFREQ_THRESHOLD = 0.0365;
    c1->LOW_TIC = 2;
    c1->targetIdleCores = 4;
    c1->static_targetIdleCores = 4;

    c1->totalEligibleCores = c1->NUMCPUS;
    c1->maxSecondaryCores = c1->totalEligibleCores - c1->targetIdleCores;
    c1->minSecondaryCores = 0;

    c1->CoresAllocatedToSecondary = 0;

    c1->prev_idleCoresCount = 0;
    c1->idleCoresCount = 0;
    c1->prev_targetIdleCores = 0;
    c1->coreDifference = 0;
    c1->this_sample_time = 0;
    c1->total_sample_time = 0;
    c1->surplus_sample_time = 0;
    c1->deficit_sample_time = 0;
    c1->deficit_aggIdleCoresCount = 0;
    c1->surplus_aggIdleCoresCount = 0;
    c1->aggIdleCoresCount = 0;
    c1->num_surplus_observed = 0;
    c1->num_deficit_observed = 0;
    c1->time_spent_surplus = 0;
    c1->time_spent_deficit = 0;
    c1->num_samples_taken = 0;
    c1->deficit_weight = 0.0;
    c1->surplus_weight = 0.0;
    c1->lowIdleFreq = 0;
    c1->SAMPLE_TYPE = 0;
    c1->SpareCoresToAllocate = 0;

    c2->NUMCPUS = 8;
    c2->cpuList[0] = 1;
    c2->cpuList[1] = 3;
    c2->cpuList[2] = 5;
    c2->cpuList[3] = 7;
    c2->cpuList[4] = 9;
    c2->cpuList[5] = 11;
    c2->cpuList[6] = 13;
    c2->cpuList[7] = 15;
    //c2->LOWIDLEFREQ_THRESHOLD = 0.008712; //50k, tic=4
    c2->LOWIDLEFREQ_THRESHOLD = 0.003; //100k, tic=7
    c2->LOW_TIC = 2;
    c2->targetIdleCores = 7;
    c2->static_targetIdleCores = 4;

    c2->totalEligibleCores = c2->NUMCPUS;
    c2->maxSecondaryCores = c2->totalEligibleCores - c2->targetIdleCores;
    c2->minSecondaryCores = 0;

    c2->CoresAllocatedToSecondary = 0;

    c2->prev_idleCoresCount = 0;
    c2->idleCoresCount = 0;
    c2->prev_targetIdleCores = 0;
    c2->coreDifference = 0;
    c2->this_sample_time = 0;
    c2->total_sample_time = 0;
    c2->surplus_sample_time = 0;
    c2->deficit_sample_time = 0;
    c2->deficit_aggIdleCoresCount = 0;
    c2->surplus_aggIdleCoresCount = 0;
    c2->aggIdleCoresCount = 0;
    c2->num_surplus_observed = 0;
    c2->num_deficit_observed = 0;
    c2->time_spent_surplus = 0;
    c2->time_spent_deficit = 0;
    c2->num_samples_taken = 0;
    c2->deficit_weight = 0.0;
    c2->surplus_weight = 0.0;
    c2->lowIdleFreq = 0;
    c2->SAMPLE_TYPE = 0;
    c2->SpareCoresToAllocate = 0;

    c3->NUMCPUS = 8;
    c3->cpuList[0] = 0;
    c3->cpuList[1] = 18;
    c3->cpuList[2] = 20;
    c3->cpuList[3] = 22;
    c3->cpuList[4] = 24;
    c3->cpuList[5] = 26;
    c3->cpuList[6] = 28;
    c3->cpuList[7] = 30;
    c3->LOWIDLEFREQ_THRESHOLD = 0.33;
    c3->LOW_TIC = 2;
    c3->targetIdleCores = 3;
    c3->static_targetIdleCores = 3;

    c3->totalEligibleCores = c3->NUMCPUS;
    c3->maxSecondaryCores = c3->totalEligibleCores - c3->targetIdleCores;
    c3->minSecondaryCores = 0;

    c3->CoresAllocatedToSecondary = 0;

    c3->prev_idleCoresCount = 0;
    c3->idleCoresCount = 0;
    c3->prev_targetIdleCores = 0;
    c3->coreDifference = 0;
    c3->this_sample_time = 0;
    c3->total_sample_time = 0;
    c3->surplus_sample_time = 0;
    c3->deficit_sample_time = 0;
    c3->deficit_aggIdleCoresCount = 0;
    c3->surplus_aggIdleCoresCount = 0;
    c3->aggIdleCoresCount = 0;
    c3->num_surplus_observed = 0;
    c3->num_deficit_observed = 0;
    c3->time_spent_surplus = 0;
    c3->time_spent_deficit = 0;
    c3->num_samples_taken = 0;
    c3->deficit_weight = 0.0;
    c3->surplus_weight = 0.0;
    c3->lowIdleFreq = 0;
    c3->SAMPLE_TYPE = 0;
    c3->SpareCoresToAllocate = 0;

    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 5) {
        printf("Usage: ./balancer <secondary_pid> <targetIdleCores> <minSecondaryCores> <cpuList> <secondaryCpuList>\n");
        exit(0);
    }

    parseCpuList(argv[4]);

    /* Experimental: set up structs for Primary containers */
    c1 = malloc(sizeof(struct ctr_info));
    c2 = malloc(sizeof(struct ctr_info));
    c3 = malloc(sizeof(struct ctr_info));
    initializeCtrInfo();

     /* Initialize harvest_cores */
    for (int i = 0; i < NUMCPUS; i++) {
        harvestCores[i] = cpuList[i];
    }

    setAffinityMask = 0;
    lastIdleCount = -1;
    allowSuspendSecondary = 0;
    totalEligibleCores = NUMCPUS;
    static_targetIdleCores = atoi(argv[2]);
    targetIdleCores = static_targetIdleCores;
    currSecondaryCoreCount = 0;
    maxSecondaryCores = totalEligibleCores-targetIdleCores;
    minSecondaryCores = atoi(argv[3]);
    CoresAllocatedToSecondary = minSecondaryCores;

    /* BEGIN DYNAMIC EXPERIMENT VARS */
    aggIdleCoresCount = 0;
    surplus_aggIdleCoresCount = 0;
    deficit_aggIdleCoresCount = 0;
    prev_targetIdleCores = 0;
    num_surplus_observed = 0;
    num_deficit_observed = 0;
    num_samples_taken = 0;
    prev_targetIdleCores = 0;
    prev_idleCoresCount = 0;
    const char *dwt_env  = getenv("DEFICIT_THRESHOLD");
    const char *swt_env  = getenv("SURPLUS_THRESHOLD");
    const char *sbsr_env = getenv("SURPLUS_BUFFER_SAMPLE_RATE");
    const char *lbsr_env = getenv("DEFICIT_BUFFER_SAMPLE_RATE");
    const char *lift_env = getenv("LOWIDLEFREQ_THRESHOLD");
    const char *lt_env   = getenv("LOW_TIC");
    const char *dsc_env  = getenv("DEDICATED_SECONDARY_CORE");
    DEFICIT_THRESHOLD = dwt_env != NULL ? atof(dwt_env) : 0.10;
    SURPLUS_THRESHOLD = swt_env != NULL ? atof(swt_env) : 0.90;
    SAMPLE_TYPE = 0;
    /* Default short buffer of 1 msec */
    SURPLUS_BUFFER_SAMPLE_RATE = sbsr_env != NULL ? atoi(sbsr_env) * 1000ULL : 1000 * 1000ULL;
    /* Default long buffer of 1 sec */
    DEFICIT_BUFFER_SAMPLE_RATE = lbsr_env != NULL ? atoi(lbsr_env) * 1000ULL : 1000 * 1000 * 1000ULL;
    LOWIDLEFREQ_THRESHOLD = lift_env != NULL ? atof(lift_env) : 0.035;
    LOW_TIC = lt_env != NULL ? atoi(lt_env) : 2;

    printf("[Balancer] DEFICIT_THRESHOLD: %.2f\n", DEFICIT_THRESHOLD);
    printf("[Balancer] SURPLUS_THRESHOLD: %.2f\n", SURPLUS_THRESHOLD);
    printf("[Balancer] SURPLUS_BUFFER_SAMPLE_RATE: %llu\n", SURPLUS_BUFFER_SAMPLE_RATE);
    printf("[Balancer] DEFICIT_BUFFER_SAMPLE_RATE: %llu\n", DEFICIT_BUFFER_SAMPLE_RATE);
    printf("[Balancer] LOWIDLEFREQ_THRESHOLD: %f\n", LOWIDLEFREQ_THRESHOLD);
    time_spent_deficit = 0;
    time_spent_surplus = 0;
    surplus_sample_time = 0;
    deficit_sample_time = 0;
    total_sample_time = 0;
    /* END DYNAMIC EXPERIMENT VARS   */
    
    /* Open shared memory device so we can share status
     * info w/ kernel module */
    shm_fd = open(DEVICE_FILENAME, O_RDWR | O_NDELAY);
    if (shm_fd >= 0) {
        idle_shm = (struct idleStats*)mmap(0, 4096, PROT_WRITE, MAP_SHARED, shm_fd, 0);
    } else {
        printf("[!] Unable to open shared memory device\n");
        exit(-1);
    }

    idleCpuStats = &idle_shm[0];

    parseSecondaryCpuList(argv[5]);

    events = malloc(sizeof(struct logentry)*MAX_EVENTS);
    if (!events) {
        printf("[!] Unable to allocate memory for event log\n");
        loggingEnabled = 0;
    } else {
        #ifdef LOGGING
        loggingEnabled = 1;
        eventCount = 0;
        #endif
    }
    idleMaskChanges = malloc(sizeof(struct idleMaskChange)*MAX_EVENTS);
    if (!idleMaskChanges) {
        printf("[!] Unable to allocate memory for idleMaskChanges log\n");
        loggingEnabled = 0;
    } 
    dynamicEvents = malloc(sizeof(struct dynamic_logentry)*MAX_EVENTS);
    if (!dynamicEvents) {
        printf("[!] Unable to allocate memory for dynamicEvents log\n");
        loggingEnabled = 0;
    } else dynamicEventCount = 0;
    
    printf("\n+-------------------+\n");
    printf("+ Harvest Balancer  +\n");
    printf("+-------------------+\n");
    printf("+ [%s]\n\n", VERSION);

    /* Trigger cleanup/exit routine on signal */
    signal(SIGUSR1, trigger_cleanup);

    /* TODO
     * Dead code: We used to read initial secondary PID from cmdline;
     * now this is done via Listener; set this to -1 and remove later */
    secondary_pid = atoi(argv[1]);
    printf("[+] [Balancer] Monitoring %d cores\n", NUMCPUS);
    printf("[+] [Balancer] targetIdleCores=%d, dedicatedSecondaryCores=%d\n",
        targetIdleCores, idleCpuStats->num_secondary_cores);
    
    printf("   [!] [Balancer] Primary container c1 targetIdleCores=%d\n", c1->targetIdleCores);
    printf("   [!] [Balancer] Primary container c2 targetIdleCores=%d\n", c2->targetIdleCores);
    printf("   [!] [Balancer] Primary container c3 targetIdleCores=%d\n", c3->targetIdleCores);
    #ifndef DYNAMIC_ENABLED
    printf("   [!] [Balancer] Dynamic is OFF\n");
    #else
    printf("   [!] [Balancer] Dynamic is ON\n");
    #endif
    
    printf("[+] [Balancer] Create and zero out Secondary mask.\n");
    CPU_ZERO(&secondary_mask);

    printf("[+] [Balancer] Starting polling loop...\n");
    pollIdleCPU();
    cleanup();
    return 0;
}
