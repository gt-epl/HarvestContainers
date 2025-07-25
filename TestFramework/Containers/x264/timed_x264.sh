#!/bin/bash

NUM_THREADS=$1
DURATION=$2

timeout -s SIGINT $DURATION ./x264.sh ${NUM_THREADS} > /tmp/x264.out 2>&1
echo "x264, $DURATION seconds, $NUM_THREADS workers"
grep "encoded" /tmp/x264.out 
