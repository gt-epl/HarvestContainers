#!/bin/bash

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
YCSB_QPS=$2

source ../../Config/boilerplate.sh

JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

YCSB_THREADS="20"
#YCSB_THREADS="6"
#YCSB_QPS="25000"
#YCSB_QPS="50000"
#YCSB_QPS="75000"
#YCSB_QPS="100000"

YCSB_CORE_RANGE="28-47"
#YCSB_CORE_RANGE="1-11"

OUTPUT_DIR="${WORKING_DIR}/Results/MySQL/Baseline/${YCSB_QPS}/${TRIAL}"
mkdir -p ${OUTPUT_DIR}

echo "[+] Benchmarking reads from MySQL"

cd ${WORKING_DIR}/Containers/MySQL/ycsb-0.17.0

loadModule idlecpu
startModule idlecpu
sleep 1
startLogging idlecpu

sudo taskset -a -c ${YCSB_CORE_RANGE} bin/ycsb run jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -target ${YCSB_QPS} -s -p maxexecutiontime=60 -jvm-args='-Xmx8192m' -cp /usr/share/java/mysql-connector-java.jar 2>${OUTPUT_DIR}/stderr.log 1>${OUTPUT_DIR}/stdout.log

stopLogging idlecpu
stopModule idlecpu
sleep 3
echo "[+] Retrieving cpulogger.log"
getLoggerLog idlecpu ${OUTPUT_DIR}
sleep 1
unloadModule idlecpu
echo "[+] Done."
