#!/bin/bash
# Backup and restore module

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

BACKUP_DIR=""
MANIFEST_FILE=""

# Initialize backup directory
init_backup() {
  local timestamp=$(date +%Y%m%d_%H%M%S)
  BACKUP_DIR="$HOME/.dotfiles_backup_$timestamp"
  MANIFEST_FILE="$BACKUP_DIR/manifest.json"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would create backup directory: $BACKUP_DIR"
    return 0
  fi
  
  mkdir -p "$BACKUP_DIR"
  
  # Initialize manifest
  cat > "$MANIFEST_FILE" <<EOF
{
  "timestamp": "$timestamp",
  "date": "$(date)",
  "files": []
}
EOF
  
  log_success "Backup directory created: $BACKUP_DIR"
  export BACKUP_DIR
  export MANIFEST_FILE
}

# Backup a single file
backup_file() {
  local file_path="$1"
  local backup_name="${2:-$(basename "$file_path")}"
  
  # Skip if file doesn't exist
  if [[ ! -e "$file_path" ]]; then
    return 0
  fi
  
  # Skip if it's already a symlink
  if [[ -L "$file_path" ]]; then
    log_info "Skipping backup of symlink: $file_path"
    return 0
  fi
  
  # Skip if it's a directory
  if [[ -d "$file_path" ]]; then
    log_warn "Skipping backup of directory: $file_path"
    return 0
  fi
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would backup: $file_path -> $BACKUP_DIR/$backup_name"
    return 0
  fi
  
  # Copy file to backup directory
  cp "$file_path" "$BACKUP_DIR/$backup_name"
  
  # Update manifest
  local temp_manifest=$(mktemp)
  jq --arg path "$file_path" --arg backup "$backup_name" \
    '.files += [{"original": $path, "backup": $backup, "backed_up_at": now | todate}]' \
    "$MANIFEST_FILE" > "$temp_manifest"
  mv "$temp_manifest" "$MANIFEST_FILE"
  
  log_success "Backed up: $file_path"
}

# List available backups
list_backups() {
  local backup_dirs=("$HOME"/.dotfiles_backup_*)
  
  if [[ ${#backup_dirs[@]} -eq 0 || ! -d "${backup_dirs[0]}" ]]; then
    echo "No backups found"
    return 0
  fi
  
  echo "Available backups:"
  for dir in "${backup_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      local timestamp=$(basename "$dir" | sed 's/\.dotfiles_backup_//')
      local manifest="$dir/manifest.json"
      if [[ -f "$manifest" ]]; then
        local date=$(jq -r '.date' "$manifest")
        local file_count=$(jq '.files | length' "$manifest")
        echo "  $timestamp - $date ($file_count files)"
      else
        echo "  $timestamp - (no manifest)"
      fi
    fi
  done
}

# Restore from backup
restore_backup() {
  local timestamp="$1"
  local backup_dir="$HOME/.dotfiles_backup_$timestamp"
  local manifest="$backup_dir/manifest.json"
  
  if [[ ! -d "$backup_dir" ]]; then
    log_error "Backup not found: $backup_dir"
    return 1
  fi
  
  if [[ ! -f "$manifest" ]]; then
    log_error "Manifest not found: $manifest"
    return 1
  fi
  
  log_info "Restoring from backup: $timestamp"
  
  # Read files from manifest and restore
  local file_count=$(jq '.files | length' "$manifest")
  for ((i=0; i<file_count; i++)); do
    local original=$(jq -r ".files[$i].original" "$manifest")
    local backup=$(jq -r ".files[$i].backup" "$manifest")
    local backup_file="$backup_dir/$backup"
    
    if [[ ! -f "$backup_file" ]]; then
      log_warn "Backup file not found: $backup_file"
      continue
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[DRY RUN] Would restore: $backup_file -> $original"
      continue
    fi
    
    # Remove existing file/symlink
    if [[ -L "$original" ]]; then
      unlink "$original"
    elif [[ -f "$original" ]]; then
      rm "$original"
    fi
    
    # Restore file
    cp "$backup_file" "$original"
    log_success "Restored: $original"
  done
  
  log_success "Restore complete"
}
