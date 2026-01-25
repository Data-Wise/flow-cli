# Dotfile Management Workflow

**Level:** Beginner to Intermediate
**Time:** 15 minutes
**Goal:** Master dotfile management with chezmoi and the DOT dispatcher

---

## Quick Start

```bash
# Check status
dot

# Edit a dotfile (must be tracked first)
dot edit .zshrc

# Pull updates from remote
dot sync

# Push your changes
dot push
```

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
```

### Optional: Bitwarden (for secrets)

```bash
brew install bitwarden-cli
bw login
```

---

## Workflow 1: Quick Edit

Edit a dotfile with preview and apply workflow.

### Steps

```bash
# 1. Edit (opens $EDITOR with source file)
dot edit .zshrc
```

**Output:**

```
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
```

**Options:**

| Key | Action |
|-----|--------|
| **y** | Apply changes to `~/.zshrc` now |
| **d** | Show full diff, then prompt again |
| **n** | Keep in chezmoi source (apply later with `dot apply`) |

### Apply Later

If you pressed 'n', changes are in chezmoi but not yet in your home directory:

```bash
# See pending changes
dot diff

# Apply all pending
dot apply

# Preview first
dot apply --dry-run
```

---

## Workflow 2: Dry-Run Preview

Preview changes without applying them.

```bash
dot apply --dry-run
# or
dot apply -n
```

**Output (no changes):**

```
ℹ DRY-RUN MODE - No changes will be applied

✓ No pending changes
```

**Output (with changes):**

```
ℹ DRY-RUN MODE - No changes will be applied

ℹ Showing what would change (dry-run)...
[chezmoi verbose diff]

✓ Dry-run complete - no changes applied
```

### When to Use

- After `dot sync` to see incoming changes
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
dot push
```

### On Other Machines

```bash
# Clone and initialize
chezmoi init https://github.com/user/dotfiles.git

# Apply dotfiles
dot apply
```

### Daily Sync

```bash
# Pull from remote
dot sync

# Output if updates exist:
# ℹ Fetching from remote...
# ℹ Remote has updates:
# abc1234 Add new alias
# Apply updates? [Y/n/d]

# Push local changes
dot push
```

---

## Workflow 4: Secret Management

### Choose Your Backend

| Feature | macOS Keychain (v5.5.0) | Bitwarden |
|---------|-------------------------|-----------|
| Speed | < 50ms | 2-5s |
| Auth | Touch ID | Master password |
| Unlock | Auto with screen | Manual (`dot unlock`) |
| Best for | Local dev, scripts | Cross-device sync |
| Setup | None (built-in) | Install + login |

### Option A: macOS Keychain (Recommended for Local Dev)

```bash
# Store a secret (Touch ID protected)
dot secret add github-token
> Enter secret value: ••••••••
✓ Secret 'github-token' stored in Keychain

# Retrieve (instant, Touch ID prompt)
TOKEN=$(dot secret github-token)

# List all secrets
dot secret list

# Delete when done
dot secret delete github-token
```

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
dot unlock
```

**Store Secrets:**

1. Open Bitwarden app or web vault
2. Create Login item with name like `github-token`
3. Put secret in password field
4. Save

**Retrieve Secrets:**

```bash
# List available secrets
dot secret list

# Output:
# ℹ Retrieving items from vault...
# 🔑 github-token (Work/GitHub)
# 🔑 anthropic-api-key (AI/Keys)

# Retrieve (no echo)
TOKEN=$(dot secret github-token)
```

### Use in Templates

**Create template:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# Regular content
export PATH=$HOME/bin:$PATH

# Secrets from Bitwarden
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
```

**Apply with secrets:**

```bash
dot unlock
dot apply --dry-run  # Preview
dot apply            # Apply
```

---

## Workflow 5: Token Management (v5.2.0)

### Create Tokens with Wizards

```bash
# GitHub Personal Access Token
dot token github

# NPM automation token
dot token npm

# PyPI project token
dot token pypi
```

**Wizard output:**

```
🧙 GitHub Token Wizard

Select token type:
  1. Classic Personal Access Token
  2. Fine-grained Token (recommended)

Choice [1/2]: 2

ℹ Opening GitHub token creation page...

Paste your new token: ghp_xxxxxxxxxxxx

✓ Token validated!
✓ Stored as 'github-token' in Bitwarden
```

### Check Token Status

```bash
dot secrets
```

**Dashboard output:**

```
╭───────────────────────────────────────────────────────────────╮
│  🔐 Secrets Dashboard                                          │
├───────────────────────────────────────────────────────────────┤
│  🔑 github-token       Expires: 89 days                       │
│  🔑 npm-token          Expires: 180 days                      │
│  ⚠️  pypi-token         Expires: 9 days  ← EXPIRING SOON      │
╰───────────────────────────────────────────────────────────────╯
```

### Rotate Expiring Tokens

```bash
# Rotate a specific token
dot token pypi-token --refresh

# Short form
dot token pypi-token -r
```

**Rotation output:**

```
🔄 Rotating token: pypi-token

ℹ Opening PyPI token creation page...

Paste your new token: pypi-xxxxxxxx

✓ Token validated!
✓ Updated in Bitwarden

⚠️  Remember to revoke old token at:
   https://pypi.org/manage/account/token/
```

---

## Workflow 6: CI/CD Integration (v5.2.0)

### Sync Secrets to GitHub Actions

```bash
dot secrets sync github
```

**Output:**

```
ℹ Syncing secrets to: Data-Wise/flow-cli

Select secrets to sync:
  [x] GITHUB_TOKEN
  [x] NPM_TOKEN
  [ ] PYPI_TOKEN

✓ 2 secrets synced to repository
```

### Generate .envrc for direnv

```bash
dot env init
```

**Output:**

```
✓ Generated .envrc with 3 secrets

  Contents:
  ─────────────────────────────
  export GITHUB_TOKEN="$(dot secret github-token)"
  export NPM_TOKEN="$(dot secret npm-token)"
  ─────────────────────────────

💡 Run 'direnv allow' to activate
```

---

## Common Patterns

### Quick Config Change

```bash
dot edit .gitconfig  # Edit, apply immediately
```

### Safe Batch Changes

```bash
dot edit .zshrc      # Press 'n' to defer
dot edit .gitconfig  # Press 'n' to defer
dot diff             # Review all
dot apply --dry-run  # Preview
dot apply            # Apply all
```

### Emergency Rollback

```bash
# Restore from chezmoi source
chezmoi apply --force

# Or revert chezmoi source to remote
cd ~/.local/share/chezmoi
git checkout -- .
dot apply
```

---

## Error Handling

### File Not Tracked

```
✗ File not found in managed dotfiles: .zshrc
ℹ Use 'chezmoi add <file>' to start tracking a new file
```

**Fix:** `chezmoi add ~/.zshrc`

### Vault Locked

```
✗ Bitwarden vault is locked
ℹ Run: dot unlock
```

**Fix:** `dot unlock`

### Session Expired

```
✗ Session expired
Run: dot unlock
```

**Fix:** `dot unlock` (re-enter master password)

---

## Command Reference

| Command | Description |
|---------|-------------|
| `dot` | Show status |
| `dot edit <file>` | Edit with preview |
| `dot diff` | Show pending changes |
| `dot apply` | Apply pending changes |
| `dot apply -n` | Dry-run preview |
| `dot sync` | Pull from remote |
| `dot push` | Push to remote |
| `dot unlock` | Unlock Bitwarden (15-min session) |
| `dot secret <name>` | Retrieve secret |
| `dot secret list` | List secrets |
| `dot secrets` | Dashboard with expiration |
| `dot token github` | GitHub PAT wizard |
| `dot token npm` | NPM token wizard |
| `dot token pypi` | PyPI token wizard |
| `dot token <n> --refresh` | Rotate existing token |
| `dot secrets sync github` | Sync to GitHub Actions |
| `dot env init` | Generate .envrc |
| `dot doctor` | Run diagnostics |
| `dot help` | Show help |

---

## Best Practices

1. **Track files first** - `chezmoi add` before `dot edit`
2. **Use dry-run** - Preview before applying templates
3. **Small commits** - One logical change per `dot push`
4. **Lock vault** - `bw lock` when done with secrets
5. **Check status** - Run `dot` to see current state

---

**Version:** v5.2.0
**See Also:** [DOT Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#dot-dispatcher) | [Tutorial](../tutorials/12-dot-dispatcher.md)
