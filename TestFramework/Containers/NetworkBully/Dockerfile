FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y iperf3

COPY iperf3_server.sh .

ENTRYPOINT ["/bin/sh", "-c", "./iperf3_server.sh"]
