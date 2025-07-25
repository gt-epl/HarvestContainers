#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../Config/MYSQL.sh

# Uncomment to use local vars
#CNTR_NAME="mysql"
#CNTR_PORT="3306"

docker run --rm -p ${CNTR_PORT}:${CNTR_PORT} --cpuset-cpus=${CORE_RANGE} --name ${CNTR_NAME}_primary -e MYSQL_ROOT_PASSWORD=taskmaster -e MYSQL_DATABASE=ycsb -e MYSQL_USER=ycsb -e MYSQL_PASSWORD=ycsb -v ${WORKING_DIR}/Containers/MySQL/initdb:/docker-entrypoint-initdb.d mysql:5.7
