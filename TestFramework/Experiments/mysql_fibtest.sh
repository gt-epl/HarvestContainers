#!/bin/bash

if [ -z "$1" ]
then
  echo "Please specify POD ID of Secondary"
  exit
fi

FIB_ONE_IP="10.99.178.75"
FIBTEST_DURATION="120"
FIBTEST_WORKERS="8"

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh

TARGET_IDLE_CORES="3"

SECONDARY_PID="-1"

POD_ID=$1

loadModule idlecpu
startModule idlecpu

runListener
sleep 3
sendPodId ${POD_ID}

echo "[+] Starting logging"
startLogging idlecpu

runBalancer

curl --data "{\"duration\":\"${FIBTEST_DURATION}\",\"workers\":\"${FIBTEST_WORKERS}\"}" --header "Content-Type: application/json" http://${FIB_ONE_IP}:20000

echo "[+] Stopping logging"
stopLogging idlecpu
stopModule idlecpu

sudo kill -10 `pgrep balancer`
sudo kill -10 `pgrep listener`

echo "[+] Retrieving logs"
getLoggerLog idlecpu /tmp

unloadModule idlecpu
echo "[+] Done."
