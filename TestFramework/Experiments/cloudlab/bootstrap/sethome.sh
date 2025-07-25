#!/usr/bin/env bash

SVR=$1

ssh $SVR bash << EOF
echo 'alias home="cd /project/HarvestContainers/TestFramework"' >> ~/.bashrc
EOF
