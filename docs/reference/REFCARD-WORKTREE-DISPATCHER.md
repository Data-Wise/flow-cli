# Worktree Dispatcher Quick Reference

> All `wt` subcommands at a glance.
>
> **Version:** v7.6.0 | **Dispatcher:** `lib/dispatchers/wt-dispatcher.zsh`

## Commands

| Command | Aliases | Description |
|---------|---------|-------------|
| `wt` | — | Formatted overview with branch, status, and session indicators |
| `wt <filter>` | — | Filter overview by project name |
| `wt list` | `ls`, `l` | Raw `git worktree list` output |
| `wt status` | `st` | Detailed health: disk usage, merge status, session tracking |
| `wt create <branch>` | `add`, `c` | Create worktree for branch (auto-creates branch if needed) |
| `wt move` | `mv` | Move current branch to a worktree |
| `wt remove <path>` | `rm` | Remove a worktree |
| `wt clean` | — | Prune stale worktree references (`git worktree prune`) |
| `wt prune` | — | Comprehensive cleanup: find and remove merged worktrees |
| `wt help` | `h` | Show help |

### wt prune Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--dry-run` | `-n` | Preview what would be cleaned |
| `--force` | `-f` | Skip confirmation prompts |
| `--branches` | `-b` | Also delete merged branches after removing worktrees |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `FLOW_WORKTREE_DIR` | `~/.git-worktrees` | Base directory for worktrees |

## Quick Examples

```bash
# View all worktrees with status indicators
wt

# Filter by project
wt flow-cli

# Create feature worktree
wt create feature/auth

# Create worktree from dev
wt create feature/new-feature dev

# Move current branch to worktree
wt move

# Check health and disk usage
wt status

# Preview cleanup
wt prune --dry-run

# Clean merged worktrees and branches
wt prune --branches --force

# Remove specific worktree
wt remove ~/.git-worktrees/flow-cli/feature-old
```

## Common Workflows

### Start Feature (Worktree Workflow)

```bash
wt create feature/my-feature    # Create worktree
cd ~/.git-worktrees/project/feature-my-feature
# ... develop feature ...
gh pr create --base dev
wt prune --branches             # Cleanup after merge
```

### Parallel Development

```bash
# Working on feature A, urgent fix needed
wt create hotfix/critical-bug
cd ~/.git-worktrees/project/hotfix-critical-bug
# ... fix bug, push, PR ...
cd ~/projects/my-project        # Back to feature A (untouched)
```

## Status Icons

| Icon | Meaning |
|------|---------|
| ✅ active | Branch is in progress |
| 🧹 merged | Branch has been merged (safe to clean) |
| ⚠️ stale | Worktree reference is broken |
| 🏠 main | Protected branch (main/dev) |
| 🟢 | Active Claude session (< 30 min) |
| 🟡 | Recent Claude session (< 24h) |
| ⚪ | No active session |

## See Also

- [Tutorial 09: Worktrees](../tutorials/09-worktrees.md)
- [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md#wt-dispatcher)

---

**Version:** v7.6.0
**Last Updated:** 2026-02-27
