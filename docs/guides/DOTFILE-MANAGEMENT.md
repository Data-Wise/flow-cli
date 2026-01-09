# Dotfile Management Guide

**Manage your dotfiles across machines with chezmoi and Bitwarden secrets**

**Last Updated:** 2026-01-09
**Version:** v1.2.0
**Target Audience:** Users wanting to synchronize dotfiles and manage secrets securely

---

## Overview

The `dot` dispatcher provides a unified interface for managing your dotfiles with chezmoi and secrets with Bitwarden CLI. It's designed to be ADHD-friendly with smart defaults, clear status displays, and progressive disclosure of complexity.

**Key Benefits:**

| Feature | Benefit |
|---------|---------|
| **Sync dotfiles** | Keep configs consistent across machines |
| **Secure secrets** | Store API keys/tokens in Bitwarden |
| **Safe edits** | Preview changes before applying |
| **Fast operations** | < 500ms for most commands |
| **Optional tools** | Works even if tools not installed |

---

## Quick Start

### 1. Install Tools

```bash
# Required for dotfile sync
brew install chezmoi

# Required for secret management
brew install bitwarden-cli

# Optional (for pretty secret listings)
brew install jq
```

### 2. Initialize Chezmoi

```bash
# Option A: Start fresh
chezmoi init

# Option B: Clone existing dotfiles
chezmoi init https://github.com/yourusername/dotfiles
```

### 3. Authenticate Bitwarden

```bash
# One-time login
bw login
```

### 4. Start Using

```bash
# Check status
dot

# Edit a dotfile
dot edit .zshrc

# Unlock secrets
dot unlock
```

---

## Architecture

```mermaid
flowchart TD
    A[User] --> B{dot command}

    B -->|dot status| C[Show Status]
    B -->|dot edit| D[Edit Workflow]
    B -->|dot sync| E[Sync Workflow]
    B -->|dot unlock| F[Unlock Bitwarden]
    B -->|dot secret| G[Retrieve Secret]

    D --> D1[Open in $EDITOR]
    D1 --> D2{Modified?}
    D2 -->|Yes| D3[Show Diff]
    D3 --> D4{Apply?}
    D4 -->|Yes| D5[chezmoi apply]
    D2 -->|No| D6[No changes]

    E --> E1[git fetch]
    E1 --> E2{Behind?}
    E2 -->|Yes| E3[Show commits]
    E3 --> E4{Pull?}
    E4 -->|Yes| E5[chezmoi update]
    E2 -->|No| E6[Up to date]

    F --> F1[Prompt password]
    F1 --> F2[bw unlock --raw]
    F2 --> F3[Export BW_SESSION]
    F3 --> F4[Validate session]

    G --> G1{Session valid?}
    G1 -->|Yes| G2[bw get password]
    G1 -->|No| G3[Error: vault locked]
    G2 --> G4[Return value no echo]

    C --> C1[chezmoi status]
    C1 --> C2[Check git status]
    C2 --> C3[Format display]

    style D5 fill:#90EE90
    style E5 fill:#90EE90
    style F4 fill:#90EE90
    style G4 fill:#90EE90
    style D6 fill:#FFD700
    style E6 fill:#FFD700
    style G3 fill:#FF6B6B
```

**Key Components:**

- **Chezmoi:** Dotfile source control & templating
- **Bitwarden CLI:** Secret management
- **Git:** Version control & sync
- **Flow-CLI:** Unified interface

---

## Common Workflows

### Workflow 1: Edit Dotfile (Most Common)

```bash
# 1. Check current status
dot

# 2. Edit a file
dot edit .zshrc

# 3. Preview changes (automatic)
# Shows: Modified: ~/.zshrc

# 4. Apply changes
# Prompt: Apply changes? [Y/n/d(iff)]
# Press: y

# 5. Changes applied to home directory
```

**Time:** < 30 seconds
**Commands:** 2 (`dot`, `dot edit .zshrc`)

### Workflow 2: Sync from Another Machine

```bash
# 1. Pull latest changes
dot sync

# 2. Review what changed
# Shows: Remote has updates: [commit list]

# 3. Confirm pull
# Prompt: Pull updates? [Y/n]
# Press: y

# 4. Apply changes (if needed)
dot apply
```

**Time:** 10-30 seconds
**Commands:** 2 (`dot sync`, `dot apply`)

### Workflow 3: Push Local Changes

```bash
# 1. Check what's modified
dot diff

# 2. Push changes
dot push

# 3. Enter commit message
# Prompt: Commit message:
# Type: "Update ZSH aliases"

# 4. Committed and pushed
```

**Time:** 20-40 seconds
**Commands:** 2-3 (`dot diff`, `dot push`)

### Workflow 4: Use Secret in Template

```bash
# 1. Unlock Bitwarden
dot unlock

# 2. Edit template file
dot edit .gitconfig

# 3. Add secret reference in template
# {{ bitwarden "item" "github-token" }}

# 4. Apply template (automatic)
# Result: ~/.gitconfig contains actual token
```

**Time:** 1-2 minutes
**Commands:** 2-3 (`dot unlock`, `dot edit`)

---

## Chezmoi Setup

### Directory Structure

```
~/.local/share/chezmoi/          # Source files (templates)
├── .git/                        # Git repository
├── dot_zshrc.tmpl               # Template → ~/.zshrc
├── dot_gitconfig.tmpl           # Template → ~/.gitconfig
├── private_env.sh.tmpl          # Private → ~/.env.sh
└── ...

~/                               # Applied files
├── .zshrc                       # Generated from template
├── .gitconfig                   # Generated from template
└── ...
```

### Naming Convention

Chezmoi uses special prefixes for file transformations:

| Prefix | Result | Example |
|--------|--------|---------|
| `dot_` | Adds leading `.` | `dot_zshrc` → `.zshrc` |
| `.tmpl` | Template processing | `dot_gitconfig.tmpl` → `.gitconfig` |
| `private_` | Executable only by you | `private_env.sh` → `.env.sh` (0600) |
| `executable_` | Executable file | `executable_script.sh` → `script.sh` (0755) |

### Adding New Files

```bash
# Add file to chezmoi (starts tracking)
chezmoi add ~/.zshrc

# Add as template (for variable substitution)
chezmoi add --template ~/.gitconfig
```

### Removing Files

```bash
# Stop tracking a file
chezmoi forget ~/.old_config

# Remove from chezmoi directory
rm ~/.local/share/chezmoi/dot_old_config
```

---

## Bitwarden Setup

### Initial Configuration

```bash
# 1. Login (one-time)
bw login

# 2. Test authentication
bw status
# Output: {"status":"locked",...}

# 3. Unlock vault (per-session)
dot unlock

# 4. Verify unlock
dot secret list
```

### Creating Items

```bash
# Option A: Via CLI
bw create item \
  --name "github-token" \
  --username "youruser" \
  --password "ghp_..." \
  --folder "Work/GitHub"

# Option B: Via web vault
# 1. Go to vault.bitwarden.com
# 2. Add item → Login
# 3. Name: github-token
# 4. Password: ghp_...
# 5. Save
```

### Organizing Items

Use folders for organization:

```
Work/
├── GitHub
│   ├── github-token
│   └── github-ssh-key
├── Node
│   ├── npm-token
│   └── npmrc-auth
└── Cloud
    ├── aws-key
    └── do-token

Personal/
├── ssh-passphrase
└── gpg-key
```

### Item Types

| Type | Icon | Use Case | Example |
|------|------|----------|---------|
| Login | 🔑 | API tokens, passwords | GitHub token |
| Secure Note | 📝 | SSH keys, certificates | Private key |
| Card | 💳 | Stripe test keys | Payment API |

---

## Template Examples

### Example 1: Git Config with Token

**File:** `~/.local/share/chezmoi/dot_gitconfig.tmpl`

```ini
[user]
    name = Your Name
    email = your@email.com

[github]
    user = youruser
    token = {{ bitwarden "item" "github-token" }}

[core]
    editor = vim
```

**Apply:**

```bash
dot unlock
dot edit .gitconfig
# Changes applied → ~/.gitconfig has actual token
```

### Example 2: ZSH with API Keys

**File:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# API Keys (from Bitwarden)
export OPENAI_API_KEY="{{ bitwarden "item" "openai-key" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-key" }}"
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"

# Regular config
export PATH="$HOME/bin:$PATH"
```

**Apply:**

```bash
dot unlock
dot edit .zshrc
source ~/.zshrc
```

### Example 3: Environment File

**File:** `~/.local/share/chezmoi/private_env.sh.tmpl`

```bash
#!/bin/bash
# Auto-generated from Bitwarden secrets
# Source: source ~/.env.sh

export OPENAI_API_KEY="{{ bitwarden "item" "openai-key" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-key" }}"
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
export NPM_TOKEN="{{ bitwarden "item" "npm-token" }}"
```

**Apply:**

```bash
dot unlock
chezmoi apply ~/.env.sh
source ~/.env.sh
```

### Example 4: SSH Config

**File:** `~/.local/share/chezmoi/private_dot_ssh/config.tmpl`

```
Host github.com
    User git
    IdentityFile ~/.ssh/github_ed25519
    IdentitiesOnly yes

Host bitbucket.org
    User git
    IdentityFile ~/.ssh/bitbucket_rsa
```

**Apply:**

```bash
dot edit .ssh/config
```

---

## Dashboard Integration

The `dash` command automatically shows dotfile status:

```
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD ✓                  Jan 09, 2026  🕐 14:30 │
╰──────────────────────────────────────────────────────────────╯

  ...

  📝 Dotfiles: 🟢 Synced (2h ago) · 12 files tracked

  ...
```

**Status Icons:**

| Icon | State | Meaning |
|------|-------|---------|
| 🟢 | Synced | Everything up to date |
| 🟡 | Modified | Local changes pending |
| 🔴 | Behind | Remote has new commits |
| 🔵 | Ahead | Local commits not pushed |

**Performance:** < 100ms (uses cached values)

---

## Doctor Integration

The `flow doctor` command includes dotfile health checks:

```
📁 DOTFILES
  ✓ chezmoi v2.45.0
  ✓ Bitwarden CLI v2024.1.0
  ✓ Chezmoi initialized with git
  ✓ Remote configured: git@github.com:user/dotfiles.git
  ✓ No uncommitted changes
  ✓ Synced with remote
  ✓ Bitwarden vault unlocked
```

**Run diagnostics:**

```bash
# Via dot dispatcher
dot doctor

# Via flow doctor
flow doctor
```

---

## Troubleshooting

### "Chezmoi not initialized"

**Symptoms:**
- `dot status` shows "Not initialized"
- Commands fail with errors

**Solution:**

```bash
# Option A: Start fresh
chezmoi init

# Option B: Clone existing repo
chezmoi init https://github.com/yourusername/dotfiles
```

### "Bitwarden vault is locked"

**Symptoms:**
- `dot secret` fails
- Template processing fails

**Solution:**

```bash
# Unlock vault
dot unlock

# Try again
dot secret github-token
```

### "Item not found or access denied"

**Symptoms:**
- `dot secret <name>` fails
- Template shows error

**Solution:**

```bash
# List all items (check exact name)
dot secret list

# Check item exists
bw get item github-token
```

### Changes Not Applied

**Symptoms:**
- `dot edit` succeeds but file unchanged
- Templates not processing

**Solution:**

```bash
# Check pending changes
dot diff

# Apply manually
dot apply

# For templates, ensure vault unlocked
dot unlock
dot apply
```

### Session Token in History

**Concern:**
- Worried about BW_SESSION in shell history

**Solution:**

The `dot unlock` command safely captures tokens without exposing them. History exclusion patterns prevent storage:

```bash
# Verify history settings
echo $HISTIGNORE

# Should include: *bw unlock*:*bw get*:*BW_SESSION*
```

This is automatically configured when dotfile helpers load.

---

## Security Best Practices

### ✅ DO

- **Unlock per-session:** Run `dot unlock` in each shell where you need secrets
- **Lock when done:** Run `bw lock` after template operations
- **Use templates:** Store templates in chezmoi, not plain files with secrets
- **Capture securely:** Use `VAR=$(dot secret name)` to capture without echo
- **Validate items:** Use `dot secret list` to verify item names before using
- **Review templates:** Check templates before applying to ensure no leaks

### ❌ DON'T

- **Don't export globally:** Never add `export BW_SESSION=...` to `.zshrc`
- **Don't commit secrets:** Never commit files with actual secret values
- **Don't echo secrets:** Avoid `echo $(dot secret name)` in scripts
- **Don't log secrets:** Ensure secrets aren't written to logs/history
- **Don't share sessions:** Each user should unlock their own vault
- **Don't hardcode tokens:** Use templates and Bitwarden instead

### Security Checklist

```bash
# 1. Check for global BW_SESSION exports (should find nothing)
grep -r "export BW_SESSION" ~/.config/zsh ~/.zshrc ~/.zshenv 2>/dev/null

# 2. Verify history exclusion
echo $HISTIGNORE | grep "bw unlock"

# 3. Check for committed secrets (in chezmoi repo)
cd ~/.local/share/chezmoi
git log -p | grep -i "token\|password\|secret" | grep -v "bitwarden"

# 4. Audit applied files (should contain actual secrets, not templates)
grep "bitwarden" ~/.gitconfig ~/.zshrc 2>/dev/null
# Should return nothing (templates are processed)
```

---

## Advanced Usage

### Multiple Machines

Keep dotfiles synced across machines:

```bash
# Machine A (iMac): Make changes
dot edit .zshrc
dot push

# Machine B (MacBook): Pull changes
dot sync
dot apply
```

### Conditional Templates

Use chezmoi's template syntax for machine-specific config:

```bash
{{ if eq .chezmoi.hostname "imac" }}
export WORK_MODE=true
{{ else }}
export WORK_MODE=false
{{ end }}
```

### Custom Fields

Access custom fields in Bitwarden items:

```bash
# In template
{{ bitwardenFields "item" "api-key" "custom-field-name" }}
```

### Secret Rotation

When rotating secrets:

```bash
# 1. Update in Bitwarden
bw edit item github-token

# 2. Re-apply templates
dot unlock
dot apply

# 3. Verify new secret
grep github-token ~/.gitconfig
```

---

## Command Reference

| Command | Alias | Purpose |
|---------|-------|---------|
| `dot` | - | Show status (default) |
| `dot status` | `dot s` | Show sync status |
| `dot edit FILE` | `dot e FILE` | Edit dotfile with preview |
| `dot sync` | - | Pull from remote |
| `dot push` | `dot p` | Push to remote |
| `dot diff` | `dot d` | Show pending changes |
| `dot apply` | `dot a` | Apply changes |
| `dot unlock` | `dot u` | Unlock Bitwarden vault |
| `dot secret NAME` | - | Retrieve secret |
| `dot secret list` | - | List all secrets |
| `dot doctor` | `dot dr` | Run diagnostics |
| `dot help` | - | Show help |

---

## See Also

- [DOT-DISPATCHER-REFERENCE.md](../reference/DOT-DISPATCHER-REFERENCE.md) - Complete command reference
- [SECRET-MANAGEMENT.md](../SECRET-MANAGEMENT.md) - Deep dive into Bitwarden integration
- [Chezmoi Documentation](https://www.chezmoi.io/) - Official chezmoi docs
- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/) - Official Bitwarden CLI docs

---

**Version:** 1.2.0
**Last Updated:** 2026-01-09
**Status:** Production Ready
