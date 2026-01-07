# flow alias

> Display all flow-cli custom aliases organized by category

The `flow alias` command shows all 29 custom aliases defined by flow-cli, organized by category for easy discovery.

---

## Usage

```bash
flow alias              # Show all aliases (summary view)
flow alias <category>   # Show specific category aliases
flow alias help         # Show help
```

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
```

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
```

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
```

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

## Related

- [Alias Reference Card](../reference/ALIAS-REFERENCE-CARD.md) - Complete alias list
- [Command Quick Reference](../reference/COMMAND-QUICK-REFERENCE.md) - All commands
- [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md) - All dispatchers
- [Enhanced Help Quick Start](../guides/ENHANCED-HELP-QUICK-START.md) - Phase 2 features

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (alias v4.9.0)
**Status:** ✅ Production ready with interactive help system
