---
tags:
  - tutorial
  - git
---

# Tutorial: Git Feature Branch Workflow

> **What you'll learn:** Use the feature branch workflow to safely develop and merge changes
>
> **Time:** ~15 minutes | **Level:** Intermediate
> **Version:** v4.1.0+

---

## Prerequisites

Before starting, you should:

- [ ] Completed: [Tutorial 1: Your First Flow Session](01-first-session.md)
- [ ] Have a git repository with `main` and `dev` branches
- [ ] Understand basic git concepts (branches, commits, PRs)

**Verify your setup:**

```bash
# Check g dispatcher is available
g help

# Check you have main and dev branches
git branch -a | grep -E "main|dev"
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Create feature branches from dev
2. Keep features synced with dev
3. Create PRs using the proper workflow
4. Clean up merged branches

---

## The Workflow Pattern

```
feature/* ──► dev ──► main
    │          │        │
    └── PR ────┘        │
               └── PR ──┘
```

**Key Rules:**

- Never push directly to `main` or `dev`
- All work happens on `feature/*`, `hotfix/*`, or `bugfix/*` branches
- Use PRs to merge changes up the chain

---

## Part 1: Starting a Feature

### Step 1.1: Create a Feature Branch

```bash
# Start a new feature from dev
g feature start auth-improvements
```

**What happened:**

```
✅ Created feature/auth-improvements from dev
📍 Now on: feature/auth-improvements
```

This:

- Fetches latest `dev`
- Creates `feature/auth-improvements` from `dev`
- Switches to the new branch

### Step 1.2: Verify Your Branch

```bash
# Check current branch
g
```

**Output:**

```
On branch feature/auth-improvements
nothing to commit, working tree clean
```

---

## Part 2: Working on Your Feature

### Step 2.1: Make Changes and Commit

```bash
# Make your changes...
# Then commit
g add .
g commit "Add OAuth2 support"
```

### Step 2.2: Keep in Sync with Dev

While you work, `dev` may have new changes. Stay synced:

```bash
# Rebase your feature onto latest dev
g feature sync
```

**What happened:**

```
✅ Rebased feature/auth-improvements onto dev
📊 Your branch is 3 commits ahead of dev
```

**Tip:** Run `g feature sync` daily to avoid big merge conflicts!

### Step 2.3: Push Your Feature

```bash
# Push to remote
g push
```

The workflow guard will let this through because you're on a feature branch.

---

## Part 3: Creating Pull Requests

### Step 3.1: PR to Dev (Promote)

When your feature is ready:

```bash
# Create PR: feature → dev
g promote
```

**What happened:**

```
Creating PR: feature/auth-improvements → dev

✅ PR #42 created
   https://github.com/user/repo/pull/42
```

### Step 3.2: PR to Main (Release)

Once changes are tested in dev:

```bash
# First, switch to dev
git checkout dev

# Create PR: dev → main
g release
```

**What happened:**

```
Creating PR: dev → main

✅ PR #43 created
   https://github.com/user/repo/pull/43
```

---

## Part 4: Finishing and Cleanup

### Step 4.1: Finish a Feature

Push and create PR in one command:

```bash
# Push + create PR to dev
g feature finish
```

**What happened:**

```
📤 Pushing feature/auth-improvements...
✅ Created PR #42: feature/auth-improvements → dev
```

### Step 4.2: Clean Up Merged Branches

After your PRs are merged:

```bash
# See what would be deleted
g feature prune -n

# Actually delete merged branches
g feature prune

# Also clean remote tracking branches
g feature prune --all
```

**Output:**

```
🧹 Cleaning merged feature branches...

Will delete:
  feature/auth-improvements (merged to dev)
  feature/old-feature (merged to dev)

Delete 2 branches? [y/N] y

✅ Deleted 2 merged branches
```

---

## Part 5: The Workflow Guard

### What It Does

The workflow guard protects `main` and `dev` from direct pushes:

```bash
# Try to push to main (blocked)
git checkout main
g push
```

**Output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔ Direct push to 'main' blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflow: feature/* → dev → main

Commands:
  g promote    Create PR: feature → dev
  g release    Create PR: dev → main

Override: GIT_WORKFLOW_SKIP=1 git push
```

### Override When Needed

For emergencies only:

```bash
# Skip the guard (use sparingly!)
GIT_WORKFLOW_SKIP=1 git push
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `g feature start <name>` | Create feature branch from dev |
| `g feature sync` | Rebase feature onto dev |
| `g feature list` | List feature/hotfix branches |
| `g feature finish` | Push + create PR to dev |
| `g feature prune` | Delete merged branches |
| `g promote` | Create PR: feature → dev |
| `g release` | Create PR: dev → main |

---

## Common Scenarios

### Scenario 1: Starting New Work

```bash
g feature start new-feature    # Create branch
# ... make changes ...
g add . && g commit "message"  # Commit
g feature finish               # Push + PR
```

### Scenario 2: Hotfix Needed

```bash
g feature start hotfix/urgent-fix  # Use hotfix/ prefix
# ... fix the issue ...
g promote                          # PR to dev
g release                          # PR to main (after dev merge)
```

### Scenario 3: Weekly Cleanup

```bash
g feature list                 # See all feature branches
g feature prune --all          # Clean merged + remote
```

---

## Troubleshooting

### "Branch already exists"

```bash
# Delete old branch first
git branch -d feature/old-name
g feature start new-name
```

### "Rebase conflicts"

```bash
# During g feature sync, if conflicts:
# 1. Fix conflicts in files
# 2. git add <fixed-files>
# 3. git rebase --continue
```

### "PR creation failed"

```bash
# Check gh is authenticated
gh auth status

# Re-authenticate if needed
gh auth login
```

---

## What's Next?

- **[Tutorial 9: Worktrees](09-worktrees.md)** - Parallel development with worktrees
- **[Git Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#g-dispatcher)** - All g commands
- **[V4.3 Roadmap](../planning/V4.3-ROADMAP.md)** - Upcoming features

---

**Tip:** Start with `g feature start` for every new piece of work. It keeps your branches organized and your workflow clean!
