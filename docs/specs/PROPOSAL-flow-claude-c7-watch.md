# PROPOSAL: flow claude C7 + --watch

**Date:** 2026-06-19  
**Context:** Extensions to `flow claude check` (shipped in v7.12.0)

---

## Feature 1: C7 — Per-project CLAUDE.md audit

### What

C4 already checks `~/.claude/CLAUDE.md` (global, length only).  
C7 scans **all project-level CLAUDE.md files** under `~/projects/**` for three
degradation signals:

| Sub-check | Signal | Severity |
|-----------|--------|----------|
| C7a Line count | > 180 lines (global rule = 180; project files creep too) | WARN |
| C7b Version drift | Hardcoded `vX.Y.Z` strings that don't match the project's current version | WARN |
| C7c Last-updated staleness | File not touched in > 90 days while the project has recent git activity | INFO |

### Scope

- Discovery: `find ~/projects -maxdepth 3 -name "CLAUDE.md"` (skip `.git/`)
- ~40 files currently; scan is fast (wc/grep, no external tools)
- injectable via `FLOW_CLAUDE_PROJECTS_ROOT` for tests
- Default: skip dirs matching `/.git/` and `/node_modules/`
- Version check: only fires if the CLAUDE.md is inside a git repo and
  `git describe --tags --abbrev=0` succeeds; compares against any `vX.Y.Z`
  pattern in the file

### Output

```
ℹ C7 Project CLAUDE.md   scanned 40 files
✓ C7 Project CLAUDE.md   38 clean
⚠ C7 Project CLAUDE.md   2 issues:
    craft/CLAUDE.md: 203 lines (> 180)
    flow-cli/CLAUDE.md: version ref v7.11.0 (current: v7.12.0)
```

### Complexity: Medium
- Pure ZSH + grep/wc — no new deps
- Needs a `_flow_find_project_claude_mds` helper (reusable)
- Version extraction from CLAUDE.md: grep `v[0-9]+\.[0-9]+\.[0-9]+` patterns
- Test: inject `FLOW_CLAUDE_PROJECTS_ROOT` pointing to a fixture dir

---

## Feature 2: `flow claude watch`

### What

Background daemon that runs the full C1–C7 suite on a timer, notifies on state
change (pass → warn/error or vice versa), and stores last-known state so the
next `flow claude check` can show a diff.

### Design

```
flow claude watch [--interval N]   # start watcher (default: 30 min)
flow claude watch --stop           # kill watcher
flow claude watch --status         # show watcher PID + last check result
```

State file: `~/.flow/claude-health-state.json`

```json
{
  "last_check": "2026-06-19T17:30:00Z",
  "result": "warn",
  "checks": {
    "C1": "pass", "C2": "pass", "C3": "warn",
    "C4": "pass", "C5": "pass", "C6": "pass", "C7": "pass"
  }
}
```

Notification (macOS via `terminal-notifier`):

```
terminal-notifier \
  -title "flow claude" \
  -subtitle "Health degraded" \
  -message "C3 Memory index drift — testproj: 3 files, 2 entries" \
  -sound default
```

Notification only fires on **state change** (pass→warn, warn→error, any→pass).
Silent poll otherwise — no notification spam.

Daemon lifecycle:
- PID stored in `~/.flow/claude-watch.pid`
- `flow claude watch` checks for existing PID before starting
- Watcher runs `_flow_claude_check` in a subshell; output goes to
  `~/.flow/claude-watch.log` (last 100 lines kept via tail)
- On `--stop`: `kill $(cat ~/.flow/claude-watch.pid)`

### Complexity: Medium-high
- ZSH background process management (`&`, `disown`)
- PID file lifecycle (stale PID detection via `kill -0`)
- `terminal-notifier` dep (already installed; graceful fallback to `print`)
- No new external deps on Linux CI (guard with `command -v terminal-notifier`)
- Tests: mock `_flow_claude_check` exit codes, assert state file transitions

---

## Implementation Plan

### Quick Wins (< 30 min)
1. **C7a line count only** — 10-line addition to `_flow_claude_check`; reuses
   `wc -l` pattern from C4; injectable root via env var; single test case

### Medium Effort (2–3 hrs each)
- [ ] **C7 full** (a+b+c) — discovery helper, version extraction, staleness check,
  injectable fixture, 6–8 tests
- [ ] **`flow claude watch` core** — background loop, PID file, state JSON,
  notifier integration, `--stop`/`--status` subcommands, 4–5 tests

### Long-term (future)
- [ ] `flow claude watch --on-fix` — auto-run `--fix` when state degrades on
  fixable checks (C1, C6)
- [ ] `precmd` hook variant — check on every new shell prompt (1-second cached
  check, badge in prompt if degraded)
- [ ] `flow doctor` integration — expose C7 + watch status in the full doctor
  output

## Recommended Next Step

→ **C7a first** (line count across all project CLAUDE.md files) — 30-min win,
ships in the next patch, gives immediate value and proves the discovery helper
before adding version/staleness checks. Then C7b+c as a follow-on. Watch is
a separate worktree feature.

---

**Scope decision needed before starting:**

1. C7: scope to `~/projects/**` only, or also scan `~/.claude/projects/*/` memory
   CLAUDE.md files? (Memory ones rarely have version refs — probably skip.)
2. Watch interval: 30 min default, or configurable only (no default)?
3. Watch notifier: notification-center only, or also `osascript` speech fallback?
