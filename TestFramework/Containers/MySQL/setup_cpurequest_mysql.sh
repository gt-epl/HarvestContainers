#!/bin/bash

if [ -z "$1" ]
then
  echo ""
  echo "Please specify the hostname of the node where the MySQL pod will be deployed (./config_mysql.sh <client_node>)"
  echo ""
  exit
fi

MYSQL_NODE_NAME=$1

echo ""

echo "[+] Labeling node ${MYSQL_NODE_NAME} with mysql_pod=primary"
kubectl label node ${MYSQL_NODE_NAME} mysql_pod=primary

echo ""

read -p "Ensure you have manually created the ramdisk on ${MYSQL_NODE_NAME} using command:

  sudo mkdir /mnt/data && sudo mount -t tmpfs -o size=20G tmpfs /mnt/data && sudo mkdir /mnt/data/mysql

Press any key when ready..."

echo "[+] Updating mysql-pv.yaml file to use MySQL node name"
sed "s/MYSQL_NODE/${MYSQL_NODE_NAME}/g" mysql-pv.yaml.template > mysql-pv.yaml

echo "[+] Creating PersistentVolume"
kubectl apply -f mysql-pv.yaml

cp mysql-pvc.yaml.template mysql-pvc.yaml
echo "[+] Creating PersistentVolume Claim"
kubectl apply -f mysql-pvc.yaml

echo "[+] Deplying pod"
kubectl create -f mysql_cpurequest_pod.yaml

echo "[+] Creating MySQL service to expose its port to the cluster"
MYSQL_IP_ADDR=$(kubectl expose pod mysql --type=ClusterIP --port=3306 --name=mysql --output='json' | jq -r '.spec.clusterIP')

echo "[+] MySQL pod accessible at ${MYSQL_IP_ADDR}:3306"

echo "[+] Updating db.properties file to use MySQL service address"
sed "s/MYSQL_SVC/${MYSQL_IP_ADDR}/g" db.properties.template > db.properties
