#!/bin/bash

source ../../bin/boilerplate.sh
source ../../Config/LATSENSITIVE.sh

# Uncomment to use local vars
#LS_CONFIG="config.json"
#LS_OUTPUT="latsensitive.out"

runLSContainer ${LS_CONFIG} fg