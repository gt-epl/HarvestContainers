#include <sched.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "taskinfo.h"

/* Code in this file heavily based on Linux taskset utility:
 * https://github.com/karelzak/util-linux/blob/master/schedutils/taskset.c
 */

/* Opens /proc/<pid>/task, which contains pids of all children
 * belonging to <pid> 
 */
struct proc_tasks *proc_open_tasks(pid_t pid)
{
    struct proc_tasks *tasks;
    char path[PATH_MAX];

    snprintf(path, sizeof(path), "/proc/%d/task/", pid);

    tasks = malloc(sizeof(struct proc_tasks));
    if (tasks) {
        tasks->dir = opendir(path);
        if (tasks->dir)
            return tasks;
    }

    free(tasks);
    return NULL;
}

void proc_close_tasks(struct proc_tasks *tasks)
{
    if (tasks && tasks->dir)
        closedir(tasks->dir);
    free(tasks);
}

int proc_next_tid(struct proc_tasks *tasks, pid_t *tid)
{
    struct dirent *d;
    char *end;

    if (!tasks || !tid)
        return -EINVAL;

    *tid = 0;
    errno = 0;

    do {
        d = readdir(tasks->dir);
        if (!d)
            return errno ? -1 : 1;

        if (!isdigit((unsigned char) *d->d_name))
            continue;
        errno = 0;
        *tid = (pid_t) strtol(d->d_name, &end, 10);
        if (errno || d->d_name == end || (end && *end))
            return -1;

    } while (!*tid);

    return 0;
}