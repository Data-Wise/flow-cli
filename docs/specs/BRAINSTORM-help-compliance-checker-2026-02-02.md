# Help Compliance Checker - Brainstorm

**Generated:** 2026-02-02
**Context:** flow-cli help function standards enforcement
**Decision:** Option C (shared library + tests + CLI)

## Problem

12 dispatchers, each with a `_*_help()` function. Standards defined in `docs/CONVENTIONS.md:173-199` but no automated enforcement. Result: 6 non-compliant dispatchers drifted over time.

## Options Considered

### Option A: Test-Only
- `tests/test-help-compliance.zsh`
- CI catches regressions
- **Rejected:** No on-demand check for developers

### Option B: CLI-Only (`flow doctor --help-check`)
- Visual pass/fail per dispatcher
- ADHD-friendly colored output
- **Rejected:** No CI protection

### Option C: Both (Shared Core) ✅ SELECTED
- `lib/help-compliance.zsh` shared validation
- Tests call it -> CI protection
- `flow doctor` calls it -> on-demand check
- Single source of truth for rules

### Option D: Pre-commit Hook
- Block commits breaking standards
- **Rejected:** Annoying, slows commits

## What the Checker Validates (9 Rules)

| # | Rule | Pattern |
|---|---|---|
| 1 | Box header | `╭─.*─╮` |
| 2 | Box footer | `╰─.*─╯` |
| 3 | MOST COMMON | `🔥.*MOST COMMON` |
| 4 | QUICK EXAMPLES | `💡.*QUICK EXAMPLES` |
| 5 | Categorized actions | `📋` |
| 6 | TIP section | `💡.*TIP` |
| 7 | See Also | `See also` or `📚` |
| 8 | Color codes | ANSI escapes present |
| 9 | Function naming | `_<cmd>_help` exists |

## Current Audit Results

| Dispatcher | Grade | Issues |
|---|---|---|
| g | A | None |
| r | A | None |
| mcp | A | None |
| qu | A | None |
| wt | A | None |
| v | A- | See Also uses "EXISTING COMMANDS" |
| teach | B+ | ANSI not rendering (cat <<EOF), FLOW_COLORS |
| cc | B- | Double-line box, no MOST COMMON, no See Also |
| tm | B- | Double-line box, no MOST COMMON, no emoji |
| dot | C | Fully boxed layout, FLOW_COLORS, no standard sections |
| obs | F | Plain text, no colors, wrong function name |
| prompt | F | Plain cat <<EOF, no colors, no sections |

## Quick Reference Version Staleness

`docs/help/QUICK-REFERENCE.md` shows `v5.18.0-dev` but project is `v6.2.0`.

## Next Steps

1. Implement in worktree: `~/.git-worktrees/flow-cli/feature-help-compliance`
2. Start with `lib/help-compliance.zsh` (shared rules)
3. Fix dispatchers from worst to best (obs, prompt, dot, cc, tm, teach)
4. Add test suite and doctor integration
5. PR to dev
