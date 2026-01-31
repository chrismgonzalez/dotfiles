#!/bin/bash
# Package installation module

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Install or update Homebrew
install_homebrew() {
    log_info "Setting up Homebrew..."

    if command_exists brew; then
        log_info "Homebrew already installed, updating..."
        run_cmd "brew update"
        run_cmd "brew upgrade"
        log_success "Homebrew updated"
    else
        log_info "Installing Homebrew..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would install Homebrew"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

            # Add to PATH for Apple Silicon
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi
        log_success "Homebrew installed"
    fi

    export HOMEBREW_NO_AUTO_UPDATE=1
}

# Install or upgrade a brew package
brew_install_or_upgrade() {
    local package="$1"

    if brew ls --versions "$package" >/dev/null 2>&1; then
        if brew outdated | grep -q "^$package"; then
            log_info "Upgrading $package..."
            if run_cmd "brew upgrade $package"; then
                log_success "Upgraded $package"
            else
                log_error "Failed to upgrade $package"
                return 1
            fi
        else
            log_info "$package is already up to date"
        fi
    else
        log_info "Installing $package..."
        if run_cmd "brew install $package"; then
            log_success "Installed $package"
        else
            log_error "Failed to install $package"
            return 1
        fi
    fi
}

# Install brew packages
install_brews() {
    log_info "Installing brew packages..."

    local brew_count=$(yq eval '.packages.brews | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    if [[ "$brew_count" == "0" || "$brew_count" == "null" ]]; then
        log_warn "No brew packages defined in config"
        return 0
    fi

    for ((i = 0; i < brew_count; i++)); do
        local package=$(yq eval ".packages.brews[$i]" "$CONFIG_FILE")
        if [[ -n "$package" && "$package" != "null" ]]; then
            brew_install_or_upgrade "$package" || true
        fi
    done

    log_success "Brew packages installation complete"
}

# Install cask packages
install_casks() {
    log_info "Installing cask packages..."

    local cask_count=$(yq eval '.packages.casks | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    if [[ "$cask_count" == "0" || "$cask_count" == "null" ]]; then
        log_warn "No cask packages defined in config"
        return 0
    fi

    for ((i = 0; i < cask_count; i++)); do
        local package=$(yq eval ".packages.casks[$i]" "$CONFIG_FILE")
        if [[ -n "$package" && "$package" != "null" ]]; then
            if brew list --cask "$package" >/dev/null 2>&1; then
                log_info "$package is already installed"
            else
                log_info "Installing $package..."
                if run_cmd "brew install --cask $package"; then
                    log_success "Installed $package"
                else
                    log_error "Failed to install $package"
                fi
            fi
        fi
    done

    log_success "Cask packages installation complete"
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    log_info "Checking Xcode Command Line Tools..."

    if command_exists gcc; then
        log_info "Xcode Command Line Tools already installed"
        return 0
    fi

    log_info "Installing Xcode Command Line Tools..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Xcode Command Line Tools"
    else
        xcode-select --install
        log_success "Xcode Command Line Tools installation started"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_info "Setting up Oh My Zsh..."

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh already installed"
        return 0
    fi

    log_info "Installing Oh My Zsh..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Oh My Zsh"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed"
    fi

    # Install plugins
    local plugin_count=$(yq eval '.packages.zsh_plugins | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    if [[ "$plugin_count" == "0" || "$plugin_count" == "null" ]]; then
        log_warn "No zsh plugins defined in config"
        return 0
    fi

    for ((i = 0; i < plugin_count; i++)); do
        local plugin=$(yq eval ".packages.zsh_plugins[$i]" "$CONFIG_FILE")
        if [[ -n "$plugin" && "$plugin" != "null" ]]; then
            local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
            if [[ -d "$plugin_dir" ]]; then
                log_info "$plugin already installed"
            else
                log_info "Installing $plugin..."
                if [[ "$DRY_RUN" == "true" ]]; then
                    log_info "[DRY RUN] Would install $plugin"
                else
                    git clone "https://github.com/zsh-users/$plugin.git" "$plugin_dir"
                    log_success "Installed $plugin"
                fi
            fi
        fi
    done
}

# Setup Python via uv
setup_python() {
    log_info "Setting up Python..."

    local python_version=$(yq eval '.versions.python' "$CONFIG_FILE" 2>/dev/null || echo "3.12")

    if ! command_exists uv; then
        log_error "uv not found. Install it first with: brew install uv"
        return 1
    fi

    # Check if already installed
    if uv python list 2>/dev/null | grep -q "$python_version"; then
        log_info "Python $python_version already installed"
        if command_exists python3; then
            local version=$(python3 --version)
            log_info "Current Python: $version"
        fi
        return 0
    fi

    log_info "Installing Python $python_version via uv..."
    if run_cmd "uv python install $python_version"; then
        log_success "Python $python_version installed"
    else
        log_warn "Python installation may have failed or already exists"
    fi

    # Verify
    if command_exists python3; then
        local version=$(python3 --version)
        log_info "Python version: $version"
    fi
}

# Setup Node.js via nvm
setup_node() {
    log_info "Setting up Node.js..."

    local node_version=$(yq eval '.versions.node' "$CONFIG_FILE" 2>/dev/null || echo "lts/*")

    # Check if nvm is installed
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -d "$NVM_DIR" ]]; then
        log_info "Installing nvm..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would install nvm"
        else
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
            log_success "nvm installed"
        fi
    else
        log_info "nvm already installed"
    fi

    # Source nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command_exists nvm; then
        # Check if version already installed
        if nvm list 2>/dev/null | grep -q "$node_version"; then
            log_info "Node.js $node_version already installed"
            nvm use "$node_version" >/dev/null 2>&1
        else
            log_info "Installing Node.js $node_version..."
            if run_cmd "nvm install $node_version && nvm use $node_version && nvm alias default '$node_version'"; then
                log_success "Node.js $node_version installed"
            else
                log_error "Failed to install Node.js"
                return 1
            fi
        fi

        # Install global packages
        local npm_count=$(yq eval '.packages.npm_global | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
        if [[ "$npm_count" != "0" && "$npm_count" != "null" ]]; then
            for ((i = 0; i < npm_count; i++)); do
                local package=$(yq eval ".packages.npm_global[$i]" "$CONFIG_FILE")
                if [[ -n "$package" && "$package" != "null" ]]; then
                    local pkg_name="${package%%@*}" # Remove version suffix
                    if npm list -g "$pkg_name" >/dev/null 2>&1; then
                        log_info "$pkg_name already installed globally"
                    else
                        log_info "Installing $package..."
                        run_cmd "npm install -g $package" "true" || log_warn "Failed to install $package"
                    fi
                fi
            done
        fi
    else
        log_warn "nvm not available in current shell"
    fi
}

# Change default shell to Zsh
change_default_shell() {
    if [[ "$SHELL" == "$(which zsh)" ]]; then
        log_info "Default shell is already zsh"
        return 0
    fi

    log_info "Current shell: $SHELL"
    if confirm "Change default shell to Zsh? [y/N]"; then
        log_info "Changing default shell to zsh..."
        if run_cmd "chsh -s $(which zsh)"; then
            log_success "Default shell changed to zsh (restart terminal to apply)"
        else
            log_error "Failed to change default shell"
            return 1
        fi
    else
        log_info "Keeping current shell"
    fi
}

# Setup Rust via rustup
setup_rust() {
    log_info "Setting up Rust..."

    local rust_version=$(yq eval '.versions.rust' "$CONFIG_FILE" 2>/dev/null || echo "stable")

    # Check if rustup is installed
    if ! command_exists rustup; then
        log_info "Installing rustup..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would install rustup"
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$rust_version"
            source "$HOME/.cargo/env"
            log_success "rustup installed"
        fi
    else
        log_info "rustup already installed"
    fi

    if command_exists rustup; then
        # Check if version already installed
        if rustup toolchain list 2>/dev/null | grep -q "$rust_version"; then
            log_info "Rust $rust_version already installed"
            rustup default "$rust_version" >/dev/null 2>&1
        else
            log_info "Installing Rust $rust_version..."
            if run_cmd "rustup install $rust_version && rustup default $rust_version"; then
                log_success "Rust $rust_version installed"
            else
                log_error "Failed to install Rust"
                return 1
            fi
        fi

        # Verify
        if command_exists rustc; then
            local version=$(rustc --version)
            log_info "Rust version: $version"
        fi
    else
        log_warn "rustup not available"
    fi
}

# Setup Go
setup_go() {
    log_info "Setting up Go..."

    local go_version=$(yq eval '.versions.go' "$CONFIG_FILE" 2>/dev/null || echo "latest")

    if [[ "$go_version" == "latest" ]]; then
        # Install via Homebrew (always latest)
        if command_exists brew; then
            log_info "Installing Go via Homebrew..."
            brew_install_or_upgrade "go"
        fi
    else
        # Install specific version via script or asdf
        log_warn "Specific Go version installation not yet implemented. Using Homebrew (latest)."
        if command_exists brew; then
            brew_install_or_upgrade "go"
        fi
    fi

    # Verify
    if command_exists go; then
        local version=$(go version)
        log_info "Go version: $version"
    fi
}
