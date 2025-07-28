#include <sched.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <limits.h>

#include "listener.h"
#include "getpids.h"

int get_container_tasks(char *pod_id, char *container_id)
{
    printf("[+] [Listener] Getting tasks for container %s\n", container_id); //DEBUG
    int num_pids;
    char container_path[PATH_MAX];
    char proc_path[PATH_MAX];
    char *proc_name = (char*)calloc(1024, sizeof(char));
    ssize_t bytes_read;
    ssize_t proc_bytes;
    ssize_t len = 0;
    char *tid = NULL;
    FILE *fp;
    FILE *proc_fp;

    snprintf(container_path, sizeof(container_path), "/sys/fs/cgroup/cpuset/kubepods/besteffort/%s/%s/tasks", pod_id, container_id);
    fp = fopen(container_path, "r");
    if(fp == NULL) {
        printf("[!] [Listener] Could not read tasks for container %s. Skipping.\n", container_id);
        return -1;
    }
    idleCpuStats->updatingPids = 1;
    num_pids = 0;
    //printf("[+] [Listener] Updating secondary_pid_list: \n"); //DEBUG
    while( (bytes_read = getline(&tid, &len, fp)) != -1) {
      tid[strcspn(tid, "\n")] = 0;
      snprintf(proc_path, sizeof(proc_path), "/proc/%s/cmdline", tid);
      proc_fp = fopen(proc_path, "r");
      if(proc_fp == NULL) {
        printf("[!] [Listener] Could not read /proc entry at %s\n", proc_path);
        return -1;
      }
      else {
        proc_bytes = fread(proc_name, sizeof(char), 1024, proc_fp);
        if( !strcmp(proc_name, "harvest_launcher") ) {
            printf("[*] [Listener] Adding PID: %s ", tid); //DEBUG
            idleCpuStats->secondary_pid_list[idleCpuStats->nr_secondary_ctrs] = atoi(tid);
            idleCpuStats->secondary_ctrs[idleCpuStats->nr_secondary_ctrs].parent_pid = atoi(tid);
            idleCpuStats->secondary_ctrs[idleCpuStats->nr_secondary_ctrs].nr_pids = 0;
            idleCpuStats->nr_secondary_ctrs += 1;
            fclose(proc_fp);
            idleCpuStats->updatingPids = 0;
            fclose(fp);
            if(tid) free(tid);
            printf("[+] [Listener] Done updating PIDs for container %s\n", container_id); //DEBUG
            return num_pids;
        }
      }
    }
    printf("[!] [Listener] Container %s is not a harvest container. Skipping.\n", container_id);
    idleCpuStats->updatingPids = 0;
    return 0;
}

int get_containers(char *pod_id)
{
    printf("[+] [Listener] Finding containers for pod %s\n", pod_id); //DEBUG
    int total_pids = 0;
    DIR *pod_dir;
    struct dirent *d;
    char *container_id;
    char path[PATH_MAX];

    snprintf(path, sizeof(path), "/sys/fs/cgroup/cpuset/kubepods/besteffort/%s", pod_id);
    printf("[+] [Listener] get_containers() checking path %s\n", path); //DEBUG
    errno = 0;
    pod_dir = opendir(path);
    if(!pod_dir) return 0;
    while( (d=readdir(pod_dir) ) ) {
        if(d->d_type != DT_DIR) continue;
        if( !strcmp(d->d_name, ".") || !strcmp(d->d_name, "..") ) continue;
        printf("[+] [Listener] Found container @ %s\n", d->d_name); //DEBUG
        total_pids += get_container_tasks(pod_id, d->d_name);
    }
    closedir(pod_dir);

    printf("[+] [Listener] get_containers() done, returning %d total pids\n", total_pids); //DEBUG
    return total_pids;
}
