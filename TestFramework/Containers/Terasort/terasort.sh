#!/bin/bash

#rm -rf /outputs/terasort-output
#rm -f /outputs/terasort_console.out
ERRFILE=/mnt/data/outputs/stderr.log

echo "\n---"
echo "Start Terasort"

if [ "$1" == "10G" ]; then
    timeout $2 /usr/local/hadoop-2.7.1/bin/hadoop jar /usr/local/hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar terasort /mnt/data/inputs/10G-terasort-input /mnt/data/outputs/terasort-output 2>$ERRFILE
elif [ "$1" == "2G" ]; then
    timeout $2 /usr/local/hadoop-2.7.1/bin/hadoop jar /usr/local/hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar terasort /mnt/data/inputs/2G-terasort-input /mnt/data/outputs/terasort-output 2>$ERRFILE
elif [ "$1" == "1G" ]; then
    timeout $2 /usr/local/hadoop-2.7.1/bin/hadoop jar /usr/local/hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar terasort /mnt/data/inputs/1G-terasort-input /mnt/data/outputs/terasort-output 2>$ERRFILE
else
    timeout $2 /usr/local/hadoop-2.7.1/bin/hadoop jar /usr/local/hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar terasort /mnt/data/inputs/100M-terasort-input /mnt/data/outputs/terasort-output 2>$ERRFILE
fi
echo "---\n"
