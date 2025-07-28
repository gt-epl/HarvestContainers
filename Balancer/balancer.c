#define _GNU_SOURCE
#include <sched.h>
#include <time.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "balancer.h"
#include "taskinfo.h"
#include "logger.h"

/* Begin Experimental */
void printHarvestCores()
{
    printf("Harvest Cores => ");
    for (int c = 0; c < NUMCPUS; c++) {
        printf("%d ", harvestCores[c]);
    }
    printf("\n");
}
/* End Experimental */

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

void ComputeSecondaryAffinityMask(struct ctr_info *ctr)
{
    int actualCoresAllocated = 0;
    int c, i = 0;

    /* If we have no other spares to allocate, return */
    if (ctr->SpareCoresToAllocate <= 0) {
        //CoresAllocatedToSecondary = currSecondaryCoreCount;
        ctr->CoresAllocatedToSecondary = 0;
        return;
    }

    /* Otherwise assign spare cores to Secondary */
    for (c = ctr->totalEligibleCores; c > (0); c--) {
        /* If core was NOT set in the last affinity mask AND it is now ACTIVE,
         * assume it is occupied by a Primary thread and skip giving it to
         * Secondary */
        if (!CoreIsActive(ctr->cpuList[c-1], lastAffinityMask) && 
            CoreIsActive(ctr->cpuList[c-1], currIdleMask)) {
                continue;
        } else {
            CPU_SET(ctr->cpuList[c-1], &secondary_mask);
            setAffinityMask |= 1ULL << (ctr->cpuList[c-1]);
            idleCpuStats->affinity_list[affinityListPos] = ctr->cpuList[c-1];
            affinityListPos++;
            i++;
            currSecondaryCoreCount++;
            actualCoresAllocated++;
            if (i == ctr->SpareCoresToAllocate) break;
        }
    }
    ctr->CoresAllocatedToSecondary = actualCoresAllocated;
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
    /* TODO: This function should go through each Primary container struct,
     * call ComputeSecondaryAffinityMask() to update the Secondary's 
     * mask based on that Primary's spare cores, and then apply 
     * the new affinity mask based on the results
     * NOTE: FOR NOW WE JUST CALL THIS FOR c1-c3 */
    ComputeSecondaryAffinityMask(c1);
    //ComputeSecondaryAffinityMask(c2);
    //ComputeSecondaryAffinityMask(c3);

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

    /*
    if (SpareCoresToAllocate != 0 && processSuspended) {
        WakeSecondary();
        processSuspended = 0;
    }
    */
    return 1;
}
