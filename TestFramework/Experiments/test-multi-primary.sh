#!/bin/bash

start=1
end=1
dur=60

#./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>

mkdir -p /mnt/extra/config
mkdir -p /mnt/extra/results/multi-primary
mkdir -p /mnt/extra/logs/multi-primary

ssh clabsvr bash << EOF
mkdir -p /mnt/extra/config
mkdir -p /mnt/extra/results/multi-primary
mkdir -p /mnt/extra/logs/multi-primary
EOF

xapian_cpulist=2,4,6,8,10,12,14,16
mysql_cpulist=1,3,5,7,9,11,13,15
x264_cpulist=18
dedup_cpulist=19

echo "[+] Pinning cores for workloads"
cur_dir=$(pwd)
cd ~/HarvestContainers/TestFramework/Tools/
./pincores.sh $mysql_cpulist clabcl1 mysql-primary
./pincores.sh $xapian_cpulist clabcl1 xapian-primary 
./pincores.sh $x264_cpulist clabcl1 x264-secondary
./pincores.sh $dedup_cpulist clabcl1 dedup-secondary
cd $cur_dir

start_time=$(date +%s)

#./multi-primary_runner.sh 1 9 7 HIGH $dur baseline $mysql_cpulist $xapian_cpulist
./multi-primary_runner.sh 1 9 7 HIGH $dur harvest $mysql_cpulist $xapian_cpulist

echo "[+] copy results to clabcl1"
rsync -avz clabsvr:/mnt/extra/results/multi-primary /mnt/extra/results/

end_time=$(date +%s)
echo "[+] multi-primary runtime: $((end_time - start_time)) seconds"

mv multi-primary_config.out /mnt/extra/config/
