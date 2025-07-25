#!/bin/bash

source ../Config/boilerplate.sh

TEST_TYPE="BASELINE"

sampleTest() {
  TEST_NAME=$1
  CONFIG_NAME="/Config/${TEST_NAME}/config.json"
  PRIMARY_OUTPUT="ls_${TEST_TYPE}_${TEST_NAME}.out"
  OUTPUT_DIR="Results/IdleCPUSampleRate/${TEST_NAME}"
  mkdir -p ${OUTPUT_DIR}
  runLSContainer ${CONFIG_NAME}
  sleep 15
  startLogging idlecpu
  sleep 5
  stopLogging idlecpu
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv ${WORKING_DIR}/Containers/LatSensitive/results.csv ${OUTPUT_DIR}/
  mv *.out ${OUTPUT_DIR}/
  sleep 3
}

loadModule idlecpu
startModule idlecpu

sampleTest Test-1
sleep 3
echo ""

stopModule idlecpu
unloadModule idlecpu
