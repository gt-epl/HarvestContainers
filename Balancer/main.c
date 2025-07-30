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

//#define ADDITIVE_INCREASE
//#define MULTIPLICATIVE_DECREASE
//#define VERBOSE
#define BALANCE_INTERRUPTS
#define ALPHA 0.85  //trust in old dr
#define SURPLUS_EVTS_THRESH 10


int lastIdleCount;
unsigned long long lastIdleMask;
double deficits;
int surplus_evts = SURPLUS_EVTS_THRESH+1;
int within_error_flag = 0;

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

int within_error(double deficit_rate) {
    if(within_error_flag) {
        return 1;
    }

    within_error_flag = deficit_rate > 0.66*LOWIDLEFREQ_THRESHOLD;
    return within_error_flag;
}

void pollIdleCPU(void)
{

    if(idleCpuStats->balancerControl == 0)
        printf("[!] [Balancer] Paused. (balancerControl == 0)\n");
    while(idleCpuStats->balancerControl == 0) {
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
    double deficit_rate = 0;
    
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
    AllocateCoresToSecondary(secondary_pid, totalEligibleCores, 
        CoresAllocatedToSecondary);
    printf("[+] [Balancer] Starting main polling loop.\n");
    clock_gettime(CLOCK_MONOTONIC_RAW, &prev_sample_timestamp); //DYNAMIC VAR
    /* Begin main sample/balance loop */
    while(1) {
        // Balancer is paused. Do nothing.
        if(idleCpuStats->balancerControl == 0) continue;
        // Balancer exit triggered. Return + clean up.
        if(idleCpuStats->balancerControl == -1) return;

        iterationsCount++;
        
        currIdleMask = idleCpuStats->mask;

        /* Log changes to Idle CPUs mask; otherwise, skip rebalance and 
         * continue loop from top since nothing changed */
        if(currIdleMask != lastIdleMask) {
            clock_gettime(CLOCK_MONOTONIC_RAW, &idleMaskChangeTS);
            idleMaskChanges[idleMaskChangeCount].ts_sec = idleMaskChangeTS.tv_sec;
            idleMaskChanges[idleMaskChangeCount].ts_nsec = idleMaskChangeTS.tv_nsec;
            idleMaskChanges[idleMaskChangeCount].oldMask = lastIdleMask;
            idleMaskChanges[idleMaskChangeCount].newMask = currIdleMask;
            lastIdleMask = currIdleMask;
            idleMaskChangeCount++;
        } else continue;

        prevIdleCoresCount = idleCoresCount;
        idleCoresCount = 0;
        for(int i = 0; i < NUMCPUS; i++) {
            if( !CoreIsActive(cpuList[i], currIdleMask) ) {
                idleCoresCount++;
            }
        }

        coreDifference = idleCoresCount - targetIdleCores;

        /* BEGIN DYNAMIC EXPERIMENT */
        this_sample_time = getTimeElapsed(&prev_sample_timestamp);
        clock_gettime(CLOCK_MONOTONIC_RAW, &prev_sample_timestamp);

        sample_time_elapsed += this_sample_time;

        if (prevIdleCoresCount==0 || prev_targetIdleCores==1 ) {
        lowIdleFreq+=this_sample_time; 
        }

        if(sample_time_elapsed >= IDLEACTIVE_SAMPLE_RATE) {
            if(ramp_ctr < RAMPUP1) {
                ramp_ctr++;
            } else {
                if (ramp_ctr < RAMPUP1 + RAMPUP2) {
                    if(deficits==0) {
                        deficits = lowIdleFreq;
                    } else {
                        deficits = 0.5*deficits + 0.5*lowIdleFreq;
                    }
                    ramp_ctr++;
                } else {
                    deficits = ALPHA*deficits + (1-ALPHA)*lowIdleFreq;
                    deficit_rate = deficits/sample_time_elapsed;
                    if(DYNAMIC_ENABLED) {
                        if(deficit_rate > LOWIDLEFREQ_THRESHOLD) {
                            prev_targetIdleCores = targetIdleCores;
                            targetIdleCores += 1;
                            if(targetIdleCores > static_targetIdleCores) targetIdleCores = static_targetIdleCores;
                        }
                        else {
                            if(within_error(deficit_rate)) {
                                if(surplus_evts < SURPLUS_EVTS_THRESH)  {
                                    //need confidence.
                                    surplus_evts += 1;
                                }
                                else {
                                    prev_targetIdleCores = targetIdleCores;
                                    targetIdleCores -= 1;
                                    if(targetIdleCores < LOW_TIC) targetIdleCores = LOW_TIC; //min is 2
                                    surplus_evts = 0;
                                    within_error_flag = 0;
                                }
                            }
                            else {
                                prev_targetIdleCores = targetIdleCores;
                                targetIdleCores -= 1;
                                if(targetIdleCores < LOW_TIC) targetIdleCores = LOW_TIC; //min is 2
                                surplus_evts = 0;
                            }
                        }
                    }
                    logDynamicEvent(&prev_sample_timestamp, sample_time_elapsed, 
                        idleCoresCount, prev_targetIdleCores, targetIdleCores, 
                        time_spent_surplus, time_spent_deficit, surplus_weight,
                        deficit_weight, deficits, deficit_rate, lowIdleFreq);
                    /* We updated targetIdleCores, so recalculate coreDifference */
                    coreDifference = idleCoresCount - targetIdleCores;
                    maxSecondaryCores = totalEligibleCores-targetIdleCores;

                }
            }
            // Reset counters
            lowIdleFreq = 0;
            sample_time_elapsed = 0;
        }
        /* END DYNAMIC EXPERIMENT   */

        /* If we have surplus idle cores but we've already allocated
         * everything possible to Secondary, skip rebalance */
        if (coreDifference > 0 && CoresAllocatedToSecondary == maxSecondaryCores) continue;

        /* If we have a deficit of idle cores but we've already limited
         * Secondary to its minimum, skip rebalance */
        if (coreDifference < 0 && CoresAllocatedToSecondary == minSecondaryCores) continue;

        #ifdef ADDITIVE_INCREASE
        /* Grow in small steps regardless of the surplus */
        if(coreDifference > 0) {
            coreDifference = 1;
        } 
        #endif

        #ifdef MULTIPLICATIVE_DECREASE
        /* Begin Experimental */
        /* If we're at a deficit, multiplicatively increase it
         * so that Secondary shrinks in bigger leaps */
        if(coreDifference < 0) {
            coreDifference *= 20; // Evict all Secondary threads when any deficit happen
        }
        /* End Experimental */
        #endif

        SpareCoresToAllocate = CoresAllocatedToSecondary + coreDifference;

        if (SpareCoresToAllocate <= 0) SpareCoresToAllocate = 0;
        if (SpareCoresToAllocate > maxSecondaryCores) SpareCoresToAllocate = maxSecondaryCores;

        #ifdef BALANCE_INTERRUPTS
        /* If time between last sample and this sample > IRQ_SAMPLE_RATE */
        if(getTimeElapsed(&irq_sample_time) > IRQ_SAMPLE_RATE) {
            /* Timestamp the new sample */
            clock_gettime(CLOCK_MONOTONIC_RAW, &irq_sample_time);
            
            /* Get interrupt weights from Monitor and sort cores based on
             * recent and history interrupt handing time. If cores
             * are reordered, need to rebalance Secondary */
            needs_rebalance = getInterruptWeights();

            /* Begin Experimental */
            if(needs_rebalance) {
                interruptRebalanceCount++;
                // printHarvestCores();
            } 
            /* End Experimental */
        }
        #endif

        /* Otherwise we have a deficit or surplus of cores and must rebalance */
        if (coreDifference != 0 || needs_rebalance) {
            needs_rebalance = 0;
            clock_gettime(CLOCK_MONOTONIC_RAW, &eventStart);
            setAffinityStatus = AllocateCoresToSecondary(secondary_pid, 
                                totalEligibleCores, SpareCoresToAllocate);
            UpdateCoreTracking(SpareCoresToAllocate, CoresAllocatedToSecondary);
            if(SpareCoresToAllocate == 0) CoresAllocatedToSecondary = minSecondaryCores;
            else CoresAllocatedToSecondary = currSecondaryCoreCount;
            clock_gettime(CLOCK_MONOTONIC_RAW, &eventEnd);
            addLogEvent(&eventStart, &eventEnd, coreDifference, 
                    setAffinityStatus, currIdleMask, idleCoresCount, setAffinityMask,
                    CoresAllocatedToSecondary);
        }
        lastAffinityMask = setAffinityMask;
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
    while( (token = strsep(&cpuListString, ",")) != NULL ) {
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
    while( (token = strsep(&cpuListString, ",")) != NULL ) {
      sscanf(token, "%d", &curr_cpuid);
      idleCpuStats->secondary_cores_list[curr_cpu] = curr_cpuid;
      curr_cpu++;
      printf("  -> Added cpu%d to Dedicated Secondary list (count: %d)\n", curr_cpuid, curr_cpu);
    }
    idleCpuStats->num_secondary_cores = curr_cpu;
    return 0;
}

int main(int argc, char **argv)
{
    if(argc < 5) {
        printf("Usage: ./balancer <secondary_pid> <targetIdleCores> <minSecondaryCores> <cpuList> <secondaryCpuList>\n");
        exit(0);
    }

    parseCpuList(argv[4]);

     /* Initialize harvest_cores */
    for(int i = 0; i < NUMCPUS; i++) {
        harvestCores[i] = cpuList[i];
    }

    setAffinityMask = 0;
    lastIdleCount = -1;
    allowSuspendSecondary = 0;
    totalEligibleCores = NUMCPUS;
    static_targetIdleCores = atoi(argv[2]);
    targetIdleCores = static_targetIdleCores;
    currSecondaryCoreCount = 0;
    /* CoresAllocatedToSecondary should start 
     * with value of maxSecondaryCores */
    maxSecondaryCores = totalEligibleCores-targetIdleCores;
    minSecondaryCores = atoi(argv[3]);
    //CoresAllocatedToSecondary = maxSecondaryCores;
    CoresAllocatedToSecondary = minSecondaryCores;

    /* BEGIN DYNAMIC EXPERIMENT VARS */
    DYNAMIC_ENABLED = 1;
    sample_time_elapsed = 0;
    num_surplus_observed = 0;
    num_deficit_observed = 0;
    num_samples_taken = 0;
    prev_targetIdleCores = 0;
    const char *dwt_env = getenv("DEFICIT_THRESHOLD");
    const char *swt_env = getenv("SURPLUS_THRESHOLD");
    const char *sbsr_env = getenv("POSTSURPLUS_BUFFER_SAMPLE_RATE");
    const char *lbsr_env = getenv("POSTDEFICIT_BUFFER_SAMPLE_RATE");
    const char *lift_env = getenv("LOWIDLEFREQ_THRESHOLD");
    const char *lt_env   = getenv("LOW_TIC");

    DEFICIT_THRESHOLD = dwt_env!=NULL ? atof(dwt_env) : 0.10;
    SURPLUS_THRESHOLD = swt_env!=NULL ? atof(swt_env) : 0.90;
    /* Default short buffer of 1 msec */
    POSTSURPLUS_BUFFER_SAMPLE_RATE = sbsr_env!=NULL ? atoi(sbsr_env)*1000ULL : 1000*1000ULL;
    /* Default long buffer of 1 sec */
    POSTDEFICIT_BUFFER_SAMPLE_RATE = lbsr_env!=NULL ? atoi(lbsr_env)*1000ULL : 1000*1000*1000ULL;

    /* based on memcached profiling */
    LOWIDLEFREQ_THRESHOLD = lift_env!=NULL ? atof(lift_env) : 0.035;
    LOW_TIC = lt_env!=NULL ? atoi(lt_env) : 2;


    printf("[Balancer] DEFICIT_THRESHOLD: %.2f\n", DEFICIT_THRESHOLD);
    printf("[Balancer] SURPLUS_THRESHOLD: %.2f\n", SURPLUS_THRESHOLD);
    printf("[Balancer] POSTSURPLUS_BUFFER_SAMPLE_RATE: %llu\n", POSTSURPLUS_BUFFER_SAMPLE_RATE);
    printf("[Balancer] POSTDEFICIT_BUFFER_SAMPLE_RATE: %llu\n", POSTDEFICIT_BUFFER_SAMPLE_RATE);
    printf("[Balancer] LOWIDLEFREQ_THRESHOLD: %f\n", LOWIDLEFREQ_THRESHOLD);

    IDLEACTIVE_SAMPLE_RATE = POSTDEFICIT_BUFFER_SAMPLE_RATE;
    time_spent_deficit = 0;
    time_spent_surplus = 0;
    /* END DYNAMIC EXPERIMENT VARS   */
    
    /* Open our shared memory device so we can share status
     * info w/ IdleCPU kernel module */
    shm_fd = open(DEVICE_FILENAME, O_RDWR|O_NDELAY);
    if(shm_fd >= 0) {
        idle_shm = (struct idleStats*)mmap(0, 4096, PROT_WRITE, MAP_SHARED, shm_fd, 0);
    }
    else {
        printf("[!] Unable to open QIDLECPU shared memory\n");
        exit(-1);
    }

    idleCpuStats = &idle_shm[0];

    parseSecondaryCpuList(argv[5]);

    events = malloc(sizeof(struct logentry)*MAX_EVENTS);
    if(!events) {
        printf("[!] Unable to allocate memory for event log\n");
        loggingEnabled = 0;
    } else {
        #ifdef LOGGING
        loggingEnabled = 1;
        eventCount = 0;
        #endif
    }
    idleMaskChanges = malloc(sizeof(struct idleMaskChange)*MAX_EVENTS);
    if(!idleMaskChanges) {
        printf("[!] Unable to allocate memory for idleMaskChanges log\n");
        loggingEnabled = 0;
    } 
    dynamicEvents = malloc(sizeof(struct dynamic_logentry)*MAX_EVENTS);
    if(!dynamicEvents) {
        printf("[!] Unable to allocate memory for dynamicEvents log\n");
        loggingEnabled = 0;
    }
    else dynamicEventCount = 0;
    
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
    
    printf("[+] [Balancer] Create and zero out Secondary mask.\n");
    CPU_ZERO(&secondary_mask);

    printf("[+] [Balancer] Starting polling loop...\n");
    pollIdleCPU();
    cleanup();
    return 0;
}
