# SPEC: flow claude v2 — Extended Checks + Watch

**Version target:** v7.13.0  
**Branch:** `feature/flow-claude-v2` from `dev`  
**Date:** 2026-06-19

---

## Summary

Extends `flow claude check` with four new checks (C4 two-tier, C7–C10) and adds
`flow claude watch` as a background health daemon with `terminal-notifier` alerts.
Ships as a single PR.

---

## Check Changes

### C4 (existing): CLAUDE.md length — fix threshold

**Current:** warns at `> 100` lines  
**New:** two-tier

| Threshold | Severity | Message |
|-----------|----------|---------|
| > 100 | WARN | `$n lines — approaching 180-line limit (trim before adding)` |
| > 180 | ERROR | `$n lines — exceeds 180-line hard limit (see ~/.claude/rules/claude-md-length.md)` |

File: `commands/claude.zsh` in `_flow_claude_check`, C4 block.

---

## New Checks

### C7: Per-project CLAUDE.md audit

**What:** Scans all project-level CLAUDE.md files under `~/projects/**` for:

| Sub-check | Signal | Severity |
|-----------|--------|----------|
| C7a | Line count > 180 | WARN |
| C7b | `vX.Y.Z` string in file doesn't match `git describe --tags --abbrev=0` | WARN |

**Discovery:**
```zsh
find "${FLOW_CLAUDE_PROJECTS_ROOT:-$HOME/projects}" \
  -maxdepth 4 -name "CLAUDE.md" \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*"
```

**Version check guard:** only fires if `git -C "$proj_dir" describe --tags --abbrev=0 2>/dev/null` succeeds. Skip silently if no tags.

**Version extraction:** `grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$file"` — compares each match against the git tag. If any match differs, it's drift.

**Injectable env:** `FLOW_CLAUDE_PROJECTS_ROOT` for tests.

**Output example:**
```
⚠ C7 Project CLAUDE.md   3 issues (40 files scanned):
    flow-cli/CLAUDE.md: 380 lines (> 180)
    craft/CLAUDE.md: 203 lines (> 180)
    flow-cli/CLAUDE.md: version ref v7.11.0 (current: v7.12.0)
✓ C7 Project CLAUDE.md   37 clean
```

---

### C8: Orphaned memory dirs

**What:** Checks `~/.claude/projects/` for dirs whose corresponding project path
no longer exists on disk. The dir name is a path slug (e.g.,
`-Users-dt-projects-dev-tools-flow-cli`) — decode by replacing `-` with `/`
(leading `-` → `/`).

**Decode logic:**
```zsh
slug="${dir##*/}"          # e.g. -Users-dt-projects-dev-tools-flow-cli
path="/${slug//-//}"       # /Users/dt/projects/dev-tools/flow-cli
path="${path// //}"        # collapse any double-slash artifacts
```

Flag if `[[ ! -d "$path" ]]`.

**Severity:** WARN (stale data, not broken behavior)

**Output example:**
```
⚠ C8 Orphaned memory     1 stale dir:
    -Users-dt-old-project (path /Users/dt/old-project not found)
✓ C8 Orphaned memory     12 dirs all valid
```

---

### C9: Rules drift

**What:** For each `.md` file in `~/.claude/rules/`, checks whether its stem
(filename without `.md`) appears anywhere in `~/.claude/CLAUDE.md`.

**Logic:**
```zsh
for rule_file in "$claude_home/rules"/*.md(N); do
  stem="${rule_file:t:r}"   # e.g. doc-update-currency-check
  if ! grep -qF "$stem" "$claude_home/CLAUDE.md" 2>/dev/null; then
    unreferenced+=("$stem")
  fi
done
```

**Severity:** WARN

**Output example:**
```
⚠ C9 Rules drift         1 unreferenced rule:
    my-old-rule (not mentioned in CLAUDE.md)
✓ C9 Rules drift         14 rules all referenced
```

---

### C10: Missing hook files

**What:** Reads `hooks` array from `~/.claude/settings.json` via `jq`, checks
each hook's `command` field for a file path — if the path is a script (starts
with `/` or `~`), verify it exists.

**jq extraction:**
```zsh
jq -r '(.hooks // {}) | to_entries[] | .value[] | .command' "$settings_json" 2>/dev/null
```

Flag paths that start with `/` or `~` and don't exist as files.

**Severity:** ERROR (missing hook = silent breakage)

**Requires:** `jq` (same guard as C1)

**Output example:**
```
✗ C10 Hook files          1 missing:
    /Users/dt/.claude/hooks/my-hook.sh (defined in settings.json, not found)
✓ C10 Hook files          5 hooks all present
```

---

### C11: Plugin health

**What:** For each directory under `~/.claude/plugins/` (excluding `cache/`),
check that `plugin.json` exists and is valid JSON.

```zsh
for plugin_dir in "$claude_home/plugins"/*(N/); do
  [[ "${plugin_dir:t}" == "cache" ]] && continue
  pjson="$plugin_dir/plugin.json"
  if [[ ! -f "$pjson" ]]; then
    broken+=("${plugin_dir:t}: missing plugin.json")
  elif ! jq empty "$pjson" 2>/dev/null; then
    broken+=("${plugin_dir:t}: invalid JSON in plugin.json")
  fi
done
```

**Severity:** WARN

---

## `flow claude watch`

### Subcommand routing

```zsh
case "$subcmd" in
  watch) _flow_claude_watch "$@" ;;
```

### Interface

```
flow claude watch               # start watcher (30-min default)
flow claude watch --interval N  # start with N-minute interval
flow claude watch --stop        # kill watcher
flow claude watch --status      # PID + last check result + time since last run
```

### State file: `~/.flow/claude-health-state.json`

```json
{
  "pid": 12345,
  "interval": 1800,
  "last_check": "2026-06-19T17:30:00Z",
  "result": "warn",
  "checks": {
    "C1": "pass", "C2": "pass", "C3": "warn",
    "C4": "pass", "C5": "info", "C6": "pass",
    "C7": "warn", "C8": "pass", "C9": "pass",
    "C10": "pass", "C11": "pass"
  }
}
```

### Daemon lifecycle

```zsh
_flow_claude_watch_start() {
  local interval=$(( ${1:-30} * 60 ))
  local pid_file="$HOME/.flow/claude-watch.pid"
  local state_file="$HOME/.flow/claude-health-state.json"
  local log_file="$HOME/.flow/claude-watch.log"

  # Stale PID check
  if [[ -f "$pid_file" ]]; then
    local old_pid=$(< "$pid_file")
    if kill -0 "$old_pid" 2>/dev/null; then
      _flow_log_warning "watch already running (PID $old_pid) — use --stop first"
      return 1
    fi
    rm -f "$pid_file"
  fi

  # Launch background loop
  (
    print $$ > "$pid_file"
    while true; do
      _flow_claude_watch_run_check "$state_file" >> "$log_file" 2>&1
      tail -c 50000 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
      sleep "$interval"
    done
  ) &
  disown $!
  _flow_log_success "watch started (PID $!, interval ${1:-30}m)"
}
```

### Notification logic

Only notify on **state change at WARN or ERROR level**. C5 (`info`) never triggers.

```zsh
_flow_claude_watch_notify() {
  local prev_result="$1"  # pass/warn/error
  local new_result="$2"
  local summary="$3"

  [[ "$prev_result" == "$new_result" ]] && return  # no change, silent

  # Only notify if new or old state is warn/error (ignore info↔pass)
  if [[ "$new_result" == "pass" && "$prev_result" == "pass" ]]; then return; fi

  local title="flow claude"
  local subtitle message
  if [[ "$new_result" == "pass" ]]; then
    subtitle="Health restored"
    message="All checks passing"
  elif [[ "$new_result" == "error" ]]; then
    subtitle="Health degraded — ERROR"
    message="$summary"
  else
    subtitle="Health warning"
    message="$summary"
  fi

  if command -v terminal-notifier &>/dev/null; then
    terminal-notifier -title "$title" -subtitle "$subtitle" \
      -message "$message" -sound default
  fi
  # Silent fallback on Linux (no terminal-notifier)
}
```

### `--status` output

```
● flow claude watch   running (PID 12345, interval 30m)
  Last check: 4 min ago — WARN
  C3 Memory index drift, C7 Project CLAUDE.md (2 issues)
```

If not running:
```
○ flow claude watch   not running
  Last check: 2026-06-19 17:30 — WARN (watcher was stopped)
```

---

## Help text additions

```
  flow claude watch              Start background health watcher (30-min default)
  flow claude watch --stop       Stop watcher
  flow claude watch --status     Show watcher status + last result
  flow claude watch --interval N Set poll interval in minutes

Checks:
  C7  Project CLAUDE.md  per-project line count + version drift
  C8  Orphaned memory    ~/.claude/projects/ dirs for deleted projects
  C9  Rules drift        ~/.claude/rules/*.md files not cited in CLAUDE.md
  C10 Hook files         hooks in settings.json pointing to missing scripts
  C11 Plugin health      ~/.claude/plugins/ dirs missing valid plugin.json
```

---

## Files to change

| File | Change |
|------|--------|
| `commands/claude.zsh` | C4 two-tier, C7–C11, `watch` subcommand + helpers |
| `completions/_flow_claude` | add `watch`, `--interval`, `--stop`, `--status` |
| `man/man1/flow.1` | document new subcommand + checks |
| `tests/test-flow-claude.zsh` | new test cases for C4 two-tier, C7–C11, watch |

---

## Test cases (new)

| Test | What |
|------|------|
| C4: 95 lines → pass | under both thresholds |
| C4: 150 lines → warn | over 100, under 180 |
| C4: 200 lines → error | over 180 |
| C7: fixture with 200-line CLAUDE.md → warn | line count breach |
| C7: fixture with stale version tag → warn | version drift (mock git describe) |
| C7: no git tags → skip version check | no false positive |
| C8: slug decodes to missing dir → warn | orphan detection |
| C8: slug decodes to valid dir → pass | no false positive |
| C9: rule stem missing from CLAUDE.md → warn | unreferenced rule |
| C9: all rules referenced → pass | clean |
| C10: hook path missing → error | missing file |
| C10: no hooks in settings → pass | skip gracefully |
| C11: plugin missing plugin.json → warn | broken plugin |
| C11: plugin has invalid JSON → warn | parse error |
| watch --stop: kills PID, removes pid file | lifecycle |
| watch --status: not running → clean message | no crash |
| watch notify: warn→pass fires notifier | state change |
| watch notify: pass→pass silent | no spam |

---

## Implementation order

1. C4 two-tier fix (minimal, safe)
2. C8 orphaned memory (pure ZSH, no new deps)
3. C9 rules drift (pure ZSH)
4. C10 missing hooks (needs jq, same guard as C1)
5. C11 plugin health (needs jq)
6. C7 per-project scan (needs `_flow_find_project_claude_mds` helper + git calls)
7. `flow claude watch` daemon (background process management)
8. Tests for all above
9. Help text + man page + completions

---

**Status:** SPEC ONLY — no implementation
