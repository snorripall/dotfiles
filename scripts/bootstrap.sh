#!/usr/bin/env bash
# Install shared + OS-specific dotfiles via symlinks.
# omo.jsonc is linked so the repository remains the source of truth.
#
# Usage:
#   ./scripts/bootstrap.sh              # shared + detected OS
#   ./scripts/bootstrap.sh --os linux   # force OS pack
#   ./scripts/bootstrap.sh --os macos
#   ./scripts/bootstrap.sh --profile cloud|homelab
#   ./scripts/bootstrap.sh --dry-run

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
FORCE_OS=""
PROFILE="${OPENCODE_PROFILE:-cloud}"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --os) FORCE_OS="${2:-}"; shift 2 ;;
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

detect_os() {
  if [[ -n "$FORCE_OS" ]]; then
    echo "$FORCE_OS"
    return
  fi
  case "$(uname -s)" in
    Linux)  echo "linux" ;;
    Darwin) echo "macos" ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
  esac
}

OS_NAME="$(detect_os)"
OS_DIR="$ROOT/os/$OS_NAME"

if [[ ! -d "$OS_DIR" ]]; then
  echo "Error: OS pack not found: $OS_DIR" >&2
  exit 1
fi

log() { printf '%s\n' "$*"; }

backup_if_needed() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local bak="${target}.backup.$(date +%Y%m%d%H%M%S)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "  [dry-run] backup $target -> $bak"
    else
      mv "$target" "$bak"
      log "  backed up $target -> $bak"
    fi
  fi
}

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest" || true)"
    if [[ "$current" == "$src" ]]; then
      log "  ok   $dest"
      return
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "  [dry-run] relink $dest -> $src"
      return
    fi
    rm "$dest"
  else
    backup_if_needed "$dest"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "  [dry-run] link  $dest -> $src"
  else
    ln -sfn "$src" "$dest"
    log "  link $dest -> $src"
  fi
}

# Map logical config key + relative path -> absolute destination under $HOME.
# key: fish | git | niri | omo | opencode | zed | bin | skills
dest_for() {
  local key="$1"
  local rel="$2"
  case "$key" in
    bin)     echo "$HOME/.local/bin/${rel}" ;;
    omo)     echo "$HOME/.omo/${rel}" ;;
    skills)  echo "$HOME/.config/opencode/skills/${rel}" ;;
    fish|git|niri|opencode|zed)
      echo "$HOME/.config/${key}/${rel}"
      ;;
    *)
      echo "$HOME/.config/${key}/${rel}"
      ;;
  esac
}

# Link every file under pack_dir into dest_for(key, relpath).
# Skips files matching optional skip globs (space-separated basenames/paths).
link_pack() {
  local pack_dir="$1"
  local key="$2"
  local label="$3"

  log ""
  log "==> $label"

  if [[ ! -d "$pack_dir" ]]; then
    log "  (missing, skip)"
    return
  fi

  local src rel dest
  while IFS= read -r -d '' src; do
    rel="${src#"$pack_dir"/}"

    # Never install setup scripts or merge overlays via plain link
    case "$rel" in
      opencode.overlay.json) continue ;;
    esac

    dest="$(dest_for "$key" "$rel")"
    link_file "$src" "$dest"
  done < <(find "$pack_dir" -type f -print0 | sort -z)
}

merge_opencode_config() {
  local base="$ROOT/opencode/opencode.json"
  local overlay="$OS_DIR/opencode/opencode.overlay.json"
  local dest="$HOME/.config/opencode/opencode.json"

  mkdir -p "$(dirname "$dest")"
  log ""
  log "==> OpenCode config (base + OS overlay)"

  if [[ ! -f "$base" ]]; then
    log "  missing base: $base"
    return 1
  fi

  if [[ ! -f "$overlay" ]]; then
    link_file "$base" "$dest"
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log "  warning: jq not found; linking base without overlay"
    link_file "$base" "$dest"
    return
  fi

  if [[ -L "$dest" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "  [dry-run] replace symlink with merged config: $dest"
      return
    fi
    rm "$dest"
  else
    backup_if_needed "$dest"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "  [dry-run] merge -> $dest"
    return
  fi

  jq -s '.[0] * .[1]' "$base" "$overlay" >"$dest"
  log "  wrote $dest"
}

install_opencode_profile() {
  local profile_src="$ROOT/opencode/profiles/${PROFILE}.json"
  local dest="$HOME/.config/opencode/oh-my-openagent.json"

  log ""
  log "==> OpenCode agent profile: $PROFILE"

  if [[ ! -f "$profile_src" ]]; then
    echo "Error: profile not found: $profile_src" >&2
    echo "Available profiles:" >&2
    for f in "$ROOT/opencode/profiles"/*.json; do
      [[ -f "$f" ]] && basename "$f" .json >&2
    done
    exit 1
  fi

  link_file "$profile_src" "$dest"

  if [[ -f "$ROOT/opencode/AGENTS.md" ]]; then
    link_file "$ROOT/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
  fi
}

log "Dotfiles root: $ROOT"
log "OS pack:       $OS_NAME"
log "Profile:       $PROFILE"
[[ "$DRY_RUN" -eq 1 ]] && log "(dry-run mode)"

# --- shared ---
link_pack "$ROOT/omo" "omo" "shared omo"
link_pack "$ROOT/fish" "fish" "shared fish"
link_pack "$ROOT/zed" "zed" "shared zed"
if [[ -d "$ROOT/git" ]]; then
  link_pack "$ROOT/git" "git" "shared git"
fi

# --- OS pack ---
# Each top-level dir under os/<name>/ is a key for dest_for
if [[ -d "$OS_DIR" ]]; then
  for entry in "$OS_DIR"/*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    case "$name" in
      setup)
        log ""
        log "==> os/$OS_NAME/setup (not installed; run from repo)"
        for s in "$entry"/*; do
          [[ -f "$s" ]] && log "  - $s"
        done
        ;;
      opencode)
        # overlay merged separately; link any other files if present
        log ""
        log "==> os/$OS_NAME/opencode (overlay handled below)"
        while IFS= read -r -d '' src; do
          rel="${src#"$entry"/}"
          [[ "$rel" == "opencode.overlay.json" ]] && continue
          link_file "$src" "$(dest_for opencode "$rel")"
        done < <(find "$entry" -type f -print0 2>/dev/null | sort -z)
        ;;
      *)
        link_pack "$entry" "$name" "os/$OS_NAME/$name"
        ;;
    esac
  done
fi

merge_opencode_config
install_opencode_profile

# --- macOS: hook env-sync into .zshrc ---

hook_zshrc() {
  local zshrc="$HOME/.zshrc"
  local guard="# >>> dotfiles env-sync >>>"

  log ""
  log "==> zsh env-sync hook (~/.zshrc)"

  if [[ -f "$zshrc" ]] && grep -qF "$guard" "$zshrc"; then
    log "  ok   (hook already present)"
    return
  fi

  local block
  block="$(cat <<'BLOCK'

# >>> dotfiles env-sync >>>
[[ -f "$HOME/.config/zsh/env-sync.zsh" ]] && source "$HOME/.config/zsh/env-sync.zsh"
[[ -f "$HOME/.config/zsh/env-sync-vars.zsh" ]] && source "$HOME/.config/zsh/env-sync-vars.zsh"
# <<< dotfiles env-sync <<<
BLOCK
)"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "  [dry-run] append env-sync hook to $zshrc"
    return
  fi

  printf '%s\n' "$block" >> "$zshrc"
  log "  appended env-sync hook to $zshrc"
}

if [[ "$OS_NAME" == "macos" ]]; then
  hook_zshrc
fi

log ""
log "Done."
log ""
log "Next steps:"
log "  - Restart fish or open a new shell"
log "  - Switch agent profile:  ./scripts/opencode-profile.sh cloud|homelab"
if [[ "$OS_NAME" == "macos" ]]; then
  log "  - Restart zsh or:        source ~/.zshrc"
fi
if [[ "$OS_NAME" == "linux" ]]; then
  log "  - Optional setups:       ./os/linux/setup/niri.sh"
  log "                           ./os/linux/setup/ssh.sh"
  log "  - Niri: ensure config.kdl has:  include \"custom.kdl\""
fi
