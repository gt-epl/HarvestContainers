#!/bin/bash

OUTPUT_DIR=$1
mkdir -p Results/SYSINFO/${OUTPUT_DIR}
cd Results/SYSINFO/${OUTPUT_DIR}

echo "[+] Checking /proc/cpuinfo"
sudo cat /proc/cpuinfo | tee system_cpu_info.log
echo ""

echo "[+] Checking /proc/cpuinfo MHz"
sudo cat /proc/cpuinfo | grep MHz | tee system_cpu_mhz.log
echo ""

echo "[+] Checking /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
sudo cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | tee  cpufreq_scaling_governor.log
echo ""

echo "[+] Checking /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq"
sudo cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq | tee cpufreq_scaling_min_freq.log
echo ""

echo "[+] Checking /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"
sudo cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq | tee cpufreq_scaling_max_freq.log
echo ""

echo "[+] Checking lspci -v"
sudo lspci -v | tee lspci.log
echo ""

echo "[+] Checking lshw"
sudo lshw | tee lshw.log
echo ""

echo "[+] Checking lscpu"
sudo lscpu | tee lscpu.log
echo ""

echo "[+] Checking dmidecode -t processor"
sudo dmidecode -t processor | tee dmidecode_processor.log
echo ""

echo "[+] Checking dmidecode -t memory"
sudo dmidecode -t memory | tee dmidecode_memory.log
echo ""

echo "[+] Checking /proc/interrupts"
sudo cat /proc/interrupts | tee interrupts.log
echo ""

echo "[+] Checking cpupower frequency-info"
sudo cpupower frequency-info | tee cpupower_frequency-info.log
echo ""

echo "[+] Checking /sys/devices/system/cpu/cpufreq/policy*/scaling_driver"
grep . /sys/devices/system/cpu/cpufreq/policy*/scaling_driver | tee scaling_driver.log
echo ""

echo "[+] Checking /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq"
cat /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq | tee cpu_curr_freq.log
echo""

echo "[+] Checking cpufreq-info"
cpufreq-info | tee cpufreq-info-output.log
echo ""

echo "[+] Checking /sys/devices/system/cpu/intel_pstat_noturbo"
cat /sys/devices/system/cpu/intel_pstate/no_turbo | tee intel_pstate_no_turbo.log
echo ""

echo "[+] Checking /sys/devices/system/cpu/cpufreq/boost"
cat /sys/devices/system/cpu/cpufreq/boost | tee cpufreq-boost.log
echo ""

echo "[+] Done"
