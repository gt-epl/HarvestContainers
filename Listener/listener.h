#ifndef LISTENER_H
#define LISTENER_H

#include <pthread.h>
#include <dirent.h>

#define MAX_PODS 64
#define MAX_POD_ID_LEN 37

extern int listenerControl;

// extern char podList[MAX_PODS][MAX_POD_ID_LEN];

extern pthread_t conn_handler_thread;

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
    
    pid_t secondary_pid_list[128];
    int nr_secondary_ctrs;
    int needs_rebalance;

    int affinity_list[64];
    int num_affinity;
    int num_secondary_cores;
    int secondary_cores_list[64];
    struct ctr_info secondary_ctrs[64];
};

extern struct idleStats *idleCpuStats;

#endif // LISTENER_H
