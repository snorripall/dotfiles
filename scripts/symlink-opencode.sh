#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config/opencode"

mkdir -p "$CONFIG_DIR"

ln -sf "$SCRIPT_DIR/opencode/opencode.json" "$CONFIG_DIR/opencode.json"
ln -sf "$SCRIPT_DIR/opencode/oh-my-opencode.json" "$CONFIG_DIR/oh-my-opencode.json"
ln -sf "$SCRIPT_DIR/opencode/AGENTS.md" "$CONFIG_DIR/AGENTS.md"

echo "Symlinked opencode config files"
