# SPEC — flow-cli planning-command refactor + atlas-agenda coordination

**Status:** Draft (awaiting approval)
**Date:** 2026-07-01 · **Target version:** v7.14.0 · **Focus:** architecture / ops
**Companion:** [`BRAINSTORM-planning-coordination-2026-07-01.md`](BRAINSTORM-planning-coordination-2026-07-01.md)
**Scope in this repo:** Track A (flow-cli internal refactor) + Track C (consume atlas agenda). Tracks B (atlas `task`/`agenda` CLI) and D (obs render/seed) are cross-repo dependencies, documented here as contract only.

---

## 1. Context & motivation

flow-cli's planning surface (`agenda`, `dash`, `morning`, `next`, `js`) works but (a) duplicates core logic across 5 files, (b) carries a confirmed latent bug, and (c) is blind to atlas's task/deadline data. The brainstorm locked an **atlas-owns-the-brain** architecture: atlas aggregates tasks + deadlines into a daily agenda (JSON/iCal); flow-cli displays it fast, merged with its existing `.STATUS`/teaching sources; obs renders it into the vault. This SPEC delivers the flow-cli half on a de-duplicated base.

## 2. Goals / non-goals

**Goals**
- G1 — Single accessor for `.STATUS` fields, project-path resolution, and project suggestion (kill 4×/2×/5× duplication).
- G2 — Fix the `$path` → `project_path` bug in `morning.zsh` + `adhd.zsh`.
- G3 — Route `agenda` through the shared `_schedule_window_records` engine (no inlined pipeline).
- G4 — New `_schedule_atlas_items` source: merge `atlas agenda`/`atlas task` records into the schedule engine, capability-probed, graceful-degrading.
- G5 — Pin `atlas task list --format json` + `atlas agenda --format json` in `docs/ATLAS-CONTRACT.md` as proposed contract.

**Non-goals**
- Implementing the atlas CLI (Track B) or obs rendering (Track D) — separate repos/specs.
- Changing the `.STATUS ## Schedule:` grammar or teach-config parsing.
- New top-level command (extends existing `agenda`; no count-cascade).

## 3. Design

### 3.1 Shared accessors (`lib/core.zsh`)
- `_flow_status_field <root> <field>` — replaces `_dash_get_status_field` (`dash.zsh:1325`), the inline `grep`s in `morning.zsh:84` / `adhd.zsh:104` / `capture.zsh:406`, and `_flow_where_fallback` field reads (`atlas-bridge.zsh:836`). Handles both `## Field:` and `field:` dialects (superset of current behavior).
- `_flow_resolve_project_path <name>` — single resolver merging `_dash_find_project_path` (`dash.zsh:1284`, has apps + quarto/manuscripts + presentations) and `_flow_get_project_fallback` (`atlas-bridge.zsh:370`). **Always emits `project_path=` never `path=`.**
- `_flow_suggest_project` — single active/priority scan replacing the 5 reimplementations (`dash.zsh:181`, `:1139`, `morning.zsh:144`, `adhd.zsh` `next`, `js`).

### 3.2 Bug fix (G2)
`morning.zsh:83` and `adhd.zsh:103` do `eval "$info"` then read `$path`. The fallback emits `project_path=` (`atlas-bridge.zsh:397` — deliberately, per its comment "Avoid 'path' — conflicts with ZSH's PATH-tied variable"). Result: `$path` = the shell's PATH array, so `.STATUS` focus/progress + `_flow_detect_project_type "$path"` operate on garbage. Fix: read `$project_path` (routed through `_flow_resolve_project_path`).

### 3.3 agenda unification (G3)
`agenda.zsh:62` runs an inline collect→filter→classify variant. Re-point it at `_schedule_window_records` (`schedule.zsh:549`) so bucketing + holiday-drop logic lives once. `_schedule_classify` stays for OVERDUE/TODAY/THIS-WEEK/LATER labelling.

### 3.4 atlas agenda source (G4)
New `_schedule_atlas_items <window>` invoked inside `_schedule_collect` (`schedule.zsh:378`, alongside `_schedule_parse_status` + `_schedule_teach_items`):
- Probe capability once (session-cached, e.g. `_FLOW_ATLAS_HAS_AGENDA`), mirroring `_FLOW_ATLAS_HAS_SCHEDULE`.
- Call `_flow_atlas_json agenda "$window"`; map each record to the engine's `date|label|type|project|recurrence|source` shape (`source=atlas`).
- **Absent/older atlas → silent no-op**, engine falls back to `.STATUS` + teach only. No behavior change without atlas.

### 3.5 Contract (G5)
Add to `docs/ATLAS-CONTRACT.md` (bump contract version): `atlas task list --format json`, `atlas agenda [today|week|--all] --format json`, marked **proposed** until atlas ships them (same status `schedule push` carries today).

## 4. Files touched

- `lib/core.zsh` — new shared accessors.
- `lib/schedule.zsh` — `_schedule_atlas_items` + call site in `_schedule_collect`.
- `commands/agenda.zsh` — route through shared engine.
- `commands/morning.zsh`, `commands/adhd.zsh` — bug fix + use shared accessors.
- `commands/dash.zsh`, `commands/capture.zsh` — migrate to shared accessors.
- `lib/atlas-bridge.zsh` — capability probe + `agenda` JSON passthrough for `at`.
- `docs/ATLAS-CONTRACT.md` — proposed contract entries.

---

## 5. Testing plan *(refined — first-class, red-first, in-tree)*

Run everything in the worktree via `./tests/run-all.sh`; new suites registered there. Judge failures against the `dev` baseline.

### 5.1 Unit
| Suite (new/extended) | Asserts |
|---|---|
| `tests/test-status-field-accessor.zsh` (new) | `_flow_status_field` reads both `## Focus:` and `focus:` dialects; missing field → empty; strips `%` on progress; no leak to `$path`/`$PATH` |
| `tests/test-project-path-resolver.zsh` (new) | `_flow_resolve_project_path` finds apps, quarto/manuscripts, presentations; emits `project_path=` never `path=`; unknown project → empty |
| `tests/test-suggest-project.zsh` (new) | `_flow_suggest_project` prefers active + high-priority; deterministic tie-break; empty registry → graceful |
| `tests/test-schedule-atlas-source.zsh` (new) | `_schedule_atlas_items` maps stub JSON → normalized records; malformed JSON → no-op not crash; capability-absent → 0 records |

### 5.2 Integration (cross-command data flow)
| Suite | Asserts |
|---|---|
| `tests/integration/agenda-merged-sources.zsh` (new) | `.STATUS` + teach + atlas records merge with **no double-count**; dedupe on `date|label|project`; `dash` UPCOMING, `morning`, `agenda` all render the same merged set (shared engine) |
| `tests/integration/atlas-flow-integration.zsh` (extend) | agenda path with atlas present vs absent yields identical non-atlas rows |

### 5.3 Dependency / contract
| Suite | Asserts |
|---|---|
| `tests/test-atlas-contract.zsh` (extend) | `atlas task list --format json` + `atlas agenda --format json` shapes pinned; flow-cli degrades to no-op when atlas lacks them (proven against a stub that omits the commands) |

### 5.4 E2E + dogfood
| Suite | Asserts |
|---|---|
| `tests/e2e-agenda-atlas.zsh` (new) | sandbox + stub `atlas agenda` returning 2 tasks + `_flow_has_atlas` override → merged view shows research deadlines alongside `.STATUS` schedule (capture real output per memory `capture-real-agenda-output-for-docs`) |
| dogfood (manual, quoted in PR) | run `agenda` / `dash` / `morning` against the real repo set; confirm the `$path` fix restores focus/progress; confirm no regression when atlas agenda unavailable |

### 5.5 Regression guards
- Terminal-hygiene guard unaffected (no new fzf picker) — confirm `tests/test-terminal-hygiene-regression.zsh` still green.
- Man-page version-sync guard — bump `.TH` on release only.

**Baseline discipline:** any failure must be reproduced on `dev` before dismissal; PR body reports exact command + pass/fail/skip counts + baseline mapping.

---

## 6. Documentation plan *(refined — first-class, currency-checked)*

Inventory current state before editing (per doc-currency rule); update only genuine deltas.

| Doc | Change |
|---|---|
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | agenda now merges an atlas source; note graceful degradation |
| `docs/guides/AGENDA-SCHEDULE-GUIDE.md` | new data source diagram; merged research+dev example with real captured output |
| `docs/reference/MASTER-API-REFERENCE.md` | document `_flow_status_field`, `_flow_resolve_project_path`, `_flow_suggest_project`, `_schedule_atlas_items` |
| `docs/help/QUICK-REFERENCE.md` | one-line: agenda spans research + dev |
| `docs/ATLAS-CONTRACT.md` | proposed `atlas task`/`atlas agenda` entries + contract version bump |
| `CHANGELOG.md` + `docs/CHANGELOG.md` | `[Unreleased]` — mirrored (both files) |
| `CLAUDE.md` | refresh test-file/suite counts after new suites land |
| `mkdocs.yml` | no nav change (extends existing pages); `mkdocs build --strict` must pass |
| stale-spec hygiene | mark `SPEC-agenda-schedule-2026-06-13.md` **Implemented** |

Doc-scorer (`commands/docs/sync.md`, threshold ≥3): guide ✅, refcard ✅, contract ✅; demo `N/A — score 2` (no new command surface); mermaid ✅ (in brainstorm).

---

## 7. Cross-repo dependencies (contract only — not built here)

- **atlas (Track B):** `atlas task {add,list,done} --format json`; `atlas agenda [today|week|--all] --format json` emitting `date|label|type|project|recurrence|source`. → own spec in `atlas/docs/specs/`.
- **obsidian-cli-ops (Track D):** extend `obs board`/`research board` to render agenda + seed `TaskNotes/Tasks/` from `atlas task list --format json`. → own spec in `obsidian-cli-ops/docs/`.

## 8. Verification (end-to-end)

1. `source flow.plugin.zsh` — clean load, no errors.
2. `./tests/run-all.sh` — all suites green (1 expected interactive/tmux timeout); new suites pass; counts updated in CLAUDE.md.
3. Dogfood with **no atlas**: `agenda`, `dash`, `morning` identical to pre-change (graceful degradation proven).
4. Dogfood with **stub atlas agenda**: research deadlines appear merged; `$path` fix restores focus/progress in `morning`/`next`.
5. `mkdocs build --strict` — 0 warnings.
6. `/craft:docs:lint` — clean.

## 9. Rollout

- Branch: `feature/planning-coordination` (worktree off `dev`).
- Ship Track A independently if Track C's atlas dependency isn't ready — the refactor + bug fix stand alone.
- Release as v7.14.0 once C's contract is pinned (C degrades safely even before atlas ships).

---

## Next step

`--orch` handoff: `/craft:orchestrate:plan docs/specs/SPEC-planning-coordination-2026-07-01.md` → generates `ORCHESTRATE-planning-coordination.md` (+ optional worktree), detects the cross-repo shape, and fans out the atlas/obs companion specs.
