#!/bin/bash

source ../../bin/boilerplate.sh
source ../../Config/IMGDNN.sh

# Uncomment to use local values
#CNTR_NAME="img-dnn"
#CNTR_PORT="19002"
#THREADS=10
#TBENCH_MAXREQS=200000
#TBENCH_QPS=2500

runImgDnnContainer fg ${THREADS} ${TBENCH_MAXREQS} ${TBENCH_QPS}