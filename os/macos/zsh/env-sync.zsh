export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

env-sync() {
  local script="${${${(%):-%x}:A}%/os/macos/zsh/env-sync.zsh}/scripts/env-sync.sh"

  if [[ ! -f "$script" ]]; then
    printf 'Error: env-sync.sh not found at %s\n' "$script" >&2
    return 1
  fi

  local arg
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      "$script" --shell zsh "$@"
      return $?
    fi
  done

  eval "$("$script" --shell zsh "$@")"
}
