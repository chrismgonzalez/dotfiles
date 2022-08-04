#!/bin/bash

sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

set +e
set -x

# backup existing .zshrc file

if [ -f "$HOME/.zshrc"]; then
  mv $HOME/.zshrc $HOME/.zshrc.bak
fi

# Install Oh My zsh and powerlevel10k theme
if ! [ -d "$HOME/.oh-my-zsh"]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo "Oh My Zsh installed..."
fi

if ! [ -d "$(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  brew install romkatv/powerlevel10k/powerlevel10k
  echo "source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
fi

# copy the new .zshrc file into the dotfiles and reset the symlink
cp $HOME/.zshrc $HOME/dotfiles/.zshrc
ln -s -f ~/dotfiles/.zshrc ~/.zshrc

# if there was an existing .zshrc file present, let's append it's contents to the one created by the Oh My Zsh installer

if [ -f "$HOME/.zshrc.pre-oh-my-zsh" ]; then
  # append the old file to the new one
  echo cat $HOME/.zshrc.pre-oh-my-zsh >>$HOME/dotfiles/.zshrc
fi