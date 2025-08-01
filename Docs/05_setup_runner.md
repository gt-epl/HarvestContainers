# Test Runners

## Introduction
Test runners are currently designed to be executed from the clabcl1 that hosts Primary and Secondary containers. Therefore, this document consists of steps to be executed on this specific node (unless explicitly mentioned otherwise). Most test runners have a similar design and follows the below automated workflow:
1. Start the Listener, Monitor and Balancer components
2. Start the Primary workload
3. Start the Secondary workload (skip if Baseline test)
4. Stop the Listener, Monitor and Balancer components
5. Collect the logs under:
   1.  `/mnt/extra/logs` for system logs
   2.  `/mnt/extra/results` for application centric output and results e.g., latency
6. All runner files are of the format `<primary_application>_runner.sh`. Command line arguments for that file maybe found within that file. But are of the following format:
    ```bash
    ./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>
    ```
7. All secondary runners are specified within `secondary.sh`. Default is `CPUBully`
8. Runner files are within `~/HarvestContainers/TestFramework/Experiment`

## Per application Setup Steps
1. Prepare the HarvestContainers compontents on clabcl1. 
   ```bash
   cd /project/HarvestContainers/TestFramework/Experiment
   ./setup-bins.sh
   ```
2. Ensure appropriate configs in `~/HarvestContainers/TestFramework/Config/SYSTEM.sh`. The default should work for the provided cloudlab profile.
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

3. Create the following directory if not present:
   1. `/mnt/extra/logs`
   2. `/mnt/extra/results`
   3. `/mnt/extra/config`

4. Inspect `<app>_runner.sh` file and run. 



## Application specifition info

### Xapian
Currently xapian runs in integrated mode i.e. client and server are packaged in the same binary and hence no external client is necessary.

### Memcached
Memcached utilizes mutilate running on clabsvr so that clients do not interfere with the memcached server. Therfore, all latency results are hosted on clabsvr

### MySQL
Similar to Memcached, MySQL utilizes ycsb that runs on clabsvr and outputs the results on the same.
   