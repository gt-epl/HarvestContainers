#!/bin/bash
# Usage: ./multi-primary_runner.sh <iteration> <secondary_workers> <target_idle_cores> <qps> <duration> <type>
# e.g.,: ./multi-primary_runner.sh 1 1 1 3000 60 baseline

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh
source ./secondary.sh

XAPIAN_IP="192.168.10.11"
XAPIAN_PORT="31000"
XAPIAN_ALIAS="clabcl1"
XAPIAN_SRC="../Containers/xapian/xapian-src/xapian"

YCSB_ALIAS="clabsvr"

ITER=$1
SECONDARY_WORKERS=$2
TARGET_IDLE_CORES=$3
QPS=$4 # LOW, MEDIUM, HIGH
DURATION=$5
TYPE="$6"
MYSQL_CPULIST=$7
XAPIAN_CPULIST=$8

META="multi-primary"
LOGDIR="/mnt/extra/logs/multi-primary"
RESDIR="/mnt/extra/results/multi-primary"


mkdir -p $LOGDIR
mkdir -p $RESDIR

LOGFILE=$(cat /proc/sys/kernel/random/uuid)
LOGDEST=$LOGDIR/$LOGFILE
CFGFILE="multi-primary_config.out"

if [ ! -f "$CFGFILE" ]; then
  echo "uuid type iter sec_workers target_idle qps duration metadata" > $CFGFILE
  echo "uuid event-weighted time-weighted x264_progress dedup_progress" > $LOGDIR/summary
fi

if [ $QPS == "LOW" ]; then
  XAPIAN_QPS=500
  MYSQL_QPS=1000
elif [ $QPS == "MEDIUM" ]; then
  XAPIAN_QPS=2500
  MYSQL_QPS=4000
elif [ $QPS == "HIGH" ]; then
  XAPIAN_QPS=4000
  MYSQL_QPS=8000
fi

echo "${LOGFILE} ${TYPE} ${ITER} ${SECONDARY_WORKERS} ${TARGET_IDLE_CORES} ${QPS} ${DURATION} ${META}" >> $CFGFILE
mkdir -p $LOGDEST


runXapian() {
  cur=$(pwd)

  cd $XAPIAN_SRC
  ./k8sclient.sh $QPS $DURATION $XAPIAN_IP $XAPIAN_PORT

  cd $cur
}

runMysql() {
  # Start ycsb
  curl --data "{\"trial\":\"${LOGFILE}\",\"qps\":\"${QPS}\",\"duration\":\"${DURATION}\"}" --header "Content-Type: application/json" http://192.168.10.10:32002/run

}

calcUtil() {
  if [ $TYPE == "harvest" ]; then
    X264_PROGRESS=$(get_x264_progress)
    DEDUP_PROGRESS=$(get_dedup_progress)
  fi
  UTIL_SUMMARY=$(grep "average active cores" cpuloggersummary.log | awk '{print $NF}' | tr "\n" " ")
  echo "$LOGFILE $UTIL_SUMMARY\"$X264_PROGRESS\" \"$DEDUP_PROGRESS\""  >> $LOGDIR/summary
}

calcLats() {
  cur=$(pwd)

  if [ ! -f "summary" ]; then
    echo "uuid mean p50 p90 p95 p99 min max" > $RESDIR/xapian.summary
  fi

  cd $XAPIAN_SRC
  cp /dev/shm/results/lats.bin $RESDIR/$LOGFILE.bin
  echo "${LOGFILE} $(python parselats_old.py $RESDIR/$LOGFILE.bin)" | tee -a $RESDIR/xapian.summary

  cd $cur

  ssh $YCSB_ALIAS bash <<EOF
  sudo -s 
  cd $RESDIR
  if [ ! -f "summary" ]; then
    echo "uuid mean p90 p95 p99 min max ops" > mysql.summary
  fi
  echo "${LOGFILE} \$(python ~/HarvestContainers/TestFramework/Containers/MySQL/parsemysql.py ${RESDIR}/$LOGFILE.out)" | tee -a mysql.summary
EOF
}


baseline() {
  loadModule idlecpu
  startModule idlecpu

  echo "[+] Starting logging"
  startLogging idlecpu

  runXapian &
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
  mv *.log $LOGDEST/

  echo "[+] Done."
}

harvest() {

  SECONDARY_PID="-1"

  loadModule idlecpu
  startModule idlecpu

  runListener
  sleep 3
  # xapian info
  XAPIAN_LOWIDLEFREQ_THRESHOLD=0.33
  sendPrimaryInfo $XAPIAN_CPULIST $XAPIAN_LOWIDLEFREQ_THRESHOLD
  MYSQL_LOWIDLEFREQ_THRESHOLD=0.002
  sendPrimaryInfo $MYSQL_CPULIST $MYSQL_LOWIDLEFREQ_THRESHOLD

  SECONDARY=x264-secondary
  sendSecondaryPodID $(secondary_pod_id)
  SECONDARY=dedup-secondary
  sendSecondaryPodID $(secondary_pod_id)


  echo "[+] Starting logging"
  startLogging idlecpu
 
  # env vars for dynamic balancer (time in us)
  export DEFICIT_THRESHOLD=0.50
  export SURPLUS_THRESHOLD=0.50
  export DEFICIT_BUFFER_SAMPLE_RATE=500000
  export SURPLUS_BUFFER_SAMPLE_RATE=1000000
  export AGGIDLE_CORES_COUNT_THRESHOLD=2.5
  export LOWIDLEFREQ_THRESHOLD=0.33
  export LOW_TIC=2

  runBalancer

  echo "[+] Start primary workload in background"
  runXapian &
  runMysql &

  echo "[+] Start x264 workload in background"
  secondary $DURATION "192.168.10.11:30002" "x264-secondary"

  echo "[+] Start dedup workload in foreground"
  secondary $DURATION "192.168.10.11:30001" "dedup-secondary"

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
  mv *.log $LOGDEST/

  sleep 5;
  echo "[+] Done."
}


if [ $TYPE == "baseline" ]; then
  baseline
elif [ $TYPE == "harvest" ]; then
  harvest
elif [ $TYPE == "secondary" ]; then
  secondary 60
else
  echo "Unknown TYPE: $TYPE"
fi
