#!/bin/bash
# Bootstrap script - installs minimal dependencies needed for setup.sh
# Run this first on a fresh machine

set -e

echo "======================================"
echo "   Dotfiles Bootstrap"
echo "======================================"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != darwin* ]]; then
  echo "Error: This script is designed for macOS"
  exit 1
fi

# Install Xcode Command Line Tools if needed
if ! command -v gcc >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools..."
  echo "Please follow the prompts and re-run this script after installation completes."
  xcode-select --install
  exit 0
else
  echo "✓ Xcode Command Line Tools installed"
fi

# Install Homebrew if needed
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  
  # Add Homebrew to PATH for Apple Silicon
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    echo "Adding Homebrew to PATH..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    # Add to shell profile if not already there
    if ! grep -q "/opt/homebrew/bin/brew" "$HOME/.zprofile" 2>/dev/null; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
  fi
  
  echo "✓ Homebrew installed"
else
  echo "✓ Homebrew already installed"
fi

# Install yq (required for config parsing)
if ! command -v yq >/dev/null 2>&1; then
  echo "Installing yq..."
  brew install yq
  echo "✓ yq installed"
else
  echo "✓ yq already installed"
fi

# Install jq (required for backup manifests)
if ! command -v jq >/dev/null 2>&1; then
  echo "Installing jq..."
  brew install jq
  echo "✓ jq installed"
else
  echo "✓ jq already installed"
fi

echo ""
echo "======================================"
echo "   Bootstrap Complete!"
echo "======================================"
echo ""
echo "You can now run the main setup:"
echo "  ./setup-new.sh --init          # Full setup"
echo "  ./setup-new.sh --init --dry-run  # Preview changes"
echo "  ./setup-new.sh --validate      # Check config"
echo ""
