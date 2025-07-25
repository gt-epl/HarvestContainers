#!/bin/bash

PROJECT_DIR=$1
REPO_NAME=$2

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

cd ${PROJECT_DIR}/${REPO_NAME}/TestFramework/Bootstrap/dotfiles/ach/
cp ach.zsh-theme ${HOME}/.oh-my-zsh/themes 
cp tmux.conf ${HOME}/.tmux.conf 
cp vimrc ${HOME}/.vimrc 
cp zshrc ${HOME}/.zshrc
sudo chsh ach -s /usr/bin/zsh
