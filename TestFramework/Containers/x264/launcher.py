import socket
import sys
import subprocess
from _thread import *

host = ''
port = 1984
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    s.bind((host, port))
except socket.error as e:
    print(str(e))

s.listen(5)

def get_client_input(conn):
    conn.send(str.encode('x264 launcher ready\n'))

    while True:
        data = conn.recv(2048)
        reply = 'Starting workload'
        if not data:
            break
        conn.sendall(str.encode(reply))
    conn.close()

while True:
    conn, addr = s.accept()
    subprocess.run(["/bin/sh", "-c", "/x264_net.sh"])
    sys.exit(0)
