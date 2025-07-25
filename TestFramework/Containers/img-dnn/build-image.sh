#!/bin/env bash

echo "[+] Copying models & input (For cloudlab)"
cp ~/img-dnn.inputs.tgz ./
mkdir -p img-dnn-src/img-dnn.inputs
tar -xzvf img-dnn.inputs.tgz -C img-dnn-src/

echo "[+] build docker image"
docker build -f Dockerfile -t img-dnn:latest .
