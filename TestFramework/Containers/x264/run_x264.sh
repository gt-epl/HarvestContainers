#!/bin/bash

source ../../Config/SYSTEM.sh

CNTR_NAME="x264"
CNTR_PORT="20031"

docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name ${CNTR_NAME}_1 --rm -p 1984:${CNTR_PORT} -v ${WORKING_DIR}/Containers/${CNTR_NAME}/outputs:/outputs -v ${WORKING_DIR}/Containers/${CNTR_NAME}/inputs:/inputs ${CNTR_NAME} ${NUM_THREADS}