#!/bin/bash

source ../../Config/SYSTEM.sh
source ../../Config/MUTILATE.sh

sudo taskset -a -c ${MUTILATE_CORE_RANGE} ${WORKING_DIR}/bin/mutilate -s ${MEMCACHED_SERVER}:11211 -K fb_key -V fb_value -r 1000000 -i fb_ia --loadonly
