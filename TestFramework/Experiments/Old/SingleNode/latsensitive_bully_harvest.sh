#!/bin/bash

source ../Config/boilerplate.sh

TEST_TYPE="HARVEST"

balancerTest() {
  TEST_NUM=$1
  TEST_NAME="8kQPS-4workers"

  startLogging idlecpu

  # Run Test
  echo ""
  echo "================BEGIN ${TEST_NAME}-${TEST_NUM}==============="
  CONFIG_NAME="/Config/${TEST_NAME}/config.json"
  LS_OUTPUT="latsensitive.out"
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
  runLSContainer ${CONFIG_NAME} fg

  # Gather results
  stopLogging idlecpu
  stopModule idlecpu
  sleep 3
  sudo kill -10 `pgrep balancer`
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv ${WORKING_DIR}/Containers/LatSensitive/results.csv ${OUTPUT_DIR}/
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