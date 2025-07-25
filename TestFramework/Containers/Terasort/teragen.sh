#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

trap "" HUP

MR_EXAMPLES_JAR=./hadoop-2.7.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar

#SIZE=500G
#ROWS=5000000000

#SIZE=100G
#ROWS=1000000000

#SIZE=1T
#ROWS=10000000000

#SIZE=10G
#ROWS=100000000

#SIZE=1G
#ROWS=10000000

SIZE=100M
ROWS=1000000

LOGDIR=logs

if [ ! -d "$LOGDIR" ]
then
    mkdir ./$LOGDIR
fi

DATE=`date +%Y-%m-%d:%H:%M:%S`

RESULTSFILE="./$LOGDIR/teragen_results_$DATE"

OUTPUT=./teragen-out/${SIZE}-terasort-input

# Run teragen
time hadoop-2.7.1/bin/hadoop jar $MR_EXAMPLES_JAR teragen \
-Dmapreduce.map.log.level=INFO \
-Dmapreduce.reduce.log.level=INFO \
-Dyarn.app.mapreduce.am.log.level=INFO \
-Dio.file.buffer.size=131072 \
-Dmapreduce.map.cpu.vcores=1 \
-Dmapreduce.map.java.opts=-Xmx1536m \
-Dmapreduce.map.maxattempts=1 \
-Dmapreduce.map.memory.mb=2048 \
-Dmapreduce.map.output.compress=true \
-Dmapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.Lz4Codec \
-Dmapreduce.reduce.cpu.vcores=1 \
-Dmapreduce.reduce.java.opts=-Xmx1536m \
-Dmapreduce.reduce.maxattempts=1 \
-Dmapreduce.reduce.memory.mb=2048 \
-Dmapreduce.task.io.sort.factor=100 \
-Dmapreduce.task.io.sort.mb=384 \
-Dyarn.app.mapreduce.am.command.opts=-Xmx768m \
-Dyarn.app.mapreduce.am.resource.mb=1024 \
-Dmapred.map.tasks=92 \
${ROWS} ${OUTPUT} >> $RESULTSFILE 2>&1