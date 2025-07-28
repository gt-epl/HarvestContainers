#include <dirent.h>

char cpuList[64];

int listenerControl;

char podList[64][37];

pthread_t conn_handler_thread;

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

struct idleStats *idleCpuStats;
