#!/bin/bash

source ../../bin/boilerplate.sh
source ../../Config/TERASORT.sh

# Uncomment to use local vars
#TERASORT_OUTPUT="outputs/terasort.out"
#TERASORT_WORKLOAD="100M"

runTerasortContainer fg ${TERASORT_WORKLOAD}