#!/bin/bash

# Extract this file
# Extract parsec-3.0/pkgs/apps/x264/inputs/input_native.tar to ./inputs/

echo "[+] Downloading PARSEC source"
wget "http://parsec.cs.princeton.edu/download/3.0/parsec-3.0.tar.gz"
echo "[+] Extracting PARSEC files"
tar xzvf parsec-3.0.tar.gz
echo "[+] Extracting input video file"
tar xvf parsec-3.0/pkgs/apps/x264/inputs/input_native.tar -C inputs/
echo "[+] Cleaning up."
rm -rf parsec-3.0 parsec-3.0.tar.gz
