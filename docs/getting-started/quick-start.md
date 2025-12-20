# Quick Start Guide

Get up and running with ZSH Configuration in 5 minutes.

---

## Step 1: Check Your Setup

The configuration files are already installed in `~/.config/zsh/`. Verify:

```bash
ls ~/.config/zsh/.zshrc
ls ~/.config/zsh/functions/
```

---

## Step 2: Learn the 6 Core Aliases

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

## Step 3: Use Smart Dispatchers

Instead of navigating manually, use context-aware functions:

### Project Picker
```bash
pick     # Fuzzy-find and navigate to any project
pp       # Same as pick (shorter alias)
```

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

## Step 4: Set Up Focus Timers

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

## Step 5: Learn Git Plugin Aliases

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

### Master the Essentials
1. Read [Alias Reference Card](../user/ALIAS-REFERENCE-CARD.md) - All 28 aliases
2. Review [Workflow Quick Reference](../user/WORKFLOW-QUICK-REFERENCE.md) - Daily workflows
3. Explore [Pick Command](../user/PICK-COMMAND-REFERENCE.md) - Project navigation

### Customize Your Workflow
- Add aliases if used 10+ times/day
- Create custom dispatcher functions
- Configure focus timer defaults

### Get Help
- All docs: [Complete Index](../doc-index.md)
- Coding standards: [Development Guidelines](../ZSH-DEVELOPMENT-GUIDELINES.md)
- Git plugin: [OMZ Git Plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)

---

**Ready to dive deeper?** See the full [User Guide](../user/ALIAS-REFERENCE-CARD.md).
