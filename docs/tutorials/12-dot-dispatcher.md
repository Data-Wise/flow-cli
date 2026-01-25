# Tutorial: DOT Dispatcher - Dotfile Management

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
```

---

## Part 1: Getting Started

### Understanding the DOT Dispatcher

The `dot` dispatcher is a wrapper around chezmoi that provides:

- **Quick status checks** - See dotfile state at a glance
- **Safe editing** - Preview changes before applying
- **Hash-based detection** - Catches all edits, even quick ones
- **Bitwarden integration** - Manage secrets securely

### Check Your Status

```bash
dot
```

**Output when chezmoi is not initialized:**

```
╭───────────────────────────────────────────────────╮
│  📁 Dotfiles Status                                │
├───────────────────────────────────────────────────┤
│  State: ⚪ Not initialized                        │
│                                                   │
│  Initialize chezmoi:                              │
│    chezmoi init                                   │
╰───────────────────────────────────────────────────╯
```

**Output when chezmoi is ready:**

```
╭───────────────────────────────────────────────────╮
│  📁 Dotfiles Status                                │
├───────────────────────────────────────────────────┤
│  State: 🟢 Synced                                 │
│  Last sync: 2 hours ago                           │
│  Tracked files: 12                                │
│                                                   │
│  Quick actions:                                   │
│    dot edit .zshrc    Edit shell config           │
│    dot sync           Pull latest changes         │
│    dot help           Show all commands           │
╰───────────────────────────────────────────────────╯
```

---

## Part 2: Tracking Your First Dotfile

### Step 1: Add a File to Chezmoi

Before you can use `dot edit`, the file must be tracked by chezmoi:

```bash
# Add your shell config to chezmoi
chezmoi add ~/.zshrc
```

This copies `~/.zshrc` to chezmoi's source directory (`~/.local/share/chezmoi/`).

### Step 2: Edit the File

```bash
dot edit .zshrc
```

**What happens:**

1. Opens your `$EDITOR` with the **source file** in chezmoi's directory
2. You make changes and save
3. Hash-based detection determines if anything changed
4. If changed, shows diff and prompts for action

**Example session:**

```
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
```

**Options:**
- **y** (or Enter) - Apply changes to your actual `~/.zshrc`
- **d** - Show full diff, then ask again
- **n** - Keep changes in chezmoi source (not applied yet)

### Step 3: Apply Changes Later

If you pressed 'n' during edit, the changes are in chezmoi's source but not yet applied to your home directory.

```bash
# See what would change
dot diff

# Apply all pending changes
dot apply
```

---

## Part 3: Dry-Run Mode

### Preview Without Applying

The `--dry-run` flag (or `-n`) shows what would change without actually modifying files.

```bash
dot apply --dry-run
```

**Output when nothing to apply:**

```
ℹ DRY-RUN MODE - No changes will be applied

✓ No pending changes
```

**Output when changes are pending:**

```
ℹ DRY-RUN MODE - No changes will be applied

ℹ Showing what would change (dry-run)...
[chezmoi verbose diff output]

✓ Dry-run complete - no changes applied
```

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
dot push
```

### On Other Machines

```bash
# Clone your dotfiles
chezmoi init https://github.com/username/dotfiles.git

# Apply to this machine
dot apply
```

### Daily Sync Pattern

**Pull changes from remote:**

```bash
dot sync
```

**Output:**

```
ℹ Fetching from remote...

ℹ Remote has updates:
abc1234 Add new alias
def5678 Update git config

Apply updates? [Y/n/d]
```

**Push your changes:**

```bash
dot push
```

**Output:**

```
ℹ Staging changes...
ℹ Committing...

Commit message: [enter your message]

✓ Pushed to remote
```

---

## Part 5: macOS Keychain Secrets (v5.5.0)

The recommended way to manage secrets is using macOS Keychain. It provides:

- ⚡ **Instant access** - No unlock step needed
- 🍎 **Touch ID / Apple Watch** - Biometric authentication
- 🔒 **Auto-lock** - Locks with screen lock
- 📡 **Works offline** - No internet required

### Store a Secret

```bash
dot secret add github-token
```

**Output:**

```
Enter secret value: [hidden input]

✓ Secret 'github-token' stored in Keychain
```

### Retrieve a Secret

```bash
# Get a secret (Touch ID prompt may appear)
TOKEN=$(dot secret github-token)

# Use in a command
gh auth login --with-token <<< $(dot secret github-token)
```

### List Keychain Secrets

```bash
dot secret list
```

**Output:**

```
ℹ Secrets in Keychain (flow-cli):
  • github-token
  • npm-token
  • anthropic-api-key
```

### Delete a Secret

```bash
dot secret delete old-token
```

**Output:**

```
✓ Secret 'old-token' deleted
```

### Import from Bitwarden (One-Time Migration)

If you have secrets in Bitwarden, you can import them to Keychain:

```bash
# Unlock Bitwarden first
dot unlock

# Import all secrets from 'flow-cli-secrets' folder
dot secret import
```

**Output:**

```
ℹ Import secrets from Bitwarden folder 'flow-cli-secrets'?
Continue? [y/N] y

✓ Imported: github-token
✓ Imported: npm-token
✓ Imported: anthropic-api-key

✓ Imported 3 secret(s) to Keychain
```

After import, secrets are in Keychain and no longer need Bitwarden unlock.

---

## Part 6: Bitwarden Cloud Secrets (Alternative)

If you need cloud-synced secrets (team sharing, multiple devices), use Bitwarden:

### Prerequisites

```bash
brew install bitwarden-cli

# Login (first time)
bw login
```

### Unlock Vault

```bash
dot unlock
```

**Output:**

```
ℹ Enter your Bitwarden master password:
[password prompt]

✓ Vault unlocked successfully

  Session active in this shell only
ℹ Use 'dot secret <name>' to retrieve secrets
```

### List Secrets

```bash
dot secret list
```

**Output:**

```
ℹ Retrieving items from vault...

🔑 github-token (Work/GitHub)
🔑 npm-token (Work/Node)
🔑 anthropic-api-key (AI/Keys)
📝 ssh-passphrase (SSH)

ℹ Usage: dot secret <name>
```

### Retrieve a Secret

```bash
# Retrieve without echo (secure)
TOKEN=$(dot secret github-token)

# Use in a command
curl -H "Authorization: Bearer $TOKEN" https://api.github.com/user
```

### Using Secrets in Templates

Create a template file in chezmoi:

**File:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# API Keys (from Bitwarden)
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-api-key" }}"
```

**Apply with secrets:**

```bash
# Unlock vault first
dot unlock

# Preview (dry-run)
dot apply --dry-run

# Apply for real
dot apply
```

---

## Part 7: Token Management (v5.2.0)

### Create a GitHub Token

The token wizard guides you through creating properly-scoped tokens:

```bash
dot token github
```

**Example session:**

```
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

💡 Tip: dot token github-token --refresh to rotate later
```

### Check Token Expiration

```bash
dot secrets
```

**Output:**

```
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
```

### Rotate an Expiring Token

```bash
dot token pypi-token --refresh
```

**Example session:**

```
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
```

### Sync to GitHub Actions

Push secrets to your repository for CI/CD:

```bash
dot secrets sync github
```

**Example session:**

```
ℹ Syncing secrets to: Data-Wise/flow-cli

Select secrets to sync:
  [x] GITHUB_TOKEN
  [x] NPM_TOKEN
  [ ] PYPI_TOKEN

Sync 2 secrets? [Y/n] y

✓ Synced GITHUB_TOKEN
✓ Synced NPM_TOKEN

✓ 2 secrets synced to repository
```

### Generate .envrc for Local Development

```bash
dot env init
```

**Output:**

```
✓ Generated .envrc with 3 secrets

  Contents:
  ─────────────────────────────────
  export GITHUB_TOKEN="$(dot secret github-token)"
  export NPM_TOKEN="$(dot secret npm-token)"
  export ANTHROPIC_API_KEY="$(dot secret anthropic-api-key)"
  ─────────────────────────────────

💡 Run 'direnv allow' to activate
```

---

## Part 8: Error Handling

### Common Errors

**File not tracked:**

```
✗ File not found in managed dotfiles: .zshrc
ℹ Use 'chezmoi add <file>' to start tracking a new file
```

**Vault locked:**

```
✗ Bitwarden vault is locked
ℹ Run: dot unlock
```

**Secret not found:**

```
✗ Secret not found: wrong-name
Tip: Use 'dot secret list' to see available items
```

**Session expired:**

```
✗ Session expired
Run: dot unlock
```

---

## Quick Reference

### Core Commands

```bash
dot                  # Show status
dot edit <file>      # Edit dotfile (preview + apply)
dot diff             # Show pending changes
dot apply            # Apply pending changes
dot apply --dry-run  # Preview what would change
```

### Sync Commands

```bash
dot sync             # Pull from remote
dot push             # Push to remote
```

### Keychain Secrets (v5.5.0 - Recommended)

```bash
dot secret add <name>       # Store secret in Keychain
dot secret <name>           # Get secret (Touch ID)
dot secret list             # List Keychain secrets
dot secret delete <name>    # Remove secret
dot secret import           # Import from Bitwarden
```

### Bitwarden Secrets (Cloud)

```bash
dot unlock           # Unlock Bitwarden vault
dot secret bw <name> # Get Bitwarden secret
dot secrets          # Dashboard with expiration
```

### Token Commands (v5.2.0)

```bash
dot token github              # GitHub PAT wizard
dot token npm                 # NPM token wizard
dot token pypi                # PyPI token wizard
dot token <name> --refresh    # Rotate existing token
dot secrets sync github       # Sync to GitHub Actions
dot env init                  # Generate .envrc for direnv
```

### Troubleshooting

```bash
dot doctor           # Run diagnostics
dot help             # Show all commands
```

---

## Best Practices

1. **Always check status first** - Run `dot` before making changes
2. **Use dry-run** - Preview before applying, especially with templates
3. **Small commits** - One logical change per push
4. **Lock vault when done** - Run `bw lock` after using secrets
5. **Never commit secrets** - Use templates, not plain text

---

## Next Steps

1. **Set up chezmoi:** `chezmoi init`
2. **Add your first file:** `chezmoi add ~/.zshrc`
3. **Try editing:** `dot edit .zshrc`
4. **Set up remote:** Push to GitHub for cross-machine sync
5. **Add secrets:** Store API keys in Bitwarden, use templates

### Further Reading

- [DOT Dispatcher Reference](../reference/DOT-DISPATCHER-REFERENCE.md) - Full command reference
- [Chezmoi Documentation](https://www.chezmoi.io/) - Official chezmoi docs
- [Bitwarden CLI](https://bitwarden.com/help/cli/) - Bitwarden CLI reference

---

**Version:** v5.5.0
**Last Updated:** 2026-01-13
