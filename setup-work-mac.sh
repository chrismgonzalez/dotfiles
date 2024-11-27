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
    
    DOTFILES_DIR="$HOME/code/dotfiles"
    
    # Define configuration files - find all dotfiles in your existing dotfiles directory
    local config_files=($(find "$DOTFILES_DIR" -maxdepth 1 -type f -name ".*" -exec basename {} \;))
    echo "Found dotfiles: ${config_files[@]}"

    # Create symlinks in home directory pointing to files in ~/code/dotfiles
    echo "Creating symlinks in home directory..."
    for file in "${config_files[@]}"; do
        if [ -f "$DOTFILES_DIR/$file" ]; then
            # Backup existing file if it exists and is not a symlink
            if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
                echo "Backing up existing $file"
                mv "$HOME/$file" "$HOME/$file.backup"
            fi
            
            echo "Creating symlink from $DOTFILES_DIR/$file to $HOME/$file"
            ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
            
            # Source the file if it's a shell config file
            case $file in
                .bash_profile|.bashrc|.zshrc|.aliases)
                    source "$HOME/$file" 2>/dev/null
                    ;;
            esac
        fi
    done

    # Handle VS Code settings
    if [ -d "$DOTFILES_DIR/vscode" ]; then
        echo "Setting up VS Code configuration..."
        
        local vscode_user_dir="$HOME/Library/Application Support/Code/User"
        local dotfiles_vscode_dir="$DOTFILES_DIR/vscode"
        local vscode_files=(
            "settings.json"
            "keybindings.json"
        )

        # Create VS Code user directory if it doesn't exist
        mkdir -p "$vscode_user_dir"

        # Create symlinks for VS Code files
        for file in "${vscode_files[@]}"; do
            if [ -f "$dotfiles_vscode_dir/$file" ]; then
                # Backup existing file if it exists and is not a symlink
                if [ -f "$vscode_user_dir/$file" ] && [ ! -L "$vscode_user_dir/$file" ]; then
                    echo "Backing up existing VS Code $file"
                    mv "$vscode_user_dir/$file" "$vscode_user_dir/$file.backup"
                fi
                
                echo "Creating symlink from $dotfiles_vscode_dir/$file to $vscode_user_dir/$file"
                ln -sf "$dotfiles_vscode_dir/$file" "$vscode_user_dir/$file"
            fi
        done
    fi

    echo "Dotfiles setup complete!"
}

function configure_zsh() {
    echo "Configuring Zsh..."
    
    # Only create minimal initial configuration if .zshrc doesn't exist in dotfiles
    if [ ! -f "$HOME/.zshrc" ]; then
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
    if [ ! -f "$HOME/.p10k.zsh" ]; then
        echo "Creating default Powerlevel10k configuration..."
        curl -fsSL https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh > "$HOME/.p10k.zsh"
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

function setup_completions() {
    echo "Setting up shell completions..."

    # Create completions directory if it doesn't exist
    mkdir -p ~/.zsh/completion
    
    # Array of completion setup commands
    local completion_cmds=(
        # AWS CLI
        "complete -C '/usr/local/bin/aws_completer' aws"
        
        # kubectl
        "source <(kubectl completion zsh)"
        
        # terraform
        "complete -o nospace -C $(which terraform) terraform"
        
        # docker
        "if [ -f /Applications/Docker.app/Contents/Resources/etc/docker.zsh-completion ]; then
            source /Applications/Docker.app/Contents/Resources/etc/docker.zsh-completion
        fi"
        "if [ -f /Applications/Docker.app/Contents/Resources/etc/docker-compose.zsh-completion ]; then
            source /Applications/Docker.app/Contents/Resources/etc/docker-compose.zsh-completion
        fi"
        
        # pip
        "eval \"$(pip completion --zsh)\""
        
        # npm
        "source <(npm completion)"
        
        # gh (GitHub CLI)
        "source <(gh completion -s zsh)"
        
        # poetry
        "source <(poetry completions zsh)"
        
        # pipenv
        "eval \"$(pipenv --completion)\""
        
        # brew
        "if type brew &>/dev/null; then
            FPATH=\"$(brew --prefix)/share/zsh/site-functions:${FPATH}\"
            autoload -Uz compinit
            compinit
        fi"
    )

    # Add completions to .zshrc if they don't already exist
    echo "Adding completions to .zshrc..."
    
    # First, add the completion setup section if it doesn't exist
    if ! grep -q "# Shell Completions" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# Shell Completions" >> "$HOME/.zshrc"
        echo "fpath=(~/.zsh/completion \$fpath)" >> "$HOME/.zshrc"
        echo "autoload -Uz compinit && compinit -i" >> "$HOME/.zshrc"
    fi

    # Add each completion command if it's not already present
    for cmd in "${completion_cmds[@]}"; do
        if ! grep -qF "$cmd" "$HOME/.zshrc"; then
            echo "$cmd" >> "$HOME/.zshrc"
        fi
    done

    # Install additional completion packages via Homebrew
    echo "Installing completion packages..."
    brew install \
        bash-completion@2 \
        zsh-completions \
        docker-completion \
        docker-compose-completion \
        pip-completion \
        terraform-completion

    # Download additional completions
    echo "Downloading additional completions..."

    # Git completions
    curl -o ~/.zsh/completion/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh 2>/dev/null

    # AWS CLI v2 completions
    if command -v aws >/dev/null; then
        aws --version | grep -q "aws-cli/2" && {
            curl -o ~/.zsh/completion/_aws https://raw.githubusercontent.com/aws/aws-cli/v2/contrib/completion/zsh/_aws 2>/dev/null
        }
    fi

    # Setup bash-completion for both bash and zsh
    echo "Setting up bash-completion..."
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        echo "[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion" >> "$HOME/.bashrc"
    fi

    # Add completion initialization to .zshrc if not present
    if ! grep -q "# Initialize completion system" "$HOME/.zshrc"; then
        cat << 'EOF' >> "$HOME/.zshrc"

# Initialize completion system
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
EOF
    fi

    # Source completions immediately
    source "$HOME/.zshrc"

    echo "Shell completions setup complete!"
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

    if confirm "Set up shell completions? [y/N]"; then
        setup_completions
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