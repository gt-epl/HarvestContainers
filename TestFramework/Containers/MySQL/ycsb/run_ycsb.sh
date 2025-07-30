#!/bin/bash

if [ -z "$1" ]
then
    echo "Please specify TRIAL name"
    exit
fi

if [ -z "$2" ]
then
    echo "Please specify QPS"
    exit
fi

TRIAL=$1
YCSB_QPS=$2
YCSB_DURATION=$3

echo "[+] Benchmarking reads from MySQL"

cd ycsb-0.17.0

RAW_FILE="/app/results/${TRIAL}.raw"
exec 2>&1 1>$RAW_FILE

# Run YCSB with raw measurements (env defined apriori: e.g., in Dockerfile or ycsb_pod.yaml)
bin/ycsb run jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -target ${YCSB_QPS} -p maxexecutiontime=${YCSB_DURATION} -p measurementtype=raw -p measurement.raw.output_file=${OUTPUT_FILE} -s -cp /usr/share/java/mysql-connector-java.jar


grep SCAN, $RAW_FILE > /app/results/${TRIAL}.out
