#!/bin/bash

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh

loadModule idlecpu
startModule idlecpu

echo "[+] Starting logging"
startLogging idlecpu

echo "[+] Start iperf test"
core=5
bash run-irq.sh $core

echo "[+] Stopping logging"
stopLogging idlecpu
stopModule idlecpu

echo "[+] Retrieving logs"
getLoggerLog idlecpu /tmp

unloadModule idlecpu
echo "[+] Done."
