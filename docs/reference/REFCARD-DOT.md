# Dot Dispatcher Quick Reference Card

**Version:** 1.2.0 | **Updated:** 2026-01-09

---

## Essential Commands

| Command | Purpose | Time |
|---------|---------|------|
| `dot` | Show status + actions | < 500ms |
| `dot edit FILE` | Edit with preview | instant |
| `dot sync` | Pull from remote | 1-3s |
| `dot push` | Push to remote | 1-3s |
| `dot unlock` | Unlock secrets | 2-5s |
| `dot secret NAME` | Get secret | < 200ms |

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

### 5. Edit Template (2 min)

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
| `dot doctor` | `dot dr` | `dot dr` |

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

## Bitwarden Secrets

### Quick Reference

```bash
# Unlock (per-session)
dot unlock

# List items
dot secret list

# Get secret (no echo)
TOKEN=$(dot secret github-token)

# Use in command
curl -H "Authorization: Bearer $(dot secret api-key)" https://api.example.com
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
