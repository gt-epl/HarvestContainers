#!/bin/bash
source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh

MASTER="clabsvr"
ITER=$1
SECONDARY_WORKERS=$2
TARGET_IDLE_CORES=$3
QPS=$4
DURATION=$5
TYPE="baseline"
META="8c,8st,1ct"

#e.g. ./img-dnn_logger.sh 1 1 1 3000 60

#QPS=4000

if [ ! -f "config.out" ]; then
  echo "uuid type iter sec_workers target_idle qps duration metadata" > config.out
  echo "uuid event-weighted time-weighted" > logs/summary
fi

#LOGFILE="${QPS}qps_8c_8st_1ct_run$ITER"
#LOGFILE="${QPS}qps_secondary${SECONDARY_WORKERS}w_idle${TARGET_IDLE_CORES}_aimd_run$ITER"

LOGFILE=$(cat /proc/sys/kernel/random/uuid)
echo "${LOGFILE} ${TYPE} ${ITER} ${SECONDARY_WORKERS} ${TARGET_IDLE_CORES} ${QPS} ${DURATION} ${META}" >> config.out

mkdir -p logs


runImgDnn() {
  cur=$(pwd)

  cd /project/HarvestContainers/TestFramework/Containers/img-dnn/img-dnn-src/img-dnn
  ./k8sclient.sh $QPS $DURATION

  cd $cur
}

calcLats() {
  cur=$(pwd)

  res=$cur/results
  cd /project/HarvestContainers/TestFramework/Containers/img-dnn/img-dnn-src/img-dnn
  mkdir -p $res
  cp /dev/shm/results/lats.bin $res/$LOGFILE.bin
  python parselats_old.py $res/$LOGFILE.bin >> $res/summary

  cd $cur
}

calcUtil() {
  echo "$LOGFILE $(grep "average active cores" logs/$LOGFILE.out | awk '{print $NF}' | tr "\n" " ")" >> logs/summary
}

baseline() {
  loadModule idlecpu
  startModule idlecpu

  echo "[+] Starting logging"
  startLogging idlecpu

  runImgDnn

  echo "[+] Stopping modules"
  stopLogging idlecpu
  stopModule idlecpu

  echo "[+] Retrieving logs"
  getLoggerLog idlecpu /tmp

  unloadModule idlecpu

  echo "[+] summarize stats"
  python ../Tools/parse_cpulogger2.py /tmp/cpulogger.log $CPULIST > logs/$LOGFILE.out
  calcUtil
  calcLats

  echo "[+] Done."
}

cleanup() {

  echo "[+] Stopping logging"
  stopLogging idlecpu
  stopModule idlecpu

  sudo kill $(pgrep listener)
  sudo kill $(pgrep balancer)
  unloadModule idlecpu
}

harvest() {
  SECONDARY_IP="192.168.10.11"
  SECONDARY_DURATION=$DURATION

  SECONDARY_PID="-1"
  SECONDARY=fibtest-secondary
  PODFILE=${SECONDARY}_podinfo.txt
  rm -f $PODFILE
  bash cloudlab/get_pod_info.sh $MASTER $SECONDARY
  POD_ID="pod$(cat $PODFILE | jq -r .metadata.uid)"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId ${POD_ID}

  #echo "[+] Starting logging"
  #startLogging idlecpu

  runBalancer

  echo "[+] Start primary workload in background"
  runImgDnn &

  echo "[+] Start secondary workload in foreground"
  curl --data "{\"duration\":\"${SECONDARY_DURATION}\",\"workers\":\"${SECONDARY_WORKERS}\"}" --header "Content-Type: application/json" http://${SECONDARY_IP}:30000



  echo "[+] Stopping Modules"
  #stopLogging idlecpu
  stopModule idlecpu

  sudo kill `pgrep balancer`
  sudo kill `pgrep listener`


  #echo "[+] Retrieving logs"
  #getLoggerLog idlecpu /tmp

  unloadModule idlecpu

  sleep 5;
  echo "[+] Done."
}

secondary() {
  SECONDARY_IP="192.168.10.11"
  SECONDARY_DURATION=$DURATION
  SECONDARY_WORKERS=1

  curl --data "{\"duration\":\"${SECONDARY_DURATION}\",\"workers\":\"${SECONDARY_WORKERS}\"}" --header "Content-Type: application/json" http://${SECONDARY_IP}:30000
}


if [ $TYPE == "baseline" ]; then
  baseline
elif [ $TYPE == "harvest" ]; then
  harvest
elif [ $TYPE == "cleanup" ]; then
  cleanup
elif [ $TYPE == "secondary" ]; then
  secondary
else
  echo "Unknown TYPE: $TYPE"
fi
