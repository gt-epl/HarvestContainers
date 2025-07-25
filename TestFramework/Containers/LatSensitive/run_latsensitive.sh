#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../LATSENSITIVE.sh

# Uncomment to use local vars
#CNTR_NAME="latsensitive"
#CNTR_PORT="19001"

docker run --cpuset-cpus=${CORE_RANGE} --name ${CNTR_NAME}_primary --rm -p 1984:${CNTR_PORT} -v ${WORKING_DIR}/Containers/LatSensitive/outputs:/outputs ${CNTR_NAME}