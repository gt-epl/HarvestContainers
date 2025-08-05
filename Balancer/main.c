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

#include "shmem.h"
#include "taskinfo.h"
#include "balancer.h"
#include "logger.h"
#include "interrupts.h"

#define VERSION "two_phase_affinity"

#define LOGGING
#define DEVICE_FILENAME "/dev/qidlecpu"

int lastIdleCount;
unsigned long long lastIdleMask;

unsigned long long getTimeElapsed(struct timespec *prev_time)
{
    struct timespec curr_time;
    unsigned long long elapsed;
    clock_gettime(CLOCK_MONOTONIC_RAW, &curr_time);
    elapsed = (1000 * 1000 * 1000) * 
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

int within_error(struct primary_ctr_info *ci, balancer_info *bi) {
    if (bi->within_error_flag) {
        return 1;
    }

    bi->within_error_flag = bi->deficit_rate > 0.66 * ci->LOWIDLEFREQ_THRESHOLD;
    return bi->within_error_flag;
}

int doHarvest(struct primary_ctr_info *ci, balancer_info *bi) {

    /* If we have surplus idle cores but we've already allocated
        * everything possible to Secondary, skip rebalance */
    if (bi->coreDifference > 0 && bi->CoresAllocatedToSecondary == ci->maxSecondaryCores) 
        return 0;

    /* If we have a deficit of idle cores but we've already limited
        * Secondary to its minimum, skip rebalance */
    if (bi->coreDifference < 0 && bi->CoresAllocatedToSecondary == ci->minSecondaryCores)
        return 0;

    bi->SpareCoresToAllocate = bi->CoresAllocatedToSecondary + bi->coreDifference;

    if (bi->SpareCoresToAllocate <= 0) 
        bi->SpareCoresToAllocate = 0;
    if (bi->SpareCoresToAllocate > ci->maxSecondaryCores) 
        bi->SpareCoresToAllocate = ci->maxSecondaryCores;

    #ifdef BALANCE_INTERRUPTS
    /* If time between last sample and this sample > IRQ_SAMPLE_RATE */
    if (getTimeElapsed(&irq_sample_time) > IRQ_SAMPLE_RATE) {
        /* Timestamp the new sample */
        clock_gettime(CLOCK_MONOTONIC_RAW, &irq_sample_time);
        
        /* Get interrupt weights from Monitor and sort cores based on
         * recent and history interrupt handing time. If cores
         * are reordered, need to rebalance Secondary */
        needs_rebalance = getInterruptWeights();

        if(needs_rebalance) {
            interruptRebalanceCount++;
        } 
    }
    #endif

    coreDifference += bi->coreDifference;
    idleCoresCount += bi->idleCoresCount;

    bi->currentState = ADJUST;

    /* There's a surplus or deficit of cores, so
     * rebalance is needed; return 1 */
    if (bi->coreDifference != 0) {
        return 1;
    }
    /* No rebalance needed; return 0 */
    return 0;
}

void doObserve(struct primary_ctr_info *ci, balancer_info *bi) {
    if (bi->ramp_ctr < RAMPUP1) {
        bi->ramp_ctr++;
        return;
    }

    if (bi->ramp_ctr < RAMPUP1 + RAMPUP2) {
        if (bi->deficits == 0) {
            bi->deficits = bi->lowIdleFreq;
            bi->deficit_rate = bi->deficits / bi->sample_time_elapsed;
            //bi->deficit_rate = bi->deficits / 1000000000;
            bi->ACBF_high = (bi->deficit_rate > bi->ACBF_high) ? bi->deficit_rate : bi->ACBF_high;
            bi->ACBF_low = (bi->deficit_rate < bi->ACBF_low) ? bi->deficit_rate : bi->ACBF_low;
        } else {
            bi->deficits = 0.5 * bi->deficits + 0.5 * bi->lowIdleFreq;
            bi->deficit_rate = bi->deficits / bi->sample_time_elapsed;
            //bi->deficit_rate = bi->deficits / 1000000000;
            bi->ACBF_high = (bi->deficit_rate > bi->ACBF_high) ? bi->deficit_rate : bi->ACBF_high;
            bi->ACBF_low = (bi->deficit_rate < bi->ACBF_low) ? bi->deficit_rate : bi->ACBF_low;
        }
        bi->ramp_ctr++;
    } else {
        bi->ramp_ctr = 0;
        bi->currentState = ADJUST;
    }

    return;
}

int doAdjust(struct primary_ctr_info *ci, balancer_info *bi) {
    
    bi->deficits = ALPHA * bi->deficits + (1 - ALPHA) * bi->lowIdleFreq;

    bi->deficit_rate = bi->deficits / bi->sample_time_elapsed;
    //bi->deficit_rate = bi->deficits / 1000000000;

    if (bi->deficit_rate > ci->LOWIDLEFREQ_THRESHOLD) {
        bi->prev_targetIdleCores = ci->targetIdleCores;
        ci->targetIdleCores += 1;
        if (ci->targetIdleCores > ci->static_targetIdleCores)
            ci->targetIdleCores = ci->static_targetIdleCores;
    } else {
        if (within_error(ci, bi)) {
            if (bi->surplus_evts < SURPLUS_EVTS_THRESH)  {
                bi->surplus_evts += 1;
            } else {
                bi->prev_targetIdleCores = ci->targetIdleCores;
                ci->targetIdleCores -= 1;
                if (ci->targetIdleCores < LOW_TIC) 
                    ci->targetIdleCores = LOW_TIC;
                bi->surplus_evts = 0;
                bi->within_error_flag = 0;
            }
        } else {
            bi->prev_targetIdleCores = ci->targetIdleCores;
            ci->targetIdleCores -= 1;
            if (ci->targetIdleCores < LOW_TIC) 
                ci->targetIdleCores = LOW_TIC;
            bi->surplus_evts = 0;
        }
    }
    
    logDynamicEvent(&bi->prev_sample_timestamp, bi->sample_time_elapsed, 
        bi->idleCoresCount, bi->prev_targetIdleCores, ci->targetIdleCores, 
        bi->time_spent_surplus, bi->time_spent_deficit, bi->surplus_weight,
        bi->deficit_weight, bi->deficits, bi->deficit_rate, bi->lowIdleFreq);

    /* We updated targetIdleCores, so recalculate coreDifference */
    bi->coreDifference = bi->idleCoresCount - ci->targetIdleCores;
    ci->maxSecondaryCores = ci->totalEligibleCores - ci->targetIdleCores;

    bi->currentState = HARVEST;
}

int evaluatePrimaryContainer(struct primary_ctr_info *ci, balancer_info *bi) {
    int result = 0;
    bi->prev_idleCoresCount = bi->idleCoresCount;
        bi->idleCoresCount = 0;
        for (int i = 0; i < ci->NUMCPUS; i++) {
            if (!CoreIsActive(ci->cpuList[i], currIdleMask) ) {
                bi->idleCoresCount++;
            }
        }

    bi->coreDifference = bi->idleCoresCount - ci->targetIdleCores;

    bi->this_sample_time = getTimeElapsed(&bi->prev_sample_timestamp);
    clock_gettime(CLOCK_MONOTONIC_RAW, &bi->prev_sample_timestamp);

    bi->sample_time_elapsed += bi->this_sample_time;

    if (bi->prev_idleCoresCount == 0 || bi->prev_targetIdleCores == 1) {
        bi->lowIdleFreq += bi->this_sample_time; 
    }

    if (bi->sample_time_elapsed >= IDLEACTIVE_SAMPLE_RATE) {

        if (bi->currentState == OBSERVE) {
            doObserve(ci, bi);
        }

        doAdjust(ci, bi);

        bi->lowIdleFreq = 0;
        bi->sample_time_elapsed = 0;
    }


    result = doHarvest(ci, bi);
        
    return result;
}

int evaluateContainers() {
    int needs_rebalance = 0;
    for (int i = 0; i < idleCpuStats->nr_primary_ctrs; i++) {
        needs_rebalance += evaluatePrimaryContainer(&idleCpuStats->primary_ctrs[i], &balancer_ctr_stats[i]);
    }
    return needs_rebalance;
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

    clock_gettime(CLOCK_MONOTONIC_RAW, &prev_sample_timestamp);

    for (int i = 0; i < MAX_CONTAINERS; i++) {
        clock_gettime(CLOCK_MONOTONIC_RAW, &balancer_ctr_stats[i].prev_sample_timestamp);
    }

    /* Begin main sample/balance loop */
    while (1) {
        /* Balancer is paused. Do nothing. */
        if (idleCpuStats->balancerControl == 0) continue;
        /* Balancer exit triggered. Return + clean up. */
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

        needs_rebalance = evaluateContainers();

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

int initializeBalancerInfo()
{
    /* Allocate memory for tracking up to MAX_CONTAINERS */
    balancer_ctr_stats = (balancer_info*)malloc(MAX_CONTAINERS * sizeof(balancer_info));

    if (balancer_ctr_stats == NULL) {
        perror("Failed to allocate memory for balancer_ctr_stats");
        return 1;
    }

    /* Initialize all stats */
    for (int i = 0; i < MAX_CONTAINERS; i++) {
        balancer_ctr_stats[i].CoresAllocatedToSecondary = 0;
        balancer_ctr_stats[i].prev_idleCoresCount = 0;
        balancer_ctr_stats[i].idleCoresCount = 0;
        balancer_ctr_stats[i].prev_targetIdleCores = 0;
        balancer_ctr_stats[i].coreDifference = 0;
        balancer_ctr_stats[i].this_sample_time = 0;
        balancer_ctr_stats[i].total_sample_time = 0;
        balancer_ctr_stats[i].surplus_sample_time = 0;
        balancer_ctr_stats[i].deficit_sample_time = 0;
        balancer_ctr_stats[i].deficit_aggIdleCoresCount = 0;
        balancer_ctr_stats[i].surplus_aggIdleCoresCount = 0;
        balancer_ctr_stats[i].aggIdleCoresCount = 0;
        balancer_ctr_stats[i].num_surplus_observed = 0;
        balancer_ctr_stats[i].num_deficit_observed = 0;
        balancer_ctr_stats[i].time_spent_surplus = 0;
        balancer_ctr_stats[i].time_spent_deficit = 0;
        balancer_ctr_stats[i].num_samples_taken = 0;
        balancer_ctr_stats[i].deficit_weight = 0.0;
        balancer_ctr_stats[i].surplus_weight = 0.0;
        balancer_ctr_stats[i].lowIdleFreq = 0;
        balancer_ctr_stats[i].SAMPLE_TYPE = 0;
        balancer_ctr_stats[i].SpareCoresToAllocate = 0;
        balancer_ctr_stats[i].ACBF_high = 0.0;
        balancer_ctr_stats[i].ACBF_low = 0.0;
        balancer_ctr_stats[i].ACBF_current = 0.0;
        balancer_ctr_stats[i].deficits = 0;
        balancer_ctr_stats[i].deficit_rate = 0;
        balancer_ctr_stats[i].surplus_evts = SURPLUS_EVTS_THRESH + 1;
        balancer_ctr_stats[i].within_error_flag = 0;
        balancer_ctr_stats[i].ACBF_high = INT_MIN * 1.0;
        balancer_ctr_stats[i].ACBF_low = INT_MAX * 1.0;
        balancer_ctr_stats[i].currentState = OBSERVE;
        balancer_ctr_stats[i].ramp_ctr = 0;
        balancer_ctr_stats[i].sample_time_elapsed = 0;
    }

    return 0;
}

void checkCtrInfo() {
    /* Print test data */
    printf("\nnr_primary_ctrs is %d\n\n", idleCpuStats->nr_primary_ctrs);

    for (int i = 0; i < idleCpuStats->nr_primary_ctrs; i++) {
        printf("--- Container c%d ---\n", idleCpuStats->nr_primary_ctrs);
        printf("NUMCPUS: %d\n", idleCpuStats->primary_ctrs[i].NUMCPUS);
            for (int c = 0; c < idleCpuStats->primary_ctrs[i].NUMCPUS; c++) {
                printf("  cpu%d: %d\n", c, idleCpuStats->primary_ctrs[i].cpuList[c]);
            }
        printf("LOW_TIC = %d\n", idleCpuStats->primary_ctrs[i].LOW_TIC);
        printf("ACBF = %f\n", idleCpuStats->primary_ctrs[i].LOWIDLEFREQ_THRESHOLD);
        printf("targetIdleCores = %d\n", idleCpuStats->primary_ctrs[i].targetIdleCores);
        printf("static_targetIdleCores = %d\n", idleCpuStats->primary_ctrs[i].static_targetIdleCores);
        printf("totalEligibleCores = %d\n", idleCpuStats->primary_ctrs[i].totalEligibleCores);
        printf("maxSecondaryCores = %d\n", idleCpuStats->primary_ctrs[i].maxSecondaryCores);
        printf("minSecondaryCores = %d\n", idleCpuStats->primary_ctrs[i].minSecondaryCores);
        printf("\n\n");
    }
}

int main(int argc, char **argv)
{
    if (argc < 5) {
        printf("Usage: ./balancer <secondary_pid> <targetIdleCores> <minSecondaryCores> <cpuList> <secondaryCpuList>\n");
        exit(0);
    }

    parseCpuList(argv[4]);

    initializeBalancerInfo();

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

    SURPLUS_BUFFER_SAMPLE_RATE = sbsr_env != NULL ? atoi(sbsr_env) * 1000ULL : 1000 * 1000ULL;

    DEFICIT_BUFFER_SAMPLE_RATE = lbsr_env != NULL ? atoi(lbsr_env) * 1000ULL : 1000 * 1000 * 1000ULL;
    LOWIDLEFREQ_THRESHOLD = lift_env != NULL ? atof(lift_env) : 0.035;
    LOW_TIC = lt_env != NULL ? atoi(lt_env) : 2;

    printf("[Balancer] DEFICIT_THRESHOLD: %.2f\n", DEFICIT_THRESHOLD);
    printf("[Balancer] SURPLUS_THRESHOLD: %.2f\n", SURPLUS_THRESHOLD);
    printf("[Balancer] SURPLUS_BUFFER_SAMPLE_RATE: %llu\n", SURPLUS_BUFFER_SAMPLE_RATE);
    printf("[Balancer] DEFICIT_BUFFER_SAMPLE_RATE: %llu\n", DEFICIT_BUFFER_SAMPLE_RATE);
    printf("[Balancer] LOWIDLEFREQ_THRESHOLD: %f\n", LOWIDLEFREQ_THRESHOLD);

    IDLEACTIVE_SAMPLE_RATE = 1000*1000*1000ULL;
    time_spent_deficit = 0;
    time_spent_surplus = 0;
    surplus_sample_time = 0;
    deficit_sample_time = 0;
    total_sample_time = 0;
    
    /* Open shared memory device so we can share status
     * info w/ kernel module */
    shm_fd = open(DEVICE_FILENAME, O_RDWR | O_NDELAY);
    if (shm_fd >= 0) {
        idle_shm = (struct idleStats*)mmap(0, SHMEM_SIZE, PROT_WRITE, MAP_SHARED, shm_fd, 0);
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
    idleMaskChanges = malloc(sizeof(struct idleMaskChange) * MAX_EVENTS);
    if (!idleMaskChanges) {
        printf("[!] Unable to allocate memory for idleMaskChanges log\n");
        loggingEnabled = 0;
    } 
    dynamicEvents = malloc(sizeof(struct dynamic_logentry) * MAX_EVENTS);
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

    secondary_pid = atoi(argv[1]);
    printf("[+] [Balancer] Monitoring %d cores\n", NUMCPUS);
    printf("[+] [Balancer] targetIdleCores=%d, dedicatedSecondaryCores=%d\n",
        targetIdleCores, idleCpuStats->num_secondary_cores);
    
    printf("[+] [Balancer] Create and zero out Secondary mask.\n");
    CPU_ZERO(&secondary_mask);

    printf("[+] [Balancer] Starting polling loop...\n");
    
    checkCtrInfo();
    pollIdleCPU();
    
    cleanup();
    return 0;
}
