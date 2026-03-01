#!/bin/bash
# Sudo askpass helper that detects OpenCode vs terminal
# 
# SETUP INSTRUCTIONS FOR LINUX:
# 
# 1. Save this script to ~/.local/bin/sudo-askpass:
#    mkdir -p ~/.local/bin
#    # (paste this script into ~/.local/bin/sudo-askpass)
#
# 2. Make it executable:
#    chmod +x ~/.local/bin/sudo-askpass
#
# 3. Set the SUDO_ASKPASS environment variable:
#
#    For Bash/Zsh (add to ~/.bashrc or ~/.zshrc):
#        export SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass
#
#    For Fish (add to ~/.config/fish/config.fish):
#        set -x SUDO_ASKPASS $HOME/.local/bin/sudo-askpass
#    
#    Or set it universally in Fish (persists across sessions):
#        set -Ux SUDO_ASKPASS $HOME/.local/bin/sudo-askpass
#
# 4. Reload your shell or start a new terminal session
#
# 5. Test it:
#    sudo -A whoami
#    # You should see a GUI password dialog appear
#
# HOW IT WORKS:
# - When OpenCode runs sudo commands, OPENCODE=1 is set and no TTY is available
# - This script detects that and shows a GUI dialog (pinentry-qt)
# - When you run sudo manually in a terminal, you get the normal password prompt
#
# REQUIREMENTS:
# - pinentry-qt must be installed (usually comes with GnuPG)
# - A Wayland or X11 display session

# Check if running under OpenCode AND without a TTY
if [ -n "$OPENCODE" ]; then
    # Verify we actually don't have a TTY (double-check)
    if ! tty -s 2>/dev/null; then
        # We're in OpenCode without a TTY - use GUI dialog
        # Use pinentry-qt (gnome3 is broken due to missing libraries)
        
        # Get the command being run by looking at sudo's command line
        # SUDO_COMMAND env var isn't passed to askpass, so we read from /proc
        if [ -n "$PPID" ]; then
            # Read the command sudo is executing from /proc
            SUDO_CMD=$(cat /proc/$PPID/cmdline 2>/dev/null | tr '\0' ' ' | sed 's/^sudo //; s/ *-A *//; s/ *--askpass//; s/ *-k//; s/^ *//; s/ *$//')
            if [ -n "$SUDO_CMD" ]; then
                COMMAND="$SUDO_CMD"
            else
                COMMAND="elevated permissions"
            fi
        else
            COMMAND="elevated permissions"
        fi
        
        
        echo "SETTITLE Authentication Required
SETDESC OpenCode requires your password to use $COMMAND
SETPROMPT Password:
GETPIN" | /usr/bin/pinentry-qt 2>/dev/null | grep '^D ' | cut -c3-
        exit $?
    fi
fi

# Either not OpenCode, or we have a TTY - fall back to normal sudo behavior
# Exit with error so sudo prompts normally on the terminal
exit 1
