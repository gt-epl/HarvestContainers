#!/bin/bash

NUM_THREADS=$1

DATE=$(date '+%Y-%m-%d_%H-%M-%S')
INPUTS=/mnt/data/inputs/eledream_1920x1080_512.y4m


while true; do
trap break SIGINT SIGTERM
./x264 --threads ${NUM_THREADS} -q 0 -o test.mkv $INPUTS
done
