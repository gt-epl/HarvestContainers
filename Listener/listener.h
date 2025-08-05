#ifndef LISTENER_H
#define LISTENER_H

#include <pthread.h>
#include <dirent.h>

#define MAX_PODS 64
#define MAX_POD_ID_LEN 37

extern int listenerControl;

extern pthread_t conn_handler_thread;

void* handle_connection(void *arg);

extern struct idleStats *idleCpuStats;

#endif // LISTENER_H
