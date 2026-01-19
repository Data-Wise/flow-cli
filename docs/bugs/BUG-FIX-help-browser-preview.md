# Bug Fix: Help Browser Preview Pane

**Date:** 2026-01-06
**Status:** ✅ Fixed
**Version:** v4.9.1 (pending)

## Problem

The `flow help -i` interactive help browser showed "command not found" errors in the preview pane instead of displaying help text for commands.

### User Report

```
flow help -i preview pane does not work. it says command not found
```

### Symptom

When navigating through commands in the fzf picker, the right-side preview pane displayed:

```
Command not found: work
Command not found: dash
Command not found: finish
...
```

## Root Cause

The fzf `--preview` option runs commands in a **new subshell** that doesn't have the flow-cli plugin loaded. The preview script tried to execute flow-cli commands directly, but they weren't available in that isolated environment.

**Before (broken):**

```bash
--preview='
  cmd=$(echo {} | awk "{print \$1}")
  cmd=$(echo "$cmd" | sed "s/\x1b\[[0-9;]*m//g")

  if type "${cmd}" >/dev/null 2>&1; then    # ← Always fails
    $cmd help
  else
    echo "Command not found: $cmd"           # ← Always hits this
  fi
'
```

The `type` check failed because commands like `work`, `dash`, `cc`, etc. weren't defined in the subshell.

## Solution

Created a helper function `_flow_show_help_preview()` that runs in the **current shell environment** (where the plugin is loaded), following the existing pattern used by `_flow_show_project_preview()` in [lib/tui.zsh](lib/tui.zsh#L137).

**After (fixed):**

```bash
# Helper function defined in current shell
_flow_show_help_preview() {
  local cmd="$1"

  if type "${cmd}" >/dev/null 2>&1; then
    if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm)$ ]]; then
      $cmd help 2>/dev/null || echo "Help not available for $cmd"
    else
      $cmd --help 2>/dev/null || $cmd help 2>/dev/null || echo "Help not available for $cmd"
    fi
  else
    echo "Command not found: $cmd"
  fi
}

# fzf preview now calls the function
--preview='
  cmd=$(echo {} | awk "{print \$1}" | sed "s/\x1b\[[0-9;]*m//g")
  _flow_show_help_preview "$cmd"
'
```

## Files Changed

| File                                                                                 | Change                                     | Lines |
| ------------------------------------------------------------------------------------ | ------------------------------------------ | ----- |
| [lib/help-browser.zsh](lib/help-browser.zsh)                                         | Added `_flow_show_help_preview()` function | +18   |
| [lib/help-browser.zsh](lib/help-browser.zsh)                                         | Simplified fzf preview script              | -13   |
| [tests/test-help-browser-preview.zsh](tests/test-help-browser-preview.zsh)           | New test suite                             | +109  |
| [tests/interactive-dog-feeding-phase2.zsh](tests/interactive-dog-feeding-phase2.zsh) | Updated expected behavior                  | +2    |

**Total:** 1 file changed core logic, 2 new/updated test files

## Verification

### Automated Tests (6 tests)

```bash
./tests/test-help-browser-preview.zsh
```

**Results:** ✅ All 6 tests pass

- ✅ Helper function exists
- ✅ Preview shows help for regular commands (dash)
- ✅ Preview shows help for dispatchers (r)
- ✅ All dispatchers work (g, cc, wt, mcp, r, qu, obs, tm)
- ✅ Graceful handling of nonexistent commands
- ✅ ANSI code stripping

### Manual Verification

Run interactive help and confirm preview pane shows help text:

```bash
flow help -i
```

**Expected:** Preview pane shows formatted help (e.g., "DASH - Project Dashboard")
**Before fix:** Preview pane showed "Command not found: dash"
**After fix:** ✅ Preview pane shows full help text

### Dog-Feeding Test

Updated Phase 2 interactive test to explicitly check for this fix:

```bash
./tests/interactive-dog-feeding-phase2.zsh
```

Expected behavior now includes:

- "Preview pane showing help text (NOT 'command not found')"
- "Full help for selected command (e.g., 'DASH - Project Dashboard')"

## Why This Pattern?

This fix follows the established pattern in flow-cli's codebase:

**Existing example:** [lib/tui.zsh:129-137](lib/tui.zsh#L129-L137)

```bash
# Project picker uses a helper function for fzf preview
--preview="_flow_show_project_preview {}" \
```

**Advantages:**

1. ✅ Functions are available in current shell environment
2. ✅ No need to source plugin repeatedly
3. ✅ Cleaner, more maintainable code
4. ✅ Better performance (no subprocess overhead)
5. ✅ Consistent with existing patterns

## Prevention

- ✅ Added comprehensive test suite (6 tests)
- ✅ Updated manual test guide
- 📝 Documented pattern for future fzf preview implementations

**Guideline for future fzf previews:**
Always use helper functions instead of inline scripts when commands depend on the plugin being loaded.

## Related Issues

This bug affected **Phase 2 (v4.9.0)** features:

- Interactive help browser (`flow help -i`)
- Context-aware help detection

The fix ensures the interactive help browser works as designed for Phase 2 release.

## Next Steps

1. ✅ Bug fixed and tested
2. ✅ Tests passing (6/6 automated + manual verification)
3. ⏳ Include in v4.9.1 release
4. ⏳ Update CHANGELOG.md
5. ⏳ Deploy to GitHub Pages with updated docs

---

**Resolution:** Bug fixed via helper function pattern (18 lines added, 13 lines simplified)
**Impact:** Phase 2 interactive help now fully functional
**Tests:** 6/6 passing
