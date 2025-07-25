QPS=$1
DURATION=$2

#SVR="localhost"
SVR="192.168.10.11"
LAUNCHPORT=31000
SVRCONF="serverconf.json"

WARMUPS=$((2*QPS))

data=`jq --arg d "$DURATION" --arg q "$QPS" --arg w "$WARMUPS" '.duration = $d | .qps=$q | .TBENCH_WARMUPREQS=$w' $SVRCONF`

echo "[+] Server config:"
echo $data


echo "[+] Start xapian integrated-server ... "
curl --data "$data" --header "Content-Type: application/json" http://${SVR}:${LAUNCHPORT} #> req.out 2>&1
