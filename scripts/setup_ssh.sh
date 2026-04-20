#!/bin/bash

# SSH Setup Script for GitHub Account Switcher
# Creates SSH keys and configures SSH config for both personal and work accounts

set -e

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
PERSONAL_KEY="$SSH_DIR/id_ed25519"
WORK_KEY="$SSH_DIR/id_ed25519_emu"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== GitHub SSH Setup ==="
echo ""

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "Creating $SSH_DIR directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo -e "${GREEN}✓${NC} Created .ssh directory"
fi

# Function to generate SSH key
generate_ssh_key() {
    local key_path="$1"
    local email="$2"
    local description="$3"

    if [ -f "$key_path" ]; then
        echo -e "${YELLOW}!${NC} SSH key already exists: $key_path"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping $description key generation"
            return 0
        fi
    fi

    echo "Generating $description SSH key..."
    ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N ""

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Generated $description SSH key: $key_path"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to generate $description SSH key"
        return 1
    fi
}

# Generate personal key
echo "--- Personal Account Setup ---"
read -p "Enter email for personal account (haifeng-li-at-salesforce): " personal_email
generate_ssh_key "$PERSONAL_KEY" "$personal_email" "personal"
echo ""

# Generate work key
echo "--- Work Account Setup ---"
read -p "Enter email for work account (haifeng-li_sfemu): " work_email
generate_ssh_key "$WORK_KEY" "$work_email" "work"
echo ""

# Create or update SSH config
echo "--- SSH Config Setup ---"

# Backup existing config
if [ -f "$SSH_CONFIG" ]; then
    backup_file="$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up existing SSH config to $backup_file"
    cp "$SSH_CONFIG" "$backup_file"
fi

# Check if GitHub config already exists
if grep -q "^Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}!${NC} SSH config already contains GitHub configuration"
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping SSH config update"
        echo "You'll need to manually configure your SSH config"
        exit 0
    fi

    # Remove existing GitHub entries
    temp_config=$(mktemp)
    awk '/^Host github\.com/ { skip=1 } skip && /^Host / { skip=0 } !skip { print }' "$SSH_CONFIG" > "$temp_config"
    mv "$temp_config" "$SSH_CONFIG"
fi

# Append new GitHub SSH configuration
cat >> "$SSH_CONFIG" << EOF

# GitHub Account Configuration (managed by gh-switch skill)
# Active account (personal by default)
Host github.com
    HostName github.com
    User git
    IdentityFile $PERSONAL_KEY
    IdentitiesOnly yes

# Inactive account (work)
Host github.com-work
    HostName github.com
    User git
    IdentityFile $WORK_KEY
    IdentitiesOnly yes

EOF

chmod 600 "$SSH_CONFIG"
echo -e "${GREEN}✓${NC} SSH config updated"
echo ""

# Display public keys for GitHub
echo "=== Next Steps ==="
echo ""
echo "Add these SSH public keys to your GitHub accounts:"
echo ""
echo -e "${GREEN}Personal Account (haifeng-li-at-salesforce):${NC}"
echo "1. Copy this public key:"
echo "---"
cat "$PERSONAL_KEY.pub"
echo "---"
echo "2. Go to: https://github.com/settings/ssh/new"
echo "3. Paste the key and save"
echo ""

echo -e "${GREEN}Work Account (haifeng-li_sfemu):${NC}"
echo "1. Copy this public key:"
echo "---"
cat "$WORK_KEY.pub"
echo "---"
echo "2. Go to: https://github.com/settings/ssh/new"
echo "3. Paste the key and save"
echo ""

echo "After adding the keys, test the connection with:"
echo "  ssh -T git@github.com"
echo ""

# Start SSH agent if not running
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "Starting SSH agent..."
    eval "$(ssh-agent -s)"
fi

# Add keys to SSH agent
echo "Adding SSH keys to agent..."
ssh-add "$PERSONAL_KEY" 2>/dev/null || echo "Note: Could not add personal key to agent (may need password)"
ssh-add "$WORK_KEY" 2>/dev/null || echo "Note: Could not add work key to agent (may need password)"
echo ""

echo -e "${GREEN}✓${NC} Setup complete!"
echo ""
echo "You can now use the gh-switch skill to switch between accounts:"
echo "  /gh-switch work      # Switch to work account"
echo "  /gh-switch personal  # Switch to personal account"
echo "  /gh-switch           # Show current status"
