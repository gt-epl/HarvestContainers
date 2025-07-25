#!/bin/bash

#source ../../bin/boilerplate.sh

WORKING_DIR="/home/ach/Workspace/TestFramework"

if [ -z "$1" ]
then
    echo "Please specify TRIAL name"
    exit
fi

if [ -z "$2" ]
then
    echo "Please specify QPS"
    exit
fi

TRIAL=$1

MUTILATE_QPS="100000"
#MUTILATE_QPS=$2
MUTILATE_RECORDS="1000000"
MUTILATE_DURATION="60"

MUTILATE_CORE_RANGE="1-4"
MUTILATE_THREADS="4"
MUTILATE_CONNS="4"
MUTILATE_DURATION="60"
MEMCACHED_SERVER="10.108.173.137"

OUTPUT_DIR="${WORKING_DIR}/Results/Memcached/Baseline/${MUTILATE_QPS}/${TRIAL}"
mkdir -p ${OUTPUT_DIR}

echo "[+] Benchmarking reads from memcached"

cd ${WORKING_DIR}/Containers/memcached/

#loadModule idlecpu
#startModule idlecpu
#sleep 1
#startLogging idlecpu

sudo taskset -a -c ${MUTILATE_CORE_RANGE} ${WORKING_DIR}/bin/mutilate -s ${MEMCACHED_SERVER}:11211 --noload -K fb_key -V fb_value -r ${MUTILATE_RECORDS} -i fb_ia -T ${MUTILATE_THREADS} -c ${MUTILATE_CONNS} -u 0.00 -d 1 -q ${MUTILATE_QPS} --time=${MUTILATE_DURATION} --blocking --save=${OUTPUT_DIR}/mutilate.log 2>${OUTPUT_DIR}/stderr.log 1>${OUTPUT_DIR}/stdout.log

#stopLogging idlecpu
#stopModule idlecpu
#sleep 3
#echo "[+] Retrieving cpulogger.log"
#getLoggerLog idlecpu ${OUTPUT_DIR}
#sleep 1
#unloadModule idlecpu
#echo "[+] Done."
