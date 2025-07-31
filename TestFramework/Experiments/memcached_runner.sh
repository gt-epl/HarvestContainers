#!/bin/bash

# Usage: ./memcached_runner.sh <iteration> <secondary_workers> <target_idle_cores> <qps> <duration> <type>
# e.g.,: ./memcached_runner.sh 1 1 1 10000 60 baseline

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh
source ./secondary.sh

MUTILATE_ALIAS="clabsvr"
MUTILATE_HOST="192.168.10.10:32003"
MEMCACHED_HOST="192.168.10.11:31212"

ITER=$1
SECONDARY_WORKERS=$2
TARGET_IDLE_CORES=$3
QPS=$4
DURATION=$5
TYPE="$6"

META="mutilate"
LOGDIR="/mnt/extra/logs/memcached"
RESDIR="/mnt/extra/results/memcached"

mkdir -p $LOGDIR


LOGFILE=$(cat /proc/sys/kernel/random/uuid)
LOGDEST=$LOGDIR/$LOGFILE
CFGFILE="memcached_config.out"

if [ ! -f "$CFGFILE" ]; then
  echo "uuid type iter sec_workers target_idle qps duration metadata" > $CFGFILE
  echo "uuid event-weighted time-weighted progress" > $LOGDIR/summary
fi

echo "${LOGFILE} ${TYPE} ${ITER} ${SECONDARY_WORKERS} ${TARGET_IDLE_CORES} ${QPS} ${DURATION} ${META}" >> $CFGFILE
mkdir -p $LOGDEST

runMemcached() {
  # Start mutilate
  echo "[+] Run Memcached(mutilate)"

  TRIAL_NAME="$LOGFILE"

  curl --data "{\"trial\":\"${TRIAL_NAME}\",\"qps\":\"${QPS}\",\"duration\":\"${DURATION}\",\"memcached_server\":\"${MEMCACHED_HOST}\"}" --header "Content-Type: application/json" http://${MUTILATE_HOST}/run 
} 

calcUtil() {
  if [ $TYPE == "harvest" ]; then
    PROGRESS=$(get_secondary_progress)
  fi
  UTIL_SUMMARY=$(grep "average active cores" cpuloggersummary.log | awk '{print $NF}' | tr "\n" " ")
  echo "$LOGFILE $UTIL_SUMMARY\"$PROGRESS\""  >> $LOGDIR/summary
}

calcLats() {
ssh $MUTILATE_ALIAS bash <<EOF

  cd $RESDIR

  if [ ! -f "summary" ]; then
    echo "uuid mean min p90 p95 p99 achieved_qps" | sudo tee summary
  fi

  ACHQPS=\$(cat $LOGFILE/stdout.log | grep "Total QPS" | awk '{print \$4}')
  SUMMARY=\$(cat $LOGFILE/stdout.log | grep read | awk '{print \$2" "\$4" "\$7" "\$8" "\$9}')
  
  echo "${LOGFILE} \${SUMMARY} \${ACHQPS}" | sudo tee -a summary
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
  export DEFICIT_THRESHOLD=0.50
  export SURPLUS_THRESHOLD=0.50
  export DEFICIT_BUFFER_SAMPLE_RATE=500000
  export SURPLUS_BUFFER_SAMPLE_RATE=1000000
  export AGGIDLE_CORES_COUNT_THRESHOLD=2.5
  export LOWIDLEFREQ_THRESHOLD=0.001 #100k, tic7
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
