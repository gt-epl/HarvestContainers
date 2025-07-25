#!/bin/bash

CPUBULLY_ONE_IP="10.111.234.243"
CPUBULLY_TWO_IP="10.99.95.199"

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

curl --data "{\"duration\":\"2\",\"workers\":\"4\"}" --header "Content-Type: application/json" http://${CPUBULLY_ONE_IP}:20000 &
curl --data "{\"duration\":\"2\",\"workers\":\"4\"}" --header "Content-Type: application/json" http://${CPUBULLY_TWO_IP}:20000

echo "[+] Stopping logging"
stopLogging idlecpu
stopModule idlecpu

sudo kill -10 `pgrep balancer`
sudo kill -10 `pgrep listener`

echo "[+] Retrieving logs"
getLoggerLog idlecpu /tmp

unloadModule idlecpu
echo "[+] Done."
