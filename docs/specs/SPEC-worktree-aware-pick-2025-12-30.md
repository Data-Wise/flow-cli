# SPEC: Worktree-Aware Pick

**Status:** implemented
**Created:** 2025-12-30

---

## Overview

Enhance the `pick` command to recognize git worktrees as a first-class category (`wt`) alongside existing categories (r, dev, teach, rs, q, app). This provides unified project navigation where parallel workspaces are instantly accessible with session status visibility and smart keybindings.

---

## Primary User Story

**As a** developer using multiple git worktrees for parallel feature work
**I want** to navigate to worktrees using the same `pick` interface I use for projects
**So that** I have a unified, fast way to switch contexts without remembering different commands

### Acceptance Criteria

- [ ] `pick wt` lists all worktrees across all projects in `~/.git-worktrees/`
- [ ] `pick wt <project>` filters to a specific project's worktrees
- [ ] Worktrees display as `project (branch) 🌳 wt` in the picker
- [ ] Session status indicator shows: 🟢 recent (< 24h) / 🟡 old / ⚪ none + time
- [ ] `cd` to worktree displays git status (branch, modified, untracked counts)
- [ ] Resume feature tracks worktrees (unified session file)
- [ ] Ctrl-W toggles between projects view and worktrees view
- [ ] Ctrl-D deletes worktree from picker (with confirmation)
- [ ] Ctrl-R resumes Claude session if worktree has one
- [ ] Ctrl-O launches Claude Code (cc) in selected directory
- [ ] Ctrl-Y launches Claude Code YOLO (ccy) in selected directory
- [ ] `--no-claude` flag disables Ctrl-O/Ctrl-Y (for use by cc dispatcher)
- [ ] `pickwt` alias added for quick access

---

## Secondary User Stories

### 2. Quick Worktree Cleanup

**As a** developer who accumulates many worktrees
**I want** to delete stale worktrees directly from the picker
**So that** I can clean up without switching context

**Acceptance Criteria:**
- [ ] Ctrl-D in picker triggers worktree deletion
- [ ] Confirmation prompt before deletion (unless --force)
- [ ] List refreshes after successful deletion

### 3. Claude Session Resumption

**As a** developer working on features across multiple worktrees
**I want** to see which worktrees have active Claude sessions
**So that** I can resume work without losing context

**Acceptance Criteria:**
- [ ] 🟢 indicator for sessions < 24h old
- [ ] 🟡 indicator for older sessions
- [ ] ⚪ no indicator if no `.claude/` directory
- [ ] Time displayed (e.g., "2h ago", "3d ago")
- [ ] Ctrl-R triggers `claude --resume` in selected worktree

### 4. Quick Claude Launch from Picker

**As a** developer who frequently uses Claude Code
**I want** to launch Claude directly from the picker
**So that** I can start coding immediately without extra commands

**Acceptance Criteria:**
- [ ] Ctrl-O navigates to selection AND launches `claude --permission-mode acceptEdits`
- [ ] Ctrl-Y navigates to selection AND launches `claude --dangerously-skip-permissions`
- [ ] Works for both projects and worktrees
- [ ] Session is saved before Claude launches

---

## Technical Requirements

### Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                         pick command                            │
├─────────────────────┬──────────────────┬───────────────────────┤
│  Category Filter    │  Query/Project   │   Options             │
│  (r, dev, wt...)    │  (fuzzy match)   │   (--fast, -a)        │
└─────────────────────┴──────────────────┴───────────────────────┘
            │                   │                    │
            ▼                   ▼                    ▼
┌───────────────────────────────────────────────────────────────┐
│                    _proj_list_all()                            │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────┐ │
│  │ Standard    │  │ Standard    │  │ NEW: wt category       │ │
│  │ ~/projects/ │  │ scan        │  │ ~/.git-worktrees/      │ │
│  │ directories │  │             │  │ special handling       │ │
│  └─────────────┘  └─────────────┘  └────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────────────────────────────┐
│                         fzf picker                             │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  flow-cli        🔧 dev                                 │  │
│  │  mediationverse  📦 r                                   │  │
│  │  scribe (live-editor) 🌳 wt  🟢 2h                      │  │
│  │  stat-440        🎓 teach                               │  │
│  └─────────────────────────────────────────────────────────┘  │
│  Keybindings:                                                  │
│  [Enter=cd] [^O=cc] [^Y=ccy] [^R=resume] [^W=wt] [^D=del]     │
└───────────────────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────────────────────────────┐
│                      Action Handler                            │
│  cd + save session + show status (for worktrees)              │
└───────────────────────────────────────────────────────────────┘
```

### API Design

N/A - No API changes; this is a ZSH function enhancement.

### Data Models

**Session File Enhancement** (`~/.current-project-session`):

```
# Current format:
name|path|timestamp

# Enhanced format:
name|path|timestamp|type
# type = "project" | "worktree"

# Example:
live-editor-enhancements|~/.git-worktrees/scribe/live-editor-enhancements|1735600000|worktree
flow-cli|~/projects/dev-tools/flow-cli|1735599000|project
```

**Backward Compatibility:** Missing `type` field defaults to "project"

### Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| fzf | Yes | Interactive picker |
| git | Yes | Worktree management |
| stat | Yes | Session age calculation |
| bat | No | Enhanced status display |

---

## UI/UX Specifications

### User Flow

```
User invokes pick wt
        │
        ▼
┌──────────────────────────────────┐
│ Scan ~/.git-worktrees/*/         │
│ for all worktree directories     │
└──────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────┐
│ For each worktree:               │
│ - Get project name (parent dir)  │
│ - Get branch name (folder name)  │
│ - Check .claude/ for session     │
│ - Format as list entry           │
└──────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────┐
│ Display in fzf with keybindings  │
│ User selects worktree            │
└──────────────────────────────────┘
        │
        ├──[Enter]─────────────────▶ cd + show status
        ├──[Ctrl-O]────────────────▶ cd + claude (cc)
        ├──[Ctrl-Y]────────────────▶ cd + claude YOLO (ccy)
        ├──[Ctrl-R]────────────────▶ cd + claude --resume
        ├──[Ctrl-W]────────────────▶ Toggle to projects view
        ├──[Ctrl-D]────────────────▶ Delete worktree (confirm)
        └──[Ctrl-C]────────────────▶ Cancel
```

### Wireframes (ASCII)

**Worktree List View:**

```
╔════════════════════════════════════════════════════════════╗
║  🌳 WORKTREE PICKER                                        ║
╚════════════════════════════════════════════════════════════╝

  💡 Showing all worktrees from ~/.git-worktrees/
  [Enter] cd  │  [^O] cc  │  [^Y] ccy  │  [^R] Resume  │  [^W] Projects

> scribe (live-editor-enh)    🌳 wt  🟢 2h ago
  scribe (swiftui-native)     🌳 wt  🟡 old
  scribe (wonderful-wilson)   🌳 wt  ⚪
  medfit (hardcore-cerf)      🌳 wt  ⚪
  rmediation (condesc-shamir) 🌳 wt  🟡 old

  5/5 ───────────────────────────────────────────────────────
```

**After Navigation:**

```
  📂 Changed to: ~/.git-worktrees/scribe/live-editor-enhancements

  🌿 Branch: live-editor-enhancements
  📊 Status: 3 modified, 1 untracked
```

### Accessibility Checklist

- [x] Keyboard-only navigation via fzf
- [x] Clear visual indicators (icons + colors)
- [x] Consistent with existing pick interface
- [x] Help text visible in picker header
- [ ] Screen reader support (fzf limitation)

---

## Open Questions

1. **Performance:** With 20+ worktrees, should session status be cached or computed on-demand?
   - **Recommendation:** Compute on-demand; worktree count typically < 10

2. **Naming collision:** What if project name matches worktree branch name?
   - **Recommendation:** Always show `project (branch)` format, no ambiguity

3. **Ordering:** How should worktrees sort?
   - **Recommendation:** By project name, then by recency within project

4. **Stale worktrees:** Should stale/orphaned worktrees be hidden?
   - **Recommendation:** Show with ⚠️ indicator, don't hide

5. **RESOLVED: Claude keybinding conflict with `cc pick`**
   - **Problem:** `cc pick` calls `pick && claude`, so if pick has Ctrl-O/Ctrl-Y, double launch occurs
   - **Solution:** Add `--no-claude` flag to pick; cc passes this flag
   - See "Claude Keybinding Context Awareness" section below

---

## Review Checklist

- [ ] Primary user story is clear and testable
- [ ] All acceptance criteria are measurable
- [ ] Architecture diagram matches implementation plan
- [ ] Data model changes are backward compatible
- [ ] Keybindings don't conflict with existing fzf bindings
- [ ] Documentation locations identified
- [ ] Test cases defined (see below)

---

## Implementation Notes

### Key Implementation Details

1. **Special category handling:** The `wt` category needs custom logic in `_proj_list_all()` since it scans `$FLOW_WORKTREE_DIR` instead of `$PROJ_BASE`.

2. **Session status calculation:** Use `find` with `-mtime` to check for recent `.claude/*.json` files.

3. **Keybinding gotchas:**
   - Ctrl-C cannot be rebound (always cancels)
   - Ctrl-W may conflict on some terminals (word delete)
   - Ctrl-O opens file in some terminals (but usually safe in fzf)
   - Ctrl-Y is paste in some terminals (but usually safe in fzf)
   - Use `--bind` with `reload` for toggle functionality
   - Use `execute-silent` + `accept` for actions that exit picker

### Claude Keybinding Context Awareness

**Problem:** `cc pick` and `cc yolo pick` already launch Claude after pick completes:

```zsh
# In cc-dispatcher.zsh:
pick "$@" && claude --permission-mode acceptEdits  # cc pick
pick "$@" && claude --dangerously-skip-permissions # cc yolo pick
```

If pick has Ctrl-O/Ctrl-Y keybindings, pressing them would cause double Claude launch.

**Solution:** Add `--no-claude` flag to pick that disables Ctrl-O/Ctrl-Y keybindings.

```zsh
# pick() changes:
pick() {
    local no_claude_keys=0

    # Parse --no-claude flag
    if [[ "$1" == "--no-claude" ]]; then
        no_claude_keys=1
        shift
    fi

    # ... existing argument parsing ...

    # Build fzf keybindings conditionally
    local claude_bindings=""
    if [[ $no_claude_keys -eq 0 ]]; then
        claude_bindings='--bind=ctrl-o:execute-silent(echo cc > '$action_file')+accept'
        claude_bindings+=' --bind=ctrl-y:execute-silent(echo ccy > '$action_file')+accept'
    fi

    # ... fzf call with $claude_bindings ...
}
```

```zsh
# cc-dispatcher.zsh changes:
# Before:
pick "$@" && claude --permission-mode acceptEdits

# After:
pick --no-claude "$@" && claude --permission-mode acceptEdits
```

**Behavior Matrix:**

| Invocation | Ctrl-O/Ctrl-Y | Result |
|------------|---------------|--------|
| `pick` | Enabled | cd + launch Claude |
| `pick wt` | Enabled | cd + launch Claude |
| `cc pick` | Disabled | cd only (cc handles Claude) |
| `cc yolo pick` | Disabled | cd only (cc handles Claude) |
| `cc wt pick` | Disabled | cd only (cc handles Claude) |

**Header changes based on context:**

```
# Normal pick:
[Enter] cd  │  [^O] cc  │  [^Y] ccy  │  [^R] Resume

# pick --no-claude (called from cc):
[Enter] cd  │  [^S] Status  │  [^L] Log  │  [^W] Worktrees
```

1. **Format string:** Use printf with fixed widths for alignment:

   ```zsh
   printf "%-25s %-5s %-3s %s\n" "$name" "$icon" "$type" "$session"
   ```

### Test Cases

| Test | Input | Expected |
|------|-------|----------|
| List all worktrees | `pick wt` | Shows all worktrees from ~/.git-worktrees |
| Filter by project | `pick wt scribe` | Shows only scribe's worktrees |
| No worktrees | `pick wt` (empty dir) | Shows "No worktrees found" message |
| Direct jump | `pick live-editor` | Navigates to matching worktree |
| Session indicator | worktree with .claude/ | Shows 🟢/🟡 with time |
| Delete worktree | Ctrl-D on selection | Confirms and removes |
| Toggle view | Ctrl-W in picker | Switches to project list |
| Launch Claude | Ctrl-O on selection | cd + launches `claude --permission-mode acceptEdits` |
| Launch Claude YOLO | Ctrl-Y on selection | cd + launches `claude --dangerously-skip-permissions` |
| Resume Claude | Ctrl-R on selection | cd + launches `claude --resume` |
| No Claude keys | `pick --no-claude` | Ctrl-O/Ctrl-Y bindings not present |
| cc pick integration | `cc pick` | pick called with --no-claude, Claude launched by cc |

### Files to Modify

| File | Changes | Priority |
|------|---------|----------|
| `commands/pick.zsh` | Add wt category, worktree lister, keybindings, `--no-claude` flag | P0 |
| `lib/dispatchers/cc-dispatcher.zsh` | Pass `--no-claude` to all `pick` calls | P0 |
| `completions/_pick` | Add `wt` to category completions, `--no-claude` option | P1 |
| `do../reference/.archive/COMMAND-QUICK-REFERENCE.md` | Document `pick wt` | P1 |
| `CLAUDE.md` | Update Quick Reference section | P2 |
| `docs/tutorials/` | Add worktree navigation tutorial | P2 |

---

## History

| Date | Change |
|------|--------|
| 2025-12-30 | Initial spec from brainstorm session |
| 2025-12-30 | Added Ctrl-O (cc) and Ctrl-Y (ccy) keybindings for Claude launch |
| 2025-12-30 | Added `--no-claude` flag to prevent double-launch when called from cc dispatcher |

---

*Captured from /workflow:brainstorm deep feat save*
