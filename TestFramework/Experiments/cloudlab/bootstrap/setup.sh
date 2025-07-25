sudo swapoff -a
echo "[+] Installing apt deps"
sudo apt-get update && sudo apt-get install -y software-properties-common cpufrequtils build-essential

echo "[+] Add docker"
sudo apt-get install -y docker.io && sudo usermod -aG docker $USER

echo "[+] Add K8s"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add 
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get update
sudo apt-get -y install kubeadm
sudo apt-get -y install libopencv-dev python3-pip

#echo "[+] Disable Intel power driver"
#echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash intel_pstate=disable\"" | sudo tee /etc/default/grub
#sudo update-grub
#
#echo "[+] Reboot System"
#sudo reboot

### SCRIPT END ###
