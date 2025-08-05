#!/bin/bash

# Usage: ./k8sclient.sh <qps> <duration> <server_ip> <launch_port>
# e.g.,: ./k8sclient.sh 3000 60 192.168.10.11 31000

QPS=$1
DURATION=$2
SVR=$3
LAUNCHPORT=$4

SVRCONF="serverconf.json"

WARMUPS=$((2*QPS))

data=`jq --arg d "$DURATION" --arg q "$QPS" --arg w "$WARMUPS" '.duration = $d | .qps=$q | .TBENCH_WARMUPREQS=$w' $SVRCONF`

echo "[+] Server config:"
echo $data


echo "[+] Start xapian integrated-server ... "
curl --data "$data" --header "Content-Type: application/json" http://${SVR}:${LAUNCHPORT} #> req.out 2>&1
