#!/bin/bash

source ../Config/boilerplate.sh

TEST_TYPE="BALANCER"

MEMCACHED_THREADS="8"
MEMCACHED_CONNS="8192"
MEMCACHED_RAM="32768"

MUTILATE_NODE="k8s01"

balancerTest() {
  TEST_NUM=$1
  TEST_NAME="Memcached-Bully-Harvest"

  startLogging idlecpu

  # Run Test
  echo ""
  echo "================BEGIN ${TEST_NAME}-${TRIAL_NUM}==============="
  MUTILATE_OUTPUT="mutilate.out"
  BULLY_OUTPUT="bully.out"
  OUTPUT_DIR="../Results/${TEST_TYPE}/${TEST_NAME}-${TEST_NUM}"
  mkdir -p ${OUTPUT_DIR}

  echo "[+] Starting Listener"
  runListener
  echo "[+] Sending Pod ID to Listener"
  sendPodId

  echo "[+] Running ${TEST_TYPE} Benchmark: ${TEST_NAME}-${TEST_NUM}"
  runBullyContainer
  sleep 1
  SECONDARY_PID=-1
  runBalancer
  # Start memcached container
  docker run --rm -p 11211:11211 --cpuset-cpus=${CORE_RANGE} --name memcache_test memcached memcached -t ${MEMCACHED_THREADS} -c ${MEMCACHED_CONNS} -m ${MEMCACHED_RAM} -v
  # Run mutilate on remote node to query memcached
  #ssh -i ${TASKMASTER_KEY} ${MUTILATE_NODE} '${WORKING_DIR}/bin/run_mutilate.sh' 2>&1 > ${OUTPUT_DIR}/mutilate.console
  # Run mutilate on local node's 2nd socket to query memcached
  ${WORKING_DIR}/bin/run_mutilate.sh

  # Gather results
  stopLogging idlecpu
  stopModule idlecpu
  sleep 3
  sudo kill -10 `pgrep balancer`
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv *.out ${OUTPUT_DIR}/
  mv *.log ${OUTPUT_DIR}/
  scp -i ${TASKMASTER_KEY} ${MUTILATE_NODE}:${WORKING_DIR}/Results/mutilate.log ${OUTPUT_DIR}/
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