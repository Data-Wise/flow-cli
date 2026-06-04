# SPEC: Systemic fzf→exec Terminal-Hygiene Fix

**Status:** implemented (2026-06-04, commit af1bf685)
**Created:** 2026-06-03
**Type:** bugfix (follow-up to v7.7.1 terminal-hygiene work)
**Reported:** prompt corruption with `cc wt pick` and `ccy` (= `cc yolo`)

> **Implemented directly on `dev`** (existing-file edits only — branch guard
> permits; small fix, user-authorized) rather than the planned
> `feature/cc-wt-pick-hygiene` worktree. Helper landed in `lib/core.zsh` (not
> `tui.zsh` — Open Q1 resolved toward core, loaded earliest). Scope: the 3
> claude-launch pickers (Open Q2 = exec paths only). Bundled tok completion fix
> done. Regression guard `test-terminal-hygiene-regression.zsh` rewritten: 9/9.

---

## Overview

v7.7.1 added terminal-state cleanup (reset focus-reporting/mouse modes +
drain pending input) for the fzf→exec handoff, but implemented it
**inline in `pick()` only** (`commands/pick.zsh:1165`). Investigation
shows the codebase has **18 fzf invocation sites and only that one** has
the cleanup. Any other picker that hands off to an interactive program
(Claude) leaves the terminal dirty → garbled characters / broken input
in the next TUI. This is a class-of-bug, not a single call site.

## Confirmed corrupting paths (feed a Claude launch)

| Trigger | Picker without cleanup | Launch site |
|---|---|---|
| `cc wt pick` | `_proj_pick_worktree_path` (`commands/pick.zsh:512`) | `_cc_worktree_pick`: `cd … && eval "claude …"` (`cc-dispatcher.zsh:453`) |
| `ccy wt pick` (= `cc yolo wt pick`) | same `_proj_pick_worktree_path` | same, `--dangerously-skip-permissions` |
| `work` / `work -e` with `ccy` editor | `_flow_pick_project` (`lib/tui.zsh:290`) | `_work_launch_claude_code`: `claude --dangerously-skip-permissions` (`work.zsh:396`) |

## Root cause

The terminal-hygiene contract applies to every fzf→exec handoff but was
encoded once, inline, in `pick()`. Two pitfalls make naive copy-paste
wrong:

1. **Command-substitution context.** The other pickers are called as
   `x=$(_flow_pick_project)` / `selected=$(_proj_pick_worktree_path)`, so
   their stdout is a pipe. `pick()`'s guard is `[[ -t 1 ]]`
   (stdout-is-a-tty) which is **false** in these callers → a copied block
   silently no-ops. The cleanup must guard on the tty device
   (`[[ -e /dev/tty ]]` or `[[ -t 2 ]]`), reading/writing `/dev/tty`
   directly.
2. **No single source of truth.** 18 sites, 1 fix → drift guaranteed.

## Fix

### Shared helper (new)

Add to `lib/core.zsh` (or `lib/tui.zsh`):

```zsh
# Restore terminal state after an fzf/TUI handoff. Safe inside command
# substitution: guards on /dev/tty, not stdout (often captured by caller).
_flow_tty_handoff_cleanup() {
    [[ -e /dev/tty ]] || return 0
    printf '\e[?1004l\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l' > /dev/tty
    while read -t 0.05 -k 1 _ 2>/dev/null; do : ; done < /dev/tty
}
```

### Apply

- `_proj_pick_worktree_path` — call helper after fzf (`pick.zsh:516`,
  before `rm`).
- `_flow_pick_project` — call helper after fzf (`tui.zsh:~298`).
- `pick()` — **replace** the existing inline block (`pick.zsh:1165`)
  with a call to the helper (single source of truth; keep its
  `[[ -t 1 ]]`→`/dev/tty` behavior — the helper handles it).

## Acceptance Criteria

- [ ] `_flow_tty_handoff_cleanup` exists, guarded on `/dev/tty`, drains input.
- [ ] `cc wt pick`, `ccy wt pick`, and `work -e`→`ccy` launch Claude with
      a clean prompt (no stray chars, input works) — verified manually.
- [ ] `pick()` uses the helper (no duplicated escape-sequence literal).
- [ ] Regression test extends `tests/test-pick.zsh`: assert the picker
      functions emit the reset sequence / call the helper (mock `/dev/tty`
      or assert the helper is invoked).
- [ ] No behavior change to non-exec fzf sites (status displays).

## Bundled fix — tok completion drift (folded into this worktree)

Found during a post-merge `tok` help audit (2026-06-04): the in-shell
`tok help` text documents `tok sync push`/`repos` + `--no-sync`, but the
shell completion `completions/_tok` (the `sync)` branch, ~lines 45-53)
still offers only `github`. `tok sync <TAB>` therefore misses the two new
subcommands. Small UX-parity fix, bundled here since both are
completion/UX touch-ups.

- [ ] `completions/_tok` `sync_targets` lists `gh`, `push`, `repos`:
  ```zsh
  sync_targets=(
    'gh:Authenticate gh CLI with stored token'
    'push:Fan out token to GitHub Actions secrets'
    'repos:Dry run — list planned sync targets'
  )
  ```
- [ ] (Optional follow-up) complete the `<name>` arg for `push`/`repos`
      from `tok-sync.conf` token names — deeper, can defer.

## Open Questions

1. Helper home: `lib/core.zsh` (loaded early, broadly available) vs
   `lib/tui.zsh` (TUI-specific). *Recommendation: `lib/core.zsh`.*
2. Adopt across all 18 fzf sites now, or only the 3 exec paths + leave
   displays for a follow-up? *Recommendation: 3 exec paths now (fixes the
   bug), open a tracking note for the rest.*

## Implementation Notes

- New code → worktree `feature/cc-wt-pick-hygiene` off `dev`. This doc
  lands on `dev`.
- Pairs with the existing v7.7.1 contract documented in `CLAUDE.md`
  (Architecture Principles §5) — update that note to reference the shared
  helper as the canonical mechanism.

## History

| Date | Event |
|---|---|
| 2026-06-03 | Diagnosis from /debug: corruption on `cc wt pick` + `ccy`. Found systemic gap (18 fzf sites, 1 cleanup). Fix = shared `/dev/tty`-guarded helper applied to the 3 claude-launch pickers. |
