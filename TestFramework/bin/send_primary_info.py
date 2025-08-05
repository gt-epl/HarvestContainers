#sendpodid.py
#!/usr/bin/env python3
import sys

import socket
import select

CTR_TYPE="Primary"

cpuList = sys.argv[1]
acbf = sys.argv[2]

msg = '{"ctr_type":"' + CTR_TYPE + '","cpuList":"' + cpuList + '","LOWIDLEFREQ_THRESHOLD":"' + acbf + '","LOW_TIC":"2","targetIdleCores":"7","static_targetIdleCores":"7","minSecondaryCores":"0"}'

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setblocking(1)

host = "127.0.0.1"
port = 10101

print("Sending Primary id %s (len = %s)" % (msg, len(msg)))

try:
  sock.connect((host, port))
except BlockingIOError as e:
  print("BlockingIOError")
  
select.select([], [sock], [])
sock.sendall(bytes(msg, 'UTF-8'))
rtn = sock.recv(4)
print("Got reply: %s" % (rtn))
sock.close()
