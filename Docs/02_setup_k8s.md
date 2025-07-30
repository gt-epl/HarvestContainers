# Kubernetes Setup

## Introduction
---
This document assumes we have a cloudlab setup with all deps installed (including docker and k8s). In this document we setup the k8s cluster semi-automatically.

## Setup master on clabsvr
```
cd /project/HarvestContainers/TestFramework/K8s
./master-setup.sh
```
- You will have to enter the ip of the node. If master is setup on the first cloudlab node. This is `192.168.10.10`

## Setup client on clabcl1
1. First run `client-setup-1.sh`
2. Run the join command as obtained in the output of master setup above.
    1. On the console, join command will appear as follows:
    ```bash
    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join 192.168.10.10:6443 \
        --token t96nws.p6bl55kopf44hvfu \
        --discovery-token-ca-cert-hash sha256:fe1a54199d3e99b1e4461ce2e93b5bed1b2b301cc80a7336912d15cf2645128b
    ``` 
3. Run `client-setup-2.sh` and enter IP of the cloudlab node. (This should be `192.168.10.11`)

## Verify cluster.
1. On master node. Execute follow to see nodes added - 
    ```
    kubectl get nodes -o wide
    ```

## Next: setup experiment runners

