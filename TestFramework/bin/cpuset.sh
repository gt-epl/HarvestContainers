#!/bin/bash

POD_ID=$1
CPUSET=$2

cd /sys/fs/cgroup/cpuset/kubepods/besteffort/pod${POD_ID}/

for d in */
do
    echo "[+] Updating cpuset.cpus for container ${d}:"
    echo ${CPUSET} | sudo tee ${d}/cpuset.cpus
    echo ""
done
