#!/bin/bash

source /project/HarvestContainers/TestFramework/Config/SYSTEM.sh

echo ""
echo "[!] WORKING_DIR set to ${WORKING_DIR}"
echo ""

# --- BEGIN BOILERPLATE CODE --- #
loadModule() {
    TARGET=$1
    if [ "${TARGET}" == "idlecpu" ]; then
        MODNAME=${IDLECPU_BINARY}
        CPULIST_PATH="/proc/idlecpu/cpulist"
        CTRL_PATH="/proc/idlecpu/control"
        BIND_PATH="/proc/idlecpu/bindcpu"
        BIND_CPU=${MONITOR_BINDCPU}
    elif [ "${TARGET}" == "logger" ]; then
        MODNAME=${LOGGER_BINARY}
        CPULIST_PATH="/proc/cpulogger/cpulist"
        CTRL_PATH="/proc/cpulogger/control"
        BIND_PATH="/proc/cpulogger/bindcpu"
        BIND_CPU=${LOGGER_BINDCPU}
    else
        echo "Invalid module name"
        exit 1
    fi
    
    if [ ! -f "${BIN_PATH}/${MODNAME}" ]; then
        echo "Could not find ${MODNAME} module file"
        exit 1
    fi

    echo "[+] Loading ${MODNAME} module"
    sudo insmod ${BIN_PATH}/${MODNAME}

    sleep 2

    echo "[+] Writing cpuList to ${CPULIST_PATH}"
    echo ${CPULIST} > ${CPULIST_PATH}

    sleep 2

    echo "[+] ${MODNAME} polling for status on CPUs:"
    cat ${CPULIST_PATH}

    echo "[+] Setting CPU to bind via ${BIND_PATH}"
    echo ${MONITOR_BINDCPU} > ${BIND_PATH}

    sleep 2
}

unloadModule() {
    TARGET=$1
    if [ "${TARGET}" == "idlecpu" ]; then
        MODNAME=${IDLECPU_BINARY}
    elif [ "${TARGET}" == "logger" ]; then
        MODNAME=${LOGGER_BINARY}
    else
        echo "Invalid module name"
        exit 1
    fi
    echo "[+] Unloading ${MODNAME} module"
    sudo rmmod ${MODNAME}
    sleep 1
}

startModule() {
    TARGET=$1
    if [ "${TARGET}" == "idlecpu" ]; then
        MODNAME=${IDLECPU_BINARY}
        CTRL_PATH="/proc/idlecpu/control"
    elif [ "${TARGET}" == "logger" ]; then
        MODNAME=${LOGGER_BINARY}
        CTRL_PATH="/proc/cpulogger/control"
    else
        echo "Invalid module name"
        exit 1
    fi
    echo "[+] Starting ${MODNAME} module via ${CTRL_PATH}"
    echo 1 > ${CTRL_PATH}
    sleep 1
}

stopModule() {
    TARGET=$1
    if [ "${TARGET}" == "idlecpu" ]; then
        MODNAME=${IDLECPU_BINARY}
        CTRL_PATH="/proc/idlecpu/control"
    elif [ "${TARGET}" == "logger" ]; then
        MODNAME=${LOGGER_BINARY}
        CTRL_PATH="/proc/cpulogger/control"
    else
        echo "Invalid module name"
        exit 1
    fi
    echo "[+] Stopping ${MODNAME} module via ${CTRL_PATH}"
    sudo echo 0 > ${CTRL_PATH}
    sleep 1
}

startLogging() {
    TARGET=$1
    if [ "${TARGET}" == "idlecpu" ]; then
        CTRL_PATH="/proc/idlecpu/logcontrol"
    elif [ "${TARGET}" == "logger" ]; then
        CTRL_PATH="/proc/cpulogger/control"
    else
        echo "Invalid module name"
        exit 1
    fi    
    echo "[+] Starting ${TARGET} logging"
    echo 1 > ${CTRL_PATH}
}

stopLogging() {
    TARGET=$1
    if [ "${TARGET}" == "idlecpu" ]; then
        CTRL_PATH="/proc/idlecpu/logcontrol"
    elif [ "${TARGET}" == "logger" ]; then
        CTRL_PATH="/proc/cpulogger/control"
    else
        echo "Invalid module name"
        exit 1
    fi    
    echo "[+] Stopping ${TARGET} logging"
    echo 0 > ${CTRL_PATH}
}

getLoggerLog() {
    TARGET=$1
    if [ "${TARGET}" == "idlecpu" ]; then
        LOG_PATH="/proc/idlecpu/log"
    elif [ "${TARGET}" == "logger" ]; then
        LOG_PATH="/proc/cpulogger/log"
    else
        echo "Invalid module name"
        exit 1
    fi    
    OUTPUT_DIR=$2
    echo "[+] Retrieving logs from ${TARGET}"
    cat ${LOG_PATH} > ${OUTPUT_DIR}/cpulogger.log
}

runCPUBullyContainer() {
    echo "[+] Starting Bully container"
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name cpubully_secondary --rm ${BULLY_CNTR} ${BULLY_WORKERS} ${BULLY_TEST_DURATION} CPUBoundSum 2>&1 > ${BULLY_OUTPUT}
    else
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name bully_secondary --rm ${BULLY_CNTR} ${BULLY_WORKERS} ${BULLY_TEST_DURATION} CPUBoundSum 2>&1 > ${BULLY_OUTPUT} &
    fi
}

runNetworkBullyContainer() {
    echo "[+] Starting NetworkBully container"
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name networkbully_secondary --rm -p 127.0.0.1:5101:5101 -v ${WORKING_DIR}/Containers/NetworkBully/outputs:/outputs networkbully
    else
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name networkbully_secondary --rm -p 127.0.0.1:5101:5101 -v ${WORKING_DIR}/Containers/NetworkBully/outputs:/outputs networkbully &
    fi
}

runLSContainer() {
    echo "[+] Starting LatSensitive container"
    CONFIG_FILE=$1
    if [ -n "$2" ] && [ "$2" == "fg" ]; then
        docker run --cpuset-cpus=${CORE_RANGE} --name ls_primary --rm -v ${WORKING_DIR}/Containers/LatSensitive:/App -v ${WORKING_DIR}/Config/LatSensitive:/Config ${LS_CNTR} ${CONFIG_FILE} 2>&1 > ${LS_OUTPUT}
    else
        docker run --cpuset-cpus=${CORE_RANGE} --name ls_primary --rm -v ${WORKING_DIR}/Containers/LatSensitive:/App -v ${WORKING_DIR}/Config/LatSensitive:/Config ${LS_CNTR} ${CONFIG_FILE} 2>&1 > ${LS_OUTPUT} &
    fi
}

runTerasortContainer() {
    echo "[+] Starting Terasort container"
    WORKLOAD=$2
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name terasort_secondary --rm -v ${WORKING_DIR}/Containers/Terasort/outputs:/outputs -v ${WORKING_DIR}/Containers/Terasort/inputs:/inputs ${TERASORT_CNTR} ${WORKLOAD} 2>&1 > ${TERASORT_OUTPUT}
    else
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name terasort_secondary --rm -v ${WORKING_DIR}/Containers/Terasort/outputs:/outputs -v ${WORKING_DIR}/Containers/Terasort/inputs:/inputs ${TERASORT_CNTR} ${WORKLOAD} 2>&1 > ${TERASORT_OUTPUT} &
    fi
}

runX264Container() {
    NUM_THREADS=$2
    echo "[+] Starting x264 container"
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name x264_1 --rm -v ${WORKING_DIR}/Containers/x264/outputs:/outputs -v ${WORKING_DIR}/Containers/x264/inputs:/inputs x264 ${NUM_THREADS}
    else
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name x264_1 --rm -v ${WORKING_DIR}/Containers/x264/outputs:/outputs -v ${WORKING_DIR}/Containers/x264/inputs:/inputs x264 ${NUM_THREADS} &
    fi
}

runMySQLContainer() {
    echo "[+] Starting MySQL container"
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name mysql_primary --rm -p 3306:3306 -e MYSQL_ROOT_PASSWORD=taskmaster -e MYSQL_DATABASE=ycsb -e MYSQL_USER=ycsb -e MYSQL_PASSWORD=ycsb -v ${WORKING_DIR}/Containers/MySQL/initdb:/docker-entrypoint-initdb.d mysql:5
    else
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name mysql_primary --rm -p 3306:3306 -e MYSQL_ROOT_PASSWORD=taskmaster -e MYSQL_DATABASE=ycsb -e MYSQL_USER=ycsb -e MYSQL_PASSWORD=ycsb -v ${WORKING_DIR}/Containers/MySQL/initdb:/docker-entrypoint-initdb.d mysql:5 &
    fi
}

runMemcachedContainer() {
    MEMCACHED_THREADS=$2
    MEMCACHED_CONNS=$3
    MEMCACHED_RAM=$4
    echo "[+] Starting Memcached container"
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name memcached_primary --rm -p 11211:11211 memcached memcached -t ${MEMCACHED_THREADS} -c ${MEMCACHED_CONNS} -m ${MEMCACHED_RAM} -v
    else
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name memcached_primary --rm -p 11211:11211 memcached memcached -t ${MEMCACHED_THREADS} -c ${MEMCACHED_CONNS} -m ${MEMCACHED_RAM} -v &
    fi
}

runImgDnnContainer() {
    THREADS=$2
    TBENCH_MAXREQS=$3
    TBENCH_QPS=$4
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name img-dnn_primary --rm -v ${WORKING_DIR}/Containers/img-dnn/outputs:/outputs img-dnn ${THREADS} ${TBENCH_MAXREQS} ${TBENCH_QPS}
    else
        docker run --cgroup-parent=${CGROUP_PARENT_PATH} --cpuset-cpus=${CORE_RANGE} --name img-dnn_primary --rm -v ${WORKING_DIR}/Containers/img-dnn/outputs:/outputs img-dnn ${THREADS} ${TBENCH_MAXREQS} ${TBENCH_QPS} &
    fi
}

runBalancer() {
    if [ -n "$1" ] && [ "$1" == "fg" ]; then
        sudo taskset -a -c ${BALANCER_BINDCPU} ${BIN_PATH}/${BALANCER_BINARY} ${SECONDARY_PID} ${TARGET_IDLE_CORES} ${MIN_SECONDARY_CORES} ${CPULIST} ${SECONDARY_CPULIST}
    else
        sudo taskset -a -c ${BALANCER_BINDCPU} ${BIN_PATH}/${BALANCER_BINARY} ${SECONDARY_PID} ${TARGET_IDLE_CORES} ${MIN_SECONDARY_CORES} ${CPULIST} ${SECONDARY_CPULIST} &
    fi
}

runListener() {
    sudo taskset -a -c ${LISTENER_BINDCPU} ${BIN_PATH}/${LISTENER_BINARY} ${CPULIST} &
}

sendPodId() {
    #python3 ${BIN_PATH}/sendpodid.py &
    python3 ${BIN_PATH}/sendpodid.py $1 &
}

balancerRunning() {
  if pgrep -x "balancer" >/dev/null
  then
    return 1
  else
    return 0
  fi
}

# --- END BOILERPLATE CODE --- #
