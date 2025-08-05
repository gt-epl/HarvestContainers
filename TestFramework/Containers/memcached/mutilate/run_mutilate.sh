#!/bin/bash

WORKING_DIR=/app

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
MUTILATE_QPS=$2
MUTILATE_DURATION=$3
MEMCACHED_SERVER=$4

MUTILATE_RECORDS="1000000"
#MUTILATE_DURATION="120"

OUTPUT_DIR="${WORKING_DIR}/results/${TRIAL}"
mkdir -p ${OUTPUT_DIR}

echo "[+] Benchmarking reads from memcached for ${TRIAL}, ${MUTILATE_QPS}, ${MUTILATE_DURATION}"

cd ${WORKING_DIR}

${WORKING_DIR}/mutilate -s ${MEMCACHED_SERVER} \
                            --noload -K fb_key -V fb_value \
                            -r ${MUTILATE_RECORDS} -i fb_ia \
                            -T ${MUTILATE_THREADS} -c ${MUTILATE_CONNS} \
                            -u 0.00 -d 1 -q ${MUTILATE_QPS} \
                            --time=${MUTILATE_DURATION} \
                            --blocking \
                            --save=${OUTPUT_DIR}/mutilate.log 2>${OUTPUT_DIR}/stderr.log 1>${OUTPUT_DIR}/stdout.log

echo "[+] Done."
