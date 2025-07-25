#!/bin/bash

source ../../bin/boilerplate.sh

OUTPUT_DIR="."

loadModule idlecpu
startModule idlecpu

echo ""
echo "[+] Starting Logging"
echo ""
startLogging idlecpu
read -p "Press any key to stop..."
echo "[+] Stopping Logging"
stopLogging idlecpu
stopModule idlecpu
sleep 3
echo "[+] Retrieving logs..."
getLoggerLog idlecpu ${OUTPUT_DIR}
echo "[+] Done."
unloadModule idlecpu
