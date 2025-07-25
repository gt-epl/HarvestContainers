#!/bin/bash

if [ -z "$1" ]
then
  echo ""
  echo "Please specify the pod name (./expose_pod.sh <pod_name>)"
  echo ""
  exit
fi

POD_NAME=$1
POD_PORT="11211"

POD_IP_ADDR=$(kubectl expose pod ${POD_NAME} --type=ClusterIP --port=${POD_PORT} --name=${POD_NAME} --output='json' | jq -r '.spec.clusterIP')

echo "[+] Pod exposed at ${POD_IP_ADDR}"
