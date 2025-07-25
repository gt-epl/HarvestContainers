#!/bin/bash

kubectl delete pod mysql 
sleep 1
kubectl delete configmap mysql-initdb-config
sleep 1
kubectl delete pvc mysql-pv-claim
sleep 1
kubectl patch pv mysql-pv -p '{"metadata":{"finalizers":null}}'
sleep 1
kubectl delete pv mysql-pv

rm -f ./mysql-pv.yaml mysql-pvc.yaml db.properties

# If you try to remove the pv before removing the pvc, pv removal will be
# stuck in 'Terminating' status; Run the following command to fix:
#
# kubectl patch pv mysql-pv -p '{"metadata":{"finalizers":null}}'
