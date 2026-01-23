# Phase 1 Manual Testing Guide

**Version:** v4.9.0 Phase 1
**Date:** 2026-01-05
**Time Required:** ~10 minutes

## Quick Setup

1. **Reload your shell** to get the latest flow-cli:

   ```bash
   source ~/.zshrc
   # OR if using antidote
   antidote update
   source ~/.zshrc
   ```

2. **Verify you have the latest version:**
   ```bash
   flow --version
   # Should show: flow-cli v4.7.0 or higher
   ```

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
