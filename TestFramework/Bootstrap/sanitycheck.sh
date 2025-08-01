#!/bin/bash

echo "No turbo?"
cat /sys/devices/system/cpu/intel_pstate/no_turbo
echo ""
echo "cpufreq/boost?"
cat /sys/devices/system/cpu/cpufreq/boost
echo ""
echo "cpuidle/current_driver?"
cat /sys/devices/system/cpu/cpuidle/current_driver
echo ""
echo "Now manually run 'cpufreq-info'"
