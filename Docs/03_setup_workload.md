# Workload Setup

## Introduction

This document assumes we have a k8s cluster running on cloudlab. We will setup all the primary & secondary containers along with inputs on ramdisk for operation.

If ssh aliases are setup, then the below helper script should setup the workloads.

**Automated Helper script:** [../TestFramework/Experiments/setup_workload.sh](../TestFramework/Experiments/setup_workload.sh)


 All primary and secondary workloads have been dockerized and hosted on dockerhub. If you wish to build your own images, Dockerfiles are provided for workloads are present under [../TestFramework/Containers/](../TestFramework/Containers/).

Continue for manual setup or skip to [Running experiments](./setup_runner.md).

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

    #expose service on node port
    kubectl apply xapian-primary_svc.yaml
    ```
3. [~14 min] Setup inputs on clabcl1 node
    - [~11 min] Download xapian inputs from [tailbench](http://tailbench.csail.mit.edu/)
        ```bash
        cd /mnt/extra
        wget https://tailbench.csail.mit.edu/tailbench.inputs.tgz
        ```
    - [~3 min] Extract the xapian directory into `/dev/shm/xapian.inputs`. Path for `terms.in` input file should read `/dev/shm/xapian.inputs/xapian/terms.in` 
        ```bash
        tar -xvf tailbench.inputs.tgz tailbench.inputs/xapian
        mkdir -p /dev/shm/xapian.inputs && cp -r tailbench.inputs/xapian /dev/shm/xapian.inputs/
        ```

### Memcached
1. [~2 min] Pull image on clabcl1.
    ```bash
    docker pull asarma31/memcached-primary:latest
    ```
2. Deploy image via kubectl on clabsvr 
    ```bash
    # On clabsvr
    cd ~/HarvestContainers/TestFramework/Containers/memcached
    kubectl apply memcached-primary_pod.yaml

    #expose service on node port
    kubectl apply memcached-primary_svc.yaml
    ```
3. [~2 min] Setup mutilate load client on clabsvr
    ```bash
    cd ~/HarvestContainers/TestFramework/Containers/memcached/mutilate
    docker pull asarma31/mutilate:latest
    kubectl apply -f mutilate_pod.yaml
    kubectl apply -f mutilate_svc.yaml
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
3. [~2 min] Setup ycsb load client on clabsvr
    ```bash
    cd ~/HarvestContainers/TestFramework/Containers/MySQL/ycsb
    docker pull asarma31/ycsb:latest
    kubectl apply -f mutilate_pod.yaml
    kubectl apply -f mutilate_svc.yaml
    ```

4. [~2 min] Load dataset
    ```bash
    curl --data "{\"mysql_server\":\"192.168.10.11:32306\"}" --header "Content-Type: application/json" http://192.168.10.10:32002/load
    ```

## Secondaries
### CPUBully
```bash
#build docker image
docker pull asarma31/cpubully:latest

#on master node deploy container
cd /project/HarvestContainers/TestFramework/Containers/CPUBully
kubectl apply cpubully-secondary_pod.yaml

#expose service on node port
kubectl apply cpubully-secondary_svc.yaml
```

**x264**
>TODO

**Dedup**
>TODO


## Misc.
1. Install remnant dependencies on clabcl1 and clabsvr
```bash
pip install scipy pandas
```

## Next: [Setup Experiments](./setup_runner.md)
