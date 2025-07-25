FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip3 install setproctitle

COPY fibtest . 
COPY harvest_launcher.py .

ENTRYPOINT ["python3", "./harvest_launcher.py"]
