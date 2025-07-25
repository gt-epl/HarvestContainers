#!/usr/bin/python

import sys
import os
import numpy as np
from scipy import stats

class Lat(object):
    def __init__(self, fileName):
        f = open(fileName, 'rb')
        a = np.fromfile(f, dtype=np.uint64)
        self.reqTimes = a.reshape((int(a.shape[0]/3), 3))
        f.close()

    def parseQueueTimes(self):
        return self.reqTimes[:, 0]

    def parseSvcTimes(self):
        return self.reqTimes[:, 1]

    def parseSojournTimes(self):
        return self.reqTimes[:, 2]

if __name__ == '__main__':
    def getLatPct(latsFile):
        assert os.path.exists(latsFile)

        latsObj = Lat(latsFile)

        qTimes = [l/1e6 for l in latsObj.parseQueueTimes()]
        svcTimes = [l/1e6 for l in latsObj.parseSvcTimes()]
        sjrnTimes = [l/1e6 for l in latsObj.parseSojournTimes()]
        f = open('lats.txt','w')

        f.write('%12s | %12s | %12s\n\n' \
                % ('QueueTimes', 'ServiceTimes', 'SojournTimes'))

        for (q, svc, sjrn) in zip(qTimes, svcTimes, sjrnTimes):
            f.write("%12s | %12s | %12s\n" \
                    % ('%.3f' % q, '%.3f' % svc, '%.3f' % sjrn))
        f.close()
        p50      = np.round(stats.scoreatpercentile(sjrnTimes, 50), 2)
        p90      = np.round(stats.scoreatpercentile(sjrnTimes, 90), 2)
        p95      = np.round(stats.scoreatpercentile(sjrnTimes, 95), 2)
        p99      = np.round(stats.scoreatpercentile(sjrnTimes, 99), 2)
        maxLat   = np.round(max(sjrnTimes), 2)
        minLat   = np.round(min(sjrnTimes), 2)
        genstats = stats.describe(sjrnTimes)
        #print(f"50th percentile latency (ms): {p50}")
        #print(f"90th percentile latency (ms): {p90}")
        #print(f"95th percentile latency (ms): {p95}")
        #print(f"99th percentile latency (ms): {p99}")
        #print(f"max latency (ms): {maxLat}")
        #print(f"general - \n {genstats}")
        print(f"{sys.argv[1]} {np.round(genstats.mean,2)} {p50} {p90} {p95} {p99} {minLat} {maxLat}")

    latsFile = sys.argv[1]
    getLatPct(latsFile)
        
