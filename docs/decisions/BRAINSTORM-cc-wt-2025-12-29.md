# Brainstorm: CC Worktree Integration

**Date:** 2025-12-29
**Status:** Implementation Plan
**Version:** v4.2.0

---

## Overview

Add worktree support to the `cc` dispatcher, enabling Claude Code sessions in isolated git worktrees.

## Current CC Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ccy` | `cc yolo` | Skip permissions |
| `ccp` | `cc plan` | Plan mode |
| `ccr` | `cc resume` | Session picker |
| `ccc` | `cc continue` | Most recent |
| `cca` | `cc ask` | Quick question |
| `ccf` | `cc file` | Analyze file |
| `ccd` | `cc diff` | Review changes |
| `cco` | `cc opus` | Opus model |
| `cch` | `cc haiku` | Haiku model |

## Proposed New Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `cc wt <branch>` | `ccw` | Launch Claude in worktree |
| `cc wt` | - | List worktrees |
| `cc wt pick` | `ccwp` | fzf picker for worktrees |
| `cc wt yolo <branch>` | `ccwy` | Worktree + yolo mode |
| `cc wt plan <branch>` | - | Worktree + plan mode |
| `cc wt opus <branch>` | - | Worktree + opus model |

## Implementation Plan

### Phase 1: Foundation (~10 min)

Add `_wt_get_path()` helper to `wt-dispatcher.zsh`:

```zsh
_wt_get_path() {
    local branch="$1"
    local project=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
    local folder=$(echo "$branch" | tr '/' '-')
    local path="$FLOW_WORKTREE_DIR/$project/$folder"
    [[ -d "$path" ]] && echo "$path"
}
```

### Phase 2: Basic cc wt (~25 min)

Add to `cc-dispatcher.zsh`:

```zsh
wt|worktree|w)
    shift
    _cc_worktree "$@"
    ;;
```

Implement `_cc_worktree()`:

```zsh
_cc_worktree() {
    local mode=""
    local branch=""

    # Parse mode if provided (yolo, plan, opus, haiku)
    case "$1" in
        yolo|y) mode="--dangerously-skip-permissions"; shift ;;
        plan|p) mode="--plan"; shift ;;
        opus|o) mode="--model opus"; shift ;;
        haiku|h) mode="--model haiku"; shift ;;
        pick) _cc_worktree_pick; return ;;
    esac

    branch="$1"

    # No branch = list worktrees
    if [[ -z "$branch" ]]; then
        wt list
        return
    fi

    # Get or create worktree
    local wt_path=$(_wt_get_path "$branch")
    if [[ -z "$wt_path" ]]; then
        _flow_log_info "Creating worktree for $branch..."
        wt create "$branch"
        wt_path=$(_wt_get_path "$branch")
    fi

    if [[ -z "$wt_path" ]]; then
        _flow_log_error "Failed to get/create worktree for $branch"
        return 1
    fi

    # Launch Claude in worktree
    _flow_log_success "Launching Claude in $wt_path"
    cd "$wt_path" && claude $mode
}
```

### Phase 3: Aliases (~10 min)

Add to `cc-dispatcher.zsh`:

```zsh
alias ccw='cc wt'
alias ccwy='cc wt yolo'
alias ccwp='cc wt pick'
```

### Phase 4: fzf Picker (~15 min)

```zsh
_cc_worktree_pick() {
    if ! command -v fzf >/dev/null; then
        _flow_log_error "fzf required for pick mode"
        wt list
        return 1
    fi

    local selected=$(git worktree list --porcelain | \
        grep "^worktree " | \
        cut -d' ' -f2 | \
        fzf --prompt="Select worktree: " --height=40%)

    if [[ -n "$selected" ]]; then
        cd "$selected" && claude
    fi
}
```

### Phase 5: Tests (~30 min)

Create `tests/test-cc-wt.zsh` with:
- Help text tests
- _wt_get_path() tests
- cc wt <branch> creates worktree
- cc wt lists worktrees
- Mode chaining tests (yolo, plan, opus)
- Error handling tests

### Phase 6: Documentation (~15 min)

Update:
- `docs/reference/CC-DISPATCHER-REFERENCE.md`
- `docs/reference/DISPATCHER-REFERENCE.md`
- `.STATUS` session log

## Design Decisions

### Why `cc wt` instead of `wt cc`?

- Keeps Claude commands grouped under `cc`
- Consistent with `cc yolo`, `cc opus` pattern
- `wt` stays focused on worktree management

### Why support mode chaining?

- `cc wt yolo feature/auth` is more flexible
- Avoids needing separate aliases for every combination
- Matches existing cc patterns

### Aliases for Speed

- `ccw` for quick worktree access
- `ccwy` for common yolo+worktree combo
- `ccwp` for interactive selection

## Effort Estimate

| Task | Time |
|------|------|
| _wt_get_path() helper | 10 min |
| cc wt case + mode support | 25 min |
| Aliases (ccw, ccwy, ccwp) | 10 min |
| cc wt pick (fzf) | 15 min |
| Tests | 30 min |
| Docs + PR | 15 min |
| **Total** | **~1.75 hours** |

---

*Generated: 2025-12-29*
*Author: Claude Code*
