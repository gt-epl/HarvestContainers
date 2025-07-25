#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../Config/MUTILATE.sh

# Uncomment to use local vars
MUTILATE_CORE_RANGE="7-12"
MUTILATE_THREADS="6"
MUTILATE_CONNS="1"
MUTILATE_DURATION="120"
MEMCACHED_SERVER="10.108.236.121"
MUTILATE_RECORDS="1000000"

MUTILATE_QPS=$1

sudo rm -f ${WORKING_DIR}/Results/Mutilate/mutilate.log

sudo taskset -a -c ${MUTILATE_CORE_RANGE} ${WORKING_DIR}/bin/mutilate -s ${MEMCACHED_SERVER}:11211 --noload -K fb_key -V fb_value -r ${MUTILATE_RECORDS} -i fb_ia -T ${MUTILATE_THREADS} -c ${MUTILATE_CONNS} -u 0.00 -d 1 -q ${MUTILATE_QPS} --time=${MUTILATE_DURATION}
