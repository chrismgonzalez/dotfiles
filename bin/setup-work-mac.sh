#!/bin/bash

# Mac Development Environment Setup Script
# Requirements: MacOS

# Global variables
GO_VERSION="1.23"
NODE_VERSION="16"

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

vscode=(
    amazonwebservices.aws-toolkit-vscode
    ameenahsanma.poetry-monorepo
    antfu.browse-lite
    azemoh.one-monokai
    batisteo.vscode-django
    bierner.markdown-preview-github-styles
    boto3typed.boto3-ide
    continue.continue
    cstrap.flask-snippets
    davidanson.vscode-markdownlint
    dbaeumer.vscode-eslint
    donjayamanne.python-environment-manager
    donjayamanne.python-extension-pack
    dsznajder.es7-react-js-snippets
    eamodio.gitlens
    edison1105.vite-theme-night
    esbenp.prettier-vscode
    formulahendry.auto-close-tag
    github.copilot
    github.copilot-chat
    github.vscode-github-actions
    github.vscode-pull-request-github
    golang.go
    hashicorp.terraform
    hbenl.vscode-test-explorer
    kevinrose.vsc-python-indent
    littlefoxteam.vscode-python-test-adapter
    me-dutour-mathieu.vscode-github-actions
    meezilla.json
    mightbesimon.emoji-icons
    ms-azuretools.vscode-docker
    ms-kubernetes-tools.vscode-kubernetes-tools
    ms-python.autopep8
    ms-python.black-formatter
    ms-python.debugpy
    ms-python.isort
    ms-python.python
    ms-python.vscode-pylance
    ms-toolsai.jupyter
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode-remote.remote-wsl
    ms-vscode-remote.vscode-remote-extensionpack
    ms-vscode.makefile-tools
    ms-vscode.remote-explorer
    ms-vscode.remote-server
    ms-vscode.test-adapter-converter
    njpwerner.autodocstring
    pkief.material-icon-theme
    premparihar.gotestexplorer
    redhat.vscode-yaml
    roscop.activefileinstatusbar
    sameeramin.cdk-snippets-for-python
    taniarascia.new-moon-vscode
    tomoki1207.pdf
    visualstudioexptteam.intellicode-api-usage-examples
    visualstudioexptteam.vscodeintellicode
    vscodevim.vim
    wesbos.theme-cobalt2
    wholroyd.jinja
    zainchen.json
)

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
        sleep 60
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
    
    # Define configuration files
    local config_files=(
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

    # Create dotfiles directory if it doesn't exist
    mkdir -p ~/.dotfiles

    # Create symlinks
    for file in "${config_files[@]}"; do
        # Check if original file exists in home directory
        if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
            echo "Backing up existing $file"
            mv "$HOME/$file" "$HOME/$file.backup"
        fi

        # Create symlink if dotfile exists
        if [ -f "$HOME/.dotfiles/$file" ]; then
            echo "Creating symlink for $file"
            ln -s -f "$HOME/.dotfiles/$file" "$HOME/$file"
            # Source the file if it's a shell config file
            case $file in
                .bash_profile|.bashrc|.zshrc|.aliases)
                    source "$HOME/$file" 2>/dev/null
                    ;;
            esac
        else
            echo "Warning: $file not found in dotfiles directory"
        fi
    done
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
    
    # Install VS Code extensions
    install 'code --install-extension' "${vscode[@]}"
    
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
function main() {
    keep_sudo_alive
    create_directories
    install_xcode_tools
    setup_homebrew
    setup_dotfiles
    install_zsh
    configure_zsh
    setup_python
    setup_node
    install_packages
    setup_vscode
    
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing shell to Zsh..."
        chsh -s "$(which zsh)"
    fi
    # Final cleanup
    brew cleanup
    
    echo "Installation complete! Please restart your terminal."
    echo "After restart, run 'p10k configure' to customize your prompt."

}

# Run the script
main