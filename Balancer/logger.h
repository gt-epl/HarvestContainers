#include <stdint.h>

#define MAX_EVENTS 1000 * 1000 * 100

int loggingEnabled;
unsigned int eventCount;
unsigned int iterationsCount;
unsigned int idleMaskChangeCount;

struct idleMaskChange {
    unsigned long ts_sec;
    unsigned long ts_nsec;
    unsigned long long oldMask;
    unsigned long long newMask;
};

struct timespec eventStart, eventEnd,
                affinityStart, affinityEnd,
                idleMaskChangeTS;

struct execTimes {
    uint64_t idle;
    uint64_t active;
    int id;
};

struct logentry {
    /* Start of event in sec and nanosec */
    unsigned long startSec;
    unsigned long startNSec;
    /* End of event in sec and nanosec */
    unsigned long endSec;
    unsigned long endNSec;
    /* idleCoresCount - targetIdleCores, i.e. how much
     * surplus or deficit of idle cores we have */
    int coreDifference;
    /* 1 if sched_setaffinity() was called, 0 otherwise */
    unsigned int setAffinity;
    /* IdleCPU mask at time of event */
    unsigned long long currIdleMask;
    /* Affinity mask that was generated for this rebalance event */
    unsigned long long setAffinityMask;
    /* How many idle cores triggered this rebalance event */
    int idleCoresCount;
    /* How many cores rebalance ultimately allocated to Secondary */
    int CoresAllocatedToSecondary;
};

struct logentry *events;
struct idleMaskChange *idleMaskChanges;

void addLogEvent(struct timespec *eventStart, struct timespec *eventEnd,
        int coreDifference, int setAffinity, unsigned long long currIdleMask,
        int idleCoresCount, unsigned long long setAffinityMask, 
        int CoresAllocatedToSecondary);

void writeLog(void);

struct dynamic_logentry {
    unsigned long startSec;
    unsigned long startNSec;
    unsigned long long sample_time_elapsed;
    int idleCoresCount;
    int prev_targetIdleCores;
    int targetIdleCores;
    unsigned long long time_spent_surplus;
    unsigned long long time_spent_deficit;
    float surplus_weight;
    float deficit_weight;
    int num_samples_taken;
};

void logDynamicEvent(struct timespec *eventTime, 
        unsigned long long sample_time_elapsed,
        int idleCoresCount, int prev_targetIdleCores,
        int targetIdleCores, unsigned long long time_spent_surplus,
        unsigned long long time_spent_deficit, float surplus_weight,
        float deficit_weight, int num_samples_taken);

struct dynamic_logentry *dynamicEvents;
unsigned int dynamicEventCount;
