#!/bin/bash
# refer to dockerfile for deps

echo "[+] Cloning mutilate repo"
git clone https://github.com/leverich/mutilate.git
cd mutilate
sed -i 's|/usr/bin/python3|/usr/bin/python2.7|g' /usr/bin/scons
scons
echo "[+] Done."