#!/bin/bash

source ../../Config/YCSB.sh

# Uncomment to use local vars
#JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
#YCSB_THREADS=32

echo "[+] Loading YCSB workload data into MySQL"

cd ycsb-0.17.0

bin/ycsb load jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -s -cp /usr/share/java/mysql-connector-java.jar
