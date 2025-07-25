#!/bin/bash

ARCHIVE_NAME=$1
RESULTS_PATH=$2

7z a -mmt=47 -t7z ${ARCHIVE_NAME} -m0=lzma2 -mx=9 -aoa ${RESULTS_PATH}
