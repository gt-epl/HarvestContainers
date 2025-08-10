#!/bin/bash

start=1
end=1
dur=60

#./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>

mkdir -p /mnt/extra/config
mkdir -p /mnt/extra/results
mkdir -p /mnt/extra/logs

ssh clabsvr bash << EOF
mkdir -p /mnt/extra/config
mkdir -p /mnt/extra/results
mkdir -p /mnt/extra/logs
EOF

xapian_cpulist=2,4,6,8,10,12,14,16
mysql_cpulist=1,3,5,7,9,11,13,15
x264_cpulist=18
dedup_cpulist=19

pincores() {
  echo "[+] Pinning cores for workloads"
  cur_dir=$(pwd)
  cd ~/HarvestContainers/TestFramework/Tools/
  ./pincores.sh $mysql_cpulist clabcl1 mysql-primary
  ./pincores.sh $xapian_cpulist clabcl1 xapian-primary 
  ./pincores.sh $x264_cpulist clabcl1 x264-secondary
  ./pincores.sh $dedup_cpulist clabcl1 dedup-secondary
  cd $cur_dir
}

start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for qps in LOW MEDIUM HIGH; do
    pincores
    ./multi-primary_runner.sh $i 1 1 $qps $dur baseline $mysql_cpulist $xapian_cpulist
    pincores
    ./multi-primary_runner.sh $i 9 7 $qps $dur harvest $mysql_cpulist $xapian_cpulist
  done 
done

echo "[+] copy results to clabcl1"
rsync -avz clabsvr:/mnt/extra/results/multi-primary /mnt/extra/results/

end_time=$(date +%s)
echo "[+] multi-primary runtime: $((end_time - start_time)) seconds"

mv multi-primary_config.out /mnt/extra/config/
