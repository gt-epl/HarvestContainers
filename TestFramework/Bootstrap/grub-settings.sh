#!/bin/bash

# TODO: Copy settings based on ENV_TYPE

mv /etc/default/grub.d/50-cloudimg-settings.cfg 50-cloudimg-settings.BAK
sudo cp ./50-cloudimg-settings.cfg /etc/default/grub.d/50-cloudimg-settings.cfg
