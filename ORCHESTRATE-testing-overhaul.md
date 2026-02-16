# Testing Overhaul Orchestration Plan

> **Branch:** `feature/testing-overhaul`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-testing-overhaul`
> **Proposal:** `~/PROPOSAL-testing-overhaul-2026-02-16.md`

## Objective

Upgrade flow-cli's test infrastructure (Option C) so tests catch behavioral errors,
not just function existence. Add assertion helpers, mock registry, subshell isolation,
and convert key test files from existence-only to behavioral assertions.

## Phase Overview

| Phase | Task | Agent | Priority | Status |
| ----- | ---- | ----- | -------- | ------ |
| 1a | Add assertion helpers to `tests/test-framework.zsh` | agent-1 | High | ✅ Done |
| 1b | Add mock registry to `tests/test-framework.zsh` | agent-1 | High | ✅ Done |
| 1c | Add subshell isolation helper | agent-1 | High | ✅ Done |
| 2a | Convert `tests/test-work.zsh` to behavioral assertions | agent-2 | High | ✅ Done |
| 2b | Convert dispatcher tests to behavioral assertions | parallel | Medium | ✅ Done (30+ files) |
| 2c | Convert remaining tests to shared framework | parallel | Medium | ✅ Done |
| 3 | Add dogfood smoke test: `tests/dogfood-test-quality.zsh` | agent-2 | Medium | ✅ Done |
| 4 | Run full test suite, verify 45/45 still passes | any | High | ✅ 45/45 pass |

## Parallel Execution Strategy

**Batch 1 (sequential):** Phase 1a + 1b + 1c -- framework helpers (must finish first)
**Batch 2 (parallel):** Phases 2a, 2b, 2c -- three agents convert test files simultaneously
**Batch 3 (sequential):** Phase 3 + 4 -- dogfood test + final verification

## Key Files

| File | Action |
|------|--------|
| `tests/test-framework.zsh` | ADD: `assert_exit_code`, `assert_output_contains`, `assert_output_excludes`, `create_mock`, `assert_mock_called`, `assert_mock_args`, `reset_mocks`, `run_isolated` |
| `tests/test-work.zsh` | CONVERT: Replace existence checks with behavioral assertions using new framework |
| `tests/test-dispatchers.zsh` | CONVERT: Replace existence checks with output/exit code assertions |
| `tests/test-core.zsh` | CONVERT: Replace existence checks with behavioral assertions |
| `tests/dogfood-test-quality.zsh` | NEW: Smoke test that scans test files for anti-patterns |

## Anti-Patterns to Eliminate

1. `if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]` -- always passes
2. `if type X &>/dev/null; then pass` -- only checks existence
3. Tests that run commands but don't check output
4. Tests that mock functions but don't verify mock was called
5. Tests that share global state between test functions

## Acceptance Criteria

- [x] `tests/test-framework.zsh` has assertion helpers (14 functions)
- [x] `tests/test-framework.zsh` has mock registry (5 functions)
- [x] `tests/test-work.zsh` uses behavioral assertions (no existence-only tests)
- [x] 30+ dispatcher/integration tests converted to shared framework
- [x] `tests/dogfood-test-quality.zsh` scans for anti-patterns (4 categories)
- [x] Full test suite: 45/45 passing (1 expected timeout)
- [x] No regressions in existing tests

## Dogfood Scanner Results (post-conversion)

| Anti-pattern | Before | After |
|---|---|---|
| Permissive exit codes | 2 in 2 files | **0 (CLEAN)** |
| Existence-only tests | 11 in 6 files | 11 in 6 files |
| Unused output captures | 21 in 8 files | **8 in 4 files** |
| Inline frameworks | 80 in 30 files | **2 in 1 file** |

## Remaining (Future Work)

- 1 file with inline framework: `test-course-planning-docs-unit.zsh`
- 11 existence-only tests across E2E/integration files (by design)
- 8 unused output captures in 4 files (edge cases)

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-testing-overhaul
claude
# Then: "implement the ORCHESTRATE plan with parallel agents"
```
