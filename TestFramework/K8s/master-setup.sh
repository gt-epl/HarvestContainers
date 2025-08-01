#!/bin/bash

sudo swapoff -a

sudo kubeadm reset -f

sudo kubeadm init --config kubeadm-config.yaml

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f calico.yaml

echo ""
read -p "Enter internal node IP address for MASTER server: " MASTER_IP
echo ""

sed "s/NODE_IP_ADDR/${MASTER_IP}/g" kubeadm-flags.env > kubeadm-flags.env.tmp

sudo mv kubeadm-flags.env.tmp /var/lib/kubelet/kubeadm-flags.env

sudo systemctl restart kubelet
