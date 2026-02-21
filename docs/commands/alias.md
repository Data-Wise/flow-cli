# flow alias

> Display, manage, and validate shell aliases

The `flow alias` command provides complete alias lifecycle management - from viewing and searching to creating, testing, and safely removing aliases.

**New in v5.4.0:** Full management suite with validation, health checking, and safe operations.

---

## Usage

```bash
# View aliases
flow alias              # Show all aliases (summary view)
flow alias <category>   # Show specific category aliases

# Manage aliases (v5.4.0)
flow alias doctor       # Health check all aliases
flow alias find <pat>   # Search by name or command
flow alias add          # Create new alias (interactive)
flow alias rm <name>    # Safe removal (backup + comment out)
flow alias test <name>  # Validate and dry-run
flow alias edit         # Open .zshrc at alias section
flow alias help         # Show all commands
```diff

---

## Categories

| Category   | Count | Description                      |
| ---------- | ----- | -------------------------------- |
| `git`      | 11    | Git workflow shortcuts           |
| `cc`       | 3     | Claude Code launcher shortcuts   |
| `pick`     | 4     | Project picker shortcuts         |
| `dash`     | 1     | Dashboard shortcuts              |
| `work`     | 1     | Work session shortcuts           |
| `capture`  | 1     | Capture shortcuts (wins)         |
| `mcp`      | 1     | MCP server shortcuts             |
| `quarto`   | 2     | Quarto publishing shortcuts      |
| `r`        | 4     | R package development shortcuts  |
| `obs`      | 1     | Obsidian shortcuts               |

**Total:** 29 custom aliases

---

## Examples

### View All Aliases (Summary)

```bash
$ flow alias

╭─────────────────────────────────────────────────────────────────────────────╮
│ 🔗 Flow CLI Custom Aliases                                                  │
╰─────────────────────────────────────────────────────────────────────────────╯

📁 Git (11 aliases)
  ga → g add      # Stage files
  gp → g push     # Push to remote
  gc → g commit   # Commit changes
  ...
  flow alias git for details

🤖 Claude Code (3 aliases)
  ccy → cc yolo (YOLO mode - skip permissions)
  ccp → claude -p (print mode)
  ccr → claude -r (resume session)
  flow alias cc for details

...
```yaml

### View Category Details

```bash
$ flow alias cc

🤖 Claude Code Aliases
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ccy    → cc yolo              YOLO mode (skip permissions)
  ccp    → claude -p            Print mode (non-interactive)
  ccr    → claude -r            Resume session picker

Tip: Use cc dispatcher for full Claude workflow
See also: cc help for all Claude commands
```bash

### Common Categories

```bash
# Git aliases
flow alias git

# Project picker aliases
flow alias pick

# R package development
flow alias r

# Quarto publishing
flow alias quarto
```yaml

---

## Features

### ADHD-Optimized Design

- **Visual hierarchy** - Categories clearly separated
- **Quick scanning** - See all aliases at a glance
- **Detail on demand** - Drill down into specific categories
- **Cross-references** - Links to related commands

### Discoverability

- Shows all custom shortcuts in one place
- Organized by domain (git, claude, r, etc.)
- Includes descriptions of what each alias does
- Tips on related commands

### Use Cases

| Scenario                    | Command              |
| --------------------------- | -------------------- |
| Forgot a git shortcut       | `flow alias git`     |
| Discover Claude aliases     | `flow alias cc`      |
| See all available shortcuts | `flow alias`         |
| Find project picker aliases | `flow alias pick`    |
| Learn R package shortcuts   | `flow alias r`       |

---

## Alias Highlights

### Git Workflow (11 aliases)

Most commonly used:

- `ga` → `g add` - Stage files
- `gp` → `g push` - Push to remote
- `gc` → `g commit` - Commit with message
- `gl` → `g log` - Pretty log
- `gundo` → `g undo` - Undo last commit

### Claude Code (3 aliases)

- `ccy` → `cc yolo` - Skip permission prompts (YOLO mode)
- `ccp` → `claude -p` - Print mode (non-interactive)
- `ccr` → `claude -r` - Resume session picker

### Project Picker (4 aliases)

- `pickr` → `pick --recent` - Frecency-sorted projects
- `pickdev` → `pick dev` - Dev tools only
- `pickwt` → `pick wt` - All worktrees
- `pickq` → `pick q` - Quarto projects only

### R Package Development (4 aliases)

- `rtest` → `r test` - Run package tests
- `rcycle` → `r cycle` - Full dev cycle
- `rload` → `r load` - Load package
- `rdoc` → `r doc` - Generate docs

---

## Tips

!!! tip "Combine with help"
    After viewing aliases, use `<dispatcher> help` for full command reference.
    Example: `flow alias cc` → `cc help`

!!! tip "Muscle memory"
    Use aliases consistently to build muscle memory for common workflows.

!!! tip "No conflicts"
    All aliases are carefully chosen to avoid conflicts with system commands.

---

## Management Commands (v5.4.0)

### Doctor - Health Check

```bash
flow alias doctor
```diff

Scans all aliases and reports:

- **Shadows** - Aliases that hide system commands (e.g., `cat='bat'`)
- **Broken targets** - Aliases pointing to non-existent commands
- **Statistics** - Total count, healthy/warning/error counts

```text
⚡ ALIAS HEALTH CHECK

📊 SUMMARY
  Total: 45 aliases
  Healthy: 42 (93%)
  Shadows: 2 (cat, gem)
  Broken: 1 (oldcmd)
```text

### Find - Search Aliases

```bash
flow alias find git        # All git-related aliases
flow alias find --exact gst # Exact match only
```text

### Add - Create Alias

**One-liner mode:**

```bash
flow alias add myalias='echo hello'
```bash

**Interactive mode:**

```bash
flow alias add
# Prompts for name and command with validation
```diff

**Safety checks:**

- Duplicate detection
- Shadow warning (system command conflicts)
- Target validation (command exists?)

### Remove - Safe Deletion

```bash
flow alias rm myalias
```text

**What happens:**

1. Creates backup (`~/.zshrc.alias-backup`)
2. Comments out the line (doesn't delete)
3. Shows confirmation

### Test - Validate & Execute

```bash
flow alias test gst           # Show definition + validation
flow alias test gst --dry-run # Show what would run
flow alias test gst --exec    # Actually execute it
```

---

## Related

- [Alias Reference Card](../reference/MASTER-DISPATCHER-GUIDE.md#aliases) - Complete alias list
- [Alias Management Workflow](../guides/ALIAS-MANAGEMENT-WORKFLOW.md) - Workflow guide
- [Command Quick Reference](../help/QUICK-REFERENCE.md) - All commands
- [Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md) - All dispatchers

---

**Last Updated:** 2026-01-12
**Command Version:** v5.4.0
**Status:** ✅ Production ready with full management suite
