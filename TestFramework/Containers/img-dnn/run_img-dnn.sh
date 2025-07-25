#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../Config/IMGDNN.sh

# Uncomment to use local values
#CNTR_NAME="img-dnn"
#CNTR_PORT="19002"
#THREADS=10
#TBENCH_MAXREQS=200000
#TBENCH_QPS=2500

docker run --cpuset-cpus=${CORE_RANGE} --name ${CNTR_NAME}_primary --rm -p 1984:${CNTR_PORT} -v ${WORKING_DIR}/Containers/img-dnn/outputs:/outputs ${CNTR_NAME} ${THREADS} ${TBENCH_MAXREQS} ${TBENCH_QPS}
