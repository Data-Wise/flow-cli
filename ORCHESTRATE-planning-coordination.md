# planning-coordination — Orchestration Plan

> **Branch:** `feature/planning-coordination`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-planning-coordination`
> **Spec:** `docs/specs/SPEC-planning-coordination-2026-07-01.md` (grilled 2026-07-01, D1–D16)
> **Brainstorm:** `docs/specs/BRAINSTORM-planning-coordination-2026-07-01.md`
> **Version Target:** v7.14.0

## Objective

Refactor flow-cli's planning-command duplication (single `.STATUS` accessor,
project-path resolver, project-suggester; fix the `$path`→`project_path` bug
as an isolated pre-step) and add a **dark-ready** atlas-agenda source to the
schedule engine so `agenda`/`dash`/`morning` will surface research deadlines
(atlas `Task.dueDate`) merged with the existing `.STATUS`/teaching schedule
once atlas ships the command — graceful-degrading (silent no-op) until then.
Also add a flow-cli-scoped `.STATUS` template + warn-only enforcer.

**Cross-repo:** atlas (Track B) and obsidian-cli-ops (Track D) are
**contract-only** here (SPEC §7, hard-scoped by grill decision D7). Do NOT
implement them in this worktree; they get their own specs + grills. This
worktree ships Tracks A + C + the `.STATUS` template/enforcer only.

**Execution model (grill D10):** this is **phase-gated, not one-shot.** Stop
after each phase (including the pre-step) and wait for the reviewer to run the
full suite independently before proceeding — do not chain phases yourself
even if you believe tests pass.

## Phase Overview

| Phase | Increment                                              | Priority | Effort | Status |
| ----- | ------------------------------------------------------ | -------- | ------ | ------ |
| 0     | Pre-step — `$path` bug fix (isolated)                  | High     | ~20min |        |
| 1     | Track A — internal refactor (characterization-guarded) | High     | ~2-3h  |        |
| 2     | Track C — atlas agenda source + contract (dark-ready)  | High     | ~2-3h  |        |
| 3     | `.STATUS` template + enforcer (warn-only)              | Medium   | ~1h    |        |
| 4     | Documentation & Discoverability                        | High     | ~1-2h  |        |

## Phase 0: Pre-step — `$path` → `project_path` bug fix (D2, isolated)

**Scope:** ONLY this bug. Do not touch the shared accessors yet — that's Phase 1.

- [x] 0.1 **Red test first:** `tests/test-path-bug-fix.zsh` — proves `next`/
      `morning` focus/progress display is blank or wrong today for a project
      with nonzero progress (the actual broken behavior, not a synthetic case)
- [x] 0.2 Fix: `morning.zsh:83`, `adhd.zsh:103` — read `$project_path` (the
      field the fallback actually emits, `atlas-bridge.zsh:397`) instead of
      `$path` (ZSH's PATH array)
- [x] 0.3 Green: `test-path-bug-fix.zsh` passes; full `./tests/run-all.sh`
- [x] 0.4 **Isolated commit** — `fix(planning): read $project_path not $path in morning/next`
- [x] 0.5 **STOP.** Report: test output, diff, full-suite result. Wait for the
      reviewer's go-ahead before Phase 1.

**Key files:** `commands/morning.zsh`, `commands/adhd.zsh` (2-line fix each), `tests/test-path-bug-fix.zsh` (NEW)

## Phase 1: Track A — internal refactor (characterization-guarded, Axis 2)

**Scope:** De-duplicate planning helpers onto shared accessors in `lib/core.zsh`;
route `agenda` through the shared schedule engine. TDD — characterization tests
BEFORE any consolidation, then red unit tests for the new accessors.

- [x] 1.0 **Characterization tests first (Axis 2 — parity guard):**
      `tests/test-status-field-parity.zsh` — snapshot the CURRENT output of
      `_dash_get_status_field` (`dash.zsh:1325`), the inline greps
      (`morning.zsh:84`, `adhd.zsh:104`, `capture.zsh:406`), and
      `_flow_where_fallback` (`atlas-bridge.zsh:836`) across 4 `.STATUS`
      dialect + missing-field fixtures. Land GREEN on today's code (register
      in `run-all.sh`) BEFORE writing any new accessor.
- [x] 1.1 **Red tests:** `tests/test-status-field-accessor.zsh`,
      `tests/test-project-path-resolver.zsh`, `tests/test-suggest-project.zsh`
      (register in `tests/run-all.sh`)
- [x] 1.2 Add `_flow_status_field <root> <field>` to `lib/core.zsh`
      (handles `## Field:` + `field:` dialects; strips `%`)
- [x] 1.3 Add `_flow_resolve_project_path <name>` — merges
      `_dash_find_project_path` (`dash.zsh:1284`) + `_flow_get_project_fallback`
      (`atlas-bridge.zsh:370`); **always emits `project_path=`**
- [x] 1.4 Add `_flow_suggest_project` — one active/priority scan replacing the 5
      reimplementations (`dash.zsh:181`, `:1139`, `morning.zsh:144`, `adhd.zsh`
      `next`, `js`)
- [x] 1.5 Migrate call sites: `dash.zsh:1325`, `capture.zsh:406`,
      `atlas-bridge.zsh:836`, `morning.zsh:84`, `adhd.zsh:104` → `_flow_status_field`
- [x] 1.6 Route `agenda` (`agenda.zsh:62`) through `_schedule_window_records`
      (`schedule.zsh:549`); keep `_schedule_classify` for bucketing
- [x] 1.7 **Parity check:** `test-status-field-parity.zsh` still GREEN
      post-refactor — any diff is a silent-behavior-loss regression, not an
      acceptable "improvement"; investigate before proceeding
- [x] 1.8 Green: all new/parity unit suites + full `./tests/run-all.sh`
- [x] 1.9 Commit — `refactor(planning): shared .STATUS/project accessors` (+ separate `test:` commit for the characterization/red suites if helpful for review)
- [x] 1.10 **STOP.** Report: files changed, tests added, pass/fail/skip counts,
      parity-suite diff (should be none). Wait for the reviewer's go-ahead.

**Key files:** `lib/core.zsh` (update), `commands/{morning,adhd,dash,capture,agenda}.zsh` (update), `lib/atlas-bridge.zsh` (update), `tests/test-status-field-parity.zsh` / `tests/test-status-field-accessor.zsh` / `tests/test-project-path-resolver.zsh` / `tests/test-suggest-project.zsh` (NEW)

## Phase 2: Track C — atlas agenda source + contract (dark-ready, D1)

**Scope:** New capability-probed schedule source that merges atlas records —
ships as tested, inert code (real atlas has no `agenda` command yet). Pin the
proposed contract; leave `.STATUS`-ingestion mechanism as **atlas's own open
question** (D4) — do not design it here.

- [ ] 2.1 **Red tests first:** `tests/test-schedule-atlas-source.zsh`,
      `tests/e2e-agenda-atlas.zsh` (register in `run-all.sh`)
- [ ] 2.2 Create `tests/fixtures/atlas-agenda-stub.json` — the atlas-present
      test fixture (canned `agenda --format json` response)
- [ ] 2.3 Add `_schedule_atlas_items <window>` in `lib/schedule.zsh`;
      capability cache `_FLOW_ATLAS_HAS_AGENDA` (mirror `_FLOW_ATLAS_HAS_SCHEDULE`);
      call `_flow_atlas_json agenda "$window"`; map to
      `date|label|type|project|recurrence|source` with `source=atlas`
- [ ] 2.4 Wire into `_schedule_collect` (`schedule.zsh:378`) alongside
      `_schedule_parse_status` + `_schedule_teach_items`; **no-op when absent**
- [ ] 2.5 `at` dispatcher: `agenda` JSON passthrough in `lib/atlas-bridge.zsh`
- [ ] 2.6 Extend `docs/ATLAS-CONTRACT.md`: proposed `atlas task list --format json` + `atlas agenda [today|week|--all] --format json`; bump contract version;
      explicitly note `.STATUS`-ingestion as **atlas's open design question**,
      not prescribed here
- [ ] 2.7 Extend `tests/test-atlas-contract.zsh`: assert the fixture
      (2.2)'s shape matches what the contract doc (2.6) documents — a
      contract edit without a fixture update must fail this test (D16)
- [ ] 2.8 **Test both atlas states (D15):** absent via capability-flag
      override (`_FLOW_ATLAS_HAS_AGENDA` / `_flow_has_atlas`, NOT
      `FLOW_ATLAS_ENABLED=no` alone — env var is known-insufficient per memory
      `capture-real-agenda-output-for-docs`); present via a stub `atlas` shim
      on `PATH` returning the fixture
- [ ] 2.9 Green: dependency + e2e + full integration
      (`agenda-merged-sources.zsh` now with atlas third source, dedupe on
      `date|label|project`, no double-count); full `./tests/run-all.sh`
- [ ] 2.10 Commit — `feat(agenda): merge atlas agenda source into schedule engine (dark-ready)` (+ `docs(contract):` for ATLAS-CONTRACT)
- [ ] 2.11 **STOP.** Report: files changed, tests added, pass/fail/skip counts,
      dogfood confirmation that no-atlas behavior is unchanged. Wait for the
      reviewer's go-ahead.

**Key files:** `lib/schedule.zsh` (update), `lib/atlas-bridge.zsh` (update), `docs/ATLAS-CONTRACT.md` (update), `tests/test-schedule-atlas-source.zsh` / `tests/e2e-agenda-atlas.zsh` / `tests/fixtures/atlas-agenda-stub.json` (NEW), `tests/test-atlas-contract.zsh` / `tests/integration/agenda-merged-sources.zsh` (extend)

## Phase 3: `.STATUS` template + enforcer (D9, warn-only per D11)

**Scope:** flow-cli-scoped only — NOT an ecosystem-wide standard.

- [ ] 3.1 **Red test first:** `tests/test-status-schema.zsh`
- [ ] 3.2 Write `templates/.STATUS.template` — canonical structure + inline
      comments (header fields, `## Schedule:` grammar, `## daily_goal:`,
      `## Active Worktrees`, session-log convention; documents the dual
      dialect `_flow_status_field` supports)
- [ ] 3.3 Write `scripts/check-status.zsh` (model: `scripts/check-math.zsh`) —
      validates required fields, `Progress` int 0–100, `Schedule` grammar,
      `Status` in allowed set. **exit 0 always (warn-only, D11)** — print
      violations, never block
- [ ] 3.4 Wire into `lint-staged`: extensionless `.STATUS` filename match
      (not a glob) alongside the `check-math.zsh` entry
- [ ] 3.5 Green: `check-status.zsh` rejects (prints, doesn't block) a
      malformed fixture; passes clean on the template and on flow-cli's own
      `.STATUS`; full `./tests/run-all.sh`
- [ ] 3.6 Commit — `feat(status): add .STATUS template + warn-only schema enforcer`
- [ ] 3.7 **STOP.** Report results. Wait for the reviewer's go-ahead.

**Key files:** `templates/.STATUS.template` (NEW), `scripts/check-status.zsh` (NEW), `package.json` (lint-staged entry), `tests/test-status-schema.zsh` (NEW)

## Phase 4: Documentation & Discoverability (REQUIRED — final phase)

Per SPEC §6 — currency-check each file before editing; update genuine deltas only.

- [ ] Guide — `docs/reference/MASTER-DISPATCHER-GUIDE.md` (atlas source + degradation)
- [ ] Guide — `docs/guides/AGENDA-SCHEDULE-GUIDE.md` (data-source diagram + merged example w/ real captured output — memory `capture-real-agenda-output-for-docs`)
- [ ] API ref — `docs/reference/MASTER-API-REFERENCE.md` (`_flow_status_field`, `_flow_resolve_project_path`, `_flow_suggest_project`, `_schedule_atlas_items`)
- [ ] REFCARD — `docs/help/QUICK-REFERENCE.md` (agenda spans research + dev)
- [ ] Contract — `docs/ATLAS-CONTRACT.md` version bump (done in Phase 2; verify)
- [ ] `CONTRIBUTING.md` — note `.STATUS` template + warn-only `check-status.zsh`
- [ ] CHANGELOG — `CHANGELOG.md` + `docs/CHANGELOG.md` `[Unreleased]`, **mirrored**
- [ ] CLAUDE.md — refresh test-file/suite counts after new suites
- [ ] Website — `mkdocs build --strict` 0 warnings (no nav change expected)
- [ ] Hygiene — mark `docs/specs/SPEC-agenda-schedule-2026-06-13.md` **Implemented**
- [ ] `/craft:docs:lint` clean
- Demo — N/A (no new user-facing command surface; extends existing `agenda`)
- Catalog/hub — N/A (no new command/skill/agent)
- [ ] **STOP.** Report results. Wait for the reviewer's final go-ahead before any PR is opened (agent does NOT open the PR).

## Friction Prevention

- **Context first:** read this ORCHESTRATE file + the SPEC before any edit.
- **Verify location:** `git worktree list` + `pwd` — confirm you are in the
  worktree, not the main repo. Branch must be `feature/planning-coordination`.
- **No new code files on dev:** all code lands here on the feature branch.
- **Red-first:** every new test starts failing; carry
  `# TODO(author): delete if not contract-bearing` until the contract is confirmed.
- **Characterization before consolidation (Axis 2):** never refactor a
  duplicated call site before its current behavior is snapshotted — silent
  behavior-loss is the #1 risk this plan guards against.
- **Graceful degradation is a hard requirement:** Track C must be a silent
  no-op with no/older atlas — prove it via capability-flag override, not
  `FLOW_ATLAS_ENABLED=no` alone (D15).
- **Warn-only means warn-only (D11):** `check-status.zsh` must exit 0 always
  this cycle — do not make it blocking.
- **`.STATUS` ingestion is NOT your design problem (D4):** if you find
  yourself designing how atlas parses `.STATUS`, stop — that belongs in
  atlas's own spec.
- **STOP after EVERY phase (including Phase 0)** and wait for the reviewer's
  explicit go-ahead before proceeding — this is phase-gated execution (D10),
  not autonomous multi-phase execution.
- **On a failed review gate:** you'll receive the exact failing output via a
  follow-up message. Fix forward and re-commit in the same phase — do not
  reset, do not skip ahead. If told this is the 2nd failed attempt, stop and
  wait; do not attempt a 3rd fix unprompted (D13/D14).
- Portability (memory `macos-only-shell-isms-break-linux-ci`): no `sed -i ''`,
  `stat -f`, `date -j`, `exec {var}>`; POSIX-portable for Linux CI.

## Acceptance Criteria (SPEC §8)

- [ ] `source flow.plugin.zsh` — clean load, no errors
- [ ] `./tests/run-all.sh` — **reviewer-run independently**, green (1 expected interactive/tmux timeout); new suites pass; CLAUDE.md counts updated
- [ ] Characterization suite unchanged pre/post-refactor (parity proven)
- [ ] `check-status.zsh` warn-only: exit 0 always, prints violations on a bad fixture, clean on template + real `.STATUS`
- [ ] Dogfood **no atlas** (capability-flag override): `agenda`/`dash`/`morning` identical to pre-change (degradation proven)
- [ ] Dogfood **atlas stub on PATH**: research deadlines merged; `$path` fix restores focus/progress
- [ ] `mkdocs build --strict` — 0 warnings
- [ ] `/craft:docs:lint` clean
- [ ] Documentation & Discoverability phase complete

## Commit Strategy

- Phase 0: `fix(planning): read $project_path not $path in morning/next`
- Phase 1: `refactor(planning): shared .STATUS/project accessors` (+ `test:` for characterization/red suites)
- Phase 2: `feat(agenda): merge atlas agenda source into schedule engine (dark-ready)` (+ `docs(contract):` for ATLAS-CONTRACT)
- Phase 3: `feat(status): add .STATUS template + warn-only schema enforcer`
- Phase 4: `docs(planning): agenda/dispatcher/API guides + CHANGELOG`

## Verification (after each phase — run by the REVIEWER, not self-reported)

```bash
cd ~/.git-worktrees/flow-cli/feature-planning-coordination
source flow.plugin.zsh          # clean load
./tests/run-all.sh              # FULL suite, every phase gate (Axis 5)
mkdocs build --strict           # docs (Phase 4)
```

## Integrate (after ALL phases verified — reviewer does this, not the agent)

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
feature. The SPEC (`docs/specs/SPEC-planning-coordination-2026-07-01.md`,
grilled — decisions D1–D16) has full design details; the BRAINSTORM has the
ecosystem rationale. Tracks B/D are out of scope — contract-only.

### How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-planning-coordination
claude
```

On session start, paste:

> Read `ORCHESTRATE-planning-coordination.md` and the spec at
> `docs/specs/SPEC-planning-coordination-2026-07-01.md`. Confirm you are in the
> worktree (`git worktree list`, `pwd`, branch = `feature/planning-coordination`).
> Then start **Phase 0** (the isolated `$path` fix) using TDD. **STOP after
> Phase 0** and report — do not proceed to Phase 1 without an explicit
> go-ahead. This plan is phase-gated: every phase stops for independent
> review, not just a final summary.

### Phase-by-Phase

1. Read the current state of each file listed in the phase.
2. Write the red/characterization tests first, then implement per the SPEC design.
3. Run `./tests/run-all.sh` before stopping.
4. Commit per the Commit Strategy.
5. **STOP and report — wait for the reviewer's go-ahead before the next phase.**
6. On a failed gate: fix forward per the follow-up instruction, re-commit,
   re-report. Cap 2 attempts per phase (D13/D14).
