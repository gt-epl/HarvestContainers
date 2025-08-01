#!/bin/bash
start=1
end=1

echo "[+] Disbale Intel Flow Director"
sudo ethtool -K ethX ntuple off

echo "[+] Disbale IRQ balance"
sudo systemctl stop irqbalance

echo "[+] save interrupt numbers specific to cloudlab interface: enp24s0f1"
cat /proc/interrupts | grep "enp24s0f1" | awk '{print $1}' | sed 's/://g' > /mnt/extra/config/irq_nums

# primary core list
CPULIST=2,4,6,8,10,12,14,16,18

echo "[+] pin irq to $CPULIST"
cat /mnt/extra/config/irq_nums | while read irq; do
  echo $CPULIST | sudo tee /proc/irq/$irq/smp_affinity_list
done

echo "[+] Pinning cores for workloads"
cur_dir=$(pwd)
cd ~/HarvestContainers/TestFramework/Tools/
./pincores.sh $CPULIST clabcl1 memcached-primary
./pincores.sh $CPULIST clabcl1 xapian-primary
./pincores.sh $CPULIST clabcl1 mysql-primary
./pincores.sh 18 clabcl1 cpubully-secondary
./pincores.sh 20 clabcl1 nwbully-secondary
cd $cur_dir

for((i=start; i<=end; i++)); do
  for qps in 10000 50000 100000; do
    ./memcached_runner.sh $i 9 7 $qps 60 harvest-irq
    ./memcached_runner.sh $i 9 7 $qps 60 harvest-irq "aware"
  done
done

for((i=start; i<=end; i++)); do
  for qps in 500 2500 4000; do
    ./xapian_runner.sh $i 9 7 $qps 60 harvest
    ./xapian_runner.sh $i 9 7 $qps 60 harvest-irq "aware"
  done
done

for((i=start; i<=end; i++)); do
  for qps in 1000 4000 8000; do
    ./mysql_runner.sh $i 9 7 $qps 60 harvest
    ./mysql_runner.sh $i 9 7 $qps 60 harvest-irq "aware"
  done
done
