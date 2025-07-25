#sendpodid.py
#!/usr/bin/env python3
import sys

import socket
import select

if len(sys.argv) < 2:
  msg = "TESTTEST-TEST-TEST-TEST-TESTTESTTEST"
else:
  msg = sys.argv[1]

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
if sock.send(bytes(msg, 'UTF-8')) == len(msg):
    print("Sent ", repr(msg), " successfully.")
rtn = sock.recv(4)
print("Got reply: %s" % (rtn))

sock.close()
