# Shared fish entrypoint.
# OS-specific snippets live in conf.d/ and are installed from os/<platform>/fish/conf.d/
# by scripts/bootstrap.sh. Fish auto-loads ~/.config/fish/conf.d/*.fish.


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<

# opencode
fish_add_path /home/snorri/.opencode/bin
