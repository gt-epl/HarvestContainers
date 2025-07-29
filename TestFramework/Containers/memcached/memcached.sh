#!/bin/bash

/memcached -t ${MEMCACHED_THREADS} -c ${MEMCACHED_CONNS} -m ${MEMCACHED_RAM} -u root -p 11212
