#define _GNU_SOURCE
#include <sched.h>
#include <time.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "shmem.h"
#include "balancer.h"
#include "taskinfo.h"
#include "logger.h"


void printHarvestCores()
{
    printf("Harvest Cores => ");
    for (int c = 0; c < NUMCPUS; c++) {
        printf("%d ", harvestCores[c]);
    }
    printf("\n");
}

int CoreIsActive(int core_id, unsigned long long mask)
{
    if ((mask & (1ULL << (core_id)))) return 1;
    return 0;
}

void SchedAllSecondary(void)
{
    while (idleCpuStats->updatingPids == 1) {
        if (idleCpuStats->balancerControl == -1) return;
        continue;
    }
    idleCpuStats->needs_rebalance = rebalanceAction;
    while (idleCpuStats->needs_rebalance == rebalanceAction) {
        if (idleCpuStats->balancerControl == -1) return;
        continue;
    }
    #ifdef VERBOSE
    if(rebalanceAction == 2)
        printf("SHRINK to %d cores in %llu ns (%d idle)\n", currSecondaryCoreCount, getTimeElapsed(&now), idleCoresCount);
    if(rebalanceAction == 1)
        printf("GROW to %d cores in %llu ns (%d idle)\n", currSecondaryCoreCount, getTimeElapsed(&now), idleCoresCount);
    #endif
    rebalanceAction = 0;
}

int GetMinSecondaryCores(void)
{
	if (allowSuspendSecondary) return 0;
	return 1;
}

void ComputeSecondaryAffinityMask(struct primary_ctr_info *ci, balancer_info *bi)
{
    int actualCoresAllocated = 0;
    int c, i = 0;

    /* If we have no other spares to allocate, return */
    if (bi->SpareCoresToAllocate <= 0) {
        bi->CoresAllocatedToSecondary = 0;
        return;
    }

    /* Otherwise assign spare cores to Secondary */
    for (c = ci->totalEligibleCores; c > (0); c--) {
        /* If core was NOT set in the last affinity mask AND it is now ACTIVE,
         * assume it is occupied by a Primary thread and skip giving it to
         * Secondary */
        if (!CoreIsActive(ci->cpuList[c-1], lastAffinityMask) && 
            CoreIsActive(ci->cpuList[c-1], currIdleMask)) {
                continue;
        } else {
            CPU_SET(ci->cpuList[c-1], &secondary_mask);
            setAffinityMask |= 1ULL << (ci->cpuList[c-1]);
            idleCpuStats->affinity_list[affinityListPos] = ci->cpuList[c-1];
            affinityListPos++;
            i++;
            currSecondaryCoreCount++;
            actualCoresAllocated++;
            if (i == bi->SpareCoresToAllocate) break;
        }
    }
    bi->CoresAllocatedToSecondary = actualCoresAllocated;
    return;
}

void SleepSecondary(void)
{
    /*
    struct pid *secondary_pid_struct;
    struct task_struct *secondary_task;
    secondary_pid_struct = find_get_pid(secondary_pid);
    secondary_task = pid_task(secondary_pid_struct, PIDTYPE_PID);
    kill_pid(secondary_pid_struct, SIGSTOP, 0);
    */
    //send_sig(SIGSTOP, secondary_task, 0);
}

void WakeSecondary(void)
{
    /*
    struct pid *secondary_pid_struct;
    struct task_struct *secondary_task;
    secondary_pid_struct = find_get_pid(secondary_pid);
    secondary_task = pid_task(secondary_pid_struct, PIDTYPE_PID);
    kill_pid(secondary_pid_struct, SIGCONT, 0);
    */
    //send_sig(SIGCONT, secondary_task, 0);
}

int AllocateCoresToSecondary()
{
    CPU_ZERO(&secondary_mask);
    lastSecondaryCoreCount = currSecondaryCoreCount;
    currSecondaryCoreCount = 0;
    setAffinityMask = 0;
    affinityListPos = 0;
    
    /* Update Secondary affinity mask based on each Primary's spare cores,
     * then apply new affinity mask based on the results */
    for (int i = 0; i < idleCpuStats->nr_primary_ctrs; i++) {
        ComputeSecondaryAffinityMask(&idleCpuStats->primary_ctrs[i], &balancer_ctr_stats[i]);
    }

    if (currSecondaryCoreCount == 0) {
        rebalanceAction = 3;
        idleCpuStats->num_affinity = currSecondaryCoreCount;
        SchedAllSecondary();
        return 1;
    } else if (currSecondaryCoreCount > lastSecondaryCoreCount) {
        rebalanceAction = 1;
    } else if (currSecondaryCoreCount < lastSecondaryCoreCount) {
        rebalanceAction = 2;
    } else {
        rebalanceAction = 1;
    }

    if (setAffinityMask != lastAffinityMask) {
        idleCpuStats->num_affinity = currSecondaryCoreCount;
        SchedAllSecondary();
    } else return 0;

    return 1;
}
