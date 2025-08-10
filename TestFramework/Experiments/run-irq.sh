#!/bin/bash
start=1
end=1

echo "[+] Disable Intel Flow Director"
sudo ethtool -K enp24s0f1 ntuple off

echo "[+] Disable IRQ balance"
sudo systemctl stop irqbalance

echo "[+] Save interrupt numbers specific to Cloudlab interface: enp24s0f1"
cat /proc/interrupts | grep "enp24s0f1" | awk '{print $1}' | sed 's/://g' > /mnt/extra/config/irq_nums

# primary core list
IRQ_CPULIST=2,4,6,8,10,12,14,16,18

echo "[+] Pin IRQ to $IRQ_CPULIST"
cat /mnt/extra/config/irq_nums | while read irq; do
  echo $IRQ_CPULIST | sudo tee /proc/irq/$irq/smp_affinity_list
done

CPULIST=2,4,6,8,10,12,14,16
WORKER_LIST=1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31

pincores() {
  echo "[+] Pinning cores for workloads"
  cur_dir=$(pwd)
  cd ~/HarvestContainers/TestFramework/Tools/
  ./pincores.sh $CPULIST clabcl1 memcached-primary
  ./pincores.sh $CPULIST clabcl1 xapian-primary
  ./pincores.sh $CPULIST clabcl1 mysql-primary
  ./pincores.sh 18 clabcl1 cpubully-secondary
  ./pincores.sh 20 clabcl1 nwbully-secondary
  ./pincores.sh $WORKER_LIST clabcl1 mutilate-cl1
  ./pincores.sh $WORKER_LIST clabcl1 ycsb-cl1
  cd $cur_dir
}

# start iperf servers
curl --data "{\"duration\":\"${DURATION}\",\"workers\":\"10\",\"trial\":\"${ITER}\"}" --header "Content-Type: application/json" http://192.168.10.11:30300/start

time_start=$(date +%s)
for((i=start; i<=end; i++)); do

# Baseline and IRQ Unaware Harvest
  for qps in 10000 50000 100000; do
    pincores
    ./memcached_runner.sh $i 9 7 $qps 60 baseline-irq
    pincores
    ./memcached_runner.sh $i 9 7 $qps 60 harvest-irq
  done

  for qps in 500 2500 4000; do
    pincores
    ./xapian_runner.sh $i 9 7 $qps 60 baseline-irq
    pincores
    ./xapian_runner.sh $i 9 7 $qps 60 harvest-irq
  done

  for qps in 1000 4000 8000; do
    pincores
    ./mysql_runner.sh $i 9 7 $qps 60 baseline-irq
    pincores
    ./mysql_runner.sh $i 9 7 $qps 60 harvest-irq
  done
done


# IRQ Aware Harvest
for((i=start; i<=end; i++)); do

  for qps in 10000 50000 100000; do
    pincores
    ./memcached_runner.sh $i 9 7 $qps 60 harvest-irq "aware"
  done

  for qps in 500 2500 4000; do
    pincores
    ./xapian_runner.sh $i 9 7 $qps 60 harvest-irq "aware"
  done

  for qps in 1000 4000 8000; do
    pincores
    ./mysql_runner.sh $i 9 7 $qps 60 harvest-irq "aware"
  done
done


time_end=$(date +%s)
echo "[+] IRQ experiments completed in $((time_end - time_start)) seconds"


for app in memcached mysql xapian; do
   mv ${app}_config.out /mnt/extra/config/$app-irq_config.out
done

echo "[+] Enable Intel Flow Director"
sudo ethtool -K enp24s0f1 ntuple on

echo "[+] Enable IRQ balance"
sudo systemctl start irqbalance
