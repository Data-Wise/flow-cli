# SPEC: `teach dashboard` — Dynamic Website Content

| | |
|---|---|
| **Status** | Draft |
| **Created** | 2026-09-12 |
| **Author** | dt + Claude |
| **From** | [Issue #275](https://github.com/Data-Wise/flow-cli/issues/275) |
| **Target version** | Next minor (new subcommand) |
| **Effort** | 6-9h (revised down from the issue's 8-12h — see corrections below) |

---

## Overview

The STAT 545 course website reads a generated `semester-data.json` via client-side
JavaScript to show "This Week," upcoming deadlines, and announcements without a site
rebuild. Today that file is hand-edited alongside `index.qmd`/`_variables.yml` every
week. This adds a `teach dashboard` subcommand that generates, previews, and manages
that JSON from `teach-config.yml`.

**Confirmed still needed (2026-09-12):** the STAT 545 site is still the active
teaching-site setup — this is real, current pain, not a stale ask sitting since
January.

## Corrections to the issue (verified against the code, not assumed)

The issue's proposal is broadly sound, but three of its five building blocks already
exist, one output path is wrong for this codebase's conventions, and one referenced
schema field doesn't do what it looks like it does:

| Issue's proposal | What's actually true |
|---|---|
| Output to `.flow/semester-data.json` | **Wrong directory.** `.flow/` holds *config* (`teach-config.yml`, `templates/`); every *generated* artifact in this codebase lives under `.teach/` (`concepts.json`, `validation-status.json`, `performance-log.json` — see `lib/status-dashboard.zsh:276,331`). `semester-data.json` is generated output, not config — it belongs at `.teach/semester-data.json`. |
| "Calculate current week" (Phase 1, implied new logic) | **Already exists.** `_calculate_current_week()` in `lib/teaching-utils.zsh:44` does exactly this from `semester_info.start_date`, and is already wired into `work <project>` (`commands/work.zsh:504`) to print "Current Week: Week N". Reuse it — don't reimplement. **Caveat to inherit or fix:** it hardcodes a 16-week cap ("standard semester"); confirm STAT 545's semester length before relying on it as-is. |
| New `breaks[]` schema (`name`, `start`, `end`, `show_next`) | **Already exists and already works** — `_is_break_week()` (`lib/teaching-utils.zsh:~95`) reads exactly this `semester_info.breaks[].{name,start,end}` shape today. Only `show_next` is new. **Do not confuse with `break_weeks: [10]`** — a flat integer-array field present in `tests/fixtures/demo-course/.flow/teach-config.yml:46` that no code anywhere reads (verified: zero matches under `lib/`). That field is dead fixture data from an earlier, abandoned format; the dashboard work should use `breaks[]`, never `break_weeks`. |
| Per-week `topic` (shown as new in the issue's schema block) | **Already exists** — every week entry in the current schema already has `topic` (`tests/fixtures/demo-course/.flow/teach-config.yml:50` etc., and validated by `_teach_validate_config`, `lib/config-validator.zsh:176`). Only `focus`, `lecture`, `lab`, `assignment` (as nested objects) are genuinely new fields. |
| (not addressed) JSON construction | This codebase's established convention for generated JSON is `jq -n` with a `version`/`schema_version` envelope (`lib/concept-extraction.zsh:199`), not manual heredoc string-building. Follow that pattern for `semester-data.json` too — gives the STAT 545 JS a way to detect format drift later. |

**Net effect on effort:** Phase 1 ("Core generate command," originally 3-4h) is smaller
than estimated — the week-number and break-detection math is a reuse, not new code.
The remaining phases (preview rendering, announce wizard + config-write, docs/tests)
are roughly as scoped. Revised estimate: 6-9h.

## What's new vs. reused

| Piece | Status |
|---|---|
| Week-number-from-date | Reuse `_calculate_current_week` (`lib/teaching-utils.zsh:44`) |
| Break detection | Reuse `_is_break_week` (`lib/teaching-utils.zsh:~95`) |
| Per-week `topic` | Already in schema |
| Per-week `focus`, `lecture`, `lab`, `assignment` | **New** — optional YAML fields, additive, no migration needed for existing configs |
| `semester_info.timezone` | **New** — optional, defaults to unset/none in output |
| `breaks[].show_next` | **New** — optional, default `true` per the issue |
| `dashboard.fallback_message`, `dashboard.announcements[]` | **New** — optional top-level section |
| JSON generation (`jq -n`, `.teach/semester-data.json`) | **New**, but modeled on `lib/concept-extraction.zsh`'s existing pattern |
| Announcement writer (append to config) | **New** — first command in this codebase to write structured data into `teach-config.yml` itself (existing `yq -i` writers only touch a separate status file, `dispatchers/teach-deploy-enhanced.zsh:512` — same technique, new target file) |

## Design

### Dispatcher wiring

New file `lib/dispatchers/teach-dashboard.zsh`, sourced by `teach-dispatcher.zsh`
alongside the other guarded sub-dispatcher files (same pattern as
`lib/dispatchers/teach-check.zsh`, added in #359). Wired into `teach()`
(`lib/dispatchers/teach/teach-main.zsh`) exactly like `dates` — a full sub-dispatcher,
not the simpler ternary used by `doctor`/`check`:

```zsh
# In teach-main.zsh, alongside the `dates)` case:
dashboard|dash)
    _teach_dashboard_dispatcher "$@"
    ;;
```

```zsh
# lib/dispatchers/teach-dashboard.zsh
_teach_dashboard_dispatcher() {
    if [[ -z "$1" || "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_dashboard_help
        return 0
    fi

    local subcmd="$1"
    shift

    case "$subcmd" in
        generate|gen)
            _teach_dashboard_generate "$@"
            ;;
        preview|prev)
            _teach_dashboard_preview "$@"
            ;;
        announce|a)
            _teach_dashboard_announce "$@"
            ;;
        status|st)
            _teach_dashboard_status "$@"
            ;;
        *)
            _teach_error "Unknown dashboard subcommand: $subcmd"
            echo ""
            _teach_dashboard_help
            return 1
            ;;
    esac
}
```

**Naming note:** `dash` as the alias risks confusion with flow-cli's top-level `dash`
command (project dashboard, unrelated to teaching). Use `dash` only as the `teach
dashboard` sub-alias (scoped under `teach`, so no actual collision) — but call this
out in help text so it's not misread as the same feature.

### `_teach_dashboard_generate`

Reads `.flow/teach-config.yml`, computes current week via `_calculate_current_week`,
resolves break status per week via `_is_break_week`, and emits
`.teach/semester-data.json` via `jq -n`:

```zsh
_teach_dashboard_generate() {
    local config_file=".flow/teach-config.yml"
    local output_file=".teach/semester-data.json"
    local force=false
    [[ "$1" == "--force" ]] && force=true

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    if [[ -f "$output_file" && "$force" != "true" ]]; then
        _flow_log_warn "$output_file already exists (use --force to overwrite)"
        return 1
    fi

    mkdir -p .teach

    # ... build weeks/breaks/announcements arrays from config via yq,
    # assemble with jq -n (version/schema_version envelope, matching
    # lib/concept-extraction.zsh:199's convention), write to $output_file
}
```

### `_teach_dashboard_preview`

Terminal-only, no file writes — shows what `generate` would compute for "today" (or
`--week N` to preview a specific week), using the existing box style
(`_teach_check_render_report`-style formatting, #359's precedent).

### `_teach_dashboard_announce`

Two modes: positional args (`teach dashboard announce "Title" "Message" --expires
DATE --type note`) for scripting, and no-args for an interactive wizard. Writes into
`.flow/teach-config.yml`'s `dashboard.announcements[]` via `yq -i` (same technique as
`dispatchers/teach-deploy-enhanced.zsh:512`, new target file). Auto-generates an `id`
slug if not given.

### `_teach_dashboard_status`

Config-only health check: does `dashboard:` section exist, how many announcements are
configured, how many have already expired (stale — flag for cleanup), is `.teach/semester-data.json`
present and how old. Distinct from `teach check` (#359) — that's cross-tool
validation; this is dashboard-specific config state.

## Verification

- `teach dashboard generate` on a config with `semester_info.weeks[].focus/lecture/lab/assignment`
  populated → valid `.teach/semester-data.json`, schema matches the issue's example shape
  (plus the corrected `.teach/` path)
- `teach dashboard generate` twice without `--force` → second run refuses, exit 1
- `teach dashboard preview` and `teach dashboard preview --week N` → correct week/break
  resolution, including a week inside a configured break
- `teach dashboard announce` (positional args) and interactive wizard → both append a
  well-formed entry to `dashboard.announcements[]`
- `teach dashboard status` on a config with an expired announcement → flags it
- `teach dashboard --help` shows usage
- New test file `tests/test-teach-dashboard.zsh`, registered in `tests/run-all.sh`
- Docs: `docs/reference/MASTER-DISPATCHER-GUIDE.md` teach subcommand table,
  `docs/help/QUICK-REFERENCE.md`, `man/man1/teach.1`, `docs/reference/TEACH-CONFIG-SCHEMA.md`
  (new optional fields)

## Open questions for approval

1. **`.teach/semester-data.json` vs. Quarto's `_site/` copy step** — the issue says the
   file is "copied to `_site/` by Quarto." That copy step lives in the STAT 545 site's
   own `_quarto.yml` (`resources:` config), outside this repo's control. This spec only
   commits to generating the file at a stable, documented path
   (`.teach/semester-data.json`) — confirm that's sufficient, or whether flow-cli should
   also validate/scaffold the consuming site's `_quarto.yml` (out of scope as proposed).
2. **`teach dashboard announce` writing to `teach-config.yml` directly** — this is the
   first command that mutates the *config* file itself (not a separate status file).
   Confirm that's acceptable, or whether announcements should live in a separate
   `.teach/announcements.json` that `generate` merges in (keeps `teach-config.yml`
   read-mostly, avoids yq-write edge cases like comment/formatting loss on rewrite).
3. **16-week cap in `_calculate_current_week`** — confirm STAT 545's semester length,
   or whether this spec's Phase 1 should also parametrize/fix the cap while touching
   this function.

## Out of scope

- Fixing `teach week`/`teach w` (found broken during this research — `_teach_show_week`
  is called but never defined anywhere in the codebase). Unrelated to this feature;
  flagged separately.
- Any change to the STAT 545 site's own `_quarto.yml`, `stat545.js`, or repo — this spec
  only covers the flow-cli side (generating the JSON), not the consuming site.
