# Tutorial: Git Worktrees for Parallel Development

> **What you'll learn:** Use git worktrees to work on multiple branches simultaneously
>
> **Time:** ~10 minutes | **Level:** Intermediate
> **Version:** v5.13.0+

---

## Prerequisites

Before starting, you should:

- [ ] Completed: [Tutorial 1: Your First Flow Session](01-first-session.md)
- [ ] Understand basic git concepts (branches, commits)
- [ ] Have fzf installed (optional, for pickers)

**Verify your setup:**

```bash
# Check wt dispatcher is available
wt help

# Check cc wt integration
cc wt help
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Create and manage git worktrees
2. Launch Claude Code in dedicated worktrees
3. Work on multiple features in parallel
4. Clean up worktrees when done

---

## Why Worktrees?

**The Problem:**

```
# Traditional approach (context switching)
git stash                    # Save current work
git checkout feature-b       # Switch branches
# ... work ...
git checkout feature-a       # Switch back
git stash pop                # Restore work
```

**The Worktree Solution:**

```
# Parallel development (no context switching!)
~/project/              # Main worktree (feature-a)
~/.git-worktrees/
  └── project/
      └── feature-b/    # Second worktree (feature-b)
```

Each worktree is a separate directory with its own working copy.

---

## Part 1: Basic Worktree Management

### Step 1.1: List Existing Worktrees

```bash
wt list
```

**Output:**

```
/Users/you/projects/myproject  abc1234 [main]
```

### Step 1.2: Create a Worktree

```bash
# Create worktree for existing branch
wt create feature/auth

# Or for a new branch (auto-creates)
wt create feature/new-thing
```

**What happened:**

```
✓ Created worktree: ~/.git-worktrees/myproject/feature-auth

Navigate: cd ~/.git-worktrees/myproject/feature-auth
```

### Step 1.3: View Worktree Overview

**NEW in v5.13.0** - Get a formatted overview with status and session indicators:

```bash
# View all worktrees with status icons and session indicators
wt
```

**Output:**

```
🌳 Worktrees (3 total)

BRANCH              STATUS   SESSION  PATH
──────────────────────────────────────────────────────────────
feature/auth        ✅ active  🟢 5m   ~/.git-worktrees/myproject/feature-auth
feature/dashboard   🧹 merged  🟡 2h   ~/.git-worktrees/myproject/feature-dashboard
main                🏠 main    ⚪      /Users/you/projects/myproject

💡 Filter: wt <project> | Interactive picker: pick wt (Tab=multi-select, Ctrl-X=delete, Ctrl-R=refresh)
```

**Status Icons:**
- ✅ **active** - Unmerged feature branch
- 🧹 **merged** - Branch merged to base
- ⚠️ **stale** - Missing .git directory
- 🏠 **main** - Main/master/dev branch

**Session Indicators:**
- 🟢 **active** - Claude session running (< 30 min)
- 🟡 **recent** - Recent activity (< 24h)
- ⚪ **none** - No session

### Step 1.4: Filter by Project

```bash
# Show only flow-cli worktrees
wt flow
```

### Step 1.5: Navigate to Worktrees Folder

```bash
# Go to worktrees base directory (use 'cd')
wt cd
```

**Output:**

```
ℹ Changed to: /Users/you/.git-worktrees
```

---

## Part 2: Claude Code in Worktrees

### Step 2.1: Launch Claude in a Worktree

```bash
# Launch Claude in worktree (creates if needed!)
cc wt feature/auth
```

**What happened:**

```
ℹ Creating worktree for feature/auth...
✓ Created worktree: ~/.git-worktrees/myproject/feature-auth
✓ Launching Claude in ~/.git-worktrees/myproject/feature-auth
```

Claude Code opens in the worktree directory, completely isolated from your main work.

### Step 2.2: Pick from Existing Worktrees

```bash
# fzf picker for worktrees
cc wt pick
```

A picker appears showing all worktrees. Select one to launch Claude there.

### Step 2.3: Mode Chaining

Combine worktrees with Claude modes:

```bash
# YOLO mode in worktree
cc wt yolo feature/risky

# Plan mode in worktree
cc wt plan feature/complex

# Opus model in worktree
cc wt opus feature/important

# Haiku model in worktree
cc wt haiku feature/quick
```

---

## Part 3: Aliases for Speed

### Built-in Aliases

```bash
ccw feature/auth     # = cc wt feature/auth
ccwy feature/auth    # = cc wt yolo feature/auth
ccwp                 # = cc wt pick
```

### Quick Reference

| Alias  | Expands To        | Description              |
|--------|-------------------|--------------------------|
| `ccw`  | `cc wt`           | Worktree + Claude        |
| `ccwy` | `cc wt yolo`      | Worktree + YOLO mode     |
| `ccwp` | `cc wt pick`      | Worktree picker          |

---

## Part 4: Interactive Worktree Management

**NEW in v5.13.0** - Interactive picker with batch operations:

### Step 4.1: Launch Interactive Picker

```bash
# Interactive worktree picker with actions
pick wt
```

The picker shows all worktrees with status icons and session indicators. You can:

- **Filter** - Type to search worktrees
- **Tab** - Multi-select worktrees for batch operations
- **Ctrl-X** - Delete selected worktree(s)
- **Ctrl-R** - Refresh cache and show updated overview
- **Enter** - Navigate to selected worktree

### Step 4.2: Delete Worktrees

**In the picker:**

1. Select worktrees with **Tab**
2. Press **Ctrl-X** to delete

**You'll be prompted:**

```
Delete worktree: ~/.git-worktrees/myproject/feature-old? [y/n/a/q]
```

- **y** - Yes, delete this one
- **n** - No, skip this one
- **a** - Yes to all remaining
- **q** - Quit, don't delete any more

**After deleting worktree, you'll be asked:**

```
Also delete branch 'feature-old'? [y/N]
```

### Step 4.3: Refresh Cache

Press **Ctrl-R** in the picker to:

1. Clear the project cache
2. Show updated overview with current status

Useful after making git changes outside the picker.

---

## Part 5: Manual Cleanup

### Step 5.1: Remove a Worktree

```bash
# Remove specific worktree
wt remove ~/.git-worktrees/myproject/feature-auth
```

**Output:**

```
✓ Removed worktree: ~/.git-worktrees/myproject/feature-auth
```

### Step 5.2: Clean Stale Worktrees

```bash
# Prune worktrees with missing directories
wt clean
```

**Output:**

```
✓ Pruned stale worktrees
```

### Step 5.3: Move Current Branch to Worktree

```bash
# On feature/something branch
wt move
```

Creates a worktree for your current branch. Useful for moving in-progress work to a dedicated directory.

---

## Workflow Patterns

### Pattern 1: Parallel Feature Development

```bash
# Terminal 1: Main feature
cc flow
# ... work on feature-a ...

# Terminal 2: Quick fix
ccw hotfix/urgent
# ... fix the bug ...
# ... commit and push ...

# Back to Terminal 1, no context lost!
```

### Pattern 2: Code Review

```bash
# Review PR in isolated worktree
ccw feature/pr-123

# Claude can help review without affecting your work
cc wt plan feature/pr-123  # Plan mode for thorough review
```

### Pattern 3: Experimentation

```bash
# Try something risky in isolated worktree
ccwy experiment/new-approach

# If it doesn't work out:
wt remove ~/.git-worktrees/project/experiment-new-approach
git branch -D experiment/new-approach
```

---

## Configuration

### Worktree Base Directory

```bash
# Default location
~/.git-worktrees/

# Customize in .zshrc
export FLOW_WORKTREE_DIR="$HOME/worktrees"
```

### Directory Structure

Worktrees are organized by project:

```
~/.git-worktrees/
├── flow-cli/
│   ├── feature-auth/
│   └── hotfix-urgent/
├── mediationverse/
│   └── feature-new-method/
└── my-app/
    └── feature-dashboard/
```

---

## Quick Reference

| Command                    | Description                         | Version |
|----------------------------|-------------------------------------|---------|
| `wt`                       | Formatted overview (status + session) | v5.13.0 |
| `wt <project>`             | Filter worktrees by project name    | v5.13.0 |
| `wt cd`                    | Navigate to worktrees folder        | v5.13.0 |
| `wt list`                  | Raw git worktree list output        |         |
| `wt create <branch>`       | Create worktree for branch          |         |
| `wt move`                  | Move current branch to worktree     |         |
| `wt remove <path>`         | Remove a worktree                   |         |
| `wt clean`                 | Prune stale worktrees               |         |
| `pick wt`                  | Interactive picker with actions     | v5.13.0 |
| `cc wt <branch>`           | Launch Claude in worktree           |         |
| `cc wt pick`               | Pick worktree → Claude              |         |
| `cc wt yolo <branch>`      | Worktree + YOLO mode                |         |

**Interactive Picker Keybindings (v5.13.0):**

| Key        | Action                                    |
|------------|-------------------------------------------|
| **Tab**    | Multi-select worktrees for batch ops      |
| **Ctrl-X** | Delete selected worktree(s)               |
| **Ctrl-R** | Refresh cache and show updated overview   |
| **Enter**  | Navigate to selected worktree             |

---

## Troubleshooting

### "Branch already checked out"

```bash
# Can't have same branch in two worktrees
# Solution: Use a different branch name
wt create feature/auth-v2
```

### "Worktree not found"

```bash
# Prune stale references
wt clean

# Then try again
wt list
```

### "Not in a git repository"

```bash
# Worktree commands must run from a git repo
cd /path/to/your/repo
wt list
```

---

## What's Next?

- **[Git Feature Workflow](08-git-feature-workflow.md)** - Feature branch workflow
- **[CC Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#cc-dispatcher)** - Full Claude Code commands
- **[Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md)** - All dispatchers

---

**Tip:** Use `cc wt` when you need isolation for experiments, reviews, or parallel work. The worktree stays even after Claude exits!
