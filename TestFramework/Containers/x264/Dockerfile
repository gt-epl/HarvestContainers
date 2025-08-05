FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3
RUN apt-get install -y python3-pip && pip3 install setproctitle
RUN apt-get install -y ffmpeg

COPY x264 .
COPY x264.sh .
COPY timed_x264.sh .
COPY harvest_launcher.py .
COPY out.py .

ENTRYPOINT ["python3", "./harvest_launcher.py"]
