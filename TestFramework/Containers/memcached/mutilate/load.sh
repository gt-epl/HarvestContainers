#!/bin/bash
WORKING_DIR=/app
MEMCACHED_SERVER=$1

${WORKING_DIR}/mutilate -s ${MEMCACHED_SERVER} -K fb_key -V fb_value -r 1000000 -i fb_ia --loadonly > ${WORKING_DIR}/results/load.log 2>&1
