#include <dirent.h>

struct proc_tasks {
    DIR *dir;
};

struct proc_tasks *proc_open_tasks(pid_t pid);
void proc_close_tasks(struct proc_tasks *tasks);
int proc_next_tid(struct proc_tasks *tasks, pid_t *tid);
