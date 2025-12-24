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

**Cause:** CLI not installed or not in PATH

**Solution:**

```bash
# Check if CLI exists
ls ~/projects/dev-tools/flow-cli/cli/

# Option 1: Use npm link (recommended)
cd ~/projects/dev-tools/flow-cli
npm link

# Option 2: Add to PATH
echo 'export PATH="$PATH:~/projects/dev-tools/flow-cli/cli"' >> ~/.zshrc
source ~/.zshrc

# Verify
which flow
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
flow dashboard --web
# Error: Cannot start server
```

**Solutions:**

```bash
# 1. Check if port in use
lsof -ti:3000

# If output shows PID, kill it:
lsof -ti:3000 | xargs kill -9

# 2. Try different port
flow dashboard --web --port 8080

# 3. Check Node.js version
node --version
# Should be v18+ or v20+

# 4. Reinstall dependencies
cd ~/projects/dev-tools/flow-cli
npm install
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

### "Dashboard not auto-refreshing"

**Symptoms:** Data doesn't update in web dashboard

**Solutions:**

```bash
# 1. Manual refresh
# Press 'r' in dashboard

# 2. Check refresh interval
flow dashboard --web --interval 5000

# 3. Check browser console for errors
# Open DevTools (F12), check Console tab

# 4. Restart dashboard
# Ctrl+C, then relaunch
```

### "Browser doesn't open automatically"

**Cause:** Browser opening mechanism failed

**Solution:**

```bash
# Dashboard still works, manually open:
open http://localhost:3000/dashboard

# Or visit in any browser:
http://localhost:3000/dashboard
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

**Symptoms:** Web dashboard takes >5 seconds to load

**Solutions:**

```bash
# 1. Reduce refresh rate
flow dashboard --web --interval 10000

# 2. Filter to category
flow dashboard --web --category teaching

# 3. Check number of projects
ls -d ~/projects/*/* | wc -l
# If >50 projects, consider archiving old ones

# 4. Clear browser cache
# Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)
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

**Symptoms:** Dashboard consuming >10% CPU

**Solutions:**

```bash
# 1. Use slower refresh
flow dashboard --web --interval 30000

# 2. Use terminal dashboard instead
flow dashboard  # TUI uses less resources

# 3. Close when not viewing
# Ctrl+C to stop
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
# Terminal output when running commands
flow dashboard --web 2>&1 | tee dashboard.log

# Check system logs (macOS)
log show --predicate 'process == "node"' --last 1h

# Check system logs (Linux)
journalctl -u flow-cli -n 50
```

### Verify Installation

```bash
# Check all components
ls ~/.config/zsh/functions/adhd-helpers.zsh
ls ~/projects/dev-tools/flow-cli/cli/
node --version
npm --version
which flow

# Check sourcing
grep -r "adhd-helpers" ~/.zshrc ~/.config/zsh/
```

### Reset to Defaults

```bash
# Backup current config
cp ~/.config/zsh/.zshrc ~/.config/zsh/.zshrc.backup

# Re-source clean config
source ~/.config/zsh/.zshrc

# If still broken, reinstall:
cd ~/projects/dev-tools/flow-cli
npm install
npm link
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
   echo "Node: $(node --version)"

   # Flow CLI info
   which flow
   flow --version 2>&1
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
   Shell: $SHELL ($ZSH_VERSION)
   Node: $(node --version)

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
type just-start

# 3. Manually source functions
source ~/.config/zsh/functions/adhd-helpers.zsh

# 4. Reinstall CLI
cd ~/projects/dev-tools/flow-cli
npm install && npm link

# 5. Reset dashboard
# Ctrl+C to stop, then:
flow dashboard --web
```

---

## See Also

- [Quick Start Guide](quick-start.md)
- [Installation Guide](installation.md)
- [Tutorial 1: First Session](../tutorials/01-first-session.md)
- [Command Reference: status](../commands/status.md)
- [Command Reference: dashboard](../commands/dashboard.md)

---

**Last updated:** 2025-12-24
