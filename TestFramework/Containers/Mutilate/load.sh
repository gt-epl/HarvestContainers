#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../Config/MUTILATE.sh

# Uncomment to use local vars
#MUTILATE_CORE_RANGE="1-11"
#MUTILATE_THREADS="4"
#MUTILATE_CONNS="4"
#MUTILATE_DURATION="60"
MEMCACHED_SERVER="10.108.236.121"

sudo taskset -a -c ${MUTILATE_CORE_RANGE} ${WORKING_DIR}/bin/mutilate -s ${MEMCACHED_SERVER}:11211 -K fb_key -V fb_value -r 1000000 -i fb_ia --loadonly
