#!/usr/bin/env python
import sys

template = \
'''Host {}
  User asarma31
  Hostname {}
  IdentityFile ~/.ssh/sshkeys/cloudlab
  StrictHostKeyChecking=no
  #UserKnownHostsFile=/dev/null
  UserKnownHostsFile ~/.ssh/clab_hosts
  ServerAliveInterval 120
'''
username="asarma31@"
is_server = True
host = 'clabsvr'
ctr=0

hosts = []

for line in sys.stdin:
    line = line.rstrip()
    token = line.split()[1]
    hostname = token[len(username):]

    if is_server:
        is_server = False

    print(template.format(host, hostname))
    hosts.append(host)

    host = 'clabcl{}'.format(ctr)
    ctr += 1

with open('hosts.txt','w') as fw:
    fw.write('\n'.join(hosts))
