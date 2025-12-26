# Alias Conflict Review - flow-cli

**Date:** December 25, 2025  
**Requested by:** User preference against single-letter commands  
**Status:** ✅ COMPLETED - All conflicts resolved (Commit: 91a4f3f)

---

## Executive Summary

**Total Aliases:** 15 active aliases in flow-cli  
**Single-Letter Aliases:** 2 (both violate user preference)  
**System Command Conflicts:** 1 (`pp` conflicts with system command)  
**Recommendation:** Remove or rename 3 aliases

---

## 🚨 Single-Letter Aliases (User Dislikes)

### 1. `d` → `dash`

**File:** `commands/dash.zsh`  
**Line:** Search for `alias d=`  
**Conflicts:** ✓ No system conflict  
**Issue:** ❌ Single-letter alias (user preference violation)

**Recommendation:** **REMOVE**

```zsh
# Remove this line:
alias d='dash'

# Users should use:
dash           # Full command (4 letters, acceptable)
```

---

### 2. `f` → `flow`

**File:** `commands/flow.zsh`  
**Line:** Search for `alias f=`  
**Conflicts:** ✓ No system conflict  
**Issue:** ❌ Single-letter alias (user preference violation)

**Recommendation:** **REMOVE**

```zsh
# Remove this line:
alias f='flow'

# Users should use:
flow           # Full command (4 letters, acceptable)
```

---

## ⚠️ Short Aliases (2-3 Letters) - Review

### 3. `di` → `dash -i`

**File:** `commands/dash.zsh`  
**Conflicts:** ✓ No system conflict  
**Assessment:** ✅ **KEEP** (reasonable abbreviation, no conflict)

---

### 4. `pp` → `pick`

**File:** `commands/pick.zsh`  
**Conflicts:** ❌ **CONFLICTS** with system `pp` command  
**System Command:** `/usr/bin/pp` (exists on macOS)

**Recommendation:** **REMOVE**

```zsh
# Remove this line:
alias pp='pick'

# Users should use:
pick           # Full command (4 letters, acceptable)
```

---

### 5. `ah` → `aliashelp`

**File:** `zsh/functions.zsh`  
**Conflicts:** ✓ No system conflict  
**Assessment:** ⚠️ **CONSIDER REMOVING** (single-letter philosophy)

- Short (2 letters) but not single
- Helper command (low frequency use)
- Consider using full `aliashelp` instead

**Recommendation:** **OPTIONAL REMOVE**

---

### 6. `nx` → `nexus`

**File:** `zsh/functions/adhd-helpers.zsh`  
**Conflicts:** ✓ No system conflict  
**Assessment:** ✅ **KEEP** (reasonable abbreviation)

---

## ✅ Longer Aliases (4+ Letters) - All Good

These aliases follow best practices and have no conflicts:

| Alias       | Target       | File                               | Status  |
| ----------- | ------------ | ---------------------------------- | ------- |
| `pickr`     | `pick r`     | commands/pick.zsh                  | ✅ KEEP |
| `pickdev`   | `pick dev`   | commands/pick.zsh                  | ✅ KEEP |
| `pickq`     | `pick q`     | commands/pick.zsh                  | ✅ KEEP |
| `pickteach` | `pick teach` | commands/pick.zsh                  | ✅ KEEP |
| `pickrs`    | `pick rs`    | commands/pick.zsh                  | ✅ KEEP |
| `pickapp`   | `pick app`   | commands/pick.zsh                  | ✅ KEEP |
| `mcpp`      | `mcp pick`   | lib/dispatchers/mcp-dispatcher.zsh | ✅ KEEP |
| `tut`       | `tutorial`   | commands/tutorial.zsh              | ✅ KEEP |

---

## 📋 Recommended Actions

### High Priority (User Preference + Conflicts)

1. **Remove `d='dash'`** from `commands/dash.zsh`
   - Reason: Single-letter alias (user dislikes)
   - Impact: Minimal, `dash` is only 4 letters
2. **Remove `f='flow'`** from `commands/flow.zsh`
   - Reason: Single-letter alias (user dislikes)
   - Impact: Minimal, `flow` is only 4 letters

3. **Remove `pp='pick'`** from `commands/pick.zsh`
   - Reason: Conflicts with system command `/usr/bin/pp`
   - Impact: Minimal, `pick` is only 4 letters

### Medium Priority (Consistency)

4. **Consider removing `ah='aliashelp'`** from `zsh/functions.zsh`
   - Reason: Follows single-letter philosophy
   - Impact: Low-frequency command
   - Alternative: Use full `aliashelp`

---

## 🔍 Detailed File Locations

### commands/dash.zsh

```zsh
# Lines to remove/modify:
alias d='dash'      # ❌ REMOVE (single-letter)
alias di='dash -i'  # ✅ KEEP (acceptable)
```

### commands/flow.zsh

```zsh
# Line to remove:
alias f='flow'      # ❌ REMOVE (single-letter)
```

### commands/pick.zsh

```zsh
# Line to remove:
alias pp='pick'     # ❌ REMOVE (conflict with /usr/bin/pp)

# Keep these:
alias pickr='pick r'
alias pickdev='pick dev'
alias pickq='pick q'
alias pickteach='pick teach'
alias pickrs='pick rs'
alias pickapp='pick app'
```

### zsh/functions.zsh

```zsh
# Consider removing:
alias ah='aliashelp'  # ⚠️ OPTIONAL (philosophy)
```

### zsh/functions/adhd-helpers.zsh

```zsh
# Keep this:
alias nx="nexus"      # ✅ KEEP
```

### lib/dispatchers/mcp-dispatcher.zsh

```zsh
# Keep this:
alias mcpp='mcp pick' # ✅ KEEP
```

---

## 📊 Statistics Summary

| Category                    | Count | Action          |
| --------------------------- | ----- | --------------- |
| **Single-letter aliases**   | 2     | ❌ Remove both  |
| **Conflicting aliases**     | 1     | ❌ Remove       |
| **Short (2-3 letter) safe** | 3     | ✅ Keep         |
| **Longer (4+ letter)**      | 8     | ✅ Keep all     |
| **Total to remove**         | 3-4   | d, f, pp, (ah?) |
| **Total to keep**           | 11-12 | Rest            |

---

## 🎯 Implementation Guide

### Step 1: Create Backup

```bash
cd /Users/dt/projects/dev-tools/flow-cli
git add -A
git commit -m "backup: before alias cleanup"
```

### Step 2: Remove Single-Letter Aliases

```bash
# Remove from commands/dash.zsh
sed -i.bak '/^alias d=/d' commands/dash.zsh

# Remove from commands/flow.zsh
sed -i.bak '/^alias f=/d' commands/flow.zsh
```

### Step 3: Remove Conflicting Alias

```bash
# Remove from commands/pick.zsh
sed -i.bak '/^alias pp=/d' commands/pick.zsh
```

### Step 4: Optional - Remove Short Helper

```bash
# Remove from zsh/functions.zsh (if desired)
sed -i.bak '/^alias ah=/d' zsh/functions.zsh
```

### Step 5: Test

```bash
# Reload plugin
source flow.plugin.zsh

# Test that commands still work:
dash
flow
pick
aliashelp  # instead of 'ah'
```

### Step 6: Commit Changes

```bash
git add -A
git commit -m "refactor: remove single-letter aliases and conflicts

- Remove 'd' alias (single-letter, user preference)
- Remove 'f' alias (single-letter, user preference)
- Remove 'pp' alias (conflicts with system /usr/bin/pp)
- Optional: Remove 'ah' alias (consistency)

Rationale: User prefers explicit command names over single-letter shortcuts.
All removed aliases have acceptable full-length alternatives.
"
```

---

## 💡 User Guidance

### Transition Guide

**What Changed:**

```bash
# Before (single-letter):
d              # ❌ No longer works
f              # ❌ No longer works
pp             # ❌ No longer works (also conflicted)

# After (explicit):
dash           # ✅ Use this (4 letters)
flow           # ✅ Use this (4 letters)
pick           # ✅ Use this (4 letters)
```

**What Stayed:**

```bash
# These still work (longer aliases):
di             # dash -i
nx             # nexus
pickr          # pick r
pickdev        # pick dev
mcpp           # mcp pick
tut            # tutorial
# ... and 4 more pick* aliases
```

---

## 🔄 Alternative Approach (If Wanted Later)

If you later decide you want **some** short aliases, consider this philosophy:

**Good Short Aliases:**

- Minimum 2 letters (no single-letter)
- No conflicts with system commands
- High-frequency commands only
- Mnemonic (makes sense)

**Examples:**

```zsh
# Acceptable:
alias ds='dash'        # 2 letters, mnemonic
alias fl='flow'        # 2 letters, mnemonic
alias pk='pick'        # 2 letters, mnemonic

# Not acceptable:
alias d='dash'         # Single-letter
alias pp='pick'        # Conflicts with system
```

---

## ✅ Checklist

Before implementing:

- [ ] Review all 3-4 aliases to remove
- [ ] Verify you don't use these aliases frequently
- [ ] Create git backup commit
- [ ] Remove aliases from source files
- [ ] Test plugin reloads correctly
- [ ] Verify all commands still work with full names
- [ ] Commit changes with clear message
- [ ] Update documentation if needed

---

## 📚 See Also

- [Alias Reference Card](ALIAS-REFERENCE-CARD.md)
- [Command Quick Reference](COMMAND-QUICK-REFERENCE.md)
- [ZSH Development Guidelines](../../ZSH-DEVELOPMENT-GUIDELINES.md)

---

**Review completed:** December 25, 2025  
**Reviewer:** OpenCode  
**Status:** Ready for implementation

---

## ✅ RESOLUTION COMPLETE

**Commit:** `91a4f3f` - "refactor: remove single-letter and conflicting aliases"  
**Date:** December 25, 2025

### Aliases Removed

1. ✅ `d='dash'` - Removed from commands/dash.zsh
2. ✅ `f='flow'` - Removed from commands/flow.zsh
3. ✅ `pp='pick'` - Removed from commands/pick.zsh
4. ✅ `ah='aliashelp'` - Removed from zsh/functions.zsh

### Impact

- Users now use full command names: `dash`, `flow`, `pick`, `aliashelp`
- No more system conflicts
- Cleaner, more explicit namespace
- Consistent with user preference for explicit commands

### Testing

All commands tested and working:

```bash
dash              # ✅ Works
flow help         # ✅ Works
pick              # ✅ Works
aliashelp         # ✅ Works
```

---

# Original Analysis (For Reference)
