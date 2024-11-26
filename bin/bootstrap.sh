#!/bin/bash

# This script is specifically targeted to setup the development environment for a work machine
# it is stripped down compared to setup.sh

sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


echo "------------------------------------"
echo "Installing Xcode Command Line Tools."
echo "------------------------------------"
# Install Xcode command line tools
xcode-select --install


echo "----------------------------------------------"
echo "-----Creating folder for install downloads----"
# Create a folder that contains downloaded things for the setup
INSTALL_FOLDER=~/.macsetup
mkdir -p $INSTALL_FOLDER
MAC_SETUP_PROFILE=$INSTALL_FOLDER/macsetup_profile

# initial setup for finder

echo "----- Customizing MacOS -----"

## call .osx script
chmod +x ./.osx
./.osx

# # show library folder
# chflags nohidden ~/Library

# # show hidden folders
# defaults write com.apple.finder AppleShowAllFiles YES

# # show path bar
# defaults write com.apple.finder ShowPathbar -bool true

# # show status bar
# defaults write com.apple.finder ShowStatusBar -bool true

echo "-------------------"
echo "installing homebrew"
echo "-------------------"


# install brew
if ! hash brew
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew update
  brew upgrade --all
else
  printf "\e[93m%s\e[m\n" "You already have brew installed."
fi

echo "-------------------------"
echo "Installing brew applications"

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed
# Install Bash 4.
brew install bash
brew install bash-completion

echo "[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion" >> ~/.bashrc
source ~/.bash_profile

# We installed the new shell, now we have to activate it
echo "Adding the newly installed shell to the list of allowed shells"
# Prompts for password
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
# Change to the new shell, prompts for password
chsh -s /usr/local/bin/bash

echo "------------------------------"
echo "installing curl/wget/git/bash "
echo "------------------------------"

# CURL / WGET
brew install curl
brew install wget

{
  # shellcheck disable=SC2016
  echo 'export PATH="/usr/local/opt/curl/bin:$PATH"'
  # shellcheck disable=SC2016
  echo 'export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"'
  # shellcheck disable=SC2016
  echo 'export PATH="/usr/local/opt/sqlite/bin:$PATH"'
}>>$MAC_SETUP_PROFILE

# git
brew install git
git config --global credential.helper osxkeychain

echo "------------------------------------"
echo "installing Alacritty and other tools"
echo "------------------------------------"

# Pimp command line
brew install lsd                                                                                      # replacement for ls
{
  echo "alias ls='lsd'"
  echo "alias l='ls -l'"
  echo "alias la='ls -a'"
  echo "alias lla='ls -la'"
  echo "alias lt='ls --tree'"
} >>$MAC_SETUP_PROFILE

brew install \
awscli \
tree \
ack \
jq \
htop \
tldr \
coreutils \
watch \
vim \
ssh-copy-id \

echo "------------------------------"
echo "Common Applications & Fonts"
echo "------------------------------"

brew install --cask \
font-jetbrains-mono \
font-victor-mono \
alacritty \
google-chrome \
firefox \
kap \
rectangle \
visual-studio-code \

echo "------------------------------"
echo "Install progrmaming languages "
echo "------------------------------"

echo "------------------------------"
echo "Go@1.18"
echo "------------------------------"

brew install go@1.18
mkdir -p $GOPATH $GOPATH/src $GOPATH/pkg $GOPATH/bin

echo "---------------------------------"
echo "Clean up existing python installs"
echo "---------------------------------"

rm /usr/local/bin/python*
rm /usr/local/bin/pip*
rm /usr/bin/python*
rm /usr/bin/pip*

rm -Rf /Library/Frameworks/Python.framework/Versions/*

brew install python3
brew install pipenv

echo "------------------------------"
echo "Docker"
echo "------------------------------"

# Docker
brew install docker
docker run hello-world
docker-machine stop default


echo "------------------------------"
echo "Cleaning up homebrew installs"
echo "------------------------------"
brew cleanup

# # create ssh keys
# echo "------------------------------"
# echo "Creating SSH keys"
# echo "------------------------------"

# ssh-keygen -t ed25519 -C "$EMAIL"

# echo "------------------------------"
# echo "adding key to auth agent"
# echo "------------------------------"

# ssh-add ~/.ssh/id_rsa


echo "--------------------------------"
echo "Add aliases and paths to profile"
echo "--------------------------------"

## TODO

echo "------------------------------"
echo "Source the shells"
echo "------------------------------"

{
  echo "source $MAC_SETUP_PROFILE # alias and things added by mac_setup script"
}>>~/.bash_profile
{
  echo "source $MAC_SETUP_PROFILE"
}>>~/.zshrc

# shellcheck disable=SC1090
source ~/.bash_profile
source ~/.zshrc