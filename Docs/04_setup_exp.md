# Experiment setup

## Introduction

There 3 key results from the paper.
1. Fig 5. that shows HarvestContainers ability to harvest cores from a varied Primary workloads while still meeting SLOs.
2. Fig 8. that demonstrates its efficacy in shielding a Primary from interrupt interference of a NetworkBully.
3. Fig 9. that it can work even when multiple primary and secondary containers are involved.

The document desribes how to reproduce plots for figures -

### Fig 5.

- The provided [runall.sh](../TestFramework/Experiments/runall.sh) should execute all 3 Primary workloads and generate results.
- It should also generate the plot that can be found in the [figs/](../TestFramework/Experiments/figs/) folder.
- You will find the data and results used in the paper under [final_runs](../TestFramework/Experiments/final_runs/).
- [plot_all.py](../TestFramework/Experiments/plot_all.py) can be modifed to use the existing data instead.


### Fig 8.


