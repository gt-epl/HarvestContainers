#!/bin/bash

WORKING_DIR=/project/HarvestContainers/TestFramework
source ${WORKING_DIR}/bin/boilerplate.sh
source ${WORKING_DIR}/Config/SYSTEM.sh

SECONDARY_POD_ID="pod48dc0c1c-2d60-410b-a514-736e58eafb18"

CPUBULLY_IP=10.101.186.161
CPUBULLY_DURATION="1"
CPUBULLY_WORKERS="8"

# 1k
BASELINE_NAME="1k"
QPS="1000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""

# 2k
BASELINE_NAME="2k"
QPS="2000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""

# 3k
BASELINE_NAME="3k"
QPS="3000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""

# 4k
BASELINE_NAME="4k"
QPS="4000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""

# 5k
BASELINE_NAME="5k"
QPS="5000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""

# 6k
BASELINE_NAME="6k"
QPS="6000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""

# 7k
BASELINE_NAME="7k"
QPS="7000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""

# 8k
BASELINE_NAME="8k"
QPS="8000"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="cgroup-req1-${BASELINE_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  startLogging idlecpu

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sleep 10
done

echo ""
