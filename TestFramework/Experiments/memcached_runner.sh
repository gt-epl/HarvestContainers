#!/bin/bash

WORKING_DIR=/project/HarvestContainers/TestFramework
source ${WORKING_DIR}/bin/boilerplate.sh
source ${WORKING_DIR}/Config/SYSTEM.sh
source ./secondary.sh

MASTER="clabsvr"
ITER=$1
SECONDARY_WORKERS=$2
TARGET_IDLE_CORES=$3
QPS=$4
DURATION=$5
LOGDIR="/mnt/extra/logs"

TYPE="$6"
META="mutilate"
#e.g. ./memcached_runner.sh 1 1 1 3000 60

LOGFILE=$(cat /proc/sys/kernel/random/uuid)
LOGDEST=$LOGDIR/$LOGFILE

if [ ! -f "config.out" ]; then
  echo "uuid type iter sec_workers target_idle qps duration metadata" > config.out
  echo "uuid event-weighted time-weighted progress" > $LOGDIR/summary
fi

echo "${LOGFILE} ${TYPE} ${ITER} ${SECONDARY_WORKERS} ${TARGET_IDLE_CORES} ${QPS} ${DURATION} ${META}" >> config.out
mkdir -p $LOGDEST

runMemcached() {
  # Start mutilate
  echo "[+] Run Memcached(mutilate)"

  MUTILATE_SVR="192.168.10.12:20003"
  TRIAL_NAME="$LOGFILE"

  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\",\"duration\":\"${DURATION}\"}" --header "Content-Type: application/json" http://${MUTILATE_SVR} 
} 

calcUtil() {
  if [ $TYPE == "harvest" ]; then
    PROGRESS=$(get_secondary_progress)
    #PROGRESS=$(ssh clabsvr "kubectl logs cpubully-secondary | grep -a \"Combined Progress\" | tail -n1")
    #PROGRESS=$(ssh clabsvr "kubectl logs fibtest-secondary | grep -a \"Iterations\" | tail -n1")
  fi
  UTIL_SUMMARY=$(grep "average active cores" cpuloggersummary.log | awk '{print $NF}' | tr "\n" " ")
  echo "$LOGFILE $UTIL_SUMMARY \"$PROGRESS\""  >> $LOGDIR/summary
}

calcLats() {
ssh clabcl1 bash <<EOF


  cd $WORKING_DIR/Results/Memcached/

  if [ ! -f "summary" ]; then
    echo "uuid mean min p90 p95 p99 achieved_qps" > summary
  fi

  ACHQPS=\$(cat $LOGFILE/stdout.log | grep "Total QPS" | awk '{print \$4}')

  SUMMARY=\$(cat $LOGFILE/stdout.log | grep read | awk '{print \$2" "\$4" "\$7" "\$8" "\$9}')
  
  echo "${LOGFILE} \${SUMMARY} \${ACHQPS}" >> summary
EOF

}

baseline() {
  loadModule idlecpu
  startModule idlecpu

  echo "[+] Starting logging"
  startLogging idlecpu

  runMemcached

  echo "[+] Stopping modules"
  stopLogging idlecpu
  stopModule idlecpu

  echo "[+] Retrieving logs"
  getLoggerLog idlecpu /tmp

  unloadModule idlecpu

  echo "[+] summarize stats"
  python ../Tools/parse_cpulogger2.py /tmp/cpulogger.log $CPULIST > cpuloggersummary.log 
  calcUtil
  calcLats
  mv *.log $LOGDEST/

  echo "[+] Done."
}

harvest() {
  SECONDARY_PID="-1"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  sendPodId $(secondary_pod_id)

  echo "[+] Starting logging"
  startLogging idlecpu
 
  # env vars for dynamic balancer (time in us)
  #export DEFICIT_THRESHOLD=0.50
  #export SURPLUS_THRESHOLD=0.50
  #export POSTDEFICIT_BUFFER_SAMPLE_RATE=1000000
  #export POSTSURPLUS_BUFFER_SAMPLE_RATE=1000000
  #export AGGIDLE_CORES_COUNT_THRESHOLD=2.5
  #export LOWIDLEFREQ_THRESHOLD=0.0483
  #export LOW_TIC=2
  export DEFICIT_THRESHOLD=0.50
  export SURPLUS_THRESHOLD=0.50
  export DEFICIT_BUFFER_SAMPLE_RATE=500000
  export SURPLUS_BUFFER_SAMPLE_RATE=1000000
  export AGGIDLE_CORES_COUNT_THRESHOLD=2.5
  #export LOWIDLEFREQ_THRESHOLD=0.0104
  #export LOWIDLEFREQ_THRESHOLD=0.008712 #50k, tic4
  export LOWIDLEFREQ_THRESHOLD=0.003 #150k, tic7
  export LOW_TIC=2

  runBalancer

  echo "[+] Start primary workload in background"
  runMemcached &

  echo "[+] Start secondary workload in foreground"
  secondary $DURATION


  echo "[+] Stopping Modules"
  stopLogging idlecpu
  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sudo kill -10 `pgrep listener`


  echo "[+] Retrieving logs"
  getLoggerLog idlecpu /tmp
  sleep 2;

  unloadModule idlecpu

  echo "[+] summarize stats"
  python ../Tools/parse_cpulogger2.py /tmp/cpulogger.log $CPULIST > cpuloggersummary.log 
  calcUtil
  calcLats
  mv *.log $LOGDEST/

  sleep 2;
  echo "[+] Done."
}

if [ $TYPE == "baseline" ]; then
  baseline
elif [ $TYPE == "harvest" ]; then
  harvest
elif [ $TYPE == "secondary" ]; then
  secondary 1
else
  echo "Unknown TYPE: $TYPE"
fi
