#!/bin/bash

start=1
end=1
dur=60

#./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>

pincores() {
  echo "[+] Pinning cores for workloads"
  cur_dir=$(pwd)
  cd ~/HarvestContainers/TestFramework/Tools/
  ./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 memcached-primary
  ./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 mysql-primary
  ./pincores.sh 2,4,6,8,10,12,14,16 clabcl1 xapian-primary
  ./pincores.sh 18 clabcl1 cpubully-secondary
  cd $cur_dir
}

# memcached: ~116 minutes
start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for ((qps=10000; qps<=100000; qps+=10000)); do
    pincores
    ./memcached_runner.sh $i 1 1 $qps $dur baseline
    pincores
    ./memcached_runner.sh $i 9 7 $qps $dur harvest
  done 
done

echo "[+] copy results to clabcl1"
rsync -avz clabsvr:/mnt/extra/results/memcached /mnt/extra/results/
sudo chown -R $USER /mnt/extra/results/*

end_time=$(date +%s)
echo "[+] memcached runtime: $((end_time - start_time)) seconds"

mv memcached_config.out /mnt/extra/config/memcached_config.out

# xapian: ~76 minutes
start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for ((qps=500; qps<=4000; qps+=500)); do
    pincores
    ./xapian_runner.sh $i 1 1 $qps $dur baseline
    pincores
    ./xapian_runner.sh $i 9 7 $qps $dur harvest
  done 
done

end_time=$(date +%s)
echo "[+] xapian runtime: $((end_time - start_time)) seconds"

mv xapian_config.out /mnt/extra/config/xapian_config.out

# mysql
start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for ((qps=1000; qps<=8000; qps+=1000)); do
    pincores
    ./mysql_runner.sh $i 1 1 $qps $dur baseline
    pincores
    ./mysql_runner.sh $i 9 7 $qps $dur harvest
  done 
done

echo "[+] copy results to clabcl1"
rsync -avz clabsvr:/mnt/extra/results/mysql /mnt/extra/results/
sudo chown -R $USER /mnt/extra/results/*

end_time=$(date +%s)
echo "[+] mysql runtime: $((end_time - start_time)) seconds"

mv mysql_config.out /mnt/extra/config/mysql_config.out
