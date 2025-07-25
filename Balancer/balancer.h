#include <sched.h>

/* BEGIN DYNAMIC EXPERIMENT VARS */
int static_targetIdleCores;
int prev_targetIdleCores;
int prev_idleCoresCount;
unsigned long long deficit_aggIdleCoresCount;
unsigned long long surplus_aggIdleCoresCount;
float aggIdleCoresCount;
float lowIdleFreq;
/* How long we've spent doing things */
unsigned long long surplus_sample_time;
unsigned long long deficit_sample_time;
unsigned long long this_sample_time;
unsigned long long time_spent_surplus;
unsigned long long time_spent_deficit;
int total_sample_time;
/* How much time to sample before making a targetIdleCores decision */
static unsigned long long SURPLUS_BUFFER_SAMPLE_RATE = 1000 * 1000 * 1000ULL; // 1 sec
static unsigned long long DEFICIT_BUFFER_SAMPLE_RATE = 1000 * 1000ULL; // 1 msec
unsigned long long IDLEACTIVE_SAMPLE_RATE;
float SURPLUS_THRESHOLD;
float DEFICIT_THRESHOLD;
float LOWIDLEFREQ_THRESHOLD;
int LOW_TIC;
/* We need to track how many times we saw a surplus and a deficit during our sample interval */
int num_surplus_observed;
int num_deficit_observed;
/* We need to track how many samples we took during the sample interval */
int num_samples_taken;
float surplus_weight;
float deficit_weight;

struct timespec prev_sample_timestamp;
int DYNAMIC_ENABLED;
/* SAMPLE_TYPE=1 for surplus sampling, 0 for deficit */
int SAMPLE_TYPE;
static unsigned long long RAMP_UP_PERIOD = 2000 * 1000 * 1000ULL; // 2 sec
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
  /* Things to get from config */
  int NUMCPUS;
  int cpuList[64];
  float LOWIDLEFREQ_THRESHOLD;
  int LOW_TIC;
  /* *** */

  int prev_idleCoresCount;
  int idleCoresCount;
  int prev_targetIdleCores;
  int targetIdleCores;
  int static_targetIdleCores;

  int coreDifference;
  unsigned long long this_sample_time;
  unsigned long long total_sample_time;
  unsigned long long surplus_sample_time;
  unsigned long long deficit_sample_time;

  unsigned long long deficit_aggIdleCoresCount;
  unsigned long long surplus_aggIdleCoresCount;

  float aggIdleCoresCount;

  int num_surplus_observed;
  int num_deficit_observed;

  unsigned long long time_spent_surplus;
  unsigned long long time_spent_deficit;

  struct timespec prev_sample_timestamp;
  struct timespec irq_sample_time;

  int num_samples_taken;

  float deficit_weight;
  float surplus_weight;

  float lowIdleFreq;

  int SAMPLE_TYPE;

  int maxSecondaryCores;
  int minSecondaryCores;
  int totalEligibleCores;

  int CoresAllocatedToSecondary;

  int SpareCoresToAllocate;
};

struct ctr_info *c1;
struct ctr_info *c2;
struct ctr_info *c3;

/* Keeps track of how many cores we've added to affinity_list while calling
 * ComputeAffinityMask() for each Primary container */
int affinityListPos;

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

int shm_fd;
struct idleStats *idle_shm;
struct idleStats *idleCpuStats;

int CoreIsActive(int core_id, unsigned long long mask);

int ComputeCoreDifference(void);

int AllocateCoresToSecondary();

void UpdateCoreTracking(int newSecondaryCores, int oldSecondaryCores);

unsigned long long getIdleMask(void);

void printHarvestCores();
