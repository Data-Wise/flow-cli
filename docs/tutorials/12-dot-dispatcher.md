# Tutorial: DOT Dispatcher - Dotfile Management

**Level:** Beginner
**Time:** 30 minutes
**Prerequisites:** chezmoi and bitwarden-cli installed

---

## What You'll Learn

By the end of this tutorial, you'll know how to:

- ✅ Edit dotfiles with automatic change detection
- ✅ Preview changes safely with dry-run mode (v5.1.0)
- ✅ Sync dotfiles across multiple machines
- ✅ Manage secrets securely with Bitwarden
- ✅ Monitor dotfile status in the dashboard

---

## Prerequisites

Install required tools:

```bash
# Install chezmoi (dotfile manager)
brew install chezmoi

# Install Bitwarden CLI (secret management)
brew install bitwarden-cli

# Optional: jq for pretty secret listing
brew install jq
```

---

## Part 1: Quick Edit Workflow

### The Problem

Manually editing dotfiles is risky:
- No version control
- Easy to break your shell
- Hard to sync across machines
- No preview before applying changes

### The Solution: `dot edit`

The DOT dispatcher provides a safe, versioned workflow for dotfile management.

### Step-by-Step

**1. Initialize chezmoi (first time only):**

```bash
# Initialize with your dotfiles repo
dot init https://github.com/username/dotfiles.git

# Or initialize from scratch
chezmoi init
```

**2. Edit a dotfile:**

```bash
dot edit .zshrc
```

![DOT Quick Edit Workflow](../demos/dot/01-quick-edit.gif)

*The `dot edit` workflow: open editor → make changes → preview diff → apply*

**What happens:**

1. **Opens your $EDITOR** with the dotfile source
2. **You make changes** and save
3. **Hash-based detection** (v5.1.0) catches ALL edits, even quick ones
4. **Shows diff** of what changed
5. **Prompts for confirmation** before applying

**3. Review and apply:**

```
✓ Changes detected!
───────────────────────────────────────────
Modified: ~/.zshrc
───────────────────────────────────────────
@@ -10,0 +11 @@
+export DEMO_VAR=v5.1.0
───────────────────────────────────────────

Apply changes? [Y/n/d]
```

**Options:**
- **Y** - Apply changes to `~/.zshrc`
- **n** - Cancel (keep source, don't apply)
- **d** - Show full diff again

### Why Hash-Based Detection Matters (v5.1.0)

**Before v5.1.0:**
- Used file modification time (`mtime`)
- ~1 second granularity
- Quick edits (< 1s) would show "No changes made"

**After v5.1.0:**
- Uses SHA-256 hash comparison
- **100% deterministic** - catches ALL changes
- Perfect for ADHD users who edit quickly

---

## Part 2: Dry-Run Mode (v5.1.0)

### New in v5.1.0: Safe Preview

Preview changes WITHOUT applying them.

### Step-by-Step

**1. Make multiple edits:**

```bash
# Edit first file
dot edit .zshrc
# Save but press 'n' (don't apply yet)

# Edit second file
dot edit .gitconfig
# Save but press 'n'
```

**2. Preview all pending changes:**

```bash
dot apply --dry-run
```

![DOT Dry-Run Mode](../demos/dot/02-dry-run.gif)

*Dry-run mode: preview what would change without actually applying*

**Output:**

```
DRY-RUN MODE - No changes will be applied

Showing what would change (dry-run)...

Files to update: 2

M .zshrc
M .gitconfig

[Shows verbose diff of both files]

✓ Dry-run complete - no changes applied
```

**3. Apply for real:**

```bash
# Now actually apply
dot apply
```

### Use Cases for Dry-Run

- ✅ **Preview template expansions** - See how Bitwarden secrets will be substituted
- ✅ **Verify changes look correct** - Catch mistakes before they break your shell
- ✅ **Safe exploration** - Test changes without risk
- ✅ **ADHD-friendly** - See before you commit

### Short Flag

```bash
# Both work the same
dot apply --dry-run
dot apply -n
```

---

## Part 3: Sync Across Machines

### The Workflow

Keep dotfiles synchronized between home machine, work machine, and servers.

### Initial Setup

**On your first machine:**

```bash
# Initialize chezmoi with git
chezmoi init

# Add dotfiles to tracking
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig
chezmoi add ~/.tmux.conf

# Push to remote
dot push
# Enter commit message: "Initial dotfiles"
```

**On subsequent machines:**

```bash
# Clone your dotfiles
dot init https://github.com/username/dotfiles.git

# Apply to this machine
dot apply
```

### Daily Sync Pattern

**Pull changes (e.g., from work machine):**

```bash
dot sync
```

**Output:**

```
Fetching from remote...

Changes from remote:
M .zshrc          # Updated aliases
M .gitconfig      # New git settings

Apply updates? [Y/n/d]
```

**Push your changes:**

```bash
dot push
```

**Output:**

```
Commit message: Add new project aliases

✓ Pushed to remote
```

### Quick Reference

```bash
dot sync          # Pull from remote
dot push          # Push to remote
dot diff          # Show pending changes
dot status        # Check sync status
```

---

## Part 4: Secret Management

### The Problem

Dotfiles often contain API keys and tokens:

```bash
# BAD: Plain text in .zshrc
export GITHUB_TOKEN="ghp_abc123..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Issues:**
- ⚠️ Secrets committed to git
- ⚠️ Visible in shell history
- ⚠️ Hard to rotate
- ⚠️ Shared across machines (security risk)

### The Solution: Bitwarden Integration

Store secrets in Bitwarden, use templates in dotfiles.

### Step-by-Step

**1. Login to Bitwarden (one-time):**

```bash
bw login
```

**2. Unlock vault for this session:**

```bash
dot unlock
```

![DOT Secret Management](../demos/dot/04-secrets.gif)

*Unlock Bitwarden, list secrets, and retrieve them securely*

**Output:**

```
ℹ Enter your Bitwarden master password:
[password prompt]

✓ Vault unlocked successfully

  Session active in this shell only (not persistent)
ℹ Use 'dot secret <name>' to retrieve secrets
```

**3. List available secrets:**

```bash
dot secret list
```

**Output:**

```
ℹ Retrieving items from vault...

🔑 github-token (Work/GitHub)
🔑 npm-token (Work/Node)
🔑 anthropic-api-key (AI/Keys)

ℹ Usage: dot secret <name>
```

**4. Use secrets in chezmoi templates:**

**Create template:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# API Keys (from Bitwarden)
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-api-key" }}"
```

**5. Preview template substitution:**

```bash
# Unlock vault first
dot unlock

# Preview with dry-run
dot apply --dry-run

# If it looks good, apply
dot apply
```

**Your actual ~/.zshrc now contains the real tokens** (not the template).

### Retrieve Secrets in Scripts

```bash
# Capture secret without echo
TOKEN=$(dot secret github-token)

# Use in command
curl -H "Authorization: Bearer $TOKEN" https://api.github.com/user
```

### Improved Error Handling (v5.1.0)

**Secret not found:**

```bash
$ dot secret wrong-name
✗ Secret not found: wrong-name
Tip: Use 'dot secret list' to see available items
```

**Session expired:**

```bash
$ dot secret github-token
✗ Session expired
Run: dot unlock
```

**Vault locked:**

```bash
$ dot secret api-key
✗ Vault is locked
Run: dot unlock
```

Each error provides **specific, actionable guidance**.

---

## Part 5: Dashboard Integration

### Quick Status Check

The DOT dispatcher integrates with the flow dashboard for at-a-glance status.

```bash
dot
```

**Output:**

```
Dotfile Status: 🟢 Synced

Last sync:     2 hours ago
Tracked files: 12
Remote:        git@github.com:user/dotfiles.git
Modified:      0 files pending

Run 'dot help' for commands
```

### Dashboard View

```bash
dash
```

**Output:**

```
╭──────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD ✓        Jan 10 🕐 14:30     │
╰──────────────────────────────────────────────────╯

  📝 Dotfiles: 🟢 Synced (2h ago) · 12 files tracked

  ... (other status)
```

**Status Icons:**
- 🟢 **Synced** - Everything up to date
- 🟡 **Modified** - Local changes pending
- 🔴 **Behind** - Remote has new commits
- 🔵 **Ahead** - Local commits not pushed

### Health Check

```bash
flow doctor
```

**Output:**

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

---

## Complete Example: Full Workflow

Let's put it all together with a complete example.

### Scenario

Add a new API key to your dotfiles and sync it across machines.

### Steps

**1. Store secret in Bitwarden:**

- Open Bitwarden app
- Create new Login item: "openai-api-key"
- Paste API key in password field
- Save

**2. Edit .zshrc template:**

```bash
dot edit .zshrc
```

Add this line:

```bash
export OPENAI_API_KEY="{{ bitwarden "item" "openai-api-key" }}"
```

Save, but press **'n'** (don't apply yet).

**3. Preview with dry-run:**

```bash
# Unlock vault first
dot unlock

# Preview substitution
dot apply --dry-run
```

Verify the API key is substituted correctly.

**4. Apply changes:**

```bash
dot apply
```

**5. Push to remote:**

```bash
dot push
# Commit message: "Add OpenAI API key from Bitwarden"
```

**6. On other machines:**

```bash
# Pull the change
dot sync

# Unlock vault (if needed)
dot unlock

# Apply with secrets
dot apply
```

Done! Your API key is now available on all machines, securely.

---

## Common Patterns

### Pattern 1: Quick Configuration Change

```bash
# Edit config
dot edit .tmux.conf

# Review and apply
# (automatically prompted)
```

### Pattern 2: Batch Preview

```bash
# Make multiple changes
dot edit .zshrc      # Edit, save, press 'n'
dot edit .gitconfig  # Edit, save, press 'n'

# Preview all at once
dot apply --dry-run

# Apply all at once
dot apply
```

### Pattern 3: Emergency Rollback

```bash
# Applied bad config
dot apply

# Oops, shell broken!
dot undo

# Restores previous version
```

### Pattern 4: Template Testing

```bash
# Edit template
dot edit .zshrc

# Unlock vault
dot unlock

# Preview substitution
dot apply --dry-run

# If it looks good, apply
dot apply
```

---

## Troubleshooting

### "Changes not detected after quick edit"

**Cause:** Using old version (< v5.1.0) with mtime-based detection.

**Solution:** Upgrade to v5.1.0+ for hash-based detection.

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

# 4. Preview first
dot apply --dry-run
```

### "Applied broken config"

**Recovery:**

```bash
# Option 1: Rollback
dot undo

# Option 2: Edit and fix
dot edit .zshrc
# Fix the issue, apply corrected version

# Option 3: Restore from repo
cd ~/.local/share/chezmoi
git reset --hard origin/main
dot apply
```

### "Bitwarden session keeps expiring"

**Expected behavior:** Session is shell-scoped for security.

**Workflow:**

```bash
# Unlock once per shell session
dot unlock

# Use secrets in this session
dot apply

# Lock when done (optional)
bw lock
```

---

## Best Practices

### 1. Small, Frequent Commits

```bash
# Good: One logical change
dot edit .zshrc
# Add: alias for new project
dot push -m "Add project alias for flow-cli"

# Bad: Dump of random changes
# (many unrelated edits)
dot push -m "misc changes"
```

### 2. Use Dry-Run Liberally

```bash
# Always preview complex changes
dot apply --dry-run

# Especially for templates with secrets
dot unlock
dot apply --dry-run  # Verify substitution
dot apply            # Apply for real
```

### 3. Lock Vault When Done

```bash
# After template operations
dot unlock
dot apply
bw lock  # Lock vault
```

### 4. Test on Non-Critical Machine First

```bash
# On test machine
dot sync
dot apply --dry-run  # Verify looks good
dot apply

# On production machine (after verification)
dot sync
dot apply
```

### 5. Never Commit Secrets

```bash
# ✅ Good: Use template
export API_KEY="{{ bitwarden "item" "api-key" }}"

# ❌ Bad: Plain text
export API_KEY="sk-abc123..."
```

---

## Summary

You've learned:

- ✅ **Quick edit workflow** with hash-based change detection
- ✅ **Dry-run mode** for safe previews (v5.1.0)
- ✅ **Sync workflows** for multiple machines
- ✅ **Secret management** with Bitwarden templates
- ✅ **Dashboard integration** for status monitoring

### Key Commands

```bash
# Editing
dot edit <file>      # Edit with preview
dot apply --dry-run  # Preview changes
dot apply            # Apply changes

# Syncing
dot sync             # Pull from remote
dot push             # Push to remote
dot status           # Check sync status

# Secrets
dot unlock           # Unlock Bitwarden
dot secret <name>    # Get secret
dot secret list      # List all secrets

# Troubleshooting
dot doctor           # Health check
dot undo             # Rollback last change
```

---

## Next Steps

1. **Set up your dotfiles repo:** `dot init`
2. **Add your first dotfile:** `chezmoi add ~/.zshrc`
3. **Try dry-run mode:** Make an edit, preview with `--dry-run`
4. **Add Bitwarden secret:** Store an API key, use in template
5. **Sync to another machine:** Clone and apply

### Further Reading

- [DOT-WORKFLOW.md](../guides/DOT-WORKFLOW.md) - Complete workflow guide
- [DOT-DISPATCHER-REFERENCE.md](../reference/DOT-DISPATCHER-REFERENCE.md) - Full command reference
- [SECRET-MANAGEMENT.md](../SECRET-MANAGEMENT.md) - Deep dive on Bitwarden integration
- [Chezmoi Documentation](https://www.chezmoi.io/) - Official chezmoi docs

---

**Version:** v5.1.0
**Last Updated:** 2026-01-10
**Tutorial Duration:** ~30 minutes
