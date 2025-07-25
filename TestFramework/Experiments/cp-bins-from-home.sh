#!/usr/bin/bash


clone() {
  echo "[+] Clone bins"
  cur=$(pwd)

  cd 

  git clone git@github.com:achgt/HarvestListener.git
  git clone git@github.com:achgt/HarvestMonitor.git
  git clone git@github.com:achgt/HarvestBalancer.git

  cd $cur
}
build() {
  echo "[+] Build bins"
  cur=$(pwd)

  cd ~/HarvestListener && make
  cd ~/HarvestMonitor && make
  cd ~/HarvestBalancer && make

  cd $cur
}

copy() {
  echo "[+] Copy bins"
  cp ~/HarvestMonitor/qidlecpu.ko ../bin/
  cp ~/HarvestListener/listener ../bin/
  cp ~/HarvestBalancer/balancer ../bin/
}

verify() {
  echo "[+] Verify bins"
  md5sum ~/HarvestMonitor/qidlecpu.ko 
  md5sum ../bin/qidlecpu.ko

  md5sum ~/HarvestListener/listener 
  md5sum ../bin/listener

  md5sum ~/HarvestBalancer/balancer
  md5sum ../bin/balancer
}

clone
build
copy
verify
