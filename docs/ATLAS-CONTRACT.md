# Atlas CLI API Contract

**Version:** 1.1.0
**Parties:** flow-cli (v7.10.x) <-> Atlas CLI `@data-wise/atlas` (v0.9.3)
**Status:** Active

---

## Version Compatibility

| flow-cli | Atlas CLI | Notes |
|----------|-----------|-------|
| v7.10.x  | v0.9.3    | Contract v1.1 — 5 new integration flags (`session status --format`, `project list --count`, `project list --suggest`, `inbox --count`, `trail --limit`) |
| v7.4.x   | v0.9.x    | Contract v1.0 — original contract |
| v7.3.x   | v0.8.x    | Legacy — no `crumb` command |
| v7.5.x   | v1.0.x    | Planned — stable API |

---

## Required Commands (Hot Path)

These 7 commands are bridged with ZSH-native fallbacks when Atlas is not installed. flow-cli calls these in performance-critical paths and MUST NOT block if Atlas is unavailable.

| Command | Usage in flow-cli | Fallback (no Atlas) | Output Format |
|---------|-------------------|---------------------|---------------|
| `atlas session start <project>` | `_flow_session_start` | worklog file | exit 0 |
| `atlas session end [note]` | `_flow_session_end` | worklog file | exit 0 |
| `atlas catch <text> [--project=X]` | `_flow_catch` | inbox.md | exit 0 |
| `atlas inbox` | `_flow_inbox` | cat inbox.md | text |
| `atlas inbox --count` | `_flow_inbox_count` | echo "0" | bare integer (pending inbox count) |
| `atlas where [project]` | `_flow_where` | filesystem detection | text |
| `atlas crumb <text> [--project=X]` | `_flow_crumb` | trail.log | exit 0 |

---

## Warm Path Commands (Atlas CLI Required)

These commands require Atlas CLI. flow-cli shows an install message if Atlas is not available. No ZSH-native fallback exists.

| Command | Description | Output Format |
|---------|-------------|---------------|
| `atlas session status` | Current session state | `table` (default); `--format=json` → `{project,durationMinutes,state,task,startedAt}` or `null` when idle |
| `atlas stats` | Project statistics | table |
| `atlas config show` | Full configuration as pretty JSON | JSON — top-level `storage` key is the backend (`filesystem` \| `sqlite`) |
| `atlas plan` | Planning view | table |
| `atlas park [project]` | Park a project | text |
| `atlas unpark [project]` | Unpark a project | text |
| `atlas parked` | List parked projects | names (one per line) |
| `atlas dash` / `atlas dashboard` | Dashboard view | table |
| `atlas focus [project]` | Set focus project | text |
| `atlas triage` | Triage inbox items | interactive |
| `atlas trail` | Show breadcrumb trail | text |
| `atlas trail --limit <n>` | Breadcrumb trail, capped at n entries (most recent first) | text |

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

Format support is **per-command**, not universal. The `--format` flag is only valid for the commands listed below.

### Per-Command Format Support Matrix

| Command | Supported `--format` values | Default | Notes |
|---------|----------------------------|---------|-------|
| `atlas project list` | `table`, `json`, `names` | `table` | `names` = one name per line, no headers |
| `atlas project show` | `table`, `json`, `names`, `shell` | `table` | `shell` = key=value pairs |
| `atlas session status` | `table`, `json` | `table` | `json` emits `{project,durationMinutes,state,task,startedAt}` or `null` when idle |
| `atlas stats` | `table`, `json`, `text`, `md` | `table` | |
| `atlas session export` | `ical`, `json` | `ical` | |
| `atlas plan` | *(n/a)* | n/a | Use `--json` flag for machine-readable output |

### Format Descriptions

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

**`--count` flag (v0.9.3+):**

```
atlas project list --count
atlas project list --status=active --count
```

Prints a bare integer (count of matched projects). Combinable with `--status`. Exits 0.

**`--suggest` flag (v0.9.3+):**

```
atlas project list --suggest
```

Prints ONE project name — the most-recently-touched active project. Prints nothing (empty output) if no active projects exist. Exits 0.

---

## `atlas inbox --count` Contract (v0.9.3+)

```
atlas inbox --count
```

Prints a bare integer (count of pending inbox captures, i.e. `status=inbox`). Exits 0.

---

## `atlas trail --limit` Contract (v0.9.3+)

```
atlas trail --limit <n>
```

Caps the breadcrumb entries shown to the `n` most recent. Exits 0. Output format is text (unchanged from `atlas trail`).

---

## `atlas session status --format=json` Contract (v0.9.3+)

```
atlas session status --format=json
```

Emits a JSON object when a session is active:

```json
{
  "project": "<project-name>",
  "durationMinutes": 42,
  "state": "active",
  "task": "<task text or null>",
  "startedAt": "2026-06-14T09:00:00.000Z"
}
```

Emits `null` (the literal JSON value) when no session is active. Always exits 0.

---

## `atlas config show` Contract (consumed by `flow doctor`)

```
atlas config show
```

Prints the **entire** atlas configuration as pretty-printed JSON
(`JSON.stringify(config, null, 2)` — always JSON, there is no `--format` flag on
this command). The top-level **`storage`** key is the active backend
(`filesystem` | `sqlite`); other keys include scan paths and `preferences`. Exits 0.

`flow doctor` consumes this for two things: (a) a **liveness check** — a non-empty
result is the connectivity signal, because a binary on `PATH` alone does not prove
atlas actually runs (e.g. a broken interpreter shebang); and (b) reading the
storage backend. Note there is **no `atlas config get <key>` subcommand** — read a
single value by parsing `config show`.

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

Contract compliance is verified by two test files:

- **`tests/test-atlas-contract.zsh`** — validates exit codes, output formats, and command availability; skips gracefully when Atlas is not installed (`[SKIP] Atlas not installed`); hot path fallbacks tested independently of Atlas availability
- **`tests/test-doctor-atlas-calls.zsh`** — static regression guard (grep-based, no Atlas needed); enforces that `doctor.zsh` uses spec-compliant calls (`atlas config show`, `command -v atlas-mcp`) and does not regress to the out-of-spec calls removed in v1.1.0
