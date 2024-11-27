#!/bin/bash

# Mac Development Environment Setup Script
# Requirements: MacOS

# Global flags
DRY_RUN=false
GO_VERSION="1.23"
GO_PATH="$HOME/go"

# Package lists
important_casks=(
    visual-studio-code
)

brews=(
    wget
    gnupg
    awscli
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
    neovim
    "go@${GO_VERSION}"
    git-extras
    git-lfs
    gnu-sed
    gnupg
    kubectl
    pinentry-mac
)

casks=(
    docker
    rectangle
)

node_packages=(
    typescript
    ts-node
    create-next-app
    npm@latest
)

# vscode=(
#     amazonwebservices.aws-toolkit-vscode
#     ameenahsanma.poetry-monorepo
#     antfu.browse-lite
#     azemoh.one-monokai
#     batisteo.vscode-django
#     bierner.markdown-preview-github-styles
#     boto3typed.boto3-ide
#     continue.continue
#     cstrap.flask-snippets
#     davidanson.vscode-markdownlint
#     dbaeumer.vscode-eslint
#     donjayamanne.python-environment-manager
#     donjayamanne.python-extension-pack
#     dsznajder.es7-react-js-snippets
#     eamodio.gitlens
#     edison1105.vite-theme-night
#     esbenp.prettier-vscode
#     formulahendry.auto-close-tag
#     github.copilot
#     github.copilot-chat
#     github.vscode-github-actions
#     github.vscode-pull-request-github
#     golang.go
#     hashicorp.terraform
#     hbenl.vscode-test-explorer
#     kevinrose.vsc-python-indent
#     littlefoxteam.vscode-python-test-adapter
#     me-dutour-mathieu.vscode-github-actions
#     meezilla.json
#     mightbesimon.emoji-icons
#     ms-azuretools.vscode-docker
#     ms-kubernetes-tools.vscode-kubernetes-tools
#     ms-python.autopep8
#     ms-python.black-formatter
#     ms-python.debugpy
#     ms-python.isort
#     ms-python.python
#     ms-python.vscode-pylance
#     ms-toolsai.jupyter
#     ms-toolsai.jupyter-keymap
#     ms-toolsai.jupyter-renderers
#     ms-toolsai.vscode-jupyter-cell-tags
#     ms-toolsai.vscode-jupyter-slideshow
#     ms-vscode-remote.remote-containers
#     ms-vscode-remote.remote-ssh
#     ms-vscode-remote.remote-ssh-edit
#     ms-vscode-remote.remote-wsl
#     ms-vscode-remote.vscode-remote-extensionpack
#     ms-vscode.makefile-tools
#     ms-vscode.remote-explorer
#     ms-vscode.remote-server
#     ms-vscode.test-adapter-converter
#     njpwerner.autodocstring
#     pkief.material-icon-theme
#     premparihar.gotestexplorer
#     redhat.vscode-yaml
#     roscop.activefileinstatusbar
#     sameeramin.cdk-snippets-for-python
#     taniarascia.new-moon-vscode
#     tomoki1207.pdf
#     visualstudioexptteam.intellicode-api-usage-examples
#     visualstudioexptteam.vscodeintellicode
#     vscodevim.vim
#     wesbos.theme-cobalt2
#     wholroyd.jinja
#     zainchen.json
# )

fonts=(
    font-fira-code
    font-jetbrains-mono
    font-victor-mono
    font-victor-mono-nerd-font
)

pipx=(
    pipenv
    poetry
    black
    flake8
    pytest
    mypy
)


zsh_plugins=(
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
)


# Confirmation function
function confirm() {
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Backup function
function backup_existing() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.dotfiles_backup_$timestamp"
    
    echo "Creating backup in $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup existing dotfiles
    for file in "${config_files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$backup_dir/"
        fi
    done
    
    # Backup VS Code settings
    if [ -d "$HOME/Library/Application Support/Code/User" ]; then
        cp -R "$HOME/Library/Application Support/Code/User" "$backup_dir/vscode"
    fi

    # Backup existing Python setup
    if [ -f "/usr/local/bin/python3" ]; then
        echo "Python version before changes: $(/usr/local/bin/python3 --version)" >> "$backup_dir/python_info.txt"
    fi

    echo "Backup completed in $backup_dir"
}

# Utility functions
function prompt() {
    if [[ -z "${CI}" ]]; then
        read -p "Hit Enter to $1 ..."
    fi
}

function brew_install_or_upgrade() {
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

function install() {
    cmd=$1
    shift
    for pkg in "$@"; do
        exec="$cmd $pkg"
        echo "Executing: $exec"
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

# Keep sudo alive
function keep_sudo_alive() {
    sudo -v
    while true; do 
        sudo -n true
        sleep 300
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# Function to create necessary directories
function create_directories() {
    echo "Creating installation directories..."
    mkdir -p $GOPATH $GOPATH/src $GOPATH/pkg $GOPATH/bin
}

# Function to install Xcode Command Line Tools
function install_xcode_tools() {
    echo "------------------------------------"
    echo "Installing Xcode Command Line Tools."
    echo "------------------------------------"
    if ! [ -x "$(command -v gcc)" ]; then
        xcode-select --install
    else
        echo "Xcode command line tools already installed..."
    fi
}

# Function to install/update Homebrew
function setup_homebrew() {
    echo "Setting up Homebrew..."
    if test ! "$(command -v brew)"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    else
        brew update
        brew upgrade
        brew doctor
    fi
    
    # Add homebrew to path
    if ! grep -qF "/opt/homebrew/bin/brew" $HOME/.zprofile; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' | sudo tee -a $HOME/.zprofile
    fi
    
    # Set no auto-update
    export HOMEBREW_NO_AUTO_UPDATE=1
}

function setup_python() {
    echo "Setting up Python environment..."

    echo "Removing existing Python installations..."
    # Remove existing Python symlinks and installations
    sudo rm -rf /usr/local/bin/python*
    sudo rm -rf /usr/local/bin/pip*
    sudo rm -rf /usr/bin/python*
    sudo rm -rf /usr/bin/pip*
    sudo rm -rf /Library/Frameworks/Python.framework/Versions/*

    echo "Installing Python 3.12 via Homebrew..."
    brew install python@3.12

    echo "Installing Python package managers..."
    # Install pipx
    brew install pipx
    pipx ensurepath


    # Add Python paths to shell configuration if they don't exist
    echo "Configuring Python paths..."
    PYTHON_PATH_CONFIG="export PATH=\"/opt/homebrew/opt/python@3.12/bin:\$PATH\""
    PIPX_PATH_CONFIG="export PATH=\"\$HOME/.local/bin:\$PATH\""

    if ! grep -q "python@3.12/bin" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# Python configuration" >> "$HOME/.zshrc"
        echo "$PYTHON_PATH_CONFIG" >> "$HOME/.zshrc"
    fi

    if ! grep -q "/.local/bin" "$HOME/.zshrc"; then
        echo "# pipx path" >> "$HOME/.zshrc"
        echo "$PIPX_PATH_CONFIG" >> "$HOME/.zshrc"
    fi

    # Verify installations
    echo "Verifying Python installation..."
    python3 --version
    pip3 --version
    pipx --version
    pipenv --version

    echo "Python setup complete!"
}

function setup_node() {
    echo "Setting up Node.js environment..."

    # Install NVM
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Add NVM configuration to shell if not already present
    if ! grep -q "NVM_DIR" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# NVM configuration" >> "$HOME/.zshrc"
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.zshrc"
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$HOME/.zshrc"
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> "$HOME/.zshrc"
    fi

    # Source NVM for immediate use
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Install latest LTS version of Node.js
    echo "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts

    # Set default Node version
    nvm alias default 'lts/*'

    # Update npm to latest version
    echo "Updating npm..."
    npm install -g npm@latest

    # Install global npm packages
    echo "Installing global npm packages..."
    for package in "${node_packages[@]}"; do
        echo "Installing $package..."
        npm install -g "$package"
    done

    # Verify installations
    echo "Verifying Node.js setup..."
    echo "Node version: $(node --version)"
    echo "npm version: $(npm --version)"
    echo "TypeScript version: $(tsc --version)"
    echo "Next.js CLI version: $(create-next-app --version)"

    # Create a basic Next.js TypeScript template (optional)
    # echo "Creating Next.js + TypeScript template in ~/Development/templates..."
    # mkdir -p ~/Development/templates
    # cd ~/Development/templates
    # npx create-next-app@latest nextjs-ts-template --typescript --tailwind --eslint

    echo "Node.js environment setup complete!"
}

function install_zsh() {
    echo "Installing and configuring Zsh..."
    
    # Backup existing .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        echo "Backing up existing .zshrc..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Oh My Zsh is already installed"
    fi

    # Install Powerlevel10k theme
    if [ ! -d "$(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme" ]; then
        echo "Installing Powerlevel10k theme..."
        brew install romkatv/powerlevel10k/powerlevel10k
        echo "source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
    fi

    # Install Zsh plugins
    for plugin in "${zsh_plugins[@]}"; do
        if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]; then
            git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
        fi
    done
}

function setup_dotfiles() {
    echo "Setting up dotfiles..."
    
    # Get the directory where the script is being run from
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    DOTFILES_DIR="$HOME/code/dotfiles"
    
    # Define configuration files - find all dotfiles in script directory
    local config_files=($(find "$SCRIPT_DIR" -maxdepth 1 -type f -name ".*" -exec basename {} \;))
    echo "Found dotfiles: ${config_files[@]}"

    # First, copy files to home directory
    echo "Copying dotfiles to home directory..."
    for file in "${config_files[@]}"; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            # Backup existing file if it exists and is not a symlink
            if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
                echo "Backing up existing $file"
                mv "$HOME/$file" "$HOME/$file.backup"
            fi
            
            echo "Copying $file to home directory"
            cp "$SCRIPT_DIR/$file" "$HOME/"
            
            # Source the file if it's a shell config file
            case $file in
                .bash_profile|.bashrc|.zshrc|.aliases)
                    source "$HOME/$file" 2>/dev/null
                    ;;
            esac
        fi
    done

    # Create symlinks in ~/code/dotfiles
    echo "Creating symlinks in $DOTFILES_DIR..."
    mkdir -p "$DOTFILES_DIR"
    
    for file in "${config_files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            echo "Creating symlink for $file in $DOTFILES_DIR"
            ln -s -f "$HOME/$file" "$DOTFILES_DIR/$file"
        fi
    done

    # Handle VS Code settings
    echo "Setting up VS Code configuration..."
    
    # Define VS Code paths
    local vscode_user_dir="$HOME/Library/Application Support/Code/User"
    local dotfiles_vscode_dir="$DOTFILES_DIR/vscode"
    local vscode_files=(
        "settings.json"
        "keybindings.json"
    )

    # Create VS Code directories if they don't exist
    mkdir -p "$vscode_user_dir"
    mkdir -p "$dotfiles_vscode_dir"

    # Copy VS Code settings to user directory and create symlinks
    if [ -d "$SCRIPT_DIR/vscode" ]; then
        echo "Setting up VS Code configuration..."
        for file in "${vscode_files[@]}"; do
            if [ -f "$SCRIPT_DIR/vscode/$file" ]; then
                # Backup existing file if it exists and is not a symlink
                if [ -f "$vscode_user_dir/$file" ] && [ ! -L "$vscode_user_dir/$file" ]; then
                    echo "Backing up existing VS Code $file"
                    mv "$vscode_user_dir/$file" "$vscode_user_dir/$file.backup"
                fi
                
                # Copy to VS Code user directory
                cp "$SCRIPT_DIR/vscode/$file" "$vscode_user_dir/"
                
                # Create symlink in dotfiles directory
                ln -s -f "$vscode_user_dir/$file" "$dotfiles_vscode_dir/$file"
            fi
        done
    fi

    # Handle VS Code extensions
    if [ -f "$SCRIPT_DIR/vscode/extensions.txt" ]; then
        echo "Installing VS Code extensions..."
        while read -r extension; do
            if [[ ! -z "$extension" ]]; then  # Skip empty lines
                code --install-extension "$extension"
            fi
        done < "$SCRIPT_DIR/vscode/extensions.txt"
        
        # Copy extensions list to dotfiles
        cp "$SCRIPT_DIR/vscode/extensions.txt" "$dotfiles_vscode_dir/"
    else
        echo "Warning: extensions.txt not found"
    fi

    echo "Dotfiles setup complete!"
}

function configure_zsh() {
    echo "Configuring Zsh..."
    
    # Only create minimal initial configuration if .zshrc doesn't exist in dotfiles
    if [ ! -f "$HOME/.dotfiles/.zshrc" ]; then
        echo "Creating basic .zshrc in dotfiles..."
        cat << 'EOF' > "$HOME/.dotfiles/.zshrc"
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set plugins
plugins=(
    git
    docker
    kubectl
    terraform
    aws
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
)

source $ZSH/oh-my-zsh.sh

# Source Powerlevel10k
source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
    fi

    # Create Powerlevel10k configuration if it doesn't exist
    if [ ! -f "$HOME/.dotfiles/.p10k.zsh" ]; then
        echo "Creating default Powerlevel10k configuration..."
        curl -fsSL https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh > "$HOME/.dotfiles/.p10k.zsh"
    fi
}

# Function to install all packages
function install_packages() {
    echo "Installing packages..."
    
    # Install important software first
    brew tap homebrew/cask-versions
    install 'brew install --cask' "${important_casks[@]}"
    
    # Install brew packages
    install 'brew_install_or_upgrade' "${brews[@]}"
    
    # Install casks
    install 'brew install --cask' "${casks[@]}"
    
    # Install pip packages
    install 'pipx install' "${pipx[@]}"
    
    # Install fonts
    brew tap homebrew/cask-fonts
    install 'brew install --cask' "${fonts[@]}"
}

function setup_vscode() {
    echo "Setting up VS Code..."
    
    # Install VS Code if not already installed
    if ! command -v code >/dev/null; then
        brew install --cask visual-studio-code
    fi
    
    # Create VS Code user directory
    mkdir -p "$HOME/Library/Application Support/Code/User"
    
    # Copy settings and keybindings
    cp "$HOME/.dotfiles/vscode/settings.json" "$HOME/Library/Application Support/Code/User/"
    cp "$HOME/.dotfiles/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/"
    
    # Install extensions
    while read extension; do
        code --install-extension "$extension"
    done < "$HOME/.dotfiles/vscode/extensions.txt"
    
    echo "VS Code setup complete!"
}


# Main function to run the script
# Then replace the main function with:

function main() {
    # Check for dry run flag
    if [[ "$1" == "--dry-run" ]]; then
        DRY_RUN=true
        echo "Running in dry-run mode - no changes will be made"
    fi

    # Initial warning
    echo "This script will set up your macOS development environment."
    echo "It may modify existing configurations and install new software."
    
    if ! $DRY_RUN; then
        if ! confirm "Would you like to proceed? [y/N]"; then
            echo "Setup cancelled."
            exit 0
        fi

        if confirm "Would you like to backup existing configurations? [y/N]"; then
            backup_existing
        fi
    fi

    keep_sudo_alive

    # Core setup
    create_directories

    if confirm "Install Xcode Command Line Tools? [y/N]"; then
        install_xcode_tools
    fi

    # Dotfiles setup
    if confirm "Set up dotfiles? This will create symlinks to your dotfiles [y/N]"; then
        setup_dotfiles
    fi

    if confirm "Set up Homebrew? [y/N]"; then
        setup_homebrew
    fi


    # Shell setup
    if confirm "Install and configure Zsh with Oh My Zsh? [y/N]"; then
        install_zsh
        configure_zsh
    fi

    # Python setup
    if confirm "Set up Python? This will modify existing Python installations [y/N]"; then
        setup_python
    fi

    # Node.js setup
    if confirm "Set up Node.js and related tools? [y/N]"; then
        setup_node
    fi

    # VS Code setup
    if confirm "Set up VS Code and install extensions? [y/N]"; then
        setup_vscode
    fi

    if confirm "Set up packages ? [y/N]"; then
        install_packages
    fi

    # Shell change
    if [ "$SHELL" != "$(which zsh)" ]; then
        if confirm "Change default shell to Zsh? [y/N]"; then
            chsh -s "$(which zsh)"
        fi
    fi

    # Final cleanup
    if ! $DRY_RUN; then
        brew cleanup
    fi
    
    echo "Installation complete!"
    if ! $DRY_RUN; then
        echo "Please restart your terminal."
        echo "After restart, run 'p10k configure' to customize your prompt."
    else
        echo "Dry run completed. No changes were made."
    fi
}

# Modify the script execution to handle arguments
if [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [--dry-run]"
    echo "  --dry-run  Show what would be done without making changes"
    echo "  --help     Show this help message"
    exit 0
fi

# Run the script with any provided arguments
main "$@"