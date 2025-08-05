FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3
RUN apt-get install -y python3-pip && pip3 install setproctitle

COPY dedup .
COPY dedup.sh .
COPY timed_dedup.sh .
COPY harvest_launcher.py .

ENTRYPOINT ["python3", "./harvest_launcher.py"]
