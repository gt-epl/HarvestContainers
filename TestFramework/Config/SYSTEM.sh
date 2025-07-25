#!/bin/bash

ENV_TYPE="CLOUDLAB"
TEST_USER="ach"

if [ "${ENV_TYPE}" == "SIRIUS" ]
then
  TEST_USER="ach"
  WORKING_DIR="/home/${TEST_USER}/Workspace/TestFramework"
  CPULIST="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14"
  MONITOR_BINDCPU="15"
  BALANCER_BINDCPU="14"
  LISTENER_BINDCPU="0"
  CORE_RANGE="1-14"
  NUM_CORES="14"
  #CPU_FREQ="2200000"
  CPU_FREQ="2800000"
  #CPU_FREQ="3400000"
fi

if [ "${ENV_TYPE}" == "EC2" ]
then
  TEST_USER="ubuntu"
  WORKING_DIR="/home/${TEST_USER}/Workspace/TestFramework"
  CPULIST="1,2,3,4,5,6,7,8,9,10,11"
  MONITOR_BINDCPU="47"
  BALANCER_BINDCPU="46"
  LISTENER_BINDCPU="45"
  CORE_RANGE="1-23"
  NUM_CORES="23"
  CPU_FREQ="3000000"
fi

if [ "${ENV_TYPE}" == "CLOUDLAB" ]
then
  WORKING_DIR="/project/HarvestContainers/TestFramework"
  CPULIST="2,4,6,8,10,12,14,16"
  SECONDARY_CPULIST="18"
  #MONITOR_BINDCPU="26"
  #BALANCER_BINDCPU="28"
  #LISTENER_BINDCPU="30"
  # This ensures Monitor/Balancer/Listener are on NUMA node1
  MONITOR_BINDCPU="24"
  BALANCER_BINDCPU="26"
  LISTENER_BINDCPU="28"
  CORE_RANGE="1-8" #unused for k8s cloudlab setup
  NUM_CORES="8"    #unused for k8s cloudlab setup
  CPU_FREQ="2600000"
fi

MIN_SECONDARY_CORES="0"
TARGET_IDLE_CORES="1"

CGROUP_PARENT_PATH="/kubepods/besteffort/TESTTEST-TEST-TEST-TEST-TESTTESTTEST"

TASKMASTER_KEY="${WORKING_DIR}/Config/taskmaster.priv"

BIN_PATH="${WORKING_DIR}/bin"
BALANCER_BINARY="balancer"
IDLECPU_BINARY="qidlecpu.ko"
LOGGER_BINARY="cpulogger.ko"
LISTENER_BINARY="listener"

BULLY_CNTR="cpubully"
LS_CNTR="ls"
TERASORT_CNTR="terasort"

EXPERIMENT_DIR="${WORKING_DIR}/Experiments"
