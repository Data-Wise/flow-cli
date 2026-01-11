# Dot Dispatcher Reference

**Command:** `dot`
**Purpose:** Dotfile management via chezmoi and Bitwarden
**Version:** v5.1.0 (Critical Improvements)

---

## Overview

The `dot` dispatcher provides a unified interface for managing dotfiles with chezmoi and secrets with Bitwarden CLI. It integrates seamlessly with flow-cli's dashboard and doctor commands.

### Key Features

- 📝 **Dotfile sync** (chezmoi integration)
- 🔐 **Secret management** (Bitwarden integration)
- 🎯 **ADHD-friendly** (smart defaults, clear status, progressive disclosure)
- ⚡ **Fast** (< 500ms for most operations)
- 🔌 **Optional** (graceful degradation if tools not installed)

**✨ New in v5.1.0:**
- 🔍 **Hash-based change detection** - SHA-256 comparison catches all edits (even < 1s)
- 🎯 **Smart error handling** - Specific guidance for each Bitwarden error type
- 👀 **Dry-run mode** - Preview changes safely with `--dry-run` / `-n` flag

---

## Quick Start

```bash
# Check dotfile status
dot

# Edit a dotfile (with preview & apply)
dot edit .zshrc

# Preview changes without applying (v5.1.0+)
dot apply --dry-run

# Sync from remote
dot sync

# Unlock Bitwarden vault
dot unlock

# Get a secret (no terminal echo)
TOKEN=$(dot secret github-token)
```

---

## Command Reference

### Status & Info

#### `dot` / `dot status` / `dot s`

Show dotfile sync status and summary.

**Output:**
```
Dotfile Status: 🟢 Synced

Last sync:     2 hours ago
Tracked files: 12
Remote:        git@github.com:user/dotfiles.git
Modified:      0 files pending

Run 'dot help' for commands
```

**Status Icons:**
- 🟢 **Synced** - Everything up to date
- 🟡 **Modified** - Local changes pending
- 🔴 **Behind** - Remote has new commits
- 🔵 **Ahead** - Local commits not pushed

#### `dot help` / `dot --help` / `dot -h`

Show detailed help with examples.

#### `dot version` / `dot --version` / `dot -v`

Show version information.

---

### Dotfile Management

#### `dot edit FILE` / `dot e FILE`

Edit a dotfile with preview and apply workflow.

**Features:**
- Opens file in `$EDITOR`
- **Hash-based change detection** (v5.1.0) - SHA-256 comparison catches ALL edits
- Shows diff preview
- Prompts to apply changes
- Fuzzy path matching (e.g., `dot edit zshrc` finds `.zshrc`)

**Examples:**
```bash
dot edit .zshrc          # Edit ZSH config
dot edit zshrc           # Fuzzy match works too
dot e gitconfig          # Short alias
```

**Workflow:**
1. Calculates SHA-256 hash of file before editing
2. Opens file in editor
3. You make changes and save (even quick edits < 1s are detected!)
4. Compares hash after saving - detects ANY content change
5. Shows diff: `Modified: ~/.zshrc`
6. Prompts: `Apply changes? [Y/n/d(iff)]`
7. If yes: Runs `chezmoi apply`

**Why hash-based detection? (v5.1.0)**

Traditional `mtime` (modification time) has ~1 second granularity, causing false negatives on quick edits—especially problematic for ADHD users who edit rapidly. SHA-256 hash comparison is deterministic and catches ALL changes, regardless of timing.

#### `dot sync` / `dot pull`

Pull changes from remote repository.

**Features:**
- Fetches latest from remote
- Shows diff preview
- Prompts before applying
- Handles merge conflicts

**Examples:**
```bash
dot sync                 # Pull with preview
dot pull                 # Alias
```

**Workflow:**
1. Fetches from remote
2. Shows pending changes
3. Prompts: `Apply updates? [Y/n/d(iff)]`
4. If yes: Pulls and applies changes

#### `dot push` / `dot p`

Commit and push changes to remote.

**Features:**
- Auto-stages modified files
- Prompts for commit message
- Pushes to remote

**Examples:**
```bash
dot push                 # Commit & push
dot p                    # Short alias
```

**Workflow:**
1. Shows modified files
2. Prompts for commit message
3. Commits with message
4. Pushes to remote

#### `dot diff` / `dot d`

Show pending changes.

**Features:**
- Shows detailed diff
- Colored output
- Can filter by file

**Examples:**
```bash
dot diff                 # Show all changes
dot d                    # Short alias
dot diff .zshrc          # Show changes for specific file
```

#### `dot apply` / `dot a`

Apply pending changes to home directory.

**Features:**
- Applies templated changes
- Shows files being updated
- Safe operation (creates backups)
- **Dry-run mode** (v5.1.0) - Preview without applying

**Examples:**
```bash
dot apply                # Apply all pending changes
dot a                    # Short alias
dot apply .zshrc         # Apply specific file

# v5.1.0: Dry-run mode (preview only)
dot apply --dry-run      # Preview all changes (no apply)
dot apply -n             # Short flag
dot apply -n .zshrc      # Preview specific file
```

**Dry-Run Mode (v5.1.0):**

Preview exactly what would change WITHOUT actually applying:

```bash
$ dot apply --dry-run

DRY-RUN MODE - No changes will be applied

Showing what would change (dry-run)...

Files to update: 2

M .zshrc
M .gitconfig

[Shows verbose diff of what would change]

✓ Dry-run complete - no changes applied
```

**Use cases for dry-run:**
- ✅ Preview changes before applying
- ✅ Verify template expansions look correct
- ✅ Check Bitwarden secret substitutions
- ✅ Safe exploration (no risk of breaking configs)
- ✅ ADHD-friendly (see before you commit)

---

### Secret Management

#### `dot unlock` / `dot u`

Unlock Bitwarden vault for the current shell session.

**Features:**
- Session-scoped (not persistent)
- Exports `BW_SESSION` environment variable
- Shows security reminders
- Validates unlock success

**Examples:**
```bash
dot unlock               # Unlock vault
dot u                    # Short alias
```

**Output:**
```
ℹ Enter your Bitwarden master password:
[password prompt]

✓ Vault unlocked successfully

  Session active in this shell only (not persistent)
ℹ Use 'dot secret <name>' to retrieve secrets

⚠ Security reminder:
  • Session expires when shell closes
  • Don't export BW_SESSION globally
  • Lock vault when done: bw lock
```

**Security:**
- Session token stored in memory only
- Not saved to disk
- Not exported to startup files
- Expires when shell closes

#### `dot secret NAME`

Retrieve a secret by name (returns value without echo).

**Features:**
- No terminal echo (secure)
- Safe for variable capture
- Validates session first
- Suppresses stderr

**Examples:**
```bash
# Capture in variable
TOKEN=$(dot secret github-token)

# Use in command
curl -H "Authorization: Bearer $(dot secret api-key)" https://api.example.com

# Check if available
if dot secret github-token >/dev/null 2>&1; then
  echo "Secret exists"
fi
```

**Error Handling (v5.1.0 - Improved):**

Smart error detection with specific guidance for each error type:

```bash
# Secret not found
$ dot secret nonexistent-item
✗ Secret not found: nonexistent-item
Tip: Use 'dot secret list' to see available items

# Session expired
$ dot secret github-token
✗ Session expired
Run: dot unlock

# Vault locked
$ dot secret api-key
✗ Vault is locked
Run: dot unlock

# Access denied (permissions)
$ dot secret protected-item
✗ Access denied for secret: protected-item
Check Bitwarden permissions for this item
```

**How it works (v5.1.0):**

Instead of generic "failed to retrieve" messages, the dispatcher now:
1. Captures `stderr` from Bitwarden CLI securely (using `mktemp`)
2. Parses error patterns ("Not found", "Session key", "locked", "access denied")
3. Provides specific, actionable guidance for each error type
4. Cleans up temp files automatically (no data leaks)

#### `dot secret list`

List all items in Bitwarden vault.

**Features:**
- Shows item type icons (🔑 login, 📝 note, 💳 card)
- Displays folder organization
- Colored output
- Falls back gracefully if `jq` not installed

**Examples:**
```bash
dot secret list
```

**Output:**
```
ℹ Retrieving items from vault...

🔑 github-token (Work/GitHub)
🔑 npm-token (Work/Node)
📝 ssh-passphrase (Personal)
💳 stripe-test-key (Work/Stripe)

ℹ Usage: dot secret <name>
```

---

### Troubleshooting

#### `dot doctor` / `dot dr`

Run diagnostics and health checks.

**Features:**
- Checks chezmoi installation
- Validates git remote
- Shows sync status
- Checks Bitwarden status
- Identifies security issues

**Examples:**
```bash
dot doctor               # Run diagnostics
dot dr                   # Short alias
```

**Also available via:**
```bash
flow doctor              # Includes dotfile checks
```

#### `dot undo`

Rollback last apply operation (emergency recovery).

**Features:**
- Reverts to previous state
- Shows what will be restored
- Confirms before reverting

**Examples:**
```bash
dot undo                 # Rollback last apply
```

---

### Setup

#### `dot init`

Initialize dotfile management (first-time setup).

**Features:**
- Initializes chezmoi
- Optionally clones existing dotfiles repo
- Sets up git remote
- Configures templates

**Examples:**
```bash
dot init                                    # Interactive setup
dot init https://github.com/user/dotfiles  # Clone from repo
```

---

## Integration

### Dashboard Integration

The `dash` command shows dotfile status automatically:

```
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD ✓                  Jan 09, 2026  🕐 14:30 │
╰──────────────────────────────────────────────────────────────╯

  ...

  📝 Dotfiles: 🟢 Synced (2h ago) · 12 files tracked

  ...
```

**Status Line Format:**
```
📝 Dotfiles: [icon] [state] [details] · [file count] tracked
```

**Conditional Display:**
- Only shows if chezmoi is installed
- Gracefully omits if not configured
- Fast (< 100ms, uses cached values)

### Doctor Integration

The `flow doctor` command includes dotfile health checks:

```
🔌 INTEGRATIONS
  ✓ atlas v3.1.0
  ○ radian (R not installed)

📁 DOTFILES
  ✓ chezmoi v2.45.0
  ✓ Bitwarden CLI v2024.1.0
  ✓ Chezmoi initialized with git
  ✓ Remote configured: git@github.com:user/dotfiles.git
  ✓ No uncommitted changes
  ✓ Synced with remote
  ✓ Bitwarden vault unlocked

🔌 PLUGIN MANAGER
  ...
```

---

## Chezmoi Templates

Use Bitwarden secrets in chezmoi templates:

### Template Syntax

```go
{{- /* Retrieve password field from Bitwarden item */ -}}
{{- bitwarden "item" "github-token" -}}

{{- /* Retrieve specific field */ -}}
{{- bitwardenFields "item" "api-key" "custom-field-name" -}}

{{- /* Retrieve from secure notes */ -}}
{{- bitwardenFields "item" "ssh-key" "notes" -}}
```

### Example: `.gitconfig` with GitHub Token

**Template:** `~/.local/share/chezmoi/dot_gitconfig.tmpl`

```ini
[user]
    name = Your Name
    email = your@email.com

[github]
    user = youruser
    token = {{ bitwarden "item" "github-token" }}
```

**Apply:**
```bash
dot unlock           # Unlock Bitwarden
dot edit .gitconfig  # Edit and apply template
```

### Example: `.zshrc` with API Keys

**Template:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# API Keys (from Bitwarden)
export OPENAI_API_KEY="{{ bitwarden "item" "openai-key" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-key" }}"
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
```

---

## Security Best Practices

### ✅ DO

- **Unlock per-session:** Run `dot unlock` in each shell where you need secrets
- **Lock when done:** Run `bw lock` after template operations
- **Use templates:** Store templates in chezmoi, not plain files with secrets
- **Capture securely:** Use `VAR=$(dot secret name)` to capture without echo
- **Validate items:** Use `dot secret list` to verify item names

### ❌ DON'T

- **Don't export globally:** Never add `export BW_SESSION=...` to `.zshrc`
- **Don't commit secrets:** Never commit files with actual secret values
- **Don't echo secrets:** Avoid `echo $(dot secret name)` in scripts
- **Don't log secrets:** Ensure secrets aren't written to logs/history
- **Don't share sessions:** Each user should unlock their own vault

---

## Configuration

### Environment Variables

```bash
# No configuration needed - uses chezmoi and bw defaults
# Optional: customize chezmoi directory
export CHEZMOI_SOURCE_DIR="$HOME/.local/share/chezmoi"
```

### Prerequisites

- **Required for dotfiles:** `chezmoi` (brew install chezmoi)
- **Required for secrets:** `bitwarden-cli` (brew install bitwarden-cli)
- **Optional:** `jq` (brew install jq) - for pretty secret listing

**Install all:**
```bash
brew install chezmoi bitwarden-cli jq
```

---

## Performance

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| `dot` / `dot status` | < 500ms | Runs chezmoi status |
| `dot edit <file>` | instant | Opens editor immediately |
| `dot edit <file>` (hash calc) | +1-2ms | SHA-256 overhead (v5.1.0) |
| `dot apply --dry-run` | same as apply | Uses chezmoi native dry-run |
| `dot sync` | 1-3s | Fetches from remote |
| `dot push` | 1-3s | Pushes to remote |
| `dot secret <name>` | < 200ms | Retrieves from vault |
| `dot secret list` | 300-500ms | Lists all items |
| Dashboard status | < 100ms | Uses cached values |

### Optimization Tips

- **Dashboard caching:** Status cached for fast display
- **Lazy loading:** dot dispatcher only loaded when called
- **Conditional checks:** Operations skip if tools not installed
- **Hash detection** (v5.1.0): SHA-256 is extremely fast (~1ms for typical dotfiles) - the deterministic accuracy far outweighs the negligible overhead

---

## Troubleshooting

### "Chezmoi not initialized"

**Cause:** Chezmoi hasn't been set up yet.

**Solution:**
```bash
dot init                                    # Interactive setup
# OR
chezmoi init https://github.com/user/dotfiles  # Clone existing
```

### "Bitwarden vault is locked"

**Cause:** No active `BW_SESSION` in current shell.

**Solution:**
```bash
dot unlock
```

### "Secret not found" (v5.1.0)

**Cause:** Item name doesn't exist in vault.

**Solution:**
```bash
# List all items to find correct name
dot secret list

# Check exact name (case-sensitive)
bw get item github-token
```

### "Session expired" (v5.1.0)

**Cause:** `BW_SESSION` environment variable is invalid or expired.

**Solution:**
```bash
# Simply unlock again
dot unlock
```

### "Access denied for secret" (v5.1.0)

**Cause:** Bitwarden permissions restrict access to this item.

**Solution:**
- Check if item is in a collection you don't have access to
- Verify item permissions in Bitwarden web vault
- Contact vault administrator if using org vault

### "Bitwarden not authenticated"

**Cause:** Not logged into Bitwarden CLI.

**Solution:**
```bash
bw login
```

### Session Token in History

**Concern:** `bw unlock --raw` output might be in shell history.

**Solution:** The `dot unlock` command captures output safely without exposing tokens. ZSH history exclusion patterns prevent storage of sensitive commands.

**Verify history settings:**
```bash
# Check if HISTIGNORE includes bw commands
echo $HISTIGNORE

# Should include: *bw unlock*:*bw get*:*BW_SESSION*
```

---

## Aliases

Built-in aliases for common operations:

```bash
dot s          # status
dot e FILE     # edit
dot d          # diff
dot a          # apply
dot p          # push
dot u          # unlock
dot dr         # doctor
```

---

## See Also

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [SECRET-MANAGEMENT.md](../SECRET-MANAGEMENT.md) - Comprehensive secret management guide
- [PHASE3-IMPLEMENTATION-SUMMARY.md](../PHASE3-IMPLEMENTATION-SUMMARY.md) - Technical implementation details
- [PHASE4-SUMMARY.md](../PHASE4-SUMMARY.md) - Dashboard integration details

---

**Version:** v5.1.0 (Critical Improvements)
**Last Updated:** 2026-01-10
