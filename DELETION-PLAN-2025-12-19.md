# Deletion Plan - 2025-12-19

**Generated:** 2025-12-19
**Source:** EXISTING-SYSTEM-SUMMARY.md (16 checked items)
**Method:** Interactive checkbox-based cleanup

---

## 📋 Items Marked for Deletion

Total checked items: **16**

### Category 1: Pick Aliases (5 items)
- [X] `pickr` - pick r (R packages)
- [X] `pickdev` - pick dev (Dev tools)
- [X] `pickq` - pick q (Quarto)
- [X] `pickteach` - pick teach (Teaching)
- [X] `pickrs` - pick rs (Research)

### Category 2: Ultra-Fast Aliases (3 items)
- [X] `t` - rtest (50x/day usage)
- [X] `c` - claude (30x/day usage)
- [X] `q` - qp - Quarto preview (10x/day usage)

### Category 3: Atomic Pairs (2 items)
- [X] `lt` - rload && rtest (load then test)
- [X] `dt` - rdoc && rtest (doc then test)

### Category 4: R Package Comprehensive (2 items)
- [X] `rcycle` - Full cycle: doc → test → check
- [X] `rquick` - Quick: load → test only

### Category 5: Claude Code (4 items)
- [X] `ccl` - Resume latest session
- [X] `cch` - Use Haiku (fastest)
- [X] `ccs` - Use Sonnet (default)
- [X] `cco` - Use Opus (most capable)

---

## 🔍 Found Locations

### ✅ Aliases Found in adhd-helpers.zsh

| Alias | Location | Line | Status |
|-------|----------|------|--------|
| `pickr` | `~/.config/zsh/functions/adhd-helpers.zsh` | 2075 | ✅ FOUND |
| `pickdev` | `~/.config/zsh/functions/adhd-helpers.zsh` | 2076 | ✅ FOUND |
| `pickq` | `~/.config/zsh/functions/adhd-helpers.zsh` | 2077 | ✅ FOUND |
| `pickteach` | `~/.config/zsh/functions/adhd-helpers.zsh` | 2991 | ✅ FOUND |
| `pickrs` | `~/.config/zsh/functions/adhd-helpers.zsh` | 3163 | ✅ FOUND |

**Total found: 5 aliases**

### ❌ Aliases Not Found (May Already Be Removed or Never Existed)

| Alias | Documented As | Notes |
|-------|---------------|-------|
| `t` | rtest | May be in .zshrc or removed |
| `c` | claude | Not found in adhd-helpers.zsh |
| `q` | qp | Not found in adhd-helpers.zsh |
| `lt` | rload && rtest | Found COMMENTED in .zshrc:265 (removed 2025-12-14) |
| `dt` | rdoc && rtest | Not found |
| `rcycle` | doc → test → check | Not found as alias (may be function) |
| `rquick` | load → test | Not found as alias (may be function) |
| `ccl` | Resume latest | Not found |
| `cch` | Haiku model | Not found |
| `ccs` | Sonnet model | Not found |
| `cco` | Opus model | Not found |

**Total not found: 11 items**

---

## 📊 Analysis

### Status Summary
- **Aliases that exist:** 5 (pick* aliases)
- **Aliases already removed:** At least 1 (`lt` - commented in .zshrc)
- **Aliases not found:** 11 (may be documented but not implemented yet)

### Explanation

The EXISTING-SYSTEM-SUMMARY.md and ALIAS-REFERENCE-CARD.md appear to document both:
1. **Implemented aliases** - Actually exist in configuration files
2. **Planned aliases** - Documented but not yet created
3. **Removed aliases** - Previously existed, now commented out

This is consistent with the ZSH-OPTIMIZATION-PROPOSAL-2025-12-16.md which mentions:
- ~100 lines of commented/removed aliases
- Ongoing optimization and cleanup

---

## 🎯 Recommended Action

### Option A: Delete Only What Exists (5 aliases)

Delete the 5 `pick*` aliases that were found:

**Files to modify:**
1. `~/.config/zsh/functions/adhd-helpers.zsh`
   - Line 2075: Remove `alias pickr='pick r'`
   - Line 2076: Remove `alias pickdev='pick dev'`
   - Line 2077: Remove `alias pickq='pick q'`
   - Line 2991: Remove `alias pickteach='pick teach'`
   - Line 3163: Remove `alias pickrs='pick rs'`

2. `/Users/dt/projects/dev-tools/zsh-configuration/docs/user/ALIAS-REFERENCE-CARD.md`
   - Remove documentation for these 5 aliases

3. `/Users/dt/projects/dev-tools/zsh-configuration/docs/reference/EXISTING-SYSTEM-SUMMARY.md`
   - Uncheck the 5 processed items

**Impact:** LOW
- These are convenience aliases (`pick r` vs `pickr` is only 2 characters difference)
- Core `pick` command remains functional
- Easy to restore if needed

---

### Option B: Update Documentation for Non-Existent Aliases

For the 11 items not found:
- Remove them from EXISTING-SYSTEM-SUMMARY.md (they don't actually exist)
- Update ALIAS-REFERENCE-CARD.md to reflect reality

**Impact:** MEDIUM
- Clarifies what actually exists vs what's planned
- Aligns documentation with implementation
- Reduces confusion

---

### Option C: Investigate Further

Search other configuration files (.zshrc, functions.zsh, etc.) to verify these aliases don't exist elsewhere before marking as "not found".

---

## ⚠️ Important Notes

### High-Risk Items Checked

You marked these ultra-high-usage aliases for deletion:
- `t` (50x/day)
- `c` (30x/day)
- `q` (10x/day)

**Good news:** These don't appear to exist as simple aliases, so there's nothing to delete. They may be:
1. Documented as planned features
2. Implemented as functions (not aliases)
3. Defined in a different file

### Recommendation

**SAFE APPROACH:**
1. Delete the 5 `pick*` aliases (confirmed to exist)
2. Create backup before deletion
3. Test that `pick` command still works
4. Uncheck those 5 items in EXISTING-SYSTEM-SUMMARY.md
5. Investigate the other 11 items separately

Would you like me to proceed with Option A (delete 5 pick aliases)?

---

## 🔄 Next Steps

1. **User Decision:** Choose Option A, B, or C
2. **If Option A:**
   - Create backup of adhd-helpers.zsh
   - Remove 5 lines
   - Update documentation
   - Test `pick` command
   - Commit changes
3. **If Option B:**
   - Clean up ALIAS-REFERENCE-CARD.md
   - Update EXISTING-SYSTEM-SUMMARY.md
   - Document what actually exists
4. **If Option C:**
   - Search .zshrc
   - Search functions.zsh
   - Search other config files
   - Create comprehensive inventory

---

**Created:** 2025-12-19
**Status:** 🟡 Awaiting User Decision
**Safe to delete:** 5 pick* aliases
**Needs investigation:** 11 other items
