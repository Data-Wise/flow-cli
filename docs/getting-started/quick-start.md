# Quick Start Guide

> **TL;DR:** Get up and running with Flow CLI in 5 minutes - install, start a session, log wins, finish.

---

## 30-Second Setup

```bash
# 1. Verify installation
flow --version

# 2. Start a session
work

# 3. Log a win
win "Set up flow-cli"

# 4. End session
finish
```

---

## The Core Workflow

Flow CLI is built around a simple, ADHD-friendly workflow:

```bash
work my-project     # 1. Start a focused session
# ... do your work ...
win "Did the thing"  # 2. Log your wins
finish "Done!"       # 3. End and optionally commit
```

**That's it!** Everything else builds on this foundation.

---

## Step 1: Verify Installation

Check that flow-cli is loaded:

```bash
# Should show version
flow --version

# Should show help
flow help
```

If commands aren't found, ensure the plugin is sourced in your `.zshrc`:

```bash
# Via antidote
antidote load data-wise/flow-cli

# Or manual source
source /path/to/flow-cli/flow.plugin.zsh
```

---

## Step 2: Start Your First Session

```bash
# Start working on a project
work my-project

# Or use the interactive picker
work
```

You'll see:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 my-project (node)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 Status: active
🎯 Focus: Implement new feature
```

**What happened:**

- Changed to project directory
- Started session tracking
- Opened your editor
- Showed project context

---

## Step 3: Log Your Wins

As you accomplish things, log them:

```bash
win "Implemented user login"
win "Fixed that annoying bug"
win --ship "Deployed to production"
```

Output:

```
🎉 WIN LOGGED! #code
Implemented user login

Keep it up! 🚀
```

### Win Categories

Wins are auto-categorized, or you can specify:

| Flag       | Category      | Icon |
| ---------- | ------------- | ---- |
| `--code`   | Code work     | 💻   |
| `--docs`   | Documentation | 📝   |
| `--fix`    | Bug fix       | 🔧   |
| `--ship`   | Deployed      | 🚀   |
| `--test`   | Testing       | 🧪   |
| `--review` | Code review   | 👀   |

---

## Step 4: Check Your Progress

```bash
# Quick dashboard
dash

# Show recent wins
yay

# Weekly summary with graph
yay --week
```

**What you'll see:**

![Dashboard Example](../assets/dashboard-example.png)

*The dashboard shows your active session, quick access to recent projects, wins tracker, and category breakdown*

---

## Step 5: End Your Session

```bash
# End session with a note
finish "Completed auth feature"

# You'll be prompted to commit if there are changes
# Commit 3 change(s)? [y/N] y
# ✓ Changes committed
```

---

## Daily Goals (Optional)

Set and track daily win goals:

```bash
# Set a goal of 3 wins per day
flow goal set 3

# Check progress
flow goal
# Today: ██████░░░░ 2/3 wins
```

---

## Essential Commands

### Workflow

| Command          | Description                    |
| ---------------- | ------------------------------ |
| `work [project]` | Start a focused session        |
| `finish [note]`  | End session, optionally commit |
| `hop <project>`  | Quick switch (tmux)            |
| `dash`           | Project dashboard              |

### Capture & Celebrate

| Command        | Description           |
| -------------- | --------------------- |
| `win <text>`   | Log an accomplishment |
| `yay`          | Show recent wins      |
| `catch <text>` | Quick idea capture    |
| `crumb <text>` | Leave a breadcrumb    |

### Navigation

| Command   | Description                |
| --------- | -------------------------- |
| `pick`    | Interactive project picker |
| `cc`      | Launch Claude Code         |
| `cc pick` | Pick project → Claude Code |

---

## Smart Dispatchers

Flow CLI includes 6 domain-specific dispatchers:

| Dispatcher | Domain      | Example                    |
| ---------- | ----------- | -------------------------- |
| `g`        | Git         | `g status`, `g push`       |
| `r`        | R packages  | `r test`, `r check`        |
| `qu`       | Quarto      | `qu preview`, `qu render`  |
| `mcp`      | MCP servers | `mcp status`, `mcp logs`   |
| `obs`      | Obsidian    | `obs daily`, `obs search`  |
| `cc`       | Claude Code | `cc`, `cc pick`, `cc yolo` |

Get help for any dispatcher:

```bash
g help
r help
cc help
```

---

## What's Next?

### Tutorials (Recommended)

1. [Your First Session](../tutorials/01-first-session.md) - Deep dive into `work`
2. [Multiple Projects](../tutorials/02-multiple-projects.md) - Managing many projects
3. [AI-Powered Commands](../tutorials/05-ai-commands.md) - Using `flow ai`

### Reference

- [Command Quick Reference](../help/QUICK-REFERENCE.md)
- [Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md)
- [Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md)

### Get Help

```bash
# Built-in help
flow help
dash --help
work --help

# Health check
flow doctor
```

---

## ADHD Tips

!!! tip "One Command to Start"
Just type `work` and let the picker guide you. No need to remember project paths.

!!! tip "Log Wins Immediately"
Don't wait - log wins as they happen. Each `win` gives you a dopamine boost!

!!! tip "Use Breadcrumbs"
Before switching contexts, run `crumb "was working on X"` so you can pick up later.

---

**Ready to dive deeper?** Start with [Tutorial 1: Your First Session](../tutorials/01-first-session.md).
