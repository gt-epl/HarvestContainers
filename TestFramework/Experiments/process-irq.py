import sys

NUMCPUS=20
def do(fn):
    fh = open(fn)
    first = True
    cpulist = [0]*NUMCPUS
    for line in fh.readlines():
        if first:
            first = False
            continue
        tokens = line.split()
        for i in range(NUMCPUS):
            tok = tokens[i+1]
            cpulist[i] += int(tok)
    return cpulist

old = do(sys.argv[1])
new = do(sys.argv[2])

diff = [0]*NUMCPUS
for i,old_val in enumerate(old):
    diff[i] = new[i]-old_val

print(" ".join(f"CPU{i}" for i in range(NUMCPUS)))
print(" ".join([str(i) for i in diff]))
