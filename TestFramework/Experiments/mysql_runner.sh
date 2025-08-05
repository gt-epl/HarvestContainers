#!/bin/bash

# Usage: ./mysql_runner.sh <iteration> <secondary_workers> <target_idle_cores> <qps> <duration> <type>
# e.g.,: ./mysql_runner.sh 1 1 1 1000 60 baseline

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh
source ./secondary.sh

YCSB_ALIAS="clabsvr"
YCSB_HOST=192.168.10.11:32002

ITER=$1
SECONDARY_WORKERS=$2
TARGET_IDLE_CORES=$3
QPS=$4
DURATION=$5
TYPE="$6"


if [ -z $7 ]; then
  META="8c,8st,1ct"
else
  META=$7
fi

LOGDIR="/mnt/extra/logs/mysql"
RESDIR="/mnt/extra/results/mysql"
SUMMARY_FILE="summary"

if [ $TYPE == "harvest-irq" ] || [ $TYPE == "baseline-irq" ]; then
  YCSB_ALIAS="clabcl1"
  YCSB_HOST="192.168.10.11:32004"
  SUMMARY_FILE="mysql-irq.summary"
fi

mkdir -p $LOGDIR

LOGFILE=$(cat /proc/sys/kernel/random/uuid)
LOGDEST=$LOGDIR/$LOGFILE
CFGFILE="mysql_config.out"

if [ ! -f $CFGFILE ]; then
  echo "uuid type iter sec_workers target_idle qps duration metadata" > $CFGFILE
  echo "uuid event-weighted time-weighted progress" > $LOGDIR/$SUMMARY_FILE
fi

echo "${LOGFILE} ${TYPE} ${ITER} ${SECONDARY_WORKERS} ${TARGET_IDLE_CORES} ${QPS} ${DURATION} ${META}" >> $CFGFILE
mkdir -p $LOGDEST

runMysql() {
  # Start ycsb
  curl --data "{\"trial\":\"${LOGFILE}\",\"qps\":\"${QPS}\",\"duration\":\"${DURATION}\"}" --header "Content-Type: application/json" http://${YCSB_HOST}/run

}

calcUtil() {
  if [ $TYPE == "harvest" ] || [ $TYPE == "harvest-irq" ]; then
    PROGRESS=$(get_secondary_progress)
  fi
  UTIL_SUMMARY=$(grep "average active cores" cpuloggersummary.log | awk '{print $NF}' | tr "\n" " ")
  echo "$LOGFILE $UTIL_SUMMARY\"$PROGRESS\""  >> $LOGDIR/$SUMMARY_FILE
}

calcLats() {
ssh $YCSB_ALIAS bash <<EOF
  sudo -s 
  cd $RESDIR
  if [ ! -f "$SUMMARY_FILE" ]; then
    echo "uuid mean p90 p95 p99 min max ops" > $SUMMARY_FILE
  fi
  echo "${LOGFILE} \$(python ~/HarvestContainers/TestFramework/Containers/MySQL/parsemysql.py ${RESDIR}/$LOGFILE.out)" | tee -a $SUMMARY_FILE
EOF
}


baseline() {
  loadModule idlecpu
  startModule idlecpu

  echo "[+] Starting logging"
  startLogging idlecpu

  runMysql

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
  sudo mv *.log $LOGDEST/

  echo "[+] Done."
}

harvest() {
  SECONDARY_PID="-1"

  loadModule idlecpu
  startModule idlecpu
  if [ $META == "aware" ]; then
    sleep 2
    echo "[+] Enabling IRQ awareness"
    ./make_irq_aware.sh
    echo "[+] IRQ awareness enabled"
    sleep 2
  fi

  runListener
  sleep 3
  sendPodId $(secondary_pod_id)
  sleep 3
  sendPrimaryInfo $CPULIST 0.002
  sleep 3

  echo "[+] Starting logging"
  startLogging idlecpu

  export DEFICIT_THRESHOLD=0.50
  export SURPLUS_THRESHOLD=0.50
  export DEFICIT_BUFFER_SAMPLE_RATE=500000
  export SURPLUS_BUFFER_SAMPLE_RATE=1000000
  export AGGIDLE_CORES_COUNT_THRESHOLD=2.5
  export LOWIDLEFREQ_THRESHOLD=0.002
  export LOW_TIC=2

  runBalancer
 
  echo "[+] Start primary workload in background"
  runMysql &

  echo "[+] Start secondary workload in foreground"
  if [ $TYPE == "harvest-irq" ]; then
    secondary $DURATION "192.168.10.11:30300" "nwbully-secondary"
  else  
    secondary $DURATION
  fi


  echo "[+] Stopping Modules"
  stopLogging idlecpu
  stopModule idlecpu

  sudo kill -10 `pgrep balancer`
  sudo kill -10 `pgrep listener`

  echo "[+] Retrieving logs"
  getLoggerLog idlecpu /tmp

  sleep 5;
  unloadModule idlecpu

  echo "[+] summarize stats"
  calcLats
  python ../Tools/parse_cpulogger2.py /tmp/cpulogger.log $CPULIST > cpuloggersummary.log 
  calcUtil
  sudo mv *.log $LOGDEST/


  sleep 2;
  echo "[+] Done."
}


if [ $TYPE == "baseline" ] || [ $TYPE == "baseline-irq" ]; then
  baseline
elif [ $TYPE == "harvest" ] || [ $TYPE == "harvest-irq" ]; then
  harvest
elif [ $TYPE == "secondary" ]; then
  secondary 60
else
  echo "Unknown TYPE: $TYPE"
fi
