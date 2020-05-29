#!/bin/bash

sudo apt update

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo apt install -y $1
  else
    echo "Already installed: ${1}"
  fi
}

# Basics
install awscli
install chromium-browser
install curl
install exfat-utils
install file
install git
install htop
install nmap
install neofetch
install openvpn
install tmux
install vim
install vlc
install p7zip-full
install steam
install rsync
install unzip
install slack-desktop
install discord

# Image processing
install gimp
install jpegoptim
install optipng

# Fun stuff
install figlet
install lolcat
