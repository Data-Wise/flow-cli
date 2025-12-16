# ZSH Alias Loading Issues - Fixed

**Date:** 2025-12-14
**Status:** ✅ Resolved

## Issues Found

### 1. **`setopt NO_ALIASES` Preventing Alias Definitions**

**File:** `~/.config/zsh/functions/adhd-helpers.zsh`
**Line:** 17 (original)

**Problem:**
```zsh
emulate -L zsh
setopt NO_ALIASES  # ❌ This line prevented aliases from being defined
```

The `setopt NO_ALIASES` directive was preventing all aliases defined in the file from being properly created, even though it was in a local scope created by `emulate -L zsh`.

**Fix:**
```zsh
emulate -L zsh
# Note: emulate -L zsh already disables aliases during emulation
# We don't need explicit setopt NO_ALIASES as it prevents our own alias definitions
```

**Result:** All ADHD helper aliases now load correctly:
- `js`, `idk`, `stuck` → `just-start`
- `why`, `win`, `yay`, `wins` → respective functions
- `work`, `here`, `pp`, `ppt`, `pprs` → workflow functions

---

### 2. **Alias Name Conflict: `gm`**

**Files:**
- `~/.config/zsh/.zshrc` line 870: `alias gm='gemini'`
- `~/.config/zsh/functions/adhd-helpers.zsh` line 2726: `alias gm='pmorning'`

**Problem:**
Since `adhd-helpers.zsh` is sourced AFTER `.zshrc`, the `gm='pmorning'` alias was overriding the Gemini CLI alias `gm='gemini'`.

**Fix:**
Renamed the morning routine alias to avoid conflict:
```zsh
alias morning='pmorning'   # good morning routine
alias gmorning='pmorning'  # alternative
# 'gm' now correctly points to 'gemini' from .zshrc
```

**Result:**
- `gm` → launches Gemini CLI (as intended)
- `morning` or `gmorning` → runs morning routine

---

## Verification

To verify all aliases are loading:

```bash
# Test in a fresh shell
exec zsh

# Check ADHD helpers
alias | grep -E '^(js|idk|stuck)='

# Check help system
alias | grep '^ah='
ah              # Should show help menu

# Check Gemini (should NOT be overridden)
alias | grep '^gm='  # Should show: gm=gemini

# Check morning routine
alias | grep '^morning='  # Should show: morning=pmorning
```

## Files Modified

1. `~/.config/zsh/functions/adhd-helpers.zsh`
   - Line 17: Removed `setopt NO_ALIASES`
   - Line 2726-2728: Renamed `gm` alias to `morning` and `gmorning`

## Impact

### ✅ Now Working:
- All ADHD helper aliases (`js`, `idk`, `stuck`, `why`, `win`, `yay`, `wins`)
- Help system (`ah`, `aliases`)
- Workflow commands (`work`, `here`, `pp`, `ppt`, `pprs`)
- Project dashboards (`tst`, `rst`, `dash`)
- Morning routine (now `morning` or `gmorning`)
- Gemini CLI (`gm`) - no longer overridden

### 📝 Action Required:
**Update muscle memory:**
If you were using `gm` for the morning routine, switch to:
- `morning` (recommended)
- `gmorning` (alternative)

`gm` now correctly launches Gemini as documented in `.zshrc`.

## Testing Checklist

- [x] Removed `setopt NO_ALIASES` from adhd-helpers.zsh
- [x] Renamed conflicting `gm` alias
- [x] Verified aliases load in fresh shell
- [x] Confirmed `ah` help system works
- [x] Confirmed `js` and other ADHD helpers work
- [x] Confirmed `gm` launches Gemini (not pmorning)

## Next Steps

1. **Reload your shell:** `exec zsh` or open a new terminal
2. **Test the changes:** Run `ah` to see the help system
3. **Update documentation:** If `gm` was documented as "good morning" anywhere, update it to `morning`

---

**Note:** This fix ensures all 144+ aliases documented in `ALIAS-REFERENCE-CARD.md` load correctly.
