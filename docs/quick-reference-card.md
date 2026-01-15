---
title: 📋 Starter Quick Reference Card
description: Essential commands on one page - print friendly
---

# 📋 Flow CLI Starter Card

!!! info "💾 Printable Version"
    Use your browser's print function (Cmd/Ctrl+P) to save as PDF

---

## 🚀 Core Commands (Start Here)

| Command | What It Does | Example |
|---------|-------------|---------|
| `dash` | 📊 Show all projects | `dash` |
| `work <project>` | 🎯 Start working on project | `work my-app` |
| `why` | 📍 Show current context | `why` |
| `win "message"` | ✅ Log accomplishment | `win "Fixed bug"` |
| `finish` | 🏁 End session | `finish` |
| `pick` | 🔍 Search/pick project (cached for speed) | `pick` |

---

## ⚡ Quick Workflows

### Start Your Day
```bash
dash              # See all projects
just-start        # Auto-pick high priority
work .            # Open in editor
f25               # Start 25-min timer
```

### During Work
```bash
why               # Where am I?
win "did thing"   # Log progress
hop other         # Switch project
```

### End of Day
```bash
status .          # Update progress
wins              # See today's wins
finish            # Close session
```

---

## 🏆 Progress Tracking

| Command | Shows |
|---------|-------|
| `wins` | Today's accomplishments |
| `yay` | Recent wins list |
| `yay --week` | Weekly summary graph |
| `flow goal` | Daily progress bar |
| `trail` | Your breadcrumb trail |

---

## 🔌 Smart Dispatchers

### R Package Development: `r`
```bash
r load            # Load package
r test            # Run tests
r doc             # Generate docs
r help            # Show all commands
```

### Git with Safety: `g`
```bash
g status          # Safe git status
g push            # Push with checks
g new feature-x   # Start feature branch
g help            # Show all commands
```

### Claude Code: `cc`
```bash
cc                # Launch Claude HERE
cc pick           # Open project in Claude
cc wt pick        # Pick worktree → Claude
cc help           # Show all commands
```

### Dotfiles & Secrets: `dot`
```bash
dot               # Show dotfile status
dot secret NAME   # Get Keychain secret (Touch ID)
dot secret add X  # Store in Keychain
dot help          # Show all commands
```

### Prompt Engines: `prompt` (v5.7.0)
```bash
prompt status     # Show current engine
prompt toggle     # Switch engines (menu)
prompt starship   # Switch to Starship
prompt p10k       # Switch to Powerlevel10k
prompt help       # Show all commands
```

### Teaching: `teach` (v5.8.0)
```bash
teach status      # Show course status
teach exam "Name" # Create exam (Scholar)
teach deploy      # Push to production
teach help        # Show all commands
```

### Worktrees: `wt` (v5.10.0)
```bash
wt list           # List all worktrees
wt create <branch> # Create worktree for branch
wt remove <path>  # Remove worktree
wt status         # Health & merge status
wt help           # Show all commands
```

---

## 🔥 Timers & Focus

| Command | Duration | Use For |
|---------|----------|---------|
| `f25` | 25 minutes | Pomodoro |
| `f50` | 50 minutes | Deep work |
| `f <num>` | Custom | Any duration |

---

## 🆘 Emergency Commands

| Problem | Solution |
|---------|----------|
| Commands not found | `source ~/.zshrc` |
| Check if installed | `flow doctor` |
| No projects showing | `status <name> --create` |
| Editor won't open | `code .` manually |

---

## 🎯 Status Values

**State:** `active`, `paused`, `blocked`, `ready`, `done`

**Priority:** `P0` (urgent) → `P4` (someday)

**Update status:**
```bash
status my-project active P0 "Next task description"
```

---

## 📚 Get More Help

- **Full docs:** [https://data-wise.github.io/flow-cli](https://data-wise.github.io/flow-cli)
- **Stuck?:** [Troubleshooting Guide](getting-started/im-stuck.md)
- **Commands:** [Complete Reference](reference/COMMAND-QUICK-REFERENCE.md)
- **Community:** [GitHub Discussions](https://github.com/data-wise/flow-cli/discussions)

---

<small>Flow CLI v5.10.0 | MIT License | [github.com/data-wise/flow-cli](https://github.com/data-wise/flow-cli)</small>
