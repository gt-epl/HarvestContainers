#!/bin/bash

# Create the target directory if it doesn't exist
mkdir -p /mnt/extra/dedup.inputs/

echo "[+] Generating 20GB synthetic.data using /dev/random"
sudo dd if=/dev/random of=/mnt/extra/dedup.inputs/synthetic.data bs=1M count=20480 status=progress

echo "[+] Done. File created at /mnt/extra/dedup.inputs/synthetic.data"
