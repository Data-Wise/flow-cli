# SPEC: Email Dispatcher Feature Expansion

> **Date:** 2026-02-18
> **Branch:** TBD (feature/em-features-v2)
> **Status:** Draft
> **From Brainstorm:** BRAINSTORM-em-features-2026-02-18.md

## Summary

Expand the `em` dispatcher with 5 quick-win features that fill gaps vs himalaya-mcp while staying true to em's terminal-native, keyboard-driven identity. Thread view, snooze, star, move, and digest bring em from "read/reply tool" to complete inbox management.

## Primary User Story

**As a** developer using flow-cli in the terminal,
**I want** to manage my full email workflow without leaving the shell,
**So that** I can triage, organize, and track emails with sub-second keyboard-driven commands.

## Acceptance Criteria

- [ ] `em thread <ID>` shows conversation thread as indented tree
- [ ] `em snooze <ID> <time>` moves email + schedules reminder
- [ ] `em star <ID>` toggles Flagged status; `em starred` lists flagged
- [ ] `em move <ID> <folder>` moves email; fzf folder picker when no folder given
- [ ] `em digest` generates AI-grouped daily summary in terminal format
- [ ] All new commands have `help` text following existing patterns
- [ ] All new commands are registered in the main case statement
- [ ] Tests added for each new command (unit + integration)
- [ ] Documentation updated: tutorial, guide, refcard

## Secondary User Stories

1. **As a** user who gets distracted by email, **I want** to snooze messages for later **so that** I can focus on current work without losing track.
2. **As a** user with multiple projects, **I want** to move emails to folders from the terminal **so that** I can organize without opening a web client.
3. **As a** user starting my day, **I want** a quick digest **so that** I know what's important without reading every email.

## Architecture

```mermaid
graph TD
    EM[em dispatcher] --> THREAD[em thread]
    EM --> SNOOZE[em snooze]
    EM --> STAR[em star]
    EM --> MOVE[em move]
    EM --> DIGEST[em digest]

    THREAD --> HML[himalaya CLI]
    SNOOZE --> HML
    SNOOZE --> NOTIFY[terminal-notifier]
    SNOOZE --> SCHED[~/.flow/email-snooze/]
    STAR --> HML
    MOVE --> HML
    MOVE --> FZF[fzf folder picker]
    DIGEST --> HML
    DIGEST --> AI[_em_ai_query]
```text

All new features follow the existing adapter pattern — they delegate to `_em_hml_*` functions in `lib/em-himalaya.zsh` for CLI operations and use `_em_ai_query` for AI features.

## API Design

| Command | Args | Description |
|---------|------|-------------|
| `em thread <ID>` | `--depth N` (default: 10) | Show conversation thread |
| `em snooze <ID> <time>` | `2h`, `tomorrow`, `monday`, `1d` | Snooze email |
| `em snooze list` | — | Show snoozed emails |
| `em star <ID>` | — | Toggle Flagged status |
| `em starred` | `--count N` (default: 25) | List flagged emails |
| `em move <ID> [folder]` | fzf picker when folder omitted | Move to folder |
| `em digest` | `--week`, `--count N` | AI daily/weekly digest |

## Data Models

### Snooze Tracking

```text
~/.flow/email-snooze/
├── pending.json          # Active snooze entries
└── completed.json        # Expired (for cleanup)
```text

```json
{
  "snoozes": [
    {
      "msg_id": "42",
      "folder": "INBOX",
      "snoozed_at": "2026-02-18T10:00:00Z",
      "wake_at": "2026-02-18T14:00:00Z",
      "subject": "Budget review"
    }
  ]
}
```diff

N/A for thread, star, move, digest — these are stateless operations.

## Dependencies

- himalaya >= 1.0.0 (existing)
- jq (existing)
- fzf (existing, for move folder picker)
- terminal-notifier (optional, for snooze reminders)
- AI backend (existing, for digest)

## UI/UX Specifications

### Thread View

```text
em thread 42
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #38  Jane Smith         2026-02-15
  ├─ #40  You              2026-02-16
  │  └─ #42  Jane Smith    2026-02-18  ← current
  └─ #41  Bob Lee          2026-02-17
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```text

### Digest Output

```text
em digest
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
em digest — 2026-02-18

  🔴 Action Required (3)
    #42  Budget review — Jane Smith
    #45  PR approval needed — GitHub
    #47  Meeting reschedule — Bob

  🟡 FYI (5)
    #43  Weekly metrics — Analytics
    ...

  ⚪ Low Priority (12)
    newsletters, automated, etc.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  3 action required  5 FYI  12 low priority
```

### Accessibility

N/A — CLI tool, inherits terminal accessibility features.

## Open Questions

1. **Thread implementation:** Does himalaya's `--include-related` flag work reliably across IMAP providers? May need client-side threading via Message-ID/References headers.
2. **Snooze mechanism:** Pure file-based reminders (cron/launchd check) or integrate with macOS Reminders via osascript?

## Review Checklist

- [ ] All commands follow `_em_<name>` function naming
- [ ] All commands have `_em_<name>_help()` or fall through to `_em_help`
- [ ] Case statement aliases follow existing short patterns
- [ ] Config variables use `FLOW_EMAIL_*` prefix
- [ ] Safety gates (y/N) on destructive operations (move, snooze)
- [ ] Tests in `tests/test-em-*.zsh`
- [ ] Docs updated: EMAIL-TUTORIAL.md, EMAIL-DISPATCHER-GUIDE.md, REFCARD-EMAIL-DISPATCHER.md

## Implementation Notes

- **Order of implementation:** star (trivial, ~15 lines) → move (~25 lines) → thread (~40 lines) → snooze (~60 lines) → digest (~50 lines)
- **fzf integration:** Add Ctrl-M (move) and Ctrl-F (star/flag) binds to `em pick`
- **Shared with himalaya-mcp:** digest and thread concepts exist in himalaya-mcp (daily_email_digest prompt, read tool). The em versions should be terminal-optimized, not markdown-optimized.
- **Testing strategy:** Unit tests for each function + integration tests using himalaya mock from existing test framework

## History

| Date | Change |
|------|--------|
| 2026-02-18 | Initial spec from brainstorm session |
