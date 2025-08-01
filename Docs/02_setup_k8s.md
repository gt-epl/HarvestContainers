# Kubernetes Setup

## Introduction
---
This document assumes we have a Cloudlab setup with all dependencies installed (including Docker and Kubernetes). In this document we will set up the Kubernetes cluster semi-automatically.

## Setup Master on clabsvr Node
- On the clabsvr node, run the following command:
```
cd /project/HarvestContainers/TestFramework/K8s
./master-setup.sh
```
- You will have to enter the IP address of the master node. If master is set up on the first Cloudlab node (clabsvr), this IP address should be `192.168.10.10`
- Be sure to note the `kubeadm join` command that the setup procedure prints out (you will need this command when setting up the client). The command looks similar to the following:
    ```bash
    kubeadm join 192.168.10.10:6443 \
        --token t96nws.p6bl55kopf44hvfu \
        --discovery-token-ca-cert-hash sha256:fe1a54199d3e99b1e4461ce2e93b5bed1b2b301cc80a7336912d15cf2645128b
    ``` 

## Setup Client on clabcl1 Node
1. First run `cd /project/HarvestContainers/TestFramework/K8s && ./client-setup-1.sh` on the clabcl1 node
2. Use sudo to run the `kubeadm join` command obtained from the output of master setup above.
3. Run `client-setup-2.sh` and enter IP of the clabcl1 node (this should be `192.168.10.11` by default)

## Verify Cluster Setup
1. On the master node (clabsvr), execute the following command to see which client nodes have been successfully added: 
    ```
    kubectl get nodes -o wide
    ```
2. If successful, you should see a node with name "clabcl1" and status "Ready"

## Next: [Setup Workload](./03_setup_workload.md)

