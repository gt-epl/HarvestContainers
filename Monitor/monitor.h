#ifndef MONITOR_H
#define MONITOR_H
int NUMCPUS;
int NUM_INTERRUPTS;
int NUM_INTERRUPT_CPUS;

/* Level of Verbosity for logging:
 * 0 = No Logging
 * 1 = Log only when idle mask changes
 * 2 = Verbose logging: record every sample */
int LOG_LEVEL;
int numentries;
int entrypos;
struct logentry {
    unsigned long sec;
    unsigned long nsec;
    unsigned long long mask;
};
struct logentry *events;
#define LOGSIZE ((1000 * 1000 * 1000) / 100) * 60

int __init logger_proc_init(void);
void __exit logger_proc_cleanup(void);

/* Indicates whether /proc/idlecpu/control has been set to 1 or 0 */
int runnable;
int numIdleCpus;
int curr_cpu;
int is_idle;
int idleCount;
int samples;
int irq_samples;
unsigned long long currMask;
unsigned long long lastMask;
/* Set to 1 when doing rebalance; otherwise 0 */
int rebalancing;
/* Set to 1 to share harvest cores w/ IRQs */
int handle_irq;

struct task_struct *check_idle_cpus_task;

int cpuList[64];
int irqAffinity[32];
int irqList[64];

struct harvest_core {
  int cpuid;
  unsigned long long curr_weight;
};

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

struct idleStats *idleCpuStats;

unsigned long long curr_irq_times[64];

int check_idle_cpus(void *data);

int set_irq_affinity(int irq);

#endif
