#!/bin/bash

QPS="40000"
TRIAL_NAME="tic5"

WORKING_DIR=/project/HarvestContainers/TestFramework

POD_ID="podc3e628ca-02e2-42cf-8e12-0a87429fbafb"

source ${WORKING_DIR}/bin/boilerplate.sh
source ${WORKING_DIR}/Config/SYSTEM.sh

FIBTEST_IP=10.100.237.215
FIBTEST_DURATION="60"
FIBTEST_WORKERS="9"

TARGET_IDLE_CORES="5"
SECONDARY_PID="-1"

loadModule idlecpu
startModule idlecpu

runListener
sleep 3
sendPodId ${POD_ID}
sleep 3

startLogging idlecpu

runBalancer

# Start mutilate
curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\"}" --header "Content-Type: application/json" http://192.168.10.10:20000 &

# Start fibtest
curl --data "{\"duration\":\"${FIBTEST_DURATION}\",\"workers\":\"${FIBTEST_WORKERS}\"}" --header "Content-Type: application/json" http://${FIBTEST_IP}:20000

stopLogging idlecpu
stopModule idlecpu

sudo kill -10 `pgrep balancer`
sudo kill -9 `pgrep listener`

getLoggerLog idlecpu /tmp
unloadModule idlecpu
