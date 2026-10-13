# Shared fish entrypoint.
# OS-specific snippets live in conf.d/ and are installed from os/<platform>/fish/conf.d/
# by scripts/bootstrap.sh. Fish auto-loads ~/.config/fish/conf.d/*.fish.

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
