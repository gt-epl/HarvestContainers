#!/bin/bash

source ../../bin/boilerplate.sh
source ../../Config/CPUBULLY.sh

# Uncomment to use local values
#CNTR_NAME="cpubully"
#CNTR_PORT="20001"
#BULLY_WORKERS="11"
#BULLY_OUTPUT="cpubully.out"

runCPUBullyContainer fg
