# SPEC: `teach check` — Cross-Tool Validation Summary

| | |
|---|---|
| **Status** | Draft |
| **Created** | 2026-09-09 |
| **Author** | dt + Claude |
| **From** | [Issue #359](https://github.com/Data-Wise/flow-cli/issues/359) |
| **Target version** | Next minor (v7.18.0 — new subcommand) |
| **Effort** | 2-3h |

---

## Overview

Three validation layers already exist for a teaching project, but a user must know
about and run each one separately: `teach validate` (local config/content), `teach
validate-r` (R-code-in-`.qmd`, via Scholar), and Craft's own `teaching_validation.py`
content checker (a separate tool, cross-repo). No unified health view exists.

This adds a top-level `teach check` subcommand that runs every available layer and
prints one aggregated pass/warn/fail report, skipping gracefully whatever tool isn't
installed.

**Correction to the issue's implementation sketch:** the sketch calls a
`_teach_require_config` helper and a `_teach_build_command validate` helper — neither
exists in the codebase. The real building blocks, confirmed by reading the current
dispatcher, are below.

## What actually exists today (verified against the code, not the issue text)

| Layer | Real entry point | Notes |
|---|---|---|
| Config file presence + YAML syntax | `[[ -f .flow/teach-config.yml ]]` + `yq '.' "$config_file"` | Same pattern used at `lib/dispatchers/teach/teach-main.zsh:25-29` |
| Schema validation (required fields, semester/year/date formats, grading %, latex_macros) | `_teach_validate_config()` in `lib/config-validator.zsh:176` | **Local to flow-cli** — no Scholar dependency, despite the issue calling this "Scholar, if available." Already degrades gracefully if `yq` is missing. |
| Content/`.qmd` validation | `teach validate` → `_teach_validate_content_flags` (`teach-main.zsh:790`) | Existing subcommand, callable programmatically |
| R-code validation | `teach validate-r` → `_teach_scholar_wrapper "validate-r"` | Requires Scholar plugin; wrapper already handles "Scholar not installed" |
| Craft content validator (`teaching_validation.py`) | **Not present anywhere in this machine's Craft checkout or `~/.claude`** — confirmed via `find`, and via `docs/specs/SPEC-teaching-ecosystem-coordination-2026-02-06.md` in the Craft repo (cross-repo, read-only reference) | Must be invoked via `python3` at a path that may not exist; skip layer with a clear "Craft not found" line, don't error |
| Quarto render check | Reuses `teach validate --render` (referenced at `teach-main.zsh:948,955`) | No new code — call the existing flag |

This means the real "4 layers" are: **config+schema** (flow-cli, always available),
**content `.qmd`** (flow-cli, always available), **R code** (Scholar, optional),
**Craft content** (Craft, optional, currently absent on this machine — untestable
locally beyond the skip path).

## Design

### Dispatcher wiring

Add a new top-level case to `teach()` in `lib/dispatchers/teach/teach-main.zsh`
(alongside `doctor|doc`, not nested under the existing `config check`, which is a
different, Scholar-strict check):

```zsh
check|chk)
    case "$1" in
        --help|-h|help) _teach_check_help; return 0 ;;
        *) _teach_check "$@" ;;
    esac
    ;;
```

### `_teach_check()` (new function, own file: `lib/dispatchers/teach-check.zsh`)

```zsh
_teach_check() {
    local config_file=".flow/teach-config.yml"
    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    local -a results=()   # each entry: "LABEL|STATUS|SOURCE|DETAIL"
    local pass=0 warn=0 fail=0

    # 1. Config syntax
    if command -v yq >/dev/null 2>&1 && yq '.' "$config_file" >/dev/null 2>&1; then
        results+=("Config syntax|PASS|flow-cli|")
        ((pass++))
    else
        results+=("Config syntax|FAIL|flow-cli|invalid YAML")
        ((fail++))
    fi

    # 2. Schema validation (local, no Scholar dependency)
    if _teach_validate_config "$config_file" --quiet; then
        results+=("Schema|PASS|flow-cli|")
        ((pass++))
    else
        results+=("Schema|FAIL|flow-cli|see 'teach validate' for details")
        ((fail++))
    fi

    # 3. Content (.qmd) validation — reuse existing subcommand, capture pass/fail only
    if _teach_validate_content_flags >/dev/null 2>&1; then
        results+=("Content (.qmd)|PASS|flow-cli|")
        ((pass++))
    else
        results+=("Content (.qmd)|WARN|flow-cli|see 'teach validate' for details")
        ((warn++))
    fi

    # 4. R code validation — Scholar, optional
    if typeset -f _teach_scholar_wrapper >/dev/null 2>&1 && _flow_has_scholar 2>/dev/null; then
        # runs async/slow (Claude call) — skip by default, note as available
        results+=("R code|SKIP|scholar|run 'teach validate-r' separately (slow)")
    else
        results+=("R code|SKIP|scholar|not installed")
    fi

    # 5. Craft content validator — optional, cross-repo
    local craft_validator
    craft_validator=$(_teach_find_craft_validator 2>/dev/null)
    if [[ -n "$craft_validator" ]]; then
        if python3 "$craft_validator" "$config_file" >/dev/null 2>&1; then
            results+=("Craft content|PASS|craft|")
            ((pass++))
        else
            results+=("Craft content|WARN|craft|see output for details")
            ((warn++))
        fi
    else
        results+=("Craft content|SKIP|craft|not installed")
    fi

    _teach_check_render_report results pass warn fail
    (( fail == 0 ))
}
```

`_teach_find_craft_validator()` is a small new helper that checks 1-2 plausible
install locations and returns empty if not found — mirrors the existing
"gracefully skip unavailable tools" pattern already used for Scholar
(`_teach_scholar_wrapper`, `_flow_has_scholar`).

### Output format

Matches the box style already used by `teach doctor` (box-drawing chars via
`_flow_log_*`/existing box helpers in `lib/tui.zsh`), not a new bespoke renderer:

```
╭─────────────────────────────────────────────╮
│  TEACHING PROJECT HEALTH                     │
╰─────────────────────────────────────────────╯
  Config syntax       PASS   [flow-cli]
  Schema               PASS   [flow-cli]
  Content (.qmd)       WARN   [flow-cli]  see 'teach validate' for details
  R code                SKIP  [scholar]   not installed
  Craft content         SKIP  [craft]     not installed

  2/5 checks passed, 1 warning, 2 skipped (optional tools not installed)
```

SKIP is counted separately from PASS/WARN/FAIL — the issue's original mockup only
had PASS/WARN, but since 2 of the 4 real layers are optional cross-tool
integrations, honestly representing "not installed" (not "failed") matters for a
machine that has neither Scholar nor Craft.

### Exit code

`0` if no FAIL entries (WARN and SKIP don't block), `1` if any FAIL — consistent
with `_teach_validate_config`'s existing convention.

## Verification

- `teach check` on a project with a valid config, no Scholar, no Craft → all
  flow-cli layers PASS, both optional layers show SKIP with reason, exit 0
- `teach check` on a project with an invalid config (bad YAML) → syntax FAIL,
  schema FAIL, exit 1
- `teach check` with no `.flow/teach-config.yml` at all → single clear error,
  exit 1, same message as other `teach` subcommands use for this case
- `teach check --help` shows usage
- New test file `tests/test-teach-check.zsh`, registered in `tests/run-all.sh`'s
  explicit list (a suite that isn't registered there never runs in CI — see
  `CLAUDE.md` Testing section)
- Man page: no new page needed (subcommand of `teach`, not a new dispatcher) —
  add an entry to `man/man1/teach.1`'s subcommand list instead
- Docs: add `check|chk` to `docs/reference/MASTER-DISPATCHER-GUIDE.md`'s teach
  subcommand table and `docs/help/QUICK-REFERENCE.md`

## Open questions for approval

1. **Command name collision risk:** `config check` already exists as a nested
   Scholar-strict check (`teach-main.zsh:1148`). Top-level `check|chk` is free
   today, but is the naming clear enough that users won't confuse `teach check`
   (this) with `teach config check` (existing, different, Scholar-only)? An
   alternative name (`teach status` — already free?) wasn't explored.
2. **R-code layer default:** the sketch above skips the (slow, Claude-backed)
   Scholar R-code validation by default and just notes it's available via
   `teach validate-r`. Is that the right default, or should `teach check --full`
   run it too?
