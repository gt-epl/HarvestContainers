FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y mono-runtime python3 iperf3
RUN apt-get install -y python3-pip && pip3 install setproctitle


COPY harvest_launcher.py .
COPY run_networkbully.sh .

ENTRYPOINT ["python3", "./harvest_launcher.py"]