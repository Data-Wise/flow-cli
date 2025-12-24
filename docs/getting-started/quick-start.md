# Quick Start Guide

Get up and running with Flow CLI in 5 minutes.

---

## Step 1: Check Your Setup

The configuration files are already installed in `~/.config/zsh/`. Verify:

```bash
ls ~/.config/zsh/.zshrc
ls ~/.config/zsh/functions/

# Test the new CLI commands
flow --version
flow status
```

---

## Step 2: Try the Enhanced Status Command

Flow CLI now includes beautiful ASCII visualizations:

```bash
flow status          # Basic status with progress bars
flow status -v       # Verbose mode with productivity metrics
flow dashboard       # Interactive real-time TUI (press 'q' to quit)
```

**What you'll see:**

- Active session status with duration
- Today's productivity stats
- Recent sessions with sparkline trends
- Quick action menu
- Flow state indicators 🔥

---

## Step 3: Learn the 6 Core Aliases

These are your daily drivers for R package development:

```bash
rload    # Load package code         (50x/day)
rtest    # Run tests                 (30x/day)
rdoc     # Generate documentation    (20x/day)
rcheck   # R CMD check              (10x/day)
rbuild   # Build tar.gz             (5x/day)
rinstall # Install package          (5x/day)
```

**Try it now:**

```bash
cd ~/projects/r-packages/active/your-package
rload
rtest
```

---

## Step 4: Use Smart Dispatchers

Instead of navigating manually, use context-aware functions:

### Project Picker

```bash
pick     # Fuzzy-find and navigate to any project (10x faster with caching!)
pp       # Same as pick (shorter alias)
```

**Performance:** First scan ~3ms, cached scans <1ms for 60 projects.

### Claude Code

```bash
cc       # Opens Claude in current project root
ccp      # Claude print mode (non-interactive)
ccr      # Resume last session
```

### File Viewer

```bash
peek README.md       # Smart syntax highlighting
peek *.R             # View R files
```

---

## Step 5: Set Up Focus Timers

Stay productive with Pomodoro timers:

```bash
f25      # 25-minute focused session
f50      # 50-minute deep work session
```

During a timer:

- Terminal shows countdown
- Notification when time's up
- Helps combat time blindness

---

## Step 6: Learn Git Plugin Aliases

Standard OMZ git plugin (226+ aliases) is enabled:

```bash
gst      # git status
ga       # git add
gaa      # git add --all
gcmsg    # git commit -m "message"
gp       # git push
glo      # git log --oneline
```

**Try it:**

```bash
gst                          # Check status
ga README.md                 # Stage file
gcmsg "Update documentation" # Commit
gp                           # Push
```

---

## What's Next?

### Learn Through Tutorials

1. [Tutorial 1: Your First Session](../tutorials/01-first-session.md) - Start tracking work
2. [Tutorial 2: Multiple Projects](../tutorials/02-multiple-projects.md) - Manage many projects
3. [Tutorial 3: Status Visualizations](../tutorials/03-status-visualizations.md) - Master ASCII visuals
4. [Tutorial 4: Web Dashboard](../tutorials/04-web-dashboard.md) - Interactive TUI

### Master the Commands

1. [flow status Command](../commands/status.md) - Complete reference
2. [flow dashboard Command](../commands/dashboard.md) - TUI guide
3. [Alias Reference Card](../user/ALIAS-REFERENCE-CARD.md) - All 28 aliases
4. [Workflow Quick Reference](../user/WORKFLOW-QUICK-REFERENCE.md) - Daily workflows

### Customize Your Workflow

- Add aliases if used 10+ times/day
- Create custom dispatcher functions
- Configure focus timer defaults

### Get Help

- All docs: [Documentation Site](https://Data-Wise.github.io/flow-cli/)
- Testing guide: [TESTING.md](../development/TESTING.md)
- Coding standards: [Development Guidelines](../ZSH-DEVELOPMENT-GUIDELINES.md)
- Git plugin: [OMZ Git Plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)

---

**Ready to dive deeper?** Start with [Tutorial 1: Your First Session](../tutorials/01-first-session.md).
