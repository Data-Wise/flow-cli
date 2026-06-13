# ORCHESTRATE: agenda + forward-looking schedule layer

> **Feature branch:** `feature/agenda` · **Base:** `dev` · **Worktree:** `~/.git-worktrees/flow-cli/agenda`
> **Spec:** `docs/specs/SPEC-agenda-schedule-2026-06-13.md` (committed on `dev`)
> **Plan:** `~/.claude/plans/eventual-bouncing-phoenix.md`
> **Target version:** v7.10.0 (minor)

## ⛔ Session boundary

This file was created by the **planning session on `dev`**. Implementation happens **here, in a
NEW `claude` session started from this worktree**:

```bash
cd ~/.git-worktrees/flow-cli/agenda && claude
```

Do NOT implement from the dev/planning session.

---

## Goal

Add a forward-looking schedule layer: new `agenda` command + UPCOMING section in `dash` +
dated enrichment of `morning`/`today`/`week`, driven by one shared engine `lib/schedule.zsh`.
Works fully without atlas and without `yq`. See the spec for the full rationale and data model.

## Reuse (read-only — do NOT reinvent)

- `lib/date-parser.zsh` → `_date_load_config` (teaching dates: `week_N`/`exam_*`/`deadline_*`/`holiday_*`), `_date_add_days`, `_date_normalize`, `_date_compute_from_week`.
- `lib/atlas-bridge.zsh` → `_flow_has_atlas`, `_flow_atlas_async`, `_flow_list_projects`, `_flow_timestamp`.
- `commands/dash.zsh` → `_dash_find_project_path`, `_dash_get_status_field`, `_dash_detect_category`, `_dash_get_urgency`.
- `lib/core.zsh` → `FLOW_COLORS`. Cache pattern → `_dash_quick_health_check`.

## Tasks (TDD: write/extend the test, then implement; `./tests/run-all.sh` + `source flow.plugin.zsh` green before each commit)

### 1. Engine — `lib/schedule.zsh` (new)  → `tests/test-schedule.zsh`
- [ ] Module guard `_FLOW_SCHEDULE_LOADED`; `typeset -g SCHEDULE_DEFAULT_WINDOW=7`.
- [ ] `_schedule_classify <iso> [window]` → `overdue|today|soon|later`.
- [ ] `_schedule_relative_days <iso>` → "today"/"in 3d"/"overdue 2d".
- [ ] `_schedule_parse_status <status_file>` → records from `## Schedule:` (no external cmds); infers `project=${status_file:h:t}`.
- [ ] `_schedule_teach_items <teach_config> <project> [window]` → `local -A CONFIG_DATES; eval "$(_date_load_config ...)"`; map week/exam/deadline; holidays typed `holiday` (filtered unless `--all`); guarded by `command -v yq` + file exists.
- [ ] `_schedule_expand_recurring <weekly:dow> <start> <end>` → concrete dates (`strftime '%u'` + `_date_add_days`).
- [ ] `_schedule_collect [window] [category]` → orchestrate over `_flow_list_projects`; emit record stream; session cache.
- [ ] `_schedule_filter_window <window>` (stdin) → in-window + always overdue.
- [ ] `_schedule_sort` (stdin) → `sort -t'|' -k1,1`.
- [ ] `_schedule_render_line <record>` → type icon + urgency color + relative-day + label + dim project.
- [ ] `_flow_schedule_to_atlas <record...>` → `_flow_has_atlas || return 0`; cap-probe `_FLOW_ATLAS_HAS_SCHEDULE`; `_flow_atlas_async`; no-op if absent.
- **Tests:** parse block; empty/malformed → no crash; classify boundaries (frozen "today" arg); expand across **month+year** boundary; window filter; teach parse (fixture w/ `start_date`); **no-yq fallback**; **atlas-absent no-op** (mock `_flow_atlas_async` asserts not called).
- **Footguns:** no `local path=` / `local status=`; `local -A CONFIG_DATES`; split with `${(f)...}`.

### 2. Wiring — `flow.plugin.zsh`
- [ ] Source `lib/date-parser.zsh` (if not already global) **then** `lib/schedule.zsh` in the core library block, after `atlas-bridge.zsh`.

### 3. Command — `commands/agenda.zsh` (new)  → `tests/test-agenda.zsh`
- [ ] `agenda [today|-w/--week|-m/--month|<category>|--all|--overdue|-h/--help]`; default = 7d.
- [ ] Pipeline `_schedule_collect | _schedule_filter_window | _schedule_sort` → bucketed render (OVERDUE/TODAY/THIS WEEK/LATER) + calm empty state; then async atlas push.
- [ ] `_agenda_help` (dash-style, `_C_*` locals). Aliases `agt`/`agw`/`agm` (avoid `ag`).
- **Tests:** `-h`; default/`--overdue`/category/`--all`/`today` vs `-m`; empty state; `run_isolated` + `FLOW_ATLAS_ENABLED=no` + temp `FLOW_PROJECTS_ROOT`.

### 4. dash — `commands/dash.zsh`  → extend `tests/test-dash.zsh`
- [ ] `_dash_upcoming` (top 3–4, 7d + overdue); insert in `dash()` **after `_dash_quick_wins`, before `_dash_quick_access`**; self-suppress when empty.
- [ ] Date-keyed session cache (~600s TTL) shared with agenda/morning.

### 5. Cadence — `commands/morning.zsh`
- [ ] `_flow_morning_agenda` in `morning` (top 5, 7d + overdue) between projects and wins; quick mode one-liner.
- [ ] `today` → "📅 Due today" (0d) + overdue. `week` → "📅 This week's deadlines" (7d, by weekday).

### 6. Packaging
- [ ] `completions/_agenda` (model `completions/_dash`): flags + category states.
- [ ] `man/man1/agenda.1` (model `man/man1/g.1`); `.TH` = `flow-cli <FLOW_VERSION>`.
- [ ] **Patch `tests/test-manpage-version-sync.zsh`** orphan check: add `[[ "$base" == "agenda" ]] && continue` next to the `flow` skip (~line 223). REQUIRED or CI fails.
- [ ] Register `tests/test-schedule.zsh` + `tests/test-agenda.zsh` in `tests/run-all.sh`.
- [ ] Add a fixture `.flow/teach-config.yml` with `weeks[].start_date` (demo uses `weeks[].date` → yields no `week_N`).

### 7. Docs
- [ ] `CLAUDE.md` (command list + Quick Reference), `docs/help/QUICK-REFERENCE.md` (`agenda` + aliases + `## Schedule:` snippet).
- [ ] `docs/reference/MASTER-DISPATCHER-GUIDE.md` (commands section; note dash UPCOMING + cadence enrichment).
- [ ] New `docs/guides/AGENDA-SCHEDULE-GUIDE.md`; add to `mkdocs.yml` nav (strict build).
- [ ] `docs/ATLAS-CONTRACT.md` — document opportunistic `atlas schedule push --format=json` contract.

## Verification (before PR)

1. `source flow.plugin.zsh` clean (no errors / leaked vars).
2. `./tests/run-all.sh` green (new + touched suites; 1 expected interactive timeout).
3. Manual: temp `FLOW_PROJECTS_ROOT` with a `## Schedule:` block + teach project w/ `start_date`; run
   `agenda`, `agenda --overdue`, `agenda research`, `agenda -m`, `agenda -h`; verify buckets/overdue/filter/empty.
4. `dash` shows UPCOMING after QUICK WINS; suppresses when none. `morning`/`today`/`week` show dated blocks.
5. `FLOW_ATLAS_ENABLED=no agenda` fully works; atlas-without-`schedule` → silent no-op.
6. `mkdocs build --strict` passes.

## Integrate

- [ ] `git fetch origin dev && git rebase origin/dev` → `./tests/run-all.sh` → `gh pr create --base dev`.
- [ ] Bump version (v7.10.0) per release flow when merging dev→main.
- [ ] **Delete this `ORCHESTRATE-agenda.md` as part of the merge cleanup** (working artifact — belongs on the feature branch, not on `dev`).

## Out of scope (v1)

Atlas-side `schedule` command (separate atlas PR); `monthly:`/multi-day recurrence; ICS export; interactive `agenda add`.
