#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FISH_FUNCTIONS_DIR="$HOME/.config/fish/functions"

# Create fish functions directory if it doesn't exist
mkdir -p "$FISH_FUNCTIONS_DIR"

# Symlink env-sync.fish
ln -sf "$REPO_DIR/fish/functions/env-sync.fish" "$FISH_FUNCTIONS_DIR/env-sync.fish"

echo "Symlinked env-sync.fish to $FISH_FUNCTIONS_DIR"


# Create fish config directory if it doesn't exist
mkdir -p "$HOME/.config/fish"

# Backup existing config.fish if it exists and is not already a symlink
if [ -f "$HOME/.config/fish/config.fish" ] && [ ! -L "$HOME/.config/fish/config.fish" ]; then
    mv "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.bak"
    echo "Backed up existing config.fish to config.fish.bak"
fi

# Symlink config.fish
ln -sf "$REPO_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"

echo "Symlinked config.fish to $HOME/.config/fish/"