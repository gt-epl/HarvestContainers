#!/bin/bash

export LD_LIBRARY_PATH=$PWD/xapian-core-1.2.13/install/lib/

TBENCH_QPS=5000 \
TBENCH_MAXREQS=300000 \
TBENCH_WARMUPREQS=10000 \
TBENCH_MINSLEEPNS=100000 \
TBENCH_RANDSEED=123 \
TBENCH_TERMS_FILE=/dev/shm/xapian.inputs/xapian/terms.in \
taskset --cpu-list 2,4,6,8,10,12,14,16 ./xapian_integrated -n 8 -d /dev/shm/xapian.inputs/xapian/wiki -r 1000000000

