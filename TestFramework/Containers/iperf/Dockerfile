FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y iperf3
RUN which iperf3
CMD ["/usr/bin/iperf3", "-s"]
