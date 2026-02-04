# teach deploy v2 — Brainstorm

**Generated:** 2026-02-03
**Context:** flow-cli v6.3.0 (`teach deploy` enhancement)
**Mode:** deep + feature + save
**Duration:** ~10 min

## Overview

Port STAT-545's battle-tested deploy patterns into flow-cli's `teach deploy` command, plus add dry-run, history, rollback, and CI mode. Consolidate the two deploy code paths into one.

## Current Pain Points

1. **Slow PR workflow** (45-90s) — STAT-545 has a 8-15s direct merge script
2. **Generic commit messages** — `"Update: 2026-02-03"` vs smart `content: week-05 lecture, assignment 5`
3. **No deployment tracking** — No history of what was deployed when
4. **No rollback** — Manual `git revert` only
5. **No dry-run** — Can't preview without executing
6. **Two code paths** — `_teach_deploy()` and `_teach_deploy_enhanced()` with inconsistent behavior
7. **No CI support** — Prompts block non-interactive use
8. **No .STATUS integration** — Teaching week / progress not tracked on deploy

## Quick Wins (Phase 0-1)

1. Delete old `_teach_deploy()` dead code (~340 lines removed)
2. Add `--ci` flag + TTY auto-detection
3. Extract shared `_deploy_preflight_checks()`

## Medium Effort (Phase 2-4)

4. Smart commit messages from changed file categories
5. `--direct` flag for direct merge mode (8-15s)
6. Branch divergence detection + recovery
7. `--dry-run` preview mode

## Larger Effort (Phase 5-6)

8. Deploy history log (`.flow/deploy-history.yml`)
9. `--rollback [N]` with interactive picker
10. `.STATUS` auto-updates (teaching week, progress, deploy count)

## Options Considered

### Option A: Phase It (rejected by user)
Port STAT-545 first, then add new features.
**Pros:** Smaller PRs, faster feedback
**Cons:** More branches, more merge overhead

### Option B: All at Once (selected)
Single feature branch with everything.
**Pros:** One implementation pass, coherent design
**Cons:** Larger PR, more risk

### Option C: Skip Rollback (not selected)
Defer rollback + history to a future release.
**Pros:** Simpler scope
**Cons:** History is needed for rollback, and both are useful independently

## Recommended Path

All 8 features + 1 refactor in a single `feature/teach-deploy-v2` branch. Implementation follows a dependency-ordered 7-phase plan where CI mode comes first (every feature needs it), then smart commits, direct merge, dry-run, history+rollback, .STATUS updates, and finally help/docs.

## Key Design Decisions

1. **`--direct` replaces `--direct-push`** — shorter name, `--direct-push` kept as alias
2. **deploy-history.yml uses append-only writes** — no yq rewrite of entire file
3. **Rollback uses `git revert`** — forward rollback, not destructive reset
4. **CI mode auto-detects from TTY** — plus explicit `--ci` flag override
5. **Smart commit messages are overridable** — `--message "text"` takes precedence
6. **.STATUS updates are non-destructive** — skip if file doesn't exist

## Next Steps

1. [ ] Create worktree: `feature/teach-deploy-v2`
2. [ ] Implement Phase 0: Consolidation
3. [ ] Implement Phase 1-6 sequentially
4. [ ] Run full test suite
5. [ ] Update help + CLAUDE.md
6. [ ] PR to dev
