#!/bin/bash

source ../../Config/boilerplate.sh

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
YCSB_QPS=$2
testNum=$3
TARGET_IDLE_CORES=$4

TEST_TYPE="MySQL"
#testNum="25k"

balancerRunning() {
  if pgrep -x "balancer" >/dev/null
  then
    return 1
  else
    return 0
  fi
}

runYCSB() {
  JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

  YCSB_THREADS="20"
  #YCSB_THREADS="6"
  #YCSB_QPS="25000"
  #YCSB_QPS="50000"
  #YCSB_QPS="75000"
  #YCSB_QPS="100000"

  YCSB_CORE_RANGE="28-47"
  #YCSB_CORE_RANGE="1-11"

  echo "[+] Benchmarking reads from MySQL"

  cd ${WORKING_DIR}/Containers/MySQL/ycsb-0.17.0

  sudo taskset -a -c ${YCSB_CORE_RANGE} bin/ycsb run jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -target ${YCSB_QPS} -s -p maxexecutiontime=60 -jvm-args='-Xmx8192m' -cp /usr/share/java/mysql-connector-java.jar 2>${OUTPUT_DIR}/ycsb-stderr.out 1>${OUTPUT_DIR}/ycsb-stdout.out

}

balancerTest() {
  TEST_NUM=$1
  TEST_NAME="MySQL-Bully-Harvest"

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
  
  # Run YCSB
  runYCSB

  sleep 5
  cd ${WORKING_DIR}/Experiments/MySQL
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
