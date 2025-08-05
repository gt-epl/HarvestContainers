#include <sched.h>

#define SURPLUS_EVTS_THRESH 10
#define ALPHA 0.85
static unsigned RAMPUP1 = 5;
static unsigned RAMPUP2 = 5;

typedef enum {
  OBSERVE,
  ADJUST,
  HARVEST
} balancerState;

int static_targetIdleCores;
int prev_targetIdleCores;
int prev_idleCoresCount;
unsigned long long deficit_aggIdleCoresCount;
unsigned long long surplus_aggIdleCoresCount;
float aggIdleCoresCount;
float lowIdleFreq;

unsigned long long surplus_sample_time;
unsigned long long deficit_sample_time;
unsigned long long this_sample_time;
unsigned long long time_spent_surplus;
unsigned long long time_spent_deficit;
int total_sample_time;

static unsigned long long SURPLUS_BUFFER_SAMPLE_RATE = 1000 * 1000 * 1000ULL; // 1 sec
static unsigned long long DEFICIT_BUFFER_SAMPLE_RATE = 1000 * 1000ULL; // 1 msec
unsigned long long IDLEACTIVE_SAMPLE_RATE;
float SURPLUS_THRESHOLD;
float DEFICIT_THRESHOLD;
float LOWIDLEFREQ_THRESHOLD;
int LOW_TIC;

int num_surplus_observed;
int num_deficit_observed;

int num_samples_taken;
float surplus_weight;
float deficit_weight;

struct timespec prev_sample_timestamp;
int DYNAMIC_ENABLED;
/* SAMPLE_TYPE=1 for surplus sampling, 0 for deficit */
int SAMPLE_TYPE;
static unsigned long long RAMP_UP_PERIOD = 2000 * 1000 * 1000ULL; // 2 sec

int NUMCPUS;

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

typedef struct {
  int prev_idleCoresCount;
  int idleCoresCount;
  int prev_targetIdleCores;

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
  int CoresAllocatedToSecondary;
  int SpareCoresToAllocate;

  float ACBF_high;
  float ACBF_low;
  float ACBF_current;

  double deficits;
  double deficit_rate;
  long long sample_time_elapsed;
  int ramp_ctr;
  int surplus_evts;
  int within_error_flag;
  balancerState currentState;

} balancer_info;

balancer_info *balancer_ctr_stats;

int affinityListPos;

int shm_fd;
struct idleStats *idle_shm;
struct idleStats *idleCpuStats;

int CoreIsActive(int core_id, unsigned long long mask);

int ComputeCoreDifference(void);

int AllocateCoresToSecondary();

void UpdateCoreTracking(int newSecondaryCores, int oldSecondaryCores);

unsigned long long getIdleMask(void);

void printHarvestCores();
