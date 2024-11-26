#!/bin/bash

# This script is specifically targeted to setup the development environment for a new macOS machine
# please review code within to be sure it meets your expectations.

# Newer macs may have certain software preinstalled, thus, be sure to check your system for existing defaults.

# The intent behind this script is to bake in sensible defaults for a base configuration
# of a new development machine.

# Requirements: MacOS

sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


echo "------------------------------------"
echo "Installing Xcode Command Line Tools."
echo "------------------------------------"
# Install Xcode command line tools, this will take awhile
# check if they are installed, if not, install them.

if ! [ -x "$(command -v gcc)" ]; then
  xcode-select --install
  else
  echo "xcode command line tools appear to be installed..."
fi

GO_VERSION=1.18
TERRAFORM_VERSION=1.2.0
NODE_VERSION=16

# Install some stuff before others!

pips=(
  pipenv
)


vscode=(
  formulahendry.auto-close-tag
  ms-azuretools.vscode-docker
  golang.go
  premparihar.gotestexplorer
  ms-kubernetes-tools.vscode-kubernetes-tools
  taniarascia.new-moon-vscode
  ms-python.python
  RoscoP.ActiveFileInStatusBar
  wesbos.theme-cobalt2
  eamodio.gitlens
  HashiCorp.terraform
)

fonts=(
  font-fira-code
  font-jetbrains-mono
  font-victor-mono
  font-victor-mono-nerd-font
)


######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}


function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

## add homebrew to path, if it's already there, don't add a new line entry
if ! grep -qF "/opt/homebrew/bin/brew" $HOME/.zprofile; then
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' | sudo tee -a $HOME/.zprofile
fi

prompt "Install Oh My Zsh"
chmod +x install-ohmyzsh.sh
./install-ohmyzsh.sh

echo "Install important software ..."
brew tap homebrew/cask-versions
install 'brew install --cask' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"

# check if .zshrc is present in the $HOME dir, if not, create it.  This file is needed for future commands.
if ! [ -f $HOME/.zshrc ]; then
  echo "Creating .zshrc in $HOME directory"
   touch $HOME/.zshrc
fi

echo "------------------------------"
echo "        Upgrade Bash          "
echo "------------------------------"

prompt "Upgrade bash"
brew install bash bash-completion@2 fzf

# We installed the new shell, now we have to activate it
echo "Adding the newly installed shell to the list of allowed shells"

if ! grep -qF "$(brew --prefix)/bin/bash" /etc/shells; then
    sudo echo "$(brew --prefix)/bin/bash" >> /private/etc/shells
    sudo echo "/usr/local/bin/bash" >> /etc/shells
    sudo echo "$(brew --prefix)/bin/bash" >> /etc/shells
fi

# bash completion
if [ -f /sw/etc/bash_completion ]; then
   . /sw/etc/bash_completion >> $HOME/.zshrc
   source $HOME/.zshrc
fi

echo "-----------------------------------"
echo "Finish Go installation requirements"
echo "-----------------------------------"

GOPATH=$HOME/go
mkdir -p $GOPATH $GOPATH/src $GOPATH/pkg $GOPATH/bin

echo "------------------------------"
echo "Install Terraform"
echo "------------------------------"

tfenv install ${TERRAFORM_VERSION}
tfenv use ${TERRAFORM_VERSION}

# verify tooling
echo "------------------------------"
echo "  Checking terraform version  "
echo "------------------------------"

terraform --version

echo "------------------------------"
echo "      Checking AWS CLI        "
echo "------------------------------"

aws --version

echo "-----------------------------------------"
echo " Checking kubectl version & configuration "
echo "-----------------------------------------"

kubectl version --client --output=json

prompt "Update packages"
pip3 install --upgrade pip setuptools wheel


prompt "Cleanup"
brew cleanup

# source shells one last time
prompt "Source shells again"
source $HOME/.zprofile
source $HOME/.zshrc
source $HOME/.bashrc
source $HOME/.bash_profile
source $HOME/.git-completion.bash
source $HOME/.vimrc

echo "Done!"

