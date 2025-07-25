#!/bin/bash

FIB_ONE_IP="10.106.184.199"
FIB_TWO_IP="10.109.231.43"

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh
source ../Config/MUTILATE.sh

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

curl --data "{\"duration\":\"60\",\"workers\":\"4\"}" --header "Content-Type: application/json" http://${FIB_ONE_IP}:20000 &
curl --data "{\"duration\":\"60\",\"workers\":\"2\"}" --header "Content-Type: application/json" http://${FIB_TWO_IP}:20000

echo "[+] Stopping logging"
stopLogging idlecpu
stopModule idlecpu

sudo kill -10 `pgrep balancer`
sudo kill -10 `pgrep listener`

echo "[+] Retrieving logs"
getLoggerLog idlecpu /tmp

unloadModule idlecpu
echo "[+] Done."
