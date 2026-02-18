---
tags:
  - tutorial
  - editors
  - work
  - claude-code
---

# Tutorial: Editor Workflow with `work -e`

Control when and how editors open during work sessions. Launch VS Code, Neovim, Positron, or Claude Code with a single flag.

**Time:** 8 minutes | **Level:** Beginner | **Version:** v7.3.0+

## What You'll Learn

1. Starting sessions without an editor (the new default)
2. Opening your preferred editor with `-e`
3. Launching Claude Code in different modes
4. Using the flag in any argument position
5. Migrating from the old positional syntax

---

## Step 1: Start a Session (No Editor)

The `work` command now just sets up context without launching an editor:

```bash
work flow-cli
```

**What happens:**

- Changes to the project directory
- Shows project type, status, and phase
- Starts session tracking
- No editor opens

This is the most common usage — you're already in a terminal and just need context.

---

## Step 2: Open Your Default Editor

Add `-e` to also launch your `$EDITOR`:

```bash
work flow-cli -e
```

If `$EDITOR` is not set, it defaults to `nvim`.

**Tip:** Set your default in `~/.zshrc`:

```bash
export EDITOR="nvim"   # or code, vim, emacs
```

---

## Step 3: Choose a Specific Editor

Pass an editor name after `-e`:

```bash
# VS Code
work flow-cli -e code

# Positron (R IDE, macOS)
work flow-cli -e positron

# Cursor (AI VS Code fork)
work flow-cli -e cursor

# Emacs
work flow-cli -e emacs
```

Any command on your `$PATH` works — `-e` just passes the name to the editor launcher.

---

## Step 4: Launch Claude Code

Three modes are available for Claude Code:

```bash
# Accept-edits mode (recommended for most work)
work flow-cli -e cc

# Yolo mode (skip all permission prompts)
work flow-cli -e ccy

# New Ghostty window (opens window, you run claude there)
work flow-cli -e cc:new
```

| Mode | Flag | What It Does |
|------|------|-------------|
| Standard | `-e cc` | `claude --permission-mode acceptEdits` in current terminal |
| Yolo | `-e ccy` | `claude --dangerously-skip-permissions` (use carefully) |
| New window | `-e cc:new` | Opens a fresh Ghostty window for you to start Claude in |

**Note:** `cc` and `ccy` are blocking — they take over your terminal until you exit Claude Code. Use `cc:new` if you want to keep your current shell free.

---

## Step 5: Flag Position Doesn't Matter

The `-e` flag works before or after the project name:

```bash
# All equivalent:
work flow-cli -e code
work -e code flow-cli
work -e flow-cli         # uses $EDITOR
```

The long form `--editor` also works:

```bash
work flow-cli --editor code
```

---

## Step 6: Migrating from Old Syntax

If you're used to the old positional syntax, it still works but shows a deprecation warning:

```bash
# Old way (deprecated)
work flow-cli nvim
# ⚠ Positional editor arg deprecated. Use: work flow-cli -e nvim

# New way
work flow-cli -e nvim
```

Update any scripts or aliases that use the old form.

---

## Step 7: Quick Reference

| Command | Result |
|---------|--------|
| `work proj` | cd + context only |
| `work proj -e` | + open `$EDITOR` |
| `work proj -e code` | + open VS Code |
| `work proj -e cc` | + Claude Code (acceptEdits) |
| `work proj -e ccy` | + Claude Code (yolo) |
| `work proj -e cc:new` | + new Ghostty window |
| `work proj nvim` | deprecated (warns, still works) |

---

## Checkpoint

After this tutorial, you should be able to:

- [x] Start sessions without an editor launching
- [x] Open any editor with `-e`
- [x] Launch Claude Code in the right mode for your task
- [x] Place the `-e` flag anywhere in the command

---

## What's Next

- **[Tutorial 1: First Session](01-first-session.md)** — Full session lifecycle
- **[Tutorial 10: CC Dispatcher](10-cc-dispatcher.md)** — More Claude Code features
- **[work command reference](../commands/work.md)** — Complete documentation
