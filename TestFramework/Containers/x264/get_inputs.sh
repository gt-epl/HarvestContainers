#!/bin/bash

cd /mnt/extra/

# Download PARSEC inputs
echo "[+] Downloading PARSEC inputs"
wget https://github.com/cirosantilli/parsec-benchmark/releases/download/3.0/parsec-3.0-input-native.tar.gz.0
wget https://github.com/cirosantilli/parsec-benchmark/releases/download/3.0/parsec-3.0-input-native.tar.gz.1
wget https://github.com/cirosantilli/parsec-benchmark/releases/download/3.0/parsec-3.0-input-native.tar.gz.2
wget https://github.com/cirosantilli/parsec-benchmark/releases/download/3.0/parsec-3.0-input-native.tar.gz.3
wget https://github.com/cirosantilli/parsec-benchmark/releases/download/3.0/parsec-3.0-input-native.tar.gz.4

# combine the tar.gz files
cat parsec-3.0-input-native.tar.gz.* > parsec-3.0-input-native.tar.gz

# extract the tar.gz file
tar xzvf parsec-3.0-input-native.tar.gz

# extract x264 inputs
mkdir -p x264.inputs
tar xvf parsec-3.0/pkgs/apps/x264/inputs/input_native.tar -C x264.inputs/

echo "[+] Done."