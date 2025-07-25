FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3 python3-pip libopencv-dev
RUN pip install numpy scipy

COPY img-dnn-src/ /src/
WORKDIR /src/img-dnn/
RUN make clean && make

ENTRYPOINT ["python3", "./launcher.py"]
