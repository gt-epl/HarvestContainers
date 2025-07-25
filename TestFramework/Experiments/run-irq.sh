#for ((core=0;core<32;core++)); do
core=$1
 

  echo "[+] Start for core: $core"

  cat /proc/softirqs | grep "NET_RX\|NET_TX\|CPU0" | tr -s " " > c${core}old.csv
  echo "[+] start iperf server"
  pkill iperf3
  taskset --cpu-list $core iperf3 -s > debug.svr 2>&1 &
  echo "[+] start iperf client"
  ssh clabcl0 "iperf3 -c 192.168.10.10 -t 60" > debug.cl 2>&1
  pkill iperf3
  cat /proc/softirqs | grep "NET_RX\|NET_TX\|CPU0" | tr -s " " > c${core}new.csv
  echo "[+] get interrupt diff"
  python process-irq.py c${core}old.csv c${core}new.csv >> diff.csv
  echo "---"
  exit 1;
#done
