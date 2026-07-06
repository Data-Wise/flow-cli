# flow-cli Restructure Decision Report

**Date:** 2026-07-06  
**Scope:** Make flow-cli maintainable without breaking users  
**Full proposal:** `docs/specs/SPEC-flow-cli-restructure-2026-07-06.md`

---

## ONE-SENTENCE BOTTOM LINE

Split flow-cli into `flow-cli-core` + `flow-cli-extensions`, but only after first refactoring the two oversized dispatchers (`teach`, `em`) inside the current repo.

---

## WHY THIS MATTERS NOW

flow-cli has grown past the size where one repo is the cheapest answer:

```
Problem scale (source only, excluding generated site/ and node_modules)

Total source files . . . . . . . . . . ~180 .zsh files
Largest dispatcher . . . . . . . . . . 5,611 lines (teach)
Second-largest . . . . . . . . . . . . 3,214 lines (email)
Doctor command . . . . . . . . . . . . 2,027 lines
test files . . . . . . . . . . . . . . 231
Full CI suite . . . . . . . . . . . .  75 blocking runs
Man pages . . . . . . . . . . . . . .  23 (already collided with R.1)
```

The two biggest dispatchers alone are larger than many whole ZSH plugins.

---

## OPTION COMPARISON

| Criterion | A: Move to sibling repos | B: Core + extensions | Winner |
|-----------|--------------------------|----------------------|--------|
| Shrinks flow-cli | Large | Medium | A |
| Keeps ZSH ownership in one place | No (spreads to craft/aiterm/atlas) | Yes | B |
| User install stays simple | No (many plugins) | Yes (2 formulae) | B |
| Release coordination | Hard (N repos) | Moderate (2 repos) | B |
| Backward compatibility | Hard | Manageable | B |
| Time to first results | Slow | Fast | B |
| Fits dev-tools stack layers | Poor | Strong | B |

**Score:** Option B wins 6 of 7 criteria.

---

## RECOMMENDED PLAN

```
PHASE 1  (v7.16.x)  --  REFACTOR IN PLACE  [teach DONE, email pending]
  |-- Break teach-dispatcher.zsh into 10 modules  [DONE] 307-line loader
  |-- Break email-dispatcher.zsh into 3-4 modules  [NEXT]
  |-- Make doctor.zsh a plugin-health framework
  |-- Archive stale generated docs
  |-- Goal: teach < 2,000 lines, email < 1,500 lines

PHASE 2  (v8.0.0)  --  SPLIT REPOS
  |-- Create Data-Wise/flow-cli-core
  |-- Create Data-Wise/flow-cli-extensions
  |-- Create flow-cli-teach and flow-cli-email packages
  |-- Keep "brew install flow-cli" working via meta-formula

PHASE 3  (v8.x)  --  MATURE
  |-- Deprecate meta-formula
  |-- Add "flow extension install <name>"
  |-- Consider merging teach into craft only if craft wants it
```

---

## TOP 3 RISKS

| Risk | How we avoid it |
|------|-----------------|
| Existing users break | Keep a transitional `flow-cli` Homebrew formula that installs core + extensions |
| Doctor check fragmentation | Extensions register checks; core runs them |
| Test harness drifts | Core owns the harness; extensions vendor it via git subtree |

---

## ONE THING TO DO NOW

Create a worktree `feature/email-dispatcher-restructure` and write characterization tests for `email-dispatcher.zsh` before splitting it into `lib/dispatchers/em/*.zsh` modules.

---

## FILES TO REVIEW

- Full proposal: `docs/specs/SPEC-flow-cli-restructure-2026-07-06.md`
- This report: `docs/specs/flow-cli-restructure-report.md`
- Related prior art: `docs/specs/SPEC-dot-rename-split-2026-02-14.md`
