#!/bin/bash

# if you source secondary.sh, make sure to set the following variables accordingly prior to calling functions in this file.
MASTER="clabsvr"
SECONDARY=cpubully-secondary
ITER=1
SECONDARY_WORKERS=9



secondary_pod_id() {
  PODFILE=${SECONDARY}_podinfo.txt
  rm -f $PODFILE
  bash ../Tools/get_pod_info.sh $MASTER $SECONDARY
  echo "pod$(cat $PODFILE | jq -r .metadata.uid)"
}

irq_secondary() {
  DURATION=$1
  HOST=$2

  ssh clabsvr bash <<EOF
  num_clients=10
  for((i=0;i<num_clients;i++)); do
    port=\$((30301+i))
    iperf3 -c 192.168.10.11 -t $DURATION -p \$port > /tmp/\$port.out 2>&1 &
  done
EOF

  let dur=$DURATION/60
  curl --data "{\"duration\":\"${dur}\",\"workers\":\"${SECONDARY_WORKERS}\",\"trial\":\"${ITER}\"}" --header "Content-Type: application/json" http://192.168.10.11:30000/

}


# secondary <duration> <host> <secondary>
secondary() {

  if [ ! -z $3 ]; then
    SECONDARY=$3
  fi

  if [ $SECONDARY == "nwbully-secondary" ]; then
    irq_secondary $1 $2
  fi

  #WARNING note duration in minutes for cpubully
  if [ $SECONDARY == "cpubully-secondary" ]; then
    let SECONDARY_DURATION=$1/60
  else
    SECONDARY_DURATION=$1
  fi

  SECONDARY_HOST=$2
  if [ -z "$SECONDARY_HOST" ]; then
    SECONDARY_HOST="192.168.10.11:30000"
  fi


  curl --data "{\"duration\":\"${SECONDARY_DURATION}\",\"workers\":\"${SECONDARY_WORKERS}\",\"trial\":\"${ITER}\"}" --header "Content-Type: application/json" http://${SECONDARY_HOST}
}

get_secondary_progress() {
  if [ $SECONDARY == "cpubully-secondary" ] || [ $SECONDARY == "nwbully-secondary" ]; then
    get_cpubully_progress
  elif [ $SECONDARY == "x264-secondary" ]; then
    get_x264_progress
  elif [ $SECONDARY == "dedup-secondary" ]; then
    get_dedup_progress
  else
    echo "[-] Secondary workload not supported"
    exit 1
  fi
}

get_cpubully_progress() {
  ssh clabsvr "kubectl logs cpubully-secondary | grep -a \"Combined Progress\" | tail -n1"
}

get_x264_progress() {
  ssh clabsvr "kubectl logs x264-secondary | tac | grep -m 1 -e x264 -B 10" > secondary.log
  head -n -1 secondary.log | awk '{s+=$2} END {print s}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

get_dedup_progress() {
  ssh clabsvr "kubectl logs dedup-secondary | tac | grep -m1 dedup, -B 500" > secondary.log
  cat secondary.log | sed 's/^[ \t]*//;s/[ \t]*$//'
}

main() {

  SECONDARY_WORKERS=1
  ITER=1
  secondary 60

}

#main
