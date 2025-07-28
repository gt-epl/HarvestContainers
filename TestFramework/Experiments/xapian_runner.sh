#!/bin/bash
# Usage: ./xapian_runner.sh <iteration> <secondary_workers> <target_idle_cores> <qps> <duration> <type>
# e.g.,: ./xapian_runner.sh 1 1 1 3000 60 baseline

source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh
source ./secondary.sh

MASTER="clabsvr" # used by secondary.sh
XAPIAN_IP="192.168.10.11"
XAPIAN_PORT="31000"
XAPIAN_ALIAS="clabcl1"
XAPIAN_SRC="../Containers/xapian/xapian-src/xapian"

ITER=$1
SECONDARY_WORKERS=$2
TARGET_IDLE_CORES=$3
QPS=$4
DURATION=$5
TYPE="$6"
META="8c,8st,1ct"
LOGDIR="/mnt/extra/logs/xapian"
RESDIR="/mnt/extra/results/xapian"


mkdir -p $LOGDIR
mkdir -p $RESDIR

LOGFILE=$(cat /proc/sys/kernel/random/uuid)
LOGDEST=$LOGDIR/$LOGFILE

if [ ! -f "config.out" ]; then
  echo "uuid type iter sec_workers target_idle qps duration metadata" > config.out
  echo "uuid mean p50 p90 p95 p99 min max" > $RESDIR/summary
  echo "uuid event-weighted time-weighted progress" > $LOGDIR/summary
fi

echo "${LOGFILE} ${TYPE} ${ITER} ${SECONDARY_WORKERS} ${TARGET_IDLE_CORES} ${QPS} ${DURATION} ${META}" >> config.out
mkdir -p $LOGDEST


runXapian() {
  cur=$(pwd)

  cd $XAPIAN_SRC
  ./k8sclient.sh $QPS $DURATION $XAPIAN_IP $XAPIAN_PORT

  cd $cur
}

calcUtil() {
  if [ $TYPE == "harvest" ]; then
    PROGRESS=$(get_secondary_progress)
  fi
  UTIL_SUMMARY=$(grep "average active cores" cpuloggersummary.log | awk '{print $NF}' | tr "\n" " ")
  echo "$LOGFILE $UTIL_SUMMARY \"$PROGRESS\""  >> $LOGDIR/summary
}

calcLats() {
  cur=$(pwd)

  cd $XAPIAN_SRC
  cp /dev/shm/results/lats.bin $RESDIR/$LOGFILE.bin
  echo "${LOGFILE} $(python parselats_old.py $RESDIR/$LOGFILE.bin)" >> $RESDIR/summary

  cd $cur
}


baseline() {
  loadModule idlecpu
  startModule idlecpu

  echo "[+] Starting logging"
  startLogging idlecpu

  runXapian

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
  export LOWIDLEFREQ_THRESHOLD=0.33
  export LOW_TIC=2

  runBalancer

  echo "[+] Start primary workload in background"
  runXapian &

  echo "[+] Start secondary workload in foreground"
  secondary $DURATION


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
