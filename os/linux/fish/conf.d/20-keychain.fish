# Reuse an SSH agent with an 8-hour key cache (timeout is in minutes).
if command -v keychain >/dev/null
    if status is-interactive
        # Skip keychain 3's extra "Press Enter to run ssh-add" confirmation.
        eval (keychain --quiet --eval --immediate --timeout 480 monster-github)
    else
        # Desktop/session startup must never wait for keyboard input.
        eval (keychain --quiet --eval --noask --timeout 480 monster-github)
    end
end
