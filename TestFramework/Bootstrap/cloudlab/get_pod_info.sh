#!/usr/bin/env bash

MASTER=$1 #k8ssvr as specified in ssh config
APP=$2
if [ -z $APP ]; then
  APP=memcached-primary
fi

echo $(ssh $MASTER "kubectl get pods ${APP} -o json") > ${APP}_podinfo.txt
