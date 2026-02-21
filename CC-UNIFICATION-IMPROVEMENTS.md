# CC Dispatcher Unification Improvements

**Date:** 2026-01-02
**Version:** 4.7.1 (proposed)

## Problem

The `cc` dispatcher supported **two patterns** for mode chaining:

### Pattern 1: Unified (Mode First)

````bash
cc yolo wt feature    # ✅ Mode → Target → Args
cc opus pick          # ✅ Mode → Target
cc plan wt pick       # ✅ Mode → Target → Subtarget
```text

### Pattern 2: Legacy (Target First)

```bash
cc wt yolo feature    # 🔄 Target → Mode → Args
cc wt opus feature    # 🔄 Target → Mode → Args
```bash

**Result:** Two mental models, confusion, dual code paths

---

## Solution Applied

### 1. **Deprecation Warnings Added** ✅

Legacy pattern now shows helpful warnings:

```bash
$ cc wt yolo feature
⚠️  Deprecated: Use 'cc yolo wt feature' instead of 'cc wt yolo feature'
# ... continues to work, but user is informed
```diff

**Files Changed:**

- `lib/dispatchers/cc-dispatcher.zsh` (lines 351-378)

### 2. **Documentation Updated** ✅

**Main Help (`cc help`):**

- Unified pattern shown first
- Legacy pattern marked as deprecated
- Clear migration path provided

**Worktree Help (`cc wt help`):**

- Emphasizes "Mode First!" pattern
- Shows deprecated commands with migration hints
- Updated examples to use unified pattern

### 3. **Alias Deprecation** ✅

- `ccwy` (cc wt yolo) marked deprecated
- Recommended replacement: `ccy wt <branch>`

---

## Migration Guide

### For Users

**Old Pattern (still works, shows warning):**

```bash
cc wt yolo feature   # ⚠️  Shows deprecation warning
cc wt plan feature   # ⚠️  Shows deprecation warning
cc wt opus feature   # ⚠️  Shows deprecation warning
ccwy feature         # ⚠️  Shows deprecation warning
```text

**New Pattern (recommended):**

```bash
cc yolo wt feature   # ✅ Mode first!
cc plan wt feature   # ✅ Mode first!
cc opus wt feature   # ✅ Mode first!
ccy wt feature       # ✅ Mode first!
```text

### Command Matrix

| Old Command            | New Command            | Status        |
| ---------------------- | ---------------------- | ------------- |
| `cc wt yolo <branch>`  | `cc yolo wt <branch>`  | ⚠️ Deprecated |
| `cc wt plan <branch>`  | `cc plan wt <branch>`  | ⚠️ Deprecated |
| `cc wt opus <branch>`  | `cc opus wt <branch>`  | ⚠️ Deprecated |
| `cc wt haiku <branch>` | `cc haiku wt <branch>` | ⚠️ Deprecated |
| `ccwy <branch>`        | `ccy wt <branch>`      | ⚠️ Deprecated |

---

## Unified Pattern Reference

```yaml
cc [mode] [target] [args]

Modes:
  (none)   → acceptEdits (default)
  yolo|y   → dangerously-skip-permissions
  plan|p   → plan mode
  opus|o   → Opus model
  haiku|h  → Haiku model

Targets:
  (none)     → HERE (current directory)
  pick       → Project picker
  wt <br>    → Worktree (create or switch)
  <project>  → Direct jump to project

Examples:
  cc                    → Launch here (default)
  cc yolo               → Launch here (YOLO)
  cc opus pick          → Pick project (Opus)
  cc haiku wt feature   → Worktree (Haiku)
  cc plan wt pick       → Pick worktree (Plan mode)
```yaml

---

## Benefits

1. **One Mental Model:** Always mode → target → args
2. **Predictable:** Same pattern everywhere
3. **Composable:** Easy to combine modes and targets
4. **Discoverable:** Help text shows clear patterns
5. **Backward Compatible:** Old pattern still works (with warnings)

---

## Future (v5.0)

**Full Removal of Legacy Pattern:**

- Remove lines 342-378 in `_cc_worktree()`
- Remove `ccwy` alias
- Simplify code (~40 lines removed)
- Single code path = easier maintenance

**Estimated Timeline:** 3-6 months after deprecation warnings

---

## Testing

```bash
# Reload dispatcher
source ~/.config/zsh/.zshrc

# Test deprecation warnings
cc wt yolo test-branch    # Should show warning
cc wt plan test-branch    # Should show warning

# Test unified pattern (no warnings)
cc yolo wt test-branch    # Clean output
cc plan wt test-branch    # Clean output
cc opus wt test-branch    # Clean output
cc haiku wt test-branch   # Clean output

# Test help
cc help          # Should show unified pattern first
cc wt help       # Should show deprecation section
````

---

## Related Files

- `lib/dispatchers/cc-dispatcher.zsh` - Main implementation
- `docs/reference/CC-DISPATCHER-REFERENCE.md` - Full docs (needs update)
- `CLAUDE.md` - Project reference (needs update)
- `README.md` - Quick start (needs update)

---

## Checklist

- [x] Add deprecation warnings to legacy pattern
- [x] Update main help text
- [x] Update worktree help text
- [x] Mark `ccwy` alias as deprecated
- [ ] Update CC-DISPATCHER-REFERENCE.md
- [ ] Update CLAUDE.md examples
- [ ] Update README.md
- [ ] Add to CHANGELOG.md
- [ ] Test all patterns
- [ ] Create v4.7.1 release

---

**Summary:** Soft deprecation approach maintains backward compatibility while guiding users toward the unified "mode-first" pattern. Full removal planned for v5.0.
