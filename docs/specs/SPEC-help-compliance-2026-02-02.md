# SPEC: Help Function Compliance System

> **Date:** 2026-02-02
> **Branch:** `feature/help-compliance`
> **Status:** Draft
> **From Audit:** Manual audit of all 12 dispatcher help functions

## Summary

Fix non-compliant help functions across all 12 dispatchers and add an automated compliance checker (shared library + test suite + `flow doctor` integration) to prevent future regressions.

## Problem

An audit of all 12 dispatcher help functions against `docs/CONVENTIONS.md:173-199` found:
- **6/12 compliant** (g, r, mcp, qu, wt, v) - Grade A
- **3/12 partially compliant** (cc, tm, teach) - Grade B
- **1/12 significantly non-compliant** (dot) - Grade C
- **2/12 fully non-compliant** (obs, prompt) - Grade F

Issues include missing required sections, wrong color systems, non-standard box styles, and a rendering bug in `teach help`.

## Scope

### Phase 1: Fix Non-Compliant Help Functions

| Dispatcher | Current Grade | Issues | Fix Effort |
|---|---|---|---|
| **obs** | F | No colors, no sections, wrong function name (`obs_help` not `_obs_help`), plain text | Rewrite |
| **prompt** | F | No colors, no sections, `cat <<EOF` plain text, version number in header | Rewrite |
| **dot** | C | Boxed layout with `FLOW_COLORS[]`, no standard sections, phase status cruft | Major refactor |
| **cc** | B- | Double-line box `╔═╗`, "QUICK START" not "MOST COMMON", no See Also | Moderate |
| **tm** | B- | Double-line box `╔═╗`, "QUICK START" not "MOST COMMON", no emoji markers | Moderate |
| **teach** | B+ | `cat <<EOF` raw ANSI codes not rendering, `FLOW_COLORS[]` instead of `_C_*` | Fix rendering |

### Phase 2: Automated Compliance Checker

Create `lib/help-compliance.zsh` as shared validation logic with two consumers:

1. **`tests/test-help-compliance.zsh`** - Test suite integration (CI)
2. **`flow doctor --help-check`** - CLI integration (on-demand)

### Out of Scope

- Changing the standard itself (CONVENTIONS.md stays as-is)
- Adding new dispatchers
- Modifying help content (only fixing structure/formatting)

## Acceptance Criteria

### Phase 1: Help Fixes

- [ ] All 12 dispatchers use `╭─╮╰─╯` single-line box (45 chars)
- [ ] All 12 dispatchers have `🔥 MOST COMMON` section (green)
- [ ] All 12 dispatchers have `💡 QUICK EXAMPLES` section (yellow)
- [ ] All 12 dispatchers have at least one `📋` categorized section (blue)
- [ ] All 12 dispatchers have `💡 TIP` section (magenta)
- [ ] All 12 dispatchers have `📚 See also` cross-references (dim)
- [ ] All 12 dispatchers use `_C_*` color variables (with fallbacks)
- [ ] All 12 dispatchers use `echo -e` (not `cat <<EOF`) for ANSI rendering
- [ ] `obs` help function renamed from `obs_help()` to `_obs_help()`
- [ ] `teach help` ANSI codes render properly in terminal

### Phase 2: Compliance Checker

- [ ] `lib/help-compliance.zsh` exists with shared validation functions
- [ ] `_flow_check_help_compliance()` validates a single dispatcher
- [ ] `_flow_check_all_help_compliance()` validates all dispatchers
- [ ] 9 compliance rules checked (box, sections, colors, function name, etc.)
- [ ] `tests/test-help-compliance.zsh` passes for all 12 dispatchers
- [ ] `flow doctor --help-check` shows pass/fail per dispatcher
- [ ] Compliance checker integrated into `./tests/run-all.sh`

## Architecture

### Shared Compliance Library

```
lib/help-compliance.zsh
  _flow_help_compliance_check()      # Check single dispatcher
  _flow_help_compliance_check_all()  # Check all dispatchers
  _flow_help_compliance_rules()      # Return rule definitions
```

### Compliance Rules

| # | Rule | Check | Pattern |
|---|---|---|---|
| 1 | Box header exists | grep for `╭` | `╭─.*─╮` |
| 2 | Box footer exists | grep for `╰` | `╰─.*─╯` |
| 3 | MOST COMMON section | grep for emoji+text | `🔥.*MOST COMMON` |
| 4 | QUICK EXAMPLES section | grep for emoji+text | `💡.*QUICK EXAMPLES` |
| 5 | Categorized actions | grep for emoji | `📋` |
| 6 | TIP section | grep for emoji+text | `💡.*TIP` |
| 7 | See Also section | grep for text | `See also\|📚` |
| 8 | Color codes present | grep for ANSI | `\033\[` or `_C_` |
| 9 | Help function naming | function exists | `_<cmd>_help` pattern |

### Integration Points

```
flow doctor --help-check
  └── calls _flow_help_compliance_check_all()
       └── calls _flow_help_compliance_check() per dispatcher
            └── captures help output, runs 9 rules

tests/test-help-compliance.zsh
  └── calls _flow_help_compliance_check_all()
       └── asserts all pass
```

## Implementation Plan

| Step | Description | Files |
|---|---|---|
| 1 | Create `lib/help-compliance.zsh` with 9 rules | `lib/help-compliance.zsh` |
| 2 | Fix `obs` help (rewrite to standard) | `lib/dispatchers/obs.zsh` |
| 3 | Fix `prompt` help (rewrite to standard) | `lib/dispatchers/prompt-dispatcher.zsh` |
| 4 | Fix `dot` help (refactor to standard) | `lib/dispatchers/dot-dispatcher.zsh` |
| 5 | Fix `cc` help (box style + sections) | `lib/dispatchers/cc-dispatcher.zsh` |
| 6 | Fix `tm` help (box style + sections) | `lib/dispatchers/tm-dispatcher.zsh` |
| 7 | Fix `teach` help (rendering + colors) | `lib/dispatchers/teach-dispatcher.zsh` |
| 8 | Create test suite | `tests/test-help-compliance.zsh` |
| 9 | Integrate with `flow doctor` | `commands/doctor.zsh` |
| 10 | Update QUICK-REFERENCE.md version | `docs/help/QUICK-REFERENCE.md` |
| 11 | Update CONVENTIONS.md if needed | `docs/CONVENTIONS.md` |

## Dependencies

- `lib/core.zsh` - Color variable definitions
- `commands/doctor.zsh` - Doctor command for integration
- `tests/run-all.sh` - Test runner for integration

## Open Questions

1. Should the compliance checker also validate `flow help`, `pick help`, and other non-dispatcher help?
2. Should `FLOW_COLORS[]` be deprecated in favor of `_C_*` everywhere, or should the checker accept both?
3. Should `teach` keep its enhanced double-line box given its much larger command surface?

## Review Checklist

- [ ] All 12 dispatchers pass compliance check
- [ ] No existing test regressions
- [ ] `flow doctor --help-check` works
- [ ] Help output visually consistent across all dispatchers
- [ ] QUICK-REFERENCE.md version updated to v6.2.0+

---

**History:**
- 2026-02-02: Initial spec from manual audit of all 12 dispatchers
