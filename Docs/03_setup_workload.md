# Workload Setup

## Introduction

This document assumes we have a Kubernetes (K8s) cluster running on Cloudlab. We will setup all the Primary & Secondary containers along with their associated input data.

If SSH aliases are set up, then the below helper script will install and configure the workloads. It should be run on the clabcl1 node:

**Automated Helper Script:** [../TestFramework/Experiments/setup_workload.sh](../TestFramework/Experiments/setup_workload.sh)


 All Primary and Secondary workloads have been Dockerized and hosted on DockerHub. If you wish to build your own images, Dockerfiles are provided for workloads and are present under [../TestFramework/Containers/](../TestFramework/Containers/).

Continue to perform the steps below for manual setup if you do not wish to run `setup_workload.sh`, or skip to [Running Experiments](./04_setup_exp.md) for artifact evaluation.

## Primaries

### Xapian

1. [~2 min] Pull image on clabcl1.
    ```bash
    docker pull asarma31/xapian-primary:latest
    ```
2. Deploy image via kubectl on clabsvr 
    ```bash
    # On clabsvr
    cd ~/HarvestContainers/TestFramework/Containers/xapian
    kubectl apply xapian-primary_pod.yaml

    # expose service on node port
    kubectl apply xapian-primary_svc.yaml
    ```
3. [~14 min] Setup inputs on clabcl1 node
    - [~11 min] Download Xapian inputs from [Tailbench](http://tailbench.csail.mit.edu/)
        ```bash
        cd /mnt/extra
        wget https://tailbench.csail.mit.edu/tailbench.inputs.tgz
        ```
    - [~3 min] Extract the Xapian directory into `/dev/shm/xapian.inputs`. Path for `terms.in` input file should read `/dev/shm/xapian.inputs/xapian/terms.in` 
        ```bash
        tar -xvf tailbench.inputs.tgz tailbench.inputs/xapian
        mkdir -p /dev/shm/xapian.inputs && cp -r tailbench.inputs/xapian /dev/shm/xapian.inputs/
        ```

### Memcached
1. [~2 min] Pull image clabcl1.
    ```bash
    docker pull asarma31/memcached-primary:latest
    ```
2. Deploy image via kubectl on clabsvr 
    ```bash
    # On clabsvr
    cd ~/HarvestContainers/TestFramework/Containers/memcached
    kubectl apply memcached-primary_pod.yaml

    # expose service on node port
    kubectl apply memcached-primary_svc.yaml
    ```
3. [~2 min] Setup mutilate load client on clabsvr and clabcl1
    ```bash
    # On clabsvr and clabcl1
    cd ~/HarvestContainers/TestFramework/Containers/memcached/mutilate
    docker pull asarma31/mutilate:latest
    
    # On clabsvr
    kubectl apply -f mutilate_pod.yaml
    kubectl apply -f mutilate_svc.yaml
    kubectl apply -f mutilate_cl1_pod.yaml
    kubectl apply -f mutilate_cl1_svc.yaml
    ```

4. [~5 sec] Load dataset
    ```bash
    curl --data "{\"memcached_server\":\"192.168.10.11:31212\"}" --header "Content-Type: application/json" http://192.168.10.10:32003/load
    ```

### MySQL
1. [~2 min] Pull image on clabcl1.
    ```bash
    docker pull mysql:5.7
    ```
2. Deploy image via kubectl on clabsvr 
    ```bash
    # On clabsvr
    cd ~/HarvestContainers/TestFramework/Containers/MySQL
    kubectl apply mysql-primary_pod.yaml

    #expose service on node port
    kubectl apply mysql-primary_svc.yaml
    ```
3. [~2 min] Setup ycsb load client on clabsvr and clabcl1
    ```bash
    # On clabsvr and clabcl1
    cd ~/HarvestContainers/TestFramework/Containers/MySQL/ycsb
    docker pull asarma31/ycsb:latest
    # On clabsvr
    kubectl apply -f ycsb_pod.yaml
    kubectl apply -f ycsb_svc.yaml
    kubectl apply -f ycsb_cl1_pod.yaml
    kubectl apply -f ycsb_cl1_svc.yaml
    ```

4. [~2 min] Load dataset
    ```bash
    curl --data "{\"mysql_server\":\"192.168.10.11:32306\"}" --header "Content-Type: application/json" http://192.168.10.10:32002/load
    ```

## Secondaries
### CPUBully
```bash
# On clabcl1, pull docker image
docker pull asarma31/cpubully:latest

# On clabsvr, deploy container
cd ~/HarvestContainers/TestFramework/Containers/CPUBully
kubectl apply cpubully-secondary_pod.yaml

# Expose service on node port
kubectl apply cpubully-secondary_svc.yaml
```
### NetworkBully
```bash
# On clabcl1, pull docker image
docker pull asarma31/nwbully-secondary:latest

# On clabsvr, deploy container
cd ~/HarvestContainers/TestFramework/Containers/NetworkBully
kubectl apply nwbully-secondary_pod.yaml

# Expose service on node port
kubectl apply nwbully-secondary_svc.yaml
```

### x264
```bash
# On clabcl1, pull docker image
docker pull asarma31/x264-secondary:latest

# On clabsvr, deploy container
cd ~/HarvestContainers/TestFramework/Containers/x264
kubectl apply x264-secondary_pod.yaml

# Expose service on node port
kubectl apply x264-secondary_svc.yaml
```

### Dedup
```bash
# On clabcl1, pull docker image
docker pull asarma31/dedup-secondary:latest

# On clabsvr, deploy container
cd ~/HarvestContainers/TestFramework/Containers/dedup
kubectl apply dedup-secondary_pod.yaml

# Expose service on node port
kubectl apply dedup-secondary_svc.yaml
```


## Misc.
1. Install remnant dependencies on clabcl1 and clabsvr
```bash
pip install scipy pandas matplotlib
```
2. Create directories for storing experiment output (logs and results) by running [../TestFramework/Experiments/create-output-dirs.sh](../TestFramework/Experiments/create-output-dirs.sh).

## Next: [Setup Experiments](./04_setup_exp.md)
