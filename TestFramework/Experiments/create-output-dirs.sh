#!/bin/bash

echo "[+] create dirs for  all configs, logs and results"


base_logs=/mnt/extra/logs
base_results=/mnt/extra/results
base_config=/mnt/extra/config

apps=('memcached' 'mysql' 'xapian' 'multi-primary')



ssh clabcl1 "mkdir -p $base_config"

for app in ${apps[@]}; do
  ssh clabcl1 bash <<EOF
    mkdir -p $base_results/${app}
    mkdir -p $base_logs/${app}

EOF
done

ssh clabsvr "mkdir -p $base_config"

for app in ${apps[@]}; do
  ssh clabsvr bash <<EOF
    mkdir -p $base_results/${app}
    mkdir -p $base_logs/${app}
EOF
done

