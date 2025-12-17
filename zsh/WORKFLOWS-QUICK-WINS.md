# 🧠 ADHD-Friendly Workflows - Quick Wins Guide

> **Focus:** Top 10 highest-impact workflows for daily R package development

**Read Time:** 5 minutes | **Apply Time:** Immediate
**Last Updated:** 2025-12-13

---

## 📋 Table of Contents

| # | Workflow | Time | Load | Use When |
|---|----------|------|------|----------|
| 1 | [Quick Test](#1-quick-test-cycle) | 5 min | 🟢 | Made code changes |
| 2 | [Load + Test](#2-load--test-atomic) | 5 min | 🟢 | Fresh start on package |
| 3 | [Doc + Test](#3-document--test) | 8 min | 🟢 | Changed function docs |
| 4 | [Full Check](#4-full-check-before-commit) | 60 min | 🟡 | Before git commit |
| 5 | [Quick Commit](#5-quick-commit-workflow) | 3 min | 🟢 | Ready to save work |
| 6 | [Fix Failing Tests](#6-fix-failing-tests) | varies | 🟡 | Tests are red |
| 7 | [Context Check](#7-where-am-i) | 30 sec | 🟢 | Lost context |
| 8 | [Focus Mode](#8-focus-mode-deep-work) | setup | 🟢 | Need concentration |
| 9 | [Start Feature](#9-start-new-feature) | 2 min | 🟢 | Beginning new work |
| 10 | [Emergency Recovery](#10-what-did-i-break) | varies | 🔴 | Something broke |

**Cognitive Load:** 🟢 Easy | 🟡 Medium | 🔴 Hard

---

## 1️⃣ Quick Test Cycle

**When:** You made code changes and want quick feedback
**Time:** ~5 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands
```bash
t                    # Test (single letter - fastest!)
# OR
rtest                # Test (explicit)
```

### Visual Flow
```
Code changes → t → 2-4 min wait → ✅ Green or ❌ Red
```

### Decision Points
- ✅ **All green** → Continue coding
- ❌ **Some red** → Fix and re-run `t`
- 🔴 **Many red** → Run `lt` to reload + test

### Pro Tips
💡 Set a 5-min timer while tests run (use `worktimer 5`)
💡 Tests too slow? Use `rtest1 "pattern"` for specific tests
💡 Leave tests running and switch tasks (ADHD-friendly!)

### What Could Go Wrong?
- Tests hang → Ctrl+C to cancel, check for infinite loops
- All tests fail → Run `here` to verify you're in right directory

---

## 2️⃣ Load + Test (Atomic)

**When:** Fresh start, want to verify everything loads and works
**Time:** ~5 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands
```bash
lt                   # Load then test (atomic pair - ultra-fast!)
# OR
rload && rtest       # Explicit version
```

### Visual Flow
```
Start work → lt → Package loads → Tests run → ✅ or ❌
```

### Why This Works (ADHD-Optimized)
- **Single command** → Less to remember
- **Automated sequence** → No decision fatigue
- **Clear output** → Green = go, Red = stop

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
dt                   # Doc then test (atomic pair)
# OR
rdoc && rtest        # Explicit version
```

### Visual Flow
```
Change @param docs → dt → Docs regenerate → Tests run → ✅
```

### What This Does
1. ⏱️ [3-5s] Regenerates .Rd files from roxygen
2. ⏱️ [3-5s] Updates NAMESPACE exports
3. ⏱️ [2-4min] Runs all tests

### Common Scenario
```
You: Added new function parameter
You: Updated @param documentation
Run: dt
Result: Documentation updated + tests verify it works
```

### Pro Tips
💡 Always run after changing ANY roxygen comment
💡 Catches missing @export tags early
💡 Faster than full `rcycle`

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
- ⏰ **Set timer** → `worktimer 60 "R CMD check"`
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
- Interrupted → Just re-run `rcheck` to continue

---

## 5️⃣ Quick Commit Workflow

**When:** Tests pass, ready to save work to git
**Time:** ~3 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands
```bash
# Option 1: Quick (if already checked)
qcommit "message"

# Option 2: Safe (docs + tests + commit)
rpkgcommit "message"

# Option 3: Ultra-safe (full check + commit)
rcycle && qcommit "message"
```

### Visual Flow
```
Code ready → qcommit "msg" → Git commit → Done in 30s
```

### Commit Message Templates
```bash
# Feature
qcommit "feat: add sensitivity analysis function"

# Bug fix
qcommit "fix: handle NA values in mediation estimate"

# Documentation
qcommit "docs: update README with new examples"

# Tests
qcommit "test: add tests for interaction effects"

# Refactor
qcommit "refactor: simplify bootstrap algorithm"
```

### Decision Tree
```
Did you run rcycle? 
├─ Yes → qcommit "message"
├─ No → rpkgcommit "message" (safer)
└─ Not sure → rcycle && qcommit "message" (safest)
```

### Pro Tips
💡 Commit often (every 30-60 min of work)
💡 Small commits = easier to undo
💡 Use clear messages (future you will thank you!)

### Safety Checks
- `rpkgcommit` runs docs + tests first
- Can always undo with `gundo`

---

## 6️⃣ Fix Failing Tests

**When:** Tests are red, need to debug
**Time:** Varies | **Load:** 🟡 Medium | **Safety:** 🟢 Safe

### Step-by-Step Process

#### Step 1: Identify the Problem (2 min)
```bash
t                    # Run tests, read error messages
```

Look for:
- Which test file failed? (test-*.R)
- Which expectation failed? (expect_equal, etc.)
- What was expected vs actual?

#### Step 2: Run Single Test (1 min)
```bash
rtestfile tests/testthat/test-myfunction.R
# OR
rtest1 "myfunction"     # Run tests matching pattern
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
t                    # Re-run all tests
```

### Common Test Failures

**1. "Error: object not found"**
- Cause: Function not exported or loaded
- Fix: Add `@export` tag, run `dt`

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
4. Test immediately with `t`
5. Repeat until green
```

### Pro Tips
💡 Only fix ONE test at a time
💡 Use `browser()` for interactive debugging
💡 Take breaks if frustrated (use `quickbreak 5`)

---

## 7️⃣ Where Am I? (Context Check)

**When:** Lost context, can't remember what you were doing
**Time:** ~30 seconds | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Commands
```bash
here                 # Show full context
next                 # Show next action from .STATUS
progress_check       # Show progress bars
```

### Visual Output
```
here → Shows:
- 📍 Current directory
- 📦 R package name + version
- 📊 .STATUS file excerpt
- 🔧 Git branch + status
```

### Quick Recovery Checklist
- [ ] Run `here` → See where you are
- [ ] Run `next` → See what to do next
- [ ] Run `gs` → Check git status
- [ ] Run `ah r` → Remember R package aliases

### Common Scenarios

**"I forgot what I was working on"**
```bash
here                 # Full context
next                 # Next action
```

**"I don't remember what this package does"**
```bash
rpkg                 # Package info
peekdesc             # Read DESCRIPTION
```

**"Did I make changes?"**
```bash
gs                   # Git status
smartgit             # Full git overview
```

### Pro Tips
💡 Start every session with `here`
💡 Make it a habit: open terminal → `here`
💡 Add to .STATUS file for persistent reminders

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
focus 25 "implement new function"
# Work for 25 min
# Timer alerts when done
quickbreak 5         # 5-min break
```

**Deep Work (90 min)**
```bash
focus 90 "write tests for mediation module"
# Work for 90 min
# Timer alerts when done
quickbreak 15        # 15-min break
```

**Quick Focus (no timer)**
```bash
focus                # Just minimize distractions
# Work until done
unfocus              # Restore when finished
```

### Pro Tips
💡 Combine with `startwork <project>` for full setup
💡 Use during `rcycle` 60-min wait
💡 Pair with `worktimer` for accountability

### After Focus Session
```bash
unfocus              # Restore notifications
endwork              # Update .STATUS
qcommit "msg"        # Commit progress
```

---

## 9️⃣ Start New Feature

**When:** Beginning new function or feature
**Time:** ~2 minutes | **Load:** 🟢 Easy | **Safety:** 🟢 Safe

### Step-by-Step Checklist

#### [ ] 1. Context Setup (30s)
```bash
here                 # Verify location
gs                   # Check git status
```

#### [ ] 2. Create Function File (30s)
```bash
rnewfun "myfunction"     # Creates R/myfunction.R
# Opens in editor automatically
```

#### [ ] 3. Create Test File (30s)
```bash
rnewtest "myfunction"    # Creates tests/testthat/test-myfunction.R
# Opens in editor automatically
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
lt                   # Load + test
# Should load successfully, test might fail (that's OK!)
```

### Quick Start Template
```bash
# All in one flow:
here && rnewfun "myfunction" && rnewtest "myfunction" && lt
```

### Pro Tips
💡 Start with test first (TDD approach)
💡 Make smallest working version
💡 Commit early: `qcommit "feat: add myfunction skeleton"`

---

## 🔟 What Did I Break? (Emergency Recovery)

**When:** Something broke and you're not sure what
**Time:** Varies | **Load:** 🔴 Hard | **Safety:** 🟡 Careful

### Emergency Triage (2 min)

#### Step 1: Assess Damage
```bash
here                 # Where am I?
gs                   # What changed?
t                    # Do tests pass?
```

#### Step 2: Identify Problem

**Tests failing?**
```bash
t                    # Run tests
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
gs                   # Git status
glog                 # Recent commits
```

### Recovery Options (Choose One)

#### Option A: Recent Changes (Most Common)
```bash
# Undo last change
gundo                # Undo last commit (keeps changes)
# Fix the issue
t                    # Verify tests pass
qcommit "fix: ..."   # Re-commit
```

#### Option B: Code Error
```bash
# Use editor to fix syntax error
# Then:
rload                # Try loading again
t                    # Run tests
```

#### Option C: Nuclear Option (Last Resort)
```bash
# Restore from backup
rpkgdeep             # Clean generated files (DESTRUCTIVE!)
dt                   # Regenerate docs + test
```

### Prevention Checklist
- ✅ Run `rcycle` before commits
- ✅ Commit frequently (small changes)
- ✅ Keep backups of .zshrc (done automatically)
- ✅ Use git (easy undo with `gundo`)

### Pro Tips
💡 Don't panic - almost everything is reversible
💡 Read error messages slowly (ADHD: pause before acting)
💡 Ask for help: `ccc` (Claude) or colleagues

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
│  └─ Run: t (test)
│
├─ Starting work on package
│  └─ Run: lt (load + test)
│
├─ Changed documentation
│  └─ Run: dt (doc + test)
│
├─ Ready to commit
│  ├─ Did full check? → qcommit "msg"
│  └─ Not sure → rcycle then qcommit "msg"
│
├─ Tests are failing
│  └─ See workflow #6 (Fix Failing Tests)
│
├─ Don't know where I am
│  └─ Run: here
│
├─ Need to focus
│  └─ Run: focus 25
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
- Run `t` (quick test)
- Check `here` (context)
- Review `next` (what's next)

**"I have 15 minutes"**
- Run `lt` (load + test)
- Fix one failing test
- Quick commit with `qcommit`

**"I have 30 minutes"**
- Run `dt` (doc + test)
- Start new feature
- Focus session with `focus 25`

**"I have 60+ minutes"**
- Run `rcycle` (full check)
- Deep work with `focus 90`
- Multiple test-fix cycles

---

## 🧠 ADHD-Specific Tips

### Managing Wait Times
- **Tests running (2-4 min)?** → Perfect for coffee/bathroom
- **R CMD check (60 min)?** → Switch to different task
- **Stuck debugging?** → Take 5-min break with `quickbreak 5`

### Preventing Context Loss
- **Start every session:** `here` then `next`
- **End every session:** `endwork` updates .STATUS
- **Commit frequently:** Small commits = less to lose

### Reducing Decision Fatigue
- **Use atomic pairs:** `lt`, `dt` (one command, no thinking)
- **Follow workflows:** Don't invent, follow the guide
- **Set timers:** `worktimer` and `focus` do it for you

### Building Habits
- **Morning ritual:** `here → lt → check output`
- **Before commit:** `rcycle → wait → qcommit`
- **After break:** `here → next → resume`

---

## 🚨 Common Mistakes & Fixes

| Mistake | Why Bad | Fix |
|---------|---------|-----|
| Skip testing | Breaks accumulate | Always run `t` |
| No documentation | Future you confused | Run `dt` after changes |
| Large commits | Hard to debug | Commit every 30-60 min |
| Commit with errors | Broken code in history | Always `rcycle` first |
| Work without breaks | Burnout, mistakes | Use `focus` + `quickbreak` |
| Ignore .STATUS | Lose context | Run `next` regularly |

---

## 📚 Integration with Existing Tools

### Connects to .STATUS Files
- `next` reads your .STATUS → shows next action
- `endwork` prompts to update .STATUS
- `progress_check` shows completion bars

### Works with Help System
- Forgot command? → `ah r` (R package help)
- Need reminder? → `ah workflow` (workflow functions)
- Full reference → `cat ALIAS-REFERENCE-CARD.md`

### Pairs with Focus Tools
- `focus` → minimize distractions
- `worktimer` → accountability
- `quickbreak` → structured breaks

---

## 🎉 Success Patterns

**Morning Start (5 min)**
```bash
here → lt → Coffee while tests run → Review results → Code
```

**Quick Feature (30 min)**
```bash
focus 25 "add function" → rnewfun → rnewtest → Code → dt → unfocus
```

**Pre-Commit (65 min)**
```bash
rcycle → worktimer 60 → Switch tasks → Check results → qcommit
```

**End of Day (5 min)**
```bash
t → qcommit "wip: progress on X" → endwork → next (for tomorrow)
```

---

## 📖 Related Documentation

- **ALIAS-REFERENCE-CARD.md** - All 120+ aliases
- **PROJECT-HUB.md** - Strategic overview
- **functions.zsh** - Function implementations
- **Apple Note** - Mobile quick reference

---

**Last Updated:** 2025-12-13
**Version:** 1.0 (Quick Wins)
**Time to Master:** Practice each workflow 3-5 times

💡 **Pro Tip:** Print this guide or keep it open in a second monitor!
