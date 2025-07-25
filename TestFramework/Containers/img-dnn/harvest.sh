#!/bin/bash

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#source ${DIR}/../configs.sh
source ./configs.sh

#THREADS=10
THREADS=$1
REQS=100000000 # Set this very high; the harness controls maxreqs

#TBENCH_WARMUPREQS=100 TBENCH_MAXREQS=100000 TBENCH_QPS=1000 \
TBENCH_WARMUPREQS=10 TBENCH_MAXREQS=$2 TBENCH_QPS=$3 \
    TBENCH_MINSLEEPNS=10000 TBENCH_MNIST_DIR=${DATA_ROOT}/img-dnn/mnist \
    ./img-dnn_integrated -r ${THREADS} \
    -f ${DATA_ROOT}/img-dnn/models/model.xml -n ${REQS}

if [ -f "lats.bin" ]; then
    DATE=$(date '+%Y-%m-%d_%H-%M-%S')
    mv lats.bin /outputs/lats.bin_${DATE}
fi