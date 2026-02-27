# Dotfile Dispatcher Quick Reference

> All `dots` subcommands at a glance.
>
> **Version:** v7.6.0 (v3.0.0 dispatcher) | **Dispatcher:** `lib/dispatchers/dots-dispatcher.zsh`
>
> **Backend:** [chezmoi](https://www.chezmoi.io/) for dotfile sync.

## Commands

| Command | Aliases | Description |
|---------|---------|-------------|
| `dots` | — | Status overview (default action) |
| `dots status` | `s` | Show chezmoi sync status with change details |
| `dots size` | — | Show dotfile repository size |
| `dots add <file>` | — | Add file to chezmoi management |
| `dots edit <file>` | `e` | Edit a managed dotfile |
| `dots sync` | `pull` | Pull changes from remote dotfile repo |
| `dots push` | `p` | Push local changes to remote |
| `dots diff` | `d` | Show diff between managed and actual files |
| `dots apply` | `a` | Apply chezmoi changes to home directory |
| `dots doctor` | `dr` | Dotfile-specific diagnostics |
| `dots init` | — | Initialize chezmoi for this machine |
| `dots env` | — | Show environment variable configuration |
| `dots version` | `-v` | Show dots dispatcher version |
| `dots help` | `-h` | Show help |

### Template Management

| Command | Aliases | Description |
|---------|---------|-------------|
| `dots managed add` | — | Add file to managed list |
| `dots managed list` | `ls` | List all managed dotfiles |
| `dots managed remove` | `rm` | Remove file from managed list |
| `dots managed edit` | — | Edit a managed file |

## Quick Examples

```bash
# Check sync status
dots

# See what's changed
dots diff

# Pull latest dotfiles from remote
dots sync

# Add a new file to management
dots add ~/.config/zsh/.zshrc

# Edit managed file (opens in $EDITOR)
dots edit .zshrc

# Apply all pending changes
dots apply

# Push changes to remote
dots push

# Run diagnostics
dots doctor
```

## Common Workflows

### Daily Sync

```bash
dots                    # Check status
dots sync               # Pull remote changes
dots diff               # Review changes
dots apply              # Apply to home dir
```

### Add New Dotfile

```bash
dots add ~/.config/starship.toml
dots push               # Sync to remote
```

### Cross-Machine Sync

```bash
# On machine A: push changes
dots push

# On machine B: pull and apply
dots sync
dots apply
```

## See Also

- [Tutorial 12: Dot Dispatcher](../tutorials/12-dot-dispatcher.md)
- [DOT-WORKFLOW.md](../guides/DOT-WORKFLOW.md)
- [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md#dots-dispatcher)

---

**Version:** v7.6.0
**Last Updated:** 2026-02-27
