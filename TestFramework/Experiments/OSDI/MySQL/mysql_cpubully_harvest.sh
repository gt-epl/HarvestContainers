#!/bin/bash

WORKING_DIR=/project/HarvestContainers/TestFramework
source ${WORKING_DIR}/bin/boilerplate.sh
source ${WORKING_DIR}/Config/SYSTEM.sh

SECONDARY_POD_ID="pode2a30a4b-af50-4c5a-9f9f-0749e8c9b703"

CPUBULLY_IP=10.101.186.161
CPUBULLY_DURATION="1"
CPUBULLY_WORKERS="9"

SECONDARY_PID="-1"

# 1k
QPS_NAME="1k"
QPS="1000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""


# 2k
QPS_NAME="2k"
QPS="2000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""


# 3k
QPS_NAME="3k"
QPS="3000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""


# 4k
QPS_NAME="4k"
QPS="4000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""


# 5k
QPS_NAME="5k"
QPS="5000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""


# 6k
QPS_NAME="6k"
QPS="6000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""


# 7k
QPS_NAME="7k"
QPS="7000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""


# 8k
QPS_NAME="8k"
QPS="8000"
TARGET_IDLE_CORES="2"

for TRIAL_NUM in {1..5}
do
  TRIAL_NAME="harvest-${QPS_NAME}-trial${TRIAL_NUM}.RAW"

  echo "Running ${TRIAL_NAME}"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${SECONDARY_POD_ID}
  sleep 3

  startLogging idlecpu

  runBalancer

  # Start ycsb
  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.15:20000 &

  # Start cpubully
  curl --data "{\"trial\":\"${TRIAL_NAME}\", \"duration\":\"${CPUBULLY_DURATION}\",\"workers\":\"${CPUBULLY_WORKERS}\"}" --header "Content-Type: application/json" http://${CPUBULLY_IP}:20000

  stopLogging idlecpu

  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sleep 3
  sudo kill -10 `pgrep listener`
  sleep 3

  getLoggerLog idlecpu /tmp

  sleep 3

  unloadModule idlecpu

  sudo mv /tmp/cpulogger.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-cpulogger

  sudo mv balancer.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-balancer.log

  sudo mv idleMaskChanges.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-idleMaskChanges.log

  sudo mv stats.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-stats.log

  sudo mv util.log ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log
  sudo chown ach ${WORKING_DIR}/Results/MySQL/${TRIAL_NAME}-util.log

  sleep 10
done

echo ""
