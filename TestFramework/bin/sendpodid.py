#sendpodid.py
#!/usr/bin/env python3
import sys

import socket
import select

CTR_TYPE="Secondary"

pod_id = sys.argv[1]

msg = '{"ctr_type":"' + CTR_TYPE + '","pod_id":"' + pod_id + '"}'

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setblocking(1)

host = "127.0.0.1"
port = 10101

print("Sending pod id %s (len = %s)" % (msg, len(msg)))

try:
    sock.connect((host, port))
except BlockingIOError as e:
    print("BlockingIOError")

select.select([], [sock], [])
sock.sendall(bytes(msg, 'UTF-8'))
rtn = sock.recv(4)
print("Got reply: %s" % (rtn))
sock.close()
