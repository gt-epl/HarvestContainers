#!/bin/bash

source ../../Config/boilerplate.sh

MEMCACHED_THREADS=8
MEMCACHED_CONNS=4096
MEMCACHED_RAM=8192

MUTILATE_CORE_RANGE="28-47"
MUTILATE_THREADS="20"
MUTILATE_CONNS="20"
MUTILATE_DURATION="60"
MEMCACHED_SERVER="127.0.0.1"

rm -f ${WORKING_DIR}/Results/mutilate.log

loadModule idlecpu

runMemcachedContainer bg ${MEMCACHED_THREADS} ${MEMCACHED_CONNS} ${MEMCACHED_RAM}

# Load mutilate data first
sudo taskset -a -c ${MUTILATE_CORE_RANGE} ./mutilate/mutilate -s ${MEMCACHED_SERVER} --loadonly

startLogging idlecpu

sudo taskset -a -c ${MUTILATE_CORE_RANGE} ./mutilate/mutilate -s ${MEMCACHED_SERVER} --noload -T ${MUTILATE_THREADS} -c ${MUTILATE_CONNS} -V fb_value -i fb_ia -K fb_key -t ${MUTILATE_DURATION} --save=${WORKING_DIR}/Results/mutilate.log

stopLogging idlecpu
stopModule idlecpu
getLoggerLog idlecpu ${WORKING_DIR}/Results/cpulogger.log
unloadModule idlecpu