#!/bin/python3
# Based on: https://gist.github.com/nitaku/10d0662536f37a087e1b
from http.server import BaseHTTPRequestHandler, HTTPServer
import socketserver
import json
import cgi
import sys
import subprocess

class Server(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_HEAD(self):
        self._set_headers()

    def do_GET(self):
        self._set_headers()
        self.wfile.write(json.dumps({'received': 'ok'}))

    def do_POST(self):
        if self.path == "/run":
            ctype, pdict = cgi.parse_header(self.headers.get('content-type'))

            # refuse to receive non-json content
            if ctype != 'application/json':
                self.send_response(400)
                self.end_headers()
                return

            # read the message and convert it into a python dictionary
            length = int(self.headers.get('content-length'))
            message = json.loads(self.rfile.read(length))

            # send the message back
            self._set_headers()
            self.wfile.write(json.dumps(message).encode())

            trial_name = message['trial']
            num_qps = message['qps']
            duration = message['duration']
            memcached_server = message['memcached_server']

            # Run cpubully with posted parameters
            subprocess.run(["./run_mutilate.sh", trial_name, num_qps, duration, memcached_server])

        elif self.path == "/load":
            

            ctype, pdict = cgi.parse_header(self.headers.get('content-type'))

            # refuse to receive non-json content
            if ctype != 'application/json':
                self.send_response(400)
                self.end_headers()
                return

            # read the message and convert it into a python dictionary
            length = int(self.headers.get('content-length'))
            message = json.loads(self.rfile.read(length))

            # send the message back
            self._set_headers()
            self.wfile.write(json.dumps(message).encode())

            memcached_server = message['memcached_server']
            subprocess.run(["./load.sh", memcached_server])

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error": "Not found"}')
def run(server_class=HTTPServer, handler_class=Server, port=20003):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)

    httpd.serve_forever()

if __name__ == "__main__":
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
