#!/bin/bash

echo "[+] remove all logs and results"

# clabcl1
ssh clabcl1 bash <<EOF
sudo -s
rm -rf ~/HarvestContainers/TestFramework/Experiments/*_config.out
rm -rf /mnt/extra/results/memcached/*
rm -rf /mnt/extra/results/mysql/*
rm -rf /mnt/extra/results/xapian/*
rm -rf /mnt/extra/logs/memcached/*
rm -rf /mnt/extra/logs/mysql/*
rm -rf /mnt/extra/logs/xapian/*
rm -rf /mnt/extra/config/*
EOF

ssh clabsvr bash <<EOF
sudo -s
rm -rf /mnt/extra/results/memcached/*
rm -rf /mnt/extra/results/mysql/*
rm -rf /mnt/extra/results/xapian/*
rm -rf /mnt/extra/logs/memcached/*
rm -rf /mnt/extra/logs/mysql/*
rm -rf /mnt/extra/logs/xapian/*
rm -rf /mnt/extra/config/*
EOF