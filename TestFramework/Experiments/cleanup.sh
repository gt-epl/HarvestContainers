
#!/bin/bash
source ../bin/boilerplate.sh
source ../Config/SYSTEM.sh
echo "[+] Stopping logging"
stopLogging idlecpu
stopModule idlecpu

sudo kill $(pgrep listener)
sudo kill $(pgrep balancer)
unloadModule idlecpu


echo "[+] remove all logs and results"

ssh clabcl1 bash <<EOF
sudo -s
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

