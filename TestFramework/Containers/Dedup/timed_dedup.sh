#!/bin/bash

NUM_THREADS=$1
DURATION=$2

rm -f /mnt/extra/inputs/results*.out

timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results1.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results2.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results3.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results4.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results5.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results6.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results7.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results8.out &
timeout -s SIGINT ${DURATION} ./dedup -v -c -i /mnt/extra/inputs/synthetic.data -o /mnt/extra/inputs/results9.out

echo "dedup, $DURATION seconds, $NUM_THREADS workers"
TotalSize=$(du -ch /mnt/extra/inputs/results*.out | grep total | awk '{print $1}')
echo $TotalSize
#cat /tmp/dedup.out
rm -f /mnt/extra/inputs/results*.out
