#!/bin/bash

echo "[+] Setting up YCSB dependencies and configs"

sudo apt-get install -y openjdk-8-jre

tmp=$(cat /etc/os-release | grep VERSION_CODENAME | awk -F '=' '{print $2}')
if [ $tmp == "focal" ]; then
  wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java_8.0.29-1ubuntu20.04_all.deb
  sudo apt install -y ./mysql-connector-java_8.0.29-1ubuntu20.04_all.deb
  sudo ln -sf /usr/share/java/mysql-connector-java-8.0.29.jar /usr/share/java/mysql-connector-java.jar
  rm mysql-connector-java_8.0.29-1ubuntu20.04_all.deb
else
  sudo apt-get install -y libmysql-java
fi

curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz
tar xzvf ycsb-0.17.0.tar.gz
rm ycsb-0.17.0.tar.gz
cd ycsb-0.17.0
if [ -f "../db.properties" ]
then
  cp ../db.properties .
else
  echo "The db.properties file has not been initialized! Please edit it to include the MySQL service IP and copy it to ycsb-0.17.0/db.properties" 
fi

cp ../harvest_read ./workloads

echo "[+] Updating ycsb binary to use python2"
mv bin/ycsb bin/ycsb.original
sed "s/env python/env python2/g" bin/ycsb.original > bin/ycsb
chmod u+x bin/ycsb

echo "[+] Done."
