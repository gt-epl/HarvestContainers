#!/bin/bash

# TODO: Create taskmaster key, add to Workspace/Framework/Config
# TODO: Add entries to /etc/hosts to map k8s* names to IPs
# TODO: Setup .ssh/config file w/ host entries

source ../Config/SYSTEM.sh

echo "[+] Running updates"
sudo apt-get update -y
echo "[+] Installing packages"
sudo apt-get install linux-tools-common -y
sudo apt-get install cpufrequtils -y 
sudo apt-get install docker.io -y
sudo apt-get install git -y
sudo apt-get install -y build-essential
sudo apt-get install -y cgroup-tools
sudo apt-get install -y software-properties-common
sudo apt-get install -y zsh
sudo apt-get install -y tmux
sudo apt-get install -y vim
sudo apt-get install -y p7zip-full
sudo apt-get install -y python3-pip
sudo apt-get install -y htop
sudo apt-get install -y jq
# Begin installing mutilate deps
sudo apt-get install scons -y
sudo apt-get install libevent-dev -y
sudo apt-get install gengetopt -y
sudo apt-get install libzmq3-dev -y
# Begin installing ycsb deps
sudo apt-get install openjdk-8-jre -y
sudo apt-get install libmysql-java -y
# Install python deps
sudo pip3 install numpy
# Begin installing K8s deps
echo "[+] Installing K8s dependencies"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get update -y
sudo apt install kubeadm=1.23.5-00 -qy
sudo apt install kubelet=1.23.5-00 -qy
sudo apt install kubeadm=1.23.5-00 -qy
echo "[+] Disabling 'ondemand' service"
sudo systemctl disable ondemand
# symlink libevent-2.1.so.7 to .7 so mutilate can run locally
echo "[+] Fix symlink for libevent-2.1.so.6 (mutilate dependency)"
sudo ln -s /lib/x86_64-linux-gnu/libevent-2.1.so.7 /lib/x86_64-linux-gnu/libevent-2.1.so.6
echo "[+] Done."
echo ""

if [ "${TEST_USER}" == "ach" ]; then
  # ach setup
  echo "[+] Copying dotfiles"
  # Usage: copy_dotfiles.sh <project_dir> <repo_name>
  /project/HarvestContainers/TestFramework/Bootstrap/dotfiles/ach/copy_dotfiles.sh /project HarvestContainers
fi

if [ "${ENV_TYPE}" == "EC2" ]; then
  # ec2 setup
  sudo apt-get install linux-tools-5.4.0-1058-aws -y
  echo "[+] Adding 'ubuntu' user to 'docker' group"
  sudo usermod -aG docker ubuntu
fi

if [ "${ENV_TYPE}" == "CLOUDLAB" ]; then
  # cloudlab setup
  sudo groupadd harvest
  echo "[+] Adding 'ach' user to 'docker' group"
  sudo usermod -aG docker ach
  sudo usermod -aG harvest ach
  echo "[+] Adding 'asarma31' user to 'docker' group"
  sudo usermod -aG docker asarma31
  sudo usermod -aG harvest asarma31
  # TODO: Create symlink for mutilate's libevent lib dep
fi
