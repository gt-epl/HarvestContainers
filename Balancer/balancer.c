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
    for(int c = 0; c < NUMCPUS; c++) {
        printf("%d ", harvestCores[c]);
    }
    printf("\n");
}
/* End Experimental */

int CoreIsActive(int core_id, unsigned long long mask)
{
    if( (mask & (1ULL << (core_id))) ) return 1;
    else return 0;
}

void SchedAllSecondary(void)
{
    while(idleCpuStats->updatingPids == 1) {
        if(idleCpuStats->balancerControl == -1) return;
        continue;
    }
    idleCpuStats->needs_rebalance = rebalanceAction;
    while(idleCpuStats->needs_rebalance == rebalanceAction) {
        if(idleCpuStats->balancerControl == -1) return;
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

void ComputeSecondaryAffinityMask(int totalEligibleCores,
    int SpareCores)
{
    int c, i = 0;
    CPU_ZERO(&secondary_mask);
    lastSecondaryCoreCount = currSecondaryCoreCount;
    currSecondaryCoreCount = 0;
    setAffinityMask = 0;

    /* If we have no other spares to allocate, return */
    if(SpareCores <= 0) {
        CoresAllocatedToSecondary = currSecondaryCoreCount;
        return;
    }

    /* Otherwise assign spare cores to Secondary */
    for(c = totalEligibleCores;
        c > (0); c--) {
        /* If core was NOT set in the last affinity mask AND it is now ACTIVE,
         * assume it is occupied by a Primary thread and skip giving it to
         * Secondary */
        if(!CoreIsActive(harvestCores[c-1], lastAffinityMask) && 
            CoreIsActive(harvestCores[c-1], currIdleMask)) {
                continue;
        }
        else {
            CPU_SET(harvestCores[c-1], &secondary_mask);
            setAffinityMask |= 1ULL << (harvestCores[c-1]);
            idleCpuStats->affinity_list[i] = harvestCores[c-1];
            i++;
            currSecondaryCoreCount++;
            if(i == SpareCores) break;
        }
    }
    CoresAllocatedToSecondary = currSecondaryCoreCount;
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

int AllocateCoresToSecondary(int pid, int totalEligibleCores, int SpareCoresToAllocate)
{
    /* Note: In Win version processSuspended is defined here and the suspended
     * process never seems to wake up because processSuspended always results
     * in 0 on call to AllocateCoresToSecondary()
     * Comment out 'int processSuspended = 0' to utilize Sleep/Wake
    */
    /*
    int processSuspended = 0;
    if (SpareCoresToAllocate == 0) {
		if (!processSuspended) {
			SleepSecondary();
			processSuspended = 1;
		}
		return 0;
	}
    */
    ComputeSecondaryAffinityMask(totalEligibleCores, SpareCoresToAllocate);

    if(currSecondaryCoreCount == 0) {
        rebalanceAction = 3;
        idleCpuStats->num_affinity = currSecondaryCoreCount;
        SchedAllSecondary();
        return 1;
    }
    else if(currSecondaryCoreCount > lastSecondaryCoreCount) {
        rebalanceAction = 1;
    }
    else if(currSecondaryCoreCount < lastSecondaryCoreCount) {
        rebalanceAction = 2;
    }
    else {
        rebalanceAction = 1;
    }

    if(setAffinityMask != lastAffinityMask) {
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

void TakeCoresFromSecondary(int coresToTake)
{
	CoresAllocatedToSecondary -= coresToTake;
    ComputeSecondaryAffinityMask(totalEligibleCores, CoresAllocatedToSecondary);
}

void ReleaseCoresToSecondary(int coresToRelease)
{
	CoresAllocatedToSecondary += coresToRelease;
    ComputeSecondaryAffinityMask(totalEligibleCores, CoresAllocatedToSecondary);
}

void UpdateCoreTracking(int newSecondaryCores, int oldSecondaryCores)
{
	int coreDifference = newSecondaryCores - oldSecondaryCores;
	if (coreDifference < 0) TakeCoresFromSecondary(-coreDifference);
	else if (coreDifference > 0) ReleaseCoresToSecondary(coreDifference);
}
