#include <sched.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <limits.h>
#include "listener.h"
#include "getpids.h"

#define PATH_MAX 4096

#include "listener.h"
#include "getpids.h"

pid_t curr_secondary_pids[MAX_SECONDARY_PIDS] = {0};

/* Retrieve all PIDs for a specific container within a pod */

int get_container_tasks(char *pod_id, char *container_id)
{
    printf("[+] [Listener] Getting tasks for container %s\n", container_id);

    char container_path[PATH_MAX];
    char proc_path[PATH_MAX];
    char *proc_name = NULL;
    ssize_t bytes_read;
    size_t len = 0;
    char *tid = NULL;
    FILE *fp = NULL;
    FILE *proc_fp = NULL;

    snprintf(container_path, sizeof(container_path), "/sys/fs/cgroup/cpuset/kubepods/besteffort/%s/%s/tasks",
             pod_id, container_id);

    fp = fopen(container_path, "r");
    if (fp == NULL) {
        printf("[!] [Listener] Could not read tasks for container %s: %s\n", container_id, strerror(errno));
        return -1;
    }
    
    proc_name = malloc(1024 * sizeof(char));
    if (proc_name == NULL) {
        printf("[!] [Listener] Memory allocation failed\n");
        fclose(fp);
        return -1;
    }

    idleCpuStats->updatingPids = 1;

    while ((bytes_read = getline(&tid, &len, fp)) != -1) {
        if (bytes_read <= 0 || tid == NULL) {
            continue; // Skip empty lines
        }

        // Clean up trailing whitespace/newline
        size_t tid_len = strlen(tid);
        if (tid_len > 0 && tid[tid_len-1] == '\n') {
            tid[tid_len--] = '\0';
        }
        for (size_t i = tid_len-1; i > 0 && isspace((unsigned char)tid[i]); i--) {
            tid[i] = '\0';
        }

        snprintf(proc_path, sizeof(proc_path), "/proc/%s/cmdline", tid);
        proc_fp = fopen(proc_path, "r");
        if (proc_fp == NULL) {
            printf("[!] [Listener] Could not read /proc entry at %s: %s\n", proc_path, strerror(errno));
            continue;
        }

        ssize_t proc_bytes = fread(proc_name, sizeof(char), 1023, proc_fp);
        if (proc_bytes >= 0) {
            proc_name[proc_bytes] = '\0';

            if (strcmp(proc_name, "harvest_launcher") == 0) {
                int pid = atoi(tid); 
                printf("[*] [Listener] Adding PID: %d\n", pid);

                idleCpuStats->secondary_pid_list[idleCpuStats->nr_secondary_ctrs] = pid;
                idleCpuStats->secondary_ctrs[idleCpuStats->nr_secondary_ctrs].parent_pid = pid;
                idleCpuStats->secondary_ctrs[idleCpuStats->nr_secondary_ctrs].nr_pids = 0;
                idleCpuStats->nr_secondary_ctrs++;

                free(proc_name);
                if (tid) free(tid);
                fclose(fp);
                fclose(proc_fp);
                idleCpuStats->updatingPids = 0;

                printf("[+] [Listener] Done updating PIDs for container %s\n", container_id);
                return 1;
            }
        }

        fclose(proc_fp);
    }

    free(proc_name);
    if (tid) free(tid);
    fclose(fp);

    idleCpuStats->updatingPids = 0;

    printf("[!] [Listener] Container %s is not a harvest container. Skipping.\n", container_id);
    return -1;
}

/* Retrieve all containers inside a specific pod */
int get_containers(char *pod_id)
{
    printf("[+] [Listener] Finding containers for pod %s\n", pod_id);

    int total_containers = 0;
    DIR *pod_dir = NULL;
    struct dirent *d;
    char path[PATH_MAX];

    snprintf(path, sizeof(path), "/sys/fs/cgroup/cpuset/kubepods/besteffort/%s", pod_id);

    errno = 0;
    pod_dir = opendir(path);
    if (!pod_dir) {
        printf("[!] [Listener] Could not open directory %s: %s\n", path, strerror(errno));
        return -1;
    }

    while ((d = readdir(pod_dir)) != NULL) {
        // Skip special directories
        if (d->d_type != DT_DIR ||
            strcmp(d->d_name, ".") == 0 ||
            strcmp(d->d_name, "..") == 0) {
            continue;
        }

        printf("[+] [Listener] Found container @ %s\n", d->d_name);

        // Process this container
        int result = get_container_tasks(pod_id, d->d_name);
        if (result < 0) {
            closedir(pod_dir);
            return -1;
        }

        total_containers++;
    }

    closedir(pod_dir);

    printf("[+] [Listener] get_containers() done, found %d total containers\n", total_containers);
    return total_containers;
}
