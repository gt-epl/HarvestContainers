#!/bin/bash

# SSH into the clabcl1, run a command, and exit (EOF)
ssh -o StrictHostKeyChecking=no clabcl1 << EOF
echo "[+] Connected to clabcl1. Running setup commands..."

pip install scipy pandas

echo "[+] Setting up xapian-primary"
docker pull asarma31/xapian-primary:latest

echo "[+] Setting up xapian-primary inputs"
cd /mnt/extra
wget https://tailbench.csail.mit.edu/tailbench.inputs.tgz
tar -xvf tailbench.inputs.tgz tailbench.inputs/xapian
sudo mkdir -p /dev/shm/xapian.inputs && sudo cp -r tailbench.inputs/xapian /dev/shm/xapian.inputs/

echo "[+] Setting up cpubully-secondary"
docker pull asarma31/cpubully:latest

echo "[+] Setting up memcached-primary"
docker pull asarma31/memcached-primary:latest

echo "[+] Setting up mysql-primary"
docker pull mysql:5.7

echo "[+] Setting up experiment config.out directory"
mkdir -p /mnt/extra/config

echo "[+] clabcl1 setup complete."
exit

EOF

# SSH into the clabsvr, run a command, and exit (EOF)
ssh -o StrictHostKeyChecking=no clabsvr << EOF
echo "[+] Connected to server. Running setup commands..."
pip install scipy pandas

echo "[+] Setting up memcached-primary"
cd ~/HarvestContainers/TestFramework/Containers/memcached/
kubectl apply -f memcached-primary_pod.yaml
kubectl apply -f memcached-primary_svc.yaml
cd mutilate
docker pull asarma31/mutilate:latest
kubectl apply -f mutilate_pod.yaml
kubectl apply -f mutilate_svc.yaml

# [~5 sec] load data
echo "[+] Load memcached-primary dataset"
curl --data "{\"memcached_server\":\"192.168.10.11:31212\"}" --header "Content-Type: application/json" http://192.168.10.10:32003/load

echo "[+] Setting up mysql-primary"
cd ~/HarvestContainers/TestFramework/Containers/MySQL/
kubectl apply -f mysql-primary_pod.yaml
kubectl apply -f mysql-primary_svc.yaml

cd ycsb
docker pull asarma31/ycsb:latest
kubectl apply -f ycsb_pod.yaml
kubectl apply -f ycsb_svc.yaml

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

echo "[+] clabsvr setup complete."
exit
EOF
