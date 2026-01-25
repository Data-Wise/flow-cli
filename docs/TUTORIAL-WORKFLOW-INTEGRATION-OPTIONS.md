# Tutorial + Workflow Integration: Two Approaches

**Date:** 2026-01-24
**Purpose:** Compare integrated vs separated workflow sections in tutorials
**Status:** Decision needed

---

## Option 1: Integrated Workflows (Within Tutorial Flow)

### Structure

```markdown
# Tutorial 09: Worktrees

## Overview
[What you'll learn]

## Prerequisites
[Required knowledge]

## Step 1: Understanding Worktrees
[Concept explanation]

**🔄 Workflow: When to Use Worktrees**
You'll use worktrees when:
- Working on multiple features simultaneously
- Need to test hotfix while feature in progress
- Want to review PR without stashing changes

## Step 2: Creating Your First Worktree
```bash
wt create feature/new-feature
```

**🔄 Workflow: Feature Development**
1. Create worktree for feature
2. Work in isolation
3. Test changes
4. Create PR
5. Cleanup after merge

## Step 3: Managing Multiple Worktrees

[Content]

**🔄 Workflow: Bug Fix + Feature Parallel**
[Workflow embedded in relevant step]

## What You Learned

[Summary]

## Next Steps

[Links to next tutorial]

```

### Characteristics

**Pros:**
- ✅ Natural flow (learn → apply immediately)
- ✅ Context-aware (workflow appears when concept is fresh)
- ✅ ADHD-friendly (action follows theory immediately)
- ✅ Single read-through (no jumping between sections)
- ✅ Easier to follow for beginners

**Cons:**
- ❌ Harder to find workflows later (scattered throughout)
- ❌ Can't quickly scan all workflows
- ❌ Might interrupt learning flow for some users
- ❌ Workflows not grouped for comparison

**Best For:**
- Beginners learning feature for first time
- Linear learning path
- Features with 1-2 main workflows
- When workflow IS the main point (e.g., Git Feature Workflow)

---

## Option 2: Separated Workflows (Dedicated Section)

### Structure

```markdown
# Tutorial 09: Worktrees

## Overview
[What you'll learn]

## Prerequisites
[Required knowledge]

## Step 1: Understanding Worktrees
[Pure concept explanation - no workflows yet]

## Step 2: Creating Your First Worktree
```bash
wt create feature/new-feature
```

[Pure tutorial - practice the mechanics]

## Step 3: Managing Multiple Worktrees

[Continue tutorial]

## What You Learned

[Summary of concepts]

---

## Common Workflows

Now that you understand worktrees, here are the most common workflow patterns:

### Workflow 1: Feature Development

**When to use:** Starting a new feature that needs isolation

**Steps:**
1. Create worktree: `wt create feature/new-feature`
2. Work in isolation (edit, test, commit)
3. Push and create PR: `g pr create`
4. After merge, cleanup: `wt prune`

**Example:**

```bash
# You're on main, want to add a new feature
wt create feature/user-auth
cd ~/.git-worktrees/flow-cli/feature-user-auth
# Work here, completely isolated from main
work user-auth
# ... make changes ...
finish "Add user authentication"
g push
g pr create
```

### Workflow 2: Bug Fix + Feature Parallel

**When to use:** Need to fix urgent bug while working on feature

**Steps:**
1. Keep feature worktree active
2. Create bug fix worktree from main repo
3. Fix bug, test, create PR
4. Return to feature worktree
5. After merge, cleanup: `wt prune`

**Example:**

```bash
# You're working on feature in worktree
# Urgent bug reported!

# Go to main repo (not worktree)
cd ~/projects/dev-tools/flow-cli
git checkout main

# Create hotfix worktree
wt create hotfix/critical-bug
cd ~/.git-worktrees/flow-cli/hotfix-critical-bug

# Fix bug
# ... make changes ...
finish "Fix critical bug"
g push
g pr create

# Return to feature work
cd ~/.git-worktrees/flow-cli/feature-user-auth
# Continue feature development
```

### Workflow 3: PR Review

**When to use:** Need to test someone's PR without disrupting your work

**Steps:**
1. Create worktree from PR branch
2. Test PR locally
3. Add review comments
4. Cleanup worktree

---

## Quick Reference

| Command | What It Does |
|---------|--------------|
| `wt create <branch>` | Create new worktree |
| `wt list` | List all worktrees |
| `wt prune` | Cleanup deleted worktrees |
| `wt status` | Show worktree status |

---

## Troubleshooting

[Common issues]

---

## Next Steps

[Links to next tutorial]

```

### Characteristics

**Pros:**
- ✅ Easy to find workflows later (single section)
- ✅ Can scan all workflows quickly
- ✅ Workflows grouped for comparison
- ✅ Tutorial section stays focused (pure learning)
- ✅ Works as reference (jump straight to workflows)

**Cons:**
- ❌ Delayed gratification (learn first, apply later)
- ❌ Might forget concepts by time you reach workflows
- ❌ Requires scrolling/jumping to see workflows
- ❌ Less context-aware (workflow separate from concept)

**Best For:**
- Features with 3+ distinct workflows
- Reference use (returning users who know the feature)
- Users who prefer overview-then-details
- When tutorial is primarily conceptual

---

## Option 3: Hybrid (Both Integrated + Separated) - RECOMMENDED

### Structure

```markdown
# Tutorial 09: Worktrees

## Overview
[What you'll learn]

## Prerequisites
[Required knowledge]

## Step 1: Understanding Worktrees
[Concept]

💡 **Quick Workflow Tip:** Use worktrees for feature isolation
```bash
wt create feature/new-feature  # Try it now!
```

## Step 2: Creating Your First Worktree

[Tutorial with inline workflow tips]

💡 **Workflow Tip:** Always create worktrees from a clean main branch

## Step 3: Managing Multiple Worktrees

[Content]

💡 **Workflow Tip:** Use `wt list` to see all active worktrees

## What You Learned

[Summary]

---

## 🔄 Common Workflows

Now that you understand the basics, here are complete workflow patterns:

### Workflow 1: Feature Development

[Full workflow with context, steps, example]

### Workflow 2: Bug Fix + Feature Parallel

[Full workflow]

### Workflow 3: PR Review

[Full workflow]

---

## Quick Reference

[Command table]

---

## Troubleshooting

[Issues]

---

## Next Steps

[Links]

```

### Characteristics

**Pros:**
- ✅ Best of both worlds
- ✅ Inline tips = immediate application (ADHD-friendly)
- ✅ Dedicated section = easy reference later
- ✅ Beginners get context + action
- ✅ Experts can jump straight to workflows section

**Cons:**
- ⚠️ Slightly longer tutorials
- ⚠️ Some repetition (tip + full workflow)

**Best For:**
- Most tutorials (default approach)
- Balances learning + reference use
- Works for both beginners and experts

---

## Visual Comparison

### Integrated (Option 1)

```

┌─────────────────────────────────────────────────────────────┐
│ Tutorial 09: Worktrees                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Step 1: Understanding Worktrees                             │
│   [Concept]                                                 │
│   🔄 Workflow: When to Use                                  │
│   [Apply immediately]                                       │
│                                                             │
│ Step 2: Creating Worktrees                                  │
│   [Tutorial]                                                │
│   🔄 Workflow: Feature Development                          │
│   [Hands-on practice]                                       │
│                                                             │
│ Step 3: Managing Worktrees                                  │
│   [Tutorial]                                                │
│   🔄 Workflow: Bug Fix Parallel                             │
│   [Apply immediately]                                       │
│                                                             │
│ Summary                                                     │
└─────────────────────────────────────────────────────────────┘

Flow: Learn → Apply → Learn → Apply (interleaved)

```

### Separated (Option 2)

```

┌─────────────────────────────────────────────────────────────┐
│ Tutorial 09: Worktrees                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Step 1: Understanding Worktrees                             │
│   [Pure concept]                                            │
│                                                             │
│ Step 2: Creating Worktrees                                  │
│   [Pure tutorial]                                           │
│                                                             │
│ Step 3: Managing Worktrees                                  │
│   [Pure tutorial]                                           │
│                                                             │
│ Summary                                                     │
│                                                             │
│ ─────────────────────────────────────────────────────────  │
│                                                             │
│ Common Workflows                                            │
│   🔄 Workflow 1: Feature Development                        │
│   🔄 Workflow 2: Bug Fix Parallel                           │
│   🔄 Workflow 3: PR Review                                  │
│                                                             │
│ Quick Reference                                             │
│ Troubleshooting                                             │
└─────────────────────────────────────────────────────────────┘

Flow: Learn All → Apply All (sequential)

```

### Hybrid (Option 3) - RECOMMENDED

```

┌─────────────────────────────────────────────────────────────┐
│ Tutorial 09: Worktrees                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Step 1: Understanding Worktrees                             │
│   [Concept]                                                 │
│   💡 Quick Tip: Try `wt create` now                         │
│                                                             │
│ Step 2: Creating Worktrees                                  │
│   [Tutorial]                                                │
│   💡 Quick Tip: Create from clean main                      │
│                                                             │
│ Step 3: Managing Worktrees                                  │
│   [Tutorial]                                                │
│   💡 Quick Tip: Use `wt list` often                         │
│                                                             │
│ Summary                                                     │
│                                                             │
│ ─────────────────────────────────────────────────────────  │
│                                                             │
│ 🔄 Common Workflows (Complete Patterns)                     │
│   Workflow 1: Feature Development                           │
│     [Full context, steps, example]                          │
│   Workflow 2: Bug Fix Parallel                              │
│     [Full context, steps, example]                          │
│   Workflow 3: PR Review                                     │
│     [Full context, steps, example]                          │
│                                                             │
│ Quick Reference                                             │
│ Troubleshooting                                             │
└─────────────────────────────────────────────────────────────┘

Flow: Learn + Quick Tips → Complete Workflow Patterns

```

---

## Recommendation Matrix

| Tutorial Type | Workflow Count | Recommended Approach |
|---------------|----------------|----------------------|
| **Concept-heavy** (e.g., Understanding Git) | 1-2 | Integrated (Option 1) |
| **Command-focused** (e.g., pick, status) | 0-1 | Integrated (Option 1) |
| **Workflow-heavy** (e.g., Git Feature Flow) | 3-5 | Hybrid (Option 3) ← DEFAULT |
| **Multi-pattern** (e.g., Worktrees, Teaching) | 6+ | Separated (Option 2) |

---

## Real Examples

### Example 1: Tutorial 08 (Git Feature Workflow)

**Current State:** Already workflow-focused

**Recommendation:** Hybrid (Option 3)

**Reason:** The tutorial IS about workflows, so integrated tips help, but dedicated section provides reference

**Structure:**
```markdown
# Tutorial 08: Git Feature Workflow

## Step 1: Understanding Feature Branches
💡 **Workflow Tip:** Create feature branch from latest main

## Step 2: Creating Feature Branch
[Tutorial]
💡 **Workflow Tip:** Use descriptive branch names

## Step 3: Development Cycle
[Tutorial]

---

## 🔄 Complete Workflow Patterns

### Workflow 1: Simple Feature (Solo Development)
[Full workflow]

### Workflow 2: Feature + Code Review
[Full workflow]

### Workflow 3: Feature + Hotfix Parallel
[Full workflow]
```

---

### Example 2: Tutorial 09 (Worktrees)

**Current State:** Tutorial-only (no workflows yet)

**Recommendation:** Hybrid (Option 3)

**Reason:** 3-4 distinct workflows, good for both learning and reference

**Structure:**

```markdown
# Tutorial 09: Worktrees

## Step 1-3: [Tutorial content]
[With inline 💡 tips]

---

## 🔄 Common Workflows

### Workflow 1: Feature Development
### Workflow 2: Bug Fix + Feature Parallel
### Workflow 3: PR Review
```

---

### Example 3: Tutorial 12 (DOT Dispatcher)

**Current State:** Tutorial-only

**Recommendation:** Separated (Option 2)

**Reason:** Many dotfile workflows (edit, sync, secret management, backup)

**Structure:**

```markdown
# Tutorial 12: DOT Dispatcher

## Step 1-4: [Pure tutorial]
[Learn commands]

---

## 🔄 Common Workflows

### Workflow 1: Edit Dotfiles
### Workflow 2: Sync Dotfiles
### Workflow 3: Secret Management
### Workflow 4: Backup & Restore
### Workflow 5: Multi-Machine Sync
```

---

## Implementation Decision

**User Choice:** ___________

- [ ] **Option 1:** Integrated (workflows within tutorial steps)
- [ ] **Option 2:** Separated (workflows in dedicated section)
- [ ] **Option 3:** Hybrid (inline tips + dedicated workflows section) ← RECOMMENDED

**OR Custom:**
- [ ] Use Option 3 (Hybrid) as DEFAULT
- [ ] But allow flexibility per tutorial based on:
  - Workflow count (1-2 = integrated, 3+ = separated)
  - Tutorial purpose (concept = integrated, patterns = separated)

---

## Next Steps

**After decision:**

1. **Create tutorial template** with chosen structure
2. **Update DOCUMENTATION-META-GUIDE.md** with workflow integration standard
3. **Migrate workflows to tutorials** following chosen approach
4. **Update help/WORKFLOWS.md** with cross-references

---

**Created:** 2026-01-24
**Status:** Awaiting user decision
**Recommended:** Option 3 (Hybrid) with flexibility per tutorial
