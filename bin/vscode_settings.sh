#!/bin/bash

VSCODE_USER_PATH="$HOME/Library/Application Support/Code/User"
DOTFILES_VSCODE_PATH="$HOME/.dotfiles/vscode"

function export_vscode_settings() {
    echo "Exporting VS Code settings..."
    
    # Create vscode directory in dotfiles if it doesn't exist
    mkdir -p "$DOTFILES_VSCODE_PATH"

    # Copy settings and keybindings
    cp "$VSCODE_USER_PATH/settings.json" "$DOTFILES_VSCODE_PATH/"
    cp "$VSCODE_USER_PATH/keybindings.json" "$DOTFILES_VSCODE_PATH/"
    
    # Export extensions list
    code --list-extensions > "$DOTFILES_VSCODE_PATH/extensions.txt"
    
    echo "VS Code settings exported to $DOTFILES_VSCODE_PATH"
}

function import_vscode_settings() {
    echo "Importing VS Code settings..."
    
    # Create VS Code user directory if it doesn't exist
    mkdir -p "$VSCODE_USER_PATH"
    
    # Copy settings and keybindings
    cp "$DOTFILES_VSCODE_PATH/settings.json" "$VSCODE_USER_PATH/"
    cp "$DOTFILES_VSCODE_PATH/keybindings.json" "$VSCODE_USER_PATH/"
    
    # Install extensions
    while read extension; do
        code --install-extension "$extension"
    done < "$DOTFILES_VSCODE_PATH/extensions.txt"
    
    echo "VS Code settings imported"
}

# Usage
case "$1" in
    "export")
        export_vscode_settings
        ;;
    "import")
        import_vscode_settings
        ;;
    *)
        echo "Usage: $0 {export|import}"
        exit 1
        ;;
esac