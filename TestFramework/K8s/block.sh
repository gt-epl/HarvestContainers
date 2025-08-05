#!/bin/bash

echo "[+] Install crds"
kubectl apply -f calico-crds.yaml


nodes=($(kubectl get nodes --no-headers | awk '{print $1}'))
if [ ${#nodes[@]} -lt 2 ]; then
  echo "Error: Need at least two nodes to map to CLABSVR and CLABCL1"
  exit 1
fi

SVR_NODE="${nodes[0]}"
CL1_NODE="${nodes[1]}"

sed "s/CLABSVR/$SVR_NODE/g; s/CLABCL1/$CL1_NODE/g" block.yaml | kubectl apply -f -
