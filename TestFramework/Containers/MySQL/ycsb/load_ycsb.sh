#!/bin/bash

echo "[+] Loading YCSB workload data into MySQL"

cd ycsb-0.17.0

bin/ycsb load jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -s -cp /usr/share/java/mysql-connector-java.jar
