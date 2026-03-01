#!/bin/bash
#
# cachyos-ssh-setup.sh
# Complete SSH key setup for CachyOS with auto-unlock on login
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running on CachyOS/Arch
check_os() {
    if ! command -v paru &> /dev/null && ! command -v pacman &> /dev/null; then
        print_error "This script is designed for Arch Linux / CachyOS"
        exit 1
    fi
}

# Install dependencies
install_deps() {
    print_status "Installing dependencies..."
    
    local deps=("kwalletcli" "openssh" "kwallet" "extra-cmake-modules" "ki18n" "kcoreaddons")
    
    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" &> /dev/null; then
            print_status "Installing $dep..."
            paru -S --noconfirm "$dep" || sudo pacman -S --noconfirm "$dep"
        else
            print_success "$dep already installed"
        fi
    done
    
    print_success "Dependencies installed"
}

# Check/setup sudo access
check_sudo() {
    print_status "Checking sudo access..."
    
    if ! sudo -n true 2>/dev/null; then
        print_warning "You need sudo access for this script"
        print_status "Please enter your password when prompted..."
        sudo -v || {
            print_error "Failed to get sudo access"
            exit 1
        }
    fi
    
    # Keep sudo alive
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done 2>/dev/null &
    
    print_success "Sudo access confirmed"
}

# Generate SSH key
generate_ssh_key() {
    print_status "Setting up SSH key..."
    
    # Ask for key name
    read -p "Enter name for your SSH key (e.g., 'github', 'gitlab', 'work'): " key_name
    
    if [ -z "$key_name" ]; then
        key_name="id_ed25519"
        print_warning "No name provided, using default: $key_name"
    fi
    
    # Ensure .ssh directory exists
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    local key_path="$HOME/.ssh/$key_name"
    
    # Check if key already exists
    if [ -f "$key_path" ]; then
        print_warning "SSH key already exists at $key_path"
        read -p "Overwrite? (y/N): " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            print_status "Skipping key generation"
            return
        fi
        rm -f "$key_path" "$key_path.pub"
    fi
    
    # Ask for passphrase
    echo ""
    print_status "Enter a passphrase for your SSH key (press Enter for no passphrase):"
    read -s passphrase
    echo ""
    
    if [ -n "$passphrase" ]; then
        read -s -p "Confirm passphrase: " passphrase_confirm
        echo ""
        
        if [ "$passphrase" != "$passphrase_confirm" ]; then
            print_error "Passphrases do not match"
            exit 1
        fi
    fi
    
    # Generate key
    print_status "Generating Ed25519 SSH key..."
    ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f "$key_path" -N "$passphrase"
    
    print_success "SSH key generated at $key_path"
    
    # Display public key
    echo ""
    print_status "Your public key (add this to GitHub/GitLab):"
    echo ""
    cat "$key_path.pub"
    echo ""
    
    # Save key name for later
    echo "$key_name" > ~/.ssh/.last_key_name
}

# Setup SSH config
setup_ssh_config() {
    print_status "Setting up SSH config..."
    
    # Get key name
    local key_name
    if [ -f ~/.ssh/.last_key_name ]; then
        key_name=$(cat ~/.ssh/.last_key_name)
    else
        # Find most recent key
        key_name=$(ls -t ~/.ssh/*.pub 2>/dev/null | head -1 | xargs basename -s .pub 2>/dev/null || echo "")
        if [ -z "$key_name" ]; then
            print_error "No SSH key found"
            return 1
        fi
    fi
    
    local key_path="$HOME/.ssh/$key_name"
    
    # Create SSH config
    cat > ~/.ssh/config << EOF
# Default settings
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $key_path

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile $key_path

# Generic git host template
Host git-*
    User git
    IdentityFile $key_path
EOF
    
    chmod 600 ~/.ssh/config
    
    print_success "SSH config created"
}

# Setup PAM for KWallet auto-unlock
setup_pam() {
    print_status "Setting up PAM for KWallet auto-unlock..."
    
    local pam_file="/etc/pam.d/system-login"
    
    # Check if already configured
    if grep -q "pam_kwallet5.so" "$pam_file" 2>/dev/null; then
        print_success "PAM already configured for KWallet"
        return
    fi
    
    # Backup original
    sudo cp "$pam_file" "${pam_file}.backup.$(date +%Y%m%d%H%M%S)"
    
    # Add KWallet PAM entries
    echo "" | sudo tee -a "$pam_file" > /dev/null
    echo "# KWallet auto-unlock with login password" | sudo tee -a "$pam_file" > /dev/null
    echo "-auth       optional   pam_kwallet5.so" | sudo tee -a "$pam_file" > /dev/null
    echo "session    optional   pam_kwallet5.so auto_start" | sudo tee -a "$pam_file" > /dev/null
    
    print_success "PAM configured for KWallet auto-unlock"
    print_warning "You will need to log out and back in for PAM changes to take effect"
}

# Store passphrase in KWallet
store_passphrase() {
    print_status "Setting up automatic SSH key unlock..."
    
    # Check if kwalletcli is available
    if ! command -v kwalletcli &> /dev/null; then
        print_error "kwalletcli not found. Please install it first."
        return 1
    fi
    
    # Get key name
    local key_name
    if [ -f ~/.ssh/.last_key_name ]; then
        key_name=$(cat ~/.ssh/.last_key_name)
    else
        print_warning "No key name found. Skipping passphrase storage."
        return
    fi
    
    local key_path="$HOME/.ssh/$key_name"
    
    # Check if key has passphrase
    if ! ssh-keygen -y -f "$key_path" &> /dev/null; then
        print_status "This step requires your SSH key passphrase"
        print_status "Enter your SSH key passphrase to store it in KWallet:"
        read -s ssh_passphrase
        echo ""
        
        if [ -z "$ssh_passphrase" ]; then
            print_warning "No passphrase provided. Skipping auto-unlock setup."
            return
        fi
        
        # Store in KWallet
        echo "$ssh_passphrase" | kwalletcli -f SSH -e "${key_name}-passphrase"
        
        if [ $? -eq 0 ]; then
            print_success "Passphrase stored in KWallet"
        else
            print_error "Failed to store passphrase in KWallet"
            return 1
        fi
    else
        print_warning "SSH key has no passphrase. Auto-unlock not needed."
    fi
}

# Setup Fish shell integration
setup_fish() {
    print_status "Setting up Fish shell integration..."
    
    local fish_config="$HOME/.config/fish/config.fish"
    
    # Create config directory if needed
    mkdir -p "$HOME/.config/fish"
    
    # Check if keychain config already exists
    if grep -q "keychain" "$fish_config" 2>/dev/null; then
        print_success "Fish config already has keychain setup"
        return
    fi
    
    # Add keychain setup to Fish config
    cat >> "$fish_config" << 'EOF'

# Load keychain for SSH agent with 8-hour cache
if command -v keychain > /dev/null
    eval (keychain --quiet --eval --timeout 28800)
end
EOF
    
    print_success "Fish shell configured for SSH agent"
}

# Create Niri autostart script (if using Niri)
setup_niri_autostart() {
    if [ -z "$DISPLAY" ] || [ ! -d "$HOME/.config/niri" ]; then
        print_status "Niri not detected, skipping autostart script"
        return
    fi
    
    print_status "Setting up Niri autostart..."
    
    # Get key name
    local key_name
    if [ -f ~/.ssh/.last_key_name ]; then
        key_name=$(cat ~/.ssh/.last_key_name)
    else
        key_name="id_ed25519"
    fi
    
    # Create autostart script
    mkdir -p "$HOME/.config/niri"
    
    cat > "$HOME/.config/niri/autostart-ssh.sh" << EOF
#!/bin/bash
# Auto-load SSH key on login
sleep 5
PASS=\$(kwalletcli -f SSH -e "${key_name}-passphrase" 2>/dev/null)
if [ -n "\$PASS" ]; then
    echo "\$PASS" | ssh-add "$HOME/.ssh/$key_name" 2>/dev/null
fi
EOF
    
    chmod +x "$HOME/.config/niri/autostart-ssh.sh"
    
    print_success "Niri autostart script created"
    print_status "Add this to your ~/.config/niri/config.kdl:"
    echo "  spawn-at-startup \"$HOME/.config/niri/autostart-ssh.sh\""
}

# Main setup function
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║     CachyOS SSH Setup with Auto-Unlock                 ║"
    echo "║     Your login password → KWallet → SSH key            ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    check_os
    check_sudo
    install_deps
    
    echo ""
    print_status "Step 1: Generate SSH key"
    generate_ssh_key
    
    echo ""
    print_status "Step 2: Configure SSH"
    setup_ssh_config
    
    echo ""
    print_status "Step 3: Setup PAM for auto-unlock"
    setup_pam
    
    echo ""
    print_status "Step 4: Store passphrase in KWallet"
    store_passphrase
    
    echo ""
    print_status "Step 5: Setup shell integration"
    setup_fish
    setup_niri_autostart
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    print_success "Setup complete!"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. ${YELLOW}Log out and log back in${NC} (required for PAM changes)"
    echo "  2. Add your public key to GitHub/GitLab (shown above)"
    echo "  3. Test with: ssh -T git@github.com"
    echo ""
    echo "After login, your SSH key will auto-load with KWallet!"
    echo ""
}

# Run main function
main "$@"
