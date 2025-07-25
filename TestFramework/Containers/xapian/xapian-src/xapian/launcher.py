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
    #set maxreqs based on duration
    qps = int(message['qps'])
    dur = int(message['duration'])
    maxreqs = dur*qps

    os.environ['TBENCH_QPS']        = str(qps)
    os.environ['TBENCH_MAXREQS']    = str(maxreqs)
    os.environ['TBENCH_WARMUPREQS'] = message['TBENCH_WARMUPREQS']
    os.environ["TBENCH_MINSLEEPNS"] = message["TBENCH_MINSLEEPNS"]    
    os.environ["TBENCH_RANDSEED"]   = message["TBENCH_RANDSEED"]      
    os.environ["TBENCH_TERMS_FILE"] = message["TBENCH_TERMS_FILE"]     
    os.environ["LD_LIBRARY_PATH"]   = "/src/xapian/xapian-core-1.2.13/install/lib/"

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
        dataset = message['dataset']

        # Run img-dnn with posted parameters
        setenv(message)

        resp = {}
        resp['status'] = "started server"
        self._set_headers()
        self.wfile.write(json.dumps(resp).encode())

        # send the message back
        print(nthreads, duration) 

        os.system(f'./xapian_integrated -n {nthreads} -d {dataset} -r 1000000000 > server.console 2>&1')
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
