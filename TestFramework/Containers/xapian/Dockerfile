FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3 python3-pip libopencv-dev
RUN pip install numpy scipy

COPY xapian-src/ /src/
WORKDIR /src/xapian/

ENTRYPOINT ["python3", "-u", "./launcher.py"]
