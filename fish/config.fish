# Git abbreviations
abbr -a g git
abbr -a gs git status
abbr -a gc git clone
abbr -a gpush git push
abbr -a gpull git pull


# Load keychain for SSH agent with 8-hour cache
if command -v keychain >/dev/null
    eval (keychain --quiet --eval --timeout 28800 monster-github)
end

source /usr/share/cachyos-fish-config/cachyos-config.fish
