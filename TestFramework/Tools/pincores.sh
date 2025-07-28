#!/usr/bin/env bash

# e.g. ./pinmc.sh 0-7 clabcl0 img-dnn

CPUSET=$1 #format = "low-high" i.e. low,high are inclusive
NODE=$2 #k8sclient
MASTER="clabsvr"
APP=$3

if [ -z $APP ]; then
  APP="img-dnn-primary"
fi

PODFILE=${APP}_podinfo.txt
if [ ! -f $PODFILE ]; then
  bash get_pod_info.sh $MASTER $APP
  sz=$(wc -c $PODFILE | awk '{print $1}')
  echo $sz
  if [ $sz -eq 1 ]; then
    echo "[!] error retrieving pod info for $APP."
    exit 1;
  fi
fi

POD_ID="pod$(cat $PODFILE | jq -r .metadata.uid)"
CONTAINER_ID=$(cat $PODFILE | jq -r .status.containerStatuses[0].containerID | cut -c 10-)

if [ ! -z $CPUSET ]; then
  echo "[+] Retrieve container info from master"

  echo "[+] Modify cpuset of container"
  ssh $NODE bash <<EOF
  echo $CPUSET | sudo tee /sys/fs/cgroup/cpuset/kubepods/besteffort/${POD_ID}/${CONTAINER_ID}/cpuset.cpus
EOF

else
  echo "[ERR]: cpuset empty"
fi
