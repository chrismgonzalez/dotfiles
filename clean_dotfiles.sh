# Remove all dotfiles from home directory (BE CAREFUL!)
rm -f ~/.{bash_profile,bashrc,zshrc,gitconfig,gitignore,inputrc,vimrc,git-completion.zsh,aliases,p10k.zsh}

# Remove only symlinks from home directory (safer option)
find ~/ -maxdepth 1 -type l -name ".*" -delete

# Remove VS Code symlinks and files
rm -f "$HOME/Library/Application Support/Code/User/settings.json"
rm -f "$HOME/Library/Application Support/Code/User/keybindings.json"

# Or as a function you can add to your script:
function cleanup_dotfiles() {
    echo "Cleaning up existing dotfiles..."
    
    # List of dotfiles to remove
    local dotfiles=(
        .bash_profile
        .bashrc
        .zshrc
        .gitconfig
        .gitignore
        .inputrc
        .vimrc
        .git-completion.zsh
        .aliases
        .p10k.zsh
    )

    # Remove dotfiles from home directory
    for file in "${dotfiles[@]}"; do
        if [ -L "$HOME/$file" ]; then
            echo "Removing symlink: $HOME/$file"
            rm -f "$HOME/$file"
        elif [ -f "$HOME/$file" ]; then
            echo "Backing up and removing: $HOME/$file"
            mv "$HOME/$file" "$HOME/${file}.old"
        fi
    done

    # Clean up VS Code files
    local vscode_dir="$HOME/Library/Application Support/Code/User"
    if [ -L "$vscode_dir/settings.json" ]; then
        rm -f "$vscode_dir/settings.json"
    fi
    if [ -L "$vscode_dir/keybindings.json" ]; then
        rm -f "$vscode_dir/keybindings.json"
    fi

    echo "Cleanup complete!"
}