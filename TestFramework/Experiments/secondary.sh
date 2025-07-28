#!/bin/bash

SECONDARY=cpubully-secondary
#SECONDARY="x264-secondary"
#SECONDARY="terasort-secondary"
#SECONDARY="dedup-secondary"



secondary_pod_id() {
  #SECONDARY=fibtest-secondary
  PODFILE=${SECONDARY}_podinfo.txt
  rm -f $PODFILE
  bash ../Tools/get_pod_info.sh $MASTER $SECONDARY
  echo "pod$(cat $PODFILE | jq -r .metadata.uid)"
}

secondary() {
  SECONDARY_IP="192.168.10.11"

  #WARNING note duration in minutes for cpubully
  let SECONDARY_DURATION=$1/60


  curl --data "{\"duration\":\"${SECONDARY_DURATION}\",\"workers\":\"${SECONDARY_WORKERS}\",\"trial\":\"${ITER}\"}" --header "Content-Type: application/json" http://${SECONDARY_IP}:30000
}

get_secondary_progress() {
  get_cpubully_progress
  #get_x264_progress
  #get_terasort_progress
  #get_dedup_progress
}

get_cpubully_progress() {
  ssh clabsvr "kubectl logs cpubully-secondary | grep -a \"Combined Progress\" | tail -n1"
}

get_x264_progress() {
  ssh clabsvr "kubectl logs x264-secondary | tac | grep -m 1 -e x264 -B 10" > secondary.log
  head -n -1 secondary.log | awk '{s+=$2} END {print s}'
}

get_terasort_progress() {
  grep -i "finishing task" /mnt/extra/terasort.outputs/stderr.log  | wc -l
}

get_dedup_progress() {
  ssh clabsvr "kubectl logs dedup-secondary | tac | grep -m1 dedup, -B 500" > secondary.log
  cat secondary.log
}

main() {

  SECONDARY_WORKERS=1
  ITER=1
  secondary 60

}

#main
