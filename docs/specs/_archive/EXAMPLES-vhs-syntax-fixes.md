# VHS Syntax Fix Examples

**Purpose:** Visual guide showing exact changes needed for syntax error fixes
**Related:** SPEC-teaching-gifs-enhancement-2026-01-29.md
**Created:** 2026-01-29

---

## Overview

This document shows real examples from problematic VHS tapes and their corrections.

**Problem:** Using `Type "# Comment"` causes ZSH to interpret `#` as a command, generating errors in GIFs.

**Solution:** Use `Type "echo 'Comment'"` instead, which properly displays text in ZSH.

---

## Example 1: teaching-git-workflow.tape

**Location:** `docs/demos/teaching-git-workflow.tape`
**Problematic Lines:** 60+ lines
**File Size:** 2.0MB GIF

### Before (WRONG)

```bash
# Line 14
Type "Teaching + Git Workflow Demo (v5.12.0)" Sleep 1s Enter

# Line 18
Type "# Phase 1: Smart Post-Generation" Enter

# Line 24-28
Type "# Choose an option:" Sleep 500ms Enter
Type "#   1) Review in editor, then commit" Sleep 300ms Enter
Type "#   2) Commit now with auto-generated message" Sleep 300ms Enter
Type "#   3) Skip commit (do it manually later)" Sleep 300ms Enter

# Line 38
Type "# Phase 2: Git Deployment" Enter

# Line 44-48
Type "# Pre-flight checks:" Sleep 500ms Enter
Type "#   ✓ On draft branch" Sleep 300ms Enter
Type "#   ✓ No uncommitted changes" Sleep 300ms Enter
Type "#   ✓ No unpushed commits" Sleep 300ms Enter
Type "#   ✓ No production conflicts" Sleep 300ms Enter

# Line 50
Type "# Creating PR: draft → main" Sleep 500ms Enter

# Line 55
Type "# Phase 3: Git-Aware Status" Enter

# Line 61-66
Type "# Course: STAT 545 (Fall 2024)" Sleep 300ms Enter
Type "# Week: 8 of 15" Sleep 300ms Enter
Type "#" Sleep 100ms Enter
Type "# 📝 Uncommitted Teaching Files:" Sleep 300ms Enter
Type "#   • exams/exam02.qmd" Sleep 300ms Enter
Type "#   • slides/week08.qmd" Sleep 300ms Enter

# Line 70
Type "# Phase 4: Teaching Mode (Auto-Commit)" Enter

# Line 73
Type "# Edit config: workflow.teaching_mode: true" Enter

# Line 77-78
Type "# 🎓 Teaching Mode: Auto-committing..." Sleep 300ms Enter
Type "# ✓ Committed: teach: add quiz for Chapter 5" Sleep 300ms Enter

# Line 83
Type "# Phase 5: Git Initialization" Enter

# Lines 89-95
Type "# → Initializing git repository" Sleep 300ms Enter
Type "# → Copying .gitignore template (95 lines)" Sleep 300ms Enter
Type "# → Creating draft branch" Sleep 300ms Enter
Type "# → Creating main branch" Sleep 300ms Enter
Type "# → Making initial commit" Sleep 300ms Enter
Type "# → GitHub repo creation? (y/N)" Sleep 500ms Enter

# Line 100
Type "# ✅ All 5 Phases Complete!" Enter
```

### After (CORRECT)

```bash
# Line 14
Type "echo 'Teaching + Git Workflow Demo (v5.12.0)'" Sleep 1s Enter

# Line 18
Type "echo 'Phase 1: Smart Post-Generation'" Enter

# Line 24-28
Type "echo 'Choose an option:'" Sleep 500ms Enter
Type "echo '  1) Review in editor, then commit'" Sleep 300ms Enter
Type "echo '  2) Commit now with auto-generated message'" Sleep 300ms Enter
Type "echo '  3) Skip commit (do it manually later)'" Sleep 300ms Enter

# Line 38
Type "echo 'Phase 2: Git Deployment'" Enter

# Line 44-48
Type "echo 'Pre-flight checks:'" Sleep 500ms Enter
Type "echo '  ✓ On draft branch'" Sleep 300ms Enter
Type "echo '  ✓ No uncommitted changes'" Sleep 300ms Enter
Type "echo '  ✓ No unpushed commits'" Sleep 300ms Enter
Type "echo '  ✓ No production conflicts'" Sleep 300ms Enter

# Line 50
Type "echo 'Creating PR: draft → main'" Sleep 500ms Enter

# Line 55
Type "echo 'Phase 3: Git-Aware Status'" Enter

# Line 61-66
Type "echo 'Course: STAT 545 (Fall 2024)'" Sleep 300ms Enter
Type "echo 'Week: 8 of 15'" Sleep 300ms Enter
Type "echo ''" Sleep 100ms Enter
Type "echo '📝 Uncommitted Teaching Files:'" Sleep 300ms Enter
Type "echo '  • exams/exam02.qmd'" Sleep 300ms Enter
Type "echo '  • slides/week08.qmd'" Sleep 300ms Enter

# Line 70
Type "echo 'Phase 4: Teaching Mode (Auto-Commit)'" Enter

# Line 73
Type "echo 'Edit config: workflow.teaching_mode: true'" Enter

# Line 77-78
Type "echo '🎓 Teaching Mode: Auto-committing...'" Sleep 300ms Enter
Type "echo '✓ Committed: teach: add quiz for Chapter 5'" Sleep 300ms Enter

# Line 83
Type "echo 'Phase 5: Git Initialization'" Enter

# Lines 89-95
Type "echo '→ Initializing git repository'" Sleep 300ms Enter
Type "echo '→ Copying .gitignore template (95 lines)'" Sleep 300ms Enter
Type "echo '→ Creating draft branch'" Sleep 300ms Enter
Type "echo '→ Creating main branch'" Sleep 300ms Enter
Type "echo '→ Making initial commit'" Sleep 300ms Enter
Type "echo '→ GitHub repo creation? (y/N)'" Sleep 500ms Enter

# Line 100
Type "echo '✅ All 5 Phases Complete!'" Enter
```

### Key Changes
- Removed `#` prefix (causes ZSH to parse as comment)
- Wrapped text in `echo '...'`
- Changed `#   1)` → `echo '  1)'` (spacing preserved)
- Empty line: `Type "#"` → `Type "echo ''"`

---

## Example 2: dot-dispatcher.tape

**Location:** `docs/demos/dot-dispatcher.tape`
**Problematic Lines:** 13 lines
**File Size:** 352KB GIF

### Before (WRONG)

```bash
# Line 15
Type "# Dot Dispatcher Demo - Dotfile Management"

# Line 21
Type "# Check dotfile status"

# Line 30
Type@100ms "# Edit a dotfile (with preview)"

# Line 37
Type@50ms "# (Editor opens, make a change, save)"
Type@50ms "# Preview shows: Modified: ~/.zshrc"
Type@50ms "# Apply? [Y/n/d] → y"

# Line 47
Type@100ms "# Unlock Bitwarden vault"

# Line 54
Type@50ms "# (Enter master password)"
Type@50ms "# ✓ Vault unlocked successfully"

# Line 60
Type@100ms "# List available secrets"

# Line 69
Type@100ms "# Retrieve a secret (no echo)"

# Line 82
Type@100ms "# Sync from remote repository"

# Line 91
Type@100ms "# Get help anytime"

# Line 103
Type "# Dotfile management made easy!"
```

### After (CORRECT)

```bash
# Line 15
Type "echo 'Dot Dispatcher Demo - Dotfile Management'"

# Line 21
Type "echo 'Check dotfile status'"

# Line 30
Type@100ms "echo 'Edit a dotfile (with preview)'"

# Line 37
Type@50ms "echo '(Editor opens, make a change, save)'"
Type@50ms "echo 'Preview shows: Modified: ~/.zshrc'"
Type@50ms "echo 'Apply? [Y/n/d] → y'"

# Line 47
Type@100ms "echo 'Unlock Bitwarden vault'"

# Line 54
Type@50ms "echo '(Enter master password)'"
Type@50ms "echo '✓ Vault unlocked successfully'"

# Line 60
Type@100ms "echo 'List available secrets'"

# Line 69
Type@100ms "echo 'Retrieve a secret (no echo)'"

# Line 82
Type@100ms "echo 'Sync from remote repository'"

# Line 91
Type@100ms "echo 'Get help anytime'"

# Line 103
Type "echo 'Dotfile management made easy!'"
```

### Key Changes
- All `Type "#..."` → `Type "echo '...'"`
- Preserved `Type@50ms` and `Type@100ms` typing speed syntax
- Preserved spacing and formatting

---

## Example 3: first-session.tape

**Location:** `docs/demos/first-session.tape`
**Problematic Lines:** 14 lines
**File Size:** Not yet generated

### Before (WRONG)

```bash
# Line 19
Type "# Tutorial 1: Your First Work Session"

# Line 22
Type "# Scene 1: Start tracking your work"

# Line 32
Type "# Start a work session"

# Line 51
Type "# Scene 2: Do some work..."

# Line 56
Type "# Edit a file, run tests, etc."

# Line 66
Type "# Check project status"

# Line 85
Type "# Scene 3: Finish your session"

# Line 90
Type "# End session with a quick note"

# Line 100
Type "# Session tracked! See summary:"

# Line 119
Type "# Quick Reference"

# Lines 122-128
Type "#   work         - Start tracking a session"
Type "#   dash         - View project dashboard"
Type "#   finish       - End session with optional note"

# Line 133
Type "# That's it! You've completed your first session."
```

### After (CORRECT)

```bash
# Line 19
Type "echo 'Tutorial 1: Your First Work Session'"

# Line 22
Type "echo 'Scene 1: Start tracking your work'"

# Line 32
Type "echo 'Start a work session'"

# Line 51
Type "echo 'Scene 2: Do some work...'"

# Line 56
Type "echo 'Edit a file, run tests, etc.'"

# Line 66
Type "echo 'Check project status'"

# Line 85
Type "echo 'Scene 3: Finish your session'"

# Line 90
Type "echo 'End session with a quick note'"

# Line 100
Type "echo 'Session tracked! See summary:'"

# Line 119
Type "echo 'Quick Reference'"

# Lines 122-128
Type "echo '  work         - Start tracking a session'"
Type "echo '  dash         - View project dashboard'"
Type "echo '  finish       - End session with optional note'"

# Line 133
Type "echo 'That'\''s it! You'\''ve completed your first session.'"
```

### Key Changes
- All `Type "#..."` → `Type "echo '...'"`
- Apostrophe escaping: `That's` → `That'\''s`
- Multi-line reference preserved with individual echo statements
- Spacing preserved with leading spaces in echo strings

---

## Font Size Fixes

### Before (WRONG)

```bash
Set FontSize 14
Set Width 1200
Set Height 800
```

### After (CORRECT)

```bash
Set FontSize 18  # Minimum for teaching workflows
Set Width 1400   # Increased for better readability
Set Height 900   # Increased for better readability
```

**Affected files:**
- teaching-git-workflow.tape (14 → 18)
- dot-dispatcher.tape (14 → 18)
- dopamine-features.tape (14 → 18)
- first-session.tape (14 → 18)
- cc-dispatcher.tape (14 → 18)
- teaching-workflow.tape (14 → 18)
- 23-token-automation-01-isolated-check.tape (16 → 18)
- 23-token-automation-02-cache-speed.tape (16 → 18)
- 23-token-automation-03-verbosity.tape (16 → 18)
- 23-token-automation-04-integration.tape (16 → 18)

---

## Common Patterns

### Pattern 1: Section Headers

```bash
# ❌ WRONG
Type "# Phase 1: Introduction" Enter

# ✅ CORRECT
Type "echo 'Phase 1: Introduction'" Enter
```

### Pattern 2: Bullet Lists

```bash
# ❌ WRONG
Type "#   • Item 1" Enter
Type "#   • Item 2" Enter

# ✅ CORRECT
Type "echo '  • Item 1'" Enter
Type "echo '  • Item 2'" Enter
```

### Pattern 3: Numbered Lists

```bash
# ❌ WRONG
Type "#   1) First option" Enter
Type "#   2) Second option" Enter

# ✅ CORRECT
Type "echo '  1) First option'" Enter
Type "echo '  2) Second option'" Enter
```

### Pattern 4: Empty Lines

```bash
# ❌ WRONG
Type "#" Enter

# ✅ CORRECT
Type "echo ''" Enter
```

### Pattern 5: Status Messages

```bash
# ❌ WRONG
Type "# ✓ Success!" Enter
Type "# ✗ Error occurred" Enter
Type "# ⚠ Warning message" Enter

# ✅ CORRECT
Type "echo '✓ Success!'" Enter
Type "echo '✗ Error occurred'" Enter
Type "echo '⚠ Warning message'" Enter
```

### Pattern 6: Multiline Blocks

```bash
# ❌ WRONG
Type "# System Information:" Enter
Type "#   OS: macOS" Enter
Type "#   Shell: zsh" Enter
Type "#   Version: 5.22.0" Enter

# ✅ CORRECT
Type "echo 'System Information:'" Enter
Type "echo '  OS: macOS'" Enter
Type "echo '  Shell: zsh'" Enter
Type "echo '  Version: 5.22.0'" Enter
```

---

## Apostrophe Escaping

### Pattern: Text with Apostrophes

When text contains apostrophes (`'`), use escape sequence:

```bash
# ❌ WRONG (causes VHS syntax error)
Type "echo 'That's great!'" Enter

# ✅ CORRECT (escape apostrophe)
Type "echo 'That'\''s great!'" Enter
```

**Explanation:** `'\''` breaks out of single quotes, adds escaped apostrophe, resumes single quotes

**Alternative (use double quotes):**
```bash
# ✅ ALSO CORRECT (if no other quotes in text)
Type "echo \"That's great!\"" Enter
```

---

## Search and Replace Commands

For bulk fixing in editors:

### Vim/Neovim
```vim
" Replace simple Type "# patterns
:%s/Type "#/Type "echo '/g

" Add closing quote and parenthesis (manual verification needed)
:%s/Type "echo '\(.*\)" Enter/Type "echo '\1'" Enter/g
```

### VS Code (Regex Find/Replace)
```
Find:    Type "# (.*)\" Enter
Replace: Type "echo '$1'" Enter
```

### sed (Command Line)
```bash
# Backup file first
cp teaching-git-workflow.tape teaching-git-workflow.tape.bak

# Simple replacement (requires manual quote fixing)
sed -i '' 's/Type "#/Type "echo '"'"'/g' teaching-git-workflow.tape
```

**Note:** Automated replacement requires careful review due to quote escaping complexity.

---

## Validation After Fixes

### Manual Check
```bash
# Check for remaining problematic patterns
grep 'Type "#' teaching-git-workflow.tape

# Should return no results if all fixed
```

### Automated Validation
```bash
# Use validation script (from Phase 2)
./scripts/validate-vhs-tapes.sh teaching-git-workflow.tape

# Expected output:
# ✓ teaching-git-workflow.tape
```

### Test Generation
```bash
# Generate GIF to verify no errors
cd docs/demos
vhs teaching-git-workflow.tape

# Check for ZSH errors in terminal output
# Verify GIF displays correctly
```

---

## Complete File Templates

### Teaching Tutorial Template (CORRECT)

```bash
# VHS Demo: Tutorial Name
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Brief Description

Output tutorial-name.gif

Require echo

Set Shell zsh
Set FontSize 18
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

Hide
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Type "cd ~/projects/teaching/scholar-demo-course" Enter
Sleep 500ms
Type "clear" Enter
Show

# Title using echo (CORRECT)
Type "echo 'Teaching Workflow v3.0: Feature Name'" Enter
Sleep 1s
Type "echo 'Brief Description'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Section 1
Type "echo 'Section 1: Description'" Enter
Sleep 1s
Type "teach command --option" Enter
Sleep 3s

Type "" Enter
Sleep 1s

# Completion
Type "echo '✓ Demo complete!'" Enter
Sleep 2s
```

### Dispatcher Demo Template (CORRECT)

```bash
# VHS Demo: Dispatcher Name
# Part of flow-cli v5.x

Output dispatcher-name.gif

Set Shell zsh
Set FontSize 18
Set Width 1200
Set Height 800
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

Hide
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Type "clear" Enter
Show

# Title using echo (CORRECT)
Type "echo 'Dispatcher Demo: Name'" Enter
Sleep 1s

# Demo commands
Type "dispatcher subcommand" Enter
Sleep 2s

# Completion
Type "echo '✓ Demo complete!'" Enter
Sleep 2s
```

---

## Summary of Changes

| File | Lines to Fix | Complexity | Time Est. |
|------|--------------|------------|-----------|
| teaching-git-workflow.tape | 60+ | High | 60-90 min |
| dot-dispatcher.tape | 13 | Low | 15-20 min |
| first-session.tape | 14 | Low | 15-20 min |
| **Total** | **87** | | **90-130 min** |

**Additional Changes:**
- 10 files need font size updates (14px/16px → 18px): ~30 min
- 10 GIFs need regeneration: ~60 min
- Testing and verification: ~30 min

**Total Estimate for Phase 1:** 3-4 hours

---

## References

- Main Spec: `SPEC-teaching-gifs-enhancement-2026-01-29.md`
- Checklist: `CHECKLIST-teaching-gifs-enhancement.md`
- VHS Documentation: https://github.com/charmbracelet/vhs

---

**Created:** 2026-01-29
**Purpose:** Reference guide for fixing VHS tape syntax errors
**Status:** Ready for implementation
