#!/bin/bash

cd ${HOME}

PROJECT_DIR="/project"
REPO_NAME="HarvestContainers"

echo "[+] Disabling swap"
sudo swapoff -a
# Remove last line from /etc/fstab to ensure swap isn't enabled on boot
sudo sed -i.bak '$d' /etc/fstab

echo "[+] Updating group permissions for current user"
sudo groupadd harvest
sudo usermod -aG docker ${USER}
sudo usermod -aG harvest ${USER}

if [ ! -d "${PROJECT_DIR}" ]
then
    sudo mkdir ${PROJECT_DIR}
fi

cd ${PROJECT_DIR}

echo "[+] Updating TestFramework repo"
if [ ! -d "${PROJECT_DIR}/${REPO_NAME}/TestFramework" ]
then
    sudo chown -R ${USER}.harvest ${PROJECT_DIR}
    cd ${PROJECT_DIR}
    GIT_SSH_COMMAND="ssh -i ${PROJECT_DIR}/.misc/testframework-ro" git clone git@github.com:achgt/HarvestContainers.git
else
    sudo chown -R ${USER}.harvest ${PROJECT_DIR}
    cd ${PROJECT_DIR}/${REPO_NAME}
    GIT_SSH_COMMAND="ssh -i ${PROJECT_DIR}/.misc/testframework-ro" git pull 
fi

if [ -f "${PROJECT_DIR}/${REPO_NAME}/TestFramework/Bootstrap/dotfiles/${USER}/copy_dotfiles.sh" ]
then
    echo "[+] Copying dotfiles to homedir"
    source ${PROJECT_DIR}/${REPO_NAME}/TestFramework/Bootstrap/dotfiles/${USER}/copy_dotfiles.sh ${PROJECT_DIR} ${REPO_NAME}
fi

echo "[+] Fixing permissions on ${PROJECT_DIR}"
sudo chown -R ${USER}.harvest ${PROJECT_DIR}

# Make sure files are user/group executable
sudo find ${PROJECT_DIR} -type f -name "*.sh" -exec chmod 774 {} \;
sudo find ${PROJECT_DIR} -type f -executable -exec chmod 774 {} \;

# Fix symlink to libevent so memcached/mutilate will work
sudo ln -s /lib/x86_64-linux-gnu/libevent-2.1.so.7 /lib/x86_64-linux-gnu/libevent-2.1.so.6
