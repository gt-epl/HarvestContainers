# bin

Populate this dir w/ binaries used for tests

- balancer
- cpulogger.ko
- qidlecpu.ko 

## Balancer

There are 3 versions of balancer:
    1. `static-balancer` uses the static method, where targetIdleCores is set once and remains the same for the entire duration of the run.
    2. `dynamic-balancer` uses the dynamic method, where it takes a starting value for targetIdleCores and increases/decreases commensurate w/ system state.
    3. `multi-balancer` uses the dynamic method, but also incorporates support for running multiple Primary containers simultaneously.
        - Currently this build hardcores values for MySQL, Memcached, and Xapian running on Cloudlab c6420 instances.
            * MySQL is configured to run on CPU `2,4,6,8,10,12,14,16` with CDR=0.0365, LOW_TIC=2, and targetIdleCores=4
            * Memcached is configured to run on CPU `1,3,5,7,9,11,13,15` with CDR=0.003, LOW_TIC=2, and targetIdleCores=7
            * Xapian is configured to run on CPU `0,18,20,22,24,26,28,30` with CDR=0.33, LOW_TIC=3, and targetIdleCores=3

TODO: Balancer binaries will be merged into a single monolithic version in the future.
