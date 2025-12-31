# Installation

> **Time:** ~5 minutes | **Level:** Beginner

This guide walks you through installing flow-cli and verifying it works.

---

## Prerequisites

Before starting, verify you have:

```bash
# Check ZSH (required)
zsh --version
# Expected: zsh 5.8 or higher

# Check Git (required)
git --version
# Expected: any recent version
```

---

## Part 1: Install flow-cli (~2 min)

### Quick Install (Recommended)

The easiest way to install:

```bash
curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/install.sh | bash
```

This auto-detects your plugin manager (antidote, zinit, oh-my-zsh) and installs accordingly.

### Manual Installation

Choose your plugin manager:

=== "Antidote"
    ```bash
    # Add to your plugins file
    echo "Data-Wise/flow-cli" >> ~/.zsh_plugins.txt

    # Regenerate plugins
    antidote update
    ```

=== "Zinit"
    ```bash
    # Add to ~/.zshrc
    zinit light Data-Wise/flow-cli
    ```

=== "Oh-My-Zsh"
    ```bash
    # Clone to custom plugins
    git clone https://github.com/Data-Wise/flow-cli.git \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/flow-cli

    # Add to plugins in ~/.zshrc
    plugins=(... flow-cli)
    ```

=== "Manual"
    ```bash
    # Clone repository
    git clone https://github.com/Data-Wise/flow-cli.git ~/.flow-cli

    # Add to ~/.zshrc
    echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc
    ```

### Reload Shell

```bash
source ~/.zshrc
# Or just restart your terminal
```

### Checkpoint

- [ ] `flow --version` shows version number
- [ ] `flow doctor` runs without errors

---

## Part 2: Verify Installation (~1 min)

### Health Check

Run the built-in doctor command:

```bash
flow doctor
```

Expected output:
```
flow doctor - Health Check

Core Commands:
  ✓ work     - Start work session
  ✓ finish   - End session
  ✓ dash     - Project dashboard
  ✓ win      - Log accomplishment
  ✓ pick     - Project picker

Dispatchers:
  ✓ cc       - Claude Code
  ✓ g        - Git workflows
  ✓ r        - R package dev
  ...

Optional Tools:
  ✓ fzf      - Interactive picker
  ✓ bat      - Syntax highlighting
  ...

All checks passed!
```

### Fix Missing Dependencies

If any optional tools are missing:

```bash
# Interactive install
flow doctor --fix

# Auto-install all
flow doctor --fix -y
```

### Checkpoint

- [ ] `flow doctor` shows "All checks passed"
- [ ] Core commands are available

---

## Part 3: Quick Test (~1 min)

Try the core commands:

```bash
# Start a work session
work my-project

# Log a win
win "Installed flow-cli"

# See your wins
yay

# End session
finish
```

### Checkpoint

- [ ] `work` starts a session
- [ ] `win` logs accomplishments
- [ ] `yay` shows your wins

---

## Installation Methods Comparison

| Method | Command | Best For |
|--------|---------|----------|
| **Quick Install** | `curl ... \| bash` | New users, auto-detection |
| **Antidote** | Add to `.zsh_plugins.txt` | Antidote users |
| **Zinit** | `zinit light ...` | Zinit users |
| **Oh-My-Zsh** | Clone to `$ZSH_CUSTOM` | OMZ users |
| **Manual** | `git clone` + source | Full control |

---

## Optional: Install Recommended Tools

For the best experience, install these CLI tools:

```bash
# Using Homebrew (macOS)
brew install fzf eza bat zoxide fd ripgrep

# Or install from Brewfile
brew bundle --file=~/.flow-cli/setup/Brewfile
```

| Tool | Purpose | Used By |
|------|---------|---------|
| `fzf` | Interactive picker | `pick`, `dash -i` |
| `bat` | Syntax highlighting | File previews |
| `eza` | Better `ls` | Dashboard |
| `zoxide` | Smart `cd` | Project navigation |
| `fd` | Better `find` | File search |
| `ripgrep` | Fast grep | Content search |

---

## Troubleshooting

### "command not found: flow"

Shell hasn't reloaded. Try:

```bash
source ~/.zshrc
# Or restart your terminal
```

### "command not found: work"

Plugin not loaded. Verify installation:

```bash
# Check if plugin file exists
ls ~/.flow-cli/flow.plugin.zsh  # Manual install
# or
ls ~/.oh-my-zsh/custom/plugins/flow-cli/  # OMZ install

# Re-source
source ~/.zshrc
```

### Plugin Manager Not Detected

Force a specific method:

```bash
INSTALL_METHOD=manual curl -fsSL .../install.sh | bash
```

Options: `antidote`, `zinit`, `omz`, `manual`

---

## Updating

### Quick Update

```bash
# If installed via plugin manager
antidote update  # or zinit update

# If manual install
cd ~/.flow-cli && git pull
```

### Check for Updates

```bash
flow --version
# Compare with: https://github.com/Data-Wise/flow-cli/releases
```

---

## Uninstalling

### Remove Plugin

=== "Antidote"
    ```bash
    # Remove from ~/.zsh_plugins.txt
    # Then: antidote update
    ```

=== "Zinit"
    ```bash
    # Remove zinit line from ~/.zshrc
    zinit delete Data-Wise/flow-cli
    ```

=== "Oh-My-Zsh"
    ```bash
    rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/flow-cli
    # Remove from plugins=(...) in ~/.zshrc
    ```

=== "Manual"
    ```bash
    rm -rf ~/.flow-cli
    # Remove source line from ~/.zshrc
    ```

---

## Next Steps

1. **Quick Start**: Follow [Quick Start Guide](quick-start.md) for a 5-minute tutorial
2. **Learn Commands**: See [Command Reference](../reference/COMMAND-QUICK-REFERENCE.md)
3. **Explore Dispatchers**: Read [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md)

---

**Questions?** See [Troubleshooting](troubleshooting.md) or [FAQ](faq.md)
