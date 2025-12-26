# Installation

The Flow CLI configuration is already installed and running. This guide explains the setup for reference.

---

## Current Setup

### Configuration Files

The configuration is located in `~/.config/zsh/`:

```
~/.config/zsh/
├── .zshrc                    # Main config file
├── .zsh_plugins.txt          # Plugin list for antidote
├── .zsh_plugins.zsh          # Generated plugin config
├── functions/                # Function libraries
│   ├── adhd-helpers.zsh      # Workflow helpers
│   ├── smart-dispatchers.zsh # cc, gm, peek, qu dispatchers
│   ├── work.zsh              # Work session manager
│   └── claude-response-viewer.zsh
├── tests/                    # Test suite
│   └── test-anti-patterns.zsh
└── scripts/                  # Lint scripts
    ├── lint-zsh.sh
    └── quick-lint.sh
```

### Plugin Manager

**Antidote** manages ZSH plugins:

- Configuration: `~/.config/zsh/.zsh_plugins.txt`
- Enabled plugins include:
  - `ohmyzsh/ohmyzsh path:plugins/git` (226+ git aliases)
  - `romkatv/powerlevel10k` (theme)
  - `zsh-users/zsh-autosuggestions`
  - `zsh-users/zsh-syntax-highlighting`

---

## Verification

### Quick Health Check

The fastest way to verify your installation:

```bash
flow doctor
```

This shows all dependencies, what's installed, and what's missing.

**Fix any issues:**

```bash
flow doctor --fix      # Interactive install
flow doctor --fix -y   # Auto-install all
```

### 1. Check Aliases

Count current aliases:

```bash
# Custom aliases in .zshrc
grep -E "^alias [a-zA-Z]" ~/.config/zsh/.zshrc | grep -v "^#" | wc -l

# Should show: 23

# Custom aliases in adhd-helpers.zsh
grep -E "^alias [a-zA-Z]" ~/.config/zsh/functions/adhd-helpers.zsh | grep -v "^#" | wc -l

# Should show: 2

# Total: 28 (not including git plugin's 226+)
```

### 2. Check Git Plugin

Verify git plugin is enabled:

```bash
grep "ohmyzsh/ohmyzsh path:plugins/git" ~/.config/zsh/.zsh_plugins.txt

# Should show:
# ohmyzsh/ohmyzsh path:plugins/git
```

Test git aliases:

```bash
alias gst
# Should show: alias gst='git status'
```

### 3. Check Dispatchers

Test smart dispatchers:

```bash
type cc gm peek qu work pick

# All should show: "cc is a shell function"
```

### 4. Run Tests

Execute test suite:

```bash
~/.config/zsh/tests/test-anti-patterns.zsh

# Should show: 9/9 tests passing
```

---

## Fresh Installation (If Needed)

If you need to set up on a new machine:

### 1. Install Prerequisites

```bash
# Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Antidote plugin manager
brew install antidote

# All recommended CLI tools via Brewfile (recommended)
brew bundle --file=~/projects/dev-tools/flow-cli/setup/Brewfile

# Or install manually:
# brew install fzf eza bat zoxide fd ripgrep
```

### 2. Copy Configuration

```bash
# Create config directory
mkdir -p ~/.config/zsh

# Copy all files from this repo
cp -r {.zshrc,.zsh_plugins.txt,functions,tests,scripts} ~/.config/zsh/

# Set ZSH to use this config
echo 'export ZDOTDIR="$HOME/.config/zsh"' >> ~/.zshenv
```

### 3. Initialize Antidote

```bash
# Generate plugin configuration
source ~/.config/zsh/.zshrc

# This will:
# 1. Load antidote
# 2. Generate .zsh_plugins.zsh from .zsh_plugins.txt
# 3. Load all plugins (including git plugin)
```

### 4. Configure Powerlevel10k

```bash
# Run p10k configuration wizard
p10k configure

# Or copy existing config:
cp ~/.config/zsh/.p10k.zsh ~/
```

---

## Updating

### Update Plugins

```bash
# Regenerate plugin cache
antidote update
```

### Update Git Plugin

The git plugin updates automatically with antidote. To manually update:

```bash
cd ~/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh
git pull
```

### Update Custom Functions

Custom functions are in this repo. Pull latest:

```bash
cd ~/projects/dev-tools/flow-cli
git pull

# Copy updated functions
cp -r functions/* ~/.config/zsh/functions/
```

---

## Troubleshooting

### Plugin Load Errors

If you see `command not found: antidote`:

```bash
# Reinstall antidote
brew install antidote

# Source zshrc again
source ~/.zshrc
```

### Git Aliases Not Working

Verify git plugin is loaded:

```bash
# Check plugin list
cat ~/.config/zsh/.zsh_plugins.txt | grep git

# Regenerate plugins
rm ~/.config/zsh/.zsh_plugins.zsh
source ~/.zshrc
```

### Function Not Found

Ensure functions are sourced in .zshrc:

```bash
grep "source.*functions" ~/.config/zsh/.zshrc

# Should show multiple source lines for each function file
```

---

## Configuration Files Reference

### `.zshrc`

Main configuration file containing:

- Environment variables
- Modern CLI tool aliases (bat, fd, etc.)
- R package development aliases (23)
- Claude Code aliases (2)
- Path configurations
- Function sourcing

### `.zsh_plugins.txt`

Antidote plugin list:

- Theme (powerlevel10k)
- OMZ git plugin
- Fish-like features (autosuggestions, syntax highlighting)
- Additional completions

### Functions

- `adhd-helpers.zsh` - Focus timers, workflow helpers
- `smart-dispatchers.zsh` - cc, gm, peek, qu dispatchers
- `work.zsh` - Work session management
- `claude-response-viewer.zsh` - Glow integration

---

## Next Steps

1. **Quick Start**: Follow [Quick Start Guide](quick-start.md)
2. **Learn Aliases**: Read [Alias Reference Card](../reference/ALIAS-REFERENCE-CARD.md)
3. **Master Workflows**: Review [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)

---

**Questions?** See [Complete Documentation Index](../doc-index.md)
