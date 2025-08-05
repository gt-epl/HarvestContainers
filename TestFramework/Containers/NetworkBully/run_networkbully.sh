num_workers=$1
num_duration=$2


for((i=0;i<num_workers;i++)); do
  port=$((20001+i))
  iperf3 -s -p $port > iperf_svr.out 2>&1 &
done