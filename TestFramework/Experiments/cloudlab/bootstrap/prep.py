#!/usr/bin/python3
"""
README!
I copy the private keys for the github repo to cloudlab to clone for the latest.
Once the system is stabilized, we can instead use a zip file, or make the repo
public to avoid using keys.

"""

import sys
import os

import argparse

parser = argparse.ArgumentParser(description='Prepare Cloudlab servers')
parser.add_argument('--hosts', type=str, required=True,
                    help='Please provide a file containing ssh hosts')

args = parser.parse_args()

svrs = []
try: 
    with open(args.hosts) as fh:
        
        svrs = [line.rstrip() for line in fh.readlines()]
except Exception:
    print(f'Error parsing hosts: {args.hosts}')
    sys.exit()

print(f"Hosts: {svrs}")

for svr in svrs:
    print(f'[+] Preparing Server: {svr}')
    print('Copying vimrc')
    os.system(f'rsync ~/.vimrc_minimal {svr}:~/.vimrc')
    print('Copying tmux conf')
    os.system(f'rsync ~/.tmux.conf {svr}:~/')
    print('Copying github cred')
    os.system(f'rsync ~/.ssh/sshkeys/github4clab {svr}:~/.ssh/sshkeys/')
    os.system(f'rsync ~/.ssh/sshkeys/cloudlab {svr}:~/.ssh/sshkeys/')
    os.system(f'rsync ~/.ssh/config.d/clab.sshconfig {svr}:~/.ssh/config')
    os.system(f'./sethome.sh {svr}')
    #print('Cloning repo')
    #os.system(f'./clonerepo.sh {svr}')
    #os.system(f'bash setcpufreq.sh {svr}')
