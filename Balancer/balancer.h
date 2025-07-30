#include <sched.h>

/* BEGIN DYNAMIC EXPERIMENT VARS */
int static_targetIdleCores;
int prev_targetIdleCores;
/* How long we've spent doing things */
unsigned long long sample_time_elapsed;
unsigned long long this_sample_time;
unsigned long long time_spent_surplus;
unsigned long long time_spent_deficit;
/* How much time to sample before making a targetIdleCores decision */
static unsigned long long POSTDEFICIT_BUFFER_SAMPLE_RATE = 1000*1000*1000ULL; // 1 sec
static unsigned long long POSTSURPLUS_BUFFER_SAMPLE_RATE = 1000*1000ULL; // 1 msec
unsigned long long IDLEACTIVE_SAMPLE_RATE;
float SURPLUS_THRESHOLD;
float DEFICIT_THRESHOLD;
float LOWIDLEFREQ_THRESHOLD;
static unsigned int REDUCE_ACTION_COUNT = 3;
int reduce_action;
int LOW_TIC;

float aggIdleCoresCount;
float lowIdleFreq;
int prevIdleCoresCount;
/* We need to track how many times we saw a surplus and a deficit during our sample interval */
int num_surplus_observed;
int num_deficit_observed;
/* We need to track how many samples we took during the sample interval */
int num_samples_taken;
float surplus_weight;
float deficit_weight;

struct timespec prev_sample_timestamp;
int DYNAMIC_ENABLED;
int ramp_ctr;
static unsigned RAMPUP1 = 5;
static unsigned RAMPUP2 = 5;
static unsigned long long RAMP_UP_PERIOD = 2000*1000*1000ULL; // 2 sec
/* END DYNAMIC EXPERIMENT VARS */

/* Total number of CPUs we'll be watching/balancing */
int NUMCPUS;
/* We want to leave CPU0 for OS, so start from CPU1 */
#define STARTCPU 1

int cpuList[64];
int secondaryCpuList[64];
int harvestCores[64];

int allowSuspendSecondary;
int totalEligibleCores;
int idleCoresCount;
int targetIdleCores;
int maxSecondaryCores;
int minSecondaryCores;
int CoresAllocatedToSecondary; 
int processSuspended;
int coreDifference;
int SpareCoresToAllocate;
int currSecondaryCoreCount;
int lastSecondaryCoreCount;
int rebalanceAction;
unsigned long long currIdleMask;
unsigned long long lastIdleMask;
unsigned long long setAffinityMask;
unsigned long long lastAffinityMask;

pid_t secondary_pid;
cpu_set_t secondary_mask;

struct ctr_info {
  int parent_pid;
  int nr_pids;
  int pidList[128];
};

struct idleStats {
    int numIdle;
    unsigned long long mask;
    unsigned long long prev_irq_times[64];
    unsigned long long curr_irq_times[64];
    unsigned long long hist_irq_times[64];
    int samples;
    int irq_samples;
    int update_irq;

    int balancerControl;
    int updatingPids;

    /* --- Begin Rebalance Vars --- */
    pid_t secondary_pid_list[128];
    int nr_secondary_ctrs;
    int needs_rebalance;
    /* Just a list of CPUs to set */
    int affinity_list[64];
    int num_affinity;
    int num_secondary_cores;
    int secondary_cores_list[64];
    struct ctr_info secondary_ctrs[64];
    /* --- End Rebalance Vars --- */
};

/*
struct idleStats {
    int numIdle;
    unsigned long long mask;
    unsigned long long prev_irq_times[64];
    unsigned long long curr_irq_times[64];
    unsigned long long hist_irq_times[64];
    int samples;
    int irq_samples;
    int update_irq;

    int balancerControl;
    int updatingPids;

    pid_t secondary_pid_list[128];
    int num_secondary;
    int needs_rebalance;
    int affinity_list[64];
    int num_affinity;
    int num_secondary_cores;
    int secondary_cores_list[64];
};
*/

int shm_fd;
struct idleStats *idle_shm;
struct idleStats *idleCpuStats;

int CoreIsActive(int core_id, unsigned long long mask);
int ComputeCoreDifference(void);
int AllocateCoresToSecondary(int pid, int totalEligibleCores, int SpareCoresToAllocate);
void UpdateCoreTracking(int newSecondaryCores, int oldSecondaryCores);
unsigned long long getIdleMask(void);
/* Begin Experimental */
void printHarvestCores();
/* End Experimental */
