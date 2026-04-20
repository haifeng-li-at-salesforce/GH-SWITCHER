#!/bin/bash

# GitHub Account Switcher
# Switches between haifeng-li-at-salesforce and haifeng-li_sfemu accounts
# Also switches SSH configuration to use the correct key

SSH_CONFIG="$HOME/.ssh/config"
SSH_BACKUP="$HOME/.ssh/config.backup"

show_status() {
    echo "=== GitHub Account Status ==="
    gh auth status 2>&1 | grep -A 3 "github.com"
    echo ""

    echo "=== SSH Configuration Status ==="
    if [ -f "$SSH_CONFIG" ]; then
        # Extract the active github.com host configuration
        local active_key=$(grep -A 5 "^Host github.com$" "$SSH_CONFIG" | grep "IdentityFile" | awk '{print $2}' | sed "s|~|$HOME|")
        if [ -n "$active_key" ]; then
            echo "Active SSH key: $active_key"
            local key_basename=$(basename "$active_key")
            if [[ "$key_basename" == *"emu"* ]]; then
                echo "Account type: Work (emu)"
            else
                echo "Account type: Personal"
            fi
        else
            echo "Warning: Could not determine active SSH key"
        fi

        # Test SSH connection
        echo -n "SSH connection test: "
        ssh -T git@github.com 2>&1 | head -n 1
    else
        echo "Warning: SSH config not found at $SSH_CONFIG"
    fi
    echo ""

    echo "Available accounts:"
    echo "  - haifeng-li_sfemu (shorthand: work)"
    echo "  - haifeng-li-at-salesforce (shorthand: personal)"
}

resolve_username() {
    local input="$1"
    case "$input" in
        work)
            echo "haifeng-li_sfemu"
            ;;
        personal)
            echo "haifeng-li-at-salesforce"
            ;;
        haifeng-li-at-salesforce|haifeng-li_sfemu)
            echo "$input"
            ;;
        *)
            echo ""
            ;;
    esac
}

switch_ssh_config() {
    local account_type="$1"  # "personal" or "work"

    if [ ! -f "$SSH_CONFIG" ]; then
        echo "Error: SSH config not found at $SSH_CONFIG"
        return 1
    fi

    # Verify SSH keys exist
    if [ "$account_type" = "personal" ]; then
        local required_key="$HOME/.ssh/id_ed25519"
    else
        local required_key="$HOME/.ssh/id_ed25519_emu"
    fi

    if [ ! -f "$required_key" ]; then
        echo "Error: SSH key not found at $required_key"
        return 1
    fi

    # Backup current config
    cp "$SSH_CONFIG" "$SSH_BACKUP"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to backup SSH config"
        return 1
    fi

    # Create temporary file for the new config
    local temp_config=$(mktemp)

    # Read and transform the SSH config
    if [ "$account_type" = "personal" ]; then
        # Switch to personal: github.com-personal → github.com, github.com → github.com-work
        awk '
        /^Host github\.com-personal/ { print "Host github.com"; next }
        /^Host github\.com$/ { print "Host github.com-work"; next }
        { print }
        ' "$SSH_CONFIG" > "$temp_config"
    else
        # Switch to work: github.com-work → github.com, github.com → github.com-personal
        awk '
        /^Host github\.com-work/ { print "Host github.com"; next }
        /^Host github\.com$/ { print "Host github.com-personal"; next }
        { print }
        ' "$SSH_CONFIG" > "$temp_config"
    fi

    # Verify the transformation worked
    if ! grep -q "^Host github.com$" "$temp_config"; then
        echo "Error: SSH config transformation failed"
        rm "$temp_config"
        return 1
    fi

    # Apply the new config
    mv "$temp_config" "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"

    # Clear SSH agent cache and re-add the correct key
    echo "Clearing SSH agent cache..."
    ssh-add -D > /dev/null 2>&1
    ssh-add "$required_key" > /dev/null 2>&1

    # Test SSH connection
    echo "Testing SSH connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✓ SSH configuration updated and verified"
        return 0
    else
        echo "Warning: SSH test did not confirm authentication, but config was updated"
        echo "You may need to add your SSH key to the GitHub account if not already done"
        return 0
    fi
}

switch_account() {
    local input="$1"
    local username=$(resolve_username "$input")

    if [ -z "$username" ]; then
        echo "Error: Unknown account '$input'"
        echo ""
        echo "Valid options:"
        echo "  - work (haifeng-li_sfemu)"
        echo "  - personal (haifeng-li-at-salesforce)"
        echo "  - haifeng-li-at-salesforce"
        echo "  - haifeng-li_sfemu"
        return 1
    fi

    # Determine account type for SSH switching
    local account_type
    if [ "$username" = "haifeng-li-at-salesforce" ]; then
        account_type="personal"
    else
        account_type="work"
    fi

    echo "Switching to $username..."
    echo ""

    # Switch gh CLI account
    echo "1. Switching gh CLI account..."
    gh auth switch --hostname github.com --user "$username"

    if [ $? -ne 0 ]; then
        echo ""
        echo "Error: Failed to switch gh account"
        return 1
    fi
    echo "✓ gh CLI switched to $username"
    echo ""

    # Switch SSH configuration
    echo "2. Switching SSH configuration..."
    switch_ssh_config "$account_type"

    if [ $? -ne 0 ]; then
        echo ""
        echo "Warning: SSH config switch failed, but gh CLI was updated"
        echo "You may need to manually update your SSH config"
        echo ""
        show_status
        return 1
    fi

    echo ""
    echo "✓ Successfully switched to $username (gh + SSH)"
    echo ""
    show_status
}

# Main logic
if [ $# -eq 0 ]; then
    show_status
else
    switch_account "$1"
fi
