#!/bin/bash

start=1
end=3
dur=60

#./<workload>_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>

for((i=start; i<=end; i++)); do

  # memcached
  # for ((qps=10000;qps<=130000;qps+=10000)); do
    #./memcached_runner.sh $i 1 1 $qps $dur baseline

  #for qps in 500 1000 1500 2000 2500 3000 3500 4000 4500; do
  #for qps in 1000 2000 3000 4000; do
  #for qps in 2000 2500; do
  #for qps in 500 1000 1500 2000 2500 3000 3500 4000 4500 5000 5500 6000; do
  for qps in 500 2500 4000; do
    #bash cleanterasortdirs.sh #required for terasort
    #./xapian_runner.sh $i 9 3 $qps $dur "harvest"
    #./xapian_runner.sh <trial_num> <num_secondary_workers> <tic> <qps> <dur> <harvest/baseline>
    ./xapian_runner.sh $i 1 1 $qps $dur baseline


  done 
done

