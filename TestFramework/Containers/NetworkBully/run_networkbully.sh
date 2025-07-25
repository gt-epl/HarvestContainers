#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../Config/NETWORKBULLY.sh

# Uncomment to use local vars
#CNTR_NAME="networkbully"
#CNTR_PORT="20011"

docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name ${CNTR_NAME}_1 --rm -p 127.0.0.1:${CNTR_PORT}:5101 -v ${WORKING_DIR}/Containers/NetworkBully/outputs:/outputs ${CNTR_NAME}