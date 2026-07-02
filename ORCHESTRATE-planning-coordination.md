# planning-coordination — Orchestration Plan

> **Branch:** `feature/planning-coordination`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-planning-coordination`
> **Spec:** `docs/specs/SPEC-planning-coordination-2026-07-01.md`
> **Brainstorm:** `docs/specs/BRAINSTORM-planning-coordination-2026-07-01.md`
> **Version Target:** v7.14.0

## Objective

Refactor flow-cli's planning-command duplication (single `.STATUS` accessor,
project-path resolver, project-suggester; fix the `$path`→`project_path` bug)
and add an atlas-agenda source to the schedule engine so `agenda`/`dash`/
`morning` surface research deadlines (atlas `Task.dueDate`) merged with the
existing `.STATUS`/teaching schedule — graceful-degrading when atlas is absent.

**Cross-repo:** atlas (Track B) and obsidian-cli-ops (Track D) are
**contract-only** here (SPEC §7). Do NOT implement them in this worktree; they
get their own specs. This worktree ships Tracks A + C.

## Phase Overview

| Phase | Increment | Priority | Effort | Status |
|-------|-----------|----------|--------|--------|
| 1 | Track A — internal refactor + bug fix | High | ~2-3h | |
| 2 | Track C — atlas agenda source + contract | High | ~2-3h | |
| 3 | Documentation & Discoverability | High | ~1-2h | |

## Phase 1: Track A — flow-cli internal refactor + bug fix

**Scope:** De-duplicate planning helpers onto shared accessors in `lib/core.zsh`;
fix the confirmed `$path` bug; route `agenda` through the shared schedule engine.
TDD — write the red unit tests first.

- [ ] 1.1 **Red tests first:** `tests/test-status-field-accessor.zsh`,
      `tests/test-project-path-resolver.zsh`, `tests/test-suggest-project.zsh`
      (register in `tests/run-all.sh`)
- [ ] 1.2 Add `_flow_status_field <root> <field>` to `lib/core.zsh`
      (handles `## Field:` + `field:` dialects; strips `%`)
- [ ] 1.3 Add `_flow_resolve_project_path <name>` — merges
      `_dash_find_project_path` (`dash.zsh:1284`) + `_flow_get_project_fallback`
      (`atlas-bridge.zsh:370`); **always emits `project_path=`**
- [ ] 1.4 Add `_flow_suggest_project` — one active/priority scan replacing the 5
      reimplementations (`dash.zsh:181`, `:1139`, `morning.zsh:144`, `adhd.zsh`
      `next`, `js`)
- [ ] 1.5 **Bug fix (G2):** `morning.zsh:83`, `adhd.zsh:103` — read
      `$project_path` not `$path` (via the new resolver); restores broken
      focus/progress/icon lookups
- [ ] 1.6 Migrate call sites: `dash.zsh:1325`, `capture.zsh:406`,
      `atlas-bridge.zsh:836` → `_flow_status_field`
- [ ] 1.7 Route `agenda` (`agenda.zsh:62`) through `_schedule_window_records`
      (`schedule.zsh:549`); keep `_schedule_classify` for bucketing
- [ ] 1.8 Green: new unit suites + `tests/integration/agenda-merged-sources.zsh`
      (STATUS+teach half); full `./tests/run-all.sh`

**Key files:** `lib/core.zsh` (update), `commands/{morning,adhd,dash,capture,agenda}.zsh` (update), `lib/atlas-bridge.zsh` (update), `tests/test-status-field-accessor.zsh` / `tests/test-project-path-resolver.zsh` / `tests/test-suggest-project.zsh` (NEW)

## Phase 2: Track C — atlas agenda source + contract

**Scope:** New capability-probed schedule source that merges atlas records;
pin the proposed atlas contract. TDD — red first.

- [ ] 2.1 **Red tests first:** `tests/test-schedule-atlas-source.zsh`,
      `tests/e2e-agenda-atlas.zsh` (register in `run-all.sh`)
- [ ] 2.2 Add `_schedule_atlas_items <window>` in `lib/schedule.zsh`;
      capability cache `_FLOW_ATLAS_HAS_AGENDA` (mirror `_FLOW_ATLAS_HAS_SCHEDULE`);
      call `_flow_atlas_json agenda "$window"`; map to
      `date|label|type|project|recurrence|source` with `source=atlas`
- [ ] 2.3 Wire into `_schedule_collect` (`schedule.zsh:378`) alongside
      `_schedule_parse_status` + `_schedule_teach_items`; **no-op when absent**
- [ ] 2.4 `at` dispatcher: `agenda` JSON passthrough in `lib/atlas-bridge.zsh`
- [ ] 2.5 Extend `docs/ATLAS-CONTRACT.md`: proposed `atlas task list --format json`
      + `atlas agenda [today|week|--all] --format json`; bump contract version;
      extend `tests/test-atlas-contract.zsh`
- [ ] 2.6 Green: dependency + e2e + full integration
      (`agenda-merged-sources.zsh` now with atlas third source, dedupe on
      `date|label|project`, no double-count)

**Key files:** `lib/schedule.zsh` (update), `lib/atlas-bridge.zsh` (update), `docs/ATLAS-CONTRACT.md` (update), `tests/test-schedule-atlas-source.zsh` / `tests/e2e-agenda-atlas.zsh` (NEW), `tests/test-atlas-contract.zsh` / `tests/integration/agenda-merged-sources.zsh` (extend)

## Documentation & Discoverability (REQUIRED — final phase)

Per SPEC §6 — currency-check each file before editing; update genuine deltas only.

- [ ] Guide — `docs/reference/MASTER-DISPATCHER-GUIDE.md` (atlas source + degradation)
- [ ] Guide — `docs/guides/AGENDA-SCHEDULE-GUIDE.md` (data-source diagram + merged example w/ real captured output — memory `capture-real-agenda-output-for-docs`)
- [ ] API ref — `docs/reference/MASTER-API-REFERENCE.md` (`_flow_status_field`, `_flow_resolve_project_path`, `_flow_suggest_project`, `_schedule_atlas_items`)
- [ ] REFCARD — `docs/help/QUICK-REFERENCE.md` (agenda spans research + dev)
- [ ] Contract — `docs/ATLAS-CONTRACT.md` version bump (done in Phase 2; verify)
- [ ] CHANGELOG — `CHANGELOG.md` + `docs/CHANGELOG.md` `[Unreleased]`, **mirrored**
- [ ] CLAUDE.md — refresh test-file/suite counts after new suites
- [ ] Website — `mkdocs build --strict` 0 warnings (no nav change expected)
- [ ] Hygiene — mark `docs/specs/SPEC-agenda-schedule-2026-06-13.md` **Implemented**
- [ ] `/craft:docs:lint` clean
- Demo — N/A (no new user-facing command surface; extends existing `agenda`)
- Catalog/hub — N/A (no new command/skill/agent)

## Friction Prevention

- **Context first:** read this ORCHESTRATE file + the SPEC before any edit.
- **Verify location:** `git worktree list` + `pwd` — confirm you are in the
  worktree, not the main repo. Branch must be `feature/planning-coordination`.
- **No new code files on dev:** all code lands here on the feature branch.
- **Red-first:** every new test starts failing; carry
  `# TODO(author): delete if not contract-bearing` until the contract is confirmed.
- **Graceful degradation is a hard requirement:** Track C must be a silent
  no-op with no/older atlas — prove it (dogfood with atlas disabled).
- **STOP after each phase** and confirm before proceeding.
- Portability (memory `macos-only-shell-isms-break-linux-ci`): no `sed -i ''`,
  `stat -f`, `date -j`, `exec {var}>`; POSIX-portable for Linux CI.

## Acceptance Criteria (SPEC §8)

- [ ] `source flow.plugin.zsh` — clean load, no errors
- [ ] `./tests/run-all.sh` — green (1 expected interactive/tmux timeout); new suites pass; CLAUDE.md counts updated
- [ ] Dogfood **no atlas**: `agenda`/`dash`/`morning` identical to pre-change (degradation proven)
- [ ] Dogfood **stub atlas agenda**: research deadlines merged; `$path` fix restores focus/progress
- [ ] `mkdocs build --strict` — 0 warnings
- [ ] `/craft:docs:lint` clean
- [ ] Documentation & Discoverability phase complete

## Commit Strategy

- Phase 1: `refactor(planning): shared .STATUS/project accessors + $path bug fix` (+ `test:` for red suites)
- Phase 2: `feat(agenda): merge atlas agenda source into schedule engine` (+ `docs(contract):` for ATLAS-CONTRACT)
- Phase 3: `docs(planning): agenda/dispatcher/API guides + CHANGELOG`

## Verification (after each phase)

```bash
cd ~/.git-worktrees/flow-cli/feature-planning-coordination
source flow.plugin.zsh          # clean load
./tests/run-all.sh              # full suite
mkdocs build --strict           # docs (Phase 3)
```

## Integrate (after all phases)

```bash
git fetch origin dev && git rebase origin/dev
./tests/run-all.sh
gh pr create --base dev
# after merge: git worktree remove ~/.git-worktrees/flow-cli/feature-planning-coordination
# delete ORCHESTRATE-planning-coordination.md as part of merge cleanup
```

## Session Instructions

### Context

You are in the **flow-cli repo worktree** for the `planning-coordination`
feature. The SPEC (`docs/specs/SPEC-planning-coordination-2026-07-01.md`) has
full design details; the BRAINSTORM has the ecosystem rationale. Tracks B/D are
out of scope — contract-only.

### How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-planning-coordination
claude
```

On session start, paste:

> Read `ORCHESTRATE-planning-coordination.md` and the spec at
> `docs/specs/SPEC-planning-coordination-2026-07-01.md`. Confirm you are in the
> worktree (`git worktree list`, `pwd`, branch = `feature/planning-coordination`).
> Then start **Phase 1** using TDD (red tests first). STOP and confirm after
> each phase before proceeding.

### Phase-by-Phase

1. Read the current state of each file listed in the phase.
2. Write the red tests first, then implement per the SPEC design.
3. Run `./tests/run-all.sh` after each phase.
4. Commit in logical groups (see Commit Strategy).
5. STOP and confirm before the next phase.
