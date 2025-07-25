# Workload Setup

## Introduction
---

This document assumes we have a k8s cluster running on cloudlab. We will setup all the primary & secondary containers along with inputs on ramdisk for operation

> **TODO:** Push all containers to dockerhub so that docker image build setup step can be eliminated

## Primaries
---
**Xapian**
1. Build image
    ```bash
    # On k8s client node
    # build binaries
    cd /project/HarvestContainers/TestFramework/Containers/xapian/xapian-src
    bash build.sh

    # build docker image
    cd /project/HarvestContainers/TestFramework/Containers/xapian/ 
    docker build -t xapian .
    ```

2. Deploy image
    ```bash
    # On k8s master node
    # deploy container
    cd /project/HarvestContainers/TestFramework/Containers/xapian
    kubectl apply xapian_pod.yaml

    #expose service on node port
    kubectl apply xapian_svc.yaml
    ```
3. Setup inputs
    - Download xapian inputs from [tailbench](http://tailbench.csail.mit.edu/)
    - Extract the xapian directory into `/dev/shm/xapian.inputs`. Path for `terms.in` input file should read `/dev/shm/xapian.inputs/xapian/terms.in` 

**Memcached**
> TODO

**MySQL**
> TODO

## Secondaries
---
**CPUBully**
```bash
#build docker image
cd /project/HarvestContainers/TestFramework/Containers/CPUBully
docker built -t cpubully .

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
