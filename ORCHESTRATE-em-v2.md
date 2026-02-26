# ORCHESTRATE: em Dispatcher v2.0

**Feature Branch:** feature/em-v2
**Base:** dev (769625e4)
**Spec:** docs/specs/SPEC-em-v2-2026-02-26.md
**Target:** flow-cli v7.5.0
**Mode:** Swarm (isolated worktrees per agent, parallel execution)

---

## Swarm Configuration

| Agent | Worktree | Focus | Files (exclusive scope) |
|-------|----------|-------|------------------------|
| new-modules | swarm-new | ICS parser + IMAP watch | `lib/em-ics.zsh` (NEW), `lib/em-watch.zsh` (NEW) |
| security | swarm-security | Security fixes + version detection + adapter | `lib/em-himalaya.zsh`, `lib/email-helpers.zsh`, `lib/em-ai.zsh` |
| tests | swarm-tests | Test suites for all v2.0 features | `tests/test-em-v2-*.zsh` (NEW) |
| dispatcher | swarm-dispatcher | Safety gate + folder CRUD + attach + wiring | `lib/dispatchers/email-dispatcher.zsh`, `lib/em-render.zsh`, `lib/em-cache.zsh` |
| docs | swarm-docs | Documentation updates | `docs/**`, `completions/` |

**Merge order:** security → new-modules → tests → dispatcher → docs

---

## Wave 1: Parallel (3 agents, no file overlap)

### Agent: new-modules (swarm-new)

**Scope:** Create two NEW files — zero conflict risk.

#### Task 1: ICS Parser (`lib/em-ics.zsh`, ~120 lines)

Create pure ZSH ICS (iCalendar RFC 5545) parser:

```zsh
# Public functions
em_calendar "$msg_id"                      # Parse ICS from email attachment

# Internal functions
_em_ics_parse "$ics_file"                  # Pure ZSH VEVENT parser
_em_ics_parse_enhanced "$ics_file"         # Python icalendar fallback
_em_ics_extract_from_msg "$msg_id"         # Download ICS attachment to temp
_em_ics_format_dt "$raw_datetime"          # Format: YYYYMMDDTHHMMSS → 2026-02-26 14:00
_em_ics_display_event "$assoc_array_name"  # Colored terminal output
_em_ics_create_event "$summary" "$start" "$end" "$location"  # Apple Calendar via osascript
```

**Implementation details:**
- Parse `BEGIN:VEVENT` / `END:VEVENT` blocks line-by-line
- Handle line folding (RFC 5545 sec 3.1 — continuation lines start with space/tab)
- Extract fields: SUMMARY, DTSTART, DTEND, LOCATION, DESCRIPTION, ORGANIZER
- **Security gates:**
  - 1MB file size limit (`stat -f %z`)
  - 10-event maximum per ICS file
  - Sanitize all fields before AppleScript: `${var//[^[:print:]]/}`
  - Use `osascript -e` with escaped vars (NOT heredoc interpolation) — see Finding 1 fix
  - Calendar creation requires `[y/N]` confirm
- Optional Python enhancement: detect `python3` + `icalendar` at runtime, fall back to pure ZSH
- Source `lib/core.zsh` for `_flow_log_*` helpers

#### Task 2: IMAP Watch (`lib/em-watch.zsh`, ~150 lines)

Create IMAP IDLE background watcher:

```zsh
# Public functions
em_watch ["start"|"stop"|"status"|"log"]   # Subcommand dispatch

# Internal functions
_em_watch_start "$folder"                  # Start background himalaya envelope watch
_em_watch_stop                             # Kill background watcher via PID file
_em_watch_is_running                       # Check PID file + process alive
_em_watch_status                           # Report running/stopped + folder
_em_watch_log                              # Tail last 20 entries
_em_watch_handle_line "$line"              # Parse envelope, trigger notification
_em_watch_help                             # Help text
```

**Implementation details:**
- PID file: `${FLOW_STATE_DIR:-$HOME/.flow}/em-watch.pid` (mode 0600)
- Log file: `${FLOW_STATE_DIR:-$HOME/.flow}/em-watch.log`
- Use `&!` (disown) for background process survival after shell exit
- Single-instance guard: check PID file + `kill -0` before starting
- `himalaya envelope watch --folder "$folder"` piped to `while IFS= read -r line`
- **Notification:** `terminal-notifier -title "New Email" -message "$safe_subject" -group "flow-em-watch" -sound default`
- **Security:**
  - NEVER use `-execute` flag (prevents RCE via crafted subjects)
  - Sanitize subject: strip newlines, control chars, truncate to 100 chars
  - Static `-title` string (never from email content)
  - Rate limit: max 1 notification per 10 seconds
- Require `terminal-notifier` — check at start, clear error with install command
- `em doctor` integration: detect orphaned watch processes
- Label as **experimental** in help text

**Commit:** `feat: add em-ics.zsh and em-watch.zsh modules`

---

### Agent: security (swarm-security)

**Scope:** Fix security findings + add version detection in adapter layer.

#### Task 1: Version Detection (`lib/em-himalaya.zsh`, +80 lines)

Add to top of adapter file:

```zsh
_em_hml_version()                          # Parse himalaya --version, cache in $_EM_HML_VERSION
_em_hml_version_gte "$min_version"          # Semver compare using ${(s:.:)} split
_em_require_version "$ver" "$feature"       # Gate macro with user-friendly error
_em_hml_version_clear_cache                 # Clear $_EM_HML_VERSION (called by em doctor)
```

- Cache in session-scoped global `$_EM_HML_VERSION` (zero disk I/O)
- Parse: `himalaya --version` outputs `himalaya 1.2.0` → extract `1.2.0`
- Comparison: split on `.`, compare numeric major.minor.patch
- Edge case: handle `1.9.0` vs `1.10.0` correctly (numeric, not string compare)

#### Task 2: Adapter Functions (`lib/em-himalaya.zsh`)

Add new adapter functions:

```zsh
_em_hml_folder_create "$name"              # himalaya folder create -- "$name"
_em_hml_folder_delete "$name"              # himalaya folder delete -- "$name"
_em_validate_folder_name "$name"           # Reject empty, leading dash, /\, control chars, >255
_em_hml_attachment_list "$msg_id"           # Version-aware: JSON (v1.2+) or plain (v1.0)
_em_hml_attachment_download "$id" "$file" "$dir"
_em_hml_watch "$folder"                    # himalaya envelope watch --folder "$folder"
```

- All folder operations use `--` terminator before user-supplied name (Finding 7)
- All msg_id usage validated via `_em_validate_msg_id` (Finding 2)

#### Task 3: Security Fixes

**Finding 1 (Critical) — AppleScript injection** (`lib/em-himalaya.zsh` or wherever `_em_create_calendar_event` lives):
- Replace heredoc with `osascript -e` statements
- Escape all interpolated values: `${var//\"/\\\"}`
- Strip non-printable characters: `${var//[^[:print:]]/}`
- Fix global replace: `${var//\"/\'}` not `${var/\"/\'}` (was missing `//`)

**Finding 2 (High) — jq injection** (`lib/dispatchers/email-dispatcher.zsh` — coordinate with dispatcher agent):
- Add `_em_validate_msg_id()` function to adapter
- Returns 1 if not `^[0-9]+$`
- Dispatcher agent will call this + switch to `jq --argjson`

**Finding 3 (High) — Config source** (`lib/email-helpers.zsh`):
- Replace `source "$config_file"` with key=value parser `_em_load_config_safe()`
- Allowlist: FLOW_EMAIL_AI, FLOW_EMAIL_PAGE_SIZE, FLOW_EMAIL_FOLDER, FLOW_EMAIL_TRASH_FOLDER, FLOW_EMAIL_AI_TIMEOUT, FLOW_EMAIL_CACHE_MAX_MB, FLOW_EMAIL_CACHE_WARM
- Strip quotes from values, ignore unknown keys, skip comments/blanks

**Finding 5 (Medium) — Body arg injection** (`lib/em-himalaya.zsh`):
- Pass body via temp file or stdin instead of positional arg to `script(1)`
- `printf '%s' "$body" > "$tmpbody"` then pass file

**Finding 13 (Medium) — AI extra args** (`lib/em-ai.zsh`):
- Add `_em_ai_validate_extra_args()` allowlist: `^[-a-zA-Z0-9_[:space:]]*$`

**Finding 14 (Low) — Predictable log file** (`lib/em-himalaya.zsh`):
- Replace `em-reply-$$.log` with `mktemp` + `chmod 0600` + trap cleanup

**Commits:**
1. `fix(security): add message ID validation and folder name sanitization`
2. `fix(security): replace config source with safe key-value parser`
3. `fix(security): fix AppleScript injection in calendar event creation`
4. `feat: add himalaya version detection with progressive enhancement`
5. `feat: add folder CRUD and attachment adapter functions`

---

### Agent: tests (swarm-tests)

**Scope:** Write test suites FIRST (TDD). Tests define the v2.0 contract.

#### Test Files to Create

| File | Tests | What it validates |
|------|-------|-------------------|
| `tests/test-em-v2-version.zsh` | ~15 | Version parse, compare, cache, clear, gate |
| `tests/test-em-v2-security.zsh` | ~25 | msg_id validation, folder name validation, config parser, AppleScript escaping |
| `tests/test-em-v2-safety-gate.zsh` | ~20 | Preview display, y/N/e flow, --force bypass, draft cleanup, TOCTOU prevention |
| `tests/test-em-v2-folders.zsh` | ~12 | create-folder, delete-folder, confirm gate, injection blocked |
| `tests/test-em-v2-attachments.zsh` | ~15 | attach list, attach get, path traversal blocked, MIME display |
| `tests/test-em-v2-ics.zsh` | ~20 | Valid ICS, malformed, oversized, multi-event, line folding, timezone, Apple Calendar |
| `tests/test-em-v2-watch.zsh` | ~15 | start, stop, status, log, orphan detect, duplicate guard, notification sanitize |
| `tests/dogfood-em-v2.zsh` | ~25 | Code quality, function naming, help text, no raw himalaya calls outside adapter |

**Total: ~147 new tests across 8 files**

**Testing patterns:**
- Use existing test framework (`tests/test-framework.zsh`)
- Mock himalaya CLI with fake binary (return fixture JSON)
- Mock `terminal-notifier` with noop
- Mock `osascript` with capture function
- Test security boundaries: pass injection payloads, verify they're rejected
- Test edge cases: empty inputs, special characters, oversized files

**Commits:**
1. `test: add version detection and security validation tests`
2. `test: add safety gate and folder CRUD tests`
3. `test: add attachment, ICS, and watch tests`
4. `test: add v2.0 dogfood quality tests`

---

## Wave 2: Sequential (depends on Wave 1 merge)

### Agent: dispatcher (swarm-dispatcher)

**Scope:** Wire everything into the main dispatcher. Depends on security + new-modules.

#### Task 1: Safety Gate (`lib/dispatchers/email-dispatcher.zsh`, ~100 lines)

Modify `_em_send()` and `_em_reply()`:

```zsh
_em_compose_draft "$to" "$subject" "$body"     # Write to temp file
_em_safety_gate "$draft_file" "$action_label" ["--force"]  # Preview + [y/N/e]
_em_draft_cleanup "$draft_file"                # rm temp file
_em_v2_migration_notice                        # One-time "em v2.0 now previews" notice
```

- Return codes: 0=sent, 1=error, 2=user-abort
- `--force` / `--yes` flag bypasses gate
- Edit option (`e`) re-opens `$EDITOR` then re-previews
- TOCTOU fix: read draft into variable before confirm, send from variable (Finding 8)
- Temp files created with `mktemp` + `chmod 0600`
- Trap cleanup on SIGINT (Finding 12)
- One-time notice tracked via `~/.config/flow/em-v2-notice-shown`

#### Task 2: Folder CRUD (`lib/dispatchers/email-dispatcher.zsh`, ~50 lines)

Add case entries + functions:

```zsh
create-folder|cf)  shift; _em_create_folder "$@" ;;
delete-folder|df)  shift; _em_delete_folder "$@" ;;
```

- `_em_create_folder()`: validate name → `_em_hml_folder_create` → success message
- `_em_delete_folder()`: validate name → type-to-confirm ("Type folder name: ") → `_em_hml_folder_delete`

#### Task 3: Attachment Improvements (`lib/dispatchers/email-dispatcher.zsh`, ~60 lines)

Modify `_em_attach()`:

```zsh
em attach list <ID>                    # New: show table of attachments
em attach get <ID> <filename> [dir]    # New: download specific file
em attach <ID> [dir]                   # Existing: download all (preserved)
```

- Path traversal protection: `realpath` containment check (Finding 11)
- Sanitize filename: strip directory components, control chars
- Download to temp dir first, then selectively copy

#### Task 4: Wire New Modules

Add to dispatcher `case` block:

```zsh
calendar|cal)  shift; _em_calendar "$@" ;;     # → lib/em-ics.zsh
watch|w)       shift; em_watch "$@" ;;          # → lib/em-watch.zsh
```

Source new files in `flow.plugin.zsh` or in dispatcher header.

#### Task 5: jq Injection Fix (Finding 2)

Replace all 6 instances of shell-interpolated `$msg_id` in jq filters:

```zsh
# Before (vulnerable)
jq -r ".[] | select(.id == \"$msg_id\")"

# After (safe)
_em_validate_msg_id "$msg_id" || return 1
jq -r --argjson id "$msg_id" '.[] | select(.id == $id)'
```

Locations: lines ~332, 630, 994, 1395, 1842, 2060

#### Task 6: Other Security Fixes in Dispatcher

- Finding 4: Sanitize terminal-notifier subjects in snooze (line ~2094)
- Finding 6: Use `mktemp` for snooze atomic write (line ~2074)
- Finding 12: Add `trap` cleanup in subshells for temp dirs

#### Task 7: Update Help

Update `_em_help()` with new commands: create-folder, delete-folder, attach list, attach get, calendar, watch.

#### Task 8: Minor Module Updates

- `lib/em-render.zsh` (+15): Add ICS content type detection
- `lib/em-cache.zsh` (+5): Hook `_em_hml_version_clear_cache` into `em cache clear`

**Commits:**
1. `feat!: add two-phase safety gate for em send and em reply (BREAKING)`
2. `feat: add folder CRUD (em create-folder, em delete-folder)`
3. `feat: improve em attach with list and get-by-filename`
4. `feat: wire ICS calendar and IMAP watch into dispatcher`
5. `fix(security): replace jq string interpolation with --argjson`
6. `fix(security): sanitize terminal-notifier subjects, temp file cleanup`
7. `docs: update em help with v2.0 commands`

---

### Agent: docs (swarm-docs)

**Scope:** Update all documentation for v2.0.

#### Files to Update

| File | Changes |
|------|---------|
| `docs/reference/REFCARD-EMAIL-DISPATCHER.md` | Add new commands, update safety gate behavior |
| `docs/guides/EMAIL-DISPATCHER-GUIDE.md` | New sections for folder CRUD, calendar, watch, safety gate |
| `docs/guides/EMAIL-TUTORIAL.md` | Update examples for new confirm flow |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | Update em section |
| `docs/reference/MASTER-API-REFERENCE.md` | Add new functions |
| `docs/help/QUICK-REFERENCE.md` | Add new commands |
| `completions/_em` | Add new subcommands to ZSH completion |
| `CHANGELOG.md` | v2.0 entry with breaking change note |

**Commits:**
1. `docs: update email dispatcher reference for v2.0`
2. `docs: update guides and tutorials for safety gate + new features`
3. `docs: add ZSH completions for new em subcommands`
4. `docs: add CHANGELOG entry for em v2.0`

---

## Convergence Merge

After all agents complete:

```bash
# Checkout feature branch
cd ~/.git-worktrees/flow-cli/feature-em-v2

# Merge in wave order (least → most dependent)
git merge swarm-em-v2-security --no-edit     # Adapter + security fixes
git merge swarm-em-v2-new --no-edit          # New ICS + watch modules
git merge swarm-em-v2-tests --no-edit        # Test suites
git merge swarm-em-v2-dispatcher --no-edit   # Main dispatcher wiring
git merge swarm-em-v2-docs --no-edit         # Documentation

# Run full test suite
./tests/run-all.sh

# Verify source loads
source flow.plugin.zsh

# Create PR
gh pr create --base dev --title "feat!: em dispatcher v2.0"
```

---

## Verification Checklist

- [ ] `em help` shows all new commands
- [ ] `em send` shows preview before sending (breaking change)
- [ ] `em reply <ID>` shows preview before sending
- [ ] `em send --force` bypasses preview (power user escape hatch)
- [ ] `em create-folder Test` creates folder
- [ ] `em delete-folder Test` requires type-to-confirm
- [ ] `em attach list <ID>` shows filename, MIME, size
- [ ] `em attach get <ID> <filename>` downloads safely
- [ ] `em calendar <ID>` parses ICS attachment
- [ ] `em watch start` starts IMAP IDLE with terminal-notifier
- [ ] `em watch stop` kills the background process
- [ ] `em watch status` reports running/stopped
- [ ] `em doctor` checks terminal-notifier + himalaya version
- [ ] All 46 existing test suites pass
- [ ] New v2.0 test suites pass (~147 tests)
- [ ] Security: msg_id injection blocked, folder name injection blocked, path traversal blocked
- [ ] `source flow.plugin.zsh` succeeds without errors

---

## Branch Naming

```
feature/em-v2                    ← convergence branch (this worktree)
  ├── swarm-em-v2-security       ← security fixes + version detection + adapter
  ├── swarm-em-v2-new            ← ICS parser + IMAP watch (new files)
  ├── swarm-em-v2-tests          ← test suites (TDD)
  ├── swarm-em-v2-dispatcher     ← main dispatcher wiring
  └── swarm-em-v2-docs           ← documentation updates
```

---

*Generated from SPEC-em-v2-2026-02-26.md by /craft:orchestrate --swarm*
