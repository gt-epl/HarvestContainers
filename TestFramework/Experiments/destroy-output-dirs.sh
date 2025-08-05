#!/bin/bash

echo "[+] destroy dirs for  all configs, logs and results"

base_logs=/mnt/extra/logs
base_results=/mnt/extra/results
base_config=/mnt/extra/config

ssh clabcl1 "rm -rf $base_config"
ssh clabcl1 "rm -rf $base_results"
ssh clabcl1 "rm -rf $base_logs"

ssh clabsvr "rm -rf $base_config"
ssh clabsvr "rm -rf $base_results"
ssh clabsvr "rm -rf $base_logs"

