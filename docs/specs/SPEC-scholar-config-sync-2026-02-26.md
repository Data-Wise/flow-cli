# SPEC: Scholar Config Sync + New Wrappers

**Status:** draft
**Created:** 2026-02-26
**Issue:** #299 (close as mostly-done) → new issue for wiring + wrappers
**From Brainstorm:** BRAINSTORM-scholar-config-sync-2026-02-26.md
**Prerequisite:** #298 (teach migrate-config) — Complete
**Estimated Effort:** 3-4 hours (flow-cli side only — Scholar already implemented)

---

## Overview

Two-part feature: (1) Wire flow-cli's existing config infrastructure to Scholar's `--config` flag so all teach commands auto-inject course context, and (2) add new teach subcommands wrapping Scholar features that flow-cli doesn't expose yet: `teach config {check,diff,show,scaffold}`, `teach solution`, `teach sync`, and `teach validate-r`.

---

## Primary User Story

**As a** course instructor using flow-cli's `teach` dispatcher,
**I want** Scholar to automatically use my `.flow/teach-config.yml` when generating content,
**So that** exams, quizzes, and lectures reflect my course name, semester, grading policy, notation, and teaching style without manual flag passing.

### Acceptance Criteria

- [ ] `teach exam "Topic"` automatically passes `--config .flow/teach-config.yml` to Scholar
- [ ] All 9 Scholar-wrapped commands receive the config flag when config exists
- [ ] If no `.flow/teach-config.yml` found, Scholar runs without `--config` (graceful fallback)
- [ ] `teach doctor` reports config sync status (connected vs. not found)
- [ ] Warning shown when config changed since last Scholar invocation
- [ ] Tests cover: config found, config missing, config changed scenarios

---

## Secondary User Stories

### Instructor with legacy config
**As a** user with `.claude/teaching-style.local.md` (legacy),
**I want** Scholar to prefer `.flow/teach-config.yml` when both exist,
**So that** I can migrate at my own pace without breaking existing workflows.

### Instructor checking config status
**As a** user debugging generation quality,
**I want** `teach config check` to show what Scholar sees,
**So that** I can verify my config is being read correctly.

---

## Architecture

```
teach exam "Bayesian Stats"
    │
    ▼
_teach_preflight()          ← validates config, checks hash
    │
    ▼
_teach_build_command()      ← maps to /teaching:exam
    │
    ▼
command assembly block      ← NEW: append --config "$config_path"
    │
    ▼
_teach_execute()            ← runs: claude --print "/teaching:exam --config /path/to/.flow/teach-config.yml ..."
    │
    ▼
Scholar loadTeachConfig()   ← reads YAML, merges with defaults, applies 4-layer style
    │
    ▼
Generated exam content      ← uses course name, semester, grading policy, notation
```

---

## API Design

N/A — No API changes. This is a ZSH function modification (internal wiring).

### New/Modified Functions

| Function | File | Change |
|----------|------|--------|
| Command assembly block (~L2153-2201) | `lib/dispatchers/teach-dispatcher.zsh` | Add `--config` injection |
| `_teach_preflight()` (~L1349) | `lib/dispatchers/teach-dispatcher.zsh` | Add hash change warning |
| `_teach_config_sync_status()` (NEW) | `lib/config-validator.zsh` | Return sync status for doctor |
| `_teach_doctor_config()` (MODIFY) | `commands/teach-doctor.zsh` | Add config sync section |

### New Subcommands

#### Config Subcommands (wrapping `/teaching:config`)

| Subcommand | Maps To | Purpose |
|------------|---------|---------|
| `teach config check` | `/teaching:config validate --strict` | Pre-flight: is config valid? |
| `teach config diff` | `/teaching:config diff` | Compare your prompts vs Scholar defaults |
| `teach config show` | `/teaching:config show` | See what Scholar actually sees (4 layers merged) |
| `teach config scaffold` | `/teaching:config scaffold` | Copy Scholar default prompts to `.flow/` for customization |

#### New Scholar Wrappers

| Subcommand | Maps To | Purpose |
|------------|---------|---------|
| `teach solution` | `/teaching:solution` | Generate standalone solution keys for assignments/exams |
| `teach sync` | `/teaching:sync` | Sync teach-config.yml to Scholar's internal format |
| `teach validate-r` | `/teaching:validate-r` | Validate R code chunks in .qmd files |

---

## Data Models

N/A — No data model changes. Uses existing `.flow/teach-config.yml` schema.

---

## Dependencies

| Dependency | Status | Required For |
|------------|--------|-------------|
| Scholar plugin v2.2.0+ | Installed | `--config` flag support |
| `_teach_find_config()` | Exists (unwired) | Config path discovery |
| `_flow_config_hash()` | Exists (unwired) | Change detection |
| `_flow_config_changed()` | Exists (unwired) | Stale config warning |
| `yq` (optional) | Recommended | Config validation |

---

## UI/UX Specifications

N/A — CLI only. No visual changes beyond terminal warnings.

### Warning Output (stale config)

```
⚠  Config changed since last Scholar run
   File: .flow/teach-config.yml
   Run: teach config check   (to verify)
```

### Doctor Output (new section)

```
Scholar Config:
  ✓ Config file: .flow/teach-config.yml
  ✓ Scholar section: present
  ✓ Auto-injection: enabled
  ✓ Last synced: 2026-02-26 14:30
  ⚠ Legacy file: .claude/teaching-style.local.md (deprecated)
```

---

## Implementation Plan

### Increment 1: Core Wiring (30 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

1. In the command assembly block (~lines 2153-2201), after existing flag appends:

```zsh
# Config injection (Scholar Config Sync, #299)
local config_path
config_path=$(_teach_find_config 2>/dev/null)
if [[ -n "$config_path" ]]; then
    scholar_cmd="$scholar_cmd --config \"$config_path\""
fi
```

2. In `_teach_preflight()`, add hash check:

```zsh
# Stale config warning
if _flow_config_changed 2>/dev/null; then
    _flow_log_warn "Config changed since last Scholar run"
    _flow_log_warn "  Run: teach config check"
fi
```

### Increment 2: Config Subcommands (30 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

Add to the `config` case in the dispatcher:

```zsh
config)
    shift
    case "$1" in
        check)     _teach_scholar_wrapper "config" "validate" "--strict" ;;
        diff)      _teach_scholar_wrapper "config" "diff" "${@:2}" ;;
        show)      _teach_scholar_wrapper "config" "show" "${@:2}" ;;
        scaffold)  _teach_scholar_wrapper "config" "scaffold" "${@:2}" ;;
        sync)      _teach_scholar_wrapper "config" "show" ;;
        # existing: edit, view, cat
        *)         _teach_config_edit "$@" ;;
    esac
    ;;
```

### Increment 3: New Scholar Wrappers (45 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

Add new cases to the main teach dispatcher:

```zsh
solution)  shift; _teach_scholar_wrapper "solution" "$@" ;;
sync)      shift; _teach_scholar_wrapper "sync" "$@" ;;
validate-r) shift; _teach_scholar_wrapper "validate-r" "$@" ;;
```

Update `_teach_help()` to include new commands. Update `_teach_build_command()` to map:
- `solution` → `/teaching:solution`
- `sync` → `/teaching:sync`
- `validate-r` → `/teaching:validate-r`

### Increment 4: Doctor Integration (15 min)

**File:** `commands/teach-doctor.zsh`

Add config sync section to both quick and full doctor modes.

### Increment 5: Legacy Deprecation Warning (15 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

In `_teach_preflight()`, after config validation:

```zsh
# Legacy file deprecation warning
local legacy_style="${FLOW_PROJECT_ROOT}/.claude/teaching-style.local.md"
if [[ -f "$legacy_style" ]] && [[ -n "$config_path" ]]; then
    _flow_log_warn "Deprecated: .claude/teaching-style.local.md"
    _flow_log_warn "  Scholar now reads from: .flow/teach-config.yml"
    _flow_log_warn "  teaching_style section takes precedence"
fi
```

### Increment 6: Tests (30 min)

**File:** `tests/test-scholar-config-sync.zsh` (NEW)

- Test: config found → `--config` appended to scholar_cmd
- Test: config missing → no `--config` (graceful fallback)
- Test: config changed → warning shown
- Test: legacy file + new config → deprecation warning
- Test: `teach config check/diff/show/scaffold` dispatch correctly
- Test: `teach solution/sync/validate-r` dispatch correctly
- Test: help output includes new commands

### Increment 7: Documentation (30 min)

- Update `docs/reference/MASTER-DISPATCHER-GUIDE.md` (teach config subcommands + new wrappers)
- Update `docs/guides/TEACHING-SYSTEM-ARCHITECTURE.md` (config sync section)
- Update `docs/help/QUICK-REFERENCE.md` (all new commands)
- Update `CLAUDE.md` (teach subcommands list: add solution, sync, validate-r)

---

## Open Questions

1. **Config path naming in issue #299:** Issue says `.flow/config-teach.yml` but all infrastructure uses `.flow/teach-config.yml`. Decision: use `teach-config.yml` (canonical). Close discrepancy in issue comments.
2. **Scholar version check:** Should `_teach_preflight()` verify Scholar version >= 2.2.0 before injecting `--config`? Currently no version check exists.

---

## Review Checklist

- [ ] All 9 Scholar-wrapped commands receive `--config` when config exists
- [ ] Graceful fallback when no config file present
- [ ] Hash change detection wired and warning shown
- [ ] Legacy deprecation warning present
- [ ] Doctor reports config sync status
- [ ] Config subcommands (check/diff/show/scaffold) dispatch correctly
- [ ] New wrappers (solution/sync/validate-r) dispatch correctly
- [ ] Help output includes all new commands
- [ ] Tests: 10+ test functions covering all scenarios
- [ ] Docs updated (dispatcher guide, architecture, quick reference)
- [ ] `./tests/run-all.sh` passes with new test file
- [ ] `zsh tests/dogfood-test-quality.zsh` passes

---

## Implementation Notes

- The core change is ~10 lines in the command assembly block of `teach-dispatcher.zsh`
- All config infrastructure (`_teach_find_config`, `_flow_config_hash`, `_flow_config_changed`) already exists and is tested — just needs wiring
- Scholar's `--config` flag is fully implemented as of Scholar v2.2.0
- One-way sync: flow-cli owns `.flow/teach-config.yml`, Scholar only reads
- No changes needed on Scholar side — this is 100% a flow-cli wiring task
- New wrappers (solution, sync, validate-r) follow the same `_teach_scholar_wrapper` + `_teach_build_command` pattern as existing commands
- Total new teach subcommands: 7 (config check/diff/show/scaffold + solution + sync + validate-r)

---

## Documentation Deliverables

### Increment 7a: Help Output Updates

Update `_teach_help()` in teach-dispatcher.zsh to include:

```
Config Management:
  teach config check       Validate config (pre-flight)
  teach config diff        Compare prompts vs defaults
  teach config show        Show resolved 4-layer config
  teach config scaffold    Copy default prompts for customization
  teach config edit        Open config in editor (existing)

Content Generation:
  teach solution <topic>   Generate solution key
  teach sync               Sync config to Scholar format

Code Quality:
  teach validate-r         Validate R code in .qmd files
```

### Increment 7b: MASTER-DISPATCHER-GUIDE.md Updates

Add to the teach dispatcher section:

**Config Commands Table:**

| Command | Description | Scholar Mapping |
|---------|-------------|-----------------|
| `teach config check` | Validate config against Scholar schema | `/teaching:config validate --strict` |
| `teach config diff [TYPE]` | Compare your prompts vs Scholar defaults | `/teaching:config diff` |
| `teach config show [--command CMD]` | Show resolved 4-layer config | `/teaching:config show` |
| `teach config scaffold <type>` | Copy default prompt to `.flow/` | `/teaching:config scaffold` |
| `teach config edit` | Open config in editor | (existing, local) |

**New Generation Commands:**

| Command | Description | Scholar Mapping |
|---------|-------------|-----------------|
| `teach solution <topic>` | Generate standalone solution key | `/teaching:solution` |
| `teach sync` | Sync YAML config to Scholar JSON | `/teaching:sync` |
| `teach validate-r [file]` | Validate R code chunks in .qmd | `/teaching:validate-r` |

**Config Auto-Injection (new section):**

As of v7.6.0, all Scholar-wrapped teach commands automatically pass `--config` pointing to `.flow/teach-config.yml` when the file exists. This means Scholar reads your full course context (name, semester, grading policy, teaching style, notation) without manual flag passing.

Config injection is transparent — commands work exactly as before, but Scholar now has richer context for generation.

### Increment 7c: TEACHING-SYSTEM-ARCHITECTURE.md Updates

Add new "Config Sync" section:

```
## Config Sync Architecture

flow-cli and Scholar share configuration via `.flow/teach-config.yml`:

1. flow-cli OWNS the config file (create, edit, validate, migrate)
2. flow-cli AUTO-INJECTS `--config` on every Scholar command
3. Scholar READS the config (course, semester, style, macros)
4. Direction: one-way (flow-cli → Scholar)

### Config Discovery Chain

1. _teach_find_config() walks up from CWD to find .flow/teach-config.yml
2. If found, path is appended as --config "$path" to Scholar command
3. If not found, Scholar runs without --config (graceful fallback)

### Change Detection

_flow_config_hash() computes SHA-256 of the config file.
_flow_config_changed() compares current hash vs cached hash.
Warning is shown in _teach_preflight() when config has changed.

### Legacy Migration

`.claude/teaching-style.local.md` (Scholar v1 format) is deprecated.
Scholar's style-loader.js checks `.flow/teach-config.yml` first, then
falls back to the legacy markdown file. A deprecation warning is shown
when both files exist.

### 4-Layer Style Resolution (Scholar-side)

1. Global: ~/.claude/CLAUDE.md (teaching_style key)
2. Course: .flow/teach-config.yml (teaching_style section)
3. Command: command_overrides.<cmd> in config
4. Lesson: teaching_style_overrides from lesson plan

Precedence: Command > Lesson > Course > Global > Default
```

### Increment 7d: Integration Guide (NEW file)

**File:** `docs/guides/SCHOLAR-INTEGRATION-GUIDE.md`

```markdown
# Scholar Integration Guide

How flow-cli's `teach` dispatcher integrates with the Scholar Claude Code plugin.

## Prerequisites

- flow-cli v7.6.0+
- Scholar plugin v2.2.0+ installed in ~/.claude/plugins/scholar/
- A course with .flow/teach-config.yml

## How Config Sync Works

[config discovery → auto-injection → Scholar reads → generation]

## Setting Up Config Sync

1. Verify Scholar is installed: `teach doctor`
2. Initialize config: `teach init` (creates .flow/teach-config.yml)
3. Verify config: `teach config check`
4. View resolved config: `teach config show`

## Config Management Commands

### teach config check
Validates your config against Scholar's schema. Catches:
- Missing required fields
- Invalid values
- Schema version mismatches

### teach config diff
Shows differences between your prompts and Scholar's defaults.
Useful for understanding what you've customized.

### teach config show
Shows the fully resolved 4-layer config. This is exactly what
Scholar sees when generating content.

### teach config scaffold <type>
Copies Scholar's default prompt for a command type to .flow/
for customization. Types: exam, quiz, lecture, slides, etc.

## New Generation Commands

### teach solution <topic>
Generates standalone solution keys. Pairs with teach exam/quiz.
Example: `teach solution "Bayesian inference"`

### teach sync
Syncs .flow/teach-config.yml to Scholar's internal JSON format.
Typically automatic, but useful for debugging.

### teach validate-r [file]
Validates R code chunks in .qmd files. Checks:
- Syntax validity
- Package availability
- Chunk option correctness

## Troubleshooting

### "Config changed since last Scholar run"
Your .flow/teach-config.yml was edited since the last teach command.
Run `teach config check` to verify, then re-run your command.

### Scholar not reading my config
1. Verify config exists: `ls .flow/teach-config.yml`
2. Verify Scholar is installed: `teach doctor`
3. Check for validation errors: `teach config check`
4. View what Scholar sees: `teach config show`

### Legacy file warning
If you see "Deprecated: .claude/teaching-style.local.md", your
teaching_style section should now live in .flow/teach-config.yml.
The legacy file still works but will be removed in a future version.
```

---

## History

| Date | Event |
|------|-------|
| 2026-02-26 | Spec created from max-depth brainstorm. Key discovery: Scholar already implements `--config` flag on all commands. Scope reduced from "both repos" to "flow-cli wiring only". |
| 2026-02-26 | Re-scoped after user feedback: expanded to include new Scholar wrappers (solution, sync, validate-r) and full config subcommands (check/diff/show/scaffold). Added detailed documentation deliverables (help output, dispatcher guide, architecture docs, new integration guide). 7 increments, ~3-4 hours. |
