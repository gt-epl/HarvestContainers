#!/bin/bash

source ../../bin/boilerplate.sh
source ../../Config/MUTILATE.sh

START_QPS="100000"
STOP_QPS="250000"
STEP_QPS="10000"

MUTILATE_RECORDS="1000000"
MUTILATE_DURATION="60"

OUTPUT_DIR="${WORKING_DIR}/Results/Memcached/Baseline/${START_QPS}-${STOP_QPS}-${STEP_QPS}"
mkdir -p ${OUTPUT_DIR}

echo "[+] Benchmarking reads from memcached"

cd ${WORKING_DIR}/Containers/memcached/

loadModule idlecpu
startModule idlecpu
sleep 1
startLogging idlecpu

echo "[+] Scanning memcached QPS range ${START_QPS}:${STOP_QPS}"
sudo taskset -a -c ${MUTILATE_CORE_RANGE} ${WORKING_DIR}/bin/mutilate -s ${MEMCACHED_SERVER}:11211 --noload -K fb_key -V fb_value -r ${MUTILATE_RECORDS} -i fb_ia -T ${MUTILATE_THREADS} -c ${MUTILATE_CONNS} -u 0.00 -d 1 --scan=${START_QPS}:${STOP_QPS}:${STEP_QPS} --blocking 2>${OUTPUT_DIR}/mutilate-stderr.log 1>${OUTPUT_DIR}/mutilate-stdout.log

stopLogging idlecpu
stopModule idlecpu
sleep 3
echo "[+] Retrieving cpulogger.log"
getLoggerLog idlecpu ${OUTPUT_DIR}
sleep 1
unloadModule idlecpu
echo "[+] Done."
