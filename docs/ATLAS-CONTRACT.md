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
