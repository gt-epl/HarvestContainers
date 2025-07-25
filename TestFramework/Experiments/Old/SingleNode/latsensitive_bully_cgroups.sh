#!/bin/bash

source ../Config/boilerplate.sh

TEST_TYPE="CGROUP"

cgroupTest() {
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
  echo "[+] Running ${TEST_TYPE} Benchmark: ${TEST_NAME}-${TEST_NUM}"
  # Run Bully container with cgroups in place
  docker run --cpu-shares=512 --cpu-quota=1000 --cpu-period=2000 --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name bully_secondary --rm ${BULLY_CNTR} ${BULLY_WORKERS} 1 CPUBoundSum 2>&1 > ${BULLY_OUTPUT} &
  runLSContainer ${CONFIG_NAME} fg

  # Gather results
  stopLogging idlecpu
  stopModule idlecpu
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv ${WORKING_DIR}/Containers/LatSensitive/results.csv ${OUTPUT_DIR}/
  mv *.out ${OUTPUT_DIR}/
  mv *.log ${OUTPUT_DIR}/

  echo "================END ${TEST_NAME}-${TEST_NUM}==============="
  echo ""
  sleep 3
}

loadModule idlecpu
startModule idlecpu

echo ""
echo "[+] Starting ${TEST_TYPE} Benchmarks"
echo ""
# Trial 1 - cgroups, 11 Workers
testNum="1"
BULLY_WORKERS="11"
cgroupTest ${testNum}
sleep 3
echo ""

echo ""
echo "[+] ${TEST_TYPE} Benchmarks Completed."
echo ""

unloadModule idlecpu