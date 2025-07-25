#!/bin/bash

POD_NAME=$1

kubectl get pods ${POD_NAME} -o json | jq -r .metadata.uid
