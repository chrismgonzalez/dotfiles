#!/bin/bash

# This script is specifically targeted to setup the development environment for a work machine
# please review code within to be sure it meets your expectations.

# Newer macs may have certain software preinstalled, thus, be sure to check your system for existing defaults.

# The intent behind this script is to bake in sensible defaults for a base configuration
# of a new development machine

# Requirements: MacOS

sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


echo "------------------------------------"
echo "Installing Xcode Command Line Tools."
echo "------------------------------------"
# Install Xcode command line tools, this will take awhile
# check if they are installed, if not, install them

if [[-n xcode-select -p]]
  then
    printf "xcode command line tools already exist on system"
  else
    xcode-select --install
fi

echo "------------------------------------"
echo "-----Create folder for downloads----"
echo "------------------------------------"

# Create a folder that contains downloaded things for the setup
INSTALL_FOLDER=~/.macsetup
mkdir -p $INSTALL_FOLDER
MAC_SETUP_PROFILE=$INSTALL_FOLDER/macsetup_profile

# initial setup for finder
echo "------------------------------------"
echo "-------- Customizing MacOS ---------"
echo "------------------------------------"

# Install some stuff before others!
important_casks=(
  visual-studio-code
)

brews=(
  wget
  awscli
  cfn-lint
  tree
  ack
  jq
  htop
  tldr
  coreutils
  vim  
  git
  go@${GO_VERSION}
  tfenv
  terraform-docs
  git-extras    # for git undo
  git-lfs
  gnu-sed --with-default-names
  kubectl
  kubernetes-cli
)

casks=(
  docker
  alacritty
  rectangle
)

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
)

fonts=(
  font-fira-code
  font-source-code-pro
  font-jetbrains-mono
  font-victor-mono
)

GO_VERSION=1.18
TERRAFORM_VERSION=1.0.11

######################################## End of app list ########################################

set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    #prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
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

echo "Install important software ..."
brew tap homebrew/cask-versions
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"


echo "------------------------------"
echo "Upgrade Bash"
echo "------------------------------"

prompt "Upgrade bash"
brew install bash bash-completion@2 fzf
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
sudo chsh -s "$(brew --prefix)"/bin/bash

echo "[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion" >> ~/.bashrc
source ~/.bash_profile

# We installed the new shell, now we have to activate it
echo "Adding the newly installed shell to the list of allowed shells"
# Prompts for password
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'

echo "------------------------------"
echo "Begin installs..."
echo "------------------------------"

install 'brew cask install' "${casks[@]}"

prompt "Install secondary packages"
install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

echo "-----------------------------------"
echo "Finish Go installation requirements"
echo "-----------------------------------"

mkdir -p $GOPATH $GOPATH/src $GOPATH/pkg $GOPATH/bin

echo "------------------------------"
echo "Install Terraform"
echo "------------------------------"
tfenv install ${TERRAFORM_VERSION}
tfenv use ${TERRAFORM_VERSION}

# verify tooling
echo "------------------------------"
echo "Checking terraform version"
echo "------------------------------"
terraform --version


echo "------------------------------"
echo "Checking AWS CLI"
echo "------------------------------"

aws --version

echo "------------------------------"
echo "Checking kubectl version & configuration"
echo "------------------------------"

kubectl version --client

export BASH_COMPLETION_COMPAT_DIR="usr/local/etc/bash_completion.d"
[[-r "usr/local/etc/profile.d/bash_completion.sh"]] && . "usr/local/etc/profile.d/bash_completion.sh"


prompt "Update packages"
pip3 install --upgrade pip setuptools wheel

prompt "Cleanup"
brew cleanup

echo "Done!"

