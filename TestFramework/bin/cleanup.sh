#!/bin/bash

sudo kill -9 `pgrep balancer`
sleep 1
sudo kill -9 `pgrep listener`
sleep 1
sudo rmmod qidlecpu
