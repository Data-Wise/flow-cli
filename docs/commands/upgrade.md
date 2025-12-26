# flow upgrade

> Update flow-cli and related tools

## Synopsis

```bash
flow upgrade [target] [options]
```

## Description

`flow upgrade` updates flow-cli itself, Homebrew packages, and ZSH plugins. It provides a unified interface for keeping your workflow tools current.

## Targets

| Target    | Description                   |
| --------- | ----------------------------- |
| `self`    | Update flow-cli via git pull  |
| `tools`   | Update Homebrew packages      |
| `plugins` | Update ZSH plugins (antidote) |
| `all`     | Update everything             |

## Options

| Option        | Description                          |
| ------------- | ------------------------------------ |
| `-c, --check` | Check for updates without installing |
| `--changelog` | Show what's new in latest version    |
| `-f, --force` | Skip confirmations                   |
| `-h, --help`  | Show help message                    |

## Examples

### Update flow-cli

```bash
flow upgrade self
```

This runs `git pull` in the flow-cli directory and reloads the plugin.

### Update Homebrew Packages

```bash
flow upgrade tools
```

Runs `brew update && brew upgrade` for flow-cli recommended tools.

### Update ZSH Plugins

```bash
flow upgrade plugins
```

Updates plugins via antidote (if installed).

### Update Everything

```bash
flow upgrade all
```

Updates flow-cli, Homebrew packages, and ZSH plugins in sequence.

### Check for Updates

```bash
flow upgrade --check
```

Output:

```
📦 Checking for updates...

flow-cli:
  Current: v3.2.0
  Latest:  v3.2.0
  Status:  ✅ Up to date

Homebrew:
  Outdated packages: 3
    • bat (0.23.0 → 0.24.0)
    • fzf (0.44.0 → 0.45.0)
    • gh (2.40.0 → 2.41.0)

ZSH Plugins:
  Status: ✅ Up to date
```

### Show Changelog

```bash
flow upgrade --changelog
```

Shows recent changes from the git log.

### Force Update (No Prompts)

```bash
flow upgrade all --force
```

## How It Works

### Self Update

1. Checks current git remote for flow-cli
2. Runs `git fetch` to check for updates
3. Shows diff of incoming changes
4. Runs `git pull` if confirmed
5. Reloads the plugin

### Tools Update

1. Runs `brew update` to refresh formulae
2. Checks for outdated packages
3. Runs `brew upgrade` for selected packages

### Plugins Update

1. Detects plugin manager (antidote, zinit, oh-my-zsh)
2. Runs appropriate update command
3. Reloads shell configuration

## Requirements

- Git (for self-update)
- Homebrew (for tools update)
- Plugin manager: antidote, zinit, or oh-my-zsh (for plugins update)

## Related Commands

- [`flow install`](install.md) - Install new tools
- [`flow doctor`](doctor.md) - Check installation health

## See Also

- [Installation Guide](../getting-started/installation.md)

---

_Added in v3.2.0_
