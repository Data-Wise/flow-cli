# work

> **Start a focused work session on a project with full context setup**

---

## Synopsis

```bash
work [PROJECT] [-e [EDITOR]]
```

**Quick examples:**

```bash
# Interactive project selection
work

# Start working on specific project (no editor)
work flow-cli

# Open in $EDITOR (default: nvim)
work flow-cli -e

# Open in VS Code
work flow-cli -e code

# Launch Claude Code
work flow-cli -e cc
```

---

## Description

The `work` command is the **primary entry point** for flow-cli. It sets up your entire development context in one command - checking for existing sessions, locating the project, changing directory, recording session start, and displaying context.

By default, `work` does **not** open an editor. Use the `-e` flag to explicitly request one.

**Use cases:**
- Starting focused work sessions
- Switching between projects with session tracking
- Opening projects in preferred editors (with `-e`)
- Maintaining work context and history

---

## Arguments

| Argument  | Description          | Default                                          |
| --------- | -------------------- | ------------------------------------------------ |
| `project` | Project name or path | Interactive picker (if fzf) or current directory |

## Options

| Option             | Description                      | Default          |
| ------------------ | -------------------------------- | ---------------- |
| `-e, --editor`     | Open editor (optionally specify) | `$EDITOR` or `nvim` |
| `-h, --help`       | Show help message                | -                |

---

## What It Does

1. **Checks for existing session** - Prompts to switch if another project is active
2. **Locates the project** - Uses atlas registry or scans `$FLOW_PROJECTS_ROOT`
3. **Changes to project directory** - `cd` to the project root
4. **Starts a session** - Records session start time in atlas
5. **Shows context** - Displays project type, status, and focus
6. **Checks GitHub token** - Shows warning if token is expired/expiring (for GitHub projects)
7. **Opens editor** (only if `-e` flag is passed)

---

## Examples

### Start Working on a Project

```bash
# Just cd + context (most common)
work flow-cli

# Open default editor ($EDITOR or nvim)
work flow-cli -e

# Open in VS Code
work flow-cli -e code

# Open in Positron
work flow-cli -e positron

# Launch Claude Code (acceptEdits mode)
work flow-cli -e cc

# Launch Claude Code (yolo mode)
work flow-cli -e ccy

# New Ghostty window for Claude Code
work flow-cli -e cc:new
```

### Interactive Selection

```bash
# Opens fzf picker if no project specified
work
```

### Use Current Directory

```bash
# If you're already in a project directory
cd ~/projects/my-app
work
```

---

## Output

When you run `work`, you'll see:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 flow-cli (zsh-plugin)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 Status: active
📍 Phase: Active Development
🎯 Focus: Documentation enhancement
```

---

## Session Management

`work` automatically manages your session state:

- **Single active session** - Only one project can be "active" at a time
- **Conflict detection** - Prompts before switching projects
- **Duration tracking** - Session time is recorded for productivity stats

### Check Current Session

```bash
# See what you're working on
flow status

# Or use the quick status
st
```

---

## Editor Support

Editors are only launched when you pass `-e`. The following editors are supported out of the box:

| Editor          | Flag           | Notes                                        |
| --------------- | -------------- | -------------------------------------------- |
| **Nvim**        | `-e` or `-e nvim` | Default if `$EDITOR` not set (recommended) |
| Vim             | `-e vim`       | Classic vi-compatible editor                 |
| VS Code         | `-e code`      | Microsoft Visual Studio Code                 |
| Cursor          | `-e cursor`    | AI-powered VS Code fork                      |
| Emacs           | `-e emacs`     | Uses emacsclient if available                |
| Positron        | `-e positron`  | RStudio-based IDE (macOS only)               |
| Claude Code     | `-e cc`        | `--permission-mode acceptEdits` (blocking)   |
| Claude Code     | `-e ccy`       | Yolo mode (`--dangerously-skip-permissions`) |
| Claude Code     | `-e cc:new`    | New Ghostty window — run `claude` there (macOS) |

Any other command-line editor works too — just pass its name after `-e`.

### Custom Editor

```bash
# Set default editor in .zshrc
export EDITOR="nvim"

# Use -e with no argument to use $EDITOR
work my-project -e

# Or specify per-session
work my-project -e "code-insiders"
```

### Deprecated: Positional Editor Argument

The old syntax `work project editor` still works but shows a deprecation warning:

```bash
# Old (deprecated)
work flow-cli nvim
# ⚠ Positional editor arg deprecated. Use: work flow-cli -e nvim

# New (recommended)
work flow-cli -e nvim
```

### Learning Nvim

**New to nvim?** Flow-cli uses nvim as the default editor, and we've created a comprehensive learning path for beginners:

| Resource | Time | Description |
|----------|------|-------------|
| [Tutorial 15: Nvim Quick Start](../tutorials/15-nvim-quick-start.md) | 10 min | Survival guide - essential commands to get started |
| [Tutorial 16: Vim Motions](../tutorials/16-vim-motions.md) | 15 min | Efficient navigation and editing |
| [Tutorial 17: LazyVim Basics](../tutorials/17-lazyvim-basics.md) | 15 min | Essential plugins (Neo-tree, Telescope, splits) |
| [Tutorial 18: LazyVim Showcase](../tutorials/18-lazyvim-showcase.md) | 30 min | Full feature tour (LSP, Mason, customization) |
| [Nvim Quick Reference](../reference/MASTER-DISPATCHER-GUIDE.md) | - | 1-page printable reference card |

**Interactive tutorial:**

```bash
# Hands-on guided practice with checkpoints
flow nvim-tutorial
```

**Total learning time:** ~70 minutes from zero to productive

!!! tip "Why Nvim?"
    Nvim integrates seamlessly with flow-cli commands:

    - `mcp edit <server>` - Edit MCP configs
    - `dots edit <file>` - Edit dotfiles
    - `r edit` - Edit R package files
    - Works in SSH, tmux, and terminal sessions
    - Extremely fast and lightweight
    - LazyVim provides modern IDE features

---

## Related Commands

| Command               | Description                          |
| --------------------- | ------------------------------------ |
| [`finish`](finish.md) | End the current session              |
| [`hop`](hop.md)       | Quick switch between projects (tmux) |
| [`dash`](dash.md)     | View all projects dashboard          |
| [`pick`](pick.md)     | Interactive project picker           |

---

## Tips

!!! tip "ADHD-Friendly Workflow"
    The `work` command is designed to minimize friction:

    - **One command** to set up everything
    - **No editor by default** — just cd + context, no distractions
    - **`-e` when ready** — open your editor only when you need it
    - **Visual feedback** confirms what's happening

!!! note "Project Detection"
    flow-cli automatically detects your project type (R package, Node.js, Python, ZSH, etc.) and shows the appropriate icon and context.

---

## See Also

- **Tutorial:** [First Session Tutorial](../tutorials/01-first-session.md)
- **Tutorial:** [Multiple Projects Tutorial](../tutorials/02-multiple-projects.md)
- **Reference:** [Workflow Quick Reference](../help/WORKFLOWS.md)

---

**Last Updated:** 2026-02-16
**Command Version:** v7.3.0
**Status:** ✅ Production ready with session tracking and optional editor integration
