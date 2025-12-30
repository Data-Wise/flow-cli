# Troubleshooting Guide

Common issues and solutions for Flow CLI.

---

## Table of Contents

- [Installation Issues](#installation-issues)
- [Command Not Found Errors](#command-not-found-errors)
- [Dashboard Problems](#dashboard-problems)
- [Project Detection Issues](#project-detection-issues)
- [Status Update Problems](#status-update-problems)
- [Performance Issues](#performance-issues)
- [Git Integration Issues](#git-integration-issues)

---

## Installation Issues

### "zsh functions not loading"

**Symptoms:**

```bash
dash
# zsh: command not found: dash
```

**Cause:** Shell configuration not sourced

**Solution:**

```bash
# Reload shell configuration
source ~/.zshrc

# Or restart terminal
```

**Verify:**

```bash
# Check functions exist
ls ~/.config/zsh/functions/adhd-helpers.zsh

# Check .zshrc sources functions
grep "adhd-helpers" ~/.zshrc
```

### ".zshrc not found"

**Symptoms:**

```bash
source ~/.zshrc
# No such file or directory
```

**Cause:** Flow CLI installed in `~/.config/zsh/` but `.zshrc` not updated

**Solution:**

```bash
# Create/update .zshrc
echo 'source ~/.config/zsh/.zshrc' >> ~/.zshrc

# Reload
source ~/.zshrc
```

### "Functions work but aliases don't"

**Symptoms:**

```bash
dash  # works
rload # zsh: command not found
```

**Cause:** Alias file not sourced

**Solution:**

```bash
# Check if aliases.zsh exists
ls ~/.config/zsh/aliases.zsh

# Check if sourced in .zshrc
grep "aliases.zsh" ~/.config/zsh/.zshrc

# If missing, add:
echo 'source ~/.config/zsh/aliases.zsh' >> ~/.config/zsh/.zshrc
source ~/.zshrc
```

---

## Command Not Found Errors

### "dash: command not found"

**Quick fix:**

```bash
# Option 1: Reload shell
source ~/.zshrc

# Option 2: Check function exists
type dash

# Option 3: Manually source
source ~/.config/zsh/functions/adhd-helpers.zsh
```

**Permanent fix:**

```bash
# Ensure .zshrc sources functions
cat ~/.config/zsh/.zshrc | grep adhd-helpers

# If missing, add:
echo 'source ~/.config/zsh/functions/adhd-helpers.zsh' >> ~/.config/zsh/.zshrc
```

### "flow: command not found"

**Cause:** Plugin not sourced in shell

**Solution:**

```bash
# Check if flow function exists
type flow

# If not found, ensure plugin is sourced in .zshrc:

# Via antidote (recommended)
antidote bundle data-wise/flow-cli

# Or manual source
source /path/to/flow-cli/flow.plugin.zsh

# Reload shell
source ~/.zshrc

# Verify
type flow
```

### "just-start: command not found"

**Cause:** Function not defined

**Solution:**

```bash
# Check if function exists
type just-start

# If not found, source the file
source ~/.config/zsh/functions/adhd-helpers.zsh

# Verify
type just-start
```

---

## Dashboard Problems

### "Dashboard won't launch"

**Symptoms:**

```bash
dash
# Error or blank output
```

**Solutions:**

```bash
# 1. Check terminal supports required features
echo $TERM  # Should be xterm-256color or similar

# 2. Check fzf is installed (for interactive mode)
which fzf
brew install fzf  # If missing

# 3. Reload plugin
source ~/.zshrc

# 4. Try different modes
dash          # Terminal dashboard
dash -i       # Interactive (requires fzf)
dash --fast   # Quick mode
```

### "Dashboard shows no projects"

**Cause:** No `.STATUS` files found

**Solution:**

```bash
# Create .STATUS for existing projects
cd ~/projects/your-category/your-project
flow status your-project --create

# Verify
flow status your-project --show

# Check dashboard
dash
```

### "Dashboard not refreshing"

**Symptoms:** Data doesn't update after changes

**Solutions:**

```bash
# 1. Press 'r' to refresh in dashboard

# 2. Use watch mode for live updates
dash --watch

# 3. Check .STATUS files are being updated
cat ~/projects/category/project/.STATUS

# 4. Restart terminal and reload
source ~/.zshrc
dash
```

---

## Project Detection Issues

### "Project type not detected"

**Symptoms:**

```bash
cd ~/projects/your-project
work .
# Project type not detected, opening in default editor
```

**Cause:** No recognized project files

**Solution:**

```bash
# For R packages, ensure these exist:
ls DESCRIPTION  # R package
ls package.json # Node.js
ls Cargo.toml   # Rust
ls *.qmd        # Quarto

# Or manually specify type:
flow status . --create
# Edit .STATUS file to set type manually
```

### "Wrong editor opens"

**Symptoms:** VS Code opens when you want RStudio

**Solution:**

```bash
# Check project type detection
cd ~/projects/your-project
cat .STATUS | grep type

# For R packages:
# Ensure DESCRIPTION file exists
ls DESCRIPTION

# Edit work function if needed
# (advanced - edit ~/.config/zsh/functions/work.zsh)
```

### "Project not appearing in dashboard"

**Cause:** No `.STATUS` file or wrong location

**Solution:**

```bash
# Check if .STATUS exists
cd ~/projects/category/project
ls -la .STATUS

# If missing, create it:
flow status project-name --create

# Check dashboard
dash
```

---

## Status Update Problems

### "Status update fails"

**Symptoms:**

```bash
flow status project active P0 "Task" 80
# Error: Cannot update status
```

**Solutions:**

```bash
# 1. Check .STATUS file permissions
cd ~/projects/category/project
ls -la .STATUS

# If not writable:
chmod 644 .STATUS

# 2. Check .STATUS format
cat .STATUS
# Should have valid fields

# 3. Try creating fresh
mv .STATUS .STATUS.bak
flow status project --create
```

### "Interactive mode not working"

**Symptoms:** Prompts don't appear

**Solution:**

```bash
# Use quick mode instead:
flow status project active P1 "Task" 50

# Or check terminal:
# Ensure not in non-interactive shell
echo $-
# Should include 'i' for interactive
```

### "Progress not showing in dashboard"

**Cause:** `.STATUS` file format issue

**Solution:**

```bash
# Check .STATUS format
cd ~/projects/category/project
cat .STATUS

# Should have:
# progress: 80

# If missing or malformed, recreate:
flow status project active P1 "Task" 80
```

---

## Performance Issues

### "Dashboard slow to load"

**Symptoms:** Dashboard takes >2 seconds to load

**Solutions:**

```bash
# 1. Use fast mode
dash --fast

# 2. Filter to specific category
dash teaching
dash active

# 3. Check number of projects
ls -d ~/projects/*/* | wc -l
# If >50 projects, consider archiving old ones

# 4. Use targeted commands
dash active    # Only active projects
```

### "Commands feel laggy"

**Symptoms:** `dash` or `status` takes >2 seconds

**Solutions:**

```bash
# 1. Check filesystem speed
time ls ~/projects/*/*/.STATUS

# 2. Reduce project count
# Move completed/archived projects

# 3. Check disk space
df -h ~

# 4. Check for file sync conflicts
# (Dropbox, Google Drive, iCloud)
```

### "High CPU usage"

**Symptoms:** Shell processes consuming high CPU

**Solutions:**

```bash
# 1. Use fast mode for quick checks
dash --fast

# 2. Avoid watch mode unless needed
# dash --watch runs continuously

# 3. Check for runaway processes
ps aux | grep zsh
```

---

## Git Integration Issues

### "Git aliases not working"

**Symptoms:**

```bash
gst
# zsh: command not found: gst
```

**Cause:** OMZ git plugin not loaded

**Solution:**

```bash
# Check if plugin loaded
omz plugin list | grep git

# If not loaded, add to .zshrc:
# plugins=(git other-plugins)

# Or source manually:
source $ZSH/plugins/git/git.plugin.zsh
```

### "gcmsg doesn't work"

**Symptoms:**

```bash
gcmsg "message"
# zsh: command not found: gcmsg
```

**Solution:**

```bash
# Ensure git plugin loaded
grep "plugins=.*git" ~/.zshrc

# If missing, use full command:
git commit -m "message"

# Or add plugin:
# Edit ~/.zshrc, add 'git' to plugins array
```

---

## Less Common Issues

### "Permissions denied"

**Symptoms:**

```bash
flow status project active P0 "Task" 80
# Error: Permission denied
```

**Solution:**

```bash
# Check file permissions
cd ~/projects/category/project
ls -la .STATUS

# Fix permissions:
chmod 644 .STATUS

# Fix directory:
chmod 755 .
```

### "Encoding issues (weird characters)"

**Symptoms:** Dashboard shows `�` or other strange characters

**Solution:**

```bash
# Set UTF-8 encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Add to .zshrc for permanence:
echo 'export LANG=en_US.UTF-8' >> ~/.zshrc
echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshrc
```

### "Time zone issues"

**Symptoms:** Timestamps wrong in dashboard

**Solution:**

```bash
# Check system timezone
date

# Set timezone (example: US Eastern)
export TZ='America/New_York'

# Add to .zshrc:
echo 'export TZ="America/New_York"' >> ~/.zshrc
```

---

## Getting More Help

### Check Logs

```bash
# Enable debug mode
export FLOW_DEBUG=1
source ~/.zshrc

# Run command with debug output
dash 2>&1 | tee debug.log

# Check for shell errors
zsh -x -c 'source flow.plugin.zsh' 2>&1 | head -50
```

### Verify Installation

```bash
# Run health check
flow doctor

# Check all components
type flow work dash pick
type cc g mcp r qu

# Check plugin is sourced
grep -r "flow-cli" ~/.zshrc ~/.config/zsh/
```

### Reset to Defaults

```bash
# Backup current config
cp ~/.config/zsh/.zshrc ~/.config/zsh/.zshrc.backup

# Re-source clean config
source ~/.config/zsh/.zshrc

# If still broken, re-source the plugin:
source /path/to/flow-cli/flow.plugin.zsh

# Or reinstall via antidote:
antidote update data-wise/flow-cli
```

### Report Issues

If you can't solve the issue:

1. **Check existing docs:**
   - [Quick Start](quick-start.md)
   - [Installation](installation.md)
   - [Tutorial 1](../tutorials/01-first-session.md)

2. **Gather debug info:**

   ```bash
   # System info
   echo "OS: $(uname -a)"
   echo "Shell: $SHELL"
   echo "ZSH: $ZSH_VERSION"

   # Flow CLI info
   flow doctor
   type flow
   ls -la ~/.config/zsh/functions/
   ```

3. **Create issue file:**

   ```bash
   # Create detailed bug report
   cat > ~/FLOW-CLI-ISSUE.md <<EOF
   ## Issue Description
   [Describe what's wrong]

   ## Steps to Reproduce
   1. Command I ran: ...
   2. What happened: ...
   3. What I expected: ...

   ## Environment
   OS: $(uname -a)
   Shell: $SHELL
   ZSH Version: $ZSH_VERSION

   ## Error Output
   [Paste error messages]

   ## What I've Tried
   - Tried X: didn't work
   - Tried Y: same error
   EOF
   ```

---

## Quick Reference

**Most Common Fixes:**

```bash
# 1. Reload shell
source ~/.zshrc

# 2. Check function exists
type dash
type flow

# 3. Manually source plugin
source /path/to/flow-cli/flow.plugin.zsh

# 4. Run health check
flow doctor

# 5. Reset dashboard
dash          # Terminal dashboard
dash --fast   # Quick mode
```

---

## See Also

- [Quick Start Guide](quick-start.md)
- [Installation Guide](installation.md)
- [Tutorial 1: First Session](../tutorials/01-first-session.md)
- [Command Reference: status](../commands/status.md)
- [Command Reference: dashboard](../commands/dashboard.md)

---

**Last updated:** 2025-12-30
