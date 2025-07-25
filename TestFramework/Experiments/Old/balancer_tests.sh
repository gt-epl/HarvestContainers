#!/bin/bash

source ../Config/boilerplate.sh

TEST_TYPE="BALANCER"

cfsTest() {
  TEST_NUM=$1
  TRIAL_NUM=$2
  TEST_NAME="Test-${TEST_NUM}"

  startLogging idlecpu

  # Run Test
  echo ""
  echo "================BEGIN ${TEST_NAME}-${TRIAL_NUM}==============="
  CONFIG_NAME="/Config/${TEST_NAME}/config.json"
  PRIMARY_OUTPUT="primary.out"
  SECONDARY_OUTPUT="secondary.out"
  OUTPUT_DIR="../Results/Balancer/${TEST_NAME}-${TRIAL_NUM}"
  mkdir -p ${OUTPUT_DIR}
  echo "[+] Running CFS Benchmark: ${TEST_NAME}-${TRIAL_NUM}"
  runBullyContainer
  sleep 1
  SECONDARY_RUNNING=$(docker inspect -f '{{.State.Running}}' bully_secondary)
  until [ "${SECONDARY_RUNNING}"=="true" ]
  do
    sleep 0.1
    SECONDARY_RUNNING=$(docker inspect -f '{{.State.Running}}' bully_secondary)
  done
  SECONDARY_PID=$(docker inspect -f '{{.State.Pid}}' bully_secondary)
  runLSContainer ${CONFIG_NAME} fg

  # Gather results
  stopLogging idlecpu
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv ${WORKING_DIR}/Containers/LatSensitive/results.csv ${OUTPUT_DIR}/
  mv *.out ${OUTPUT_DIR}/
  mv *.log ${OUTPUT_DIR}/

  echo "================END ${TEST_NAME}-${TRIAL_NUM}==============="
  echo ""
  sleep 3
}

balancerTest() {
  TEST_NUM=$1
  TRIAL_NUM=$2
  TEST_NAME="Test-${TEST_NUM}"

  startLogging idlecpu

  # Run Test
  echo ""
  echo "================BEGIN ${TEST_NAME}-${TRIAL_NUM}==============="
  CONFIG_NAME="/Config/${TEST_NAME}/config.json"
  PRIMARY_OUTPUT="primary.out"
  SECONDARY_OUTPUT="secondary.out"
  OUTPUT_DIR="../Results/Balancer/${TEST_NAME}-${TRIAL_NUM}"
  mkdir -p ${OUTPUT_DIR}
  echo "[+] Running Balancer Benchmark: ${TEST_NAME}-${TRIAL_NUM}"
  runBullyContainer
  sleep 1
  SECONDARY_RUNNING=$(docker inspect -f '{{.State.Running}}' bully_secondary)
  until [ "${SECONDARY_RUNNING}"=="true" ]
  do
    sleep 0.1
    SECONDARY_RUNNING=$(docker inspect -f '{{.State.Running}}' bully_secondary)
  done
  SECONDARY_PID=$(docker inspect -f '{{.State.Pid}}' bully_secondary)
  runBalancer
  runLSContainer ${CONFIG_NAME} fg

  # Gather results
  stopLogging idlecpu
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv ${WORKING_DIR}/Containers/LatSensitive/results.csv ${OUTPUT_DIR}/
  mv *.out ${OUTPUT_DIR}/
  mv *.log ${OUTPUT_DIR}/

  echo "================END ${TEST_NAME}-${TRIAL_NUM}==============="
  echo ""
  sleep 3
}

loadModule idlecpu
startModule idlecpu

echo ""
echo "[+] Starting Balancer Benchmarks"
echo ""
for testNum in {1..9}
do
  # Trial 1 - CFS Only, 11 Workers
  SECONDARY_WORKERS="11"
  cfsTest ${testNum} 1
  sleep 3
  echo ""
  # Trial 2 - CFS Only, 23 Workers
  SECONDARY_WORKERS="23"
  cfsTest ${testNum} 2
  sleep 3
  echo ""
  # Trial 3 - Balancer, 11 Workers
  SECONDARY_WORKERS="11"
  balancerTest ${testNum} 3
  sleep 3
  echo ""
  # Trial 4 - Balancer, 23 Workers
  SECONDARY_WORKERS="23"
  balancerTest ${testNum} 4
  sleep 3
  echo ""
done

echo ""
echo "[+] Balancer Benchmarks Completed."
echo ""

stopModule idlecpu
unloadModule idlecpu
