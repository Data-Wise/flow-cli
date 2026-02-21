---
tags:
  - tutorial
  - dispatchers
  - configuration
---

# Tutorial: Dotfile, Secret & Token Management (dots/sec/tok)

**Level:** Beginner
**Time:** 30 minutes
**Prerequisites:** chezmoi installed (`brew install chezmoi`)

---

## What You'll Learn

By the end of this tutorial, you'll know how to:

- ✅ Set up chezmoi and track your first dotfile
- ✅ Edit dotfiles with automatic change detection
- ✅ Sync dotfiles across multiple machines
- ✅ Use dry-run mode to preview changes safely
- ✅ **Store secrets in macOS Keychain** (Touch ID, instant access)
- ✅ **Import secrets from Bitwarden** to Keychain
- ✅ Manage cloud secrets with Bitwarden (team sharing)
- ✅ Create tokens with guided wizards (GitHub, NPM, PyPI)
- ✅ Rotate tokens safely with `--refresh`
- ✅ Sync secrets to GitHub Actions

---

## Prerequisites

```bash
# Install chezmoi (dotfile manager)
brew install chezmoi

# Initialize chezmoi (first time only)
chezmoi init

# Optional: Bitwarden CLI for secret management
brew install bitwarden-cli
```diff

---

## Part 1: Getting Started

### Understanding the dots/sec/tok Dispatchers

The `dots` dispatcher (and its siblings `sec` and `tok`) is a wrapper around chezmoi that provides:

- **Quick status checks** - See dotfile state at a glance
- **Safe editing** - Preview changes before applying
- **Hash-based detection** - Catches all edits, even quick ones
- **Bitwarden integration** - Manage secrets securely

### Check Your Status

```bash
dots
```text

**Output when chezmoi is not initialized:**

```text
╭───────────────────────────────────────────────────╮
│  📁 Dotfiles Status                                │
├───────────────────────────────────────────────────┤
│  State: ⚪ Not initialized                        │
│                                                   │
│  Initialize chezmoi:                              │
│    chezmoi init                                   │
╰───────────────────────────────────────────────────╯
```text

**Output when chezmoi is ready:**

```text
╭───────────────────────────────────────────────────╮
│  📁 Dotfiles Status                                │
├───────────────────────────────────────────────────┤
│  State: 🟢 Synced                                 │
│  Last sync: 2 hours ago                           │
│  Tracked files: 12                                │
│                                                   │
│  Quick actions:                                   │
│    dots edit .zshrc    Edit shell config           │
│    dots sync           Pull latest changes         │
│    dots help           Show all commands           │
╰───────────────────────────────────────────────────╯
```bash

---

## Part 2: Tracking Your First Dotfile

### Step 1: Add a File to Chezmoi

Before you can use `dots edit`, the file must be tracked by chezmoi:

```bash
# Add your shell config to chezmoi
chezmoi add ~/.zshrc
```text

This copies `~/.zshrc` to chezmoi's source directory (`~/.local/share/chezmoi/`).

### Step 2: Edit the File

```bash
dots edit .zshrc
```text

**What happens:**

1. Opens your `$EDITOR` with the **source file** in chezmoi's directory
2. You make changes and save
3. Hash-based detection determines if anything changed
4. If changed, shows diff and prompts for action

**Example session:**

```diff
ℹ Opening in vim: dot_zshrc

[Editor opens, you make changes, save and exit]

✓ Changes detected!
───────────────────────────────────────────
@@ -10,6 +10,7 @@
 export PATH=$HOME/bin:$PATH
+export MY_NEW_VAR="hello"
───────────────────────────────────────────

ℹ Apply changes?
  y - Apply now
  d - Show detailed diff
  n - Keep in staging

Apply? [Y/n/d]
```diff

**Options:**
- **y** (or Enter) - Apply changes to your actual `~/.zshrc`
- **d** - Show full diff, then ask again
- **n** - Keep changes in chezmoi source (not applied yet)

### Step 3: Apply Changes Later

If you pressed 'n' during edit, the changes are in chezmoi's source but not yet applied to your home directory.

```bash
# See what would change
dots diff

# Apply all pending changes
dots apply
```text

---

## Part 3: Dry-Run Mode

### Preview Without Applying

The `--dry-run` flag (or `-n`) shows what would change without actually modifying files.

```bash
dots apply --dry-run
```text

**Output when nothing to apply:**

```text
ℹ DRY-RUN MODE - No changes will be applied

✓ No pending changes
```text

**Output when changes are pending:**

```bash
ℹ DRY-RUN MODE - No changes will be applied

ℹ Showing what would change (dry-run)...
[chezmoi verbose diff output]

✓ Dry-run complete - no changes applied
```diff

### When to Use Dry-Run

- ✅ After pulling updates from another machine
- ✅ Before applying template changes with secrets
- ✅ To verify changes look correct

---

## Part 4: Sync Across Machines

### Initial Setup (First Machine)

```bash
# Initialize with a git repo
chezmoi init https://github.com/username/dotfiles.git

# Add files
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig

# Commit and push
dots push
```bash

### On Other Machines

```bash
# Clone your dotfiles
chezmoi init https://github.com/username/dotfiles.git

# Apply to this machine
dots apply
```text

### Daily Sync Pattern

**Pull changes from remote:**

```bash
dots sync
```text

**Output:**

```text
ℹ Fetching from remote...

ℹ Remote has updates:
abc1234 Add new alias
def5678 Update git config

Apply updates? [Y/n/d]
```text

**Push your changes:**

```bash
dots push
```text

**Output:**

```text
ℹ Staging changes...
ℹ Committing...

Commit message: [enter your message]

✓ Pushed to remote
```diff

---

## Part 5: macOS Keychain Secrets (v5.5.0)

The recommended way to manage secrets is using macOS Keychain. It provides:

- ⚡ **Instant access** - No unlock step needed
- 🍎 **Touch ID / Apple Watch** - Biometric authentication
- 🔒 **Auto-lock** - Locks with screen lock
- 📡 **Works offline** - No internet required

### Store a Secret

```bash
sec add github-token
```text

**Output:**

```text
Enter secret value: [hidden input]

✓ Secret 'github-token' stored in Keychain
```bash

### Retrieve a Secret

```bash
# Get a secret (Touch ID prompt may appear)
TOKEN=$(sec github-token)

# Use in a command
gh auth login --with-token <<< $(sec github-token)
```text

### List Keychain Secrets

```bash
sec list
```text

**Output:**

```text
ℹ Secrets in Keychain (flow-cli):
  • github-token
  • npm-token
  • anthropic-api-key
```text

### Delete a Secret

```bash
sec delete old-token
```text

**Output:**

```text
✓ Secret 'old-token' deleted
```bash

### Import from Bitwarden (One-Time Migration)

If you have secrets in Bitwarden, you can import them to Keychain:

```bash
# Unlock Bitwarden first
sec unlock

# Import all secrets from 'flow-cli-secrets' folder
sec import
```text

**Output:**

```text
ℹ Import secrets from Bitwarden folder 'flow-cli-secrets'?
Continue? [y/N] y

✓ Imported: github-token
✓ Imported: npm-token
✓ Imported: anthropic-api-key

✓ Imported 3 secret(s) to Keychain
```bash

After import, secrets are in Keychain and no longer need Bitwarden unlock.

---

## Part 6: Bitwarden Cloud Secrets (Alternative)

If you need cloud-synced secrets (team sharing, multiple devices), use Bitwarden:

### Prerequisites

```bash
brew install bitwarden-cli

# Login (first time)
bw login
```text

### Unlock Vault

```bash
sec unlock
```text

**Output:**

```bash
ℹ Enter your Bitwarden master password:
[password prompt]

✓ Vault unlocked successfully

  Session active in this shell only
ℹ Use 'sec <name>' to retrieve secrets
```text

### List Secrets

```bash
sec list
```text

**Output:**

```text
ℹ Retrieving items from vault...

🔑 github-token (Work/GitHub)
🔑 npm-token (Work/Node)
🔑 anthropic-api-key (AI/Keys)
📝 ssh-passphrase (SSH)

ℹ Usage: sec <name>
```bash

### Retrieve a Secret

```bash
# Retrieve without echo (secure)
TOKEN=$(sec github-token)

# Use in a command
curl -H "Authorization: Bearer $TOKEN" https://api.github.com/user
```sql

### Using Secrets in Templates

Create a template file in chezmoi:

**File:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# API Keys (from Bitwarden)
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-api-key" }}"
```bash

**Apply with secrets:**

```bash
# Unlock vault first
sec unlock

# Preview (dry-run)
dots apply --dry-run

# Apply for real
dots apply
```text

---

## Part 7: Token Management (v5.2.0)

### Create a GitHub Token

The token wizard guides you through creating properly-scoped tokens:

```bash
tok github
```text

**Example session:**

```sql
🧙 GitHub Token Wizard

Select token type:
  1. Classic Personal Access Token
  2. Fine-grained Token (recommended)

Choice [1/2]: 2

ℹ Opening GitHub token creation page...
  [Browser opens to github.com/settings/tokens]

Paste your new token: ghp_xxxxxxxxxxxx

✓ Token validated successfully!
  User: username
  Scopes: repo, workflow

ℹ Setting expiration...
  Expires: 2026-04-10 (90 days)

✓ Stored as 'github-token' in Bitwarden

💡 Tip: tok github-token --refresh to rotate later
```text

### Check Token Expiration

```bash
sec dashboard
```text

**Output:**

```text
╭───────────────────────────────────────────────────────────────╮
│  🔐 Secrets Dashboard                                          │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  🔑 github-token                                              │
│     Expires: 2026-04-10 (89 days)                            │
│     Scopes: repo, workflow                                    │
│                                                               │
│  🔑 npm-token                                                 │
│     Expires: 2026-07-10 (180 days)                           │
│     Type: automation                                          │
│                                                               │
│  ⚠️  pypi-token                                               │
│     Expires: 2026-01-20 (9 days) ← EXPIRING SOON             │
│     Scope: project:mypackage                                  │
│                                                               │
╰───────────────────────────────────────────────────────────────╯
```text

### Rotate an Expiring Token

```bash
tok pypi-token --refresh
```text

**Example session:**

```bash
🔄 Rotating token: pypi-token

ℹ Current token expires: 2026-01-20 (9 days)

ℹ Opening PyPI token creation page...
  [Browser opens to pypi.org/manage/account/token/]

Paste your new token: pypi-xxxxxxxx

✓ Token validated!
  Scope: project:mypackage

✓ Updated 'pypi-token' in Bitwarden
  New expiration: 2026-04-10 (90 days)

⚠️  Remember to revoke the old token at:
   https://pypi.org/manage/account/token/
```text

### Sync to GitHub Actions

Push secrets to your repository for CI/CD:

```bash
sec sync github
```text

**Example session:**

```sql
ℹ Syncing secrets to: Data-Wise/flow-cli

Select secrets to sync:
  [x] GITHUB_TOKEN
  [x] NPM_TOKEN
  [ ] PYPI_TOKEN

Sync 2 secrets? [Y/n] y

✓ Synced GITHUB_TOKEN
✓ Synced NPM_TOKEN

✓ 2 secrets synced to repository
```text

### Generate .envrc for Local Development

```bash
dots env
```text

**Output:**

```bash
✓ Generated .envrc with 3 secrets

  Contents:
  ─────────────────────────────────
  export GITHUB_TOKEN="$(sec github-token)"
  export NPM_TOKEN="$(sec npm-token)"
  export ANTHROPIC_API_KEY="$(sec anthropic-api-key)"
  ─────────────────────────────────

💡 Run 'direnv allow' to activate
```text

---

## Part 8: Error Handling

### Common Errors

**File not tracked:**

```text
✗ File not found in managed dotfiles: .zshrc
ℹ Use 'chezmoi add <file>' to start tracking a new file
```text

**Vault locked:**

```text
✗ Bitwarden vault is locked
ℹ Run: sec unlock
```text

**Secret not found:**

```text
✗ Secret not found: wrong-name
Tip: Use 'sec list' to see available items
```text

**Session expired:**

```text
✗ Session expired
Run: sec unlock
```text

---

## Quick Reference

### Core Commands

```bash
dots                 # Show status
dots edit <file>      # Edit dotfile (preview + apply)
dots diff             # Show pending changes
dots apply            # Apply pending changes
dots apply --dry-run  # Preview what would change
```text

### Sync Commands

```bash
dots sync             # Pull from remote
dots push             # Push to remote
```text

### Keychain Secrets (v5.5.0 - Recommended)

```bash
sec add <name>       # Store secret in Keychain
sec <name>           # Get secret (Touch ID)
sec list             # List Keychain secrets
sec delete <name>    # Remove secret
sec import           # Import from Bitwarden
```text

### Bitwarden Secrets (Cloud)

```bash
sec unlock           # Unlock Bitwarden vault
sec bw <name> # Get Bitwarden secret
sec dashboard          # Dashboard with expiration
```text

### Token Commands (v5.2.0)

```bash
tok github              # GitHub PAT wizard
tok npm                 # NPM token wizard
tok pypi                # PyPI token wizard
tok rotate NAME    # Rotate existing token
sec sync github       # Sync to GitHub Actions
dots env                  # Generate .envrc for direnv
```text

### Troubleshooting

```bash
dots doctor           # Run diagnostics
dots help             # Show all commands
```

---

## Best Practices

1. **Always check status first** - Run `dots` before making changes
2. **Use dry-run** - Preview before applying, especially with templates
3. **Small commits** - One logical change per push
4. **Lock vault when done** - Run `bw lock` after using secrets
5. **Never commit secrets** - Use templates, not plain text

---

## Next Steps

1. **Set up chezmoi:** `chezmoi init`
2. **Add your first file:** `chezmoi add ~/.zshrc`
3. **Try editing:** `dots edit .zshrc`
4. **Set up remote:** Push to GitHub for cross-machine sync
5. **Add secrets:** Store API keys in Bitwarden, use templates

### Further Reading

- [Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#dots-dispatcher) - Full command reference
- [Chezmoi Documentation](https://www.chezmoi.io/) - Official chezmoi docs
- [Bitwarden CLI](https://bitwarden.com/help/cli/) - Bitwarden CLI reference

---

**Version:** v5.5.0
**Last Updated:** 2026-01-13
