# SPEC — flow-cli planning-command refactor + atlas-agenda coordination

**Status:** Approved (grilled 2026-07-01 — see `GRILL-planning-coordination-2026-07-01` decisions D1–D16 in `~/.claude/plans/fuzzy-conjuring-milner.md`)
**Date:** 2026-07-01 · **Target version:** v7.14.0 · **Focus:** architecture / ops
**Companion:** [`BRAINSTORM-planning-coordination-2026-07-01.md`](BRAINSTORM-planning-coordination-2026-07-01.md)
**Scope in this repo — hard boundary (D7):** Track A (flow-cli internal refactor) + Track C (consume atlas agenda, shipped **dark-ready**, D1) + a new flow-cli-scoped `.STATUS` template/enforcer (D9). Tracks B (atlas `task`/`agenda` CLI) and D (obs render/seed) are cross-repo dependencies, documented here as contract only — **not designed or built in this cycle**; each gets its own spec + grill.

---

## 1. Context & motivation

flow-cli's planning surface (`agenda`, `dash`, `morning`, `next`, `js`) works but (a) duplicates core logic across 5 files, (b) carries a confirmed latent bug, and (c) is blind to atlas's task/deadline data. The brainstorm locked an **atlas-owns-the-brain** architecture: atlas aggregates tasks + deadlines into a daily agenda (JSON/iCal); flow-cli displays it fast, merged with its existing `.STATUS`/teaching sources; obs renders it into the vault. This SPEC delivers the flow-cli half on a de-duplicated base.

## 2. Goals / non-goals

**Goals**
- G0 — **(Pre-step, isolated — D2)** Fix the `$path` → `project_path` bug in `morning.zsh` + `adhd.zsh`, red-test-first, landed **before** any refactor so it's independently bisectable/revertable.
- G1 — Single accessor for `.STATUS` fields, project-path resolution, and project suggestion (kill 4×/2×/5× duplication), **guarded by characterization/snapshot tests of every call site's CURRENT output, landed green before consolidation** (Axis 2 — the unification must not silently change what a call site sees).
- G2 — *(superseded by G0 — kept as the design record of the bug; the fix itself ships as the pre-step)*.
- G3 — Route `agenda` through the shared `_schedule_window_records` engine (no inlined pipeline).
- G4 — New `_schedule_atlas_items` source: merge `atlas agenda`/`atlas task` records into the schedule engine, capability-probed, graceful-degrading, **shipped dark-ready (D1)** — mirrors the existing `schedule push` no-op-until-atlas-ships pattern.
- G5 — Pin `atlas task list --format json` + `atlas agenda --format json` in `docs/ATLAS-CONTRACT.md` as proposed contract. **`.STATUS`-ingestion mechanism is explicitly left as atlas's own open design question (D4) — this SPEC does not prescribe it.**
- G6 — **(D9)** flow-cli-scoped `.STATUS` template (`templates/.STATUS.template`) + a **warn-only** enforcer (`scripts/check-status.zsh`, D11) documenting the dialects `_flow_status_field` supports.

**Non-goals**
- Implementing the atlas CLI (Track B), its `.STATUS`-ingestion design, or obs rendering (Track D) — separate repos/specs (D4, D7).
- Changing the `.STATUS ## Schedule:` grammar or teach-config parsing.
- New top-level command (extends existing `agenda`; no count-cascade).
- An ecosystem-wide `.STATUS` standard — flow-cli-scoped only this cycle (deferred per the follow-up to D7).
- Blocking `.STATUS` commits anywhere — the enforcer is warn-only until a follow-up proves the template against real files (D11).

## 3. Design

### 3.0 Pre-step: `$path` bug fix (G0, D2 — isolated, ahead of everything)
`morning.zsh:83` and `adhd.zsh:103` do `eval "$info"` then read `$path`. The fallback emits `project_path=` (`atlas-bridge.zsh:397` — deliberately, per its comment "Avoid 'path' — conflicts with ZSH's PATH-tied variable"). Result: `$path` = the shell's PATH array, so `.STATUS` focus/progress + `_flow_detect_project_type "$path"` operate on garbage. **This lands as its own commit before Phase 1's refactor**, so it's bisectable independent of the larger change:
1. Red test proving the *current* broken output (focus/progress blank or wrong in `next`/`morning` for a project with nonzero progress).
2. Fix: read `$project_path` directly (not yet through the new resolver — that consolidation is Phase 1 proper).
3. Green — isolated commit.

### 3.1 Shared accessors (`lib/core.zsh`) — guarded by characterization tests (Axis 2)
**Before writing any of these**, snapshot each call site's CURRENT output against fixtures (four `.STATUS` dialect variants + missing-field cases) and land those characterization tests green on **today's** code. Only then refactor; the same tests must stay green after (parity, not just new-behavior coverage) — this is the guard against silently changing what a call site sees when unifying 4 divergent readers / 2 resolvers / 5 suggesters into one each.
- `_flow_status_field <root> <field>` — replaces `_dash_get_status_field` (`dash.zsh:1325`), the inline `grep`s in `morning.zsh:84` / `adhd.zsh:104` / `capture.zsh:406`, and `_flow_where_fallback` field reads (`atlas-bridge.zsh:836`). Handles both `## Field:` and `field:` dialects (superset of current behavior).
- `_flow_resolve_project_path <name>` — single resolver merging `_dash_find_project_path` (`dash.zsh:1284`, has apps + quarto/manuscripts + presentations) and `_flow_get_project_fallback` (`atlas-bridge.zsh:370`). **Always emits `project_path=` never `path=`.**
- `_flow_suggest_project` — single active/priority scan replacing the 5 reimplementations (`dash.zsh:181`, `:1139`, `morning.zsh:144`, `adhd.zsh` `next`, `js`).

### 3.2 *(bug fix moved to §3.0 as an isolated pre-step — D2)*

### 3.3 agenda unification (G3)
`agenda.zsh:62` runs an inline collect→filter→classify variant. Re-point it at `_schedule_window_records` (`schedule.zsh:549`) so bucketing + holiday-drop logic lives once. `_schedule_classify` stays for OVERDUE/TODAY/THIS-WEEK/LATER labelling.

### 3.4 atlas agenda source (G4 — shipped dark-ready, D1)
New `_schedule_atlas_items <window>` invoked inside `_schedule_collect` (`schedule.zsh:378`, alongside `_schedule_parse_status` + `_schedule_teach_items`):
- Probe capability once (session-cached, e.g. `_FLOW_ATLAS_HAS_AGENDA`), mirroring `_FLOW_ATLAS_HAS_SCHEDULE`.
- Call `_flow_atlas_json agenda "$window"`; map each record to the engine's `date|label|type|project|recurrence|source` shape (`source=atlas`).
- **Absent/older atlas → silent no-op**, engine falls back to `.STATUS` + teach only. No behavior change without atlas.
- **Deliberately dark this cycle:** real atlas has no `agenda` command yet (Track B unbuilt) — this ships as tested, capability-probed, inert code, same posture as `schedule push` today. Zero user-visible payoff until atlas B ships; zero rework required when it does.

**Test simulation of both atlas states (D15/D16):**
- **Absent:** override the capability flag (`_FLOW_ATLAS_HAS_AGENDA` / `_flow_has_atlas`) directly — `FLOW_ATLAS_ENABLED=no` alone is insufficient (memory `capture-real-agenda-output-for-docs`).
- **Present:** a stub `atlas` shim placed on `PATH` returning `tests/fixtures/atlas-agenda-stub.json` (real atlas can't be used — it lacks the command). The fixture's shape is asserted against what `docs/ATLAS-CONTRACT.md` documents inside `test-atlas-contract.zsh`, so a contract edit without a fixture update fails loudly instead of drifting silently.

### 3.5 Contract (G5)
Add to `docs/ATLAS-CONTRACT.md` (bump contract version): `atlas task list --format json`, `atlas agenda [today|week|--all] --format json`, marked **proposed** until atlas ships them (same status `schedule push` carries today). **The `.STATUS`-ingestion mechanism is explicitly recorded as atlas's own open question (D4) — not designed here**, to respect the §7/D7 scope boundary.

### 3.6 `.STATUS` template + enforcer (G6, D9/D11)
flow-cli-scoped only (not an ecosystem standard — that's deferred). Reuses the `scripts/check-math.zsh` pattern:
- **Template** `templates/.STATUS.template` — canonical structure with inline comments: header fields (`## Project/Type/Status/Phase/Focus/Priority/Progress`), the `## Schedule:` grammar, `## daily_goal:`, `## Active Worktrees`, session-log convention. Documents the dual dialect (`## Field:` and `field:`) that `_flow_status_field` (§3.1) supports.
- **Enforcer** `scripts/check-status.zsh` — validates required fields present, `Progress` is int 0–100, `Schedule` lines match grammar, `Status` in the allowed set. **Warn-only (D11): exit 0, prints violations** — does NOT block commits. Flip to blocking only in a follow-up once flow-cli's own `.STATUS` + the template are confirmed compliant.
- **Wiring:** add a `.STATUS`-keyed entry to `lint-staged` (extensionless filename match, not a glob) alongside `check-math.zsh`'s existing entry; new `tests/test-status-schema.zsh` (schema validity + template-parses-clean).

## 4. Files touched

- `lib/core.zsh` — new shared accessors.
- `lib/schedule.zsh` — `_schedule_atlas_items` + call site in `_schedule_collect`.
- `commands/agenda.zsh` — route through shared engine.
- `commands/morning.zsh`, `commands/adhd.zsh` — `$path` pre-step fix + use shared accessors.
- `commands/dash.zsh`, `commands/capture.zsh` — migrate to shared accessors.
- `lib/atlas-bridge.zsh` — capability probe + `agenda` JSON passthrough for `at`.
- `docs/ATLAS-CONTRACT.md` — proposed contract entries (`.STATUS` ingestion left open).
- `templates/.STATUS.template` (NEW) — canonical `.STATUS` structure.
- `scripts/check-status.zsh` (NEW) — warn-only schema enforcer.
- `tests/fixtures/atlas-agenda-stub.json` (NEW) — atlas-present test fixture, shape-asserted against the contract.

---

## 5. Testing plan *(refined — first-class, red-first, in-tree)*

Run everything in the worktree via `./tests/run-all.sh`; new suites registered there. Judge failures against the `dev` baseline. **Verification bar (Axis 5): the FULL suite, run independently by the reviewer, at every phase gate and before merge — never a sampled subset, never the agent's self-reported summary.**

### 5.0 Characterization (parity guard, Axis 2 — precedes 5.1)
| Suite | Asserts |
|---|---|
| `tests/test-status-field-parity.zsh` (new, RED against current code until it captures it, then GREEN pre-refactor) | Snapshots each existing call site's CURRENT output (`_dash_get_status_field`, the 3 inline greps, `_flow_where_fallback`) across 4 `.STATUS` dialect + missing-field fixtures; **must stay green after §3.1's consolidation** — a diff here means silent behavior change, not a passing refactor |

### 5.1 Unit
| Suite (new/extended) | Asserts |
|---|---|
| `tests/test-status-field-accessor.zsh` (new) | `_flow_status_field` reads both `## Focus:` and `focus:` dialects; missing field → empty; strips `%` on progress; no leak to `$path`/`$PATH` |
| `tests/test-project-path-resolver.zsh` (new) | `_flow_resolve_project_path` finds apps, quarto/manuscripts, presentations; emits `project_path=` never `path=`; unknown project → empty |
| `tests/test-suggest-project.zsh` (new) | `_flow_suggest_project` prefers active + high-priority; deterministic tie-break; empty registry → graceful |
| `tests/test-schedule-atlas-source.zsh` (new) | `_schedule_atlas_items` maps stub JSON → normalized records; malformed JSON → no-op not crash; capability-absent → 0 records |
| `tests/test-path-bug-fix.zsh` (new, pre-step §3.0) | RED first: proves `next`/`morning` focus/progress is blank/wrong today; GREEN after the isolated fix |
| `tests/test-status-schema.zsh` (new, §3.6) | `check-status.zsh` schema validity; `templates/.STATUS.template` parses clean; warn-only (exit 0) on a malformed fixture, prints violations |

### 5.2 Integration (cross-command data flow)
| Suite | Asserts |
|---|---|
| `tests/integration/agenda-merged-sources.zsh` (new) | `.STATUS` + teach + atlas records merge with **no double-count**; dedupe on `date|label|project`; `dash` UPCOMING, `morning`, `agenda` all render the same merged set (shared engine) |
| `tests/integration/atlas-flow-integration.zsh` (extend) | agenda path with atlas present vs absent yields identical non-atlas rows |

### 5.3 Dependency / contract
| Suite | Asserts |
|---|---|
| `tests/test-atlas-contract.zsh` (extend) | `atlas task list --format json` + `atlas agenda --format json` shapes pinned; flow-cli degrades to no-op when atlas lacks them (proven against a stub that omits the commands); **`tests/fixtures/atlas-agenda-stub.json` shape asserted against the documented contract (D16) — a contract edit without a fixture update fails this test** |

### 5.4 E2E + dogfood
| Suite | Asserts |
|---|---|
| `tests/e2e-agenda-atlas.zsh` (new) | sandbox + **capability-flag override** for atlas-absent (not `FLOW_ATLAS_ENABLED=no` alone, D15) + a **stub `atlas` shim on PATH** for atlas-present returning the shared fixture → merged view shows research deadlines alongside `.STATUS` schedule (capture real output per memory `capture-real-agenda-output-for-docs`) |
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
| `docs/ATLAS-CONTRACT.md` | proposed `atlas task`/`atlas agenda` entries + contract version bump; `.STATUS` ingestion noted as atlas's open question (D4) |
| `templates/.STATUS.template` inline comments (new) | canonical structure + dialect documentation (§3.6) |
| `CONTRIBUTING.md` | note the `.STATUS` template + `check-status.zsh` (warn-only, D11) in the contributor checklist |
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
2. `./tests/run-all.sh` — **run independently by the reviewer** (Axis 5, not the agent's self-report), all suites green (1 expected interactive/tmux timeout); new suites pass; counts updated in CLAUDE.md.
3. Characterization suite (`test-status-field-parity.zsh`) unchanged pre/post-refactor — parity proven, not just new-behavior coverage.
4. `check-status.zsh` — warn-only (exit 0) on a malformed `.STATUS` fixture, prints violations; clean (no violations) on the template and on flow-cli's own `.STATUS`.
5. Dogfood with **no atlas** (capability-flag override, D15): `agenda`, `dash`, `morning` identical to pre-change (graceful degradation proven).
6. Dogfood with **stub atlas shim on PATH** (D15): research deadlines appear merged; `$path` fix restores focus/progress in `morning`/`next`.
7. `mkdocs build --strict` — 0 warnings.
8. `/craft:docs:lint` — clean.

## 9. Rollout & execution model

- Branch: `feature/planning-coordination` (worktree off `dev`); `npm install` run in the worktree first so husky/lint-staged (prettier, `check-math.zsh`, the new `check-status.zsh`) fire on every commit (D12 — the worktree has no `node_modules` by default).
- **Execution is phase-gated (D10), not one-shot:** pre-step ($path fix) → Phase 1 (characterization + refactor) → Phase 2 (atlas source + contract) → Phase 3 (`.STATUS` template + enforcer) → Phase 4 (docs). Each phase stops for an independent full-suite review before the next proceeds.
- **Failure recovery (D13/D14):** a phase that fails review gets fixed forward via follow-up instruction to the same agent (context retained), re-verified; capped at 2 attempts. On a 2nd failure, execution stops and the finding is reported directly — no silent retry, no skip-ahead to the next phase.
- Ship Track A independently if Track C's atlas dependency isn't ready — the refactor + bug fix stand alone.
- Release as v7.14.0 once C's contract is pinned (C degrades safely even before atlas ships).

---

## Next step

`--orch` handoff: `/craft:orchestrate:plan docs/specs/SPEC-planning-coordination-2026-07-01.md` → generates `ORCHESTRATE-planning-coordination.md` (+ optional worktree), detects the cross-repo shape, and fans out the atlas/obs companion specs.
