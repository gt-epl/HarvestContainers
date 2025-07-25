#!/bin/bash

QPS=$1
if [ -z $QPS ]; then
  QPS=500
fi

DATA_ROOT=~/img-dnn.inputs
TBENCH_QPS=$QPS \
TBENCH_MNIST_DIR=${DATA_ROOT}/img-dnn/mnist \
TBENCH_SERVER=192.168.10.11  \
TBENCH_SERVER_PORT=31211 \
TBENCH_CLIENT_THREADS=1  \
TBENCH_MINSLEEPNS=100    \
TBENCH_RANDSEED=123      \
./img-dnn_client_networked
