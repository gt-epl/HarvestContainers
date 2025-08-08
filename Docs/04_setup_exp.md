# Setup and Run Experiments

## Introduction

The document describes how to reproduce plots for figures included in the paper. 
For a description on how the test runners are designed to work, refer to [Setup Runners](./05_setup_runner.md)

There are three key results from the paper:
1. Fig 5. demonstrates HarvestContainers' ability to harvest cores from a Primary at different workloads while still meeting SLOs within 10% of standalone operation.
2. Fig 8. demonstrates HarvestContainers' efficacy in shielding a Primary from interference caused by a Secondary (NetworkBully) that creates heavy interrupt request activity.
3. Fig 9. demonstrates that HarvestContainers supports multiple Primary and Secondary containers running simultaneously.

## Build HarvestContainers Binaries
- Before you can run experiments, you will need to have builds of the Monitor, Listener, and Balancer components of HarvestContainers. These binaries should have been created for you if you ran the [../TestFramework/Experiments/setup_workload.sh](../TestFramework/Experiments/setup_workload.sh) script. Check `~/HarvestContainers/TestFramework/bin` to ensure that `listener`, `balancer`, and `qidlecpu.ko` are present. If they are missing, run the [../TestFramework/Experiments/setup-bins.sh](../TestFramework/Experiments/setup-bins.sh) script on clabcl1 to build them.

## Pinning Cores for Reproducibility
For correctly determining the CPU utilization of Primary and Secondary workloads, it is important that their containers always run on the same set of CPU cores. Each Primary receives 8 cores needed to achieve SLOs under a given workload, and Secondaries share these cores when they are harvested. We provide a script, `TestFramework/Tools/pincores.sh`, that pins Primary and Secondary containers to their respective set of cores. Note that this pinning is also done automatically when using our `runall.sh` script to run experiments. To manually use `pincores.sh`, refer to the following:

```bash
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 memcached-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 mysql-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 xapian-primary
./pincores.sh 2,4,6,8,10,12,14,16,18 clabcl1 cpubully-secondary
```

### Pre-Flight: Check for Correct Workload Setup

- Use the [sanity.sh](../TestFramework/Experiments/sanity.sh) to test if the workloads are setup properly. This script runs sample baseline and harvest tests, and takes ~9 minutes to complete. It should be run on the clabcl1 node.
- The outputs from evaluation scripts are Primary-specific. They can be found in the following locations:
    - `/mnt/extra/config/<primary_name>_config.out` for info on the runs (e.g., `/mnt/extra/config/memcached_config.out`)
    - `/mnt/extra/results/<primary_name>/summary` for Primary latency results
    - `/mnt/extra/logs/<primary_name>/summary` for CPU utilization / Secondary progress results
- If `sanity.sh` ran successfully, you should see outputs for `memcached`, `mysql`, and `xapian` evaluations in their respective directories. The results for `harvest` should be within 10% of the results for `baseline` at the 99th percentile. For exampe, the `memcached` result might look like the following:
```bash
# From /mnt/extra/results/memcached/sanity.summary
uuid mean min p90 p95 p99 achieved_qps
4e9fa89b-347f-4829-b261-a59171eac98f 64.1 45.3 70.2 73.9 84.8 9986.7  <--Last column is the QPS (10k) and next-to-last column is the 99th percentile latency when running standalone
4ebd21dc-5b46-4155-bbf7-805dfd95a36f 64.6 45.3 70.6 74.7 85.8 10003.4 <--These are the results when harvesting cores
```
 
### Evaluating Harvest for Different Primary Containers (Fig 5.)

- The provided [runall.sh](../TestFramework/Experiments/runall.sh) script should evaluate all three Primary workloads under baseline and harvest at their respective workload levels (as seen in the paper). It should be run on the clabcl1 node, and should take ~2 hours to generate results. We recommend running this script in a tmux or screen session to ensure it can continue to run in the background.
- You will find data and results from evaluations that we ran in the [final_runs](../TestFramework/Experiments/final_runs/) directory and plots of these results in the [figs/](../TestFramework/Experiments/figs/) directory. See [Interpreting Results](./06_interpreting_results.md) for further guidance on how to read plots.
- The [plot_all.py](../TestFramework/Experiments/plot_all.py) script is used to generate plots from these evaluations.

### Evaluating Multiple Primary and Secondary Containers (Fig. 9)

- The provided [run-multi-primary.sh](../TestFramework/Experiments/run-multi-primary.sh) script should evaluate the MySQL and Xapian Primary containers running simultaneously alongside x264 and dedup Secondary containers.
- This script will first gather baselines for both Primary containers when running standalone on their respective sets of CPUs, and then evaluate harvesting from that set of CPUs while also running the x264 and dedup Secondary containers.
- You will find data and results from evaluations that we ran under [final_runs](../TestFramework/Experiments/final_runs/).
- The [plot_multi-primary.py](../TestFramework/Experiments/plot_multi-primary.py) script is used to generate plots from these evaluations.

### Evaluating Interrupt Interference Handling (Fig 8.)

- The provided [run-irq.sh](../TestFramework/Experiments/run-irq.sh) script will test IRQ interference handling, and should be run on the clabcl1 node. It will evaluate each Primary under three different conditions:
  1. Baseline (standalone) operation
  2. Harvesting while running alongside an interrupt-heavy Secondary (NetworkBully) without interrupt-awareness
  3. Harvesting when running alongside an interrupt-heavy Secondary (NetworkBully) with interrupt awareness (shielding) enabled
 - Results when running without interrupt awareness should be significantly worse than baseline, and results when running with interrupt awareness (shielding) enabled should be within 10% of baseline
- You will find data and results from evaluations that we ran under [final_runs](../TestFramework/Experiments/final_runs/).
- The [plot_irq.py](../TestFramework/Experiments/plot_irq.py) script is used to generate plots from these evaluations.


### Handling Reboots
- If you need to reboot the server, you will need to perform the following two steps before running any experiments:
  - 1. Copy Xapian workload data into shared memory by running command `sudo mkdir -p /dev/shm/xapian.inputs && sudo cp -r tailbench.inputs/xapian /dev/shm/xapian.inputs/` (Note: This command will take several minutes to run)
  - 2. Run [../TestFramework/Bootstrap/powerfix.sh](../TestFramework/Bootstrap/powerfix.sh) to re-enable fixed CPU frequencies, which are necessary to achieve repeatable results

## Next: Continue to [Interpreting Results](./06_interpreting_results.md) or [Understanding Test Runners](./05_setup_runner.md)
