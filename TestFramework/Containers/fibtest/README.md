# fibtest Container

This directory holds files for creating a fibtest container and pod.

fibtest is similar to CPUBully: each thread keeps a CPU at 100% for as long as it runs and progress made is reported upon test completion. However, there are some notable differences:
- It is written in C++ and runs as native code (i.e., it does not require Mono to run)
- Number of threads spawned is equivalent to number of workers specified. With CPUBully, the Mono runtime creates extra idle threads as part of a threadpool
- It only has a single workload: calculating the Fibonacci sequence

The *launcher.py* file is used to start fibtest with a given configuration after its pod/container have been deployed.

It can be accessed with a command similar to the following:

`curl --data "{\"duration\":\"60\",\"workers\":\"5\"}" --header "Content-Type: application/json" http://<IP-of-fibtest-Service>:20000`

Note: Unlike CPUBully, `duration` is specified in *seconds* instead of *minutes*.

Source code is available here: https://github.com/indeedeng/fibtest
