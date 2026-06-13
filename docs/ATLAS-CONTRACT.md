# Atlas CLI API Contract

**Version:** 1.0.0
**Parties:** flow-cli (v7.4.x) <-> Atlas CLI `@data-wise/atlas` (v0.9.x)
**Status:** Active

---

## Version Compatibility

| flow-cli | Atlas CLI | Notes |
|----------|-----------|-------|
| v7.4.x   | v0.9.x    | Current contract version |
| v7.3.x   | v0.8.x    | Legacy — no `crumb` command |
| v7.5.x   | v1.0.x    | Planned — stable API |

---

## Required Commands (Hot Path)

These 6 commands are bridged with ZSH-native fallbacks when Atlas is not installed. flow-cli calls these in performance-critical paths and MUST NOT block if Atlas is unavailable.

| Command | Usage in flow-cli | Fallback (no Atlas) | Output Format |
|---------|-------------------|---------------------|---------------|
| `atlas session start <project>` | `_flow_session_start` | worklog file | exit 0 |
| `atlas session end [note]` | `_flow_session_end` | worklog file | exit 0 |
| `atlas catch <text> [--project=X]` | `_flow_catch` | inbox.md | exit 0 |
| `atlas inbox` | `_flow_inbox` | cat inbox.md | text |
| `atlas where [project]` | `_flow_where` | filesystem detection | text |
| `atlas crumb <text> [--project=X]` | `_flow_crumb` | trail.log | exit 0 |

---

## Warm Path Commands (Atlas CLI Required)

These commands require Atlas CLI. flow-cli shows an install message if Atlas is not available. No ZSH-native fallback exists.

| Command | Description | Output Format |
|---------|-------------|---------------|
| `atlas stats` | Project statistics | table |
| `atlas plan` | Planning view | table |
| `atlas park [project]` | Park a project | text |
| `atlas unpark [project]` | Unpark a project | text |
| `atlas parked` | List parked projects | names (one per line) |
| `atlas dash` / `atlas dashboard` | Dashboard view | table |
| `atlas focus [project]` | Set focus project | text |
| `atlas triage` | Triage inbox items | interactive |
| `atlas trail` | Show breadcrumb trail | text |

---

## Opportunistic Commands (Capability-Detected, Optional)

These commands are **not required**. flow-cli detects them at runtime and uses
them only if present; otherwise the call is a **silent no-op**. flow-cli owns
the data model and degrades fully without atlas.

| Command | Description | Direction |
|---------|-------------|-----------|
| `atlas schedule push --format=json --data=<json>` | Ingest forward-looking dated items | flow-cli → atlas |

### `atlas schedule push` (proposed)

The `agenda` layer (`lib/schedule.zsh`) aggregates dated activity from each
project's `.STATUS` `## Schedule:` block and `.flow/teach-config.yml`, then
pushes it opportunistically and **asynchronously** (fire-and-forget) so it never
blocks the prompt.

**Capability probe.** flow-cli runs `atlas schedule --help` once per session and
caches the result (`_FLOW_ATLAS_HAS_SCHEDULE`). If atlas is absent, or present
but lacks a `schedule` subcommand, `_flow_schedule_to_atlas` returns without
calling atlas.

**Payload.** A JSON array of normalized records:

```json
[
  {"date":"2026-06-20","label":"Submit JRSS-B revision","type":"research","project":"manuscript-x","recurrence":"none","source":"status"},
  {"date":"2026-06-26","label":"Grading window","type":"recurring","project":"stat-101","recurrence":"weekly:fri","source":"status"}
]
```

| Field | Meaning |
|-------|---------|
| `date` | ISO `YYYY-MM-DD` (recurring tokens are expanded to concrete dates) |
| `label` | Human text |
| `type` | `teaching` · `research` · `general` · `recurring` · `holiday` |
| `project` | Source project name |
| `recurrence` | `none` or `weekly:<dow>` |
| `source` | `status` or `teach-config` |

**Suggested semantics.** Upsert keyed on `(project, date, label)`. Exit code per
the standard contract; flow-cli ignores the result (async). This is a *proposed*
contract — the atlas-side `schedule` command is a separate atlas PR; flow-cli
ships with the silent no-op until it lands.

---

## Output Format Specifications

Atlas CLI supports 4 output formats via the `--format` flag:

| Format | Description | Example |
|--------|-------------|---------|
| `names` | Plain text, one item per line, no headers | `project-a\nproject-b\n` |
| `json` | Valid JSON object or array | `[{"name":"project-a"}]` |
| `table` | Human-readable table with headers | Column-aligned with `---` separator |
| `shell` | Shell-evaluable key=value pairs | `PROJECT=myapp\nSTATUS=active\n` |

**Validation rule:** flow-cli uses `--format=names` for project listing. If output starts with `{` or `[`, flow-cli treats it as a format violation and falls back to filesystem scan.

---

## Exit Code Contract

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (command failed) |
| 2 | Not found (project/session not found) |

Exit codes are stable. New codes may be added in future versions, but existing meanings MUST NOT change.

---

## Project List Contract

```
atlas project list --format=names
```

MUST return plain text with one project name per line. If it returns JSON, flow-cli treats this as a failure and falls back to filesystem scan.

Filtered listing:

```
atlas project list --status=<filter> --format=names
```

Valid `--status` values: `active`, `parked`, `archived`, `all`.

---

## Breaking Change Policy

| Version Change | Policy |
|----------------|--------|
| Patch (0.9.x) | No breaking changes to contracted commands |
| Minor (0.x.0) | May add new commands. Deprecations require 1 minor version warning before removal |
| Output format | Changes require a new `--format` value. Existing format behavior MUST NOT change |
| Exit codes | Stable. New codes may be added; existing meanings MUST NOT change |

---

## Help Format Convention

flow-cli wraps Atlas help with its own `_at_help()` function. Atlas's native `--help` output is NOT shown to users directly.

The flow-cli wrapper provides:

- Consistent color scheme (using flow-cli color variables from `lib/core.zsh`)
- ADHD-friendly grouping (MOST COMMON, SESSION, CAPTURE, etc.)
- Install instructions when Atlas is not available
- Dispatcher-pattern help format matching all other flow-cli dispatchers

---

## Testing

Contract compliance is verified by `tests/test-atlas-contract.zsh`.

- Tests validate exit codes, output formats, and command availability
- Tests skip gracefully when Atlas is not installed (`[SKIP] Atlas not installed`)
- Hot path fallbacks are tested independently of Atlas availability
