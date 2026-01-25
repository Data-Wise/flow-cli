# Troubleshooting Guide

**Purpose:** Common issues and solutions for flow-cli
**Audience:** All users experiencing problems
**Format:** Problem → Diagnosis → Solution
**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24

---

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Installation Issues](#installation-issues)
- [Command Not Found Errors](#command-not-found-errors)
- [Git Integration Problems](#git-integration-problems)
- [Token & Authentication Issues](#token--authentication-issues)
- [Performance Problems](#performance-problems)
- [Plugin Issues](#plugin-issues)
- [Atlas Integration Issues](#atlas-integration-issues)
- [Teaching Workflow Issues](#teaching-workflow-issues)
- [Configuration Problems](#configuration-problems)

---

## Quick Diagnostics

### Health Check (Start Here)

**Always run this first before reporting issues:**

```bash
flow doctor
```

**Output shows:**
- Dependencies status (git, zsh, fzf, etc.)
- Git configuration
- Token status
- Configuration validation
- Atlas connection
- Plugin health

**Quick fixes available:**

```bash
flow doctor --fix        # Interactive fix mode
flow doctor --dot        # Token check only (< 3s)
flow doctor --fix-token  # Fix token issues only
```

---

## Installation Issues

### Issue: flow-cli commands not recognized

**Symptom:**
```bash
work
# Output: command not found: work
```

**Diagnosis:**

```bash
# Check if plugin is loaded
which work
# Output: (nothing) = not loaded

# Check .zshrc
grep "flow.plugin.zsh" ~/.zshrc
# OR
grep "flow-cli" ~/.config/zsh/.zshrc
```

**Solution 1: Plugin not sourced**

```bash
# Add to ~/.zshrc or ~/.config/zsh/.zshrc
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh

# Reload shell
exec zsh
```

**Solution 2: Using plugin manager**

For antidote:
```bash
# Add to ~/.zsh_plugins.txt
~/projects/dev-tools/flow-cli

# Update plugins
antidote update
```

For zinit:
```bash
# Add to ~/.zshrc
zinit light ~/projects/dev-tools/flow-cli
```

---

### Issue: Installation via curl failed

**Symptom:**
```bash
curl: (7) Failed to connect to raw.githubusercontent.com
```

**Solution:**

```bash
# Clone manually
git clone https://github.com/Data-Wise/flow-cli.git ~/projects/dev-tools/flow-cli

# Source in .zshrc
echo 'source ~/projects/dev-tools/flow-cli/flow.plugin.zsh' >> ~/.zshrc

# Reload
exec zsh
```

---

### Issue: Dependencies missing

**Symptom:**
```bash
flow doctor
# Output: ❌ git not found
#         ❌ fzf not found
```

**Solution:**

```bash
# Run interactive fix
flow doctor --fix
# OR install manually:

# macOS
brew install git fzf

# Linux (Ubuntu/Debian)
sudo apt-get install git fzf

# Then reload shell
exec zsh
```

---

## Command Not Found Errors

### Issue: "command not found: <dispatcher>"

**Example:**
```bash
g status
# Output: command not found: g
```

**Diagnosis:**

```bash
# Check if flow-cli is loaded
which work
# If work exists but g doesn't, dispatcher not loaded

# Check for errors
flow doctor
```

**Solution:**

```bash
# Reload shell
exec zsh

# If still failing, check dispatcher file exists
ls -la ~/projects/dev-tools/flow-cli/lib/dispatchers/g-dispatcher.zsh

# Source manually to test
source ~/projects/dev-tools/flow-cli/lib/dispatchers/g-dispatcher.zsh

# Try command
g status
```

---

### Issue: Specific command works but subcommand doesn't

**Example:**
```bash
g status        # Works
g feature start # command not found: feature
```

**Diagnosis:**

```bash
# Check help
g help

# If help shows feature, but command doesn't work:
# dispatcher partially loaded
```

**Solution:**

```bash
# Reload plugin completely
unset -f g  # Unset function
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh
exec zsh
```

---

## Git Integration Problems

### Issue: Git push fails with authentication error

**Symptom:**
```bash
g push
# Output: remote: Invalid username or password.
#         fatal: Authentication failed
```

**Diagnosis:**

```bash
# Check token
flow doctor --dot=github

# Check git credential helper
git config --global credential.helper
```

**Solution 1: Token expired**

```bash
# Check expiration
flow doctor --dot

# Rotate if needed
dot secret rotate GITHUB_TOKEN

# OR set in environment
export GITHUB_TOKEN="ghp_your_new_token"
```

**Solution 2: Keychain issue (macOS)**

```bash
# Unlock keychain
dot unlock

# If Touch ID fails:
security unlock-keychain ~/Library/Keychains/login.keychain-db

# Set keychain helper
git config --global credential.helper osxkeychain
```

**Solution 3: HTTPS vs SSH**

```bash
# Check remote URL
git remote -v
# If https:// and you want SSH:

git remote set-url origin git@github.com:username/repo.git
```

---

### Issue: Git operations very slow

**Symptom:**
```bash
g status
# Takes 10+ seconds
```

**Diagnosis:**

```bash
# Check repo size
du -sh .git

# Check if in large worktree
git worktree list

# Check for network issues
time git ls-remote origin
```

**Solution 1: Large repo**

```bash
# Use sparse checkout
git sparse-checkout init --cone
git sparse-checkout set <paths>

# OR shallow clone
git clone --depth 1 <repo>
```

**Solution 2: Git gc needed**

```bash
# Garbage collect
git gc --aggressive

# Prune
git prune

# Verify
du -sh .git  # Should be smaller
```

---

### Issue: Merge conflicts

**Symptom:**
```bash
g pull
# Output: CONFLICT (content): Merge conflict in file.txt
```

**Solution:**

```bash
# See conflicted files
g status

# Resolve manually
$EDITOR file.txt
# Remove conflict markers: <<<<<<<, =======, >>>>>>>

# Mark resolved
g add file.txt

# Complete merge
g commit

# OR abort merge
git merge --abort
```

---

## Token & Authentication Issues

### Issue: Token check takes too long

**Symptom:**
```bash
flow doctor --dot
# Takes 60+ seconds
```

**Solution:**

```bash
# Use cached check (v5.17.0+)
flow doctor --dot
# Should be < 3s with cache

# If still slow, check network
curl -I https://api.github.com
# Should respond quickly

# Clear cache and retry
rm -f ~/.cache/flow/doctor/tokens.cache
flow doctor --dot
```

---

### Issue: Token rotation fails

**Symptom:**
```bash
dot secret rotate GITHUB_TOKEN
# Output: Error: Failed to update keychain
```

**Solution 1: Keychain locked**

```bash
# Unlock keychain
dot unlock

# Retry rotation
dot secret rotate GITHUB_TOKEN
```

**Solution 2: Touch ID not working**

```bash
# Check Touch ID in System Preferences
# System Preferences → Touch ID & Password

# OR use password fallback
# When prompted for Touch ID, click "Enter Password"
```

**Solution 3: Keychain permissions**

```bash
# Grant iTerm2/Terminal accessibility
# System Preferences → Privacy & Security → Accessibility
# Enable iTerm2 or Terminal.app
```

---

### Issue: "Token not found in keychain"

**Symptom:**
```bash
dot secret get GITHUB_TOKEN
# Output: Error: Token not found
```

**Solution:**

```bash
# Store token
dot secret set GITHUB_TOKEN
# Enter token when prompted

# Verify
dot secret list
# Should show GITHUB_TOKEN
```

---

## Performance Problems

### Issue: Commands are slow (> 100ms)

**Symptom:**
```bash
work my-project
# Takes 2-3 seconds
```

**Diagnosis:**

```bash
# Check Atlas connection
flow doctor
# Look for Atlas status

# Profile command
time work my-project
```

**Solution 1: Atlas connection slow**

```bash
# Disable Atlas temporarily
export FLOW_ATLAS_ENABLED=no
exec zsh

# Check if faster
time work my-project
```

**Solution 2: Cache issues**

```bash
# Clear project cache
rm -rf ~/.cache/flow/projects/*.cache

# Rebuild cache
dash  # Will rebuild cache
```

**Solution 3: Too many projects**

```bash
# Limit project scan
export FLOW_PROJECTS_ROOT="$HOME/projects/active"
# Only scan active directory

exec zsh
```

---

### Issue: Dashboard takes forever to load

**Symptom:**
```bash
dash
# Takes 10+ seconds
```

**Solution:**

```bash
# Use filter
dash dev          # Only dev projects
dash --recent     # Only recent 10

# Rebuild cache
rm -rf ~/.cache/flow/projects/*.cache

# Check for stuck Git operations
# In large repos, git status can be slow
```

---

## Plugin Issues

### Issue: git plugin aliases not working

**Symptom:**
```bash
gst
# Output: command not found: gst
```

**Diagnosis:**

```bash
# Check if Oh-My-Zsh git plugin loaded
type gst
# Should show: gst is an alias for git status

# Check plugin manager
antidote list
# Should show git plugin
```

**Solution 1: Plugin not loaded**

```bash
# For antidote, add to ~/.zsh_plugins.txt:
ohmyzsh/ohmyzsh path:plugins/git

# Update plugins
antidote update
exec zsh
```

**Solution 2: Alias conflicts**

```bash
# Check for conflicts
alias gst
# If shows different alias, unalias first

unalias gst
# Then reload plugins
exec zsh
```

---

### Issue: fzf not working in pick command

**Symptom:**
```bash
pick
# Output: No fzf found, falling back to basic picker
```

**Solution:**

```bash
# Install fzf
brew install fzf

# Run fzf install
$(brew --prefix)/opt/fzf/install

# Reload shell
exec zsh

# Verify
which fzf
# Output: /opt/homebrew/bin/fzf
```

---

## Atlas Integration Issues

### Issue: "Atlas connection failed"

**Symptom:**
```bash
flow doctor
# Output: ⚠️  Atlas: Connection failed (timeout)
```

**Solution 1: Atlas not running**

```bash
# Check if Atlas is running
pgrep atlas || echo "Atlas not running"

# Start Atlas (if installed)
# Refer to Atlas documentation
```

**Solution 2: Disable Atlas**

```bash
# flow-cli works fine without Atlas
export FLOW_ATLAS_ENABLED=no
exec zsh

# Verify
flow doctor
# Should show: Atlas: Disabled (manual)
```

**Solution 3: Auto-detect**

```bash
# Let flow-cli auto-detect
export FLOW_ATLAS_ENABLED=auto
exec zsh

# flow-cli will use Atlas if available, skip if not
```

---

## Teaching Workflow Issues

### Issue: "teach command not found"

**Symptom:**
```bash
teach init
# Output: command not found: teach
```

**Solution:**

```bash
# teach is a dispatcher, check if loaded
g help  # If this works, reload:
exec zsh

# If still failing:
source ~/projects/dev-tools/flow-cli/lib/dispatchers/teach-dispatcher.zsh
teach help
```

---

### Issue: "Scholar not found" error

**Symptom:**
```bash
teach exam "Midterm"
# Output: Error: Scholar CLI not installed
```

**Solution:**

```bash
# Check Scholar status
teach scholar status

# Install Scholar (if missing)
# Follow Scholar installation guide

# Verify
which scholar
# Output: /path/to/scholar
```

---

### Issue: Quarto rendering fails

**Symptom:**
```bash
qu render lecture.qmd
# Output: ERROR: Quarto not found
```

**Solution:**

```bash
# Install Quarto
# macOS:
brew install --cask quarto

# Linux:
# Download from https://quarto.org/docs/get-started/

# Verify
quarto --version

# Reload shell
exec zsh
```

---

### Issue: GitHub Pages deployment fails

**Symptom:**
```bash
teach deploy
# Output: Error: gh CLI not found
```

**Solution:**

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Verify
gh auth status

# Retry deployment
teach deploy
```

---

## Configuration Problems

### Issue: .STATUS file not recognized

**Symptom:**
```bash
dash my-project
# Progress: 0% (expected 75%)
```

**Solution:**

```bash
# Check .STATUS format
cat ~/projects/my-project/.STATUS

# Should be:
status: Active
progress: 75
next: Next task
target: Milestone

# Fix format if needed
$EDITOR ~/projects/my-project/.STATUS

# Verify
dash my-project
```

---

### Issue: Environment variables not persisting

**Symptom:**
```bash
export FLOW_QUIET=1
exec zsh
# Welcome message still shows
```

**Solution:**

```bash
# Add to shell config BEFORE sourcing plugin
# ~/.zshrc or ~/.config/zsh/.zshrc:

export FLOW_QUIET=1
export FLOW_PROJECTS_ROOT="$HOME/projects"
# ... other exports ...

source ~/projects/dev-tools/flow-cli/flow.plugin.zsh

# Reload
exec zsh
```

---

### Issue: Completions not working

**Symptom:**
```bash
work <Tab>
# No completions shown
```

**Solution:**

```bash
# Check if completions loaded
echo $fpath | grep flow-cli
# Should show completions directory

# If not, add to .zshrc BEFORE compinit:
fpath=(~/projects/dev-tools/flow-cli/completions $fpath)

# Rebuild completions
rm -f ~/.zcompdump
autoload -U compinit && compinit

exec zsh

# Test
work <Tab>
```

---

## Getting Help

### Still Having Issues?

1. **Search existing issues:**
   - https://github.com/Data-Wise/flow-cli/issues

2. **Create new issue:**
   - Include `flow doctor` output
   - Include steps to reproduce
   - Include expected vs actual behavior
   - Include environment info (OS, ZSH version)

3. **Check documentation:**
   - [Quick Reference](QUICK-REFERENCE.md)
   - [Workflows](WORKFLOWS.md)
   - [00-START-HERE](00-START-HERE.md)

---

## Diagnostic Commands Reference

```bash
# Full health check
flow doctor

# Token check (fast)
flow doctor --dot

# Fix issues interactively
flow doctor --fix

# Check specific category
flow doctor --dependencies
flow doctor --git
flow doctor --tokens
flow doctor --config

# Verbose output
flow doctor --verbose

# Quiet mode (exit code only)
flow doctor --quiet

# Check plugin status
antidote list        # For antidote users
zinit list           # For zinit users

# Check shell config
echo $SHELL
echo $ZSH_VERSION
echo $fpath

# Check git config
git config --list --global
git config --list --local

# Check environment
env | grep FLOW_
env | grep GITHUB_

# Check file permissions
ls -la ~/projects/dev-tools/flow-cli/
ls -la ~/.cache/flow/
```

---

## Prevention Tips

### Avoid Issues Before They Happen

1. **Regular health checks:**
   ```bash
   # Monthly
   flow doctor

   # Before reporting issues
   flow doctor --verbose
   ```

2. **Keep flow-cli updated:**
   ```bash
   cd ~/projects/dev-tools/flow-cli
   git pull
   exec zsh
   ```

3. **Backup configuration:**
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   cp ~/.config/zsh/.zshrc ~/.config/zsh/.zshrc.backup
   ```

4. **Monitor token expiration:**
   ```bash
   # Weekly
   flow doctor --dot
   ```

5. **Clear caches periodically:**
   ```bash
   # Monthly
   rm -rf ~/.cache/flow/*.cache
   ```

---

**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24
**Need more help?** https://github.com/Data-Wise/flow-cli/issues
