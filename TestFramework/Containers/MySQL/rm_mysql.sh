#!/bin/bash

kubectl delete pod mysql-primary
sleep 1
kubectl delete configmap mysql-initdb-config