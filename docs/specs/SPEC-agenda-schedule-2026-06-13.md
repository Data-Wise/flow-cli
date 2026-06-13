# SPEC: Forward-Looking Schedule Layer (`agenda` + dated `dash`/cadence)

| | |
|---|---|
| **Status** | draft |
| **Created** | 2026-06-13 |
| **Author** | dt + Claude (brainstorm) |
| **From brainstorm** | `/workflow:brainstorm -d -s` session, 2026-06-13 |
| **Plan file** | `~/.claude/plans/eventual-bouncing-phoenix.md` |
| **Target version** | v7.10.0 (minor — new command + env-free schema) |

---

## Overview

`dash` and the daily/weekly commands (`morning`, `today`, `week`) are **present- and
backward-looking** (project status, current session, wins, "work on X"). `research` and
`teach` already exist as *project categories*, but nothing surfaces **forward-looking dated
activity** — upcoming lectures, assignment due dates, exam dates, manuscript/grant deadlines,
milestones, or recurring blocks (grading window, writing time, advisor meeting).

This spec adds a forward-looking schedule layer: a new **`agenda`** command, an **UPCOMING**
section in `dash`, and dated enrichment of `morning`/`today`/`week` — all driven by one shared
engine (`lib/schedule.zsh`), working fully without atlas and without `yq`.

Two existing assets make this cheap:
- Teaching dates already aggregate via `_date_load_config` (`lib/date-parser.zsh:561`) into a
  `CONFIG_DATES` map (`week_N`, `exam_*`, `deadline_*`, `holiday_*`) with cross-platform date math.
- `.STATUS` already carries a half-used `deadline` field parsed by `_dash_get_urgency`
  (`commands/dash.zsh:415`) for overdue/soon — but never aggregated.

Atlas is skeletal here (no project-level deadlines, no semester awareness, no research
milestones, no cross-project "upcoming" view), so **flow-cli owns the model**; atlas is an
opportunistic, capability-detected sync target.

## User stories

**Primary (developer / instructor / researcher — the same person, ADHD-optimized):**
> As a multi-hat user, when I run `dash` or `agenda` I want to see what's *due soon* across all
> my projects — assignment due dates, exam dates, manuscript deadlines, recurring blocks — so I
> stop missing deadlines that live siloed in course configs or in my head.

**Secondary:**
- As an instructor, I want this week's lecture topic, assignment due dates, and exam dates pulled
  automatically from my existing `.flow/teach-config.yml` (no re-entry).
- As a researcher, I want to add manuscript/grant deadlines to a project with one line in `.STATUS`.
- As an ADHD user, I want overdue items surfaced loudly and a calm empty state when nothing's due.
- As an atlas user, I want these dated items pushed to atlas opportunistically (no-op when atlas absent).

## Acceptance criteria

- [ ] `agenda` lists in-window + overdue dated items across all projects, grouped (OVERDUE/TODAY/THIS WEEK/LATER).
- [ ] `agenda` flags work: default/`-w` (7d), `today` (0d), `-m` (30d), `--all`, `--overdue`, `<category>`, `-h`.
- [ ] Teaching items derive from `.flow/teach-config.yml` via `_date_load_config` (week topics, exams, deadlines).
- [ ] Research/general/recurring items derive from a new `## Schedule:` section in `.STATUS` (no `yq` needed).
- [ ] Recurring `weekly:<dow>` tokens expand correctly within the window, across month/year boundaries.
- [ ] `dash` shows an UPCOMING section after QUICK WINS; self-suppresses when empty.
- [ ] `morning`/`today`/`week` show dated blocks.
- [ ] Works fully with `FLOW_ATLAS_ENABLED=no` and with `yq` absent.
- [ ] Atlas push is capability-detected + async; silent no-op when atlas/`schedule` subcommand absent.
- [ ] `./tests/run-all.sh` green (new `test-schedule`, `test-agenda`, touched `test-dash`, patched manpage guard); `source flow.plugin.zsh` clean; `mkdocs build --strict` passes.

## Architecture

```
                        ┌──────────────────────────────┐
   .flow/teach-config   │      lib/schedule.zsh        │
   (per teach project) ─┤  _schedule_collect           │── records: date|label|type|project|recurrence|source
                        │   ├ _schedule_parse_status    │
   .STATUS ## Schedule: ┤   ├ _schedule_teach_items ────┼── reuses lib/date-parser.zsh (_date_load_config, _date_add_days)
   (per project)        │   ├ _schedule_expand_recurring│
                        │   ├ _schedule_filter_window   │
                        │   ├ _schedule_sort            │
                        │   ├ _schedule_render_line     │
                        │   └ _flow_schedule_to_atlas ──┼── opportunistic (lib/atlas-bridge.zsh _flow_atlas_async)
                        └───────────┬──────────────────┘
                                    │ consumed by
              ┌─────────────────────┼───────────────────────┐
        commands/agenda.zsh   _dash_upcoming        _flow_morning_agenda
        (new command)         (dash.zsh section)    (morning/today/week)
```

## Command design (`agenda`)

```
agenda [today | -w/--week | -m/--month | <category> | --all | --overdue | -h/--help]
```
| Invocation | Window | Notes |
|---|---|---|
| `agenda` / `agenda -w` | 7d | default |
| `agenda today` | 0d | today + overdue |
| `agenda -m` | 30d | includes LATER bucket |
| `agenda --all` | ∞ | includes holidays |
| `agenda --overdue` | — | overdue only |
| `agenda teach\|research\|general\|dev\|r\|quarto\|apps` | 7d | category filter |
| `agenda -h` | — | `_agenda_help` (dash-style) |

Pipeline: `_schedule_collect "$w" "$cat" | _schedule_filter_window "$w" | _schedule_sort` → render
→ fire `_flow_schedule_to_atlas` (async). Aliases: `agt`/`agw`/`agm` (avoid `ag`, collides with silver-searcher).

`agenda` is a **top-level command** (`commands/agenda.zsh`, auto-loaded), NOT a dispatcher — not
subject to the binary-precedence guard, not in `_FLOW_HELP_FUNCTIONS`.

## Data models

**`.STATUS` `## Schedule:` section** (greenfield, no migration, ZSH-parseable, no `yq`):
```
## Schedule:
- 2026-06-20 | Submit JRSS-B revision | research
- 2026-07-01 | Project beta milestone | general
- weekly:fri | Grading window | teaching
- weekly:mon | Advisor meeting | research
```
Grammar: `- <when> | <label> | <type>` where `when` = ISO `YYYY-MM-DD` or `weekly:<dow>`;
`type` ∈ `teaching|research|general|recurring` (optional → `general` for ISO, `recurring` for `weekly:`).
`project` inferred from `${status_file:h:t}`; unknown tokens skipped, not fatal.

**Normalized internal record** (pipe-delimited; labels forbid `|`):
`date|label|type|project|recurrence|source`  (`source` ∈ `status|teach-config`).

**Classification:** `_schedule_classify` → `overdue|today|soon|later` (ISO string-compare +
`strftime`, same logic as `_dash_get_urgency`). Icons: 🔥 high / ⏰ medium / 📅 low; type icons 🎓/🔬/📌/🔁.

## Dependencies

- **Reused (read-only):** `lib/date-parser.zsh` (`_date_load_config`, `_date_add_days`, `_date_normalize`,
  `_date_compute_from_week`); `lib/atlas-bridge.zsh` (`_flow_has_atlas`, `_flow_atlas_async`,
  `_flow_list_projects`, `_flow_timestamp`); `commands/dash.zsh` (`_dash_find_project_path`,
  `_dash_get_status_field`, `_dash_detect_category`, `_dash_get_urgency`); `lib/core.zsh` (`FLOW_COLORS`).
- **External (optional, graceful):** `yq` (teaching path only — research path needs none); `sort` (date sort).
- **Atlas (optional):** proposed `atlas schedule push --format=json` contract — see Open Questions.

## UI/UX specifications

ADHD-friendly: overdue surfaced loudly (🔥, OVERDUE bucket first), single high-signal CTA preserved,
calm empty state ("📅 Nothing scheduled — clear runway"). dash UPCOMING sits after QUICK WINS (high but
below the RIGHT NOW suggestion) and self-suppresses when empty. Relative-day labels ("today", "in 3d",
"overdue 2d"). All surfaces share `_schedule_render_line` for visual consistency.

## Implementation notes (sequencing — dev → worktree → ORCHESTRATE)

1. `lib/schedule.zsh` (engine, module guard `_FLOW_SCHEDULE_LOADED`, `typeset -g` constants) — TDD.
2. Source in `flow.plugin.zsh` core block: `date-parser.zsh` **before** `schedule.zsh`, after `atlas-bridge.zsh`.
3. `commands/agenda.zsh` + `_agenda_help` + `agt`/`agw`/`agm` — TDD.
4. `_dash_upcoming` inserted after `_dash_quick_wins`; date-keyed session cache (~600s TTL, `_dash_quick_health_check` pattern).
5. `morning`/`today`/`week` enrichment.
6. `completions/_agenda`, `man/man1/agenda.1` (`.TH` = `flow-cli 7.x.y` = FLOW_VERSION); **patch
   `tests/test-manpage-version-sync.zsh` orphan check** to skip `agenda` (~line 223, next to `flow`).
7. Register new tests in `tests/run-all.sh`; add fixture with `weeks[].start_date`.
8. Docs (§ below).
9. `./tests/run-all.sh` green + `source flow.plugin.zsh` clean before each commit.

**ZSH footguns:** never `local path=` / `local status=` (use `proj_path`/`proj_status`/`status_file`);
`local -A CONFIG_DATES` inside the teach fn; split with `${(f)...}`.

**Docs to update:** `CLAUDE.md` (command list + Quick Reference), `docs/help/QUICK-REFERENCE.md`,
`docs/reference/MASTER-DISPATCHER-GUIDE.md` (commands section), `mkdocs.yml` nav + new
`docs/guides/AGENDA-SCHEDULE-GUIDE.md`, `docs/ATLAS-CONTRACT.md` (push contract).

## Open questions

1. **Atlas contract** — proposed `atlas schedule push --format=json` consuming
   `[{date,label,type,project,recurrence,source}]`, upsert keyed on `(project,date,label)`. This is a
   separate atlas PR; flow-cli ships with a silent no-op until atlas implements it. Confirm command name.
2. **`_date_load_config` schema** — it requires `weeks[].start_date`, but the demo fixture uses
   `weeks[].date`. Fix the fixture for tests; possible follow-up: make `_date_load_config` fall back to `date`.
3. **`agenda add`** — interactive write of `## Schedule:` lines is out of scope v1; confirm it's a follow-up.

## Review checklist

- [ ] Engine works without `yq` and without atlas.
- [ ] Recurring expansion tested across month + year boundaries.
- [ ] dash UPCOMING self-suppresses; perf acceptable (cached).
- [ ] Man-page guard patched; CI green.
- [ ] All new docs in mkdocs nav (`--strict`).
- [ ] No `local path=` / `local status=` regressions (`tests/test-local-path-regression.zsh`).

## Out of scope (v1)

Atlas-side `schedule` command; `monthly:`/multi-day recurrence; ICS/calendar export; interactive `agenda add`.

## History

- **2026-06-13** — Initial draft from `/workflow:brainstorm -d -s`; plan approved in plan mode.
