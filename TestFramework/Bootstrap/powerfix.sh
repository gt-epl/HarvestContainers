#!/bin/bash

source ../Config/SYSTEM.sh

echo "[+] Disabling turbo boost"
# Disable turbo boost for intel-pstate driver
echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
# Disable turbo boost for acpi-cpufreq scaling driver
echo "0" | sudo tee /sys/devices/system/cpu/cpufreq/boost
sleep 1
# Set power governor to "performance"
echo "[+] Setting power governor to 'userspace'"
echo "userspace" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sleep 1
# Set max freq
echo "[+] Setting MAX frequency to ${CPU_FREQ} Hz"
echo "${CPU_FREQ}" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq
echo "[+] Setting MIN frequency to ${CPU_FREQ} Hz"
echo "${CPU_FREQ}" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq
sleep 2
# Disable ondemand.service
echo "[+] Disabling 'ondemand' service"
sudo systemctl disable ondemand
# Check freqs
echo "[+] Getting current CPU freq stats"
sudo cpufreq-info | grep "current CPU frequency"
