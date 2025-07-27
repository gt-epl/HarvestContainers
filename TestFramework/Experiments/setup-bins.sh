#!/usr/bin/bash

build() {
  echo "[+] Build bins"
  cur=$(pwd)

  cd ../../Listener && make
  cd ../../Monitor && make
  cd ../../Balancer && make

  cd $cur
}

copy() {
  echo "[+] Copy bins"
  cp ../../Monitor/qidlecpu.ko ../bin/
  cp ../../Listener/listener ../bin/
  cp ../../Balancer/balancer ../bin/
}

verify() {
  echo "[+] Verify bins"
  md5sum ../../Monitor/qidlecpu.ko 
  md5sum ../bin/qidlecpu.ko

  md5sum ../../Listener/listener 
  md5sum ../bin/listener

  md5sum ../../Balancer/balancer
  md5sum ../bin/balancer
}

build
copy
verify
