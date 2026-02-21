---
tags:
  - guide
  - configuration
---

# Dotfile Management Workflow

**Level:** Beginner to Intermediate
**Time:** 15 minutes
**Goal:** Master dotfile management with chezmoi and the dots/sec/tok dispatchers

---

## Quick Start

```bash
# Check status
dots

# Edit a dotfile (must be tracked first)
dots edit .zshrc

# Pull updates from remote
dots sync

# Push your changes
dots push
```bash

---

## Prerequisites

### Required: Chezmoi

```bash
# Install
brew install chezmoi

# Initialize (creates ~/.local/share/chezmoi/)
chezmoi init

# Track your first file
chezmoi add ~/.zshrc
```bash

### Optional: Bitwarden (for secrets)

```bash
brew install bitwarden-cli
bw login
```bash

---

## Workflow 1: Quick Edit

Edit a dotfile with preview and apply workflow.

### Steps

```bash
# 1. Edit (opens $EDITOR with source file)
dots edit .zshrc
```text

**Output:**

```diff
ℹ Opening in vim: dot_zshrc

[Make changes, save, exit editor]

✓ Changes detected!
───────────────────────────────────────────
@@ -5,0 +6 @@
+export NEW_VAR="test"
───────────────────────────────────────────

ℹ Apply changes?
  y - Apply now
  d - Show detailed diff
  n - Keep in staging

Apply? [Y/n/d]
```bash

**Options:**

| Key | Action |
|-----|--------|
| **y** | Apply changes to `~/.zshrc` now |
| **d** | Show full diff, then prompt again |
| **n** | Keep in chezmoi source (apply later with `dots apply`) |

### Apply Later

If you pressed 'n', changes are in chezmoi but not yet in your home directory:

```bash
# See pending changes
dots diff

# Apply all pending
dots apply

# Preview first
dots apply --dry-run
```bash

---

## Workflow 2: Dry-Run Preview

Preview changes without applying them.

```bash
dots apply --dry-run
# or
dots apply -n
```text

**Output (no changes):**

```text
ℹ DRY-RUN MODE - No changes will be applied

✓ No pending changes
```text

**Output (with changes):**

```bash
ℹ DRY-RUN MODE - No changes will be applied

ℹ Showing what would change (dry-run)...
[chezmoi verbose diff]

✓ Dry-run complete - no changes applied
```diff

### When to Use

- After `dots sync` to see incoming changes
- Before applying templates with secrets
- To verify changes are correct

---

## Workflow 3: Cross-Machine Sync

### First Machine Setup

```bash
# Initialize with remote
chezmoi init https://github.com/user/dotfiles.git

# Add files
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig
chezmoi add ~/.tmux.conf

# Push to remote
dots push
```bash

### On Other Machines

```bash
# Clone and initialize
chezmoi init https://github.com/user/dotfiles.git

# Apply dotfiles
dots apply
```bash

### Daily Sync

```bash
# Pull from remote
dots sync

# Output if updates exist:
# ℹ Fetching from remote...
# ℹ Remote has updates:
# abc1234 Add new alias
# Apply updates? [Y/n/d]

# Push local changes
dots push
```bash

---

## Workflow 4: Secret Management

### Choose Your Backend

| Feature | macOS Keychain (v5.5.0) | Bitwarden |
|---------|-------------------------|-----------|
| Speed | < 50ms | 2-5s |
| Auth | Touch ID | Master password |
| Unlock | Auto with screen | Manual (`sec unlock`) |
| Best for | Local dev, scripts | Cross-device sync |
| Setup | None (built-in) | Install + login |

### Option A: macOS Keychain (Recommended for Local Dev)

```bash
# Store a secret (Touch ID protected)
sec add github-token
> Enter secret value: ••••••••
✓ Secret 'github-token' stored in Keychain

# Retrieve (instant, Touch ID prompt)
TOKEN=$(sec github-token)

# List all secrets
sec list

# Delete when done
sec delete github-token
```diff

**Perfect for:**
- Shell startup scripts (instant, no unlock)
- Local development tokens
- API keys you use frequently

### Option B: Bitwarden (For Cross-Device Sync)

```bash
# Install CLI
brew install bitwarden-cli

# Login (first time)
bw login

# Unlock vault (each shell session)
sec unlock
```bash

**Store Secrets:**

1. Open Bitwarden app or web vault
2. Create Login item with name like `github-token`
3. Put secret in password field
4. Save

**Retrieve Secrets:**

```bash
# List available secrets
sec list

# Output:
# ℹ Retrieving items from vault...
# 🔑 github-token (Work/GitHub)
# 🔑 anthropic-api-key (AI/Keys)

# Retrieve (no echo)
TOKEN=$(sec github-token)
```bash

### Use in Templates

**Create template:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# Regular content
export PATH=$HOME/bin:$PATH

# Secrets from Bitwarden
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
```text

**Apply with secrets:**

```bash
sec unlock
dots apply --dry-run  # Preview
dots apply            # Apply
```bash

---

## Workflow 5: Token Management (v5.2.0)

### Create Tokens with Wizards

```bash
# GitHub Personal Access Token
tok github

# NPM automation token
tok npm

# PyPI project token
tok pypi
```text

**Wizard output:**

```sql
🧙 GitHub Token Wizard

Select token type:
  1. Classic Personal Access Token
  2. Fine-grained Token (recommended)

Choice [1/2]: 2

ℹ Opening GitHub token creation page...

Paste your new token: ghp_xxxxxxxxxxxx

✓ Token validated!
✓ Stored as 'github-token' in Bitwarden
```text

### Check Token Status

```bash
secs
```text

**Dashboard output:**

```text
╭───────────────────────────────────────────────────────────────╮
│  🔐 Secrets Dashboard                                          │
├───────────────────────────────────────────────────────────────┤
│  🔑 github-token       Expires: 89 days                       │
│  🔑 npm-token          Expires: 180 days                      │
│  ⚠️  pypi-token         Expires: 9 days  ← EXPIRING SOON      │
╰───────────────────────────────────────────────────────────────╯
```bash

### Rotate Expiring Tokens

```bash
# Rotate a specific token
tok pypi-token --refresh

# Short form
tok pypi-token -r
```text

**Rotation output:**

```text
🔄 Rotating token: pypi-token

ℹ Opening PyPI token creation page...

Paste your new token: pypi-xxxxxxxx

✓ Token validated!
✓ Updated in Bitwarden

⚠️  Remember to revoke old token at:
   https://pypi.org/manage/account/token/
```text

---

## Workflow 6: CI/CD Integration (v5.2.0)

### Sync Secrets to GitHub Actions

```bash
sec sync github
```text

**Output:**

```sql
ℹ Syncing secrets to: Data-Wise/flow-cli

Select secrets to sync:
  [x] GITHUB_TOKEN
  [x] NPM_TOKEN
  [ ] PYPI_TOKEN

✓ 2 secrets synced to repository
```text

### Generate .envrc for direnv

```bash
dots env
```text

**Output:**

```bash
✓ Generated .envrc with 3 secrets

  Contents:
  ─────────────────────────────
  export GITHUB_TOKEN="$(sec github-token)"
  export NPM_TOKEN="$(sec npm-token)"
  ─────────────────────────────

💡 Run 'direnv allow' to activate
```text

---

## Common Patterns

### Quick Config Change

```bash
dots edit .gitconfig  # Edit, apply immediately
```text

### Safe Batch Changes

```bash
dots edit .zshrc      # Press 'n' to defer
dots edit .gitconfig  # Press 'n' to defer
dots diff             # Review all
dots apply --dry-run  # Preview
dots apply            # Apply all
```bash

### Emergency Rollback

```bash
# Restore from chezmoi source
chezmoi apply --force

# Or revert chezmoi source to remote
cd ~/.local/share/chezmoi
git checkout -- .
dots apply
```text

---

## Error Handling

### File Not Tracked

```text
✗ File not found in managed dotfiles: .zshrc
ℹ Use 'chezmoi add <file>' to start tracking a new file
```text

**Fix:** `chezmoi add ~/.zshrc`

### Vault Locked

```text
✗ Bitwarden vault is locked
ℹ Run: sec unlock
```text

**Fix:** `sec unlock`

### Session Expired

```text
✗ Session expired
Run: sec unlock
```

**Fix:** `sec unlock` (re-enter master password)

---

## Command Reference

| Command | Description |
|---------|-------------|
| `dots` | Show status |
| `dots edit <file>` | Edit with preview |
| `dots diff` | Show pending changes |
| `dots apply` | Apply pending changes |
| `dots apply -n` | Dry-run preview |
| `dots sync` | Pull from remote |
| `dots push` | Push to remote |
| `sec unlock` | Unlock Bitwarden (15-min session) |
| `sec <name>` | Retrieve secret |
| `sec list` | List secrets |
| `sec dashboard` | Dashboard with expiration |
| `tok github` | GitHub PAT wizard |
| `tok npm` | NPM token wizard |
| `tok pypi` | PyPI token wizard |
| `tok rotate NAME` | Rotate existing token |
| `sec sync github` | Sync to GitHub Actions |
| `dots env` | Generate .envrc |
| `dots doctor` | Run diagnostics |
| `dots help` | Show help |

---

## Best Practices

1. **Track files first** - `chezmoi add` before `dots edit`
2. **Use dry-run** - Preview before applying templates
3. **Small commits** - One logical change per `dots push`
4. **Lock vault** - `bw lock` when done with secrets
5. **Check status** - Run `dots` to see current state

---

**Version:** v5.2.0
**See Also:** [Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#dots-dispatcher) | [Tutorial](../tutorials/12-dot-dispatcher.md)
