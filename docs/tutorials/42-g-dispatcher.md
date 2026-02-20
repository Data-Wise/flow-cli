---
tags:
  - tutorial
  - dispatchers
  - git
  - shortcuts
---

# Tutorial: Git Shortcuts with the g Dispatcher

Replace verbose git commands with single-letter shortcuts. The `g` dispatcher wraps git with smart token validation and workflow guards.

**Time:** 20 minutes | **Level:** Beginner-Intermediate | **Requires:** git, flow-cli

## What You'll Learn

1. Quick status checks and viewing changes
2. Staging, committing, and amending
3. Branch management shortcuts
4. Safe remote operations with token validation
5. Stash workflow
6. Undo and recovery commands
7. Advanced: rebase, merge, and feature workflows

---

## Step 1: Quick Status

```zsh
g              # git status -sb (short status)
g s            # git status (full)
```

You'll use `g` dozens of times per session for a quick glance at your repo state.

---

## Step 2: Viewing Changes

```zsh
g d            # git diff (unstaged changes)
g ds           # git diff --staged
g l            # git log --oneline --graph --decorate -20
g la           # same but --all (all branches)
g bl <file>    # git blame
```

---

## Step 3: Staging & Committing

```zsh
g a <files>          # git add
g aa                 # git add --all
g c "feat: new api"  # git commit -m "feat: new api"
g c                  # git commit (opens editor)
g amend              # git commit --amend --no-edit
g amendm "new msg"   # git commit --amend -m "new msg"
```

---

## Step 4: Branch Management

```zsh
g b              # git branch (list local)
g ba             # git branch -a (all)
g co <branch>    # git checkout
g cob <branch>   # git checkout -b (create + switch)
g sw <branch>    # git switch
g swc <branch>   # git switch -c (create + switch)
g main           # checkout main (falls back to master)
```

---

## Step 5: Remote Operations

All remote commands validate your GitHub token before executing:

```zsh
g push           # git push (alias: g p)
g pu             # git push -u origin HEAD (set upstream)
g pull           # git pull (alias: g pl)
g fetch          # git fetch (alias: g f)
g fa             # git fetch --all
```

**Smart features:**

- **Token validation** — before push/pull/fetch, checks if your GitHub token is expired. Shows a warning with `tok expiring` suggestion if expired.
- **Workflow guard** — `g push` checks branch rules to prevent accidental pushes to protected branches.
- Token validation only triggers for GitHub remotes (`github.com`). Non-GitHub remotes skip the check.

---

## Step 6: Stash Workflow

```zsh
g st             # git stash
g pop            # git stash pop (alias: g stp)
g stl            # git stash list
```

**Common pattern:**

```zsh
g st           # Stash WIP
g sw main      # Switch to main
g c "fix: bug" # Fix and commit
g p            # Push
g sw feature/x # Return to feature
g pop          # Restore stash
```

---

## Step 7: Undo & Recovery

```zsh
g undo           # git reset --soft HEAD~1 (undo commit, keep changes)
g unstage        # git reset HEAD (unstage files)
g discard        # git checkout -- (revert to HEAD)
g clean          # git clean -fd (remove untracked files)
g rs             # git reset
```

**Warning:** `g discard` and `g clean` are destructive — changes are lost permanently.

---

## Step 8: Advanced Workflows

**Rebase:**

```zsh
g rb             # git rebase
g rbc            # git rebase --continue
g rba            # git rebase --abort
```

**Merge:**

```zsh
g mg             # git merge
```

**Feature workflow:**

```zsh
g feat           # Feature branch workflow
g promote        # Promote branch
g rel            # Release workflow
```

**Passthrough:** Any unrecognized command passes directly to git. `g cherry-pick`, `g tag`, `g remote` all work.

---

## Quick Reference

| Command | Alias | What It Does |
|---------|-------|--------------|
| `g` | — | Short status (`git status -sb`) |
| `g status` | `g s` | Full status |
| `g diff` | `g d` | Unstaged changes |
| `g staged` | `g ds` | Staged changes |
| `g log` | `g l` | Last 20 commits (graph) |
| `g loga` | `g la` | All branches log |
| `g blame` | `g bl` | File blame |
| `g add` | `g a` | Stage files |
| — | `g aa` | Stage all |
| `g commit "msg"` | `g c "msg"` | Commit with message |
| `g commit` | `g c` | Commit (editor) |
| — | `g amend` | Amend (no edit) |
| — | `g amendm "msg"` | Amend with message |
| `g branch` | `g b` | List branches |
| — | `g ba` | All branches |
| `g checkout` | `g co` | Checkout branch |
| — | `g cob` | Create + checkout |
| `g switch` | `g sw` | Switch branch |
| — | `g swc` | Create + switch |
| — | `g main` | Checkout main/master |
| `g push` | `g p` | Push (token validated) |
| — | `g pu` | Push -u origin HEAD |
| `g pull` | `g pl` | Pull (token validated) |
| `g fetch` | `g f` | Fetch |
| — | `g fa` | Fetch all |
| `g stash` | `g st` | Stash changes |
| — | `g pop` | Stash pop |
| — | `g stl` | Stash list |
| — | `g undo` | Soft reset HEAD~1 |
| — | `g unstage` | Reset HEAD |
| — | `g discard` | Checkout -- |
| — | `g clean` | Clean untracked |
| `g rebase` | `g rb` | Rebase |
| — | `g rbc` | Rebase continue |
| — | `g rba` | Rebase abort |
| `g merge` | `g mg` | Merge |
| `g feature` | `g feat` | Feature workflow |
| — | `g promote` | Promote branch |
| `g release` | `g rel` | Release workflow |
| `g *` | — | Passthrough to git |

---

## FAQ

### Does `g` replace git?

No. Any unrecognized subcommand passes directly to `git`, so `g cherry-pick`, `g tag`, `g remote`, etc. all work. The dispatcher adds shortcuts, not restrictions.

### What's the token validation about?

Before push/pull/fetch, the dispatcher checks if your GitHub token has expired (via keychain lookup + API validation). This prevents failed operations due to stale credentials. If expired, it suggests running `tok expiring`.

### I use GitLab — will token validation slow me down?

No. Token validation only triggers for GitHub remotes (URLs containing `github.com`). Non-GitHub remotes skip the check entirely.

### What's the workflow guard on push?

`g push` checks your branch rules. If you're about to push directly to a protected branch (`main`, `dev`), it warns you and suggests using a pull request instead.

---

## Next Steps

- **[Tutorial 8: Git Feature Workflow](08-git-feature-workflow.md)** — Branch conventions and PR workflow
- **[Tutorial 9: Worktrees](09-worktrees.md)** — Parallel branch development
- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
