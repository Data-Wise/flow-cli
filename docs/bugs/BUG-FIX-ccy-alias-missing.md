# Bug Fix: Missing `ccy` Alias in Flow Alias Command

**Date:** 2026-01-06
**Status:** ✅ Fixed
**Version:** v4.9.1 (pending)
**Related:** Phase 2 - Alias Reference Command

## Problem

The `flow alias` command didn't show the `ccy` alias (shortcut for `cc yolo`), even though it was defined in the cc-dispatcher.

### User Report

```
fix: ccy is also an alias that flow alias command missed?
```

### Verification

```bash
# ccy is defined
$ grep "alias ccy" lib/dispatchers/cc-dispatcher.zsh
alias ccy='cc yolo'  # Kept by explicit user request

# But flow alias didn't show it
$ flow alias cc
🤖 Claude Code Aliases
  ccp → claude -p (print mode)
  ccr → claude -r (resume session)
  # ❌ ccy missing!
```

## Root Cause

The `ccy` alias was added to the cc-dispatcher ([lib/dispatchers/cc-dispatcher.zsh:643](lib/dispatchers/cc-dispatcher.zsh#L643)) but was never added to the alias reference command ([commands/alias.zsh](commands/alias.zsh)).

The alias command maintains its own curated list of aliases to display (not auto-discovered), so new aliases need to be manually added.

## Solution

Added `ccy` to both the summary view and detailed Claude Code alias section.

### Changes Made

**File:** [commands/alias.zsh](commands/alias.zsh)

1. **Summary view** (`_flow_alias_show_all`):
   - Updated count: "2 aliases" → "3 aliases"
   - Added `ccy` to preview text
   - Updated total count: 28 → 29 custom aliases

2. **Claude category view** (`_flow_alias_show_claude`):
   - Added `ccy` as first alias (most important)
   - Shows: `ccy → cc yolo` with description "YOLO mode (skip permissions)"

3. **Help text** (`_flow_alias_help`):
   - Updated count: "cc (2 aliases)" → "cc (3 aliases)"

### Code Changes

```diff
# Summary view
- echo "🤖 Claude Code (2 aliases)"
+ echo "🤖 Claude Code (3 aliases)"
+ echo "  ccy → cc yolo (YOLO mode - skip permissions)"
  echo "  ccp → claude -p (print mode)"
  echo "  ccr → claude -r (resume session)"

# Detailed view
_flow_alias_show_claude() {
+  printf "  %-6s → %-20s %s\n" "ccy" "cc yolo" "YOLO mode (skip permissions)"
   printf "  %-6s → %-20s %s\n" "ccp" "claude -p" "Print mode (non-interactive)"
   printf "  %-6s → %-20s %s\n" "ccr" "claude -r" "Resume session picker"
}

# Total count
- echo "Total: 28 custom aliases + 8 dispatchers + 226+ git aliases"
+ echo "Total: 29 custom aliases + 8 dispatchers + 226+ git aliases"
```

## Verification

### Manual Test

```bash
$ source flow.plugin.zsh

# Summary view shows ccy
$ flow alias | grep -A5 "Claude Code"
🤖 Claude Code (3 aliases)
  ccy → cc yolo (YOLO mode - skip permissions)
  ccp → claude -p (print mode)
  ccr → claude -r (resume session)
  flow alias cc for details

# Detailed view shows ccy
$ flow alias cc
🤖 Claude Code Aliases
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ccy    → cc yolo              YOLO mode (skip permissions)
  ccp    → claude -p            Print mode (non-interactive)
  ccr    → claude -r            Resume session picker

Tip: Use cc dispatcher for full Claude workflow
See also: cc help for all Claude commands
```

### Automated Test

Updated test suite to verify `ccy` is included:

**File:** [tests/test-phase2-features.zsh](tests/test-phase2-features.zsh)

```diff
# Test 22: Claude category
test_case "Alias: Claude category view" && {
  local output=$(flow_alias cc 2>&1)
  assert_contains "$output" "Claude Code Aliases" "Should show CC header"
+ assert_contains "$output" "ccy" "Should list ccy alias (cc yolo)"
  assert_contains "$output" "ccp" "Should list ccp alias"
  assert_contains "$output" "ccr" "Should list ccr alias"
}
```

**Results:** ✅ All 47 tests pass

## Why This Alias Matters

`ccy` is a frequently-used shortcut for YOLO mode:

- **Common pattern:** `ccy` to launch Claude Code without permission prompts
- **User preference:** Explicitly requested to keep this alias ([cc-dispatcher.zsh:643](lib/dispatchers/cc-dispatcher.zsh#L643))
- **Discoverability:** Users exploring aliases need to see this shortcut

## Files Changed

| File                                                             | Change                                  | Lines       |
| ---------------------------------------------------------------- | --------------------------------------- | ----------- |
| [commands/alias.zsh](commands/alias.zsh)                         | Added `ccy` to summary + detailed views | +4 modified |
| [tests/test-phase2-features.zsh](tests/test-phase2-features.zsh) | Added test assertion for `ccy`          | +1          |

**Total:** 2 files changed, 5 lines modified

## Prevention

**Guideline:** When adding new aliases to dispatchers, remember to also:

1. Add to `commands/alias.zsh` in appropriate category
2. Update count in summary view
3. Update total count
4. Add test assertion
5. Update help text if category count changed

**Checklist for new aliases:**

- [ ] Defined in dispatcher/command file
- [ ] Added to `flow alias <category>` view
- [ ] Added to `flow alias` summary
- [ ] Updated counts (category + total)
- [ ] Test assertion added
- [ ] Verified with `flow alias` and `flow alias <category>`

## Related

This fix completes Phase 2's alias reference feature:

- ✅ Interactive help browser (`flow help -i`) - fixed preview pane bug
- ✅ Alias reference (`flow alias`) - now includes all aliases
- ✅ Context-aware help - working
- ✅ Help cross-references - working
- ✅ Random tips - working

---

**Resolution:** Missing alias added to reference command
**Impact:** Users can now discover `ccy` shortcut via `flow alias`
**Tests:** 47/47 passing
