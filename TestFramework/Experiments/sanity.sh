#!/bin/bash

start=1
end=1
dur=60

#./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>

echo "[+] Pinning cores for workloads"
cur_dir=$(pwd)
cd ~/HarvestContainers/TestFramework/Tools/
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 memcached-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 mysql-primary
./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 xapian-primary 
./pincores.sh 18 clabcl1 cpubully-secondary
cd $cur_dir

start_time=$(date +%s)
./memcached_runner.sh 1 1 1 10000 60 baseline
./memcached_runner.sh 1 9 7 10000 60 harvest
./xapian_runner.sh 1 1 1 500 60 baseline
./xapian_runner.sh 1 9 7 500 60 harvest
./mysql_runner.sh 1 1 1 1000 60 baseline
./mysql_runner.sh 1 9 7 1000 60 harvest


echo "[+] copy results to clabcl1"
rsync -avz clabsvr:/mnt/extra/results/memcached /mnt/extra/results/
rsync -avz clabsvr:/mnt/extra/results/mysql /mnt/extra/results/

ssh clabsvr bash <<EOF
    sudo rm -rf /mnt/extra/results/memcached/*
    sudo rm -rf /mnt/extra/results/mysql/*
    sudo rm -rf /mnt/extra/logs/memcached/*
    sudo rm -rf /mnt/extra/logs/mysql/*
EOF

for app in memcached mysql xapian; do
    mv ${app}_config.out /mnt/extra/config/${app}-sanity_config.out
    mv /mnt/extra/results/${app}/summary /mnt/extra/results/${app}/sanity.summary
    mv /mnt/extra/logs/${app}/summary /mnt/extra/logs/${app}/sanity.summary
done

end_time=$(date +%s)

echo "[+] Sanity runtime: $((end_time - start_time)) seconds"

