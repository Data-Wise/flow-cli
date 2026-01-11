# Dotfile Management Workflow

**Level:** Beginner to Intermediate
**Time:** 20 minutes
**Goal:** Master dotfile management with chezmoi and Bitwarden secrets

---

## What This Guide Covers

Learn practical workflows for managing dotfiles with the `dot` dispatcher:

- ✅ **Quick edit workflow** - Edit, preview, and apply dotfile changes
- ✅ **Sync workflow** - Keep dotfiles synchronized across machines
- ✅ **Secret management** - Safely handle API keys and tokens with Bitwarden
- ✅ **Dry-run previews** (v5.1.0) - Preview changes before applying
- ✅ **Error recovery** - Handle common issues with smart error messages
- ✅ **ADHD-friendly patterns** - Quick, safe, reversible workflows

---

## Why Use the dot Dispatcher?

### The Problem with Manual Dotfile Management

**Traditional approach:**
```bash
# Edit dotfile directly
vim ~/.zshrc

# Oops, broke something - how do I revert?
# No version history
# No backup
# No sync across machines
```

**Issues:**
- ⚠️ No version control
- ⚠️ Easy to break configs
- ⚠️ Hard to sync across machines
- ⚠️ Secrets scattered everywhere
- ⚠️ No preview before applying changes

### The dot Dispatcher Solution

**Centralized, versioned, secure:**
- ✅ All dotfiles in git repository
- ✅ Changes previewed before applying
- ✅ Secrets stored securely in Bitwarden
- ✅ Automatic sync across machines
- ✅ Easy rollback with `dot undo`
- ✅ Fast, sub-second operations

---

## Workflow 1: Quick Edit

**Goal:** Edit a dotfile, preview changes, and apply.

### Step-by-Step

```bash
# 1. Edit a dotfile
dot edit .zshrc

# Your editor opens...
# Make changes and save

# 2. dot automatically detects changes (v5.1.0 hash-based detection)
# Shows diff preview:
───────────────────────────────────────────
Modified: ~/.zshrc
───────────────────────────────────────────
@@ -10,0 +11 @@
+export NEW_VAR="test"
───────────────────────────────────────────

# 3. Prompt to apply
Apply changes? [Y/n/d(iff)]

# Press:
# - Y: Apply changes to ~/.zshrc
# - n: Cancel (keep source, don't apply)
# - d: Show full diff again
```

### With Dry-Run (v5.1.0)

**Preview without committing:**

```bash
# Make multiple edits
dot edit .zshrc
# Save but press 'n' (don't apply yet)

dot edit .gitconfig
# Save but press 'n'

# Preview all pending changes
dot apply --dry-run

# Output:
DRY-RUN MODE - No changes will be applied

Files to update: 2

M .zshrc
M .gitconfig

[Shows full diff of both files]

✓ Dry-run complete - no changes applied

# Safe! Now apply for real:
dot apply
```

### Why Hash-Based Detection Matters (v5.1.0)

**ADHD-friendly change detection:**

Traditional `mtime` has ~1 second granularity. If you:
1. Open file
2. Make quick change
3. Save within 1 second
4. Exit

...the old detector would say "No changes made" (false negative).

**v5.1.0 uses SHA-256 hash comparison** - catches ALL edits, even sub-second changes. Perfect for rapid editing patterns.

---

## Workflow 2: Sync Across Machines

**Goal:** Keep dotfiles synchronized between home and work machines.

### Initial Setup (First Time)

**On your first machine:**

```bash
# Initialize chezmoi with your dotfiles repo
dot init https://github.com/username/dotfiles.git

# Verify
dot status

# Output:
Dotfile Status: 🟢 Synced
Last sync:     just now
Tracked files: 12
Remote:        git@github.com:username/dotfiles.git
```

**On subsequent machines:**

```bash
# Clone your existing dotfiles
dot init https://github.com/username/dotfiles.git

# Apply to this machine
dot apply
```

### Daily Sync Workflow

**Pull changes from remote (e.g., from work machine):**

```bash
# On home machine
dot sync

# Shows what changed:
Fetching from remote...

Changes from remote:
M .zshrc          # Updated ZSH config
M .gitconfig      # Updated git settings

Apply updates? [Y/n/d(iff)]

# Press Y to apply
✓ Applied 2 files
```

**Push changes to remote (share with other machines):**

```bash
# Made local changes
dot edit .zshrc
# Apply changes...

# Push to remote
dot push

# Prompts for commit message:
Commit message: Add new aliases for project navigation

# Pushes to GitHub
✓ Pushed to remote
```

---

## Workflow 3: Secret Management

**Goal:** Securely handle API keys and tokens in dotfiles.

### Setup Bitwarden Integration

**One-time setup:**

```bash
# Install Bitwarden CLI
brew install bitwarden-cli

# Login to Bitwarden
bw login

# Unlock vault for this session
dot unlock

# Output:
 ℹ Enter your Bitwarden master password:
[password prompt]

✓ Vault unlocked successfully

  Session active in this shell only (not persistent)
 ℹ Use 'dot secret <name>' to retrieve secrets
```

### Using Secrets in Templates

**Example: Add GitHub token to .gitconfig**

**1. Store token in Bitwarden:**
- Open Bitwarden app
- Create new "Login" item named "github-token"
- Paste token in password field
- Save

**2. Create chezmoi template:**

```bash
# Edit .gitconfig as template
dot edit .gitconfig

# Add template syntax:
[github]
    user = yourusername
    token = {{ bitwarden "item" "github-token" }}
```

**3. Apply with secret substitution:**

```bash
# Unlock vault first
dot unlock

# Preview with dry-run (v5.1.0)
dot apply --dry-run

# Verify token is substituted correctly in preview
# Then apply:
dot apply
```

**Your actual ~/.gitconfig now contains the real token** (not the template).

### Retrieve Secrets in Scripts

**Capture secret without echo:**

```bash
# Safe - no terminal output
TOKEN=$(dot secret github-token)

# Use in command
curl -H "Authorization: Bearer $TOKEN" https://api.github.com/user
```

### List Available Secrets

```bash
dot secret list

# Output:
 ℹ Retrieving items from vault...

🔑 github-token (Work/GitHub)
🔑 npm-token (Work/Node)
🔑 anthropic-api-key (AI/API Keys)
📝 ssh-passphrase (Personal)

 ℹ Usage: dot secret <name>
```

### Smart Error Handling (v5.1.0)

**Before v5.1.0:**
```bash
$ dot secret wrong-name
✗ Failed to retrieve secret
 ℹ Item not found or access denied
```

**After v5.1.0:**
```bash
# Secret doesn't exist
$ dot secret wrong-name
✗ Secret not found: wrong-name
Tip: Use 'dot secret list' to see available items

# Session expired
$ dot secret github-token
✗ Session expired
Run: dot unlock

# Vault locked
$ dot secret api-key
✗ Vault is locked
Run: dot unlock
```

**Each error type gets specific, actionable guidance.**

---

## Workflow 4: Safe Experimentation

**Goal:** Try risky config changes safely with preview and rollback.

### Preview Before Applying

```bash
# Edit config file
dot edit .zshrc

# Make experimental changes
# Save but press 'n' (don't apply yet)

# Use dry-run to preview
dot apply --dry-run .zshrc

# Review the diff carefully
# If it looks safe:
dot apply .zshrc

# If something breaks:
dot undo
```

### Rollback Last Change

```bash
# Applied bad config
dot apply

# Oops, terminal broken!
# Rollback:
dot undo

# Restores previous state
✓ Rolled back to previous version
```

---

## Workflow 5: Dashboard Integration

**Goal:** Monitor dotfile status at a glance.

### Quick Status Check

```bash
# Run dashboard
dash

# Shows dotfile status:
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD ✓                  Jan 10, 2026  🕐 14:30 │
╰──────────────────────────────────────────────────────────────╯

  📝 Dotfiles: 🟢 Synced (2h ago) · 12 files tracked

  ...
```

**Status indicators:**
- 🟢 **Synced** - Everything up to date
- 🟡 **Modified** - Local changes pending
- 🔴 **Behind** - Remote has new commits
- 🔵 **Ahead** - Local commits not pushed

### Health Check

```bash
# Run doctor command
flow doctor

# Dotfile health checks:
📁 DOTFILES
  ✓ chezmoi v2.45.0
  ✓ Bitwarden CLI v2024.1.0
  ✓ Chezmoi initialized with git
  ✓ Remote configured: git@github.com:user/dotfiles.git
  ✓ No uncommitted changes
  ✓ Synced with remote
  ✓ Bitwarden vault unlocked
```

---

## Common Patterns

### Pattern 1: Add New Dotfile to Tracking

```bash
# Add file to chezmoi
chezmoi add ~/.tmux.conf

# Verify it's tracked
dot status

# Edit via dot dispatcher
dot edit .tmux.conf

# Push to remote
dot push
```

### Pattern 2: Quick Status Check

```bash
# Minimal status
dot

# Or verbose
dot status

# Or via dashboard
dash
```

### Pattern 3: Batch Preview

```bash
# Make multiple changes
dot edit .zshrc      # Edit, save, press 'n'
dot edit .gitconfig  # Edit, save, press 'n'
dot edit .tmux.conf  # Edit, save, press 'n'

# Preview all at once
dot apply --dry-run

# Apply all at once
dot apply
```

---

## Troubleshooting Workflows

### "Changes not detected after quick edit"

**Before v5.1.0:** This happened with sub-second edits (mtime granularity issue).

**Solution:** Upgrade to v5.1.0+ with hash-based detection. All edits are now detected regardless of timing.

### "Secret substitution not working"

**Checklist:**

```bash
# 1. Vault unlocked?
dot unlock

# 2. Secret exists?
dot secret list

# 3. Template syntax correct?
# ✅ Correct: {{ bitwarden "item" "secret-name" }}
# ❌ Wrong:   {{ bitwarden "secret-name" }}

# 4. Dry-run to preview
dot apply --dry-run
```

### "Applied broken config, terminal won't work"

**Recovery:**

```bash
# Option 1: Rollback last change
dot undo

# Option 2: Edit source and re-apply
dot edit .zshrc
# Fix the issue
# Apply corrected version

# Option 3: Nuclear option (restore from repo)
cd ~/.local/share/chezmoi
git reset --hard origin/main
dot apply
```

---

## ADHD-Friendly Tips

### 1. Use Dry-Run Liberally

**Reduce anxiety about breaking things:**

```bash
# Always preview first
dot apply --dry-run

# If it looks good, apply
dot apply
```

### 2. Quick Session Pattern

```bash
# One-liner: edit → preview → apply
dot edit .zshrc && dot apply --dry-run && dot apply
```

### 3. Dashboard for Context

**Forgot what you were doing?**

```bash
dash

# Shows:
# - Pending dotfile changes (🟡 Modified)
# - Last sync time
# - Current session
```

### 4. Safety First

**Rules:**
1. **Always `dot edit`** - Never edit ~/.zshrc directly
2. **Preview with dry-run** - Especially for complex templates
3. **Small commits** - One logical change per push
4. **Lock vault when done** - `bw lock` after template work

---

## Performance Notes

### Hash Detection Overhead (v5.1.0)

**Trade-off:**
- **Cost:** ~1-2ms per edit (SHA-256 calculation)
- **Benefit:** 100% reliable change detection

**For typical dotfiles:**
- .zshrc: 1ms
- .gitconfig: <1ms
- .tmux.conf: <1ms

**ADHD perspective:** Deterministic detection (never misses edits) is worth 1ms delay.

### Dashboard Status Caching

**Dashboard caches dotfile status** to keep `dash` fast:
- First load: ~500ms (runs chezmoi status)
- Subsequent: <100ms (cached)
- Cache invalidated after: 5 minutes

---

## Quick Reference

```bash
# Status
dot                      # Quick status
dot status               # Verbose status

# Edit workflows
dot edit .zshrc          # Edit with preview
dot apply --dry-run      # Preview pending changes
dot apply                # Apply all pending
dot apply .zshrc         # Apply specific file

# Sync workflows
dot sync                 # Pull from remote
dot push                 # Push to remote
dot diff                 # Show pending changes

# Secret workflows
dot unlock               # Unlock Bitwarden vault
dot secret <name>        # Get secret (no echo)
dot secret list          # List all secrets

# Troubleshooting
dot doctor               # Health check
dot undo                 # Rollback last apply
```

---

## Next Steps

1. **Set up chezmoi:** `dot init https://github.com/username/dotfiles`
2. **Add a dotfile:** `chezmoi add ~/.zshrc`
3. **Try dry-run workflow:** Edit → Preview → Apply
4. **Set up Bitwarden:** Store API keys securely
5. **Automate sync:** Add `dot sync` to daily routine

---

## See Also

- [DOT-DISPATCHER-REFERENCE.md](../reference/DOT-DISPATCHER-REFERENCE.md) - Complete command reference
- [SECRET-MANAGEMENT.md](../SECRET-MANAGEMENT.md) - Deep dive on Bitwarden integration
- [Chezmoi Documentation](https://www.chezmoi.io/) - Official chezmoi docs
- [Bitwarden CLI Guide](https://bitwarden.com/help/cli/) - Official Bitwarden CLI docs

---

**Version:** v5.1.0
**Last Updated:** 2026-01-10
