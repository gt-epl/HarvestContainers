FROM ubuntu:18.04

COPY memcached .
COPY libevent-2.1.so.7 /lib/x86_64-linux-gnu/libevent-2.1.so.7

COPY memcached.sh .

ENTRYPOINT ["/bin/sh", "-c", "./memcached.sh"]
