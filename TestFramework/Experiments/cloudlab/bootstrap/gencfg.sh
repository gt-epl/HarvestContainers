#!/usr/bin/env bash

pbpaste | python gencfg.py > ~/.ssh/config.d/clab.sshconfig

# Optional. Comment if required.
echo "[+] copying cloudlab git credentials"
cat << EOF >> ~/.ssh/config.d/clab.sshconfig
Host github.com
  User rudh24
  IdentityFile ~/.ssh/sshkeys/github4clab
  StrictHostKeyChecking=accept-new
  UserKnownHostsFile ~/.ssh/clab_hosts
EOF

