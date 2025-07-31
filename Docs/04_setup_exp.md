# Experiment setup

## Introduction

The document desribes how to reproduce plots for figures included in the paper. 
For a description on how the test runners are designed to work, refer to [Setup Runners](./05_setup_runner.md)

There 3 key results from the paper.
1. Fig 5. that shows HarvestContainers ability to harvest cores from a varied Primary workloads while still meeting SLOs.
2. Fig 8. that demonstrates its efficacy in shielding a Primary from interrupt interference of a NetworkBully.
3. Fig 9. that it can work even when multiple primary and secondary containers are involved.

## pinning cores for reproducibility
runall.sh does this for you. You will want to pin your cores for reproducibility. Make use of the utilities under TestFramework/Tools/

```bash
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 memcached-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 mysql-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 xapian-primary
./pincores.sh 2,4,6,8,10,12,14,16,18 clabcl1 cpubully-secondary
```


### Fig 5.

- The provided [runall.sh](../TestFramework/Experiments/runall.sh) should execute all 3 Primary workloads and generate results.
- It should also generate the plot that can be found in the [figs/](../TestFramework/Experiments/figs/) folder.
- You will find the data and results used in the paper under [final_runs](../TestFramework/Experiments/final_runs/).
- [plot_all.py](../TestFramework/Experiments/plot_all.py) can be modifed to use the existing data instead.


### Fig 8.


