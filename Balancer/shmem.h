#define SHMEM_SIZE 4096 * 32
#define MAX_CONTAINERS 64

struct ctr_info {
  int parent_pid;
  int nr_pids;
  int pidList[128];
};

struct primary_ctr_info {
  int NUMCPUS;
  int cpuList[64];
  float LOWIDLEFREQ_THRESHOLD;
  int LOW_TIC;

  int targetIdleCores;
  int static_targetIdleCores;
  int totalEligibleCores;
  int maxSecondaryCores;
  int minSecondaryCores;
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

    pid_t secondary_pid_list[128];
    int nr_secondary_ctrs;
    int needs_rebalance;

    int affinity_list[64];
    int num_affinity;
    int num_secondary_cores;
    int secondary_cores_list[64];
    struct ctr_info secondary_ctrs[64];
    struct primary_ctr_info primary_ctrs[64];
    int nr_primary_ctrs;
};