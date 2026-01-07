# work

> **Start a focused work session on a project with full context setup**

---

## Synopsis

```bash
work [PROJECT] [EDITOR]
```

**Quick examples:**
```bash
# Interactive project selection
work

# Start working on specific project
work flow-cli

# With specific editor
work flow-cli cursor
```

---

## Description

The `work` command is the **primary entry point** for flow-cli. It sets up your entire development context in one command - checking for existing sessions, locating the project, changing directory, recording session start, displaying context, and opening your editor.

**Use cases:**
- Starting focused work sessions
- Switching between projects with session tracking
- Opening projects in preferred editors
- Maintaining work context and history

---

## Options

## Arguments

| Argument  | Description          | Default                                          |
| --------- | -------------------- | ------------------------------------------------ |
| `project` | Project name or path | Interactive picker (if fzf) or current directory |
| `editor`  | Editor to open       | `$EDITOR` or `code`                              |

---

## What It Does

1. **Checks for existing session** - Prompts to switch if another project is active
2. **Locates the project** - Uses atlas registry or scans `$FLOW_PROJECTS_ROOT`
3. **Changes to project directory** - `cd` to the project root
4. **Starts a session** - Records session start time in atlas
5. **Shows context** - Displays project type, status, and focus
6. **Opens your editor** - Launches VS Code, Cursor, Vim, Emacs, etc.

---

## Examples

### Start Working on a Project

```bash
# Start working on flow-cli
work flow-cli

# With a specific editor
work flow-cli cursor

# Use vim
work my-project vim
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

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 flow-cli (zsh-plugin)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 Status: active
📍 Phase: v4.0.1 Released
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

The `work` command supports these editors out of the box:

| Editor     | Command                | Notes                         |
| ---------- | ---------------------- | ----------------------------- |
| VS Code    | `code`                 | Default if `$EDITOR` not set  |
| Cursor     | `cursor`               | AI-powered VS Code fork       |
| Vim/Neovim | `vim`, `nvim`          | Opens in terminal             |
| Emacs      | `emacs`, `emacsclient` | Uses emacsclient if available |
| Positron   | `positron`             | RStudio-based IDE (macOS)     |

### Custom Editor

```bash
# Set default editor in .zshrc
export EDITOR="nvim"

# Or specify per-session
work my-project "code-insiders"
```

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
    - **Smart defaults** so you rarely need arguments
    - **Visual feedback** confirms what's happening

!!! note "Project Detection"
flow-cli automatically detects your project type (R package, Node.js, Python, ZSH, etc.) and shows the appropriate icon and context.

---

## See Also

- **Tutorial:** [First Session Tutorial](../tutorials/01-first-session.md)
- **Tutorial:** [Multiple Projects Tutorial](../tutorials/02-multiple-projects.md)
- **Reference:** [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0
**Status:** ✅ Production ready with session tracking and editor integration
