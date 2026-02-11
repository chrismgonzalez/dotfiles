#!/bin/bash
# Utility functions for setup script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global state
DRY_RUN=false
VERBOSE=false
ERRORS=()
WARNINGS=()
SUCCESSES=()
CURRENT_STEP=0
TOTAL_STEPS=0

# Progress indicator
show_progress() {
  if [[ $TOTAL_STEPS -gt 0 ]]; then
    echo -e "${BLUE}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} $1"
  else
    echo -e "${BLUE}[INFO]${NC} $1"
  fi
  [[ "$VERBOSE" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] PROGRESS: $1" >> "$LOG_FILE" || true
}

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
  [[ "$VERBOSE" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE" || true
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
  SUCCESSES+=("$1")
  [[ "$VERBOSE" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE" || true
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
  WARNINGS+=("$1")
  [[ "$VERBOSE" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $1" >> "$LOG_FILE" || true
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  ERRORS+=("$1")
  [[ "$VERBOSE" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE" || true
}

# Dry run wrapper
run_cmd() {
  local cmd="$1"
  local allow_failure="${2:-false}"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would execute: $cmd"
    return 0
  else
    if eval "$cmd"; then
      return 0
    else
      local exit_code=$?
      if [[ "$allow_failure" == "true" ]]; then
        log_warn "Command failed (non-fatal): $cmd"
        return 0
      else
        return $exit_code
      fi
    fi
  fi
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if running on macOS
is_macos() {
  [[ "$OSTYPE" == darwin* ]]
}

# Keep sudo alive
keep_sudo_alive() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would keep sudo alive"
    return 0
  fi
  
  sudo -v
  
  # Keep alive for max 2 hours (safety limit)
  local max_iterations=24  # 24 * 5 minutes = 2 hours
  local iteration=0
  
  while true; do
    sleep 300  # 5 minutes
    sudo -n true 2>/dev/null || break
    kill -0 "$$" 2>/dev/null || break
    
    ((iteration++))
    if [[ $iteration -ge $max_iterations ]]; then
      log_warn "Sudo keep-alive timeout reached (2 hours)"
      break
    fi
  done &
}

# Print summary report
print_summary() {
  echo ""
  echo "======================================"
  echo "           SETUP SUMMARY"
  echo "======================================"
  echo ""
  
  if [[ ${#SUCCESSES[@]} -gt 0 ]]; then
    echo -e "${GREEN}Successes (${#SUCCESSES[@]}):${NC}"
    for success in "${SUCCESSES[@]}"; do
      echo "  ✓ $success"
    done
    echo ""
  fi
  
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Warnings (${#WARNINGS[@]}):${NC}"
    for warning in "${WARNINGS[@]}"; do
      echo "  ⚠ $warning"
    done
    echo ""
  fi
  
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo -e "${RED}Errors (${#ERRORS[@]}):${NC}"
    for error in "${ERRORS[@]}"; do
      echo "  ✗ $error"
    done
    echo ""
    return 1
  fi
  
  return 0
}

# Get exit code based on results
get_exit_code() {
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    return 2
  fi
  return 0
}

# Confirmation prompt
confirm() {
  # Skip prompts in CI or dry-run mode
  if [[ -n "${CI:-}" || "$DRY_RUN" == "true" ]]; then
    return 0
  fi
  
  read -r -p "${1:-Are you sure? [y/N]} " response
  case "$response" in
    [yY][eE][sS]|[yY])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Safe curl wrapper
safe_curl() {
  local url="$1"
  local output="${2:--}"  # Default to stdout
  
  # Basic URL validation
  if [[ ! "$url" =~ ^https:// ]]; then
    log_error "Only HTTPS URLs are allowed: $url"
    return 1
  fi
  
  if [[ "$output" == "-" ]]; then
    curl -fsSL "$url"
  else
    curl -fsSL "$url" -o "$output"
  fi
}
