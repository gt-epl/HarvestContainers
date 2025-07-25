#!/bin/bash

source ../../bin/boilerplate.sh
source ../../Config/MUTILATE.sh

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

if [ -z "$3" ]
then
    echo "Please specify testNum"
    exit
fi

if [ -z "$4" ]
then
    echo "Please specify TARGET_IDLE_CORES"
    exit
fi

TRIAL=$1

TEST_TYPE="Memcached"
# e.g., MUTILATE_QPS=100000
MUTILATE_QPS=$2
# e.g., testNum=25k
testNum=$3
TARGET_IDLE_CORES=$4

runMutilate() {
  MUTILATE_RECORDS="1000000"
  MUTILATE_DURATION="60"

  echo "[+] Benchmarking reads from memcached"

  cd ${WORKING_DIR}/Containers/memcached/

  sudo taskset -a -c ${MUTILATE_CORE_RANGE} ${WORKING_DIR}/bin/mutilate -s ${MEMCACHED_SERVER}:11211 --noload -K fb_key -V fb_value -r ${MUTILATE_RECORDS} -i fb_ia -T ${MUTILATE_THREADS} -c ${MUTILATE_CONNS} -u 0.00 -d 1 -q ${MUTILATE_QPS} --time=${MUTILATE_DURATION} --blocking --save=${OUTPUT_DIR}/mutilate.log 2>${OUTPUT_DIR}/mutilate-stderr.log 1>${OUTPUT_DIR}/mutilate-stdout.log
}

balancerTest() {
  TEST_NUM=$1
  TEST_NAME="Memcached-Bully-Harvest"

  startLogging idlecpu

  # Run Test
  echo ""
  echo "================BEGIN ${TEST_NAME}-${TRIAL_NUM}==============="
  BULLY_OUTPUT="cpubully.out"
  OUTPUT_DIR="${WORKING_DIR}/Results/${TEST_TYPE}/${TRIAL}/${testNum}/${TEST_NAME}-${TARGET_IDLE_CORES}" 
  mkdir -p ${OUTPUT_DIR}

  echo "[+] Starting Listener"
  runListener
  echo "[+] Sending Pod ID to Listener"
  sendPodId

  echo "[+] Running ${TEST_TYPE} Benchmark: ${TEST_NAME}-${TEST_NUM}"
  runCPUBullyContainer
  #sleep 1
  SECONDARY_PID=-1
  runBalancer

  # Run Mutilate
  runMutilate

  sleep 5
  cd ${WORKING_DIR}/Experiments/memcached
  # Gather results
  stopLogging idlecpu
  stopModule idlecpu
  sleep 3
  sudo kill -10 `pgrep balancer`
  while balancerRunning
  do
    sleep 1
  done
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv *.out ${OUTPUT_DIR}/
  mv *.log ${OUTPUT_DIR}/
  sudo kill -10 `pgrep listener`

  echo "================END ${TEST_NAME}-${TEST_NUM}==============="
  echo ""
  sleep 3
}

loadModule idlecpu
startModule idlecpu

echo ""
echo "[+] Starting ${TEST_TYPE} Benchmarks"
echo ""

# Trial 1 - Balancer, 11 Workers
BULLY_WORKERS="11"
balancerTest ${testNum}
sleep 3
echo ""

echo ""
echo "[+] ${TEST_TYPE} Benchmarks Completed."
echo ""

unloadModule idlecpu