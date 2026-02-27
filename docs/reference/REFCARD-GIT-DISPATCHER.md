# Git Dispatcher Quick Reference

> All `g` subcommands at a glance — the most-used flow-cli dispatcher.
>
> **Version:** v7.6.0 | **Dispatcher:** `lib/dispatchers/g-dispatcher.zsh`
>
> Unknown commands pass through to `git` (e.g., `g remote -v` → `git remote -v`).

## Status & Info

| Command | Aliases | Description |
|---------|---------|-------------|
| `g` | — | Short status (`git status -sb`) |
| `g status` | `s` | Full status |
| `g diff` | `d` | Show diff |
| `g ds` | `staged` | Show staged diff |
| `g log` | `l` | Pretty log (last 20, graph, decorated) |
| `g loga` | `la` | Log all branches |
| `g blame <file>` | `bl` | Git blame |

## Staging & Commits

| Command | Aliases | Description |
|---------|---------|-------------|
| `g add <files>` | `a` | Stage files |
| `g aa` | — | Stage all (`git add --all`) |
| `g commit` | `c` | Commit (opens editor) |
| `g commit "msg"` | `c "msg"` | Commit with message |
| `g amend` | — | Amend last commit (no edit) |
| `g amendm "msg"` | — | Amend with new message |

## Branches

| Command | Aliases | Description |
|---------|---------|-------------|
| `g branch` | `b` | List branches |
| `g ba` | — | List all branches (local + remote) |
| `g checkout <b>` | `co` | Checkout branch |
| `g cob <name>` | — | Create and checkout new branch |
| `g switch <b>` | `sw` | Switch branch |
| `g swc <name>` | — | Switch and create new branch |
| `g main` | `m` | Checkout main (falls back to master) |

## Remote Operations

All remote operations validate GitHub token before executing and warn if expired.

| Command | Aliases | Description |
|---------|---------|-------------|
| `g push` | `p` | Push to remote (with workflow guard) |
| `g pushu` | `pu` | Push and set upstream (`-u origin HEAD`) |
| `g pull` | `pl` | Pull from remote |
| `g fetch` | `f` | Fetch from remote |
| `g fa` | — | Fetch all remotes |

## Stash

| Command | Aliases | Description |
|---------|---------|-------------|
| `g stash` | `st` | Stash changes |
| `g pop` | `stp` | Pop last stash |
| `g stl` | — | List stashes |

## Reset & Undo

| Command | Aliases | Description |
|---------|---------|-------------|
| `g undo` | — | Undo last commit, keep changes (`--soft HEAD~1`) |
| `g unstage <file>` | — | Unstage file (`reset HEAD`) |
| `g discard <file>` | — | Discard file changes |
| `g reset` | `rs` | Git reset (pass args) |
| `g clean` | — | Remove untracked files |

## Rebase & Merge

| Command | Aliases | Description |
|---------|---------|-------------|
| `g rebase` | `rb` | Start rebase |
| `g rbc` | — | Rebase continue |
| `g rba` | — | Rebase abort |
| `g merge` | `mg` | Merge branch |

## Feature Workflow

| Command | Description |
|---------|-------------|
| `g feature start <name>` | Create feature branch from dev |
| `g feature sync` | Rebase feature onto dev |
| `g feature list` | List feature/hotfix branches |
| `g feature finish` | Push and create PR to dev |
| `g promote` | Create PR: feature → dev |
| `g release` | Create PR: dev → main |

## Quick Examples

```bash
# Quick status
g

# Common commit flow
g add .
g commit "feat: add user auth"
g push

# Feature branch workflow
g feature start user-profiles
# ... develop ...
g add .
g commit "feat: add profile page"
g feature finish

# Undo mistakes
g undo                  # Undo last commit (keep changes)
g unstage file.zsh      # Unstage a file
g discard file.zsh      # Discard changes to file

# Stash and switch
g stash
g checkout other-branch
# ... do work ...
g pop                   # Restore stashed changes
```

## See Also

- [Tutorial 42: g Dispatcher](../tutorials/42-g-dispatcher.md)
- [Tutorial 08: Git Feature Workflow](../tutorials/08-git-feature-workflow.md)
- [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md#g-dispatcher)

---

**Version:** v7.6.0
**Last Updated:** 2026-02-27
