#!/bin/bash

TEST_TYPE="BASELINE"

source ../bin/boilerplate.sh

bullyLogTest() {
    BULLY_WORKERS=$1
    CPULIST=$2
    loadModule idlecpu
    sleep 1
    startModule idlecpu
    sleep 1
    startLogging idlecpu
    OUTPUT_DIR="${WORKING_DIR}/Results/Baseline/CPUBully/${TEST_NAME}"
    BULLY_OUTPUT="${OUTPUT_DIR}/cpubully.out"
    mkdir -p ${OUTPUT_DIR}
    runCPUBullyContainer fg
    sleep 1
    stopLogging idlecpu
    getLoggerLog idlecpu ${OUTPUT_DIR}
    stopModule idlecpu
    sleep 1
    unloadModule idlecpu
}

bullyTest() {
    BULLY_WORKERS=$1
    CPULIST=$2
    OUTPUT_DIR="${WORKING_DIR}/Results/Baseline/CPUBully/${TEST_NAME}"
    BULLY_OUTPUT="${OUTPUT_DIR}/cpubully.out"
    mkdir -p ${OUTPUT_DIR}
    runCPUBullyContainer fg
    sleep 1
}

if [ -z "$1" ] || [ -z "$2" ]
then
    echo "Usage: ./bully_baseline.sh <TEST_NAME> <CPULIST> <NUM_WORKERS> [log]"
    echo "(e.g., ./bully_baseline.sh Test_4workers4cores 1,2,3,4 4 log)"
    exit
fi

TEST_NAME=$1
CORE_RANGE=$2
NUM_WORKERS=$3

echo "[+] Testing Bully with ${NUM_WORKERS} workers on cores ${CORE_RANGE}"

if [ -n "$4" ] && [ "$4" == "log" ]; then
    bullyLogTest ${NUM_WORKERS} ${CORE_RANGE}
else
    bullyTest ${NUM_WORKERS} ${CORE_RANGE}
fi

echo "[+] Done"
echo ""