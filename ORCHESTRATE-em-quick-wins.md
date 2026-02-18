# Em Quick Wins Orchestration Plan

> **Branch:** `feature/em-quick-wins`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-em-quick-wins`
> **Spec:** `docs/specs/SPEC-em-features-2026-02-18.md`

## Objective

Add 5 quick-win subcommands to the `em` dispatcher: star, move, thread, snooze, and digest. Each is self-contained, < 30 min effort, and fills a gap vs himalaya-mcp.

## Phase Overview

| Phase | Feature | Priority | Effort | Status |
| ----- | ------- | -------- | ------ | ------ |
| 1 | `em star <ID>` — toggle Flagged status | High | Trivial (~15 lines) | DONE |
| 2 | `em move <ID> [folder]` — move email to folder | High | Small (~25 lines) | DONE |
| 3 | `em thread <ID>` — show conversation thread | High | Small (~40 lines) | DONE |
| 4 | `em snooze <ID> <time>` — snooze email for later | Medium | Small (~60 lines) | DONE |
| 5 | `em digest` — AI-grouped daily summary | Medium | Small (~50 lines) | DONE |
| 6 | Tests + docs | High | Medium | DONE |

## Implementation Details

### Phase 1: `em star`

**Files:** `lib/dispatchers/email-dispatcher.zsh`

```zsh
# Case statement additions:
#   star|flag)    shift; _em_star "$@" ;;
#   starred)      shift; _em_starred "$@" ;;

_em_star() {
    # Toggle Flagged on email ID
    # Check current flags → add or remove Flagged
    # himalaya message flag add/remove <ID> Flagged
}

_em_starred() {
    # List flagged emails: himalaya message list --include-flag Flagged
}
```

**fzf integration:** Add `Ctrl-F` bind in `_em_pick` for star toggle.

### Phase 2: `em move`

**Files:** `lib/dispatchers/email-dispatcher.zsh`

```zsh
# Case statement: move|mv)  shift; _em_move "$@" ;;

_em_move() {
    # If no folder arg → fzf folder picker
    # himalaya message move <ID> <folder>
    # Confirm: "Move #42 to Archive? [y/N]"
}
```

**fzf integration:** Add `Ctrl-M` bind in `_em_pick` for move.

### Phase 3: `em thread`

**Files:** `lib/dispatchers/email-dispatcher.zsh`

```zsh
# Case statement: thread|th)  shift; _em_thread "$@" ;;

_em_thread() {
    # Read email headers (Message-ID, In-Reply-To, References)
    # Build thread tree from References chain
    # Display as indented tree with timestamps
    # Highlight current message with ←
}
```

**Note:** himalaya's `--include-related` flag may help, but client-side threading via References headers is more reliable across providers.

### Phase 4: `em snooze`

**Files:** `lib/dispatchers/email-dispatcher.zsh`, new: `~/.flow/email-snooze/`

```zsh
# Case statement:
#   snooze|snz)  shift; _em_snooze "$@" ;;
#   snoozed)     shift; _em_snoozed "$@" ;;

_em_snooze() {
    # Parse time: 2h, tomorrow, monday, 1d, 3h
    # Move to "Snoozed" folder (create if needed)
    # Write entry to ~/.flow/email-snooze/pending.json
    # Schedule reminder via terminal-notifier (if available)
}

_em_snoozed() {
    # List pending snoozes from pending.json
}
```

### Phase 5: `em digest`

**Files:** `lib/dispatchers/email-dispatcher.zsh`

```zsh
# Case statement: digest|dg)  shift; _em_digest "$@" ;;

_em_digest() {
    # Fetch today's emails (or --week for weekly)
    # AI classify each into priority groups
    # Display grouped by: Action Required / FYI / Low Priority
    # Show counts per group
}
```

### Phase 6: Tests + Docs

**Test files to create:**
- `tests/test-em-star.zsh`
- `tests/test-em-move.zsh`
- `tests/test-em-thread.zsh`
- `tests/test-em-snooze.zsh`
- `tests/test-em-digest.zsh`

**Docs to update:**
- `docs/guides/EMAIL-TUTORIAL.md` — add sections for new commands
- `docs/guides/EMAIL-DISPATCHER-GUIDE.md` — add command reference
- `docs/reference/REFCARD-EMAIL-DISPATCHER.md` — add to command table
- `lib/dispatchers/email-dispatcher.zsh` — update `_em_help()`

## Acceptance Criteria

- [ ] `em star 42` toggles Flagged; `em starred` lists flagged
- [ ] `em move 42 Archive` moves; fzf picker when no folder
- [ ] `em thread 42` shows conversation tree
- [ ] `em snooze 42 2h` snoozes; `em snoozed` lists pending
- [ ] `em digest` shows AI-grouped daily summary
- [ ] All commands have help text
- [ ] All commands registered in case statement with aliases
- [ ] Tests pass for each new command
- [ ] Docs updated (tutorial, guide, refcard)
- [ ] `em pick` has new keybinds (Ctrl-F=star, Ctrl-M=move)

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-em-quick-wins
claude
```

Start with Phase 1 (star) — it's the simplest and establishes the pattern for the others.
