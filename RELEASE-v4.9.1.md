# Release Notes: v4.9.1 - Phase 2 Bug Fixes

**Release Date:** 2026-01-06
**Type:** Bug Fix Release
**Previous Version:** v4.9.0
**Focus:** Two critical UX bugs discovered during Phase 2 dogfooding

---

## Overview

v4.9.1 fixes two bugs discovered while dogfooding the Phase 2 Interactive Help System (v4.9.0). All bugs were found through actual usage and reported by the primary user. All fixes include comprehensive tests and documentation.

**Summary:**

- ✅ 2 bugs fixed (help preview, missing alias)
- ✅ 47/47 tests passing
- ✅ 7 new/updated tests added
- ✅ 2 detailed bug fix reports (339 lines total)
- ✅ Zero breaking changes

---

## Bug Fixes

### 🐛 Bug #1: Help Browser Preview Pane Shows "Command not found"

**Symptom:**

```bash
$ flow help -i
# Preview pane showed:
Command not found: dash
Command not found: work
Command not found: finish
```

**Root Cause:**
The fzf `--preview` option runs commands in a new isolated subshell that doesn't have the flow-cli plugin loaded. Inline preview scripts couldn't access flow-cli commands.

**Solution:**
Created `_flow_show_help_preview()` helper function that runs in the current shell environment (where plugin is loaded), following the existing pattern from `_flow_show_project_preview()` in `lib/tui.zsh`.

**Files Changed:**

- `lib/help-browser.zsh`: +18 lines (helper), -13 lines (simplified preview script)

**Tests Added:**

- `tests/test-help-browser-preview.zsh`: 6 automated tests
  - Preview function exists
  - Regular commands work (dash)
  - Dispatchers work (r)
  - All 8 dispatchers tested
  - Graceful handling of nonexistent commands
  - ANSI code stripping

**Result:** Preview pane now shows full help text for all commands ✅

**Documentation:** [BUG-FIX-help-browser-preview.md](BUG-FIX-help-browser-preview.md) (168 lines)

---

### 🐛 Bug #2: Missing `ccy` Alias in Reference Command

**Symptom:**

```bash
$ flow alias cc
🤖 Claude Code Aliases
  ccp → claude -p (print mode)
  ccr → claude -r (resume session)
  # ❌ ccy missing!
```

**Root Cause:**
The `ccy` alias (shortcut for `cc yolo`) was defined in `lib/dispatchers/cc-dispatcher.zsh` but never added to the alias reference command in `commands/alias.zsh`. The alias command maintains a curated list (not auto-discovered).

**Solution:**
Added `ccy` to both summary and detailed Claude Code alias views, updated all counts.

**Files Changed:**

- `commands/alias.zsh`:
  - Summary view: Updated "2 aliases" → "3 aliases"
  - Detail view: Added `ccy → cc yolo` with description
  - Total count: Updated "28 custom aliases" → "29 custom aliases"

**Tests Updated:**

- `tests/test-phase2-features.zsh` Test 22: Added assertion for `ccy`

**Result:** All Claude Code aliases now visible in reference ✅

**Documentation:** [BUG-FIX-ccy-alias-missing.md](BUG-FIX-ccy-alias-missing.md) (171 lines)

---

## Manual Testing

Both bug fixes were verified manually:

### Bug #1 - Help Browser Preview

```bash
$ flow help -i
# Navigate through commands
# ✅ Preview pane shows help text
# ✅ No "command not found" errors
```

### Bug #2 - Missing Alias

```bash
$ flow alias cc
# ✅ Shows ccy → cc yolo (YOLO mode - skip permissions)
# ✅ Count shows "3 aliases"
```

---

## Test Results

### Automated Tests

```bash
$ ./tests/test-phase2-features.zsh

╔════════════════════════════════════════════════════════════════╗
║ TEST SUMMARY
╚════════════════════════════════════════════════════════════════╝

✓ ALL TESTS PASSED

  Total:  47
  Passed: 47
  Failed: 0
```

**Test Breakdown:**

- 10 context detection tests (R, Quarto, Node, Python, Git, general)
- 5 edge case tests (empty files, invalid JSON, multiple markers)
- 2 help browser tests (function exists, fzf check)
- 11 alias command tests (all categories + routing)
- 4 context-aware help tests (banner display only)
- 4 flow command integration tests
- 4 E2E workflow tests
- 5 regression tests (existing features)
- 2 performance tests (< 100ms)

**New/Updated Tests:**

- 6 new preview tests (test-help-browser-preview.zsh)
- 1 updated alias test (Test 22 - verify `ccy`)

### Manual Tests

Updated `tests/interactive-dog-feeding-phase2.zsh` with expected behaviors:

- Preview pane showing help text (NOT "command not found")
- All 3 Claude aliases visible (`ccy`, `ccp`, `ccr`)

---

## Impact

### User Experience Improvements

1. **Interactive Help Browser** - Now fully functional
   - Users can explore all commands interactively
   - Preview pane provides instant context
   - Faster learning curve for new users

2. **Alias Discoverability** - Complete reference
   - All shortcuts visible in `flow alias`
   - Users discover `ccy` for YOLO mode
   - Better documentation of available shortcuts

### Technical Improvements

1. **Helper Function Pattern** - Established best practice
   - Use helper functions for fzf previews
   - Avoid inline scripts that need plugin context
   - Pattern documented for future fzf implementations

2. **Alias Maintenance Checklist** - Prevention
   - When adding aliases to dispatchers, also update alias.zsh
   - Update counts in summary view
   - Add test assertions
   - Documented in BUG-FIX-ccy-alias-missing.md

---

## Files Changed

| File                                       | Change                  | Lines       |
| ------------------------------------------ | ----------------------- | ----------- |
| `lib/help-browser.zsh`                     | Preview helper function | +18, -13    |
| `commands/alias.zsh`                       | Added `ccy` alias       | +4 modified |
| `tests/test-help-browser-preview.zsh`      | New test suite          | +109 new    |
| `tests/test-phase2-features.zsh`           | Updated alias test      | +1          |
| `tests/interactive-dog-feeding-phase2.zsh` | Updated expectations    | +2          |

**Total:** 5 files changed, 121 lines added

---

## Documentation

Two comprehensive bug fix reports created:

1. **BUG-FIX-help-browser-preview.md** (168 lines)
   - Problem, root cause, solution, verification
   - Code changes, test suite, manual testing
   - Why the helper function pattern works

2. **BUG-FIX-ccy-alias-missing.md** (171 lines)
   - Problem, root cause, solution, verification
   - Prevention checklist for future alias additions
   - Complete test coverage

**Total Documentation:** 339 lines

---

## Breaking Changes

**None.** This is a pure bug fix release.

All existing functionality remains unchanged:

- ✅ Existing aliases still work
- ✅ Help output format unchanged
- ✅ All commands backward compatible
- ✅ No configuration changes required

---

## Upgrade Instructions

### Via Homebrew (Recommended)

```bash
brew upgrade data-wise/tap/flow-cli
```

### Via Plugin Manager (antidote, zinit, oh-my-zsh)

```bash
# Update plugin
antidote update data-wise/flow-cli

# Reload shell
source ~/.zshrc
```

### Manual Installation

```bash
cd /path/to/flow-cli
git pull origin main
source flow.plugin.zsh
```

---

## What's Next

### v4.9.2 (Future)

- Additional bug fixes from continued dogfooding
- Performance optimizations
- Documentation improvements

### v4.10.0 (Future - Phase 3)

- Enhanced onboarding experience
- `install.sh` script for one-line installation
- First-run wizard
- Enhanced `flow doctor --fix`

**Reference:** [IMPLEMENTATION-PLAN-v4.9.0.md](IMPLEMENTATION-PLAN-v4.9.0.md)

---

## Acknowledgments

All three bugs were discovered through actual usage (dogfooding) during Phase 2 testing. This demonstrates the value of manual testing and real-world usage validation.

**Testing Methodology:**

1. Ship Phase 2 features (v4.9.0)
2. Use features in daily workflow
3. Encounter bugs in real usage
4. Fix bugs with tests + documentation
5. Release bug fix version (v4.9.1)

This rapid feedback loop (ship → dogfood → fix → release) ensures high-quality UX.

---

**Full Changelog:** [CHANGELOG.md](CHANGELOG.md)
**Phase 2 Release:** [v4.9.0](https://github.com/Data-Wise/flow-cli/releases/tag/v4.9.0)
**Repository:** https://github.com/Data-Wise/flow-cli
