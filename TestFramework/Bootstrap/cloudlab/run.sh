#!/usr/bin/env bash
MUTILATE_M="clabcl2"

MUTILATE_A="clabcl0"
AGENT_IP="192.168.10.11"

MEMCACHED_HOST="clabcl1"
MEMCACHED_SERVER="192.168.10.12:30104"

MUTILATE_DIR="/harvest/HarvestContainers/TestFramework/Containers/Mutilate"

load_mutilate() {

  echo "[+] Load dataset"
  ssh ${MUTILATE_M} bash <<EOF
  cd $MUTILATE_DIR
  # e.g ./mutilate -s 192.168.10.12:30104 -K fb_key -V fb_value -r 1000000 -i fb_ia --loadonly
  ./mutilate -s $MEMCACHED_SERVER -K fb_key -V fb_value -r 1000000 -i fb_ia --loadonly
EOF
}

run_mutilate_agent() {
  NUMTHREADS_A=$1

  echo "[+] Start mutilate agent"
  ssh ${MUTILATE_A} bash <<EOF &
  cd $MUTILATE_DIR
  # e.g ./mutilate -T 8 -A
  ./mutilate -T $NUMTHREADS_A -A
EOF
}

run_mutilate_master() {
  NUMTHREADS_M=8
  QPS_M=1000

  NUMCONN_A=1

  DURATION=$1
  QPS_A=$2
  id=$3

  if [ -z $id ]; then
    id="test"
  fi

  ssh ${MUTILATE_M} bash <<EOF
  cd $MUTILATE_DIR
  ./mutilate -s $MEMCACHED_SERVER \
             -K fb_key -V fb_value -r 1000000 -i fb_ia --noload \
             -T $NUMTHREADS_M \
             -Q $QPS_M \
             -D 1 -C 1 \
             -a $AGENT_IP \
             -c $NUMCONN_A \
             -t $DURATION \
             -q $QPS_A >> run.qps_$QPS_A.$id
EOF
}

run_mutilate_master_scan() {
  DURATION=$1
  SCAN=$2 #format=low:high:step
  id=$3

  echo "[+] Running scan"
  echo "[.] duration : $DURATION"
  echo "[.] scan : $SCAN"
  echo "[.] id : $id"
  echo "[.] memcached server : $MEMCACHED_SERVER"
  echo "[.] mutilate_dir : $MUTILATE_DIR"

  NUMTHREADS_M=8
  QPS_M=1000

  NUMCONN_A=1

  if [ -z $id ]; then
    id="test"
  fi

  ssh ${MUTILATE_M} bash <<EOF
  cd $MUTILATE_DIR
  ./mutilate -s $MEMCACHED_SERVER \
             -K fb_key -V fb_value -r 1000000 -i fb_ia --noload \
             -T $NUMTHREADS_M \
             -Q $QPS_M \
             -D 1 -C 1 \
             -a $AGENT_IP \
             -c $NUMCONN_A \
             -t $DURATION \
             --scan $SCAN >> scan.qps_$SCAN.$id
EOF
}

kill_mutilate() {
  echo "[+] Kill mutilate instances if any."
  ssh $MUTILATE_A "pkill mutilate"
  ssh $MUTILATE_M "pkill mutilate"
}

run_scan_test() {

  #TODO: SAR command: sar -P 0-7 -u 1 3
  #TODO: also start memcached here

  run_mutilate_agent 8 #num_threads

  load_mutilate

  durations=(10)
  max_cores=8
  for dur in ${durations[@]}; do
    for ((upper=1; upper<max_cores; upper++)); do

      # pin cores
      ./pinmc.sh 0-$upper $MEMCACHED_HOST

      #begin load
      run_mutilate_master_scan $dur 10000:150000:20000 run1_c0-$upper
      #run_mutilate_master_scan $dur 10000:70000:20000 run2_c0-$upper
      #run_mutilate_master_scan $dur 10000:70000:20000 run3_c0-$upper
      #run_mutilate_master_scan $dur 10000:70000:10000 4
      #run_mutilate_master_scan $dur 10000:70000:10000 5

    done
  done

  kill_mutilate
}

debug() {

  run_mutilate_agent 8 #num_threads
  load_mutilate
  

      dur=10
      upper=4
      # pin cores
      ./pinmc.sh 0-$upper $MEMCACHED_HOST

      #begin load
      run_mutilate_master_scan $dur 10000:70000:10000 1
      #run_mutilate_master_scan $dur 10000:70000:10000 2
      #run_mutilate_master_scan $dur 10000:70000:10000 3
      
      #kill mutilate
      kill_mutilate
}

#debug
run_scan_test

