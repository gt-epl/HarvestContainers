#!/usr/bin/env bash 

NUMCPUS=$(cat /proc/cpuinfo | grep processor | wc -l)
FREQ="2.6GHz"

#command to check frequency @NODE
# watch -n.1 "grep \"^[c]pu MHz\" /proc/cpuinfo"


# modify cpu 1 by 1
for ((i=0;i<$NUMCPUS;i++)); do
  sudo cpufreq-set -c $i -g userspace
  sudo cpufreq-set -c $i -f $FREQ
done
