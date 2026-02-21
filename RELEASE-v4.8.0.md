# Release Notes: v4.8.0 - CC Unified Grammar

**Release Date:** 2026-01-02
**Type:** Feature Release
**Breaking Changes:** None

---

## 🎯 Overview

Version 4.8.0 introduces **unified grammar** for the `cc` dispatcher, enabling both mode-first and target-first command patterns. Write commands the way that feels natural - both orders work identically!

### Key Highlights

✨ **Flexible Command Order**: `cc opus pick` and `cc pick opus` now work the same
✨ **Explicit HERE Targets**: New `.` and `here` keywords for clarity
✨ **Zero Breaking Changes**: All v4.7.0 patterns still work
✨ **Comprehensive Testing**: 30 new tests, 100% passing

---

## 🚀 New Features

### 1. Unified Grammar - Both Orders Work

You can now write `cc` commands in **either order**:

```bash
# Mode-first (Unified Pattern)
cc opus pick          # Pick project → Opus model
cc yolo flow          # Jump to flow → YOLO mode
cc plan .             # HERE → Plan mode

# Target-first (Natural Reading) ✨ NEW!
cc pick opus          # Pick → Opus (reads naturally!)
cc flow yolo          # Flow → YOLO (intuitive!)
cc . plan             # HERE → Plan (clear intent!)
```

**Both patterns produce identical results.** Use whichever feels natural to you!

### 2. Explicit HERE Targets

Two new keywords for explicit "launch in current directory":

```bash
cc .                  # Short, shell-conventional
cc here               # Readable, self-documenting

# With modes (both orders work!)
cc opus .             # Mode-first
cc . opus             # Target-first ✨
```

### 3. Natural Project Jumping

Direct project jumps now support both orders:

```bash
# Mode-first
cc opus flow          # Opus → jump to flow-cli

# Target-first ✨ NEW!
cc flow opus          # Jump to flow → launch Opus
```

---

## 🔧 Technical Details

### Grammar Specification

**Modes** (HOW to launch):

- `yolo`, `y` - Skip all permissions
- `plan`, `p` - Planning mode
- `opus`, `o` - Opus model
- `haiku`, `h` - Haiku model

**Targets** (WHERE to launch):

- _(empty)_ - HERE (current directory)
- `.`, `here` - Explicit HERE
- `pick` - Project picker (fzf)
- `<project>` - Direct jump to project
- `wt <branch>` - Worktree

### Parsing Rules

1. **2-argument commands**: Both orders work
   - `cc [mode] [target]` ✅
   - `cc [target] [mode]` ✅

2. **3+ argument commands**: Mode-first required
   - `cc yolo wt <branch>` ✅
   - `cc wt <branch> yolo` ❌

3. **Mode precedence**: Reserved keywords take priority
   - `cc opus` → Mode (Opus HERE)
   - `cc pick opus` → Project named "opus" requires explicit `pick`

### Implementation

**Files Changed**:

- `lib/dispatchers/cc-dispatcher.zsh` - Core parsing logic (65 lines added)
- `completions/_cc` - Shell completions (NEW, 134 lines)
- `tests/test-cc-unified-grammar.zsh` - Test suite (NEW, 292 lines)
- `docs/reference/CC-DISPATCHER-REFERENCE.md` - Updated with examples
- `CLAUDE.md` - Updated quick reference
- `README.md` - Updated dispatcher table

**Testing**:

- 30 new unit tests (all passing)
- 7 test groups covering all patterns
- 24 existing cc-dispatcher tests (all passing)
- Zero regressions

---

## 📚 Documentation Updates

All documentation has been updated to show both patterns:

### Help Text

```bash
cc help               # See updated examples
```

Shows side-by-side mode-first and target-first patterns with ✨ markers.

### Reference Docs

- **CC-DISPATCHER-REFERENCE.md**: New "Unified Grammar" section with comparison tables
- **CLAUDE.md**: Updated CC Dispatcher Quick Reference
- **README.md**: Updated Smart Dispatchers table

### Code Comments

- Inline comments explain parsing logic
- Examples in function headers
- Clear documentation of precedence rules

---

## 🔄 Migration Guide

**Good news: No migration needed!**

All v4.7.0 commands work identically in v4.8.0:

```bash
# These all still work exactly as before
cc                    # ✅ Launch HERE
cc pick               # ✅ Picker
cc opus pick          # ✅ Mode-first
cc yolo wt feature    # ✅ Worktree
```

**New options available** (opt-in):

```bash
# Now you can ALSO write:
cc pick opus          # ✨ Target-first
cc .                  # ✨ Explicit HERE
cc flow opus          # ✨ Project + mode
```

---

## 🧪 Testing

### Test Coverage

**New Tests** (test-cc-unified-grammar.zsh):

- ✅ 6 mode-first patterns
- ✅ 4 target-first patterns (NEW!)
- ✅ 6 explicit HERE targets (NEW!)
- ✅ 2 direct project jump patterns
- ✅ 6 short alias patterns
- ✅ 2 edge cases
- ✅ 4 pick with filter patterns

**Total**: 30 tests, 100% passing

### Running Tests

```bash
# Run unified grammar tests
./tests/test-cc-unified-grammar.zsh

# Run all cc dispatcher tests
zsh ./tests/test-cc-dispatcher.zsh

# Run full test suite
./tests/run-all.sh
```

---

## 📊 Performance

**Impact**: Negligible

- Parsing adds ~2 case statements (<1ms overhead)
- No new external commands
- No caching needed
- Total command latency: <10ms (unchanged)

---

## 🐛 Bug Fixes

### Fixed `cc haiku` Error (#162)

**Issue**: `cc haiku` threw "unknown option" error

**Cause**: Missing `eval` statement in `_cc_dispatch_with_mode()`

**Fix**: Added `eval` to properly expand `$mode_args`:

```zsh
# Before (broken):
claude $mode_args

# After (fixed):
eval "claude $mode_args"
```

**Applied to**: 5 locations in dispatcher

---

## 🙏 Acknowledgments

This release implements the unified grammar pattern suggested in previous brainstorming sessions. The implementation prioritizes:

1. **Zero friction** - Both orders work, no migration needed
2. **ADHD-friendly** - Use whichever pattern you remember
3. **Backward compatible** - All v4.7.0 commands unchanged
4. **Well-tested** - 30 new tests, 100% coverage

---

## 📦 Upgrade Instructions

### Via Plugin Manager

```bash
# antidote
antidote update

# zinit
zinit update data-wise/flow-cli

# oh-my-zsh
cd ~/.oh-my-zsh/custom/plugins/flow-cli && git pull
```

### Via Homebrew (coming soon)

```bash
brew upgrade data-wise/tap/flow-cli
```

### Verify Installation

```bash
flow version          # Should show 4.8.0
cc help               # Should show unified grammar examples
cc pick opus          # Should work! (target-first pattern)
```

---

## 🔮 What's Next

See `.STATUS` file for v4.9.0 roadmap:

- Enhanced MCP integration
- Cross-device sync improvements
- Advanced ADHD features

---

## 📞 Support

- **Documentation**: https://data-wise.github.io/flow-cli/
- **Issues**: https://github.com/Data-Wise/flow-cli/issues
- **Tests**: Run `./tests/test-cc-unified-grammar.zsh`

---

**Full Changelog**: https://github.com/Data-Wise/flow-cli/compare/v4.7.0...v4.8.0
