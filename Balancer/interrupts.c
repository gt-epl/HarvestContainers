#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>

#include "interrupts.h"
#include "balancer.h"

/* Find out which harvest core is busier with IRQs:
 * First check how much time was spent servicing IRQs
 * during last sample interval. If both values are the same
 * then break the tie by looking at the total time spent
 * servicing IRQs thus far */
int cmpweights (const void * c1, const void * c2) {
    const struct harvest_core *s1 = c1;
    const struct harvest_core *s2 = c2;
    if ( s1->curr_weight == s2->curr_weight ) {
        return (harvest_core_weights[s1->cpuid] - 
               harvest_core_weights[s2->cpuid]);
    } else {
        return (s1->curr_weight - s2->curr_weight);
    }
}

int getInterruptWeights() 
{
    int ret;
    int num_changes = 0;
    struct harvest_core newHarvestCores[64];
    idleCpuStats->update_irq = 1;
    while (idleCpuStats->update_irq == 1) {
      continue;
    }

    /* Calculate weights for last sample period, copy into harvest_cores */
    for (int i = 0; i < NUMCPUS; i++) {
        newHarvestCores[i].cpuid = cpuList[i];
        newHarvestCores[i].curr_weight = (idleCpuStats->curr_irq_times[cpuList[i]] - 
                                          prev_irq_times[cpuList[i]]);
        if (newHarvestCores[i].curr_weight > 0) num_changes++;
        prev_irq_times[cpuList[i]] = idleCpuStats->curr_irq_times[cpuList[i]];
    }

    /* IRQ stats didn't change; return without doing anything */
    if (num_changes == 0) {
      return 0;
    }

    /* IRQ handling time(s) changed, so sort harvest_cores by weight */
    qsort(newHarvestCores, NUMCPUS, sizeof(struct harvest_core), cmpweights);

    /* Check if harvest cores order changed;
     * if no, skip rebalance */
    if (newHarvestCores[NUMCPUS-1].cpuid == harvestCores[NUMCPUS-1]) {
        return 0;
    }

    /* Check if newHarvestCores is different from
     * harvest_cores. If yes, need to rebalance */
    for (int i = 0; i < NUMCPUS; i++) {
      if (newHarvestCores[i].cpuid != harvestCores[i]) {
        /* Copy new cores to existing harvestCores */
        for (int i = 0; i < NUMCPUS; i++) {
            harvestCores[i] = newHarvestCores[i].cpuid;
        }
        return 1;
      }
    }
    return 0;
}