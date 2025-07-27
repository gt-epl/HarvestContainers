# Workload Setup

## Introduction
---

This document assumes we have a k8s cluster running on cloudlab. We will setup all the primary & secondary containers along with inputs on ramdisk for operation

## Primaries
---
**Xapian**

1. [~2 min] Pull image on clabcl1. For building imaging, see [building images](#building-images)
    ```bash
    docker pull asarma31/xapian-primary:latest
    ```
1. Deploy image via kubectl on clabsvr 
    ```bash
    # On clabsvr
    cd ~/HarvestContainers/TestFramework/Containers/xapian
    kubectl apply xapian_pod.yaml

    #expose service on node port
    kubectl apply xapian_svc.yaml
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


## Building images

### Xapian
```bash
# On k8s client node
# build binaries
cd ~/HarvestContainers/TestFramework/Containers/xapian/xapian-src
bash build.sh

# build docker image
cd /project/HarvestContainers/TestFramework/Containers/xapian/ 
docker build -t dockerhub_username/xapian:latest .
```
