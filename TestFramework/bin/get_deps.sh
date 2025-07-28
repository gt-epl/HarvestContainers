#!/bin/bash

## TODO: this script is not used anymore and can be removed.

source ../Config/SYSTEM.sh

echo "[+] Retrieving kernel"

# --- Kernel ---
cd ${WORKING_DIR}/Bootstrap
wget https://dev.ahall.net/harvest/builds/kernel/latest -O kernel.tgz
tar xzvf kernel.tgz
rm kernel.tgz

echo "[+] Retrieving binaries"
# --- Begin Retrieve Binaries ---

cd ${WORKING_DIR}/bin

# BALANCER
wget https://dev.ahall.net/harvest/builds/balancer/latest -O balancer

# LISTENER
wget https://dev.ahall.net/harvest/builds/listener/latest -O listener

# MUTILATE
wget https://dev.ahall.net/harvest/builds/mutilate/latest -O mutilate

# QIDLECPU
wget https://dev.ahall.net/harvest/builds/qidlecpu/latest -O qidlecpu.ko

chmod u+x ${WORKING_DIR}/bin/*

echo "[+] Retrieving container files"
# --- Begin Retrieve Container Deps ---

# CPUBULLY
cd ${WORKING_DIR}/Containers/CPUBully
wget https://dev.ahall.net/harvest/builds/cpubully/latest -O bullyexe.exe
chmod u+x bullyexe.exe

# LATSENSITIVE
cd ${WORKING_DIR}/Containers/LatSensitive
wget https://dev.ahall.net/harvest/builds/latsensitive/latest -O latsensitive
chmod u+x latsensitive

# IMG-DNN
cd ${WORKING_DIR}/Containers/img-dnn
wget https://dev.ahall.net/harvest/builds/img-dnn/latest -O img-dnn.tgz
tar xzvf img-dnn.tgz
rm img-dnn.tgz
chmod u+x img-dnn_integrated *.sh

# MYSQL
cd ${WORKING_DIR}/Containers/MySQL
wget https://dev.ahall.net/harvest/builds/mysql/latest -O ycsb.tgz
tar xzvf ycsb.tgz
rm ycsb.tgz

echo "[+] Done."