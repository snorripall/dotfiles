#!/usr/bin/env bash
# Symlink Niri custom.kdl and remind about include.
# Prefer: ./scripts/bootstrap.sh  (installs niri pack automatically)
# This script is a focused helper if you only want niri.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SRC="$ROOT/os/linux/niri/custom.kdl"
NIRI_CONFIG_DIR="${NIRI_CONFIG_DIR:-$HOME/.config/niri}"
DEST="$NIRI_CONFIG_DIR/custom.kdl"

echo "Setting up Niri custom configuration..."

if [[ ! -f "$SRC" ]]; then
  echo "Error: source not found: $SRC" >&2
  exit 1
fi

if [[ ! -d "$NIRI_CONFIG_DIR" ]]; then
  echo "Error: Niri config directory not found at $NIRI_CONFIG_DIR" >&2
  exit 1
fi

if [[ -f "$DEST" && ! -L "$DEST" ]]; then
  bak="$DEST.backup.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing custom.kdl -> $bak"
  mv "$DEST" "$bak"
fi

ln -sfn "$SRC" "$DEST"
echo "Linked $DEST -> $SRC"

if [[ -f "$NIRI_CONFIG_DIR/config.kdl" ]] && ! grep -q 'include "custom.kdl"' "$NIRI_CONFIG_DIR/config.kdl"; then
  echo ""
  echo "Warning: custom.kdl is not included in config.kdl"
  echo "Add this line to ~/.config/niri/config.kdl:"
  echo '    include "custom.kdl"'
fi

echo ""
echo "Also installed:"
echo "  ~/.local/bin/run-in-automation        - wrapper to spawn apps on automation workspace"
echo "  ~/.local/bin/agent-automation-daemon  - daemon to auto-route agent-spawned windows"
echo ""
echo "The daemon auto-starts via spawn-at-startup in custom.kdl."
echo "Manual control: agent-automation-daemon {start|stop|status|restart}"
echo ""
echo "Niri custom configuration setup complete."
echo "Reload with: Mod+F5"
