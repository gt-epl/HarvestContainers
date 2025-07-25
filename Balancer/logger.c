#include <time.h>
#include <stdio.h>
#include <stdint.h>
#include <locale.h>
#include <errno.h>
#include <string.h>

#include "logger.h"
#include "balancer.h"

void getHumanIdleMask(unsigned long long mask, char *human_readable_mask)
{
    /* Write human-friendly 1's and 0's 
     * This function does NOT return the full potential mask
     * with 64 1's and 0's by default; instead, it generates a
     * string with chars for up to the max CPU as we're monitoring
     * so that output is easier to read
     */
        int i;
        for (i = 0; i <= cpuList[NUMCPUS-1]; i++) {
            if ((mask & (1ULL << (i)))) {
                human_readable_mask[i] = 1 + '0';
            } else human_readable_mask[i] = 0 + '0';
        }
        human_readable_mask[i] = '\0';
}

void addLogEvent(struct timespec *eventStart, struct timespec *eventEnd,
        int coreDifference, int setAffinity, unsigned long long currIdleMask,
        int idleCoresCount, unsigned long long setAffinityMask,
        int CoresAllocatedToSecondary)
{
    if (!loggingEnabled || eventCount > MAX_EVENTS) return;

    events[eventCount].startSec = eventStart->tv_sec;
    events[eventCount].startNSec = eventStart->tv_nsec;
    events[eventCount].endSec = eventEnd->tv_sec;
    events[eventCount].endNSec = eventEnd->tv_nsec;
    events[eventCount].coreDifference = coreDifference;
    events[eventCount].setAffinity = setAffinity;
    events[eventCount].currIdleMask = currIdleMask;
    events[eventCount].idleCoresCount = idleCoresCount;
    events[eventCount].setAffinityMask = setAffinityMask;
    events[eventCount].CoresAllocatedToSecondary = CoresAllocatedToSecondary;

    eventCount++;
}

void logDynamicEvent(struct timespec *eventTime, 
        unsigned long long sample_time_elapsed,
        int idleCoresCount, int prev_targetIdleCores,
        int targetIdleCores, unsigned long long time_spent_surplus,
        unsigned long long time_spent_deficit, float surplus_weight,
        float deficit_weight, int num_samples_taken)
{
    if (!loggingEnabled || dynamicEventCount > MAX_EVENTS) return;

    dynamicEvents[dynamicEventCount].startSec = eventTime->tv_sec;
    dynamicEvents[dynamicEventCount].startNSec = eventTime->tv_nsec;
    dynamicEvents[dynamicEventCount].sample_time_elapsed = sample_time_elapsed;
    dynamicEvents[dynamicEventCount].idleCoresCount = idleCoresCount;
    dynamicEvents[dynamicEventCount].prev_targetIdleCores = prev_targetIdleCores;
    dynamicEvents[dynamicEventCount].targetIdleCores = targetIdleCores;
    dynamicEvents[dynamicEventCount].time_spent_surplus = time_spent_surplus;
    dynamicEvents[dynamicEventCount].time_spent_deficit = time_spent_deficit;
    dynamicEvents[dynamicEventCount].surplus_weight = surplus_weight;
    dynamicEvents[dynamicEventCount].deficit_weight = deficit_weight;
    dynamicEvents[dynamicEventCount].num_samples_taken = num_samples_taken;

    dynamicEventCount++;
}

void calculateExecTime()
{
    /* To calculate execution time of each core, we take
     * the delta between when the idle mask last changed and
     * the current event. We attribute this time to
     * either active time or idle time of a core, based on its
     * status when the first event occurred (the oldMask)
     */
    int e, c;
    uint64_t elapsed = 0;
    uint64_t totalExecTime = 0;
    
    struct execTimes utilization[64] = {0,0,0};

    /* String goes from 0 to the largest CPU in the list,
     * so allocate 1 (for zero) + largestCPU (for all the bits
     * we care about seeing) + 1 (for terminating the string) */
    char humanOldMask[1 + cpuList[NUMCPUS - 1] + 1];
    char humanNewMask[1 + cpuList[NUMCPUS - 1] + 1];

    FILE *idleMaskEvents = fopen("idleMaskChanges.log", "w");
    
    for (e = 0; e < idleMaskChangeCount-1; e++) {
        getHumanIdleMask(idleMaskChanges[e].oldMask, humanOldMask);
        getHumanIdleMask(idleMaskChanges[e].newMask, humanNewMask);
        fprintf(idleMaskEvents, "%lu,%lu,%s,%#llx,%s,%#llx\n", idleMaskChanges[e].ts_sec, idleMaskChanges[e].ts_nsec,
            humanOldMask, idleMaskChanges[e].oldMask, humanNewMask, idleMaskChanges[e].newMask);
        elapsed = (1000 * 1000 * 1000) * 
            (idleMaskChanges[e+1].ts_sec - idleMaskChanges[e].ts_sec) + 
            (idleMaskChanges[e+1].ts_nsec - idleMaskChanges[e].ts_nsec);
        totalExecTime += elapsed;
        for (c = 0; c < NUMCPUS; c++) {
            if ((idleMaskChanges[e+1].oldMask & (1ULL << (cpuList[c])))) {
                utilization[cpuList[c]].active += elapsed; 
            } else {
                utilization[cpuList[c]].idle += elapsed;
            }
        }
    }
    fclose(idleMaskEvents);

    FILE *idleMaskChangeTimes = fopen("util.log", "w");
    printf("\n");
    printf(" Time Spent Executing (idle/active)    \n");
    printf(" ----------------------------------    \n");
    for(c = 0; c < NUMCPUS; c++) {
        printf(" cpu%d, %.2f%%, %.2f%%\n", cpuList[c], 
            (((utilization[cpuList[c]].idle) / (totalExecTime * 1.0)) * 100.0),
            (((utilization[cpuList[c]].active) / (totalExecTime * 1.0)) * 100.0));

        fprintf(idleMaskChangeTimes, "cpu%d, %lu, %lu\n", cpuList[c],
            utilization[cpuList[c]].idle, utilization[cpuList[c]].active);
    }
    printf(" Total Exec Time: %'lu\n", totalExecTime);
    fclose(idleMaskChangeTimes);
}

void writeLog(void)
{
    char humanIdleMask[1 + cpuList[NUMCPUS - 1] + 1];
    char humanAffinityMask[1 + cpuList[NUMCPUS - 1] + 1];
    int e;
    unsigned int tooManyIdleCount;
    unsigned int tooFewIdleCount;
    unsigned int setAffinityCount;
    uint64_t elapsed;
    uint64_t maxServiceTime;
    uint64_t minServiceTime;
    uint64_t avgServiceTime;
    uint64_t tooManyIdleTime;
    uint64_t tooFewIdleTime;
    uint64_t totalProcessingTime;
    tooManyIdleCount = 0;
    tooFewIdleCount = 0;
    setAffinityCount = 0;
    elapsed = 0;
    maxServiceTime = 0;
    minServiceTime = 0;
    avgServiceTime = 0;
    tooManyIdleTime = 0;
    tooFewIdleTime = 0;
    totalProcessingTime = 0;

    /* Generate log file name */
    time_t now = time(NULL);
    struct tm tm_now;
    localtime_r(&now, &tm_now);
    char currTime[100];
    strftime(currTime, sizeof(currTime), "%Y-%m-%d-%H.%M", &tm_now);
    char logFilename[100];
    FILE *logfile = fopen("balancer.log", "w");
    if (logfile == NULL) {
        printf("[!] Unable to open balancer.log file for writing: %s\n", strerror(errno));
        return;
    } 

    /* Write log file header */
    fprintf(logfile, "%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
        "endSec","endNSec","startSec","startNSec","serviceTime","coreDifference",
        "idleMask","idleCoresCount,setAffinityMask",
        "CoresAllocatedToSecondary\n");

    /* Write events to log file */
    for (e = 0; e < eventCount; e++) {
        elapsed = (1000 * 1000 * 1000) * 
            (events[e].endSec - events[e].startSec) + 
            (events[e].endNSec - events[e].startNSec); 
        totalProcessingTime += elapsed;
        if (elapsed > maxServiceTime) maxServiceTime = elapsed;
        if (elapsed < minServiceTime) minServiceTime = elapsed;

        if (events[e].coreDifference < 0) {
            tooFewIdleTime += elapsed;
            tooFewIdleCount++;
        } else if (events[e].coreDifference > 0) {
            tooManyIdleTime += elapsed;
            tooManyIdleCount++;
        }
        if (events[e].setAffinity) setAffinityCount++;
        /* Convert to human-readable mask format for the log */
        getHumanIdleMask(events[e].currIdleMask, humanIdleMask);
        getHumanIdleMask(events[e].setAffinityMask, humanAffinityMask);
        
        fprintf(logfile, "%lu,%lu,%lu,%lu,%lu,%d,%s,%d,%s,%d\n", 
            events[e].endSec, events[e].endNSec,
            events[e].startSec, events[e].startNSec,
            elapsed, events[e].coreDifference, 
            humanIdleMask, events[e].idleCoresCount, humanAffinityMask,
            events[e].CoresAllocatedToSecondary);
    }
    avgServiceTime = totalProcessingTime / eventCount;

    setlocale(LC_NUMERIC, "");
    printf("\n");
    printf("+------------------------+\n");
    printf("|       Statistics       |\n");
    printf("+------------------------+\n");
    printf("                          \n");
    printf(" Event Counters           \n");
    printf(" --------------           \n");
    printf("    tooFewIdle: %'u     \n", tooFewIdleCount);
    printf("   tooManyIdle: %'u     \n", tooManyIdleCount);
    printf("     Rebalance: %'u\n", eventCount);
    printf("    Iterations: %'u\n", iterationsCount);
    printf("   setaffinity: %'u\n", setAffinityCount);
    printf("\n");
    printf(" Time Spent Servicing     \n");
    printf(" --------------------     \n");
    printf("  minServiceTime: %'lu ns\n", minServiceTime);
    printf("  maxServiceTime: %'lu ns\n", maxServiceTime);
    printf("  avgServiceTime: %'lu ns\n", avgServiceTime);
    printf("     tooManyIdle: %'lu ns\n", tooManyIdleTime);
    printf("     tooFewIdles: %'lu ns\n", tooFewIdleTime);
    printf("           Total: %'lu ns\n", totalProcessingTime);

    calculateExecTime();

    FILE *statsfile = fopen("stats.log", "w");
    fprintf(statsfile, "%s,%u\n", "tooFewIdleCount", tooFewIdleCount);
    fprintf(statsfile, "%s,%u\n", "tooManyIdleCount", tooManyIdleCount);
    fprintf(statsfile, "%s,%u\n", "rebalance", eventCount);
    fprintf(statsfile, "%s,%u\n", "iterations", iterationsCount);
    fprintf(statsfile, "%s,%lu\n", "minServiceTime", minServiceTime);
    fprintf(statsfile, "%s,%lu\n", "maxServiceTime", maxServiceTime);
    fprintf(statsfile, "%s,%lu\n", "avgServiceTime", avgServiceTime);
    fprintf(statsfile, "%s,%lu\n", "tooManyIdleTime", tooManyIdleTime);
    fprintf(statsfile, "%s,%lu\n", "tooFewIdleTime", tooFewIdleTime);
    fprintf(statsfile, "%s,%lu\n", "totalProcessingTime", totalProcessingTime);
    
    printf("\n[+] Wrote stats log to %s\n", "stats.log");
    fclose(logfile);
    fclose(statsfile);

    FILE *dyn_logfile = fopen("dynamic.log", "w");
    if (dyn_logfile == NULL) {
        printf("[!] Unable to open dynamic.log file for writing: %s\n", strerror(errno));
        return;
    }

   /* Write log file header */
    fprintf(dyn_logfile, "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
        "startSec","startNSec","sample_time_elapsed","idleCoresCount",
        "prev_targetIdleCores","targetIdleCores","time_spent_surplus",
        "time_spent_deficit", "surplus_weight", "deficit_weight",
        "num_samples_taken\n");

    /* Write events to log file */
    for (e = 0; e < dynamicEventCount; e++) {
        fprintf(dyn_logfile, "%lu,%lu,%llu,%d,%d,%d,%llu,%llu,%.2f,%.2f,%d\n", 
            dynamicEvents[e].startSec,
            dynamicEvents[e].startNSec,
            dynamicEvents[e].sample_time_elapsed,
            dynamicEvents[e].idleCoresCount,
            dynamicEvents[e].prev_targetIdleCores,
            dynamicEvents[e].targetIdleCores,
            dynamicEvents[e].time_spent_surplus,
            dynamicEvents[e].time_spent_deficit,
            dynamicEvents[e].surplus_weight,
            dynamicEvents[e].deficit_weight,
            dynamicEvents[e].num_samples_taken);
    }
    printf("\n[+] Wrote dynamic log to %s\n", "dynamic.log");
    fclose(dyn_logfile);
}
