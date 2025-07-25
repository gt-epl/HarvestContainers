#!/bin/bash

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh

loadModule idlecpu
startModule idlecpu

echo "[+] Starting logging"
startLogging idlecpu

read -p "Press any key to stop logging..."

echo "[+] Stopping logging"
stopLogging idlecpu
stopModule idlecpu

echo "[+] Retrieving logs"
getLoggerLog idlecpu /tmp

unloadModule idlecpu
echo "[+] Done."
