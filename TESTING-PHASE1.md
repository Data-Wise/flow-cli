# Phase 1 Manual Testing Guide

**Version:** v4.9.0 Phase 1 + Critical Bug Fixes
**Date:** 2026-01-05 (Updated)
**Time Required:** ~15 minutes
**Bug Fixes:** PRs #175, #176, #177

## ⚠️ IMPORTANT: Recent Bug Fixes

**Three critical bugs were fixed today that affect Phase 1 testing:**

1. **PR #175**: Missing `_flow_log_muted` function
2. **PR #176**: ZSH builtin 'r' shadowing R dispatcher
3. **PR #177**: OMZ aliases breaking command substitutions (grep, cut, sort, bat)

These fixes are essential for Phase 1 to work correctly, especially if you use Oh-My-Zsh plugins.

---

## Quick Setup

1. **Reload your shell** to get the latest fixes:

   ```bash
   source ~/.zshrc
   # OR if using antidote
   antidote update
   source ~/.zshrc
   ```

2. **Verify you have the latest version:**

   ```bash
   flow --version
   # Should show: flow-cli v4.8.1 or higher
   ```

3. **Verify bug fixes are applied:**
   ```bash
   cd ~/projects/dev-tools/flow-cli
   git log --oneline -3
   # Should show:
   # 7fa4879 fix: bypass OMZ aliases in command substitutions (#177)
   # 770015c fix: disable ZSH builtin 'r' to allow R dispatcher to work (#176)
   # 66e712a fix: add missing _flow_log_muted function (#175)
   ```

---

## 🔧 Bug Fix Verification (NEW)

**Test these FIRST to ensure the critical bugs are fixed:**

### Bug Fix 1: R Dispatcher Works (PR #176)

**Issue:** ZSH builtin `r` command was shadowing the R package dispatcher.

**Test:**

```bash
r help
```

**✅ Should display:** R dispatcher help (NOT "event not found: help" error)

**❌ If you see error:** The builtin 'r' is still active. Run `disable r` manually.

---

### Bug Fix 2: Dashboard & Commands Work (PR #177)

**Issue:** OMZ aliases (grep, cut, sort, bat) were breaking command substitutions.

**Test 1: Dashboard displays without errors**

```bash
dash
```

**✅ Should display:** Project dashboard
**❌ Should NOT show:** "command not found: grep", "command not found: cut"

**Test 2: Reference card displays without errors**

```bash
ref
```

**✅ Should display:** Command quick reference
**❌ Should NOT show:** "command not found: bat"

**Test 3: Terminal manager works**

```bash
tm help
```

**✅ Should display:** Terminal manager help
**❌ Should NOT show:** "command not found: sort", "command not found: atuin"

**Test 4: Quarto dispatcher works**

```bash
qu help
```

**✅ Should display:** Quarto help
**❌ Should NOT show:** "command not found" errors

---

### Bug Fix 3: Work Command (PR #175)

**Issue:** Missing `_flow_log_muted` function caused errors in work command.

**Test:**

```bash
work flow-cli
```

**✅ Should display:** Welcome message (first time) or session start
**❌ Should NOT show:** "command not found: \_flow_log_muted"

---

## 🎯 If Bug Fixes Don't Work

If you see any of the errors above after reloading:

1. **Verify you're on main branch with latest commits:**

   ```bash
   cd ~/projects/dev-tools/flow-cli
   git status
   git pull origin main
   ```

2. **Reload flow-cli directly:**

   ```bash
   source ~/projects/dev-tools/flow-cli/flow.plugin.zsh
   ```

3. **Try the commands again** - they should work now

4. **If still broken:** Report the issue with exact error message

---

## Feature 1: First-Run Welcome Message ⭐

**What it does:** Shows a friendly welcome on first use with quick start guide.

### Test Steps

1. **Remove the welcome marker** (simulates first-time use):

   ```bash
   rm -f ~/.config/flow-cli/.welcomed
   ```

2. **Run work command:**

   ```bash
   work flow-cli
   ```

3. **✅ You should see:**

   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   👋 Welcome to flow-cli!
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Quick Start:
     work <project>  Start working on a project
     dash            Project dashboard
     pick            Pick project with fzf
     win "text"      Log an accomplishment
     finish          End session

   Get Help:
     flow help       Show all commands
     <cmd> help      Command-specific help

   Tip: Run flow doctor to check your installation
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

4. **Run work again:**

   ```bash
   work flow-cli
   ```

5. **✅ You should NOT see the welcome message** (shows only once)

---

## Feature 2: "See Also" Cross-References 🔗

**What it does:** Helps you discover related commands via "See also" sections.

### Test Steps

**Test 1: Git dispatcher (g)**

```bash
g help
```

**✅ Look for at bottom:**

```
📚 See also:
  wt - Manage git worktrees
  cc wt - Launch Claude in worktree
  flow sync - Sync project state & git
```

**Test 2: Claude Code dispatcher (cc)**

```bash
cc help
```

**✅ Look for:**

```
📚 See also:
  pick - Project picker with Claude sessions
  work - Start working on a project
  wt - Manage git worktrees
  g - Git commands
```

**Test 3: R dispatcher**

```bash
r help
```

**✅ Look for:**

```
📚 See also:
  qu - Quarto publishing (integrates with R)
  cc rpkg - Launch Claude with R package context
  flow doctor - Check R development tools
```

**Test 4: Quarto dispatcher**

```bash
qu help
```

**✅ Look for:**

```
📚 See also:
  r - R package development
  cc - Launch Claude for Quarto projects
  g - Git commands for versioning
```

**Test 5: Terminal manager dispatcher**

```bash
tm help
```

**✅ Look for:**

```
📚 See also:
  work - Start working (auto-sets terminal context)
  pick - Project picker
  cc - Launch Claude Code
```

---

## Feature 3: Random Tips in Dashboard 💡

**What it does:** Shows helpful tips ~20% of the time when you view the dashboard.

### Test Steps

1. **Run dashboard multiple times** (tips appear randomly ~20% of time):

   ```bash
   dash
   dash
   dash
   dash
   dash
   ```

2. **✅ Watch for tips at the bottom** (you should see 1-2 tips in 5 runs):

   ```
   💡 Tip: Use pick --recent to see projects with Claude sessions
   ```

   or

   ```
   💡 Tip: Try cc yolo pick for quick Claude launch without prompts
   ```

3. **Tips rotate** - run dash 10-20 times to see different tips:
   - "Use pick --recent to see projects with Claude sessions"
   - "Try cc yolo pick for quick Claude launch without prompts"
   - "Run flow doctor --fix to install missing tools interactively"
   - "Use wt create <branch> for clean git worktrees"
   - "Log wins with win \"text\" - they auto-categorize!"
   - "Set daily goals: flow goal set 3 for motivation"
   - "Try dash -i for interactive project picker"
   - "Use g feature start <name> for clean feature branches"
   - "Run yay --week to see your weekly accomplishments graph"
   - "Quick commit: g commit \"msg\" combines add & commit"
   - "Check streaks with flow goal - consistency builds momentum!"
   - "Use hop <project> for instant tmux session switching"

---

## Feature 4: Quick Reference Card 📚

**What it does:** Instant command lookup via `ref` command.

### Test Steps

**Test 1: Basic usage (shows command reference by default)**

```bash
ref
```

**✅ Should display:** Command Quick Reference with all commands

**Test 2: Workflow reference**

```bash
ref workflow
```

**✅ Should display:** Workflow Quick Reference

**Test 3: Aliases work**

```bash
ref cmd        # Same as 'ref'
ref work       # Same as 'ref workflow'
ref c          # Same as 'ref'
ref w          # Same as 'ref workflow'
```

**Test 4: Help works**

```bash
ref help
```

**✅ Should show:**

```
ref - Quick Reference Card

Usage:
  ref [type]         Show quick reference
  ref command        Show command reference (default)
  ref workflow       Show workflow reference

EXAMPLES:
  $ ref              # Command quick reference
  $ ref workflow     # Workflow patterns
  $ ref cmd          # Same as 'ref'
  $ ref work         # Same as 'ref workflow'

See also:
  flow help - Detailed help system
  <cmd> help - Command-specific help
```

---

## Feature 5: EXAMPLES Sections in Help 📖

**What it does:** Real-world usage examples in dispatcher help.

### Test Steps

**Test 1: R dispatcher examples**

```bash
r help
```

**✅ Look for EXAMPLES section:**

```
EXAMPLES:
  $ r test              # Run all package tests
  $ r doc               # Update documentation
  $ r cycle             # Full dev cycle: doc → test → check
  $ r quick             # Quick test: load → test
  $ r cran              # CRAN submission check
```

**Test 2: Quarto dispatcher examples**

```bash
qu help
```

**✅ Look for:**

```
EXAMPLES:
  $ qu                  # Render + preview in browser
  $ qu r                # Just render (no preview)
  $ qu p                # Just preview (assumes rendered)
  $ qu render article.qmd    # Render specific file
  $ qu preview --port 8080   # Custom preview port
```

**Test 3: Terminal manager examples**

```bash
tm help
```

**✅ Look for:**

```
EXAMPLES:
  $ tm title "Feature XYZ"    # Set window title
  $ tm profile dev            # Switch to dev profile (iTerm2)
  $ tm which                  # Detect current terminal
  $ tm ghost theme catppuccin # Set Ghostty theme
  $ tm switch                 # Apply project terminal context
```

---

## ✅ Checklist

Complete this checklist as you test:

### Bug Fixes (Test FIRST)

- [ ] **Bug Fix #176:** `r help` works (no "event not found" error)
- [ ] **Bug Fix #177:** `dash` works (no "command not found: grep/cut" errors)
- [ ] **Bug Fix #177:** `ref` works (no "command not found: bat" error)
- [ ] **Bug Fix #177:** `tm help` works (no "command not found: sort" error)
- [ ] **Bug Fix #177:** `qu help` works (no errors)
- [ ] **Bug Fix #175:** `work flow-cli` works (no "\_flow_log_muted" error)

### Phase 1 Features

- [ ] **Feature 1:** Welcome message shown on first work command
- [ ] **Feature 1:** Welcome message NOT shown on second work command
- [ ] **Feature 2:** `g help` has "See also" section
- [ ] **Feature 2:** `cc help` has "See also" section
- [ ] **Feature 2:** `r help` has "See also" section
- [ ] **Feature 2:** `qu help` has "See also" section
- [ ] **Feature 2:** `tm help` has "See also" section
- [ ] **Feature 3:** Random tips appear in dashboard (~20% frequency)
- [ ] **Feature 3:** Tips are helpful and mention key features
- [ ] **Feature 4:** `ref` command shows command reference
- [ ] **Feature 4:** `ref workflow` shows workflow reference
- [ ] **Feature 4:** `ref help` shows help properly
- [ ] **Feature 5:** `r help` has EXAMPLES section
- [ ] **Feature 5:** `qu help` has EXAMPLES section
- [ ] **Feature 5:** `tm help` has EXAMPLES section

---

## 🐛 Issues Found?

If you find any issues:

1. **Check the automated tests first:**

   ```bash
   cd ~/projects/dev-tools/flow-cli
   zsh tests/test-phase1-features.zsh
   ```

2. **Report issues:**
   - Create GitHub issue: https://github.com/Data-Wise/flow-cli/issues
   - Or just tell me what's not working!

---

## 🎉 Success Criteria

**Phase 1 is working correctly if:**

### Bug Fixes

- ✅ No "command not found" errors for grep, cut, sort, bat, atuin
- ✅ R dispatcher (`r help`) works without errors
- ✅ Dashboard (`dash`) displays without errors
- ✅ Reference card (`ref`) displays without errors
- ✅ All dispatcher helps work (r, qu, tm, g, cc)
- ✅ Work command (`work`) doesn't show "\_flow_log_muted" error

### Phase 1 Features

- ✅ Welcome message shows exactly once
- ✅ All 5 dispatcher helps have "See also" sections
- ✅ Dashboard shows tips occasionally (~1-2 times per 5 runs)
- ✅ `ref` command displays both command and workflow references
- ✅ All 3 dispatcher helps have EXAMPLES sections
- ✅ Everything looks clean and helpful

---

## Next Steps

After testing Phase 1:

- **If all good:** Ready for Phase 2 (Interactive Help Focus) or production use
- **If issues found:** Create GitHub issues or report directly
- **Want more features:** Check IMPLEMENTATION-PLAN-v4.9.0.md for Phase 2 & 3 roadmap

---

**Happy testing! 🚀**
