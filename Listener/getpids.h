#ifndef GETPIDS_H
#define GETPIDS_H

#include <sched.h>
#include <stdlib.h>

#define MAX_SECONDARY_PIDS 128

extern pid_t curr_secondary_pids[MAX_SECONDARY_PIDS];

/* Get all containers inside given pod ID */
int get_containers(char *pod_id);

#endif // GETPIDS_H
