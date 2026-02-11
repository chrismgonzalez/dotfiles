#!/bin/bash
# Symlink and directory creation module

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/backup.sh"

# Get environment variables from config
get_env_var() {
  local var_name="$1"
  local default_value="$2"
  
  if [[ -n "$CONFIG_FILE" ]]; then
    local value=$(yq eval ".environment.$var_name" "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$value" && "$value" != "null" ]]; then
      eval echo "$value"
      return
    fi
  fi
  
  eval echo "$default_value"
}

# Create directories
create_directories() {
  log_info "Creating directories..."
  
  local dir_count=$(yq eval '.directories | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
  if [[ "$dir_count" == "0" || "$dir_count" == "null" ]]; then
    log_warn "No directories defined in config"
    return 0
  fi
  
  for ((i=0; i<dir_count; i++)); do
    local dir=$(yq eval ".directories[$i]" "$CONFIG_FILE")
    if [[ -n "$dir" && "$dir" != "null" ]]; then
      dir=$(eval echo "$dir")  # Expand variables
      
      if [[ -d "$dir" ]]; then
        log_info "Directory already exists: $dir"
      else
        if run_cmd "mkdir -p '$dir'"; then
          log_success "Created directory: $dir"
        else
          log_error "Failed to create directory: $dir"
        fi
      fi
    fi
  done
  
  log_success "Directory creation complete"
}

# Create symlinks
create_symlinks() {
  log_info "Creating symlinks..."
  
  local dotfiles_dir=$(get_env_var "dotfiles_dir" "$HOME/code/dotfiles")
  local symlink_count=$(yq eval '.symlinks | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
  
  if [[ "$symlink_count" == "0" || "$symlink_count" == "null" ]]; then
    log_warn "No symlinks defined in config"
    return 0
  fi
  
  for ((i=0; i<symlink_count; i++)); do
    local mapping=$(yq eval ".symlinks[$i]" "$CONFIG_FILE")
    if [[ -z "$mapping" || "$mapping" == "null" ]]; then
      continue
    fi
    
    local source="${mapping%%:*}"
    local target="${mapping#*:}"
    target=$(eval echo "$target")  # Expand variables
    local source_path="$dotfiles_dir/$source"
    
    # Check if source exists
    if [[ ! -e "$source_path" ]]; then
      log_warn "Source does not exist: $source_path"
      continue
    fi
    
    # Handle existing target
    if [[ -L "$target" ]]; then
      local current_link=$(readlink "$target")
      if [[ "$current_link" == "$source_path" ]]; then
        log_info "Symlink already correct: $target"
        continue
      else
        log_info "Removing incorrect symlink: $target"
        run_cmd "unlink '$target'"
      fi
    elif [[ -d "$target" ]]; then
      log_warn "Target is a directory, skipping: $target"
      continue
    elif [[ -f "$target" ]]; then
      backup_file "$target"
      run_cmd "rm '$target'"
    fi
    
    # Create symlink
    if run_cmd "ln -s '$source_path' '$target'"; then
      log_success "Created symlink: $target -> $source_path"
    else
      log_error "Failed to create symlink: $target"
    fi
  done
  
  log_success "Symlink creation complete"
}

# Setup local bin files
setup_local_bin() {
  log_info "Setting up ~/.local/bin files..."
  
  local dotfiles_dir=$(get_env_var "dotfiles_dir" "$HOME/code/dotfiles")
  local bin_dir="$dotfiles_dir/bin"
  local local_bin="$HOME/.local/bin"
  
  run_cmd "mkdir -p '$local_bin'"
  
  if [[ ! -d "$bin_dir" ]]; then
    log_warn "Bin directory not found: $bin_dir"
    return 0
  fi
  
  for file in "$bin_dir"/*; do
    if [[ -f "$file" ]]; then
      local basename=$(basename "$file")
      local target="$local_bin/$basename"
      
      if [[ -L "$target" ]]; then
        local current_link=$(readlink "$target")
        if [[ "$current_link" == "$file" ]]; then
          log_info "Link already correct: $basename"
          continue
        else
          run_cmd "unlink '$target'"
        fi
      elif [[ -f "$target" ]]; then
        backup_file "$target" "$basename"
        run_cmd "rm '$target'"
      fi
      
      if run_cmd "ln -sf '$file' '$target'"; then
        log_success "Linked $basename to ~/.local/bin/"
      else
        log_error "Failed to link $basename"
      fi
    fi
  done
  
  log_success "Local bin setup complete"
}

# Verify symlinks
verify_symlinks() {
  log_info "Verifying symlinks..."
  
  local dotfiles_dir=$(get_env_var "dotfiles_dir" "$HOME/code/dotfiles")
  local errors=0
  local symlink_count=$(yq eval '.symlinks | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
  
  if [[ "$symlink_count" == "0" || "$symlink_count" == "null" ]]; then
    log_warn "No symlinks to verify"
    return 0
  fi
  
  for ((i=0; i<symlink_count; i++)); do
    local mapping=$(yq eval ".symlinks[$i]" "$CONFIG_FILE")
    if [[ -z "$mapping" || "$mapping" == "null" ]]; then
      continue
    fi
    
    local source="${mapping%%:*}"
    local target="${mapping#*:}"
    target=$(eval echo "$target")
    local source_path="$dotfiles_dir/$source"
    
    if [[ ! -L "$target" ]]; then
      log_warn "Not a symlink: $target"
      ((errors++))
      continue
    fi
    
    local current_link=$(readlink "$target")
    if [[ "$current_link" != "$source_path" ]]; then
      log_warn "Incorrect symlink: $target -> $current_link (expected: $source_path)"
      ((errors++))
    fi
  done
  
  if [[ $errors -eq 0 ]]; then
    log_success "All symlinks verified"
  else
    log_warn "Found $errors symlink issues"
  fi
}
