#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/sched.h>
#include <linux/kthread.h>
#include <linux/vmalloc.h>
#include <linux/fs.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/cpuset.h>
#include <linux/string.h>
#include <linux/device.h>
#include <linux/interrupt.h>

#include "monitor.h"
#include "shmem.h"
#include "procfs.h"


int set_irq_affinity(int num_cpus)
{
  int i;
  struct cpumask *new_affinity_mask;
  struct timespec64 start;
  struct timespec64 end;
  unsigned long long elapsed;
  ktime_get_raw_ts64(&start);

  new_affinity_mask = kmalloc(sizeof(struct cpumask), GFP_USER);
  cpumask_clear(new_affinity_mask);
  /* Always add the dedicated set of IRQ handling cores */
  for (i = 0; i < num_cpus; i++) {
    cpumask_set_cpu(irqAffinity[i], new_affinity_mask);
  }
  /* Now assign spare Harvest cores */
  for (i = 0; i < idleCpuStats->num_affinity; i++) {
    cpumask_set_cpu(idleCpuStats->affinity_list[i], new_affinity_mask);
  }
  /* Affinitize all the IRQs that we're managing */
  for (i = 0; i < NUM_INTERRUPTS; i++) {
    int curr_interrupt = irqList[i];
    irq_set_affinity(curr_interrupt, new_affinity_mask);
  }

  ktime_get_raw_ts64(&end);
  
  elapsed = (1000*1000*1000) *
    (end.tv_sec - start.tv_sec) +
    (end.tv_nsec - start.tv_nsec);
 
  printk(KERN_INFO "[SET_IRQ_AFFINITY] %llu\n", (unsigned long long)elapsed);

  return 0;
}

int get_irq_times(void)
{
    struct kernel_cpustat kcpustat;
    u64 *cpustat = kcpustat.cpustat;
    u64 hiq;
    int pos;

    for (pos = 0; pos < NUMCPUS; pos++) {
        kcpustat_cpu_fetch(&kcpustat, cpuList[pos]);
        hiq = div_u64(cpustat[CPUTIME_IRQ] * 9, (9ull * NSEC_PER_SEC + (USER_HZ / 2)) / USER_HZ);
        idleCpuStats->curr_irq_times[cpuList[pos]] = hiq;
        idleCpuStats->hist_irq_times[cpuList[pos]] += hiq;
    }
    return 0;
}


int update_pid_cache(struct task_struct *secondary_init_task, struct ctr_info *secondary_ctr_info)
{
  struct list_head *lh;
  struct list_head *lh_tmp;
  struct task_struct *ts;
  int curr_pid = 0;
  /* Update PID cache */
  list_for_each_safe(lh, lh_tmp, &secondary_init_task->cgroups->tasks) {
    rcu_read_lock();
    ts = list_entry(lh, struct task_struct, cg_list);
    if (unlikely(!ts)) {
      rcu_read_unlock();
      continue;
    }
    get_task_struct(ts);
    rcu_read_unlock();
    secondary_ctr_info->pidList[curr_pid] = ts->pid;
    put_task_struct(ts);
    curr_pid++;
    secondary_ctr_info->nr_pids = curr_pid;
    if (curr_pid > 127) return -1;
  }
  return 0;
}

void twopa(void) {
  struct ctr_info *curr_secondary_ctr_info;
  struct pid *secondary_init_pid;
  struct task_struct *secondary_init_task;
  struct css_set *ctr_css_set = NULL;

  struct pid *this_pid;
  struct task_struct *this_task;
  struct cpumask *new_affinity_mask;
  int has_task[64] = {0};
  int num_placements = 0;
  int curr_cpu = 0;
  int curr_secondary_ctr = 0;
  int curr_ctr_pid = 0;

  new_affinity_mask = kmalloc(sizeof(struct cpumask), GFP_USER);

  for (curr_secondary_ctr = 0; 
      curr_secondary_ctr < idleCpuStats->nr_secondary_ctrs;
      curr_secondary_ctr++) {
    curr_secondary_ctr_info = &idleCpuStats->secondary_ctrs[curr_secondary_ctr];
    /* Get task_struct for Secondary Container Init PID */
    rcu_read_lock();
    secondary_init_pid = find_vpid(curr_secondary_ctr_info->parent_pid);
    if (unlikely(!secondary_init_pid)) {
      rcu_read_unlock();
      curr_secondary_ctr++;
      continue;
    }
    secondary_init_task = pid_task(secondary_init_pid, PIDTYPE_PID);
    if (unlikely(!secondary_init_task)) {
        rcu_read_unlock();
        curr_secondary_ctr++;
        continue;
    }
    get_task_struct(secondary_init_task);
    /* Get css_set for Secondary Container */
    ctr_css_set = secondary_init_task->cgroups;
    /* Get number of Secondary PIDs in the container */
    if (curr_secondary_ctr_info->nr_pids != ctr_css_set->nr_tasks) {
      update_pid_cache(secondary_init_task, curr_secondary_ctr_info);
    }
    put_task_struct(secondary_init_task);
    rcu_read_unlock();
  }

  for (curr_secondary_ctr = 0;
      curr_secondary_ctr < idleCpuStats->nr_secondary_ctrs;
      curr_secondary_ctr++) {

    curr_secondary_ctr_info = &idleCpuStats->secondary_ctrs[curr_secondary_ctr];

    /* --------- Phase 1 --------- */
    if (idleCpuStats->needs_rebalance == 1) {
      for (curr_ctr_pid = 0; curr_ctr_pid < curr_secondary_ctr_info->nr_pids; curr_ctr_pid++) {
        rcu_read_lock();
        this_pid = find_vpid(curr_secondary_ctr_info->pidList[curr_ctr_pid]);
        if (unlikely(!this_pid)) {
          rcu_read_unlock();
          continue;
        }
        this_task = pid_task(this_pid, PIDTYPE_PID);
        if (unlikely(!this_task)) {
          rcu_read_unlock();
          continue;
        }
        /* We only care about migrating running tasks, so if this_task is not
         * in a runnable state, skip it */
        get_task_struct(this_task);
        if (this_task->state != TASK_RUNNING) {
          put_task_struct(this_task);
          rcu_read_unlock();
          continue;
        }
        /* If this_task's current CPU is NOT marked as having at least 1 active
         * task, leave this_task in place and mark that CPU has having a task. */
        if (!has_task[this_task->cpu]) {
            has_task[this_task->cpu] = 1;
            num_placements++;
            put_task_struct(this_task);
            rcu_read_unlock();
            continue;
        }
        /* Make sure we don't try and put this_task on its current CPU if it
         * needs migration */
        if (idleCpuStats->affinity_list[curr_cpu] == this_task->cpu) curr_cpu++;
        /* Loop around if we have exceeded number of affinity CPUs */
        if (curr_cpu == idleCpuStats->num_affinity) curr_cpu = 0;

        /* We need to migrate this_task, so create a single-cpu affinity mask */
        cpumask_clear(new_affinity_mask);
        cpumask_set_cpu(idleCpuStats->affinity_list[curr_cpu], new_affinity_mask);
        if (unlikely(!this_task)) {
            put_task_struct(this_task);
            rcu_read_unlock();
            continue;
        }
        set_cpus_allowed_ptr(this_task, new_affinity_mask);
        put_task_struct(this_task);
        rcu_read_unlock();

        /* Mark curr_cpu as having a task placed on it */
        has_task[idleCpuStats->affinity_list[curr_cpu]] = 1;
        num_placements++;

        /* If each core in the new affinity mask has a task
        * then we can stop doing single placements */
        if (num_placements == idleCpuStats->num_affinity) break;
        curr_cpu++;
      } // End looping thru container PIDs for Phase 1
    }

    /* --------- Phase 2 --------- */
    /* Go back and set the full affinity mask on all Secondary PIDs */
    /* Always assign dedicated Secondary cores */
    cpumask_clear(new_affinity_mask);
    for (curr_cpu = 0; curr_cpu < idleCpuStats->num_secondary_cores; curr_cpu++) {
      cpumask_set_cpu(idleCpuStats->secondary_cores_list[curr_cpu], new_affinity_mask);
    }

    /* Now assign spare Harvest cores */
    for (curr_cpu = 0; curr_cpu < idleCpuStats->num_affinity; curr_cpu++) {
      cpumask_set_cpu(idleCpuStats->affinity_list[curr_cpu], new_affinity_mask);
    }

    /* Set full affinity mask on all Secondary PIDs */
    for (curr_ctr_pid = 0; curr_ctr_pid < curr_secondary_ctr_info->nr_pids; curr_ctr_pid++) {
      rcu_read_lock();
      this_pid = find_vpid(curr_secondary_ctr_info->pidList[curr_ctr_pid]);
      if (unlikely(!this_pid)) {
        rcu_read_unlock();
        continue;
      }
      this_task = pid_task(this_pid, PIDTYPE_PID);
      if (unlikely(!this_task)) {
        rcu_read_unlock();
        continue;
      }
      get_task_struct(this_task);
      set_cpus_allowed_ptr(this_task, new_affinity_mask);
      put_task_struct(this_task);
      rcu_read_unlock();
    } // End looping thru container PIDs for Phase 2
  } // End Phase1+Phase2 for each Container

  kfree(new_affinity_mask);
} // End twopa()

int check_idle_cpus(void *data) 
{
    int pos;
    struct timespec64 now;
    long last_sec = 0;
    long last_nsec = 0;
    numentries = 0;
    entrypos = 0;
    LOG_LEVEL = 0;

    handle_irq = 0;
    runnable = 0;
    samples = 0;
    currMask = 0;
    lastMask = 0;
    rebalancing = 0;
    idleCpuStats = &sh_mem[0];

    idleCpuStats->numIdle = 0;
    idleCpuStats->num_affinity = 0;
    idleCpuStats->mask = 0;
    idleCpuStats->samples = 0;
    idleCpuStats->irq_samples = 0;
    idleCpuStats->needs_rebalance = 0;
    idleCpuStats->nr_secondary_ctrs = 0;
    idleCpuStats->nr_primary_ctrs = 0;

    /* Initialize IRQ data */
    for (pos = 0; pos < NUMCPUS; pos++) {
        idleCpuStats->curr_irq_times[cpuList[pos]] = 0;
    }

    while (1) {
        if (kthread_should_stop()) {
            return 0;
        }
        if (!runnable) {
            set_current_state(TASK_INTERRUPTIBLE);
            schedule();
        }
        idleCount = 0;
        for (curr_cpu = 0; curr_cpu < NUMCPUS; curr_cpu++) {
            is_idle = idle_cpu(cpuList[curr_cpu]);
            if (is_idle) {
                /* bit is 0 for idle */
                currMask &= ~(1ULL << (cpuList[curr_cpu]));
                idleCount++;
            } else {
                /* bit is 1 for active */
                currMask |= 1ULL << (cpuList[curr_cpu]);
            }
        }
        idleCpuStats->numIdle = idleCount;
        idleCpuStats->mask = currMask;
 
        if (idleCpuStats->update_irq > 0) {
            get_irq_times();
            idleCpuStats->update_irq = 0;
        }
        if ((idleCpuStats->needs_rebalance > 0) && !(rebalancing)) {
            rebalancing = 1;
            twopa();
            rebalancing = 0;
            idleCpuStats->needs_rebalance = 0;
            schedule();
        }

        if (samples > 100000) {
            get_irq_times();
            idleCpuStats->irq_samples += 1;
            schedule();
        } else samples++;

        if (LOG_LEVEL > 0) {
            if (numentries > LOGSIZE-1) continue;
            ktime_get_raw_ts64(&now);
            if (LOG_LEVEL == 1) {
                /* Avoid writing redundant log entry if no mask change */
                if (currMask == lastMask) continue;
            }
            /* Otherwise write entry to log and update lastMask */
            events[numentries].sec = now.tv_sec;
            last_sec = now.tv_sec;
            events[numentries].nsec = now.tv_nsec;
            last_nsec = now.tv_nsec;
            events[numentries].mask = currMask;
            lastMask = currMask;
            ++numentries;
        }
	}
    return 0; 
}

int __init logger_proc_init(void)
{
    parent = proc_mkdir(PROCFS_NAME,NULL);
    maskent = proc_create("mask",0777,parent,&proc_mask_fops);
    if (!maskent)
        return -1;

    controlent = proc_create("control",0777,parent,&proc_control_fops);
    if (!controlent)
        return -1;

    cpulistent = proc_create("cpulist",0777,parent,&proc_cpulist_fops);
    if (!cpulistent)
        return -1;

    bindcpuent = proc_create("bindcpu",0777,parent,&proc_bindcpu_fops);
    if (!bindcpuent)
        return -1;

    irqtime = proc_create("irqtime",0777,parent,&proc_irqtime_fops);
    if (!irqtime)
        return -1;

    logent = proc_create("log",0777,parent,&proc_log_fops);
    if (!logent)
        return -1;

    logcontrolent = proc_create("logcontrol",0777,parent,&proc_logcontrol_fops);
    if (!logcontrolent)
        return -1;

    irqlist = proc_create("irqlist",0777,parent,&proc_irqlist_fops);
    if (!irqlist)
        return -1;

    irqaffinity = proc_create("irqaffinity",0777,parent,&proc_irqaffinity_fops);
    if (!irqaffinity)
        return -1;

    irqcontrol = proc_create("irqcontrol",0777,parent,&proc_irqcontrol_fops);
    if (!irqcontrol)
        return -1;

    return 0;
}
	
void __exit logger_proc_cleanup(void)
{
    remove_proc_entry("mask", parent);
    remove_proc_entry("control", parent);
    remove_proc_entry("cpulist", parent);
    remove_proc_entry("bindcpu", parent);
    remove_proc_entry("irqtime", parent);
    remove_proc_entry("log", parent);
    remove_proc_entry("logcontrol", parent);
    remove_proc_entry("irqlist", parent);
    remove_proc_entry("irqaffinity", parent);
    remove_proc_entry("irqcontrol", parent);
    remove_proc_entry(PROCFS_NAME, NULL);
}

static int __init idlecpu_init(void)
{
    int data;
    int ret;

    printk(KERN_INFO "Loaded QUERY_IDLECPU module\n");
     
    ret = logger_proc_init();
    if (ret == -1)
        goto out;
    
    /* By default, we just monitor cpu0 until a proper list is defined */
    NUMCPUS = 1;
    cpuList[0] = 0;
    data = 20;
    /* Thread to check idle_cpu() will be created, but not started until
     * a core to bind to is set via /proc/idlecpu/bind */
    check_idle_cpus_task = kthread_create(&check_idle_cpus, (void *)&data, "check_idle_cpus");
    get_task_struct(check_idle_cpus_task);

    ret = 0;
    major = register_chrdev(0, DEVICE_NAME, &qidlecpu_fops);

    if (major < 0) {
        pr_info("qidlecpu: failed to register major number!");
        ret = major;
        goto out;
    }

    class = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(class)){
        unregister_chrdev(major, DEVICE_NAME);
        pr_info("qidlecpu: failed to register device class");
        ret = PTR_ERR(class);
        goto out;
    }

    device = device_create(class, NULL, MKDEV(major, 0), NULL, DEVICE_NAME);
    if (IS_ERR(device)) {
        class_destroy(class);
        unregister_chrdev(major, DEVICE_NAME);
        ret = PTR_ERR(device);
        goto out;
    }

    /* Allocate memory for cpulogger entries */
    events = vmalloc(sizeof(struct logentry)*LOGSIZE);
    if (!events) {
        return -1;
    }

    /* Init this mmap area */
    sh_mem = kmalloc(SHMEM_SIZE, GFP_KERNEL);
    if (sh_mem == NULL) {
        ret = -ENOMEM;
        goto out;
    }
    mutex_init(&qidlecpu_mutex);
out:
    return ret;
}

static void __exit idlecpu_exit(void)
{
    kthread_stop(check_idle_cpus_task);
    put_task_struct(check_idle_cpus_task);
    vfree(events);
    kfree(sh_mem);
    logger_proc_cleanup();
    mutex_destroy(&qidlecpu_mutex);
    device_destroy(class, MKDEV(major, 0));
    class_destroy(class);
    unregister_chrdev(major, DEVICE_NAME);

    printk(KERN_INFO "Unloaded QUERY_IDLECPU module\n");
}

module_init(idlecpu_init);
module_exit(idlecpu_exit);
  
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Adam Hall");
MODULE_DESCRIPTION("Query idle_cpu");
MODULE_SUPPORTED_DEVICE("idlecpu");
