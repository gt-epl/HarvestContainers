# Cloudlab Setup Notes

## Introduction
---
All experiments (functional & performance) were carried out on resources made available by [Cloudlab](https://www.cloudlab.us).
We primarily make use of 2 resource types. Refer [cloudlab docs](http://docs.cloudlab.us/hardware.html) for more details:
1. `c220g5` - 20 core Xeon Silvers (Skylake)
2. `c6420` - 16 core Xeon Gold (Skylake)

Performance runs were carried out on `c6420` machines.

## Requesting Resources on Cloulab
---
We make use of the following profiles to instantiate resources (aka creating an experiment on cloudlab)
A 3 (or even 2) node cluster is sufficient for all experiments.

Profiles:
1. For `c220g5` - https://www.cloudlab.us/show-profile.php?uuid=01f42c4b-c3a1-11ed-b28b-e4434b2381fc
2. For `c6420` - https://www.cloudlab.us/show-profile.php?uuid=70b392b8-0dc8-11ed-aacb-e4434b2381fc

>  **Note:** Cloudlab only allows you to create an experiment for upto 16 hours. You may request a reservation to create an experiment and then extend it for longer.

## Setting up management access.
---
- We will rely on ssh keys and aliases to access and manage the physical nodes.
- In fact, most scripts make use of ssh aliases to address and trigger runs on different machines
- Create a key-pair exclusive for cloudlab management using `ssh-keygen`
- You may create a key-pair for github access as well, since most of the code will need to be pulled from the remote repo.
- You will need to change group permissions on the `/project` directory recursively to avoid multi-user access restrictions. 
    ```bash
    sudo chmod 775 -R /project
    sudo chgrp -R nfslicer-PG0 /project
    ```

## Helper Scripts
---
> **WARNING:** Please review these scripts before executing. These scripts are customized to the "asarma31" user.
If you copy the ssh access urls from the experiment page of cloudlab into your clipboard, you can use the following scripts to auto-create ssh config for the provisioned resources.

> Requires `pbpaste` or [`xclip`](https://ostechnix.com/how-to-use-pbcopy-and-pbpaste-commands-on-linux/) for linux.

1. Text to copy from cloudlab.us/status.php:
    ```
    ssh asarma31@c220g5-110513.wisc.cloudlab.us
    ssh asarma31@c220g5-110519.wisc.cloudlab.us
    ssh asarma31@c220g5-110504.wisc.cloudlab.us
    ```

2. Create ssh configs in ~/.ssh/config.d/clab.sshconfig. (also creates hosts.txt)
   Run `HarvestContainers/TestFramework/Experiments/cloudlab/bootstrap/gencfg.sh`

3. Copy rc/.config files to cloudlab machines. Modify as needed and run the following file with the `--host` argument:
```bash
    HarvestContainers/TestFramework/Experiments/cloudlab/bootstrap/prep.py --hosts hosts.txt
```

## Dependencies

---
- Both machine types have a prebuilt image which should have all deps pre-built with minor exceptions which can be fixed by using `sudo apt install`. 
- The main code repository in the pre-built machine is located at `/project/HarvestContainers/`
- Please pull latest code (assuming ssh keys to access github is setup on all cloudlab nodes)
- The pre-built image already has some deps installed. Please see `/project/HarvestContainers/TestFramework/Bootstrap/firstboot.sh` for deps present in the image.
- Please see [Fix Dependencies](#fix-dependencies) for deps currently missing in the prebuilt image.

### Power Fix
- Fix frequencies for c6420 machines:
  - Run `/project/HarvestContainers/TestFramework/Bootstrap/powerfix.sh`
- Fix for c220g2:
  - Turn of smt ([source](https://serverfault.com/questions/235825/))
  
    `echo off | sudo tee /sys/devices/system/cpu/smt/control` disable-hyperthreading-from-within-linux-no-access-to-bios)
  - Review and run `/project/HarvestContainers/TestFramework/Experiment/cloudlab/bootstrap/setcpufreq.sh`
  - You may need to load acpi-cpufreq kernel module using `sudo modprobe`


### Setup Disk
1. cloudlab nodes have limited disk space. But we can mount more disk space.
2. Check if disk space is available (more than 500GB)
    ```bash
    # Commonly, for c6420 machines, disk space can be mounted on /dev/sda4. 
    lsblk -a

    # format drive
    sudo mkfs -t ext4 /dev/sda4

    # create drive. Please stick to same name for drive
    sudo mkdir /mnt/extra

    # mount drive. This will be valid till next boot
    sudo mount /dev/sda4 /mnt/extra

    # change permissions if necessary
    sudo chmod -R 775 /mnt/extra
    sudo chgrp -R nfslicer-PG0 /mnt/extra
    ```

## Fix Dependencies
---
1. `pip install scipy`
2. `sudo apt install uuid-dev`
