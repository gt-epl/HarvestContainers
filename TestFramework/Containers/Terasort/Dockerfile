FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y openjdk-8-jre python3 curl
RUN apt-get install -y python3-pip && pip3 install setproctitle

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN curl -L https://archive.apache.org/dist/hadoop/core/hadoop-2.7.1/hadoop-2.7.1.tar.gz | tar -xz -C /usr/local/

COPY terasort.sh .
COPY harvest_launcher.py .

ENTRYPOINT ["python3", "./harvest_launcher.py"]

