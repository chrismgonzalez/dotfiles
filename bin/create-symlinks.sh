#!/bin/bash

set +e
set -x

config_files=(
  .bash_profile
  .bashrc
  .zshrc
  .gitconfig
  .gitignore
  .inputrc
  .vimrc
  .git-completion.zsh
  .aliases
  .osx
)

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

# comment out the below if you would like to manually cp your own dotfiles
# the below loop create symlinks for config files included in this repo
prompt "Create symlinks for config files"
for file in "${config_files[@]}"; do
  ln -s -f ~/dotfiles/$file ~/$file
  source ~/$file
done