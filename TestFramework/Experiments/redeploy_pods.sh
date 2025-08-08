#!/bin/bash

# SSH into the clabsvr, run a command, and exit (EOF)
ssh -o StrictHostKeyChecking=no clabsvr << EOF
echo "[+] Connected to server. Removing pods..."

kubectl delete pod memcached-primary
kubectl delete pod mysql-primary
kubectl delete pod xapian-primary
kubectl delete pod cpubully-secondary
kubectl delete pod nwbully-secondary
kubectl delete pod mutilate
kubectl delete pod mutilate-cl1
kubectl delete pod ycsb
kubectl delete pod ycsb-cl1

echo [+] Done."

echo "[+] Re-deploying pods..."

cd ~/HarvestContainers/TestFramework/Containers/memcached/
echo "[+] Setting up memcached-primary"
kubectl apply -f memcached-primary_pod.yaml
cd mutilate
echo "[+] Setting up mutilate"
kubectl apply -f mutilate_pod.yaml
kubectl apply -f mutilate_cl1_pod.yaml

sleep 15

echo "[+] Loading data into memcached"
# [~5 sec] load data
echo "[+] Load memcached-primary dataset"
curl --data "{\"memcached_server\":\"192.168.10.11:31212\"}" --header "Content-Type: application/json" http://192.168.10.10:32003/load

echo "[+] Setting up mysql-primary"
cd ~/HarvestContainers/TestFramework/Containers/MySQL/
kubectl apply -f mysql-primary_pod.yaml
kubectl apply -f mysql-primary_svc.yaml

echo "[+] Setting up ycsb"
cd ycsb
docker pull asarma31/ycsb:latest
kubectl apply -f ycsb_pod.yaml
kubectl apply -f ycsb_svc.yaml
kubectl apply -f ycsb_cl1_pod.yaml
kubectl apply -f ycsb_cl1_svc.yaml

sleep 15

echo "[+] Loading data into mysql"
# [~2 min] load data
# currently ignores mysql_server as it's hardcoded. TODO: change this
echo "[+] Load mysql-primary dataset"
curl --data "{\"mysql_server\":\"192.168.10.11:32306\"}" --header "Content-Type: application/json" http://192.168.10.10:32002/load


echo "[+] Setting up xapian-primary"
cd ~/HarvestContainers/TestFramework/Containers/xapian/
kubectl apply -f xapian-primary_pod.yaml
kubectl apply -f xapian-primary_svc.yaml

echo "[+] Setting up cpubully-secondary"
cd ~/HarvestContainers/TestFramework/Containers/CPUBully/
kubectl apply -f cpubully-secondary_pod.yaml
kubectl apply -f cpubully-secondary_svc.yaml

echo "[+] Setting up x264-secondary"
cd ~/HarvestContainers/TestFramework/Containers/x264/
kubectl apply -f x264-secondary_pod.yaml
kubectl apply -f x264-secondary_svc.yaml

echo "[+] Setting up dedup-secondary"
cd ~/HarvestContainers/TestFramework/Containers/Dedup/
kubectl apply -f dedup-secondary_pod.yaml
kubectl apply -f dedup-secondary_svc.yaml

echo "[+] Pod redeploy complete."
exit
EOF

