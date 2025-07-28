#!/bin/bash


# SSH into the clabcl1, run a command, and exit (EOF)
ssh -o StrictHostKeyChecking=no clabcl1 << EOF
echo "[+] Connected to clabcl1. Running setup commands..."

pip install scipy
docker pull asarma31/xapian-primary:latest
docker pull asarma31/cpubully:latest

echo "[+] clabcl1 setup complete."
exit

EOF

# SSH into the clabsvr, run a command, and exit (EOF)
ssh -o StrictHostKeyChecking=no clabsvr << EOF
echo "[+] Connected to server. Running setup commands..."
pip install scipy


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
