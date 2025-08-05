# Test Runners

## Introduction
Test runners are currently designed to be executed from the clabcl1 node that hosts Primary and Secondary containers. Therefore, this document consists of steps to be executed on this specific node (unless explicitly mentioned otherwise). Most test runners have a similar design that follows the below automated workflow:
1. Start the Monitor, Listener, and Balancer components (in order)
2. Start the Primary workload
3. Start the Secondary workload (skip if Baseline test)
4. Stop the Monitor, Listener and Balancer components
5. Collect the logs under:
   1.  `/mnt/extra/logs` for system logs
   2.  `/mnt/extra/results` for application centric output and results (e.g., latency)
6. All runner scripts have the naming convention `<primary_application>_runner.sh`. Command line arguments for that file maybe found within that file, and generally have the following format:
    ```bash
    ./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest | baseline>
    ```
7. All Secondary runners are specified in the `secondary.sh` script. The default Secondary is `CPUBully`.
8. Runner files are located within `~/HarvestContainers/TestFramework/Experiment`

## Per Application Setup Steps
1. Prepare the HarvestContainers components on the clabcl1 node: 
   ```bash
   cd /project/HarvestContainers/TestFramework/Experiment
   ./setup-bins.sh
   ```
2. Ensure the appropriate config settings are in `~/HarvestContainers/TestFramework/Config/SYSTEM.sh`. The defaults should work for the provided Cloudlab profile (c6420 hardware).
   1.  Navigate to below snipped in config:
         ```bash
         if [ "${ENV_TYPE}" == "CLOUDLAB" ]
         then
            WORKING_DIR="~/HarvestContainers/TestFramework"
            CPULIST="2,4,6,8,10,12,14,16" # <-- this ensures 8 cores NUMA node 0 are used.
            SECONDARY_CPULIST="18"
            MONITOR_BINDCPU="24"
            BALANCER_BINDCPU="26"
            LISTENER_BINDCPU="28"
            CORE_RANGE="1-8"      #unused
            NUM_CORES="8"         #unused
            CPU_FREQ="2600000"
         fi
         ```
   2. Ensure `CPULIST` is appropriate for the machine type. For e.g., `c6420` has even cpu# on socket 0.
   3. Ensure `(MONTOR/BALANCER/LISTENER)_BINDCPU` are pinned to cores on same socket (e.g., 0) but different from the `CPULIST`

3. Create the following directories if not present (you may also do this by running [../TestFramework/Experiments/create-output-dirs.sh](../TestFramework/Experiments/create-output-dirs.sh):
   1. `/mnt/extra/logs`
   2. `/mnt/extra/results`
   3. `/mnt/extra/config`

4. Inspect `<app>_runner.sh` file and run. 



## Application Specific Info

### Xapian
Currently Xapian runs in integrated mode (i.e., client and server are packaged in the same binary and hence no external client is necessary).

### Memcached
Memcached utilizes the mutilate workload generator running on the clabsvr node so that clients do not interfere with the memcached server. Therfore, all latency results from experiments will appear on the clabsvr node.

### MySQL
Similar to Memcached, MySQL utilizes the ycsb workload generator running on the clabsvr node. Latency results from experiments will appear on this node.
   
