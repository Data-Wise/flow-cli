# SPEC: em Delete, Move, Restore + Enhanced Catch/Todo/Event/Flag

| Field       | Value                                   |
| ----------- | --------------------------------------- |
| Version     | 1.0                                     |
| Date        | 2026-02-20                              |
| Author      | DT + Claude                             |
| Branch      | `feature/em-delete-actions`             |
| Status      | Ready                                   |
| Dispatcher  | `em` (email-dispatcher.zsh)             |

---

## Overview

Complete the `em` dispatcher's email management lifecycle: read, reply, **delete**, **move**, **restore**, **flag**, capture **todos**, create calendar **events** -- all from one dispatcher.

### Problem

1. **Bug:** `em pick` Ctrl+D only adds the IMAP `\Deleted` flag via `_em_hml_flags` -- it does NOT move the email to Trash. The correct himalaya command is `himalaya message delete` which moves to Trash.
2. **Missing features:** No standalone delete command, no batch deletion, no move/restore, and `em catch` only does quick capture -- no todo list or calendar event extraction.

### Goal

7 new commands, restructured fzf multi-select picker, 4 new test files (~36 test functions).

---

## User Stories

1. **As a professor**, I want to delete emails from the CLI so I can triage my inbox without a GUI.
2. **As a professor**, I want batch delete (by folder, query, or multi-select) so I can clear spam/vendor emails quickly.
3. **As a professor**, I want `--purge` for permanent deletion with strong confirmation so I don't lose important mail accidentally.
4. **As a professor**, I want to move emails between folders so I can organize without leaving the terminal.
5. **As a professor**, I want to restore accidentally-deleted emails from Trash to INBOX with one command.
6. **As a professor**, I want AI to extract action items from emails into my flow capture + Reminders.app.
7. **As a professor**, I want AI to extract calendar events from emails into my flow capture + Calendar.app.
8. **As a professor**, I want to flag/unflag emails for follow-up from the CLI.
9. **As a professor**, I want `em pick` to support multi-select so I can act on multiple emails at once.

---

## Acceptance Criteria

- [ ] `em delete <ID>` moves email to Trash (not just flags)
- [ ] `em delete <ID1> <ID2>` batch deletes by IDs
- [ ] `em delete --folder Spam` deletes all in folder with confirmation (shows count)
- [ ] `em delete --query "newsletter"` deletes search matches with confirmation (shows count + samples)
- [ ] `em delete --pick` opens fzf multi-select for interactive delete
- [ ] `em delete --purge <ID>` permanently deletes with "yes" confirmation (not just "y")
- [ ] `em move <FOLDER> <ID>` moves email to target folder
- [ ] `em move --pick <ID>` opens fzf folder picker
- [ ] `em restore <ID>` moves from Trash to INBOX
- [ ] `em restore <ID> --to Archive` moves from Trash to specified folder
- [ ] `em todo <ID>` AI-extracts action items, feeds to `catch`, prompts for Reminders.app
- [ ] `em event <ID>` AI-extracts events (JSON), feeds to `catch`, prompts for Calendar.app
- [ ] `em flag <ID>` adds IMAP Flagged flag
- [ ] `em unflag <ID>` removes IMAP Flagged flag
- [ ] `em pick` supports Tab multi-select, new keybinds (Ctrl+O=todo, Ctrl+E=event, Ctrl+F=flag)
- [ ] All new commands have per-command help functions
- [ ] All confirmations default to NO
- [ ] All new features have test coverage (~36 test functions across 4 files)
- [ ] `source flow.plugin.zsh` loads without errors
- [ ] `em help` displays new MANAGE section

---

## Files to Modify

| File                                     | Changes                                                                 |
| ---------------------------------------- | ----------------------------------------------------------------------- |
| `lib/em-himalaya.zsh`                    | Add `_em_hml_delete`, `_em_hml_move`, `_em_hml_expunge`                |
| `lib/em-ai.zsh`                          | Add `_em_ai_todo_prompt`, add `[todo]=15` to timeout map               |
| `lib/dispatchers/email-dispatcher.zsh`   | Add 7 new commands, restructure `em pick`, update help + case statement |
| `tests/test-em-delete.zsh`               | New test file (~12 tests)                                               |
| `tests/test-em-move-restore.zsh`         | New test file (~8 tests)                                                |
| `tests/test-em-todo-event.zsh`           | New test file (~10 tests)                                               |
| `tests/test-em-flag.zsh`                 | New test file (~6 tests)                                                |

---

## Command Reference

### em delete

```yaml
em delete <ID> [<ID>...]       Move email(s) to Trash
em delete --folder <FOLDER>    Delete all in folder (confirms with count)
em delete --query "<SEARCH>"   Delete matching emails (confirms with count + samples)
em delete --pick               Interactive fzf multi-select delete
em delete --purge <ID>         PERMANENT delete (flag + expunge, requires "yes")
em delete --folder X --purge   PERMANENT delete all in folder

Aliases: em del, em rm
Safety: All deletes confirm [y/N] (default No). --purge requires typing "yes".
```text

### em move

```yaml
em move <FOLDER> <ID> [<ID>...]         Move email(s) to target folder
em move --from <SOURCE> <FOLDER> <ID>   Move from non-default source folder
em move --pick <ID> [<ID>...]           fzf folder picker -> move to selected folder

Aliases: em mv
```text

### em restore

```text
em restore <ID> [<ID>...]       Move from $FLOW_EMAIL_TRASH_FOLDER (default: Trash) to INBOX
em restore <ID> --to <FOLDER>   Move from Trash to specific folder
```text

### em todo

```yaml
em todo <ID> [<ID>...]   Extract action items via AI, capture to flow + Reminders.app

Flow: read email -> AI extract action items -> catch command -> Reminders.app (per-email confirm)
Fallback: Uses email subject if AI unavailable
```text

### em event

```yaml
em event <ID> [<ID>...]   Extract dates/times via AI, capture to flow + Calendar.app

Flow: read email -> AI extract events (JSON) -> display -> catch -> Calendar.app (per-email confirm)
Returns: title, date, time, duration, location for each extracted event
```text

### em flag / em unflag

```text
em flag <ID> [<ID>...]     Star email for follow-up (IMAP Flagged)
em unflag <ID> [<ID>...]   Remove star
Aliases: em fl
```text

### em pick (updated)

```yaml
em pick [FOLDER]   Interactive fzf browser with multi-select

Keybinds:
  Tab/Shift-Tab    Toggle selection on focused email
  Enter            Read (single) or action menu (multi-selected, per D4)
  Ctrl+D           Delete selected email(s)
  Ctrl+R           Reply to focused email
  Ctrl+A           Archive (mark read) selected email(s)
  Ctrl+S           Summarize focused email
  Ctrl+T           Catch (capture) selected email(s)
  Ctrl+O           Extract todos from selected email(s)
  Ctrl+E           Extract events from selected email(s)
  Ctrl+F           Flag selected email(s) for follow-up
  Esc              Exit picker
```text

---

## Architecture

### Adapter Layer (`lib/em-himalaya.zsh`)

Three new functions isolate all himalaya CLI specifics:

```text
_em_hml_delete(folder, IDs...)   -> himalaya message delete -f <folder> <ID>...
_em_hml_move(src, dst, IDs...)   -> himalaya message move -f <src> <dst> <ID>...
_em_hml_expunge(folder)          -> himalaya folder expunge <folder>
```text

### AI Layer (`lib/em-ai.zsh`)

One new prompt function + timeout entry:

```bash
_em_ai_todo_prompt()   -> Extract action items (1 per line, max 5, plain text)
[todo]=15              -> Added to _EM_AI_OP_TIMEOUT map
```text

Reuse existing `_em_ai_schedule_prompt` for event extraction (already returns JSON with events array).

### Dispatcher Layer (`lib/dispatchers/email-dispatcher.zsh`)

New functions: `_em_delete`, `_em_move`, `_em_restore`, `_em_todo`, `_em_event`, `_em_flag`, `_em_unflag`

Helper functions: `_em_delete_confirm`, `_em_create_calendar_event`, `_em_create_reminder`

### Existing Code to Reuse

| What                       | Where                        | How                                 |
| -------------------------- | ---------------------------- | ----------------------------------- |
| `_em_hml_flags`            | `em-himalaya.zsh:223`        | Used by `em flag`/`em unflag`       |
| `_em_ai_schedule_prompt`   | `em-ai.zsh:289`              | Reuse for `em event`                |
| `_em_ai_query`             | `em-ai.zsh:46`               | Core AI call for todo/event         |
| `catch` command            | `commands/capture.zsh:15`    | Feed todo/event items into flow     |
| `_em_hml_list`             | `em-himalaya.zsh:45`         | Email metadata for confirmations    |
| `_em_hml_search`           | `em-himalaya.zsh:176`        | Used by `em delete --query`         |
| `_em_preview_message`      | `email-dispatcher.zsh:576`   | Reuse in `em delete --pick` preview |
| `_em_confirm_send` pattern | `email-dispatcher.zsh:418`   | Pattern for safety confirmations    |
| Test mock pattern          | `tests/test-em-catch.zsh:27` | Save/restore/mock for all tests     |

---

## Safety Model

### Confirmation Tiers

| Action             | Confirmation      | Default |
| ------------------ | ----------------- | ------- |
| Single delete      | `[y/N]`           | No      |
| Batch delete (IDs) | `[y/N]` + count   | No      |
| Folder delete      | `[y/N]` + count   | No      |
| Query delete       | `[y/N]` + count + first 5 subjects | No |
| `--purge` (single) | Type "yes"        | No      |
| `--purge` (folder) | Type "yes" + count | No     |
| Move               | None (reversible)  | --      |
| Restore            | None (reversible)  | --      |
| Flag/Unflag        | None (reversible)  | --      |
| Todo Reminders.app | `[y/N]` per email  | No      |
| Event Calendar.app | `[y/N]` per email  | No      |

### `_em_delete_confirm` Helper

Shows count + first 5 subjects from the target set. Returns 0 if user confirms, 1 if declined.

```sql
  Delete 12 emails from Spam?
    1. "Get rich quick scheme"
    2. "Exclusive textbook offer"
    3. "Free webinar: AI in Education"
    4. "Your subscription renewal"
    5. "Limited time deal"
    ... and 7 more
  Confirm delete? [y/N]
```yaml

---

## fzf Multi-Select UX Design

### Current State (broken)

- `--no-multi` on line 742 (single-select only)
- Ctrl+D calls `_em_hml_flags add $id Deleted` (wrong -- only flags, doesn't move to Trash)
- No todo, event, or flag keybinds

### New State

- Replace `--no-multi` with `--multi`
- Tab/Shift-Tab for selection toggling (standard fzf behavior)
- All `--bind` uses `{+1}` (multi-select placeholder) instead of `{1}`
- Enter with single selection: read email (current behavior)
- Enter with multi-selection (>1): show action menu (delete / move / flag / catch / cancel) per D4

### Updated Header

```text
Folder: INBOX  |  Unread: 5
Tab=select  Enter=read  Ctrl-D=delete  Ctrl-R=reply  Ctrl-A=archive
Ctrl-S=summarize  Ctrl-T=catch  Ctrl-O=todo  Ctrl-E=event  Ctrl-F=flag
```text

### Action Router

```text
Parse selected -> extract action prefix + IDs
Single-item actions (read, reply, summarize): process first ID only
Multi-item actions (delete, archive, catch, todo, event, flag): process all IDs
```zsh

---

## macOS Integration

### Calendar.app (`_em_create_calendar_event`)

Uses macOS default calendar (no `tell calendar` nesting -- per D2).

```zsh
_em_create_calendar_event() {
    local title="$1" edate="$2" etime="${3:-09:00}" duration="${4:-60}" location="${5:-}"
    [[ "$(uname)" != "Darwin" ]] && return 1
    osascript <<APPLESCRIPT
        tell application "Calendar"
            make new event at end of events of default calendar with properties {
                summary:"$title",
                start date:date "$edate $etime",
                location:"$location"
            }
        end tell
APPLESCRIPT
}
```zsh

### Reminders.app (`_em_create_reminder`)

Uses default Reminders list (per D3).

```zsh
_em_create_reminder() {
    local title="$1"
    [[ "$(uname)" != "Darwin" ]] && return 1
    osascript -e "tell application \"Reminders\" to make new reminder with properties {name:\"$title\"}"
}
```diff

Both gated behind `[[ "$(uname)" == "Darwin" ]]`. Non-macOS gracefully skips.

---

## Test Plan

Follow pattern from `tests/test-em-catch.zsh`:
- Source `test-framework.zsh`, setup/cleanup with mock registry
- Mock `_em_require_himalaya`, `_em_hml_*`, `_em_ai_query` as needed
- Non-interactive via `exec < /dev/null`

### test-em-delete.zsh (~12 tests)

| Test                            | Validates                                      |
| ------------------------------- | ---------------------------------------------- |
| `test_delete_requires_id`       | No args returns error                          |
| `test_delete_single`            | Calls `_em_hml_delete` with correct ID         |
| `test_delete_batch`             | Passes multiple IDs to adapter                 |
| `test_delete_folder_confirm`    | Shows count, requires confirmation             |
| `test_delete_folder_decline`    | Default NO prevents deletion                   |
| `test_delete_query_confirm`     | Shows samples + count                          |
| `test_delete_query_decline`     | Default NO prevents deletion                   |
| `test_delete_purge_requires_yes`| Typing "y" is NOT enough for purge             |
| `test_delete_purge_full_yes`    | Typing "yes" triggers flag + expunge           |
| `test_delete_purge_folder`      | Folder purge shows count + requires "yes"      |
| `test_delete_pick_requires_fzf` | Returns error if fzf not found                 |
| `test_delete_aliases`           | `del` and `rm` route to `_em_delete`           |

### test-em-move-restore.zsh (~8 tests)

| Test                            | Validates                                      |
| ------------------------------- | ---------------------------------------------- |
| `test_move_requires_args`       | No args returns error                          |
| `test_move_calls_adapter`       | Correct source/target/ID passed to adapter     |
| `test_move_batch`               | Multiple IDs passed through                    |
| `test_move_from_flag`           | `--from` overrides default source folder       |
| `test_restore_defaults_inbox`   | Default target is INBOX, source is Trash       |
| `test_restore_to_flag`          | `--to` overrides default target folder         |
| `test_restore_batch`            | Multiple IDs passed through                    |
| `test_move_aliases`             | `mv` routes to `_em_move`                      |

### test-em-todo-event.zsh (~10 tests)

| Test                            | Validates                                      |
| ------------------------------- | ---------------------------------------------- |
| `test_todo_requires_id`         | No args returns error                          |
| `test_todo_ai_path`             | AI extracts items, feeds to catch              |
| `test_todo_fallback_subject`    | Falls back to subject when AI fails            |
| `test_todo_empty_content_fails` | Empty email content returns error              |
| `test_todo_batch_processes_each`| Multiple IDs each get processed                |
| `test_event_requires_id`        | No args returns error                          |
| `test_event_ai_json_parse`      | Parses events array from AI JSON               |
| `test_event_empty_events`       | Empty events array shows "no events found"     |
| `test_event_feeds_catch`        | Events fed to catch command                    |
| `test_event_batch`              | Multiple IDs each get processed                |

### test-em-flag.zsh (~6 tests)

| Test                            | Validates                                      |
| ------------------------------- | ---------------------------------------------- |
| `test_flag_requires_id`         | No args returns error                          |
| `test_flag_adds_flagged`        | Calls `_em_hml_flags add <ID> Flagged`         |
| `test_flag_batch`               | Multiple IDs each get flagged                  |
| `test_unflag_removes_flagged`   | Calls `_em_hml_flags remove <ID> Flagged`      |
| `test_unflag_batch`             | Multiple IDs each get unflagged                |
| `test_flag_aliases`             | `fl` routes to `_em_flag`                      |

---

## Help Output Updates

### New MANAGE Section in `_em_help`

```text
MANAGE:
  em delete <ID>       Delete email (move to Trash)
  em delete --pick     Interactive multi-select delete
  em delete --purge    Permanent delete (requires "yes")
  em move <FOLDER> <ID>  Move email to folder
  em move --pick <ID>    fzf folder picker
  em restore <ID>      Restore from Trash to INBOX
  em flag <ID>         Star for follow-up
  em unflag <ID>       Remove star
```text

### Enhanced AI FEATURES Section

```text
AI FEATURES:
  em respond           Batch AI drafts for actionable emails
  em classify <ID>     Classify email (AI)
  em summarize <ID>    One-line summary (AI)
  em catch <ID>        Capture email as task
  em todo <ID>         Extract action items -> flow + Reminders.app
  em event <ID>        Extract events -> flow + Calendar.app
```diff

### Per-Command Help

- `_em_delete_help` -- shows all delete modes + safety info
- `_em_move_help` -- shows move + --from + --pick
- `_em_restore_help` -- shows restore + --to

---

## Implementation Steps Summary

| Step | Description                                    | Files                       |
| ---- | ---------------------------------------------- | --------------------------- |
| 1    | Adapter functions (delete, move, expunge)      | `lib/em-himalaya.zsh`       |
| 2    | AI todo prompt + timeout                       | `lib/em-ai.zsh`             |
| 3    | `em delete` command                            | `email-dispatcher.zsh`      |
| 4    | `em move` command                              | `email-dispatcher.zsh`      |
| 5    | `em restore` command                           | `email-dispatcher.zsh`      |
| 6    | `em flag` / `em unflag` commands               | `email-dispatcher.zsh`      |
| 7    | `em todo` command                              | `email-dispatcher.zsh`      |
| 8    | `em event` command + macOS helpers             | `email-dispatcher.zsh`      |
| 9    | Restructure `em pick` (multi-select + router)  | `email-dispatcher.zsh`      |
| 10   | Update help + case statement                   | `email-dispatcher.zsh`      |
| 11   | Tests (4 new files, ~36 functions)             | `tests/test-em-*.zsh`       |
| 12   | Doc updates                                    | CLAUDE.md, .STATUS          |

---

## Design Decisions (Resolved)

### D1: Trash folder name

**Decision:** Add `FLOW_EMAIL_TRASH_FOLDER` config variable, default `Trash`.

Office 365/Exchange uses "Deleted Items", Gmail IMAP uses "[Gmail]/Trash", standard IMAP uses "Trash". Follows existing `FLOW_EMAIL_FOLDER` pattern. One line in the config block:

```zsh
: ${FLOW_EMAIL_TRASH_FOLDER:=Trash}
```diff

`em restore` reads from this variable as the source folder.

### D2: Calendar app selection

**Decision:** Use macOS default calendar (no config). Omit the `tell calendar "..."` nesting in osascript -- let macOS route to whatever the user has set as default. If a specific calendar is needed later, that's a v2 config.

### D3: Reminders list

**Decision:** Use default Reminders list (no config). The simpler osascript `make new reminder with properties {name:...}` without specifying a list goes to the user's default Reminders list.

### D4: em pick Enter on multi-select

**Decision:** Action menu, not auto-delete. Auto-deleting on Enter is surprising UX -- Enter normally means "open/read."

- **Enter + 1 selected:** read (current behavior, no surprise)
- **Enter + N selected:** show a numbered action menu:

```text
3 emails selected:
  1. Delete
  2. Move
  3. Flag
  4. Catch
  q. Cancel
```

Dedicated Ctrl+D keybind remains the fast path for power users.

---

## Review Checklist

- [ ] Adapter functions match himalaya v1.1.0 CLI syntax
- [ ] All confirmations default to NO
- [ ] `--purge` requires full "yes" (not "y")
- [ ] macOS helpers gated behind `uname` check
- [ ] AI fallback chain works for todo/event
- [ ] fzf multi-select `{+1}` syntax correct
- [ ] No `local path=` (ZSH gotcha)
- [ ] Tests follow test-em-catch.zsh pattern
- [ ] `em help` output is complete and formatted
