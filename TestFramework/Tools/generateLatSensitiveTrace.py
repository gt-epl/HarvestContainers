#!/usr/bin/python3
import sys
import os
import csv
import json

if len(sys.argv) < 6:
    print("Usage: " + str(sys.argv[0]) + " <WorkerCount> <ActiveTime (us)> <IdleTime (us)> <Output Dir> <Test Name>")
    sys.exit(1)

WorkerCount = int(sys.argv[1])
ActiveTime = int(sys.argv[2])
IdleTime = int(sys.argv[3])
tracePath = str(sys.argv[4])
testName = str(sys.argv[5])
traceFileName = os.path.join(tracePath, "trace.tsv")
configFileName = os.path.join(tracePath, "config.json")
IAT = ActiveTime + IdleTime

try:
    os.mkdir(tracePath)
except OSError as e:
    print("Failed to create output dir: ", e)
    sys.exit(1)

print("Generating trace.tsv")
with open(traceFileName, 'wt') as traceFile:
    traceWriter = csv.writer(traceFile, delimiter='\t')

    currWorker = 0
    currLine = 0
    numLines = 1024
    EventTime = IAT
    while(currLine < numLines):
        trace_event = [EventTime, currWorker, ActiveTime]
        traceWriter.writerow(trace_event)
        currWorker += 1
        if currWorker == WorkerCount:
            currWorker = 0
            EventTime += IAT
        currLine += 1

print("Generating config.json")
with open(configFileName, 'w') as configFile:
    configData = {}
    configData['WorkerCount'] = WorkerCount
    configData['TracePath'] = "/Config/" + testName + "/trace.tsv"
    configData['DurationSec'] = 60
    json.dump(configData, configFile)

print("Wrote trace.tsv, config.json to %s" %tracePath)
