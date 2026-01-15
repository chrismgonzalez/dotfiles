#!/bin/bash

DOTFILES_DIR="$HOME/code/dotfiles"

function manage_launch_agents() {
  echo "Managing LaunchAgents..."

  # Get list of LaunchAgents from dotfiles
  local launch_agents_dir="$DOTFILES_DIR/LaunchAgents"
  if [ ! -d "$launch_agents_dir" ]; then
    echo "No LaunchAgents directory found in dotfiles"
    return
  fi

  # First unload all existing LaunchAgents
  for plist in "$launch_agents_dir"/*.plist; do
    if [ -f "$plist" ]; then
      local agent_name=$(basename "$plist")
      local target="$HOME/Library/LaunchAgents/$agent_name"

      if [ -f "$target" ]; then
        echo "Unloading LaunchAgent: $agent_name"
        launchctl unload "$target"
      fi
    fi
  done

  # Create symlinks
  mkdir -p "$HOME/Library/LaunchAgents"
  for plist in "$launch_agents_dir"/*.plist; do
    if [ -f "$plist" ]; then
      local agent_name=$(basename "$plist")
      local target="$HOME/Library/LaunchAgents/$agent_name"

      if [ -L "$target" ]; then
        echo "Removing existing symlink for $agent_name"
        rm "$target"
      fi

      echo "Creating symlink for $agent_name"
      ln -sf "$plist" "$target"
    fi
  done

  # Load all LaunchAgents
  for plist in "$launch_agents_dir"/*.plist; do
    if [ -f "$plist" ]; then
      local agent_name=$(basename "$plist")
      local target="$HOME/Library/LaunchAgents/$agent_name"

      if [ -f "$target" ]; then
        echo "Loading LaunchAgent: $agent_name"
        launchctl load "$target"
      fi
    fi
  done
}

# Run the function
manage_launch_agents
