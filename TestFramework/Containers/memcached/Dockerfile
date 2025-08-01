FROM ubuntu:18.04

COPY memcached .
COPY libevent-2.1.so.7 /lib/x86_64-linux-gnu/libevent-2.1.so.7

COPY memcached.sh .

# can change these values in k8s deployment yaml
ENV MEMCACHED_THREADS=8
ENV MEMCACHED_CONNS=32768
ENV MEMCACHED_RAM=16384

ENTRYPOINT ["/bin/sh", "-c", "./memcached.sh"]
