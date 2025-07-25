#!/bin/bash

source ../Config/SYSTEM.sh

if [ -z "$1" ]
then
    echo "Usage: ./backup.sh <FILE_PATH>"
    exit
fi

FILE_PATH=$1
BACKUP_SSH_KEY="${WORKING_DIR}/Config/ach-ec2"
BACKUP_SERVER_CONN="ach@namsan.cc.gt.atl.ga.us:/home/ach/Backups"

rsync -Pavzh -e "ssh -i ${BACKUP_SSH_KEY}" ${FILE_PATH} ${BACKUP_SERVER_CONN}