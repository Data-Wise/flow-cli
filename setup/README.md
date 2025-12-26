# flow-cli Setup Guide

Quick setup for the optimal flow-cli experience.

## Quick Start

```bash
# From flow-cli directory
brew bundle --file=setup/Brewfile

# Or from anywhere
brew bundle --file=~/projects/dev-tools/flow-cli/setup/Brewfile

# Then check your setup
flow doctor
```

## What Gets Installed

### Required

| Tool    | Purpose                                               |
| ------- | ----------------------------------------------------- |
| **fzf** | Fuzzy finder for `pick`, `dash -i`, interactive modes |

### Highly Recommended

| Tool        | Purpose                           | Replaces  |
| ----------- | --------------------------------- | --------- |
| **eza**     | Modern ls with icons & git status | `ls`      |
| **bat**     | Syntax-highlighted file viewer    | `cat`     |
| **zoxide**  | Smart directory jumping           | `cd`, `z` |
| **fd**      | Fast file finder                  | `find`    |
| **ripgrep** | Fast text search                  | `grep`    |

### Nice to Have

| Tool      | Purpose             | Replaces |
| --------- | ------------------- | -------- |
| **dust**  | Disk usage analyzer | `du`     |
| **duf**   | Disk free viewer    | `df`     |
| **btop**  | System monitor      | `top`    |
| **delta** | Better git diffs    | `diff`   |
| **gh**    | GitHub CLI          | -        |
| **jq**    | JSON processor      | -        |

## Selective Install

Don't want everything? Install individually:

```bash
# Essentials only
brew install fzf eza bat zoxide

# Add search tools
brew install fd ripgrep

# Add system tools
brew install dust duf btop
```

## Verify Setup

After installing, run:

```bash
flow doctor
```

This shows what's installed and what's missing.

## ZSH Plugins

flow-cli works best with these ZSH plugins (via antidote):

```txt
# Already in your .zsh_plugins.txt
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-completions
romkatv/powerlevel10k
```

These are managed separately via antidote - see `~/.config/zsh/.zsh_plugins.txt`.

## Optional: Atlas Integration

For session tracking and rich state management:

```bash
npm install -g @data-wise/atlas
```

## Troubleshooting

**brew bundle fails?**

```bash
# Update Homebrew first
brew update
brew bundle --file=setup/Brewfile
```

**fzf not working after install?**

```bash
# Run fzf install script
$(brew --prefix)/opt/fzf/install
```

**zoxide not working?**

```bash
# Add to .zshrc (should already be there)
eval "$(zoxide init zsh)"
```
