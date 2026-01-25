# flow

> **Unified CLI dispatcher for all flow-cli commands with ADHD-friendly helpers**

The `flow` command is the main entry point for the flow-cli plugin. It provides access to all subcommands through a unified namespace.

---

## Synopsis

```bash
flow <command> [args]
flow help [command]
```

**Quick examples:**

```bash
# Get help
flow help                      # Show all commands
flow help work                 # Help for specific command

# Core workflow
flow work my-project           # Start session (or just: work my-project)
flow dash                      # Dashboard (or just: dash)
flow finish "Done!"            # End session (or just: finish "Done!")

# ADHD helpers
flow start                     # Just start (picks for you)
flow stuck                     # Get unstuck
flow win "Did the thing"       # Log a win
```

---

## Usage

```bash
flow <command> [args]
```

## Getting Help

```bash
flow help              # Show all commands
flow help -i           # Interactive help browser (fzf) - NEW in v4.9.0
flow help <command>    # Help for specific command
flow help --list       # List all commands
flow help --search <term>  # Search commands
```

## Aliases

```bash
flow alias             # Show all custom aliases (29 total)
flow alias <category>  # Show category aliases (e.g., flow alias cc)
```

**Categories:** `git`, `cc` (Claude Code), `pick`, `dash`, `work`, `capture`, `mcp`, `quarto`, `r`, `obs`

---

## Command Categories

### Core Workflow

| Command                | Description                    |
| ---------------------- | ------------------------------ |
| `flow work <project>`  | Start focused work session     |
| `flow pick [category]` | Interactive project picker     |
| `flow dash [scope]`    | Project dashboard              |
| `flow finish [note]`   | End session, optionally commit |
| `flow hop <project>`   | Quick switch (tmux)            |
| `flow why`             | Show current context           |

### ADHD Helpers

| Command             | Description                |
| ------------------- | -------------------------- |
| `flow start`, `js`  | Just start (picks for you) |
| `flow stuck`        | Get unstuck when blocked   |
| `flow focus <text>` | Set current focus          |
| `flow next`         | What to work on next       |
| `flow break [min]`  | Take a proper break        |

### Capture & Track

| Command             | Description              |
| ------------------- | ------------------------ |
| `flow catch <idea>` | Quick capture to inbox   |
| `flow crumb <note>` | Leave breadcrumb         |
| `flow inbox`        | View inbox               |
| `flow win <text>`   | Log a win                |
| `flow goal [set n]` | Daily win goal tracking  |
| `flow status`       | View/update .STATUS file |

### Context-Aware Actions

| Command        | Description                   |
| -------------- | ----------------------------- |
| `flow test`    | Run tests (auto-detects type) |
| `flow build`   | Build project                 |
| `flow preview` | Preview output                |
| `flow sync`    | Smart git sync                |
| `flow check`   | Health check (lint, types)    |
| `flow plan`    | Sprint/project planning       |
| `flow log`     | Activity log                  |

### Timer & Routine

| Command            | Description             |
| ------------------ | ----------------------- |
| `flow timer [min]` | Start focus timer       |
| `flow morning`     | Morning startup routine |

### Setup & Diagnostics

| Command        | Description                 |
| -------------- | --------------------------- |
| `flow doctor`  | Check dependencies & health |
| `flow setup`   | Interactive setup wizard    |
| `flow install` | Install tools               |
| `flow upgrade` | Update flow-cli             |
| `flow learn`   | Interactive tutorial        |

### AI-Powered

| Command             | Description               |
| ------------------- | ------------------------- |
| `flow ai <query>`   | Ask AI anything           |
| `flow do "request"` | Natural language commands |

### Configuration

| Command            | Description        |
| ------------------ | ------------------ |
| `flow config show` | Show settings      |
| `flow config set`  | Set a config value |
| `flow plugin`      | Manage plugins     |

---

## Direct Command Access

Most commands work directly without the `flow` prefix:

```bash
# These are equivalent:
flow work my-project
work my-project

# Direct access commands:
work, pick, dash, finish, hop, why
catch, crumb, inbox, win
timer, morning
doctor, status
```

---

## Examples

### Starting Your Day

```bash
# Morning routine
flow morning

# Or quick version
am

# Start working
flow work my-project
# or just
work my-project
```

### During Work

```bash
# Log wins as you go
flow win "Fixed the auth bug"

# Check progress
flow status

# Take a break
flow break 5
```

### Context-Aware Actions

```bash
# Run tests (auto-detects R/Node/Python)
flow test

# Build project (auto-detects Quarto/npm/R CMD)
flow build

# Preview output
flow preview
```

### Getting Help

```bash
# Search for git-related commands
flow help --search git

# Get help on sync
flow help sync

# List all available commands
flow help --list
```

---

## Dispatchers

Flow-cli includes domain-specific dispatchers that are separate from the `flow` command:

| Dispatcher | Domain            | Example              |
| ---------- | ----------------- | -------------------- |
| `g`        | Git workflows     | `g push`, `g status` |
| `r`        | R package dev     | `r test`, `r check`  |
| `qu`       | Quarto publishing | `qu preview`         |
| `mcp`      | MCP servers       | `mcp status`         |
| `obs`      | Obsidian notes    | `obs daily`          |
| `cc`       | Claude Code       | `cc`, `cc pick`      |

Get help for any dispatcher with `<dispatcher> help`.

---

## Version

```bash
flow version
# flow-cli v4.0.1
```

---

## Tips

!!! tip "Use Direct Commands"
For common commands like `work`, `dash`, `pick`, skip the `flow` prefix for speed.

!!! tip "Search When Unsure"
Use `flow help --search <term>` to find commands you don't remember.

!!! tip "Tab Completion"
If you have completions installed, `flow <Tab>` shows available commands.

---

## See Also

- **Reference:** [Command Quick Reference](../help/QUICK-REFERENCE.md) - All commands at a glance
- **Reference:** [Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md) - Domain-specific dispatchers
- **Guide:** [Getting Started](../getting-started/quick-start.md) - 5-minute quick start

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0
**Status:** ✅ Production ready with unified namespace
