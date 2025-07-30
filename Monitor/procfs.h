#include <linux/proc_fs.h>
#include <linux/kernel_stat.h>
#include <linux/cgroup-defs.h> // Needed for tasks
#include <linux/pid_namespace.h> // Needed for tasks
#include <linux/delay.h> // Needed for tasks

#include "monitor.h"

#define PROCFS_NAME "idlecpu"
#define PROCFS_MAX_SIZE 1024

static unsigned long procfs_buffer_size = 0;
static struct proc_dir_entry *logent;
static struct proc_dir_entry *logcontrolent;
static struct proc_dir_entry *maskent;
static struct proc_dir_entry *controlent;
static struct proc_dir_entry *cpulistent;
static struct proc_dir_entry *bindcpuent;
static struct proc_dir_entry *irqtime;
static struct proc_dir_entry *parent;

static int procfile_show(struct seq_file *m,void *v){
    static char *str = NULL;
    seq_printf(m,"%s\n",str);
    return 0;
}

static int procfile_open(struct inode *inode,struct file *file){
    return single_open(file,procfile_show,NULL);
}

static ssize_t control_writer(struct file *file, const char __user *ubuf, size_t count, 
                                loff_t *offset)
{
    int tlen;
    int rtn;
    int ctrl;
    char *tmp = kzalloc((count+1), GFP_KERNEL);
    if(!tmp) return -ENOMEM;
    if(copy_from_user(tmp, ubuf, count)){
        kfree(tmp);
        return EFAULT;
    }
 
    tlen = PROCFS_MAX_SIZE;
    if (count < PROCFS_MAX_SIZE)
        tlen = count;


    rtn = sscanf(tmp, "%d", &ctrl);
    if (rtn != 1) return -EFAULT;
    if(ctrl == 1) {
        runnable = 1;
        wake_up_process(check_idle_cpus_task);
    }
    else if(ctrl == 0) {
        runnable = 0;
    }
    kfree(tmp);
    return tlen;
}

static ssize_t logcontrol_writer(struct file *file, const char __user *ubuf, 
                            size_t count, loff_t *offset)
{
    int rtn;
    int ctrl;
    int tlen;
    char *tmp = kzalloc((count+1), GFP_KERNEL);
    if(!tmp) return -ENOMEM;
    if(copy_from_user(tmp, ubuf, count)) {
        kfree(tmp);
        return -EFAULT;
    }
 
    tlen = PROCFS_MAX_SIZE;
    if (count < PROCFS_MAX_SIZE)
        tlen = count;

    rtn = sscanf(tmp, "%d", &ctrl);
    if (rtn != 1) return -EFAULT;
    if(ctrl >= 0 && ctrl < 3) {
        LOG_LEVEL = ctrl;
    }
    else {
        LOG_LEVEL = 0;
    }
    kfree(tmp);
    return tlen;
}

static ssize_t bindcpu_writer(struct file *file, const char __user *ubuf, size_t count, 
                                loff_t *offset)
{
    int tlen;
    int rtn;
    int bind_cpu;
    char *tmp = kzalloc((count+1), GFP_KERNEL);
    if(!tmp) return -ENOMEM;
    if(copy_from_user(tmp, ubuf, count)){
        kfree(tmp);
        return EFAULT;
    }
 
    tlen = PROCFS_MAX_SIZE;
    if (count < PROCFS_MAX_SIZE)
        tlen = count;

    rtn = sscanf(tmp, "%d", &bind_cpu);
    if (rtn != 1) return -EFAULT;

    kthread_bind(check_idle_cpus_task, bind_cpu);
    wake_up_process(check_idle_cpus_task);

    kfree(tmp);
    return tlen;
}

static ssize_t cpulist_writer(struct file *file, const char __user *ubuf, size_t count, 
                                loff_t *offset)
{
    int tlen;
    int curr_cpu;
    char *token;
    char *tmp = kzalloc((count+1), GFP_KERNEL);

    if(!tmp) return -ENOMEM;
    if(copy_from_user(tmp, ubuf, count)){
        kfree(tmp);
        return EFAULT;
    }
 
    tlen = PROCFS_MAX_SIZE;
    if (count < PROCFS_MAX_SIZE)
        tlen = count;

    curr_cpu = 0;
    while( (token = strsep(&tmp, ",")) != NULL ) {
      sscanf(token, "%d", &cpuList[curr_cpu]);
      curr_cpu++;
    }
    NUMCPUS = curr_cpu;

    kfree(tmp);
    return tlen;
}

static ssize_t cpulist_reader(struct file *file, char __user *ubuf, size_t count, 
                            loff_t *offset)
{
    char *buf;
    int pos;
    int ret;

    if (*offset > 0 || count < PROCFS_MAX_SIZE)
        return 0;
    
    buf = vmalloc(sizeof(char)*NUMCPUS);
    for(pos = 0; pos < NUMCPUS; pos++) {
        ret = sprintf(&buf[procfs_buffer_size], "%d,", cpuList[pos]);
        if(ret < 0) return 0;
        else procfs_buffer_size += ret;
    }
    ret = sprintf(&buf[procfs_buffer_size], "%s", "\b \b\n");
    if(ret < 0) return 0;
    else procfs_buffer_size += ret;

    if(copy_to_user(ubuf, buf, procfs_buffer_size))
        return -EFAULT;
    vfree(buf);
    *offset = procfs_buffer_size;
    return procfs_buffer_size;
}

static ssize_t mask_reader(struct file *file, char __user *ubuf, size_t count, 
                            loff_t *offset)
{
    char *buf;

    if (*offset > 0 || count < PROCFS_MAX_SIZE)
        return 0;
    
    buf = vmalloc(sizeof(char)*1);
    procfs_buffer_size = sprintf(buf, "%d\n", numIdleCpus);
    if(copy_to_user(ubuf, buf, procfs_buffer_size))
        return -EFAULT;
    vfree(buf);
    *offset = procfs_buffer_size;
    return procfs_buffer_size;
}

static ssize_t irqtime_reader(struct file *file, char __user *ubuf, size_t count, 
                            loff_t *offset)
{
    char *buf;
    struct kernel_cpustat kcpustat;
    u64 *cpustat = kcpustat.cpustat;
    int pos;
    int ret;
    u64 hiq;
    //u64 siq;

    if (*offset > 0 || count < PROCFS_MAX_SIZE)
        return 0;
    
    buf = vmalloc(sizeof(unsigned long long)*NUMCPUS + NUMCPUS);
    for(pos = 0; pos < NUMCPUS; pos++) {
        kcpustat_cpu_fetch(&kcpustat, cpuList[pos]);
        hiq = div_u64(cpustat[CPUTIME_IRQ] * 9, (9ull * NSEC_PER_SEC + (USER_HZ / 2)) / USER_HZ);
        //siq = div_u64(cpustat[CPUTIME_SOFTIRQ] * 9, (9ull * NSEC_PER_SEC + (USER_HZ / 2)) / USER_HZ);
        //ret = sprintf(&buf[procfs_buffer_size], "%lld,", hiq+siq);
        ret = sprintf(&buf[procfs_buffer_size], "%lld,", hiq);
        if(ret < 0) return 0;
        else procfs_buffer_size += ret;
    }
    ret = sprintf(&buf[procfs_buffer_size], "%s", "\b \b\n");

    if(copy_to_user(ubuf, buf, procfs_buffer_size))
        return -EFAULT;
    vfree(buf);
    *offset = procfs_buffer_size;
    return procfs_buffer_size;
}

static ssize_t log_reader(struct file *file, char __user *ubuf, size_t count,
                        loff_t *offset)
{
    char *buf;
    char *human_readable_mask;
    int i;
    if (entrypos > numentries-1)
        return 0;
    buf = vmalloc(sizeof(struct logentry));
    /* Write human-friendly 1's and 0's */
    human_readable_mask = vmalloc(sizeof(char)*(1+cpuList[NUMCPUS-1]+1));
    for(i = 0; i <= cpuList[NUMCPUS-1]; i++) {
        if( (events[entrypos].mask & (1ULL << (i))) ) {
            human_readable_mask[i] = 1+'0';
        }
        else human_readable_mask[i] = 0+'0';
    }
    human_readable_mask[i] = '\0';

/* Or write the mask in hex
    procfs_buffer_size = sprintf(buf, "%i,%ld,%llu,%#llx\n", entrypos, 
                            events[entrypos].sec, events[entrypos].nsec, 
                            events[entrypos].mask);
*/

/* Formerly printed the entrypos as a way to debug/show how many log
   entries were written to procfs

    procfs_buffer_size = sprintf(buf, "%i,%lu,%lu,%s\n", entrypos, 
                            events[entrypos].sec, events[entrypos].nsec, 
                            human_readable_mask);
*/
    procfs_buffer_size = sprintf(buf, "%lu,%lu,%s\n",
                            events[entrypos].sec, events[entrypos].nsec, 
                            human_readable_mask);

    if(copy_to_user(ubuf, buf, procfs_buffer_size)) {
        vfree(buf);
        vfree(human_readable_mask);
        return -EFAULT;
    }
    vfree(buf);
    vfree(human_readable_mask);
    entrypos++;
    *offset = procfs_buffer_size;
    return procfs_buffer_size;
}

static struct proc_ops proc_logcontrol_fops =
{
    .proc_lseek = seq_lseek,
    .proc_open = procfile_open,
    //.proc_read = log_reader,
    .proc_release = single_release,
    .proc_write = logcontrol_writer,
};

static struct proc_ops proc_control_fops =
{
    .proc_lseek = seq_lseek,
    .proc_open = procfile_open,
    //.proc_read = log_reader,
    .proc_release = single_release,
    .proc_write = control_writer,
};

static struct proc_ops proc_mask_fops =
{
    .proc_lseek = seq_lseek,
    .proc_open = procfile_open,
    .proc_read = mask_reader,
    .proc_release = single_release,
    //.proc_write = control_writer,
};

static struct proc_ops proc_cpulist_fops =
{
    .proc_lseek = seq_lseek,
    .proc_open = procfile_open,
    .proc_read = cpulist_reader,
    .proc_release = single_release,
    .proc_write = cpulist_writer,
};

static struct proc_ops proc_bindcpu_fops =
{
    .proc_lseek = seq_lseek,
    .proc_open = procfile_open,
    //.proc_read = bindcpu_reader,
    .proc_release = single_release,
    .proc_write = bindcpu_writer,
};

static struct proc_ops proc_irqtime_fops =
{
    .proc_lseek = seq_lseek,
    .proc_open = procfile_open,
    .proc_read = irqtime_reader,
    .proc_release = single_release,
    //.proc_write = bindcpu_writer,
};

static struct proc_ops proc_log_fops =
{
    .proc_lseek = seq_lseek,
    .proc_open = procfile_open,
    .proc_read = log_reader,
    .proc_release = single_release,
};
