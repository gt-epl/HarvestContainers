#!/usr/bin/env python3
# Based on: https://gist.github.com/nitaku/10d0662536f37a087e1b
from http.server import BaseHTTPRequestHandler, HTTPServer
import socketserver
import json
import cgi
import sys
import subprocess
import os
from sys import argv

def setenv(message):
    os.environ['TBENCH_WARMUPREQS']     = message['TBENCH_WARMUPREQS']
    os.environ['TBENCH_SERVER']         = message['TBENCH_SERVER']
    os.environ['TBENCH_SERVER_PORT']    = message['TBENCH_SERVER_PORT']
    os.environ['TBENCH_NCLIENTS']       = message['TBENCH_NCLIENTS']

    os.environ["TBENCH_MNIST_DIR"]      = message["TBENCH_MNIST_DIR"]     
    os.environ["TBENCH_CLIENT_THREADS"] = message["TBENCH_CLIENT_THREADS"]
    os.environ["TBENCH_MINSLEEPNS"]     = message["TBENCH_MINSLEEPNS"]    
    os.environ["TBENCH_RANDSEED"]       = message["TBENCH_RANDSEED"]      

    #set maxreqs based on duration
    qps = int(message['qps'])
    dur = int(message['duration'])
    maxreqs = dur*qps
    os.environ['TBENCH_MAXREQS'] = str(maxreqs)
    os.environ['TBENCH_QPS'] = str(qps)

class Server(BaseHTTPRequestHandler):
    
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_HEAD(self):
        self._set_headers()

    def do_GET(self):
        self._set_headers()
        message = {}
        out, err = subprocess.check_output('cat server.console')
        message['msg'] = str(out)
        message['err'] = err

        self.wfile.write(json.dumps(message).encode())

    def do_POST(self):
        ctype, pdict = cgi.parse_header(self.headers.get('content-type'))

        # refuse to receive non-json content
        if ctype != 'application/json':
            self.send_response(400)
            self.end_headers()
            return

        # read the message and convert it into a python dictionary
        length = int(self.headers.get('content-length'))
        message = json.loads(self.rfile.read(length))


        nthreads = message['nthreads']
        duration = message['duration']
        model = message['model']
        reqs = message['reqs']

        # Run img-dnn with posted parameters
        setenv(message)

        resp = {}
        resp['status'] = "started server"
        self._set_headers()
        self.wfile.write(json.dumps(resp).encode())

        # send the message back
        print(nthreads, duration, model, reqs)

        os.system(f'./img-dnn_integrated -r {nthreads} -f {model} -n {reqs} > server.console 2>&1')
        os.system('mv lats.bin /results/')
         
        

def run(server_class=HTTPServer, handler_class=Server, port=20000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)

    print(f"img-dnn launcher. Serving on port {port}")
    httpd.serve_forever()

if __name__ == "__main__":

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
