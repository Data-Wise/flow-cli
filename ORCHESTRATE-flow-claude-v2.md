# ORCHESTRATE: flow claude v2 — Extended Checks + Watch

**Branch:** `feature/flow-claude-v2`  
**Spec:** `docs/specs/SPEC-flow-claude-v2.md`  
**Target:** v7.13.0

---

## Objective

Extend `flow claude check` with C4 two-tier fix and new checks C7–C11, then
add `flow claude watch` background daemon with terminal-notifier alerts on
WARN/ERROR state change.

---

## Task List

### Wave 1 — Existing file changes (no new files)

- [ ] **1a. Fix C4 two-tier threshold** (`commands/claude.zsh`)
  - Change single `if (( line_count > 100 ))` to two-tier:
    - `> 100` → `_flow_log_warning` + `has_warn=1`
    - `> 180` → `_flow_log_error` + `has_error=1`
  - Update help text: `C4  CLAUDE.md length      warns > 100 lines, errors > 180`
  - Tests: 95 lines → pass, 150 → warn, 200 → error

- [ ] **1b. Add C8: Orphaned memory dirs** (`commands/claude.zsh`)
  - After C7 block, iterate `${FLOW_CLAUDE_HOME:-$HOME/.claude}/projects/*/`
  - Decode slug to path: `/${slug//-//}` (leading `-` → `/`)
  - Flag if `[[ ! -d "$decoded_path" ]]`
  - Injectable: `FLOW_CLAUDE_HOME` (already used by C1–C4)
  - Tests: mock a slug for a nonexistent dir → warn; valid dir → pass

- [ ] **1c. Add C9: Rules drift** (`commands/claude.zsh`)
  - Iterate `$claude_home/rules/*.md`
  - Extract stem: `${rule_file:t:r}`
  - Check `grep -qF "$stem" "$claude_home/CLAUDE.md"`
  - Flag unreferenced stems
  - Tests: rule file not cited in CLAUDE.md → warn; all cited → pass

- [ ] **1d. Add C10: Missing hook files** (`commands/claude.zsh`)
  - Requires `jq` (guard same as C1)
  - Extract from settings.json: `jq -r '(.hooks // {}) | to_entries[] | .value[] | .command'`
  - For each command starting with `/` or `~`: check file exists
  - Severity: ERROR (not WARN — missing hook = silent breakage)
  - Tests: hook path missing → error; hook path present → pass; no hooks → pass

- [ ] **1e. Add C11: Plugin health** (`commands/claude.zsh`)
  - Iterate `$claude_home/plugins/*/` (skip `cache/`)
  - Check `plugin.json` exists + is valid JSON (`jq empty`)
  - Severity: WARN
  - Tests: missing plugin.json → warn; invalid JSON → warn; valid → pass

### Wave 2 — C7 (needs helper + git calls)

- [ ] **2a. Add `_flow_find_project_claude_mds` helper** (`commands/claude.zsh` or `lib/core.zsh`)
  - `find "${FLOW_CLAUDE_PROJECTS_ROOT:-$HOME/projects}" -maxdepth 4 -name "CLAUDE.md" -not -path "*/.git/*" -not -path "*/node_modules/*"`
  - Returns newline-separated paths via stdout

- [ ] **2b. Add C7: Per-project CLAUDE.md audit** (`commands/claude.zsh`)
  - Call `_flow_find_project_claude_mds` → iterate paths
  - C7a: `wc -l < "$file"` > 180 → warn
  - C7b: `git -C "$proj_dir" describe --tags --abbrev=0 2>/dev/null` → if succeeds,
    grep file for `v[0-9]+\.[0-9]+\.[0-9]+`, compare each match against tag;
    mismatch → warn; no tags → skip silently
  - Injectable: `FLOW_CLAUDE_PROJECTS_ROOT`
  - Tests: fixture dir with 200-line CLAUDE.md → warn; mocked git tag mismatch → warn;
    no tags → pass (no false positive)

### Wave 3 — Watch daemon

- [ ] **3a. Add `flow claude watch` routing** (`commands/claude.zsh`)
  - Add `watch)` case to `flow_claude()` dispatch
  - Parse `--stop`, `--status`, `--interval N` flags

- [ ] **3b. Implement `_flow_claude_watch_start`** (`commands/claude.zsh`)
  - Stale PID check via `kill -0`
  - Background loop: `_flow_claude_watch_run_check` → sleep → repeat
  - Log rotation: keep last 50KB of `~/.flow/claude-watch.log`
  - Write PID to `~/.flow/claude-watch.pid`
  - `disown $!` after backgrounding

- [ ] **3c. Implement `_flow_claude_watch_run_check`** (`commands/claude.zsh`)
  - Runs `_flow_claude_check` in a subshell, captures exit code
  - Translates exit code to result string: 0=pass, 1=error, 2=warn
  - Reads previous state from `~/.flow/claude-health-state.json`
  - Calls `_flow_claude_watch_notify` on state change
  - Writes new state JSON

- [ ] **3d. Implement `_flow_claude_watch_notify`** (`commands/claude.zsh`)
  - Only notify if new/old state is warn or error (skip info/pass↔pass)
  - `command -v terminal-notifier` guard — silent on Linux
  - Call: `terminal-notifier -title "flow claude" -subtitle "..." -message "..." -sound default`

- [ ] **3e. Implement `--stop` and `--status`** (`commands/claude.zsh`)
  - `--stop`: read PID file, `kill $pid`, remove pid file
  - `--status`: read state JSON, show PID/interval/last-check/result

- [ ] **3f. Update `_flow_claude_help`** with watch subcommand docs

### Wave 4 — Tests

- [ ] **4a. Tests for C4 two-tier, C8, C9, C10, C11** (`tests/test-flow-claude.zsh`)
  - Fixture dirs injected via `FLOW_CLAUDE_HOME` / `FLOW_CLAUDE_PROJECTS_ROOT`
  - See full test list in `SPEC-flow-claude-v2.md`

- [ ] **4b. Tests for C7** (`tests/test-flow-claude.zsh`)
  - Mock `git describe` via function override in test scope

- [ ] **4c. Tests for watch** (`tests/test-flow-claude.zsh`)
  - Mock `_flow_claude_check` exit code
  - Assert state file transitions
  - Assert `--stop` removes pid file
  - Assert `--status` doesn't crash when watcher is not running

### Wave 5 — Docs + completions

- [ ] **5a. Update `completions/_flow_claude`** — add `watch`, `--interval`, `--stop`, `--status`
- [ ] **5b. Update `man/man1/flow.1`** — document watch + new checks
- [ ] **5c. Update `CLAUDE.md`** — test count, suite count
- [ ] **5d. Update `TESTING.md`** — test count (3 locations)
- [ ] **5e. Update `CHANGELOG.md`** — Unreleased section

---

## Verification

After each wave:
```zsh
source flow.plugin.zsh
flow claude check
./tests/run-all.sh
```

Final gate before PR:
```zsh
./tests/run-all.sh  # expect 66/66 suites passing (+ new test-flow-claude tests)
flow claude check   # run against real ~/.claude — all checks should execute
flow claude watch --interval 1  # start 1-min watcher, verify state file written
flow claude watch --status       # confirm output
flow claude watch --stop         # confirm clean shutdown
```

---

## PR target

`gh pr create --base dev --title "feat(claude): C7-C11 checks + watch daemon (v7.13.0)"`
