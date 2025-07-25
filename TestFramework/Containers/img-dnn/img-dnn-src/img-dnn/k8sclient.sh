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


echo "[+] Start img-dnn server ... "
curl --data "$data" --header "Content-Type: application/json" http://${SVR}:${LAUNCHPORT} > req.out 2>&1

#sleep 2;

#echo "" #curl doesn't new line
##echo "[+] start client"
#DATA_ROOT=/dev/shm/img-dnn.inputs
#TBENCH_QPS=$QPS \
#TBENCH_MNIST_DIR=${DATA_ROOT}/img-dnn/mnist \
#TBENCH_SERVER=${SVR}  \
#TBENCH_SERVER_PORT=31211 \
#TBENCH_CLIENT_THREADS=1  \
#TBENCH_MINSLEEPNS=100    \
#TBENCH_RANDSEED=123      \
#./img-dnn_client_networked
#taskset --cpu-list 18,20,22,24,26,28,30 ./img-dnn_client_networked

