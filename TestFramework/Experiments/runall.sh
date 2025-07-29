#!/bin/bash

start=1
end=3
dur=60

#./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>

# xapian
start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for ((qps=500; qps<=4000; qps+=500)); do
    ./xapian_runner.sh $i 1 1 $qps $dur baseline
    ./xapian_runner.sh $i 9 7 $qps $dur harvest
  done 
done

end_time=$(date +%s)
echo "[+] xapian runtime: $((end_time - start_time)) seconds"

mv xapian_config.out /mnt/extra/xapian_config.out

# memcached
start_time=$(date +%s)

for((i=start; i<=end; i++)); do
  for ((qps=10000; qps<=100000; qps+=10000)); do
    ./memcached_runner.sh $i 1 1 $qps $dur baseline
    ./memcached_runner.sh $i 9 7 $qps $dur harvest
  done 
done

end_time=$(date +%s)
echo "[+] memcached runtime: $((end_time - start_time)) seconds"

mv memcached_config.out /mnt/extra/memcached_config.out