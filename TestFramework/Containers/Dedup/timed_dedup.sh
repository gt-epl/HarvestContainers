#!/bin/bash

NUM_THREADS=$1
DURATION=$2

rm -f /mnt/data/inputs/results*.out

timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results1.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results2.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results3.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results4.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results5.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results6.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results7.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results8.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/data/inputs/synthetic.data -o /mnt/data/inputs/results9.out

echo "dedup, $DURATION seconds, $NUM_THREADS workers"
FinalSize=$(ls -alh /mnt/data/inputs/results*.out)
TotalSize="dummy"
echo $FinalSize
echo $TotalSize
#cat /tmp/dedup.out
rm -f /mnt/data/inputs/results*.out
