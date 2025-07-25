#!/bin/bash

WORKERS=10
OUTPUT_DIR="/home/ach/Workspace/2021-11-13/Framework/Config/LatSensitive"

python3 ./generateLatSensitiveTrace.py ${WORKERS} 500 1500 ${OUTPUT_DIR}/Test-1 Test-1
python3 ./generateLatSensitiveTrace.py ${WORKERS} 1500 1500 ${OUTPUT_DIR}/Test-2 Test-2
python3 ./generateLatSensitiveTrace.py ${WORKERS} 1500 500 ${OUTPUT_DIR}/Test-3 Test-3

python3 ./generateLatSensitiveTrace.py ${WORKERS} 1500 3000 ${OUTPUT_DIR}/Test-4 Test-4
python3 ./generateLatSensitiveTrace.py ${WORKERS} 3000 3000 ${OUTPUT_DIR}/Test-5 Test-5
python3 ./generateLatSensitiveTrace.py ${WORKERS} 3000 1500 ${OUTPUT_DIR}/Test-6 Test-6

python3 ./generateLatSensitiveTrace.py ${WORKERS} 150 600 ${OUTPUT_DIR}/Test-7 Test-7
python3 ./generateLatSensitiveTrace.py ${WORKERS} 600 600 ${OUTPUT_DIR}/Test-8 Test-8
python3 ./generateLatSensitiveTrace.py ${WORKERS} 600 150 ${OUTPUT_DIR}/Test-9 Test-9
