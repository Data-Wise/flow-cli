# Dot Dispatcher Quick Reference Card

**Version:** 2.2.0 | **Updated:** 2026-01-11

---

## Essential Commands

| Command | Purpose | Time |
|---------|---------|------|
| `dot` | Show status + actions | < 500ms |
| `dot edit FILE` | Edit with preview | instant |
| `dot sync` | Pull from remote | 1-3s |
| `dot push` | Push to remote | 1-3s |
| `dot unlock` | Unlock secrets (15m session) | 2-5s |
| `dot secret NAME` | Get secret | < 200ms |
| `dot secrets` | Dashboard of all secrets | < 1s |
| `dot token github` | GitHub PAT wizard | 1-2 min |
| `dot token <name> --refresh` | Rotate token | 1-2 min |

---

## Common Workflows

### 1. Edit Dotfile (30 sec)

```bash
dot                # Check status
dot edit .zshrc    # Edit → Preview → Apply
```

### 2. Sync from Remote (10 sec)

```bash
dot sync           # Pull → Preview → Apply
dot apply          # If needed
```

### 3. Push Changes (30 sec)

```bash
dot diff           # Review changes
dot push           # Commit + push
```

### 4. Use Secret (1 min)

```bash
dot unlock                    # Unlock vault
TOKEN=$(dot secret api-key)   # Capture secret
```

### 5. Create Token (2 min)

```bash
dot token github              # Run wizard
# → Select type (classic/fine-grained)
# → Open browser, paste token
# → Validates and stores with expiration
```

### 6. Rotate Token (1 min)

```bash
dot token github-token --refresh
# → Opens browser for new token
# → Validates and updates
# → Reminds to revoke old token
```

### 7. Sync to CI/CD (1 min)

```bash
dot secrets sync github       # Select secrets → sync to repo
dot env init                  # Generate .envrc for direnv
```

### 8. Edit Template (2 min)

```bash
dot unlock                    # Unlock vault
dot edit .gitconfig           # Edit template
# Add: {{ bitwarden "item" "github-token" }}
# Apply → ~/.gitconfig has actual token
```

---

## Status Icons

| Icon | State | Action |
|------|-------|--------|
| 🟢 | Synced | `dot edit .zshrc` |
| 🟡 | Modified | `dot push` |
| 🔴 | Behind | `dot sync` |
| 🔵 | Ahead | `dot push` |

---

## Command Aliases

| Full Command | Alias | Example |
|--------------|-------|---------|
| `dot status` | `dot s` | `dot s` |
| `dot edit FILE` | `dot e FILE` | `dot e zshrc` |
| `dot diff` | `dot d` | `dot d` |
| `dot apply` | `dot a` | `dot a` |
| `dot push` | `dot p` | `dot p` |
| `dot unlock` | `dot u` | `dot u` |
| `dot lock` | `dot l` | `dot l` |
| `dot doctor` | `dot dr` | `dot dr` |
| `dot token github` | `dot token gh` | `dot token gh` |
| `dot token pypi` | `dot token pip` | `dot token pip` |
| `dot token <n> --refresh` | `dot token <n> -r` | `dot token gh-token -r` |

---

## Fuzzy File Matching

```bash
# All of these work:
dot edit .zshrc
dot edit zshrc
dot edit zsh
dot edit .config/zsh/.zshrc

# Chezmoi finds the right file
```

---

## Secret Management (v5.2.0)

### Quick Reference

```bash
# Unlock (15-min session cache)
dot unlock

# List items
dot secret list

# Get secret (no echo)
TOKEN=$(dot secret github-token)

# Add a secret with expiration
dot secret add api-key --expires 90

# Check expiring tokens
dot secret check

# View all secrets dashboard
dot secrets
```

### Token Wizards

```bash
# Create tokens with guided wizards
dot token github              # GitHub PAT
dot token npm                 # NPM token
dot token pypi                # PyPI token

# Rotate existing token
dot token github-token --refresh
dot token npm-token -r        # Short flag
```

### CI/CD Integration

```bash
# Sync secrets to GitHub repo secrets
dot secrets sync github

# Generate .envrc for direnv
dot env init
```

### Template Syntax

```bash
# In chezmoi template file
{{ bitwarden "item" "github-token" }}

# Custom field
{{ bitwardenFields "item" "api-key" "custom-field" }}

# Secure note
{{ bitwardenFields "item" "ssh-key" "notes" }}
```

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Not initialized" | `chezmoi init` |
| "Vault locked" | `dot unlock` |
| "Item not found" | `dot secret list` |
| "Session expired" | `dot unlock` (15-min cache) |
| Token expiring | `dot token <name> --refresh` |
| Changes not applied | `dot apply` |
| Session in history | Auto-prevented by HISTIGNORE |

---

## Security Checklist

### ✅ DO

- Run `dot unlock` per-session
- Use `VAR=$(dot secret name)` to capture
- Run `bw lock` when done
- Store templates, not plain secrets

### ❌ DON'T

- Export BW_SESSION to .zshrc
- Commit files with actual secrets
- Echo secrets to terminal
- Share session tokens

---

## Dashboard & Doctor

### Dashboard Line

```
📝 Dotfiles: 🟢 Synced (2h ago) · 12 files tracked
```

**Performance:** < 100ms

### Doctor Checks

```bash
flow doctor
# ✓ chezmoi installed
# ✓ Bitwarden CLI installed
# ✓ Remote configured
# ✓ No uncommitted changes
```

---

## Installation

```bash
# Tools
brew install chezmoi bitwarden-cli jq

# Initialize
chezmoi init

# Or clone existing
chezmoi init https://github.com/user/dotfiles

# Authenticate Bitwarden
bw login
```

---

## File Structure

```
~/.local/share/chezmoi/          # Source (templates)
├── .git/                        # Git repo
├── dot_zshrc.tmpl               # Template
└── dot_gitconfig.tmpl           # Template

~/                               # Applied files
├── .zshrc                       # Generated
└── .gitconfig                   # Generated
```

---

## Naming Convention

| Prefix | Result | Example |
|--------|--------|---------|
| `dot_` | Adds `.` | `dot_zshrc` → `.zshrc` |
| `.tmpl` | Template | `dot_gitconfig.tmpl` |
| `private_` | 0600 | `private_env.sh` |
| `executable_` | 0755 | `executable_script.sh` |

---

## See Also

- **Full Reference:** [DOT-DISPATCHER-REFERENCE.md](./DOT-DISPATCHER-REFERENCE.md)
- **Guide:** [DOTFILE-MANAGEMENT.md](../guides/DOTFILE-MANAGEMENT.md)
- **Secrets:** [SECRET-MANAGEMENT.md](../SECRET-MANAGEMENT.md)
- **Chezmoi:** https://www.chezmoi.io/
- **Bitwarden:** https://bitwarden.com/help/cli/
