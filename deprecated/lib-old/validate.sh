#!/bin/bash
# Configuration validation module

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

validate_config() {
    local config_file="$1"

    log_info "Validating configuration file: $config_file"

    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    # Check if yq is installed
    if ! command_exists yq; then
        log_error "yq is required for config validation. Install with: brew install yq"
        return 1
    fi

    # Validate YAML syntax
    if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
        log_error "Invalid YAML syntax in $config_file"
        return 1
    fi

    # Validate required top-level keys
    local required_keys=("features" "packages" "symlinks" "directories" "environment")
    for key in "${required_keys[@]}"; do
        if ! yq eval "has(\"$key\")" "$config_file" | grep -q "true"; then
            log_error "Missing required key: $key"
            return 1
        fi
    done

    # Validate boolean feature flags
    local feature_flags=(
        "features.install_xcode"
        "features.install_homebrew"
        "features.install_zsh"
        "features.install_node"
        "features.install_python"
        "features.install_rust"
        "features.install_go"
        "features.setup_symlinks"
        "features.setup_local_bin"
    )

    for flag in "${feature_flags[@]}"; do
        local value=$(yq eval ".$flag" "$config_file")
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_error "Invalid boolean value for $flag: $value (must be true or false)"
            return 1
        fi
    done

    # Validate arrays exist
    local array_keys=(
        "packages.brews"
        "packages.casks"
        "packages.zsh_plugins"
        "packages.npm_global"
        "symlinks"
        "directories"
    )

    for key in "${array_keys[@]}"; do
        local type=$(yq eval ".$key | type" "$config_file")
        if [[ "$type" != "!!seq" ]]; then
            log_error "Invalid type for $key: expected array, got $type"
            return 1
        fi
    done

    # Validate environment variables
    local env_vars=(
        "environment.dotfiles_dir"
        "environment.xdg_config_home"
        "environment.go_path"
        "environment.python_version"
        "environment.zettelkasten"
    )

    for var in "${env_vars[@]}"; do
        local value=$(yq eval ".$var" "$config_file")
        if [[ -z "$value" || "$value" == "null" ]]; then
            log_error "Missing or empty value for $var"
            return 1
        fi
    done

    log_success "Configuration validation passed"
    return 0
}

# Load config value helper
get_config_value() {
    local key="$1"
    local config_file="${2:-$CONFIG_FILE}"
    yq eval ".$key" "$config_file"
}

# Check if feature is enabled
is_feature_enabled() {
    local feature="$1"
    local value=$(get_config_value "features.$feature")
    [[ "$value" == "true" ]]
}
