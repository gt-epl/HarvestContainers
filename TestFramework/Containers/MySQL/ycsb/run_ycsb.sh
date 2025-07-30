#!/bin/bash

source /project/HarvestContainers/TestFramework/Config/YCSB.sh

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

# Uncomment to use local vars
#JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

#YCSB_QPS="12000"
YCSB_THREADS="8"

YCSB_CORE_RANGE="1-31"
YCSB_DURATION="60"
#YCSB_DURATION="300"

echo "[+] Benchmarking reads from MySQL"

cd ycsb-0.17.0

exec 2>&1 1>/project/HarvestContainers/TestFramework/Results/MySQL/${TRIAL}.out

# Run YCSB with raw measurements
sudo taskset -a -c ${YCSB_CORE_RANGE} bin/ycsb run jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -target ${YCSB_QPS} -p maxexecutiontime=${YCSB_DURATION} -p measurementtype=raw -p measurement.raw.output_file=/project/HarvestContainers/TestFramework/Results/MySQL/${TRIAL}-measurements.raw -s -cp /usr/share/java/mysql-connector-java.jar

# Run YCSB with timeseries measurements, sample granularity of 1 ms
#sudo taskset -a -c ${YCSB_CORE_RANGE} bin/ycsb run jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -target ${YCSB_QPS} -p maxexecutiontime=${YCSB_DURATION} -p measurementtype=timeseries -p timeseries.granularity=1 -s -cp /usr/share/java/mysql-connector-java.jar

# Run YCSB with default measurements
#sudo taskset -a -c ${YCSB_CORE_RANGE} bin/ycsb run jdbc -P workloads/harvest_read -P db.properties -threads ${YCSB_THREADS} -target ${YCSB_QPS} -p maxexecutiontime=${YCSB_DURATION} -s -cp /usr/share/java/mysql-connector-java.jar
