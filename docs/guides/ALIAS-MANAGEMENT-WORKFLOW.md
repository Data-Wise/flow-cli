# Alias Management Workflow (v5.4.0)

> **Quick Start:** `flow alias doctor` to check health, `flow alias help` for all commands

---

## Overview

The `flow alias` command provides complete alias lifecycle management:

| Action | Command | Use Case |
|--------|---------|----------|
| Health check | `flow alias doctor` | Find shadows, broken targets |
| Search | `flow alias find <pattern>` | Quick lookup |
| Edit | `flow alias edit` | Direct .zshrc editing |
| Create | `flow alias add` | New alias with validation |
| Remove | `flow alias rm <name>` | Safe removal with backup |
| Test | `flow alias test <name>` | Validate and dry-run |

---

## Daily Workflows

### 1. Quick Health Check

```bash
flow alias doctor
```

**Output shows:**
- Total alias count
- Shadows (aliases hiding system commands)
- Broken targets (commands that don't exist)
- Per-alias status (healthy/shadow/broken)

**Example output:**

```
⚡ ALIAS HEALTH CHECK

📊 SUMMARY
  Total: 45 aliases
  Healthy: 42 (93%)
  Shadows: 2 (cat, gem)
  Broken: 1 (oldcmd)

⚠️  SHADOWS (hiding system commands)
  cat → bat     (shadows /bin/cat)
  gem → gemini  (shadows /usr/bin/gem)

❌ BROKEN TARGETS
  oldcmd → nonexistent_binary
```

### 2. Find an Alias

```bash
# Search by name or command
flow alias find git        # All git-related aliases
flow alias find devtools   # Aliases containing 'devtools'

# Exact match
flow alias find --exact gst
```

### 3. Create a New Alias

**One-liner mode:**

```bash
flow alias add myalias='echo hello world'
```

**Interactive mode (wizard):**

```bash
flow alias add
# Prompts for:
# 1. Alias name
# 2. Command
# Validates:
# - Not a duplicate
# - Doesn't shadow system command
# - Target command exists
```

**Safety checks performed:**
- Duplicate detection: prevents overwriting existing alias
- Shadow warning: alerts if alias name matches system command
- Target validation: warns if target command doesn't exist
- Length check: flags suspiciously long aliases

### 4. Remove an Alias Safely

```bash
flow alias rm myalias
```

**What happens:**
1. Creates backup of .zshrc (`~/.zshrc.alias-backup`)
2. Comments out the alias line (doesn't delete)
3. Shows confirmation

**To undo:** Edit .zshrc and uncomment the line, or restore from backup.

### 5. Test Before Using

```bash
# Show definition + validation
flow alias test gst

# Show what would execute (dry-run)
flow alias test gst --dry-run

# Actually run it
flow alias test gst --exec
```

---

## Integration with flow doctor

Running `flow doctor` now includes a quick alias health summary:

```bash
flow doctor
```

**Output includes:**

```
⚡ ALIASES
  45 aliases (2 shadows, 1 broken)
  Run 'flow alias doctor' for details
```

---

## Common Scenarios

### Scenario 1: "My cat command looks different"

```bash
# Check if it's aliased
flow alias find cat

# Output:
# cat='bat'

# This is intentional - bat is a better cat with syntax highlighting
# If you want the real cat:
command cat file.txt
```

### Scenario 2: "I think I have duplicate aliases"

```bash
# Find all aliases with similar names
flow alias find log

# Output:
# glo='git log --oneline'
# glog='git log --graph'
# gl='git pull'
```

### Scenario 3: "My alias stopped working"

```bash
# Test the alias
flow alias test myalias

# Shows:
# - Definition
# - Whether target command exists
# - Dry-run output
```

### Scenario 4: "I want to add an alias but not sure if name conflicts"

```bash
# Interactive mode validates everything
flow alias add

# Or check manually first
flow alias find myname
which myname
```

---

## File Locations

| File | Purpose |
|------|---------|
| `~/.config/zsh/.zshrc` | Alias definitions |
| `~/.zshrc.alias-backup` | Backup before removals |
| `commands/alias.zsh` | Implementation |

---

## Tips

1. **Use `flow alias doctor` regularly** - catches shadows and broken targets
2. **Prefer interactive mode for new aliases** - validates everything automatically
3. **Test aliases before relying on them** - `flow alias test <name> --dry-run`
4. **Keep backups** - `flow alias rm` creates backups automatically
5. **Check shadows intentionally** - some shadows (like `cat='bat'`) are deliberate

---

## Quick Reference

```bash
# Health check
flow alias doctor

# Search
flow alias find <pattern>
flow alias find --exact <name>

# Create
flow alias add name='cmd'     # One-liner
flow alias add                # Interactive

# Remove (safe)
flow alias rm <name>

# Test
flow alias test <name>
flow alias test <name> --dry-run
flow alias test <name> --exec

# Edit directly
flow alias edit

# Get help
flow alias help
```

---

*Created: 2026-01-12 (v5.4.0)*
