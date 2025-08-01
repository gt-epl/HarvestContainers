import sys
import numpy as np

if len(sys.argv) < 2:
  print("Please specify input log file name.\n")
  sys.exit(1)

LOGFILE=sys.argv[1]
#CPULIST=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]
CPULIST=[1,2,3,4,5,6,7,8,9,10,11]
NUMCPUS=len(CPULIST)

num_idle_cores=[]
accumulated_time=[]
accumulated_time_ns=[]

time_spent_idle = dict.fromkeys(CPULIST, 0)
time_spent_active = dict.fromkeys(CPULIST, 0)

time_spent_with_idle_cores = dict.fromkeys(range(0,NUMCPUS+2), 0)

per_entry_active_cores = []

last_elapsed = 0

total_time = 0

event_num = 0

def parse_log():
    global event_num
    with open(LOGFILE, "r") as log:
        last_line = next(log)
        last_line_tokens = last_line.split(',')
        last_sec = int(last_line_tokens[0])
        last_nsec = int(last_line_tokens[1])
        mask = last_line_tokens[2]
        global total_time

        for this_line in log.readlines():
            per_entry_active_cores.append(0)
            this_line_tokens = this_line.split(',')
            this_sec = int(this_line_tokens[0])
            this_nsec = int(this_line_tokens[1])

            elapsed = (1000*1000*1000)*(this_sec-last_sec)+(this_nsec-last_nsec)
            total_time += elapsed

            # Record how much time we spent with num_idle cores
            num_idle = mask[1:].count('0')
            time_spent_with_idle_cores[num_idle] += elapsed

            # Record how much time each core was active or idle
            for core in CPULIST:
                if mask[core] == '1':
                    time_spent_active[int(core)] += elapsed
                    per_entry_active_cores[event_num] += 1
                else:
                    time_spent_idle[int(core)] += elapsed

            num_idle_cores.append(num_idle)
            accumulated_time_ns.append(elapsed)
            accumulated_time.append( (elapsed/1000/1000/1000) )

            last_sec = int(this_line_tokens[0])
            last_nsec = int(this_line_tokens[1])
            mask = this_line_tokens[2]
            event_num += 1

def print_active_idle():
    global total_time
    global NUMCPUS
    total_active_pct = 0
    total_idle_pct = 0
    for core in CPULIST:
        active_time = time_spent_active[core]
        idle_time = time_spent_idle[core]
        pct_active = (active_time/total_time)*100
        total_active_pct += pct_active
        pct_idle = (idle_time/total_time)*100
        total_idle_pct += pct_idle
    total_cores_idle = (total_idle_pct/(total_idle_pct+total_active_pct))*NUMCPUS
    total_cores_active = (total_active_pct/(total_idle_pct+total_active_pct))*NUMCPUS
    print("\nTotal # Idle/Active: " + str(total_cores_idle) + " / " + str(total_cores_active) + "\n")

def print_time_spent_with_idle():
    percentages = []
    totalTime = sum(time_spent_with_idle_cores.values())
    for core in CPULIST:
        time_spent = time_spent_with_idle_cores[core]
        pct_time = (time_spent/total_time)*100
        percentages.append(pct_time)
        #print(str(core) + ", " + "{:.2f} sec".format(time_spent) + ", " + "{:.2f}%".format(pct_time))


parse_log()
print_active_idle()
#print_time_spent_with_idle()
print(min(per_entry_active_cores))
print(max(per_entry_active_cores))

peac = np.array(per_entry_active_cores)
unique, counts = np.unique(peac, return_counts=True)

print(np.asarray((unique, counts)).T)
