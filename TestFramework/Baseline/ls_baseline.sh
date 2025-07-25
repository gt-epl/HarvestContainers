#!/bin/bash

source ../Config/boilerplate.sh

TEST_TYPE="BASELINE"

lsTest() {
  TEST_NAME=$1

  startLogging idlecpu

  CONFIG_NAME="/Config/${TEST_NAME}/config.json"
  PRIMARY_OUTPUT="ls_${TEST_TYPE}_${TEST_NAME}.out"
  OUTPUT_DIR="Results/LatSensitive/${TEST_NAME}"
  mkdir -p ${OUTPUT_DIR}
  runLSContainer ${CONFIG_NAME} fg

  stopLogging idlecpu
  getLoggerLog idlecpu ${OUTPUT_DIR}
  mv ${WORKING_DIR}/Containers/LatSensitive/results.csv ${OUTPUT_DIR}/
  mv *.out ${OUTPUT_DIR}/
  sleep 3
}

loadModule idlecpu
startModule idlecpu

for testNum in {1..9}
do
  lsTest Test-${testNum}
  sleep 3
  echo ""
done

stopModule idlecpu
unloadModule idlecpu
