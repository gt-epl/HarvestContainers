#!/usr/bin/env bash

SVR=$1

ssh $SVR bash << EOF
git config --global core.editor "vim"
rm -rf HarvestContainers
git clone -b cloudlab git@github.com:achgt/HarvestContainers.git
EOF
