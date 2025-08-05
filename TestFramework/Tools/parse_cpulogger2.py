import sys
import numpy as np

if len(sys.argv) < 3:
    print("Usage: parse_cpulogge2.py logfile CPULIST") 
    sys.exit(1)

def parse_cpulist(args):
    out = []
    if '-' in args:
        tokens = args.split('-')
        if len(tokens) != 2:
            print("CPULIST is either in form 1-8 or 2,4,6")
            sys.exit(-1)
        else:
            try:
                low = int(args[0])
                high = int(args[1])
                out = range(low,high+1)
            except:
                print("CPULIST is either in form 1-8 or 2,4,6")
                sys.exit(-1)

    elif "," in args:
        tokens = args.split(',')
        try:
            out = [int(x) for x in tokens]
        except:
            print("CPULIST is either in form 1-8 or 2,4,6")
            sys.exit(-1)

    return out
        


LOGFILE=sys.argv[1]
CPULIST=parse_cpulist(sys.argv[2])
NUMCPUS=len(CPULIST)

#NOTE: Each entry in the log marks a core state change event i.e. the line indicates something changed and therefore at every log line, we record observations for the last line states.

# accumulate time for a particular core (say 2nd core) which turned active in the last line
# unsure of the use
time_spent_per_core = dict.fromkeys(CPULIST,0)

# accumulate time for particular count of active cores in the last line. 
# e.g., 4 cores are active in current line indicates 4 cores were active for accumulated time.
time_spent_per_aggcorecount = [0]*(NUMCPUS+1)

# accumulate events for a particular count of active cores
# e.g. among all lines of the logs x lines correspond to 4 cores being active.
events_per_aggcorecount = [0]*(NUMCPUS+1)


def get_active_count(mask):
    ctr = 0
    for c in CPULIST:
        if mask[c] == '1':
            ctr += 1
    #import pdb; pdb.set_trace()
    return ctr


def parse_log():

    with open(LOGFILE, "r") as log:
        last_line = next(log)
        last_line_tokens = last_line.split(',')
        mask = last_line_tokens[2]
        last_nsec = int(last_line_tokens[1])
        last_sec = int(last_line_tokens[0])
        first_ts = last_ts = (1000*1000*1000*last_sec) + last_nsec

        for this_line in log.readlines():
            this_line_tokens = this_line.split(',')
            this_nsec = int(this_line_tokens[1])
            this_sec = int(this_line_tokens[0])
            this_ts = (1000*1000*1000*this_sec) + this_nsec

            elapsed = this_ts - last_ts

            for core in CPULIST:
                if mask[core] == '1':
                    time_spent_per_core[core] += elapsed

            num_active = get_active_count(mask)
            time_spent_per_aggcorecount[num_active] += elapsed
            events_per_aggcorecount[num_active] += 1


            last_ts = this_ts
            mask = this_line_tokens[2]


def print_debug():
    print(events_per_aggcorecount)

def print_events():
    arr = np.array(events_per_aggcorecount)
    total_events = np.sum(arr)
    pct = 100*(arr/total_events)
    core_counts = np.arange(NUMCPUS+1)
    final = np.stack((core_counts, pct))
    print("Events per active cores")
    print("#cores, pct")
    print(final.T)

    ratio = arr/total_events
    avg = np.round_(np.dot(ratio,core_counts), 2)
    print(f"event weighted average active cores: {avg}")

def print_agg_time_spent():
    arr = np.array(time_spent_per_aggcorecount)
    total_time = np.sum(arr)
    pct = 100*(arr/total_time)
    core_counts = np.arange(NUMCPUS+1)
    final = np.stack((core_counts, pct))
    print("Time spent per active cores")
    print("#cores, pct")
    print(final.T)

    ratio = arr/total_time
    avg = np.round_(np.dot(ratio,core_counts), 2)
    print(f"time weighted average active cores: {avg}")




np.set_printoptions(suppress=True, formatter={'float_kind':'{:0.2f}'.format})
parse_log()
print(f'TOTAL CPUS: {NUMCPUS}')
print_events()
print("---")
print_agg_time_spent()
#print_debug()

