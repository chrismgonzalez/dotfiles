#!/bin/bash

# install homebrew

# install packages

important_casks=(
  visual-studio-code
)

brews=(
  wget
  gnupg
  awscli
  granted
  cfn-lint
  k9s
  tmux
  tree
  ack
  jq
  htop
  tldr
  coreutils
  pre-commit
  vim  
  git
  neovim
  go@${GO_VERSION}
  tfenv
  terraform-docs
  git-extras
  git-lfs
  gnu-sed
  gnupg
  kubectl
  kubeadm
  minikube
  kubernetes-cli
  pinentry-mac # to resolve gpg signing issues on mac
)

casks=(
  docker
  rectangle
)

echo "------------------------------"
echo "Begin installs..."
echo "------------------------------"

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

install 'brew install --cask' "${casks[@]}"

prompt "Install secondary packages"

install 'pip3 install --upgrade' "${pips[@]}"

install 'code --install-extension' "${vscode[@]}"

brew tap homebrew/cask-fonts

install 'brew install --cask' "${fonts[@]}"