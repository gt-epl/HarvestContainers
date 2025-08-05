# Setup and Run Experiments

## Introduction

The document desribes how to reproduce plots for figures included in the paper. 
For a description on how the test runners are designed to work, refer to [Setup Runners](./05_setup_runner.md)

There are three key results from the paper:
1. Fig 5. demonstrates HarvestContainers' ability to harvest cores from a Primary at different workloads while still meeting SLOs within 10% of standalone operation.
2. Fig 8. demonstrates HarvestContainers' efficacy in shielding a Primary from interference caused by a Secondary (NetworkBully) that creates heavy interrupt request activity.
3. Fig 9. demonstrates that HarvestContainers supports multiple Primary and Secondary containers running simultaneously.

## Pinning Cores for Reproducibility
For correctly determining the CPU utilization of Primary and Secondary workloads, it is important that their containers always run on the same set of CPU cores. Each Primary receives 8 cores needed to achieve SLOs under a given workload, and Secondaries share these cores when they are harvested. We provide a script, `TestFramework/Tools/pincores.sh`, that pins Primary and Secondary containers to their respective set of cores. Note that this pinning is also done automatically when using our `runall.sh` script to run experiments. To manually use `pincores.sh`, refer to the following:

```bash
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 memcached-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 mysql-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 xapian-primary
./pincores.sh 2,4,6,8,10,12,14,16,18 clabcl1 cpubully-secondary
```

### Pre-Flight: Check for Correct Workload Setup

- Use the [sanity.sh](../TestFramework/Experiments/sanity.sh) to test if the workloads are setup properly. This script runs sample baseline and harvest tests, and takes ~9 minutes to complete.
- The outputs from evaluation scripts are Primary-specific. They can be found in the following locations:
    - `/mnt/extra/config/<primary_name>_config.out` for info on the runs (e.g., `/mnt/extra/config/memcached_config.out`)
    - `/mnt/extra/results/<primary_name>/summary` for Primary latency results
    - `/mnt/extra/logs/<primary_name>/summary` for CPU utilization / Secondary progress results
- If `sanity.sh` ran successfully, you should see outputs for `memcached`, `mysql`, and `xapian` evaluations in their respective directories. The results for `harvest` should be within 10% of the results for `baseline`.
 
### Evaluating Harvest for Different Primary Containers (Fig 5.)

- The provided [runall.sh](../TestFramework/Experiments/runall.sh) script should evaluate all three Primary workloads under baseline and harvest at their respective workload levels (as seen in the paper). It should take ~6 hours to generate results. We recommend running this script in a tmux or screen session to ensure it can continue to run in the background.
- The `runall.sh` script should also generate plots of results. These plots can be found in the [figs/](../TestFramework/Experiments/figs/) folder. See [Interpreting Results](./06_interpreting_results.md) for further guidance on how to read plots.
- You will find data and results from evaluations that we ran under [final_runs](../TestFramework/Experiments/final_runs/).
- The [plot_all.py](../TestFramework/Experiments/plot_all.py) script is used to generate plots from these evaluations.

### Evaluating Interrupt Interference Handling (Fig 8.)

- The provided [run-irq.sh](../TestFramework/Experiments/run-irq.sh) script should evaluate each Primary under three different conditions:
  1. Baseline (standalone) operation
  2. Harvesting while running alongside an interrupt-heavy Secondary (NetworkBully) without interrupt-awareness
  3. Harvesting when running alongside an interrupt-heavy Secondary (NetworkBully) with interrupt awareness (shielding) enabled
 - Results when running without interrupt awareness should be significantly worse than baseline, and results when running with interrupt awareness (shielding) enabled should be within 10% of baseline
- You will find data and results from evaluations that we ran under [final_runs](../TestFramework/Experiments/final_runs/).
- The [plot_irq.py](../TestFramework/Experiments/plot_irq.py) script is used to generate plots from these evaluations.

### Evaluating Multiple Primary and Secondary Containers (Fig. 9)

- The provided [run-multi-primary.sh](../TestFramework/Experiments/run-multi-primary.sh) script should evaluate the MySQL and Xapian Primary containers running simultaneously alongside x264 and dedup Secondary containers.
- This script will first gather baselines for both Primary containers when running standalone on their respective sets of CPUs, and then evaluate harvesting from that set of CPUs while also running the x264 and dedup Secondary containers.
- You will find data and results from evaluations that we ran under [final_runs](../TestFramework/Experiments/final_runs/).
- The [plot_multi-primary.py](../TestFramework/Experiments/plot_multi-primary.py) script is used to generate plots from these evaluations.

## Next: Continue to [Interpreting Results](./06_interpreting_results.md) or [Understanding Test Runners](./05_setup_runner.md)
