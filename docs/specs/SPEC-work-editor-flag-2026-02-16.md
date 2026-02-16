# SPEC: Refactor `work` command editor behavior

**Date:** 2026-02-16
**Status:** Implemented
**Branch:** feature/work-editor-flag

## Problem

`work <project>` auto-opens `$EDITOR` every time. Most sessions just need `cd` + context display.

## Solution

- **No editor by default** -- `work flow` just cd's + shows context
- **Optional `-e [editor]` flag** to explicitly request an editor
- **New editors supported:** `cc`/`claude` (Claude Code), `ccy` (yolo mode), `cc:new` (new Ghostty window)

## Changes

### `commands/work.zsh`

| Change | Details |
|--------|---------|
| Flag parsing | `-e`/`--editor` parsed before project arg via while-shift loop |
| Remove auto-editor | `local editor="${2:-${EDITOR:-nvim}}"` deleted |
| Conditional editor | `_flow_open_editor` only called when `editor_requested=true` |
| Deprecation shim | Positional `work proj nvim` warns and still works |
| Claude Code case | `cc\|claude\|cc:new\|claude:new\|ccy` in `_flow_open_editor()` |
| New function | `_work_launch_claude_code()` -- handles current/new/yolo modes |
| Help updated | Shows `-e` flag, all editor options, yolo mode |

### Editor modes

| Flag | Behavior |
|------|----------|
| (none) | cd + context only |
| `-e` | Open `$EDITOR` (default: nvim) |
| `-e positron` | Open Positron IDE |
| `-e code` | Open VS Code |
| `-e cc` / `-e claude` | Claude Code (`--permission-mode acceptEdits`) |
| `-e ccy` | Claude Code yolo (`--dangerously-skip-permissions`) |
| `-e cc:new` | New Ghostty window (macOS) -- user runs `claude` manually |

### Ghostty limitation

Ghostty on macOS has no AppleScript `do script` and `ghostty -e` doesn't work from CLI. `open -na Ghostty` opens a new window; user runs `claude` there. This is the cleanest available UX.

## Tests

7 new tests in `tests/test-work.zsh` (31 total, all passing):
- No editor by default
- `-e` bare uses `$EDITOR`
- `-e positron` passes editor name
- `cc|claude|ccy` case exists in function
- Legacy positional arg shows deprecation warning
- `--help` shows `-e` flag
- `_work_launch_claude_code` function exists
