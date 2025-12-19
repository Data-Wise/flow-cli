# Alias Cleanup - Detailed Removal Plan

**Generated:** 2025-12-19
**Purpose:** Remove redundant aliases replaced by dispatcher keywords
**Status:** Ready for execution

---

## Summary

After thorough analysis of the ZSH configuration files, here's what was found:

### Files Analyzed
1. `/Users/dt/.config/zsh/functions/adhd-helpers.zsh` (3300+ lines)
2. `/Users/dt/.config/zsh/functions.zsh` (597 lines)
3. `/Users/dt/.config/zsh/.zshrc` (1165 lines)

### Total Items to Remove: 10

- **5 aliases** from adhd-helpers.zsh
- **2 functions** from functions.zsh
- **3 commented lines** from .zshrc

---

## CRITICAL FINDING

**Most of the 54 aliases mentioned in the original removal list DO NOT EXIST.**

The following were NOT found and don't need to be removed:
- R Package aliases: rcycle, rquick, rcheckfast, rdoccheck, lt, dt, rpkgclean, rpkgdeep, cleantex, rpkgcommit
- Quarto aliases: q, qp, qr, qpdf, qhtml, qdocx, qcommit, qarticle, qpresent
- Vibe/Session aliases: gm, gn (as aliases - functions exist)
- Pick aliases: pp, cdproj (only pickr, pickdev, pickq, pickteach, pickrs exist)
- Timer functions: focus, unfocus, worktimer, quickbreak, break, deepwork (focus exists but is needed)
- Peek aliases: peekr, peekrd, peekqmd, peekdesc, peeknews, peeklog
- Claude aliases: ccl, cch, ccs, cco, ccplan, ccauto, ccyolo, cccode

**These aliases were likely already removed in a previous cleanup or never existed.**

---

## Part 1: adhd-helpers.zsh - Remove 5 Pick Aliases

### Location
`/Users/dt/.config/zsh/functions/adhd-helpers.zsh`

### Aliases to Remove

```bash
# Line 2075
alias pickr='pick r'         # R packages

# Line 2076
alias pickdev='pick dev'     # Dev tools

# Line 2077
alias pickq='pick q'         # Quarto

# Line 2991
alias pickteach='pick teach'

# Line 3163
alias pickrs='pick rs'
```

### Reason for Removal
These are being replaced by the `pick` dispatcher command which handles:
- `pick r` - R packages
- `pick dev` - Dev tools
- `pick q` - Quarto
- `pick teach` - Teaching
- `pick rs` - Research

The dispatcher already exists and these aliases are redundant shortcuts.

### Functions to KEEP (mentioned in removal list but are functions, not aliases)
- Line 358: `focus()` - KEEP (function, not alias)
- Line 1024: `startsession()` - KEEP (function, needed)
- Line 1043: `endsession()` - KEEP (function, needed)
- Line 2749: `pmorning()` - KEEP (function, needed by morning routines)

---

## Part 2: functions.zsh - Remove 2 Functions

### Location
`/Users/dt/.config/zsh/functions.zsh`

### Functions to Remove

#### 1. rcycle() - Lines 170-200 (approximately)

```bash
# Complete check cycle: load → document → test → check
rcycle() {
    echo "🔄 Running full R package cycle..."
    echo ""

    echo "1️⃣ Loading package..."
    rload || return 1
    echo ""

    echo "2️⃣ Documenting..."
    rdoc || return 1
    echo ""

    echo "3️⃣ Running tests..."
    rtest || return 1
    echo ""

    echo "4️⃣ Checking package..."
    rcheck || return 1
    echo ""

    echo "✅ Full cycle complete!"
}
```

**Reason:** This function is deprecated and has been moved to adhd-helpers.zsh or replaced by the `r` dispatcher.

#### 2. rquick() - Lines ~205-210 (approximately)

```bash
# Quick cycle (load + test only)
rquick() {
    echo "⚡ Quick check..."
    rload && rtest
}
```

**Reason:** Replaced by `r quick` dispatcher command.

### Functions to CHECK (may be duplicates)

#### unfocus() - Line ~486

**Action:** Compare with adhd-helpers.zsh version. If identical, remove from functions.zsh. If adhd-helpers has a better version, remove this one.

#### quickbreak() - Line ~499

**Action:** Same as unfocus - check for duplicates in adhd-helpers.zsh.

### Deprecated Comments to Remove

These comment blocks should be removed as they're just clutter:

**Line ~359-364:**
```bash
# focus() is defined in adhd-helpers.zsh (authoritative)
# The adhd-helpers version has full timer support and better ADHD features
# DEPRECATED: This basic version - use focus() from adhd-helpers.zsh
#
# focus() {
#     ... (moved to adhd-helpers.zsh)
# }
```

**Line ~573:**
```bash
# wn alias defined in adhd-helpers.zsh as 'what-next' (authoritative)
# alias wn='whatnow'  # DEPRECATED - use what-next from adhd-helpers.zsh
```

**Line ~597:**
```bash
# wh alias defined in adhd-helpers.zsh as 'wins-history' (authoritative)
# alias wh='winshistory'  # DEPRECATED - use wins-history from adhd-helpers.zsh
```

---

## Part 3: .zshrc - Remove 3 Commented Lines

### Location
`/Users/dt/.config/zsh/.zshrc`

### Lines to Remove

```bash
# Line 265
# REMOVED 2025-12-14: alias lt='rload && rtest'      # Load then test

# Line 266
# REMOVED 2025-12-14: alias dt='rdoc && rtest'       # Document then test

# Line 292
# REMOVED 2025-12-14: alias ccs='claude --model sonnet'                    # Use Sonnet (default)
```

**Reason:** These are just comment noise from a previous cleanup. They serve no purpose and can be deleted.

---

## Safety Checks Before Removal

### 1. Check adhd-helpers.zsh for Dependencies

Search for any references to the aliases being removed:

```bash
grep -n "pickr\|pickdev\|pickq\|pickteach\|pickrs" /Users/dt/.config/zsh/functions/adhd-helpers.zsh
```

Expected: Only the alias definitions themselves (lines 2075-2077, 2991, 3163).

### 2. Check if pick() dispatcher exists

```bash
grep -n "^pick() {" /Users/dt/.config/zsh/functions/adhd-helpers.zsh
```

Expected: Should find the pick() function definition.

### 3. Check for rcycle/rquick references

```bash
grep -n "rcycle\|rquick" /Users/dt/.config/zsh/functions/adhd-helpers.zsh
```

Expected: If these functions exist in adhd-helpers.zsh, then the functions.zsh versions are safe to remove.

### 4. Check for unfocus/quickbreak in adhd-helpers

```bash
grep -n "^unfocus()\|^quickbreak()" /Users/dt/.config/zsh/functions/adhd-helpers.zsh
```

Expected: Check if better versions exist.

---

## Execution Steps

### Step 1: Create Backups

```bash
# Create backup directory
backup_dir="/Users/dt/projects/dev-tools/zsh-configuration/config/backups/alias-cleanup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

# Backup files
cp /Users/dt/.config/zsh/functions/adhd-helpers.zsh "$backup_dir/adhd-helpers.zsh.backup"
cp /Users/dt/.config/zsh/functions.zsh "$backup_dir/functions.zsh.backup"
cp /Users/dt/.config/zsh/.zshrc "$backup_dir/.zshrc.backup"

# Verify backups
ls -lh "$backup_dir"
```

### Step 2: Remove Pick Aliases from adhd-helpers.zsh

```bash
# Edit file to remove lines 2075-2077, 2991, 3163
# Use sed or manual editing

# Remove the 5 pick aliases
sed -i.tmp '/^alias pickr=/d; /^alias pickdev=/d; /^alias pickq=/d; /^alias pickteach=/d; /^alias pickrs=/d' \
    /Users/dt/.config/zsh/functions/adhd-helpers.zsh
```

### Step 3: Remove Functions from functions.zsh

**Option A: Manual Editing (Recommended)**
1. Open `/Users/dt/.config/zsh/functions.zsh` in editor
2. Find and delete `rcycle()` function (lines ~170-200)
3. Find and delete `rquick()` function (lines ~205-210)
4. Remove deprecated comment blocks (lines ~359-364, ~573, ~597)
5. Check for duplicate `unfocus()` and `quickbreak()` functions
6. Save file

**Option B: Automated (Risky - verify first)**
```bash
# Create a cleaned version using vim/sed
# This is complex - manual editing recommended
```

### Step 4: Remove Commented Lines from .zshrc

```bash
# Remove the 3 commented lines
sed -i.tmp '/^# REMOVED 2025-12-14: alias lt=/d; /^# REMOVED 2025-12-14: alias dt=/d; /^# REMOVED 2025-12-14: alias ccs=/d' \
    /Users/dt/.config/zsh/.zshrc
```

### Step 5: Test Configuration

```bash
# Reload ZSH configuration
source ~/.zshrc

# Test that pick dispatcher works
pick r  # Should show R package picker

# Test that removed aliases are gone
type pickr  # Should show "not found"
type pickdev  # Should show "not found"

# Test that kept functions still work
type focus  # Should show function definition
type startsession  # Should show function definition
```

### Step 6: Verify No Broken Dependencies

```bash
# Check for any errors
zsh -n /Users/dt/.config/zsh/functions/adhd-helpers.zsh
zsh -n /Users/dt/.config/zsh/functions.zsh
zsh -n /Users/dt/.config/zsh/.zshrc

# If all pass, configuration syntax is valid
```

---

## Rollback Plan

If something breaks:

```bash
# Restore from backups
backup_dir="/Users/dt/projects/dev-tools/zsh-configuration/config/backups/alias-cleanup-YYYYMMDD-HHMMSS"

cp "$backup_dir/adhd-helpers.zsh.backup" /Users/dt/.config/zsh/functions/adhd-helpers.zsh
cp "$backup_dir/functions.zsh.backup" /Users/dt/.config/zsh/functions.zsh
cp "$backup_dir/.zshrc.backup" /Users/dt/.config/zsh/.zshrc

# Reload
source ~/.zshrc
```

---

## Expected Outcome

### What Will Be Removed
- 5 pick aliases → Use `pick <category>` instead
- 2 R package functions → Use `r cycle` and `r quick` instead
- 3 comment lines → Clean up old removal notes
- Deprecated comment blocks → Reduce clutter

### What Will Remain
- All essential functions (focus, startsession, endsession, pmorning)
- All dispatcher commands (pick, r, qu, vibe, timer, peek, cc)
- All workflow functions from functions.zsh

### Line Count Reduction
- adhd-helpers.zsh: ~5 lines removed
- functions.zsh: ~60-80 lines removed (2 functions + comments)
- .zshrc: ~3 lines removed
- **Total: ~70 lines removed**

---

## Questions Raised

1. **Where are the other 44 aliases?**
   - They were mentioned in the removal list but don't exist in the files
   - Possibly removed in a previous cleanup
   - Or never existed in the first place

2. **Should we create the dispatchers first?**
   - Before removing aliases, verify that their dispatcher equivalents exist
   - Check: `r cycle`, `r quick`, `pick r`, `pick dev`, etc.

3. **What about unfocus() and quickbreak()?**
   - Need to verify if adhd-helpers.zsh has better versions
   - If yes, remove from functions.zsh
   - If no, keep in functions.zsh

---

## Next Steps

1. **Verify this plan** - Review the removal plan for accuracy
2. **Check dispatcher existence** - Ensure `pick`, `r`, etc. dispatchers are implemented
3. **Execute backups** - Run Step 1
4. **Execute removals** - Run Steps 2-4 carefully
5. **Test thoroughly** - Run Steps 5-6
6. **Document changes** - Update CHANGELOG or relevant docs

---

## Notes

- This cleanup is much smaller than the original 54-item list suggested
- Most aliases have already been removed or never existed
- Focus on removing what actually exists: 5 pick aliases, 2 functions, 3 comments
- Total removal: ~70 lines of code
- Impact: Minimal - these are all redundant shortcuts

---

**Ready to execute?** Start with Step 1 (backups) and proceed carefully.
