#include <sched.h>

pid_t curr_secondary_pids[128];

int parsePodList(char *podListString);
int get_containers(char *pod_id);
int copy_secondary_pids();
int compare_pid_lists();
int updatePodList(char *pod_id);
int check_for_pids();