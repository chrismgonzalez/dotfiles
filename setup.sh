#!/bin/bash

# Global variables
DOTFILES_DIR="$HOME/code/dotfiles"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=false
GO_PATH="$HOME/go"
PYTHON_VERSION="3.11"

create_directories() {
  local directories=("$@")
  for dir in "${directories[@]}"; do
    mkdir -p "$dir"
  done
}

create_symlinks() {
  local items=("$@")
  for item in "${items[@]}"; do
    IFS=':' read -r source target <<<"$item"
    if [ -L "$target" ]; then
      echo "Removing existing symlink $target"
      unlink "$target"
    elif [ -d "$target" ]; then
      echo "Warning: $target is a directory. Skipping..."
      continue
    elif [ -e "$target" ]; then
      echo "Warning: $target already exists. Skipping..."
      continue
    fi
    ln -s "$DOTFILES_DIR/$source" "$target"
    echo "Created symlink for $source"
  done
}

common_directories=(
  "$XDG_CONFIG_HOME/k9s"
  "$XDG_CONFIG_HOME/kitty"
  "$XDG_CONFIG_HOME/zk"
  "$XDG_CONFIG_HOME/zk/templates"
  "$GO_PATH"
  "$GO_PATH/src"
  "$GO_PATH/pkg"
  "$GO_PATH/bin"
)

common_items=(
  "starship.toml:$XDG_CONFIG_HOME/starship.toml"
  "k9s/skin.yml:$XDG_CONFIG_HOME/k9s/skin.yml"
  ".inputrc:$HOME/.inputrc"
  ".tmux.conf:$HOME/.tmux.conf"
  "nvim:$XDG_CONFIG_HOME/nvim"
  ".zprofile:$HOME/.zprofile"
  ".zshrc:$HOME/.zshrc"
  "kitty.conf:$XDG_CONFIG_HOME/kitty/kitty.conf"
  "zk/config.toml:$XDG_CONFIG_HOME/zk/config.toml"
  "zk/templates/:$XDG_CONFIG_HOME/zk/templates/"
)

brews=(
  wget
  gnupg
  awscli
  cfn-lint
  derailed/k9s/k9s
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
  go
  git-extras
  git-lfs
  gnu-sed
  gnupg
  kubectl
  pinentry-mac
  bash-completion@2
  ssh-copy-id
  uv
  lazygit
  fzf
  fd
  eza
  hugo
  newsboat
  starship
  gh
  poetry
  zk
)

casks=(
  kitty
  docker
  rectangle
)

node_packages=(
  typescript
  ts-node
  create-next-app
  npm@latest
  aws-cdk
)

fonts=(
  font-fira-code
  font-jetbrains-mono
  font-victor-mono
  font-victor-mono-nerd-font
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
  [yY][eE][sS] | [yY])
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

  # Backup existing Python setup
  if [ -f "/usr/local/bin/python3" ]; then
    echo "Python version before changes: $(/usr/local/bin/python3 --version)" >>"$backup_dir/python_info.txt"
  fi

  echo "Backup completed in $backup_dir"
}

# Utility functions
function prompt() {
  if [[ -z "${CI}" ]]; then
    read -r -p "Hit Enter to $1 ..."
  fi
}

function brew_install_or_upgrade() {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" >/dev/null); then
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
    if ${exec}; then
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
  sudo rm -rf $HOME/.local/bin/python*
  sudo rm -rf /usr/local/bin/pip*
  sudo rm -rf /usr/bin/python*
  sudo rm -rf /usr/bin/pip*
  sudo rm -rf /Library/Frameworks/Python.framework/Versions/*

  echo "Installing Python 3.12 via uv"
  uv install python@3.12

  # Add Python paths to shell configuration if they don't exist
  echo "Configuring Python paths..."
  PYTHON_PATH_CONFIG="export PATH=\"/opt/homebrew/opt/python@3.12/bin:\$PATH\""
  PIPX_UV_CONFIG_PATH_CONFIG="export PATH=\"\$HOME/.local/bin:\$PATH\""

  if ! grep -q "python@3.12/bin" "$HOME/.zshrc"; then
    echo "" >>"$HOME/.zshrc"
    echo "# Python configuration" >>"$HOME/.zshrc"
    echo "$PYTHON_PATH_CONFIG" >>"$HOME/.zshrc"
  fi

  if ! grep -q "/.local/bin" "$HOME/.zshrc"; then
    echo "# pipx path" >>"$HOME/.zshrc"
    echo "$PIPX_UV_CONFIG_PATH_CONFIG" >>"$HOME/.zshrc"
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
  # Only backup if it's not a symlink
  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
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

  # Install Zsh plugins
  for plugin in "${zsh_plugins[@]}"; do
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]; then
      git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
    fi
  done
}

# Function to install all packages
function install_packages() {
  echo "Installing packages..."

  # Install important software first
  brew tap homebrew/cask-versions

  # Install brew packages
  install 'brew_install_or_upgrade' "${brews[@]}"

  # Install casks
  install 'brew install --cask' "${casks[@]}"

  # Install fonts
  brew tap homebrew/cask-fonts
  install 'brew install --cask' "${fonts[@]}"
}

function setup_completions() {
  echo "Setting up shell completions..."

  # Create completions directory if it doesn't exist
  mkdir -p ~/.zsh/completion
  # Get the actual .zshrc file (follow symlink if it exists)
  ZSHRC_PATH="$HOME/.zshrc"
  if [ -L "$ZSHRC_PATH" ]; then
    ZSHRC_PATH="$(readlink -f "$ZSHRC_PATH")"
  fi

  # Array of completion setup commands
  local completion_cmds=(
    # AWS CLI
    "complete -C 'opt/homebrew/bin/aws_completer' aws"

    # kubectl
    "source <(kubectl completion zsh)"

    # uv
    'eval "$(uv generate-shell-completion zsh)"'

    # poetry
    "source <(poetry completions zsh)"

  )

  # Create a temporary file for new completions
  TEMP_FILE=$(mktemp)

  # Add completion setup section if it doesn't exist
  if ! grep -q "# Shell Completions" "$HOME/.zshrc"; then
    echo "" >>"$TEMP_FILE"
    echo "# Shell Completions" >>"$TEMP_FILE"
    echo "fpath=(~/.zsh/completion \$fpath)" >>"$TEMP_FILE"
    echo "autoload -Uz compinit && compinit -i" >>"$TEMP_FILE"
  fi

  # Add each completion command if it's not already in .zshrc
  for cmd in "${completion_cmds[@]}"; do
    if ! grep -qF "$cmd" "$HOME/.zshrc"; then
      echo "$cmd" >>"$TEMP_FILE"
    fi
  done

  # Add completion initialization if not already present
  if ! grep -q "# Initialize completion system" "$HOME/.zshrc"; then
    echo "" >>"$TEMP_FILE"
    echo "# Initialize completion system" >>"$TEMP_FILE"
    echo "autoload -Uz compinit && compinit" >>"$TEMP_FILE"
    echo "zstyle ':completion:*' menu select" >>"$TEMP_FILE"
    echo "zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'" >>"$TEMP_FILE"
    echo "zstyle ':completion:*' list-colors \"\${(s.:.)LS_COLORS}\"" >>"$TEMP_FILE"
    echo "zstyle ':completion:*' verbose yes" >>"$TEMP_FILE"
    echo "zstyle ':completion:*' group-name ''" >>"$TEMP_FILE"
    echo "zstyle ':completion:*:descriptions' format '%B%d%b'" >>"$TEMP_FILE"
    echo "zstyle ':completion:*:messages' format '%d'" >>"$TEMP_FILE"
    echo "zstyle ':completion:*:warnings' format 'No matches for: %d'" >>"$TEMP_FILE"
    echo "zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'" >>"$TEMP_FILE"
  fi

  # When appending, use the actual file path
  if [ -s "$TEMP_FILE" ]; then
    echo "Adding new completions to .zshrc..."
    cat "$TEMP_FILE" >>"$ZSHRC_PATH"
  else
    echo "No new completions to add."
  fi

  # Clean up temp file
  rm "$TEMP_FILE"

  # Install additional completion packages via Homebrew
  echo "Installing completion packages..."
  brew install \
    zsh-completions

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
  if [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    if ! grep -q "bash_completion" "$HOME/.bashrc"; then
      echo "[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion" >>"$HOME/.bashrc"
    fi
  fi

  echo "Shell completions setup complete!"
  echo "Please restart your shell or run 'source ~/.zshrc' to apply changes."
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
  if [[ "$OSTYPE" == darwin* ]]; then
    create_directories "${common_directories[@]}"
  fi

  if confirm "Install Xcode Command Line Tools? [y/N]"; then
    install_xcode_tools
  fi

  # Dotfiles setup
  if confirm "Set up dotfiles? This will create symlinks to your dotfiles [y/N]"; then
    if [[ "$OSTYPE" == darwin* ]]; then
      create_symlinks "${common_items[@]}"
    fi
  fi

  if confirm "Set up Homebrew? [y/N]"; then
    setup_homebrew
  fi

  # Shell setup
  if confirm "Install and configure Zsh [y/N]"; then
    install_zsh
  fi

  # Node.js setup
  if confirm "Set up Node.js and related tools? [y/N]"; then
    setup_node
  fi

  if confirm "Set up packages ? [y/N]"; then
    install_packages
  fi

  # if confirm "Set up shell completions? [y/N]"; then
  #     setup_completions
  # fi

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
