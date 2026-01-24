# Git Worktrees with Claude Code

**Level:** Intermediate
**Time:** 15 minutes
**Goal:** Use git worktrees for isolated, parallel Claude Code development

---

## What This Guide Covers

Learn how to combine git worktrees with Claude Code for safe, parallel development:

- ✅ **What worktrees are** and why they're better than branches for experiments
- ✅ **CC dispatcher integration** with unified mode-first pattern
- ✅ **Complete workflows** for experimentation and parallel work
- ✅ **Safety practices** with YOLO mode in worktrees
- ✅ **Session tracking** to see which worktrees have active Claude sessions

---

## Why Worktrees?

### The Problem with Branch Switching

**Traditional git workflow:**

```bash
git checkout -b experiment-refactor
# Work on experiment...
# Oh no, urgent bug fix needed!
git stash                  # Save work
git checkout main          # Switch branch
git checkout -b hotfix     # Create fix branch
# Fix bug...
git checkout experiment-refactor  # Back to experiment
git stash pop              # Restore work
```

**Issues:**
- ⚠️ Constant stashing/unstashing
- ⚠️ Lost context when switching
- ⚠️ Can't work on multiple features simultaneously
- ⚠️ IDE has to reload files on every branch switch

### The Worktree Solution

**Git worktrees = Multiple working directories for same repo:**

```bash
~/projects/flow-cli/                      # Main (production)
~/.git-worktrees/flow-cli-refactor/       # Experiment 1
~/.git-worktrees/flow-cli-hotfix/         # Urgent fix
~/.git-worktrees/flow-cli-new-feature/    # Feature work
```

**Benefits:**
- ✅ Each branch has its own directory
- ✅ No branch switching needed
- ✅ Work on multiple features in parallel
- ✅ IDE stays stable (one project per window)
- ✅ Easy cleanup (just delete directory)

---

## Basic Worktree Commands

### Create Worktree

```bash
# Via flow-cli wt dispatcher
wt create feature/new-auth

# Or via git directly
git worktree add ~/.git-worktrees/flow-cli-feature-new-auth feature/new-auth
```

**Location:** `~/.git-worktrees/<repo>-<branch>/`

### List Worktrees

```bash
# Via flow-cli
wt list

# Or via git
git worktree list
```

**Output:**

```
/Users/dt/projects/flow-cli          abc123 [main]
/Users/dt/.git-worktrees/flow-cli-refactor  def456 [feature/refactor]
```

### Remove Worktree

```bash
# Via flow-cli
wt remove feature/new-auth

# Or via git
git worktree remove ~/.git-worktrees/flow-cli-feature-new-auth
```

---

## CC Dispatcher Integration

### Unified "Mode First" Pattern

The CC dispatcher now supports **consistent** mode → target syntax:

```bash
# Pattern: cc [mode] [target]
# Modes: (none), yolo, plan, opus, haiku
# Targets: (here), pick, wt <branch>, <project>
```

### Basic Worktree Launch

```bash
# Launch Claude in worktree (creates if needed)
cc wt feature/refactor

# Pick from existing worktrees
cc wt pick

# List worktrees with session info
cc wt status
```

### Mode-First Pattern (NEW!)

**YOLO mode:**

```bash
cc yolo wt feature/refactor     # Mode → worktree
cc yolo wt pick                 # Mode → worktree picker
```

**Plan mode:**

```bash
cc plan wt feature/refactor     # Plan mode in worktree
cc plan wt pick                 # Pick worktree for planning
```

**Model selection:**

```bash
cc opus wt experiment/ui        # Opus model in worktree
cc haiku wt feature/docs        # Haiku model in worktree
```

### Backward Compatible Pattern

**Old syntax still works:**

```bash
cc wt yolo feature/refactor     # Target → mode (still works)
cc wt plan feature/refactor     # Target → mode (still works)
cc wt opus experiment/ui        # Target → mode (still works)
```

**Aliases:**

```bash
ccw feature/refactor            # cc wt
ccwy feature/refactor           # cc wt yolo
ccwp                            # cc wt pick
ccy                             # cc yolo
```

---

## Complete Workflows

### Workflow 1: Safe Experimentation with YOLO Mode

**Scenario:** Want to refactor entire commands/ directory without risk

```bash
# 1. Create worktree with YOLO mode (mode-first)
cc yolo wt experiment/commands-refactor

# Claude launches in:
# ~/.git-worktrees/flow-cli-experiment-commands-refactor/
# With: --dangerously-skip-permissions

# 2. Give Claude instructions
> Refactor all commands/*.zsh files to use modern ZSH patterns and consistent error handling

# 3. Monitor from main project (separate terminal)
cd ~/projects/flow-cli
watch -n 2 'git -C ~/.git-worktrees/flow-cli-experiment-commands-refactor diff --stat'

# 4. Review when done
cd ~/.git-worktrees/flow-cli-experiment-commands-refactor
git diff --stat
git diff commands/

# 5. Decision point
# Option A: Success! Merge to main
cd ~/projects/flow-cli
git checkout main
git merge experiment/commands-refactor
git push

# Option B: Failed experiment - just delete
wt remove experiment/commands-refactor
# All changes gone, main repo untouched
```

**Why this works:**
- ✅ YOLO mode = no permission prompts
- ✅ Worktree = main repo stays safe
- ✅ Easy cleanup if experiment fails
- ✅ No branch switching needed

### Workflow 2: Parallel Feature Development

**Scenario:** Working on two features simultaneously

```bash
# Terminal 1: Feature A (authentication)
cc wt feature/new-auth
cd ~/.git-worktrees/flow-cli-feature-new-auth
# Work on auth...

# Terminal 2: Feature B (documentation)
cc plan wt feature/docs-update
cd ~/.git-worktrees/flow-cli-feature-docs-update
# Work on docs with plan mode...

# Terminal 3: Main project (review/testing)
cd ~/projects/flow-cli
git status
pytest
```

**Benefits:**
- Each feature isolated
- No context switching
- Can test changes independently
- Main repo available for review

### Workflow 3: Quick Hotfix While Working

**Scenario:** Urgent bug fix needed during feature work

```bash
# Already working in feature worktree
cd ~/.git-worktrees/flow-cli-feature-refactor
# Claude session active...

# Urgent bug reported! Don't switch context
# Terminal 2: Create hotfix worktree
cc wt hotfix/picker-crash

# Fix bug in hotfix worktree
cd ~/.git-worktrees/flow-cli-hotfix-picker-crash
# Make fix, test, commit

# Merge hotfix to main
cd ~/projects/flow-cli
git checkout main
git merge hotfix/picker-crash
git push

# Back to feature work (untouched!)
cd ~/.git-worktrees/flow-cli-feature-refactor
# Continue where you left off
```

### Workflow 4: Experimenting with Different Approaches

**Scenario:** Not sure which refactoring approach is best

```bash
# Create 3 experimental worktrees
cc wt experiment/approach-a
cc wt experiment/approach-b
cc wt experiment/approach-c

# Try different approaches in parallel
# Terminal 1: Approach A (functional)
cd ~/.git-worktrees/flow-cli-experiment-approach-a
cc yolo
> Refactor commands/ using pure functional approach

# Terminal 2: Approach B (OOP)
cd ~/.git-worktrees/flow-cli-experiment-approach-b
cc yolo
> Refactor commands/ using object-oriented patterns

# Terminal 3: Approach C (modular)
cd ~/.git-worktrees/flow-cli-experiment-approach-c
cc yolo
> Refactor commands/ into small, composable modules

# Compare results
wt status                    # See which has recent sessions
cd ~/projects/flow-cli
git diff experiment/approach-a..main -- commands/ | wc -l
git diff experiment/approach-b..main -- commands/ | wc -l
git diff experiment/approach-c..main -- commands/ | wc -l

# Pick winner, delete losers
git merge experiment/approach-b
wt remove experiment/approach-a
wt remove experiment/approach-c
```

---

## Session Tracking

### Check Worktree Sessions

```bash
# Show all worktrees with Claude session info
cc wt status
```

**Output:**

```
Worktrees with Claude Session Info
────────────────────────────────────────

🟢 ~/.git-worktrees/flow-cli-refactor     [feature/refactor] (2026-01-01 14:32)
🟡 ~/.git-worktrees/flow-cli-experiment   [experiment/new]    (old session)
⚪ ~/.git-worktrees/flow-cli-hotfix       [hotfix/bug]

Legend: 🟢 Recent session (< 24h) | 🟡 Old session | ⚪ No session
```

**Indicators:**
- 🟢 Recent session (< 24 hours ago)
- 🟡 Old session (> 24 hours ago)
- ⚪ No Claude session in this worktree

**Use case:** Find where you were last working

### Pick with Session Priority

```bash
# FZF picker shows worktrees
cc wt pick
```

**Display includes:**
- Session indicators (🟢/🟡)
- Branch names
- Recent activity timestamps

---

## Safety Practices

### 1. Worktrees Don't Replace Git Safety

**Still required:**

```bash
# Before YOLO in worktree
cd ~/.git-worktrees/flow-cli-experiment
git status                    # Ensure clean
git log -1                    # Check starting point

# During work
watch -n 2 'git diff --stat'  # Monitor changes

# After work
git diff                      # Review ALL changes
git add -p                    # Stage selectively
```

### 2. Cleanup Regularly

**Find stale worktrees:**

```bash
wt list
# Or
git worktree list

# Remove finished experiments
wt remove experiment/old-idea
wt remove feature/completed
```

### 3. Keep Main Clean

**Never work directly in main worktree during experiments:**

```bash
# Good: Separate worktree for experiment
cc yolo wt experiment/risky-change

# Bad: YOLO mode in main project
cd ~/projects/flow-cli
cc yolo                       # ❌ Too risky!
```

### 4. Name Worktrees Clearly

**Good names:**
- `experiment/commands-refactor` - Purpose clear
- `feature/oauth-login` - Feature clear
- `hotfix/picker-crash` - Type clear

**Bad names:**
- `test` - What test?
- `tmp` - Temporary what?
- `new` - New what?

### 5. One Claude Session Per Worktree

**Avoid confusion:**

```bash
# Good: One session
cd ~/.git-worktrees/flow-cli-feature-auth
cc yolo

# Bad: Multiple sessions in same worktree (confusing)
# Terminal 1
cc yolo wt feature/auth
# Terminal 2
cc yolo wt feature/auth      # ❌ Two sessions, same files
```

---

## Advanced Patterns

### Shared Worktree for Team Review

**Scenario:** Team member wants to review your experimental branch

```bash
# You: Create worktree for experiment
cc yolo wt experiment/new-parser

# Commit work
git add -A
git commit -m "WIP: new parser approach"
git push origin experiment/new-parser

# Team member: Clone as worktree
git worktree add ~/.git-worktrees/flow-cli-experiment-new-parser origin/experiment/new-parser
cd ~/.git-worktrees/flow-cli-experiment-new-parser
cc  # Review with Claude
```

### Worktree for CI/CD Testing

**Scenario:** Test changes in isolation before merge

```bash
# Create worktree from feature branch
cc wt feature/new-feature

# Run full test suite in worktree
cd ~/.git-worktrees/flow-cli-feature-new-feature
pytest
npm test
./tests/run-all.sh

# CI passes? Merge from main
cd ~/projects/flow-cli
git checkout main
git merge feature/new-feature

# CI fails? Debug in worktree (main untouched)
cd ~/.git-worktrees/flow-cli-feature-new-feature
cc yolo
> Fix the failing tests
```

### Long-Running Experiments

**Scenario:** Multi-day refactoring project

```bash
# Day 1: Start experiment
cc yolo wt experiment/async-rewrite
# Work...
git add -A && git commit -m "Day 1: Convert core functions to async"

# Day 2: Continue (worktree persists)
cd ~/.git-worktrees/flow-cli-experiment-async-rewrite
cc yolo
# Continue...
git add -A && git commit -m "Day 2: Update tests for async"

# Day 3: Finish
# Continue...
git add -A && git commit -m "Day 3: Documentation and cleanup"

# Review full history
git log experiment/async-rewrite --oneline

# Merge or squash
cd ~/projects/flow-cli
git checkout main
git merge --squash experiment/async-rewrite
git commit -m "feat: migrate to async architecture"
```

---

## Troubleshooting

### Worktree Creation Fails

**Error:** `fatal: 'feature/auth' is already checked out at '...'`

**Solution:** Branch already has a worktree

```bash
# List existing worktrees
wt list

# Remove old worktree if done with it
wt remove feature/auth

# Or use the existing worktree
cd ~/.git-worktrees/flow-cli-feature-auth
```

### Can't Find Worktree

**Error:** Created worktree but can't remember path

**Solution:**

```bash
# List all worktrees with full paths
wt list

# Or use picker
cc wt pick
```

### Worktree Out of Sync

**Problem:** Worktree doesn't have latest changes

**Solution:** Pull in worktree

```bash
cd ~/.git-worktrees/flow-cli-feature-auth
git status
git pull origin feature/auth
```

### Session Indicator Wrong

**Problem:** 🟢 indicator shows but no active session

**Explanation:** Indicator shows last session time, not current session
- 🟢 = Session within 24 hours (may be closed now)
- Check `.claude/*.json` files for actual session data

### Disk Space Issues

**Problem:** Too many old worktrees

**Solution:** Cleanup

```bash
# List all worktrees
wt list

# Remove old experiments
wt remove experiment/old-1
wt remove experiment/old-2

# Or clean up manually
git worktree prune
```

---

## Comparison: Branches vs Worktrees

| Feature | Git Branches | Git Worktrees |
|---------|--------------|---------------|
| **Isolation** | Switch working tree | Separate directories |
| **Parallel work** | ❌ No (must stash) | ✅ Yes |
| **IDE stability** | ❌ Reloads on switch | ✅ Stable |
| **Disk usage** | ✅ Minimal | ⚠️ More (separate copies) |
| **Cleanup** | Delete branch | Delete directory + branch |
| **Best for** | Sequential work | Parallel experiments |

**When to use branches:**
- Sequential development
- Single developer
- Limited disk space

**When to use worktrees:**
- Parallel development
- Experimentation (easy cleanup)
- Hotfixes during feature work
- Team reviews

---

## Best Practices Summary

### ✅ DO

- ✅ Use worktrees for experiments and risky changes
- ✅ Combine with YOLO mode for speed + safety
- ✅ Name worktrees descriptively
- ✅ Review changes before merging
- ✅ Clean up finished worktrees
- ✅ Use session indicators to find active work
- ✅ Keep one Claude session per worktree

### ❌ DON'T

- ❌ Use YOLO mode in main project directory
- ❌ Let worktrees accumulate without cleanup
- ❌ Forget to commit work in worktrees
- ❌ Run multiple Claude sessions in same worktree
- ❌ Use vague names like "test" or "tmp"

---

## Quick Reference

### Create & Launch

```bash
cc wt <branch>              # acceptEdits mode
cc yolo wt <branch>         # YOLO mode
cc plan wt <branch>         # Plan mode
cc opus wt <branch>         # Opus model
```

### Pick Existing

```bash
cc wt pick                  # acceptEdits mode
cc yolo wt pick             # YOLO mode
cc plan wt pick             # Plan mode
```

### Status & Management

```bash
cc wt status                # Show all with sessions
wt list                     # List all worktrees
wt remove <branch>          # Delete worktree
```

### Aliases

```bash
ccw <branch>                # cc wt
ccwy <branch>               # cc wt yolo
ccwp                        # cc wt pick
ccy                         # cc yolo
```

---

## Related Documentation

- [YOLO Mode Workflow](./YOLO-MODE-WORKFLOW.md) - Permission bypass strategies
- [CC Dispatcher Reference](../reference/CC-DISPATCHER-REFERENCE.md) - Complete command guide
- [Git Feature Workflow](../tutorials/08-git-feature-workflow.md) - Branch management

---

## Summary

**Git worktrees enable:**
1. ✅ Parallel development without branch switching
2. ✅ Safe experimentation with easy cleanup
3. ✅ YOLO mode isolation (fast + safe)
4. ✅ Hotfixes during feature work

**Best workflow:**
- Experiments → `cc yolo wt experiment/<name>`
- Features → `cc wt feature/<name>`
- Hotfixes → `cc wt hotfix/<name>`

**Remember:**
- Main repo stays clean
- Easy cleanup (delete directory)
- Session tracking built-in
- Works with all CC modes (yolo, plan, opus, haiku)

---

**Last Updated:** 2026-01-01
**Flow-CLI Version:** v4.8.0+
