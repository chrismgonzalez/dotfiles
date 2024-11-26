#!/bin/bash

DOTFILES_DIR="$HOME"/dotfiles

if [ "$PWD" = "$DOTFILES_DIR" ]; then
    $HOME/dotfiles/save-code-extensions.sh
    git add extensions.txt