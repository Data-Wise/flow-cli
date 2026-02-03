---
tags:
  - guide
  - getting-started
  - adhd
---

# 🧠 ADHD-Friendly Workflows - Quick Wins Guide

> **Focus:** Top 10 highest-impact workflows for daily R package development

**Read Time:** 5 minutes | **Apply Time:** Immediate
**Last Updated:** 2025-12-21 (Updated for 28-alias system)

---

## 📋 Table of Contents

| #   | Workflow                                                   | Time   | Load | Use When               |
| --- | ---------------------------------------------------------- | ------ | ---- | ---------------------- |
| 1   | [Quick Test](#1-quick-test-cycle)                          | 5 min  | 🟢   | Made code changes      |
| 2   | [Load + Test](#2-load-test-atomic)                         | 5 min  | 🟢   | Fresh start on package |
| 3   | [Doc + Test](#3-document-test)                             | 8 min  | 🟢   | Changed function docs  |
| 4   | [Full Check](#4-full-check-before-commit)                  | 60 min | 🟡   | Before git commit      |
| 5   | [Quick Commit](#5-quick-commit-workflow)                   | 3 min  | 🟢   | Ready to save work     |
| 6   | [Fix Failing Tests](#6-fix-failing-tests)                  | varies | 🟡   | Tests are red          |
| 7   | [Context Check](#7-where-am-i-context-check)               | 30 sec | 🟢   | Lost context           |
| 8   | [Focus Mode](#8-focus-mode-deep-work)                      | setup  | 🟢   | Need concentration     |
| 9   | [Start Feature](#9-start-new-feature)                      | 2 min  | 🟢   | Beginning new work     |
| 10  | [Emergency Recovery](#what-did-i-break-emergency-recovery) | varies | 🔴   | Something broke        |
| 11  | [Git Feature Workflow](#11-git-feature-branch-workflow-v410) | 2 min  | 🟢 | Feature branches       |
| 12  | [Worktrees](#12-parallel-development-with-worktrees-v410)    | 1 min  | 🟢 | Parallel development   |

**Cognitive Load:** 🟢 Easy | 🟡 Medium | 🔴 Hard

---

## 1️⃣ Quick Test Cycle

**When:** You made code changes and want quick feedback
**Time:** ~5 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
rtest                # Run all tests
```

### Visual Flow

```
Code changes → rtest → 2-4 min wait → ✅ Green or ❌ Red
```

### Decision Points

- ✅ **All green** → Continue coding
- ❌ **Some red** → Fix and re-run `rtest`
- 🔴 **Many red** → Run `rload` then `rtest` to reload + test

### Pro Tips

💡 Set a 5-min timer while tests run (use `focus 5`)
💡 Tests too slow? Focus on specific test files
💡 Leave tests running and switch tasks (ADHD-friendly!)

### What Could Go Wrong?

- Tests hang → Ctrl+C to cancel, check for infinite loops
- All tests fail → Run `rpkg` to verify you're in right package

---

## 2️⃣ Load + Test (Atomic)

**When:** Fresh start, want to verify everything loads and works
**Time:** ~5 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
rload && rtest       # Load then test
```

### Visual Flow

```
Start work → rload && rtest → Package loads → Tests run → ✅ or ❌
```

### Why This Works (ADHD-Optimized)

- **Automated sequence** → No decision fatigue
- **Clear output** → Green = go, Red = stop
- **Verifies everything** → Load + tests in one go

### When to Use

- 🌅 **Morning start** → Verify yesterday's work still works
- 🔄 **After git pull** → Check if team changes broke anything
- 🧹 **After cleanup** → Confirm nothing broke

### Pro Tips

💡 Combine with coffee break - perfect timing!
💡 First command of the day ritual
💡 Bookmark this as your "good morning" command

---

## 3️⃣ Document + Test

**When:** You changed function documentation (roxygen comments)
**Time:** ~8 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
rdoc && rtest        # Document then test
```

### Visual Flow

```
Change @param docs → rdoc && rtest → Docs regenerate → Tests run → ✅
```

### What This Does

1. ⏱️ [3-5s] Regenerates .Rd files from roxygen
2. ⏱️ [3-5s] Updates NAMESPACE exports
3. ⏱️ [2-4min] Runs all tests

### Common Scenario

```
You: Added new function parameter
You: Updated @param documentation
Run: rdoc && rtest
Result: Documentation updated + tests verify it works
```

### Pro Tips

💡 Always run after changing ANY roxygen comment
💡 Catches missing @export tags early
💡 Faster than full `rcheck`

### Safety Checks

- 🟢 Safe - only regenerates docs
- Auto-backs up NAMESPACE (devtools handles this)

---

## 4️⃣ Full Check (Before Commit)

**When:** Ready to commit, need to verify everything is perfect
**Time:** ~60 minutes | **Load:** 🟡 Medium | **Safety:** 🟢 Safe

### Commands

```bash
rcycle               # Full cycle: doc → test → check
# OR (step by step)
rdoc && rtest && rcheck
```

### Visual Flow

```
Ready to commit → rcycle → 60 min wait → ✅ 0 errors/warnings/notes
```

### What This Does

1. ⏱️ [5s] Documents package
2. ⏱️ [2-4min] Runs tests
3. ⏱️ [30-60min] Full R CMD check

### ADHD Strategy for Long Wait

- ⏰ **Set timer** → `focus 60` for focus timer
- 🎯 **Switch context** → Work on different package
- ☕ **Take break** → Perfect time for lunch/walk
- 📧 **Other tasks** → Email, admin work

### Decision Points

- ✅ **0 errors, 0 warnings, 0 notes** → COMMIT! 🎉
- ⚠️ **Warnings/notes** → Investigate (might be OK)
- ❌ **Errors** → Fix, run `rcheck` again

### Pro Tips

💡 Run this before ANY git commit
💡 Use `rcheckfast` for quicker check (skips examples/vignettes)
💡 NEVER commit with errors

### What Could Go Wrong?

- Check fails → Read error messages carefully
- Takes forever → Normal! R CMD check is thorough
- Interrupted → Just re-run to continue

---

## 5️⃣ Quick Commit Workflow

**When:** Tests pass, ready to save work to git
**Time:** ~3 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
# Option 1: Quick (if already checked)
git add . && git commit -m "message"

# Option 2: Safe (docs + tests + commit)
rdoc && rtest && git add . && git commit -m "message"

# Option 3: Ultra-safe (full check + commit)
rdoc && rtest && rcheck && git add . && git commit -m "message"
```

### Visual Flow

```
Code ready → git commit → Done in 30s
```

### Commit Message Templates

```bash
# Feature
git commit -m "feat: add sensitivity analysis function"

# Bug fix
git commit -m "fix: handle NA values in mediation estimate"

# Documentation
git commit -m "docs: update README with new examples"

# Tests
git commit -m "test: add tests for interaction effects"

# Refactor
git commit -m "refactor: simplify bootstrap algorithm"
```

### Decision Tree

```
Did you run rcheck?
├─ Yes → git add . && git commit -m "message"
├─ No → rdoc && rtest then commit (safer)
└─ Not sure → Full check first (safest)
```

### Pro Tips

💡 Commit often (every 30-60 min of work)
💡 Small commits = easier to undo
💡 Use clear messages (future you will thank you!)

### Safety Checks

- Always run tests before committing
- Can undo with `git reset HEAD~1` if needed

---

## 6️⃣ Fix Failing Tests

**When:** Tests are red, need to debug
**Time:** Varies | **Load:** 🟡 Medium | **Safety:** 🟢 Safe

### Step-by-Step Process

#### Step 1: Identify the Problem (2 min)

```bash
rtest                # Run tests, read error messages
```

Look for:

- Which test file failed? (test-\*.R)
- Which expectation failed? (expect_equal, etc.)
- What was expected vs actual?

#### Step 2: Run Single Test (1 min)

```bash
# Run specific test file in R:
devtools::test_file("tests/testthat/test-myfunction.R")
```

#### Step 3: Interactive Debugging (varies)

```bash
rload                # Load package
# Then in R console:
# debug(myfunction)
# Run test interactively
```

#### Step 4: Fix and Verify (2 min)

```bash
# Fix the code
rtest                # Re-run all tests
```

### Common Test Failures

**1. "Error: object not found"**

- Cause: Function not exported or loaded
- Fix: Add `@export` tag, run `rdoc && rtest`

**2. "Expected X but got Y"**

- Cause: Logic error or outdated test
- Fix: Check function logic or update test

**3. "Test times out"**

- Cause: Infinite loop or very slow code
- Fix: Add timeout or optimize code

### ADHD-Friendly Debug Loop

```
1. Read error (30s)
2. Hypothesize fix (1 min)
3. Make ONE small change
4. Test immediately with `rtest`
5. Repeat until green
```

### Pro Tips

💡 Only fix ONE test at a time
💡 Use `browser()` for interactive debugging
💡 Take breaks if frustrated

---

## 7️⃣ Where Am I? (Context Check)

**When:** Lost context, can't remember what you were doing
**Time:** ~30 seconds | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
pwd                  # Show current directory
rpkg                 # Package info & status
git status           # Check git status
```

### Visual Output

```
rpkg → Shows:
- 📦 R package name + version
- 📊 Package description
- 🔧 Git branch
```

### Quick Recovery Checklist

- [ ] Run `pwd` → See where you are
- [ ] Run `rpkg` → Package information
- [ ] Run `git status` → Check git status
- [ ] Check `.STATUS` file for next action

### Common Scenarios

**"I forgot what I was working on"**

```bash
pwd                  # Current directory
rpkg                 # Package info
cat .STATUS          # Check status file
```

**"I don't remember what this package does"**

```bash
rpkg                 # Package info
cat DESCRIPTION      # Read full description
```

**"Did I make changes?"**

```bash
git status           # Git status
git diff             # See changes
```

### Pro Tips

💡 Start every session with `rpkg`
💡 Keep `.STATUS` file updated
💡 Use `git status` frequently

---

## 8️⃣ Focus Mode (Deep Work)

**When:** Need concentration, minimize distractions
**Time:** Setup < 1 min | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
focus                # Minimize distractions
focus 25             # Focus + 25-min timer (Pomodoro)
unfocus              # Restore notifications
```

### What `focus` Does

1. ✅ Turns off macOS notifications
2. ✅ Closes Slack, Mail, Messages
3. ✅ Starts optional timer
4. ✅ Announces when session ends

### Visual Flow

```
Need focus → focus 25 → Work uninterrupted → Timer alert → Break
```

### Recommended Focus Workflows

**Pomodoro (25 min)**

```bash
f25                  # 25-minute focus timer
# Work for 25 min
# Timer alerts when done
# Take 5-min break
```

**Deep Work (50 min)**

```bash
f50                  # 50-minute deep work timer
# Work for 50 min
# Timer alerts when done
# Take 10-15 min break
```

**Custom Duration**

```bash
focus 90             # Custom 90-minute session
# Work until timer ends
```

### Pro Tips

💡 Use `f25` or `f50` aliases for common durations
💡 Use during `rcheck` 60-min wait
💡 Take regular breaks to maintain focus

### After Focus Session

```bash
# Update status and commit progress
git add . && git commit -m "Progress on X"
```

---

## 9️⃣ Start New Feature

**When:** Beginning new function or feature
**Time:** ~2 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Step-by-Step Checklist

#### [ ] 1. Context Setup (30s)

```bash
pwd                  # Verify location
rpkg                 # Check package info
git status           # Check git status
```

#### [ ] 2. Create Function File (30s)

```bash
# Create R/myfunction.R manually
# OR use usethis:
usethis::use_r("myfunction")
```

#### [ ] 3. Create Test File (30s)

```bash
# Create tests/testthat/test-myfunction.R
# OR use usethis:
usethis::use_test("myfunction")
```

#### [ ] 4. Document Template (30s)

Add roxygen skeleton:

```r
#' Function Title
#'
#' @param x Description
#' @return Description
#' @export
#' @examples
#' myfunction(x = 1)
myfunction <- function(x) {
  # TODO: Implement
}
```

#### [ ] 5. First Test (30s)

```r
test_that("myfunction works", {
  result <- myfunction(x = 1)
  expect_true(!is.null(result))
})
```

#### [ ] 6. Verify Setup

```bash
rload && rtest       # Load + test
# Should load successfully, test might fail (that's OK!)
```

### Quick Start Template

```bash
# Create files, then verify:
rload && rtest
```

### Pro Tips

💡 Start with test first (TDD approach)
💡 Make smallest working version
💡 Commit early: `git commit -m "feat: add myfunction skeleton"`

---

## 🔟 What Did I Break? (Emergency Recovery)

**When:** Something broke and you're not sure what
**Time:** Varies | **Load:** 🔴 Hard | **Safety:** 🟡 Careful

### Emergency Triage (2 min)

#### Step 1: Assess Damage

```bash
pwd                  # Where am I?
git status           # What changed?
rtest                # Do tests pass?
```

#### Step 2: Identify Problem

**Tests failing?**

```bash
rtest                # Run tests
# Read error messages carefully
# Jump to workflow #6 (Fix Failing Tests)
```

**Package won't load?**

```bash
rload                # Try to load
# Read error messages
# Common: syntax error, missing dependency
```

**Git issues?**

```bash
git status           # Git status
git log --oneline -5 # Recent commits
```

### Recovery Options (Choose One)

#### Option A: Recent Changes (Most Common)

```bash
# Undo last commit (keeps changes)
git reset HEAD~1
# Fix the issue
rtest                # Verify tests pass
git add . && git commit -m "fix: ..."
```

#### Option B: Code Error

```bash
# Use editor to fix syntax error
# Then:
rload                # Try loading again
rtest                # Run tests
```

#### Option C: Clean Build (Last Resort)

```bash
# Clean and rebuild
rm -rf man/ NAMESPACE
rdoc && rtest        # Regenerate docs + test
```

### Prevention Checklist

- ✅ Run tests before commits
- ✅ Commit frequently (small changes)
- ✅ Use version control
- ✅ Test after major changes

### Pro Tips

💡 Don't panic - almost everything is reversible
💡 Read error messages slowly (pause before acting)
💡 Ask for help: `cc` (Claude Code) or colleagues

### When to Ask for Help

- 🔴 Spent > 30 min stuck
- 🔴 Don't understand error message
- 🔴 Afraid of making it worse

---

## 🎯 Quick Decision Tree

**Use this when you're not sure what to do:**

```
What do you want to do?

├─ Just made code changes
│  └─ Run: rtest
│
├─ Starting work on package
│  └─ Run: rload && rtest
│
├─ Changed documentation
│  └─ Run: rdoc && rtest
│
├─ Ready to commit
│  ├─ Did full check? → git add . && git commit -m "msg"
│  └─ Not sure → rcheck then commit
│
├─ Tests are failing
│  └─ See workflow #6 (Fix Failing Tests)
│
├─ Don't know where I am
│  └─ Run: rpkg
│
├─ Need to focus
│  └─ Run: f25 or f50
│
├─ Starting new feature
│  └─ See workflow #9 (Start New Feature)
│
└─ Something broke
   └─ See workflow #10 (Emergency Recovery)
```

---

## ⏱️ Time-Based Quick Reference

**"I have 5 minutes"**

- Run `rtest` (quick test)
- Check `rpkg` (context)
- Review `.STATUS` file

**"I have 15 minutes"**

- Run `rload && rtest`
- Fix one failing test
- Quick commit

**"I have 30 minutes"**

- Run `rdoc && rtest`
- Start new feature
- Focus session with `f25`

**"I have 60+ minutes"**

- Run full `rcheck`
- Deep work with `f50` or `focus 90`
- Multiple test-fix cycles

---

## 🧠 ADHD-Specific Tips

### Managing Wait Times

- **Tests running (2-4 min)?** → Perfect for coffee/bathroom
- **R CMD check (60 min)?** → Switch to different task
- **Stuck debugging?** → Take a 5-min break

### Preventing Context Loss

- **Start every session:** Check `rpkg` and `.STATUS`
- **End every session:** Update `.STATUS` file
- **Commit frequently:** Small commits = less to lose

### Reducing Decision Fatigue

- **Use command chains:** `rload && rtest`, `rdoc && rtest`
- **Follow workflows:** Don't invent, follow the guide
- **Set timers:** `f25`, `f50`, or `focus` commands

### Building Habits

- **Morning ritual:** `rpkg → rload && rtest → check output`
- **Before commit:** `rcheck → wait → commit`
- **After break:** `rpkg → review .STATUS → resume`

---

## 🚨 Common Mistakes & Fixes

| Mistake             | Why Bad                | Fix                               |
| ------------------- | ---------------------- | --------------------------------- |
| Skip testing        | Breaks accumulate      | Always run `rtest`                |
| No documentation    | Future you confused    | Run `rdoc && rtest` after changes |
| Large commits       | Hard to debug          | Commit every 30-60 min            |
| Commit with errors  | Broken code in history | Always test first                 |
| Work without breaks | Burnout, mistakes      | Use `f25` or `f50` timers         |
| Ignore .STATUS      | Lose context           | Update `.STATUS` regularly        |

---

## 📚 Integration with Existing Tools

### Connects to .STATUS Files

- Keep `.STATUS` updated with current progress
- Check `.STATUS` at start of each session
- Use for context when switching projects

### Works with Help System

- Forgot command? Check the alias reference card
- Need reminder? Review this quick wins guide
- Full reference → See ALIAS-REFERENCE-CARD.md

### Pairs with Focus Tools

- `f25` / `f50` → Pomodoro/deep work timers
- `focus <min>` → Custom duration focus sessions
- `win` → Log accomplishments

---

## 🎉 Success Patterns

**Morning Start (5 min)**

```bash
rpkg → rload && rtest → Coffee while tests run → Review results → Code
```

**Quick Feature (30 min)**

```bash
f25 → Create files → Code → rdoc && rtest
```

**Pre-Commit (65 min)**

```bash
rcheck → f60 focus session → Switch tasks → Check results → commit
```

**End of Day (5 min)**

```bash
rtest → git commit -m "wip: progress on X" → Update .STATUS for tomorrow
```

---

## 1️⃣1️⃣ Git Feature Branch Workflow (v4.1.0+)

**When:** Working on new features, hotfixes, or any code changes
**Time:** ~2 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
# Start a feature
g feature start auth-improvements

# Work on your feature...
g add . && g commit "Add OAuth2 support"

# Stay synced with dev
g feature sync

# Finish: push + create PR
g feature finish
```

### Visual Flow

```
Start → feature start → code → commit → sync → finish → PR → merge
```

### Quick Reference

| Command                    | What It Does                    |
|----------------------------|---------------------------------|
| `g feature start <name>`   | Create feature branch from dev  |
| `g feature sync`           | Rebase feature onto dev         |
| `g feature list`           | List feature/hotfix branches    |
| `g feature finish`         | Push + create PR to dev         |
| `g promote`                | Create PR: feature → dev        |
| `g release`                | Create PR: dev → main           |
| `g feature prune`          | Delete merged branches          |

### Workflow Guard

The workflow guard blocks direct pushes to protected branches:

```bash
# Blocked ❌
git checkout main && g push   # Direct push to main blocked

# Allowed ✅
g feature start my-fix        # Create feature branch
g push                        # Push feature branch OK
g promote                     # Create PR instead
```

### Pro Tips

💡 Run `g feature sync` daily to avoid merge conflicts
💡 Use `g feature finish` to push + create PR in one step
💡 Clean up with `g feature prune` weekly

---

## 1️⃣2️⃣ Parallel Development with Worktrees (v4.1.0+)

**When:** Need to work on multiple features simultaneously
**Time:** ~1 minute | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands

```bash
# Create worktree for a branch
wt create feature/auth

# List all worktrees
wt list

# Navigate to worktrees folder
wt

# Clean up stale worktrees
wt clean
```

### Visual Flow

```
Main work → wt create feature/b → Parallel work → wt clean
```

### Claude Code + Worktrees

Launch Claude in a dedicated worktree:

```bash
# Launch Claude in worktree (creates if needed)
cc wt feature/auth

# Pick from existing worktrees
cc wt pick

# Worktree + YOLO mode
cc wt yolo feature/risky

# Worktree + Plan mode
cc wt plan feature/complex
```

### Aliases

| Alias  | Expands To     | Description           |
|--------|----------------|-----------------------|
| `ccw`  | `cc wt`        | Worktree + Claude     |
| `ccwy` | `cc wt yolo`   | Worktree + YOLO mode  |
| `ccwp` | `cc wt pick`   | Worktree picker       |

### When to Use Worktrees

- 🔀 **Parallel features** - Work on feature-a while feature-b runs tests
- 👀 **Code review** - Review PR in isolated directory
- 🧪 **Experiments** - Try risky changes without affecting main work
- ⚡ **Quick fixes** - Hotfix while feature work continues

### Pro Tips

💡 Each worktree is completely isolated - no stashing needed
💡 Worktrees persist after Claude exits
💡 Use `wt clean` regularly to remove stale worktrees

---

## 📖 Related Documentation

- **[Git Feature Workflow Tutorial](../tutorials/08-git-feature-workflow.md)** - Full tutorial
- **[Worktrees Tutorial](../tutorials/09-worktrees.md)** - Parallel development guide
- **[Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md)** - All dispatchers
- **ALIAS-REFERENCE-CARD.md** - All core aliases
- **WORKFLOW-TUTORIAL.md** - Complete tutorial
- **PROJECT-HUB.md** - Strategic overview

---

**Last Updated:** 2025-12-30
**Version:** 2.1 (Added Git Feature Workflow and Worktrees)
**Time to Master:** Practice each workflow 3-5 times

💡 **Pro Tip:** Bookmark this guide for quick reference!
