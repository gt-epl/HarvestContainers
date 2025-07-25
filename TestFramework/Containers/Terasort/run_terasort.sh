#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../Config/TERASORT.sh

# Uncomment to use local vars
#CNTR_NAME="terasort"
#CNTR_PORT="20021"

docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name ${CNTR_NAME}_1 --rm -p 127.0.0.1:${CNTR_PORT}:1984 -v ${WORKING_DIR}/Containers/Terasort/outputs:/outputs -v ${WORKING_DIR}/Containers/Terasort/inputs:/inputs ${CNTR_NAME}