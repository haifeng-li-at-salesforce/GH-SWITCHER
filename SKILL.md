---
name: gh-switch
description: "Switch between GitHub accounts (haifeng-li-at-salesforce and haifeng-li_sfemu) on github.com. Switches both gh CLI and SSH configuration to use the correct key pair. Use when the user wants to switch GitHub accounts, check current GitHub account status, or needs to use a different GitHub identity for gh CLI and git operations. Supports shorthand: 'work' for haifeng-li_sfemu, 'personal' for haifeng-li-at-salesforce."
---

# GitHub Account Switcher

Switch between two GitHub accounts on github.com using gh CLI and SSH configuration.

## Accounts

- **haifeng-li_sfemu** (shorthand: `work`) - Uses SSH key `~/.ssh/id_ed25519_emu`
- **haifeng-li-at-salesforce** (shorthand: `personal`) - Uses SSH key `~/.ssh/id_ed25519`

## What It Does

When you switch accounts, the script:
1. **Switches gh CLI authentication** to the target account
2. **Updates SSH configuration** by modifying `~/.ssh/config` to use the correct SSH key
3. **Verifies the SSH connection** to ensure git operations will work
4. **Creates a backup** of your SSH config at `~/.ssh/config.backup`

## Usage

Run the switch script with an account identifier:

```bash
bash scripts/switch_github_account.sh <account>
```

### Show Current Status

No arguments shows current account and available options:

```bash
bash scripts/switch_github_account.sh
```

This displays:
- Current gh CLI account and authentication status
- Active SSH key being used for github.com
- SSH connection test result

### Switch Account

```bash
# Using shorthand
bash scripts/switch_github_account.sh work
bash scripts/switch_github_account.sh personal

# Using full username
bash scripts/switch_github_account.sh haifeng-li_sfemu
bash scripts/switch_github_account.sh haifeng-li-at-salesforce
```

## SSH Configuration Details

The script manages two SSH host configurations in `~/.ssh/config`:

**When using work account:**
```
Host github.com            # Active (uses id_ed25519_emu)
Host github.com-personal   # Inactive (uses id_ed25519)
```

**When using personal account:**
```
Host github.com            # Active (uses id_ed25519)
Host github.com-work       # Inactive (uses id_ed25519_emu)
```

The active `github.com` host is what gets used for all git operations.

## First-Time Setup

If you don't have SSH keys configured for both accounts, run the setup script:

```bash
bash scripts/setup_ssh.sh
```

This interactive script will:
1. Create `~/.ssh` directory if it doesn't exist
2. Generate SSH key pair for personal account (`~/.ssh/id_ed25519`)
3. Generate SSH key pair for work account (`~/.ssh/id_ed25519_emu`)
4. Create or update `~/.ssh/config` with proper GitHub host configurations
5. Display the public keys for you to add to your GitHub accounts
6. Add keys to your SSH agent

After running the setup:
1. Copy each public key displayed in the output
2. Go to GitHub Settings → SSH and GPG keys → New SSH key
3. Add the personal key to haifeng-li-at-salesforce account
4. Add the work key to haifeng-li_sfemu account
5. Test the connection: `ssh -T git@github.com`

Both accounts must also be authenticated with gh CLI:
```bash
gh auth login
```

## Prerequisites

- Both GitHub accounts must be authenticated with `gh auth login`
- Both SSH keys must exist:
  - `~/.ssh/id_ed25519` (personal)
  - `~/.ssh/id_ed25519_emu` (work)
- SSH public keys must be added to the respective GitHub accounts

If these prerequisites aren't met, use the setup script above.

## Troubleshooting

**SSH authentication fails after switch:**
- Verify the SSH key exists at the expected location
- Check that the public key is added to the GitHub account:
  - Visit https://github.com/settings/keys
  - Ensure the correct key is present
- Test manually: `ssh -T git@github.com`

**Script fails to update SSH config:**
- Check file permissions on `~/.ssh/config` (should be 600)
- Verify you have write access to `~/.ssh/` directory
- Review the backup at `~/.ssh/config.backup`

**Wrong account being used for git operations:**
- Run the status command to verify both gh and SSH are using the expected account
- The SSH key in use should match the gh account

## Notes

- Switches only affect github.com (not git.soma.salesforce.com or other hosts)
- A backup of your SSH config is created before each switch
- The script confirms successful switch and shows updated status
