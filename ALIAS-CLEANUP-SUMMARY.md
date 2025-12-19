# Alias Cleanup - Quick Summary

**Date:** 2025-12-19
**Status:** Analysis Complete - Ready for Execution
**Documents Generated:** 3 files (PLAN, FINDINGS, SUMMARY)

---

## TL;DR

Of **54 aliases** mentioned for removal, only **10 items actually exist**.

- **5 pick aliases** → Replace with `pick <category>`
- **2 R functions** → Replace with `r cycle` and `r quick`
- **3 commented lines** → Just cleanup

**Impact:** ~60 lines removed, zero functionality lost, very low risk.

---

## What Actually Needs Removal

### adhd-helpers.zsh (5 aliases)
```bash
pickr='pick r'
pickdev='pick dev'
pickq='pick q'
pickteach='pick teach'
pickrs='pick rs'
```
**Lines:** 2075, 2076, 2077, 2991, 3163

### functions.zsh (2 functions + 3 comment blocks)
```bash
rcycle()      # ~30 lines around line 170
rquick()      # ~5 lines around line 205
# + 3 deprecated comment blocks (~15 lines)
```

### .zshrc (3 commented lines)
```bash
Line 265: # REMOVED 2025-12-14: alias lt=...
Line 266: # REMOVED 2025-12-14: alias dt=...
Line 292: # REMOVED 2025-12-14: alias ccs=...
```

---

## What Does NOT Exist (44 items)

All these were on the removal list but **don't exist** in files:

- **R aliases (10):** rcycle, rquick, rcheckfast, rdoccheck, lt, dt, rpkgclean, rpkgdeep, cleantex, rpkgcommit
- **Quarto (9):** q, qp, qr, qpdf, qhtml, qdocx, qcommit, qarticle, qpresent
- **Vibe (6):** gm, gn, pmorning, pnight, progress_check, status (as aliases)
- **Pick (2):** pp, cdproj
- **Timer (5):** unfocus, worktimer, quickbreak, break, deepwork
- **Peek (6):** peekr, peekrd, peekqmd, peekdesc, peeknews, peeklog
- **Claude (8):** ccl, cch, ccs, cco, ccplan, ccauto, ccyolo, cccode

**Likely reason:** Already removed in previous cleanup or never implemented.

---

## Quick Execution Guide

### 1. Backup (REQUIRED)
```bash
backup_dir="$HOME/projects/dev-tools/zsh-configuration/config/backups/alias-cleanup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"
cp ~/.config/zsh/functions/adhd-helpers.zsh "$backup_dir/"
cp ~/.config/zsh/functions.zsh "$backup_dir/"
cp ~/.config/zsh/.zshrc "$backup_dir/"
```

### 2. Remove Pick Aliases
```bash
# Edit adhd-helpers.zsh - remove lines:
# 2075: alias pickr='pick r'
# 2076: alias pickdev='pick dev'
# 2077: alias pickq='pick q'
# 2991: alias pickteach='pick teach'
# 3163: alias pickrs='pick rs'
```

### 3. Remove R Functions
```bash
# Edit functions.zsh - remove:
# rcycle() function (lines ~170-200)
# rquick() function (lines ~205-210)
# 3 deprecated comment blocks
```

### 4. Remove Comments
```bash
# Edit .zshrc - remove lines:
# 265, 266, 292
```

### 5. Test
```bash
source ~/.zshrc
pick r        # Should work (dispatcher)
type pickr    # Should fail (alias removed)
```

---

## Before You Start

**Verify these exist:**
- ✓ `pick` dispatcher in adhd-helpers.zsh
- ✓ `r cycle` command exists
- ✓ `r quick` command exists

**If dispatchers don't exist:** Don't remove the aliases yet!

---

## Risk Level: VERY LOW

All removals are:
- Redundant shortcuts to existing commands
- Commented-out code
- Deprecated documentation

**Zero functionality will be lost.**

---

## Files

1. **ALIAS-CLEANUP-PLAN.md** - Detailed execution plan (step-by-step commands)
2. **ALIAS-CLEANUP-FINDINGS.md** - Full analysis report (30+ pages)
3. **ALIAS-CLEANUP-SUMMARY.md** - This file (quick reference)

---

## Questions?

1. **Why only 10 items?** → Most were already removed or never existed
2. **Can I skip backups?** → NO. Always backup before modifying shell config
3. **Will this break anything?** → Extremely unlikely if dispatchers exist
4. **How long will this take?** → 5-10 minutes for careful manual editing

---

## Rollback (If Needed)

```bash
# Find your backup directory
ls -la ~/projects/dev-tools/zsh-configuration/config/backups/

# Restore files
backup_dir="<your-backup-directory>"
cp "$backup_dir/adhd-helpers.zsh" ~/.config/zsh/functions/
cp "$backup_dir/functions.zsh" ~/.config/zsh/functions/
cp "$backup_dir/.zshrc" ~/.config/zsh/

# Reload
source ~/.zshrc
```

---

**Ready?** Start with backups, then proceed carefully.
