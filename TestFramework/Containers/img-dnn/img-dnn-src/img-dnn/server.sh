#!/bin/bash

#Uncomment below to use defaults, else passed from Docker/K8s
set -o allexport
source server.env
set +o allexport

while true; do
  taskset --cpu-list 2,4,6,8,10,12,14,16 ./img-dnn_server_networked -r ${SVR_THREADS} \
                           -f ${DATA_ROOT}/img-dnn/models/model.xml \
                           -n ${REQS}
done
