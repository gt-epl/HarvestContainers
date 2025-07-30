#!/bin/bash

start=1
end=3
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

# memcached: ~116 minutes
start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for ((qps=10000; qps<=100000; qps+=10000)); do
    ./memcached_runner.sh $i 1 1 $qps $dur baseline
    ./memcached_runner.sh $i 9 7 $qps $dur harvest
  done 
done

echo "[+] copy results to clabcl1"
rsync -avz clabsvr:/mnt/extra/results/memcached /mnt/extra/results/

end_time=$(date +%s)
echo "[+] memcached runtime: $((end_time - start_time)) seconds"

mv memcached_config.out /mnt/extra/config/memcached_config.out

# xapian: ~76 minutes
start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for ((qps=500; qps<=4000; qps+=500)); do
    ./xapian_runner.sh $i 1 1 $qps $dur baseline
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
    ./mysql_runner.sh $i 1 1 $qps $dur baseline
    ./mysql_runner.sh $i 9 7 $qps $dur harvest
  done 
done

echo "[+] copy results to clabcl1"
rsync -avz clabsvr:/mnt/extra/results/mysql /mnt/extra/results/

end_time=$(date +%s)
echo "[+] mysql runtime: $((end_time - start_time)) seconds"

mv mysql_config.out /mnt/extra/config/mysql_config.out