#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

echo "======================================"
echo "   Dotfiles Bootstrap"
echo "======================================"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/debian_version ]]; then
  OS="debian"
elif [[ -f /etc/arch-release ]]; then
  OS="arch"
else
  OS="unknown"
fi

echo "Detected OS: $OS"
echo ""

# Install uv if not present
if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  if [[ "$OS" == "macos" ]] && command -v brew &>/dev/null; then
    brew install uv
  else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
  
  if ! command -v uv &>/dev/null; then
    echo "❌ Failed to install uv"
    exit 1
  fi
  
  echo "✓ uv installed"
else
  echo "✓ uv already installed ($(uv --version))"
fi

echo ""

# Create venv and install dependencies
if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating virtual environment..."
  uv sync
  echo "✓ Virtual environment created"
else
  echo "✓ Virtual environment exists"
fi

echo ""
echo "======================================"
echo "   Bootstrap Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  make setup    # Run full setup"
echo "  make check    # Dry run"
echo "  make help     # See all commands"
echo ""
