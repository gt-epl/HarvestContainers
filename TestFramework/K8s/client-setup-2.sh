#!/bin/bash

sudo swapoff -a

echo ""
read -p "Enter internal node IP address for CLIENT server: " CLIENT_IP
echo ""

sed "s/NODE_IP_ADDR/${CLIENT_IP}/g" kubeadm-flags.env > kubeadm-flags.env.tmp

sudo mv kubeadm-flags.env.tmp /var/lib/kubelet/kubeadm-flags.env

sudo systemctl restart kubelet
