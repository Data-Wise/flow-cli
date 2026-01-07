# Workflow Template

> **Use this template** for documenting common workflow patterns and real-world usage scenarios.

---

## When to Use

| Content Type | Use When |
|-------------|----------|
| Quick Start | Get running in < 5 minutes |
| Tutorial | Learn one feature step-by-step |
| **Workflow** | **Show how to accomplish real tasks** |
| Guide | Deep conceptual understanding |
| Reference Card | Quick command lookup |

**Workflows are for:** Users who know basics and need patterns for accomplishing specific tasks.

---

## Design Principles

1. **Task-focused** — One real-world task per workflow
2. **Scenario-based** — Start with "When you want to..."
3. **Command-heavy** — Show actual commands, minimal prose
4. **Multiple paths** — Present variations and alternatives
5. **Troubleshooting** — Include common issues

---

## Template Structure

```markdown
# [Workflow Name]

> **Scenario:** [When you use this workflow - one sentence]
> **Time:** [X] minutes
> **Difficulty:** ⚡ Easy | 🔧 Medium | 🏗️ Complex

---

## When to Use This Workflow

Use this workflow when you need to:

- [Use case 1]
- [Use case 2]
- [Use case 3]

**Example scenarios:**
- [Real-world example 1]
- [Real-world example 2]

---

## Prerequisites

Before starting, ensure you have:

- [x] [Tool or knowledge required]
- [x] [Setup or configuration needed]

**Quick check:**
\`\`\`bash
# Verify prerequisites
[verification command]
\`\`\`

---

## Basic Workflow

### Standard Path

\`\`\`bash
# Step 1: [Action]
[command]

# Step 2: [Action]
[command]

# Step 3: [Action]
[command]
\`\`\`

**Expected result:** [What success looks like]

---

## Variations

### Variation 1: [Scenario]

**When to use:** [Specific situation]

\`\`\`bash
# Modified workflow
[commands]
\`\`\`

### Variation 2: [Scenario]

**When to use:** [Specific situation]

\`\`\`bash
# Alternative approach
[commands]
\`\`\`

### Variation 3: [Scenario]

**When to use:** [Specific situation]

\`\`\`bash
# Another option
[commands]
\`\`\`

---

## Step-by-Step Breakdown

### 1. [First Step Name]

**Purpose:** [Why this step matters]

\`\`\`bash
[command]
\`\`\`

**What it does:**
- [Point 1]
- [Point 2]

**Options:**
| Flag | Purpose |
|------|---------|
| \`--option1\` | [Description] |
| \`--option2\` | [Description] |

### 2. [Second Step Name]

**Purpose:** [Why this step matters]

\`\`\`bash
[command]
\`\`\`

**What it does:**
- [Point 1]
- [Point 2]

### 3. [Third Step Name]

**Purpose:** [Why this step matters]

\`\`\`bash
[command]
\`\`\`

**Success indicators:**
- ✅ [What you should see]
- ✅ [What should happen]

---

## Common Patterns

### Pattern 1: [Pattern Name]

\`\`\`bash
# [Description of when to use]
[command sequence]
\`\`\`

### Pattern 2: [Pattern Name]

\`\`\`bash
# [Description of when to use]
[command sequence]
\`\`\`

### Pattern 3: [Pattern Name]

\`\`\`bash
# [Description of when to use]
[command sequence]
\`\`\`

---

## Troubleshooting

### Issue 1: [Problem]

**Symptoms:**
- [What you see]
- [What goes wrong]

**Cause:** [Why it happens]

**Solution:**
\`\`\`bash
# Fix
[command]
\`\`\`

### Issue 2: [Problem]

**Symptoms:**
- [What you see]

**Cause:** [Why it happens]

**Solution:**
\`\`\`bash
# Fix
[command]
\`\`\`

### Issue 3: [Problem]

**Symptoms:**
- [What you see]

**Cause:** [Why it happens]

**Solution:**
\`\`\`bash
# Fix
[command]
\`\`\`

---

## Best Practices

**Do:**
- ✅ [Best practice 1]
- ✅ [Best practice 2]
- ✅ [Best practice 3]

**Don't:**
- ❌ [Anti-pattern 1]
- ❌ [Anti-pattern 2]
- ❌ [Anti-pattern 3]

---

## Advanced Usage

### Power User Tips

\`\`\`bash
# Tip 1: [Description]
[command]

# Tip 2: [Description]
[command]

# Tip 3: [Description]
[command]
\`\`\`

### Combining with Other Workflows

This workflow combines well with:
- [Related workflow 1] — [When to combine]
- [Related workflow 2] — [When to combine]

**Example combination:**
\`\`\`bash
# This workflow + another workflow
[combined commands]
\`\`\`

---

## Quick Reference

\`\`\`
┌─────────────────────────────────────────────────────────┐
│  [WORKFLOW NAME] QUICK REFERENCE                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  BASIC WORKFLOW                                         │
│  [cmd1]         [description]                           │
│  [cmd2]         [description]                           │
│  [cmd3]         [description]                           │
│                                                         │
│  VARIATIONS                                             │
│  [var1]         [when to use]                           │
│  [var2]         [when to use]                           │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  PATTERN: [step] → [step] → [step]                      │
└─────────────────────────────────────────────────────────┘
\`\`\`

---

## Related Resources

- **Tutorial:** [Link to related tutorial]
- **Reference:** [Link to command reference]
- **Guide:** [Link to conceptual guide]
- **Video:** [Link to visual demo if available]

---

**Last Updated:** [Date]
**Workflow Difficulty:** [Easy/Medium/Complex]
```

---

## Example: Git Feature Workflow

```markdown
# Git Feature Workflow

> **Scenario:** Create a feature branch, make changes, and merge to main
> **Time:** 10-15 minutes
> **Difficulty:** 🔧 Medium

---

## When to Use This Workflow

Use this workflow when you need to:

- Work on a new feature without affecting main branch
- Experiment with changes safely
- Prepare changes for pull request

**Example scenarios:**
- Adding a new command to flow-cli
- Refactoring existing code
- Testing experimental features

---

## Prerequisites

Before starting, ensure you have:

- [x] Git installed and configured
- [x] Clean working directory (no uncommitted changes)
- [x] Main branch up to date

**Quick check:**
\`\`\`bash
# Verify prerequisites
git status
git pull origin main
\`\`\`

---

## Basic Workflow

### Standard Path

\`\`\`bash
# Step 1: Create feature branch
git checkout -b feature/my-feature

# Step 2: Make changes and commit
git add .
git commit -m "Add feature"

# Step 3: Push and merge
git push -u origin feature/my-feature
git checkout main
git merge feature/my-feature
git push origin main
\`\`\`

**Expected result:** Feature merged to main, branch pushed to remote

---

## Variations

### Variation 1: Using G Dispatcher

**When to use:** If you have flow-cli installed

\`\`\`bash
# Simplified with dispatcher
g feature start my-feature
# [make changes]
g feature finish
\`\`\`

### Variation 2: With Pull Request

**When to use:** Team collaboration, code review needed

\`\`\`bash
# Create and push branch
g feature start my-feature
# [make changes]
g push

# Create PR via GitHub CLI
gh pr create --title "Add feature" --body "Description"
\`\`\`

### Variation 3: Worktree Approach

**When to use:** Working on multiple features in parallel

\`\`\`bash
# Create worktree instead of branch
wt create feature/my-feature
cd ~/.git-worktrees/my-feature
# [make changes]
wt finish
\`\`\`

---

## Step-by-Step Breakdown

### 1. Create Feature Branch

**Purpose:** Isolate your changes from main branch

\`\`\`bash
git checkout -b feature/my-feature
\`\`\`

**What it does:**
- Creates new branch from current HEAD
- Switches to the new branch automatically
- Preserves all existing code

**Options:**
| Flag | Purpose |
|------|---------|
| \`-b\` | Create and checkout in one command |
| \`-B\` | Force create (overwrite existing) |

### 2. Make Changes and Commit

**Purpose:** Save your work with clear history

\`\`\`bash
# Make changes to files
git add .
git commit -m "feat: add new feature

Detailed description of what changed and why"
\`\`\`

**What it does:**
- Stages all changed files
- Creates commit with descriptive message
- Updates branch history

### 3. Push to Remote

**Purpose:** Backup your work and enable collaboration

\`\`\`bash
git push -u origin feature/my-feature
\`\`\`

**Success indicators:**
- ✅ Branch appears on GitHub
- ✅ No error messages
- ✅ \`git status\` shows "up to date with origin"

---

## Common Patterns

### Pattern 1: Quick Feature (No PR)

\`\`\`bash
# For small features, direct merge
g feature start quick-fix
# [make changes]
g commit "fix: quick bug fix"
g feature finish
\`\`\`

### Pattern 2: Long-Running Feature

\`\`\`bash
# Keep feature branch updated with main
g feature start big-feature
# [work for days]
g fetch
g rebase main  # Stay current with main
# [continue work]
g feature finish
\`\`\`

### Pattern 3: Collaborative Feature

\`\`\`bash
# Multiple developers on same branch
g feature start team-feature
# [make changes]
g push
# [teammate pulls and adds commits]
g pull --rebase
# [resolve any conflicts]
g push
\`\`\`

---

## Troubleshooting

### Issue 1: "Branch already exists"

**Symptoms:**
- Error: "fatal: A branch named 'feature/x' already exists"

**Cause:** Branch name conflict

**Solution:**
\`\`\`bash
# Use different name or delete old branch
git branch -d feature/old-name
# Or force overwrite (dangerous!)
git checkout -B feature/name
\`\`\`

### Issue 2: Merge conflicts

**Symptoms:**
- Error: "CONFLICT (content): Merge conflict in file.txt"
- Files show <<<<<<< markers

**Cause:** Main branch changed same lines

**Solution:**
\`\`\`bash
# Fix conflicts in editor, then:
git add file.txt
git commit -m "chore: resolve merge conflicts"
\`\`\`

### Issue 3: Forgot to create branch

**Symptoms:**
- Made commits directly on main branch

**Cause:** Forgot \`git checkout -b\`

**Solution:**
\`\`\`bash
# Create branch from current state
git branch feature/name
git reset --hard origin/main  # Reset main
git checkout feature/name     # Switch to feature
\`\`\`

---

## Best Practices

**Do:**
- ✅ Use descriptive branch names (\`feature/add-dashboard\`)
- ✅ Commit frequently with clear messages
- ✅ Pull main before starting new feature
- ✅ Delete branches after merging

**Don't:**
- ❌ Work directly on main branch
- ❌ Use generic names (\`test\`, \`fix\`)
- ❌ Commit half-finished work
- ❌ Force push to shared branches

---

## Advanced Usage

### Power User Tips

\`\`\`bash
# Tip 1: Auto-cleanup merged branches
git branch --merged | grep -v "main" | xargs git branch -d

# Tip 2: Interactive rebase for clean history
git rebase -i main

# Tip 3: Stash changes before switching
git stash && git checkout main && git stash pop
\`\`\`

### Combining with Other Workflows

This workflow combines well with:
- **Worktree Workflow** — Use worktrees for parallel features
- **YOLO Mode** — Use \`cc yolo\` for rapid AI-assisted development

**Example combination:**
\`\`\`bash
# Feature workflow + YOLO mode
g feature start ai-feature
cc yolo  # AI helps implement
g feature finish
\`\`\`

---

## Quick Reference

\`\`\`
┌─────────────────────────────────────────────────────────┐
│  GIT FEATURE WORKFLOW QUICK REFERENCE                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  BASIC WORKFLOW                                         │
│  g feature start <name>    Create feature branch        │
│  [make changes]            Work on feature              │
│  g commit "message"        Commit changes               │
│  g feature finish          Merge to main                │
│                                                         │
│  VARIATIONS                                             │
│  wt create <name>          Use worktree instead         │
│  gh pr create              Create pull request          │
│  g rebase main             Keep up to date              │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  PATTERN: start → work → commit → finish                │
└─────────────────────────────────────────────────────────┘
\`\`\`

---

## Related Resources

- **Tutorial:** [Tutorial 8: Git Feature Workflow](../../tutorials/08-git-feature-workflow.md)
- **Reference:** [G Dispatcher Reference](../../reference/G-DISPATCHER-REFERENCE.md)
- **Guide:** [Worktree Workflow](../../guides/WORKTREE-WORKFLOW.md)

---

**Last Updated:** 2026-01-07
**Workflow Difficulty:** Medium
```

---

## Workflow Difficulty Levels

| Level | Time | Prerequisites | Examples |
|-------|------|---------------|----------|
| ⚡ **Easy** | < 5 min | Basic knowledge only | Daily standup, quick commit |
| 🔧 **Medium** | 5-15 min | Some tool experience | Feature branch, PR workflow |
| 🏗️ **Complex** | 15+ min | Advanced knowledge | Monorepo release, database migration |

---

## Variation Guidelines

Always include variations that show:

1. **Different tools** (e.g., git commands vs g dispatcher)
2. **Different scenarios** (e.g., solo vs team work)
3. **Different complexity levels** (e.g., quick vs thorough)

**Format:**
```markdown
### Variation N: [Name]

**When to use:** [Specific scenario]

\`\`\`bash
# Commands
\`\`\`
```

---

## ADHD-Friendly Tips

1. **Scannable code blocks** — Commands stand out visually
2. **Variations up front** — Don't bury alternatives
3. **Quick reference at end** — One-page cheat sheet
4. **Real scenarios** — Not abstract examples
5. **Success indicators** — Know when you're done
6. **Troubleshooting first** — Address common failures
7. **Time estimates** — Manage expectations

---

## Checklist for New Workflows

- [ ] Scenario clearly stated (one sentence)
- [ ] Time and difficulty level specified
- [ ] Prerequisites listed with verification command
- [ ] Basic workflow shown first (simple path)
- [ ] At least 3 variations provided
- [ ] Step-by-step breakdown explains why
- [ ] Common patterns section included
- [ ] Troubleshooting covers top 3 issues
- [ ] Best practices (do/don't) listed
- [ ] Quick reference box at end
- [ ] Related resources linked

---

**Last Updated:** 2026-01-07
**Template Version:** 1.0
