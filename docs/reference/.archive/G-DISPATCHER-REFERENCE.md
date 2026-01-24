# G Dispatcher Reference

> **Smart Git command shortcuts with feature branch workflow and protected branch guards**

**Location:** `lib/dispatchers/g-dispatcher.zsh`

---

## Quick Start

```bash
g                     # Quick status (short)
g add .               # Stage all changes
g commit "message"    # Commit with message
g push                # Push to remote
```

---

## Usage

```bash
g [command] [args]
```

### Key Insight

- `g` provides shortcuts for the most common git operations
- Feature workflow enforces `feature/* → dev → main` pattern
- Workflow guard blocks direct push to protected branches
- Unknown commands pass through to git

---

## Status & Info Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `g` | - | Quick status (`git status -sb`) |
| `g status` | `g s` | Full status |
| `g diff` | `g d` | Show unstaged diff |
| `g ds` / `g staged` | - | Show staged diff |
| `g log` | `g l` | Pretty log (20 commits) |
| `g loga` | `g la` | Log all branches |
| `g blame <file>` | `g bl` | Blame file |

### Examples

```bash
g                  # Quick status
g d                # See unstaged changes
g ds               # See staged changes
g l                # Recent commits
g la               # All branches
```

---

## Staging & Commits

| Command | Shortcut | Description |
|---------|----------|-------------|
| `g add <files>` | `g a` | Add files |
| `g aa` | - | Add all (`git add --all`) |
| `g commit` | `g c` | Commit (opens editor) |
| `g commit "msg"` | - | Commit with message |
| `g amend` | - | Amend last commit (no edit) |
| `g amendm "msg"` | - | Amend with new message |

### Examples

```bash
g aa                    # Add all changes
g commit "fix: bug"     # Commit with message
g amend                 # Amend without editing message
g amendm "new message"  # Amend with new message
```

---

## Branch Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `g branch` | `g b` | List branches |
| `g ba` | - | All branches (local + remote) |
| `g checkout <branch>` | `g co` | Checkout branch |
| `g cob <branch>` | - | Create and checkout branch |
| `g switch <branch>` | `g sw` | Switch branch |
| `g swc <branch>` | - | Switch, create if new |
| `g main` | `g m` | Checkout main (or master) |

### Examples

```bash
g b                     # List local branches
g ba                    # List all branches
g co feature/auth       # Checkout existing branch
g cob feature/new       # Create and checkout new branch
g main                  # Go back to main
```

---

## Remote Operations

| Command | Shortcut | Description |
|---------|----------|-------------|
| `g push` | `g p` | Push (with workflow guard) |
| `g pushu` | `g pu` | Push with upstream (`-u origin HEAD`) |
| `g pull` | `g pl` | Pull |
| `g fetch` | `g f` | Fetch |
| `g fa` | - | Fetch all |

### Workflow Guard

Direct push to `main` or `dev` is blocked by default:

```bash
g push   # On main → BLOCKED
# ⛔ Direct push to 'main' blocked
# Workflow: feature/* → dev → main
# Use instead:
#   g feature start <name>
#   g promote

# Override (use sparingly):
GIT_WORKFLOW_SKIP=1 git push
```

---

## Stash Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `g stash` | `g st` | Stash changes |
| `g stash <args>` | - | Stash with arguments |
| `g pop` | `g stp` | Pop stash |
| `g stl` | - | List stashes |

### Examples

```bash
g st                    # Quick stash
g stash push -m "WIP"   # Stash with message
g stl                   # List stashes
g pop                   # Apply and remove top stash
```

---

## Reset & Undo Commands

| Command | Description |
|---------|-------------|
| `g undo` | Undo last commit (keeps changes, soft reset) |
| `g unstage <file>` | Unstage file |
| `g discard <file>` | Discard changes to file |
| `g clean` | Remove untracked files |
| `g reset <args>` | Git reset with args |

### Examples

```bash
g undo                  # Undo last commit (keep changes)
g unstage src/main.ts   # Unstage specific file
g discard src/main.ts   # Discard changes to file
g clean                 # Remove untracked files
```

---

## Rebase & Merge Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `g rebase` | `g rb` | Rebase |
| `g rbc` | - | Rebase continue |
| `g rba` | - | Rebase abort |
| `g merge` | `g mg` | Merge |

### Examples

```bash
g rb dev                # Rebase onto dev
g rbc                   # Continue after resolving conflicts
g rba                   # Abort rebase
g mg feature/auth       # Merge feature/auth
```

---

## Feature Workflow

The feature workflow enforces a clean branching pattern:

```
feature/* ──► dev ──► main
hotfix/*  ────┴───────┘
bugfix/*  ────┘
```

### Feature Commands

| Command | Description |
|---------|-------------|
| `g feature start <name>` | Create `feature/<name>` from dev |
| `g feature sync` | Rebase current feature onto dev |
| `g feature list` | List all feature/hotfix/bugfix branches |
| `g feature finish` | Push and create PR to dev |
| `g feature status` | Show merged vs active branches |
| `g feature prune` | Delete merged feature branches |

### Workflow Example

```bash
# 1. Start new feature
g feature start auth
# → Creates feature/auth from dev

# 2. Work on feature
# ... make changes ...
g aa && g commit "feat: add auth"

# 3. Keep in sync with dev
g feature sync
# → Rebases feature/auth onto dev

# 4. Complete feature
g feature finish
# → Pushes and creates PR to dev

# 5. After PR merged, cleanup
g feature prune
# → Deletes merged branches
```

### Promotion Commands

| Command | Description |
|---------|-------------|
| `g promote` | Create PR: `feature/* → dev` |
| `g release` | Create PR: `dev → main` |

```bash
# On feature/auth branch
g promote    # Creates PR to dev

# On dev branch
g release    # Creates PR to main
```

---

## Feature Prune

Clean up merged feature branches:

```bash
g feature prune              # Delete merged (with confirmation)
g feature prune --force      # Skip confirmation
g feature prune --all        # Also delete remote branches
g feature prune --dry-run    # Preview only
g feature prune --older-than 30d  # Only branches >30 days old
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--force` | `-f` | Skip confirmation prompts |
| `--all` | `-a` | Also prune remote branches |
| `--dry-run` | `-n` | Show what would be deleted |
| `--older-than <d>` | - | Only prune older branches |

### Duration Format

- `30d` → 30 days
- `1w` → 1 week (7 days)
- `2m` → 2 months (60 days)

### Safety

- Only deletes merged branches
- Never deletes: `main`, `master`, `dev`, `develop`
- Never deletes current branch
- Only targets: `feature/*`, `bugfix/*`, `hotfix/*`

---

## Feature Status

Show which branches are merged and which are active:

```bash
g feature status
```

**Sample output:**

```
📊 Feature Branch Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🧹 Stale branches (merged to dev):
  • feature/old-auth                    (3 weeks ago)
  • bugfix/typo-fix                     (5 days ago)

⚠️  Active branches (not merged to dev):
  • feature/new-dashboard               4 commits ahead (2 days ago)
  • feature/api-refactor                12 commits ahead (1 hour ago)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: 2 stale, 2 active
💡 Tip: Run g feature prune to clean up merged branches
```

---

## Passthrough

Unknown commands pass directly to git:

```bash
g remote -v        # → git remote -v
g cherry-pick abc  # → git cherry-pick abc
g reflog           # → git reflog
g tag v1.0.0       # → git tag v1.0.0
```

---

## Examples

### Daily Workflow

```bash
# Start of day
g fetch --all
g main && g pull

# Start feature
g feature start new-dashboard
# ... work ...
g aa && g commit "feat: add dashboard"
g push

# Keep updated
g feature sync

# Complete
g feature finish
```

### Quick Fix

```bash
g                       # Check status
g aa                    # Stage all
g commit "fix: typo"    # Commit
g push                  # Push
```

### Undo Mistakes

```bash
g undo                  # Undo last commit
g unstage file.ts       # Unstage file
g discard file.ts       # Discard changes
```

### Cleanup

```bash
g feature status        # See what needs cleaning
g feature prune -n      # Preview cleanup
g feature prune         # Do cleanup
```

---

## Integration

### With WT Dispatcher

Use worktrees for parallel feature development:

```bash
wt create feature/auth   # Create worktree
cd ~/.git-worktrees/project/feature-auth
g feature sync           # Keep in sync
```

### With CC Dispatcher

Launch Claude in a feature branch:

```bash
g feature start auth
cc                       # Launch Claude in feature
```

---

## Troubleshooting

### "Direct push to 'main' blocked"

This is the workflow guard. Use the proper workflow:

```bash
g feature start <name>   # Start feature
g promote                # Create PR to dev
g release                # Create PR to main (from dev)

# Or override (not recommended):
GIT_WORKFLOW_SKIP=1 git push
```

### "Not on a feature branch"

Some commands require being on a feature branch:

```bash
g feature start myfeature   # Create one first
g feature sync              # Then sync
```

### "Uncommitted changes"

Stash or commit before switching:

```bash
g st              # Stash changes
# or
g aa && g commit "WIP"
```

---

## See Also

- **Dispatcher:** [wt](WT-DISPATCHER-REFERENCE.md) - Worktree management for parallel development
- **Dispatcher:** [cc](CC-DISPATCHER-REFERENCE.md) - Launch Claude in feature branches
- **Reference:** [Dispatcher Reference](DISPATCHER-REFERENCE.md) - All dispatchers
- **Tutorial:** [Git Feature Workflow](../tutorials/08-git-feature-workflow.md) - Learn by doing

---

**Last Updated:** 2026-01-07
**Version:** v4.8.0
**Status:** ✅ Production ready with feature workflow
