# HarvestMonitor - Debug Code

## Overview

`HarvestMonitor` is a Linux kernel module that checks for CPU idle status by continually calling the *idle_cpu()* Linux kernel function. It provides access to the current number of idle CPUs and a mask showing CPU idle/active status via shared memory.

## Building

Prior to building, you will need to modify the Linux source to export the *idle_cpu()* function so that it can be called from within a module. This module was developed/tested with the Linux 5.6 kernel, which has its *idle_cpu()* function defined at `./kernel/sched/core.c`. The function can be exported by adding `EXPORT_SYMBOL(idle_cpu);` immediately after its closing bracket. Following this change, you will need to build the kernel, install, and reboot with the new kernel running. Afterwards you should be able to load the `qidlecpu.ko` module.

Use the included `Makefile` to build. Builds were tested as working on `gcc (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0`.

## Running

1. Insert the module by issuing command `sudo insmod qidlecpu.ko`
2. On load, the module will create a character device at `/dev/qidlecpu` and a procfs mount at `/proc/idlecpu`. The device is used for shared memory between kernel/userspace and the procfs mount is primarily used to start/stop *idle_cpu()* polling.
3. The module's polling loop is stopped by default. Start it by issuing command `echo 1 > /proc/idlecpu/control` and stop it by issuing command `echo 0 > /proc/idlecpu/control`.
4. See the `HarvestBalancer` code for an example of how to mount shared memory exported by `HarvestMonitor` for sharing idle CPU status.

## Caveats

There are some rough edges. Things to keep in mind:

1. To avoid locking up the system by backlogging too many RCUs, the module calls *schedule()* every 100,000 iterations. This works in theory and seems to work in practice, but there may be (and likely is) a more elegant solution.
