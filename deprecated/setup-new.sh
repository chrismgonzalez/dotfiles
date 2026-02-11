#!/bin/bash
# Dotfiles Setup Script - Refactored and Maintainable
# Usage: ./setup.sh [--init|--update] [--dry-run] [--verbose] [--validate] [--restore TIMESTAMP]

set -euo pipefail  # Add -u for undefined vars, -o pipefail for pipe failures

# Error handler
trap 'error_handler $? $LINENO' ERR

error_handler() {
  local exit_code=$1
  local line_number=$2
  log_error "Script failed at line $line_number with exit code $exit_code"
  print_summary
  exit $exit_code
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONFIG_FILE="$SCRIPT_DIR/config.yaml"
export LOG_FILE=""

# Initialize global variables (before sourcing modules)
export DRY_RUN=false
export VERBOSE=false

# Source modules
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/validate.sh"
source "$SCRIPT_DIR/lib/backup.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/symlinks.sh"

# Parse command line arguments
MODE=""
RESTORE_TIMESTAMP=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --init)
        MODE="init"
        shift
        ;;
      --update)
        MODE="update"
        shift
        ;;
      --validate)
        MODE="validate"
        shift
        ;;
      --restore)
        MODE="restore"
        RESTORE_TIMESTAMP="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --help)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
  
  # Default to init if no mode specified
  if [[ -z "$MODE" ]]; then
    MODE="init"
  fi
}

show_help() {
  cat <<EOF
Dotfiles Setup Script

Usage: $0 [OPTIONS]

Modes:
  --init              Initial setup (default) - installs everything
  --update            Update mode - only updates packages
  --validate          Validate configuration file only
  --restore TIMESTAMP Restore from backup

Options:
  --dry-run          Show what would be done without making changes
  --verbose          Enable verbose logging
  --help             Show this help message

Examples:
  $0 --init                    # Fresh machine setup
  $0 --update                  # Update packages only
  $0 --init --dry-run          # Preview what would happen
  $0 --validate                # Check config file
  $0 --restore 20260115_210000 # Restore from backup

Configuration:
  Edit config.yaml to customize your setup
EOF
}

# Pre-flight checks
preflight_checks() {
  log_info "Running pre-flight checks..."
  
  # Check OS
  if ! is_macos; then
    log_error "This script is designed for macOS"
    exit 1
  fi
  
  # Check config file
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    exit 1
  fi
  
  # Check for Homebrew (required for init and update modes)
  if [[ "$MODE" == "init" || "$MODE" == "update" ]]; then
    if ! command_exists brew; then
      log_error "Homebrew is required but not installed"
      echo ""
      echo "Install Homebrew with:"
      echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
      echo ""
      exit 1
    fi
    log_info "Homebrew found"
  fi
  
  # Check for yq (required for config validation)
  if ! command_exists yq; then
    if command_exists brew && [[ "$DRY_RUN" != "true" ]]; then
      log_info "yq not found, installing via Homebrew..."
      brew install yq
      log_success "yq installed"
    elif [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY RUN] Would install yq via Homebrew"
    else
      log_error "yq is required for config validation but not installed"
      echo "Install with: brew install yq"
      exit 1
    fi
  else
    log_info "yq found"
  fi
  
  # Validate config
  if ! validate_config "$CONFIG_FILE"; then
    log_error "Configuration validation failed"
    exit 1
  fi
  
  log_success "Pre-flight checks passed"
}

# Init mode - full setup
run_init() {
  log_info "Starting initial setup..."
  
  # Initialize backup
  init_backup
  
  # Setup log file
  if [[ "$VERBOSE" == "true" && -n "$BACKUP_DIR" ]]; then
    LOG_FILE="$BACKUP_DIR/setup.log"
    log_info "Logging to: $LOG_FILE"
  fi
  
  # Keep sudo alive
  keep_sudo_alive
  
  # Create directories
  create_directories
  
  # Install Xcode tools
  if is_feature_enabled "install_xcode"; then
    install_xcode_tools
  fi
  
  # Setup Homebrew
  if is_feature_enabled "install_homebrew"; then
    install_homebrew
    install_brews
    install_casks  # Fonts are now installed as casks
  fi
  
  # Setup Zsh
  if is_feature_enabled "install_zsh"; then
    install_oh_my_zsh
  fi
  
  # Setup symlinks
  if is_feature_enabled "setup_symlinks"; then
    create_symlinks
    verify_symlinks
  fi
  
  # Setup local bin
  if is_feature_enabled "setup_local_bin"; then
    setup_local_bin
  fi
  
  # Setup Python
  if is_feature_enabled "install_python"; then
    setup_python
  fi
  
  # Setup Node
  if is_feature_enabled "install_node"; then
    setup_node
  fi
  
  # Setup Rust
  if is_feature_enabled "install_rust"; then
    setup_rust
  fi
  
  # Setup Go
  if is_feature_enabled "install_go"; then
    setup_go
  fi
  
  # Change default shell
  change_default_shell
  
  # Cleanup
  if [[ "$DRY_RUN" != "true" ]] && command_exists brew; then
    log_info "Cleaning up Homebrew..."
    brew cleanup
  fi
  
  log_success "Initial setup complete!"
  
  if [[ "$DRY_RUN" != "true" ]]; then
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal"
    echo "  2. Review backup at: $BACKUP_DIR"
    echo "  3. Verify your shell: echo \$SHELL"
  fi
}

# Update mode - packages only
run_update() {
  log_info "Starting update mode..."
  
  # Initialize backup
  init_backup
  
  # Setup log file
  if [[ "$VERBOSE" == "true" && -n "$BACKUP_DIR" ]]; then
    LOG_FILE="$BACKUP_DIR/update.log"
    log_info "Logging to: $LOG_FILE"
  fi
  
  # Update Homebrew packages
  if is_feature_enabled "install_homebrew"; then
    if command_exists brew; then
      log_info "Updating Homebrew..."
      run_cmd "brew update"
      run_cmd "brew upgrade"
      run_cmd "brew cleanup"
      log_success "Homebrew updated"
    else
      log_warn "Homebrew not installed, skipping"
    fi
  fi
  
  # Update Python
  if is_feature_enabled "install_python"; then
    setup_python
  fi
  
  # Update Node packages
  if is_feature_enabled "install_node"; then
    if command_exists npm; then
      log_info "Updating npm packages..."
      run_cmd "npm update -g"
      log_success "npm packages updated"
    else
      log_warn "npm not installed, skipping"
    fi
  fi
  
  log_success "Update complete!"
}

# Main function
main() {
  parse_args "$@"
  
  # Handle different modes
  case $MODE in
    validate)
      log_info "Validating configuration..."
      if validate_config "$CONFIG_FILE"; then
        log_success "Configuration is valid"
        exit 0
      else
        log_error "Configuration validation failed"
        exit 1
      fi
      ;;
    restore)
      if [[ -z "$RESTORE_TIMESTAMP" ]]; then
        log_error "Restore timestamp required"
        list_backups
        exit 1
      fi
      restore_backup "$RESTORE_TIMESTAMP"
      exit $?
      ;;
    init)
      preflight_checks
      run_init
      ;;
    update)
      preflight_checks
      run_update
      ;;
    *)
      log_error "Unknown mode: $MODE"
      exit 1
      ;;
  esac
  
  # Print summary
  print_summary
  exit_code=$?
  
  exit $exit_code
}

# Run main
main "$@"
