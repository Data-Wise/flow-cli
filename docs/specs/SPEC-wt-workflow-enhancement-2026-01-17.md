# SPEC: WT Workflow Enhancement

**Feature:** Enhanced worktree listing and pick wt delete/update actions
**Status:** Draft
**Created:** 2026-01-17
**From Brainstorm:** Deep interactive session
**Target Release:** flow-cli v5.13.0 or v5.14.0
**Estimated Effort:** 6-8 hours across 3 phases

---

## Metadata

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Priority** | Medium (improves daily workflow) |
| **Complexity** | Medium (6-8 hours) |
| **Risk Level** | Low (enhances existing commands) |
| **Dependencies** | fzf 0.40+, existing wt-dispatcher, pick.zsh |
| **Target Users** | Developers using worktrees for parallel development |
| **Branch Strategy** | feature/wt-enhancement → dev → main |

---

## Overview

Enhance the `wt` workflow with:

1. **Better `wt` default** - Formatted list with status icons and session indicators (replacing `cd + ls`)
2. **`pick wt` delete action** - Multi-select deletion with preview confirmation and optional branch cleanup
3. **`pick wt` update action** - Cache refresh with immediate formatted output
4. **Filter support** - `wt <project>` to filter worktrees by project name

---

## User Stories

### Primary Story: Quick Worktree Overview

**As a** developer working with multiple worktrees
**I want to** see a formatted overview when I type `wt`
**So that I** can quickly assess worktree status without navigating away

### Acceptance Criteria

- [ ] `wt` (no args) shows formatted table with branch, status, session, path
- [ ] Status icons: ✅ active, 🧹 merged, ⚠️ stale, 🏠 main
- [ ] Session indicators: 🟢 active, 🟡 recent, ⚪ none
- [ ] `wt <project>` filters to show only that project's worktrees
- [ ] Output fits terminal width gracefully

### Secondary Stories

**Story 2: Batch Worktree Cleanup**
- As a developer with many merged worktrees
- I want to delete multiple worktrees at once with confirmation
- So that I can clean up efficiently without repetitive commands

**Story 3: Cache Refresh**
- As a developer who just created/removed worktrees
- I want to refresh the pick cache and see the updated list
- So that pick wt shows accurate information immediately

---

## Architecture

### Component Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ User: wt                                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ wt-dispatcher.zsh                                                │
│ ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│ │ wt (no args)    │  │ wt <filter>     │  │ wt list/status  │   │
│ │ → _wt_overview()│  │ → _wt_overview  │  │ → existing      │   │
│ │   NEW           │  │   + filter      │  │                 │   │
│ └─────────────────┘  └─────────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ User: pick wt + ctrl-x (delete)                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ pick.zsh                                                         │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ _pick_wt_with_actions()  NEW                                 │ │
│ │ - fzf with --multi --bind 'ctrl-x:...,ctrl-r:...'           │ │
│ │ - Preview pane shows worktree details                        │ │
│ │ - ctrl-x: execute delete flow                                │ │
│ │ - ctrl-r: execute refresh flow                               │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                              ▼                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ _pick_wt_delete()  NEW                                       │ │
│ │ - Confirm each worktree in preview                           │ │
│ │ - Ask: "Also delete branch? [y/N]"                           │ │
│ │ - Execute git worktree remove                                │ │
│ │ - Optionally git branch -d                                   │ │
│ │ - Invalidate cache                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Design

### New/Modified Commands

| Command | Current | New Behavior |
|---------|---------|--------------|
| `wt` | `cd + ls -la` | Formatted overview table |
| `wt <filter>` | N/A | Filtered overview (e.g., `wt flow`) |
| `wt list` | `git worktree list` | No change (raw git output) |
| `wt status` | Full status view | No change |
| `pick wt` | Select → cd | Select → cd, OR ctrl-x delete, OR ctrl-r refresh |

### Keybindings for `pick wt`

| Key | Action | Description |
|-----|--------|-------------|
| `Enter` | Navigate | cd to selected worktree (existing) |
| `Tab` | Multi-select | Toggle selection for batch operations |
| `ctrl-x` | Delete | Delete selected worktree(s) with confirmation |
| `ctrl-r` | Refresh | Refresh cache and show formatted `wt` list |
| `ctrl-c` / `Esc` | Cancel | Exit picker |

---

## Data Models

### Worktree Display Format

```
🌳 Worktrees (3 total)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  BRANCH                     STATUS       SESSION   PATH
  ────────────────────────── ──────────── ───────── ─────────────────
  main                       🏠 main      🟢        ~/projects/flow-cli
  feature/teaching-flags     ✅ active    🟡        ~/.git-worktrees/flow-cli/...
  feature/old-feature        🧹 merged    ⚪        ~/.git-worktrees/flow-cli/...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Tip: wt <project> to filter | pick wt for interactive
```

### Session Status Detection

| Indicator | Meaning | Detection |
|-----------|---------|-----------|
| 🟢 | Active Claude session | `.claude/` exists + recent activity |
| 🟡 | Recent session (< 24h) | Session file mtime < 24h |
| ⚪ | No session | No `.claude/` or old session |

---

## Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| fzf | 0.40+ | Multi-select, keybindings, preview |
| git | 2.30+ | Worktree commands |

---

## UI/UX Specifications

### Delete Flow (ctrl-x in pick wt)

```
┌─────────────────────────────────────────────────────────────────┐
│ Selected for deletion:                                           │
│                                                                  │
│   1. feature/old-feature   ~/.git-worktrees/flow-cli/feature-...│
│   2. bugfix/fixed-issue    ~/.git-worktrees/flow-cli/bugfix-... │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Delete worktree 1/2: feature/old-feature?                        │
│                                                                  │
│   [y] Yes, delete worktree                                       │
│   [n] No, skip this one                                          │
│   [a] Yes to all remaining                                       │
│   [q] Quit (cancel all)                                          │
│                                                                  │
│ Your choice: _                                                   │
└─────────────────────────────────────────────────────────────────┘
```

After each worktree deletion:
```
✓ Removed worktree: ~/.git-worktrees/flow-cli/feature-old-feature

Also delete branch 'feature/old-feature'? [y/N]: _
```

### Refresh Flow (ctrl-r in pick wt)

```
⟳ Refreshing worktree cache...
✓ Cache cleared

🌳 Worktrees (3 total)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[shows formatted wt output]
```

### Accessibility

- [ ] All actions have keyboard shortcuts (no mouse required)
- [ ] Color-coded status has text fallback (✅/🧹/⚠️ icons)
- [ ] Confirmation prompts are clear and unambiguous
- [ ] Error messages explain recovery steps

---

## Open Questions

1. **Should `wt` also cache its output?** Currently `wt status` rescans every time. Could be slow for many worktrees.
2. **Should ctrl-x work from main picker or require explicit `pick wt delete` subcommand?** Keybinding in main picker is more discoverable.

---

## Implementation Plan

### Phase 1: Enhanced `wt` Default (2h)

- [ ] Create `_wt_overview()` function in wt-dispatcher.zsh
- [ ] Add session indicator detection (reuse from pick.zsh)
- [ ] Add filter argument support (`wt <project>`)
- [ ] Update `wt` case to call `_wt_overview()` when no args
- [ ] Add help text mentioning filter and pick wt

### Phase 2: pick wt Actions (3-4h)

- [ ] Add fzf keybindings: `--bind 'ctrl-x:...,ctrl-r:...'`
- [ ] Implement `_pick_wt_delete()` with confirmation flow
- [ ] Implement branch deletion prompt after worktree removal
- [ ] Implement `_pick_wt_refresh()` calling cache invalidate + wt
- [ ] Add multi-select support with Tab
- [ ] Update preview pane to show action hints

### Phase 3: Testing & Polish (1-2h)

- [ ] Add tests for `wt` with and without filter
- [ ] Add tests for delete flow (mock confirmation)
- [ ] Add tests for refresh flow
- [ ] Update help system with new keybindings
- [ ] Update WT-DISPATCHER-REFERENCE.md
- [ ] Update ARCHITECTURE-DIAGRAMS.md with new flows

---

## Testing Strategy

### Unit Tests

```bash
test_wt_overview_no_filter()
test_wt_overview_with_filter()
test_wt_overview_empty_worktrees()
test_wt_session_detection()
```

### Integration Tests

```bash
test_pick_wt_delete_single()
test_pick_wt_delete_multi()
test_pick_wt_delete_with_branch()
test_pick_wt_refresh()
```

---

## Review Checklist

- [ ] Backward compatible with existing `wt` commands
- [ ] All new keybindings documented in help
- [ ] Delete confirmation is safe (no accidental deletion)
- [ ] Session indicators match pick wt behavior
- [ ] Filter argument works with all project names
- [ ] Tests cover happy path and error cases
- [ ] Documentation updated

---

## History

| Date | Change | Author |
|------|--------|--------|
| 2026-01-17 | Initial spec from deep brainstorm | Claude + DT |

---

## Related Documents

- [WT-DISPATCHER-REFERENCE.md](../reference/WT-DISPATCHER-REFERENCE.md)
- [PICK-COMMAND-REFERENCE.md](../reference/PICK-COMMAND-REFERENCE.md)
- [ARCHITECTURE-DIAGRAMS.md](../diagrams/ARCHITECTURE-DIAGRAMS.md)
