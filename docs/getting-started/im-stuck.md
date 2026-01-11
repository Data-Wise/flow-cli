---
title: 🆘 I'm Stuck - Troubleshooting Guide
description: Quick solutions when Flow CLI isn't working as expected
---

# 🆘 I'm Stuck

!!! tldr "TL;DR - Try These First (30 seconds)"
    ```bash
    source ~/.zshrc              # Reload shell
    flow doctor                  # Run diagnostics
    ls ~/.config/zsh/functions/  # Check installation
    ```

---

## 🔧 Quick Fixes

Try these in order - most common solutions first:

### ❌ "Command not found: dash" / "Command not found: work"

**What this means:** Flow CLI commands aren't loaded in your shell.

**Fix it:**
```bash
# Option 1: Reload your shell config
source ~/.zshrc

# Option 2: Check if functions file exists
ls ~/.config/zsh/functions/adhd-helpers.zsh

# Option 3: Reinstall
brew reinstall flow-cli  # If using Homebrew
```

**Why this works:** Shell needs to source the Flow CLI functions after installation.

---

### ❌ "No projects found"

**What this means:** Flow CLI can't find any projects with `.STATUS` files.

**Fix it:**
```bash
# Check your projects directory
ls ~/projects/

# Create .STATUS for an existing project
cd ~/projects/your-project
status your-project --create

# Or use quick mode
status your-project ready P2 "Initial setup"
```

**Why this works:** Flow CLI tracks projects using `.STATUS` files.

---

### ❌ "Editor didn't open" / "work command does nothing"

**What this means:** Project type not detected or editor not in PATH.

**Fix it:**
```bash
# Check what's in your project
cd ~/projects/your-project
ls -la

# Manually open your preferred editor
code .        # VS Code
rstudio .     # RStudio
emacs .       # Emacs

# Check if editor is in PATH
which code    # Should show path to executable
```

**Why this works:** `work` command tries to auto-detect project type. If detection fails, use editor directly.

---

### ❌ Timer not showing / "f25 command not found"

**What this means:** Timer functions not loaded or tmux not installed.

**Fix it:**
```bash
# Check if tmux is installed
which tmux

# Install if needed (macOS)
brew install tmux

# Reload shell
source ~/.zshrc
```

---

### ❌ Wins not logging / "win command does nothing"

**What this means:** Worklog file permissions or path issue.

**Fix it:**
```bash
# Check worklog file
ls -la ~/.config/zsh/.worklog

# Create if missing
touch ~/.config/zsh/.worklog
chmod 644 ~/.config/zsh/.worklog

# Try again
win "Test win"
```

---

## 🔍 Still Stuck?

### Run Full Diagnostics
```bash
flow doctor
```

This checks:
- ✓ Installation paths
- ✓ Required dependencies
- ✓ Configuration files
- ✓ Project detection
- ✓ Common issues

### Check Your Setup
```bash
# Verify installation
echo $PATH | grep flow-cli

# Check ZSH config
cat ~/.zshrc | grep flow

# Verify project structure
tree ~/projects/ -L 2
```

---

## 🆘 Emergency Contacts

### Search the Docs
Use the search bar (top right) to find specific commands or concepts.

### Common Issues Database
- [Installation Problems](troubleshooting.md#installation)
- [Project Detection Issues](../reference/PROJECT-DETECTION-GUIDE.md)
- [Command Reference](../reference/COMMAND-QUICK-REFERENCE.md)

### Ask the Community
- **GitHub Discussions**: [Ask a Question](https://github.com/data-wise/flow-cli/discussions)
- **GitHub Issues**: [Report a Bug](https://github.com/data-wise/flow-cli/issues/new)

---

## 📚 Next Steps

Once you're unstuck:

!!! success "You're back on track!"
    - [Try the Quick Start →](quick-start.md)
    - [Complete Your First Session →](../tutorials/01-first-session.md)
    - [Learn Core Commands →](../reference/COMMAND-QUICK-REFERENCE.md)
