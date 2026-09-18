# PROJECT KNOWLEDGE BASE

**Generated:** 2026-09-18T10:21:13Z
**Commit:** 5490ba3
**Branch:** main

## OVERVIEW

Personal cross-platform dotfiles for CachyOS/Niri Linux and Apple Silicon macOS.
Shell scripts deploy shared configuration, platform overlays, OpenCode settings, and native OMO agent routing.

## STRUCTURE

```text
dotfiles/
├── fish/                 # Shared Fish entrypoint, abbreviations, and functions
├── omo/                  # Native ~/.omo/omo.json agent and category routing
├── opencode/             # Shared OpenCode base, profiles, and deployed global policy
├── os/
│   ├── linux/            # CachyOS, Niri, helpers, skills, and one-shot setup
│   └── macos/            # Fish/Zsh, Zed, and OpenCode platform overlays
├── scripts/              # Bootstrap, secret sync, profile switching, token reports
└── zed/                  # Shared editor settings
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Install or relink dotfiles | `scripts/bootstrap.sh` | Shared packs first, then detected or forced OS pack |
| Map pack files to destinations | `scripts/bootstrap.sh` `dest_for`, `link_pack` | OMO is the only pack installed under `~/.omo` |
| Change native OMO routing | `omo/omo.json` | Ordered `models` arrays are primary-to-fallback chains |
| Change OpenCode defaults | `opencode/opencode.json` | Base merged with an OS overlay when `jq` exists |
| Change local model profile | `opencode/profiles/homelab.json` | Installed as `oh-my-openagent.json` |
| Switch an installed profile | `scripts/opencode-profile.sh` | Symlink-only switch with timestamped backup |
| Sync API keys | `scripts/env-sync.sh` | Bitwarden core; Fish and Zsh wrappers consume stdout |
| Change shared Fish behavior | `fish/` | OS-specific snippets belong under `os/<platform>/fish/conf.d` |
| Change Niri automation | `os/linux/niri/`, `os/linux/bin/` | Custom KDL plus launcher and routing daemon |
| Configure Linux SSH/KWallet | `os/linux/setup/ssh.sh` | Interactive, privileged, and CachyOS/Arch-specific |
| Change global agent policy payload | `opencode/AGENTS.md` | Deployed to `~/.config/opencode/AGENTS.md`; not a subtree guide |

## CONVENTIONS

- Root-level `fish`, `zed`, `opencode`, and `omo` are shared; platform differences stay under `os/linux` or `os/macos`.
- Deployment is symlink-first. A real destination is moved to `.backup.<timestamp>` before replacement.
- `scripts/bootstrap.sh --dry-run` reports intended changes, although destination parent directories may still be created.
- OpenCode configuration is `opencode/opencode.json` deep-merged with `os/<platform>/opencode/opencode.overlay.json`.
- Native OMO configuration goes directly to `~/.omo/omo.json`, not `~/.config/omo`.
- OMO `models` arrays are ordered fallback chains; high-complexity roles lead with GPT-5.6 Sol.
- OpenCode profiles describe model roles independently of the operating system.
- Fish loads shared `config.fish`, `conf.d/*.fish`, and `functions/`; do not fold OS snippets into the shared entrypoint.
- `scripts/env-sync.sh` emits shell code on stdout and diagnostics on stderr; wrappers source or eval only that output.
- Generated secret files use mode `600` and live outside this repository.

## ANTI-PATTERNS (THIS PROJECT)

- Never install `opencode.overlay.json` as a plain symlink; bootstrap must merge it with the shared base.
- Do not append Linux keychain setup to `fish/config.fish`; bootstrap owns the symlinked configuration.
- Do not hand-edit `env-sync-vars.fish` or `env-sync-vars.zsh`; `env-sync` regenerates them.
- Do not commit API keys, Bitwarden values, SSH private keys, `.env` files, or generated secret exports.
- Do not run `os/linux/setup/ssh.sh` casually: it installs packages, can replace keys, and edits PAM.
- Do not treat `opencode/AGENTS.md` as repository-local guidance; it is an installed global policy artifact.

## UNIQUE STYLES

- Native OMO routing uses GPT-5.6 Sol for high-reasoning roles, Luna Fast for cheaper roles, and homelab Qwen as final fallback.
- Linux Niri automation uses a dedicated workspace, a launcher wrapper, and a daemon that routes spawned windows.
- OpenCode browser configuration differs by OS only through overlays; Linux pins `/usr/lib/chromium/chromium`.
- SSH host entries are managed as `~/.ssh/config.d/` drop-ins instead of replacing the main config.

## COMMANDS

```bash
# Validate intended installation without linking files
bash scripts/bootstrap.sh --dry-run --profile homelab

# Install for the detected OS
bash scripts/bootstrap.sh --profile homelab

# Switch the installed OpenCode role profile
bash scripts/opencode-profile.sh homelab

# Linux-only focused setup
bash os/linux/setup/niri.sh
bash os/linux/setup/ssh.sh

# Refresh environment secrets
env-sync --force
```

## NOTES

- `scripts/bootstrap.sh` currently lacks an executable bit; invoke it through `bash`.
- The tracked `cloud` profile is currently absent, so bootstrap's default profile fails unless a profile is supplied.
- Missing `jq` causes bootstrap to link only the OpenCode base and skip the platform overlay.
- No repository-specific automated test or lint command is defined; use syntax checks and bootstrap dry-run.
- Semantic reference counts are unmeasured because Bash LSP and ast-grep are unavailable in this checkout.
