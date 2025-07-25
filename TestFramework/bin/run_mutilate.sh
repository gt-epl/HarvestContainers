#!/bin/bash

source ../Config/SYSTEM.sh
source ../Config/MUTILATE.sh

sudo rm -f ${WORKING_DIR}/Results/Mutilate/mutilate.log

sudo taskset -a -c ${MUTILATE_CORE_RANGE} ${WORKING_DIR}/bin/mutilate -s ${MEMCACHED_SERVER} -T ${MUTILATE_THREADS} -c ${MUTILATE_CONNS} -V fb_value -i fb_ia -K fb_key -t ${MUTILATE_DURATION} --save=${WORKING_DIR}/Results/Mutilate/mutilate.log