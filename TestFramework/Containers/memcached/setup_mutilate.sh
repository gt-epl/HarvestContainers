#!/bin/bash

source ../../Config/SYSTEM.sh

echo "[+] Cloning mutilate repo"
git clone https://github.com/leverich/mutilate.git
cd mutilate
echo "[+] Installing mutilate deps via apt"
sudo apt-get install scons libevent-dev gengetopt libzmq3-dev -y
echo "[+] Building mutilate"
scons
echo "[+] Copying mutilate to bin/"
cp mutilate ${WORKING_DIR}/bin 
echo "[+] Done."