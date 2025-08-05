#!/bin/bash

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh
echo "[+] Stopping logging"
stopLogging idlecpu
stopModule idlecpu

sudo kill $(pgrep listener)
sudo kill $(pgrep balancer)
unloadModule idlecpu
