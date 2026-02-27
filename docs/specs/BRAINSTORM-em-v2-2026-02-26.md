# BRAINSTORM: em Dispatcher v2.0 — Feature Parity + IMAP Watch

**Mode:** max (feature) | **Duration:** ~12 min | **Agents:** backend-architect, security-auditor
**Date:** 2026-02-26 | **Branch:** dev

---

## Context

Two parallel email interfaces exist:

- **em dispatcher** (flow-cli, pure ZSH, 2534 lines) — terminal-native, 31 subcommands
- **himalaya-mcp** (TypeScript MCP server, v1.3.1) — Claude AI-native, 19 tools + 4 prompts + 3 resources

Both wrap the same himalaya CLI (v1.2.0). They serve different contexts (terminal vs AI session) and should remain **independent layers** — no coupling.

## Decision Summary

| Question      | Answer                                            |
| ------------- | ------------------------------------------------- |
| Goal          | Feature parity + new capabilities                 |
| Architecture  | Independent layers (no MCP coupling)              |
| Features      | All 4 MCP parity items + IMAP watch               |
| Versioning    | Version detection with progressive enhancement    |
| Notifications | terminal-notifier (macOS native)                  |
| Safety scope  | Both send + reply get preview+confirm             |
| Version       | em v2.0 (major bump, breaking safety gate change) |
| Increments    | Single increment (one feature branch)             |

---

## Quick Wins (< 2 hours each)

1. **Version detection** (~30 lines) — `_em_hml_version()` + `_em_hml_version_gte()` + cache. Foundation for everything else.
2. **Folder CRUD** (~50 lines) — `em create-folder <name>`, `em delete-folder <name>` with confirm gate + folder name validation.
3. **Message ID validation** (~20 lines) — `_em_validate_msg_id()` fixing 6 jq injection surfaces (security fix).

## Medium Effort (2-4 hours each)

4. **Compose safety gate** (~200 lines) — Two-phase preview+confirm for `em send` and `em reply`. Temp file pattern. `--force` flag for power users. One-time v2 migration notice.
5. **Attachment improvements** (~80 lines) — `em attach list` (MIME info table), `em attach get <filename>` (download by name with path traversal protection).
6. **Security fixes** (~100 lines) — AppleScript injection (Finding 1), config source (Finding 3), terminal-notifier sanitization (Finding 4).

## Long-term (4-8 hours)

7. **ICS calendar parsing** (~120 lines, new file `lib/em-ics.zsh`) — Pure ZSH parser for basic VEVENT fields. Python enhancement as optional. 10-event limit. 1MB size gate.
8. **IMAP IDLE watch** (~150 lines, new file `lib/em-watch.zsh`) — Background `himalaya envelope watch` with PID management, terminal-notifier callback, start/stop/status/log subcommands.

---

## Agent Findings: Backend Architect

### Safety Gate Architecture

- **Pattern:** Temp file + function return codes (not env vars)
- **Return codes:** 0 = sent, 1 = error, 2 = user aborted
- **Confirm prompt:** `[y/N/e(dit)]` — edit option re-opens `$EDITOR` then re-previews
- **Breaking change:** One-time notice tracked via flag file

### IMAP IDLE Implementation

- `&!` (disown) for background process survival after shell exit
- PID file at `~/.flow/email-watch.pid` for lifecycle management
- Line-buffered pipe from `himalaya envelope watch` to handler
- No daemon complexity — shell convenience, not system service

### ICS Parsing

- **Pure ZSH feasible** for: single/multi VEVENT, basic fields, line folding
- **Not feasible in ZSH:** RRULE expansion, complex TZID conversion
- **Recommendation:** Ship pure ZSH parser, optional Python enhancement via `icalendar` library

### Estimated Code Delta

| File                                   | Change                                                 | Lines    |
| -------------------------------------- | ------------------------------------------------------ | -------- |
| `lib/em-himalaya.zsh`                  | Modified — version detect, folder CRUD, attach adapter | +80      |
| `lib/dispatchers/email-dispatcher.zsh` | Modified — safety gate, folder/attach commands         | +200     |
| `lib/em-ics.zsh`                       | New — ICS parser                                       | ~120     |
| `lib/em-watch.zsh`                     | New — IMAP IDLE watcher                                | ~150     |
| `lib/em-render.zsh`                    | Minor — ICS content type detection                     | +15      |
| `lib/em-cache.zsh`                     | Minor — version cache clear hook                       | +5       |
| **Total**                              |                                                        | **~570** |

---

## Agent Findings: Security Auditor

### Critical Findings (Fix in v2.0)

| #   | Finding                                                         | Location                       | Fix                                                             |
| --- | --------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| 1   | **AppleScript injection** via AI-extracted event title/location | email-dispatcher.zsh:1524-1568 | Use `osascript -e` with escaped vars, not heredoc interpolation |
| 7   | **Folder name injection** in planned CRUD                       | Planned adapter functions      | `--` terminator + `_em_validate_folder_name()` allowlist        |

### High Findings (Fix in v2.0)

| #   | Finding                                                               | Location                              | Fix                                                          |
| --- | --------------------------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------ |
| 2   | **jq filter injection** via unsanitized `$msg_id` (6 locations)       | email-dispatcher.zsh:332,630,994,1395 | `_em_validate_msg_id()` + `jq --argjson`                     |
| 3   | **Config file sourced as shell code**                                 | email-helpers.zsh:42-47               | Replace `source` with key=value parser                       |
| 4   | **terminal-notifier subject injection**                               | email-dispatcher.zsh:2094-2098        | Sanitize + truncate subjects before notification             |
| 8   | **Safety gate TOCTOU** (draft file modified between confirm and send) | Planned safety gate                   | Read into variable before confirm, send from variable        |
| 9   | **IMAP IDLE orphan/credential risks**                                 | Planned watch feature                 | PID file, single-instance guard, static notification strings |
| 10  | **ICS oversized/flooding**                                            | Planned ICS parsing                   | 1MB size gate, 10-event limit, no eval                       |
| 11  | **Attachment path traversal**                                         | Planned attach get                    | `realpath` containment check, sanitize filename              |

### Medium Findings

| #   | Finding                                   | Fix                         |
| --- | ----------------------------------------- | --------------------------- |
| 5   | `$body` argument injection in `script(1)` | Pass via temp file or stdin |
| 6   | Snooze file race condition                | `mktemp` for atomic write   |
| 12  | Temp directories not cleaned on SIGINT    | `trap` cleanup in subshell  |
| 13  | AI extra args flag injection              | Allowlist validation        |

---

## Risk Ranking (Implementation Order)

1. **Version detection** — lowest risk, foundation for all features
2. **Security fixes** — must land before new features add more attack surface
3. **Compose safety gate** — highest user value, sets safety precedent
4. **Folder CRUD** — quick win, deletion is destructive (needs confirm)
5. **Attachment improvements** — moderate risk (path traversal mitigated)
6. **ICS parsing** — edge cases with real-world ICS variants
7. **IMAP IDLE watch** — highest complexity, most failure modes (ship last, label experimental)

---

## Recommended Path

> Ship em v2.0 as flow-cli v7.5.0. Single feature branch, single increment.
> Fix all critical/high security issues as part of the same branch (not separate).
> Label `em watch` as experimental in help text.
> Total estimated new/modified: ~570 lines ZSH + ~200 lines security fixes + tests.

---

## Next Steps

1. Approve this brainstorm → auto-captured as spec (save action)
2. Create worktree: `feature/em-v2`
3. Write ORCHESTRATE plan to worktree
4. Implement in new session

---

_Generated by /workflow:brainstorm max feat save_
