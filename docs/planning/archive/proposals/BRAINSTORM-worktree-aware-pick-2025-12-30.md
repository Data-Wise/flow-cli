# Brainstorm: Worktree-Aware Pick

**Generated:** 2025-12-30
**Mode:** feature (feat) | **Depth:** deep (8 questions)
**Context:** flow-cli project

---

## Overview

Enhance the `pick` command to recognize worktrees as a first-class category alongside existing categories (r, dev, teach, rs, q, app). This creates a unified project navigation experience where parallel workspaces are instantly accessible.

---

## Requirements Summary (from 8 questions)

| Requirement  | Choice                                                             |
| ------------ | ------------------------------------------------------------------ |
| **Display**  | Separate category `wt`                                             |
| **Action**   | cd + show status                                                   |
| **Icon**     | 🌳 (tree)                                                          |
| **Naming**   | `project (branch)` format                                          |
| **Scope**    | All worktrees; filterable by project                               |
| **Sessions** | Show indicator + last activity time                                |
| **Resume**   | Unified - worktree OR project                                      |
| **Keys**     | Ctrl-W toggle, Ctrl-D delete, Ctrl-R resume, Ctrl-O cc, Ctrl-Y ccy |

---

## Quick Wins (< 30 min each)

### 1. ⚡ Add `wt` to PROJ_CATEGORIES

```zsh
PROJ_CATEGORIES=(
    # ... existing categories ...
    "wt:wt:🌳"  # Special: scans ~/.git-worktrees
)
```

**Implementation:**

- Special handling in `_proj_list_all()` for `wt` category
- Scans `$FLOW_WORKTREE_DIR` instead of `$PROJ_BASE`

### 2. ⚡ `pick wt` filtering

```zsh
pick wt              # All worktrees
pick wt scribe       # Only scribe's worktrees
```

**Implementation:**

- When category is `wt`, second arg filters by project name
- Fuzzy match on project subfolder name

### 3. ⚡ Show git status after navigation

```zsh
# After cd to worktree:
📂 Changed to: ~/.git-worktrees/scribe/live-editor-enhancements
🌿 Branch: live-editor-enhancements
📊 Status: 3 modified, 1 untracked
```

---

## Medium Effort (1-2 hours)

### 4. 🔧 Worktree list formatter

Create `_proj_list_worktrees()` function that outputs:

```
scribe (live-editor)     🌳 wt  🟢 2h ago
scribe (swiftui-native)  🌳 wt  🟡 old
medfit (hardcore-cerf)   🌳 wt  ⚪
```

**Format:** `project (branch) | icon | type | session-indicator`

**Implementation details:**

- Scan `$FLOW_WORKTREE_DIR/*/` for project dirs
- For each project, scan subdirs for worktree dirs
- Check for `.claude/` directory to determine session status
- Calculate session age from most recent file

### 5. 🔧 Unified resume tracking

Modify `_proj_save_session()` to distinguish:

```zsh
# Session file format (enhanced):
name|path|timestamp|type
# type = "project" | "worktree"

# Example:
live-editor-enhancements|~/.git-worktrees/scribe/live-editor-enhancements|1735600000|worktree
flow-cli|~/projects/dev-tools/flow-cli|1735599000|project
```

### 6. 🔧 Keybinding: Ctrl-W toggle

In `pick()`, add keybinding to toggle between:

- Full project list (all categories)
- Worktree-only list

```zsh
--bind="ctrl-w:reload(_proj_list_worktrees)+change-prompt(🌳 WORKTREES> )"
```

**Challenge:** fzf reload needs external command; may need tmpfile approach

### 7. 🔧 Keybinding: Ctrl-D delete worktree

```zsh
--bind="ctrl-d:execute-silent(
    wt_path=\$(echo {} | awk '{print \$NF}')
    git worktree remove \"\$wt_path\" 2>/dev/null
    echo removed > $action_file
)+reload(...)"
```

**Safety:** Only works on worktrees, not projects

### 8. 🔧 Keybinding: Ctrl-R resume session

```zsh
--bind="ctrl-r:execute-silent(echo resume > $action_file)+accept"
```

After selection:

```zsh
if [[ "$action" == "resume" && -d "$proj_dir/.claude" ]]; then
    cd "$proj_dir" && claude --resume
fi
```

---

## Long-term (Future sessions)

### 9. ✅ Claude launch keybindings (DECIDED)

**Selected approach:** Use Ctrl-O and Ctrl-Y

| Key Combo | Action                                  |
| --------- | --------------------------------------- |
| `Ctrl-O`  | Launch Claude (cc) - "O" for Open       |
| `Ctrl-Y`  | Launch Claude YOLO (ccy) - "Y" for YOLO |
| `Ctrl-R`  | Resume Claude session (existing)        |

**Implementation:**

```zsh
--bind="ctrl-o:execute-silent(echo cc > $action_file)+accept"
--bind="ctrl-y:execute-silent(echo ccy > $action_file)+accept"
```

**Note:** Ctrl-O may conflict with "open" in some terminals, Ctrl-Y with "paste" - but both are safe inside fzf

### 9b. ⚠️ Context Awareness: `--no-claude` flag

**Problem identified:** `cc pick` calls `pick && claude`, so Ctrl-O/Ctrl-Y would cause double launch.

**Solution:** Add `--no-claude` flag to pick:

- When called from cc dispatcher, pass `--no-claude`
- This disables Ctrl-O/Ctrl-Y keybindings
- Different header shown: `[Enter] cd │ [^S] Status │ [^L] Log`

**Behavior Matrix:**

| Invocation     | Ctrl-O/Ctrl-Y | Why                                         |
| -------------- | ------------- | ------------------------------------------- |
| `pick`         | Enabled       | Direct invocation, user wants Claude option |
| `pick wt`      | Enabled       | Direct invocation                           |
| `cc pick`      | Disabled      | cc already launches Claude after pick       |
| `cc yolo pick` | Disabled      | cc already launches Claude YOLO after pick  |

**Files to modify:**

- `commands/pick.zsh` - Add `--no-claude` flag parsing
- `lib/dispatchers/cc-dispatcher.zsh` - Pass `--no-claude` to all `pick` calls

### 10. 🏗️ Session indicator in list

Display format with session status:

```
scribe (live-editor)  🌳  🟢 2h     # Recent session
medfit (hardcore)     🌳  🟡 old   # Old session
rmediation (shamir)   🌳  ⚪       # No session
```

Implementation complexity: Need to stat files for each worktree on list generation (performance concern for many worktrees)

### 11. 🏗️ `pickwt` alias

```zsh
alias pickwt='pick wt'
```

Follows pattern of `pickr`, `pickdev`, etc.

---

## Architecture Diagram

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
│  │  scribe (live-editor) 🌳 wt  🟢 2h                      │  │  ← NEW
│  │  stat-440        🎓 teach                               │  │
│  └─────────────────────────────────────────────────────────┘  │
│  Keybindings:                                                  │
│  [Enter=cd] [^S=status] [^L=log] [^W=toggle-wt] [^D=delete]   │
└───────────────────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────────────────────────────┐
│                      Action Handler                            │
│  cd + save session + show status (for worktrees)              │
└───────────────────────────────────────────────────────────────┘
```

---

## Implementation Order (Recommended)

| Phase | Task                                 | Effort | Impact |
| ----- | ------------------------------------ | ------ | ------ |
| **1** | Add `wt` category with basic listing | 30 min | High   |
| **2** | `pick wt` filter by project          | 20 min | High   |
| **3** | Show git status after worktree cd    | 15 min | Medium |
| **4** | Session indicator in list            | 45 min | Medium |
| **5** | Ctrl-W toggle keybinding             | 30 min | Medium |
| **6** | Unified resume tracking              | 30 min | Medium |
| **7** | Ctrl-D delete keybinding             | 20 min | Low    |
| **8** | Ctrl-R resume keybinding             | 20 min | Low    |

**Total estimated:** 3.5 hours for full implementation

---

## Open Questions

1. **Performance:** With many worktrees, should we cache session status or compute on-demand?
2. **Naming collision:** What if project name matches worktree name? (e.g., `flow-cli` project vs `flow-cli/feature-x` worktree)
3. **Ordering:** Should worktrees sort by recency, project, or alphabetically?
4. **Stale worktrees:** Should `pick wt` hide stale/orphaned worktrees?

---

## Related Commands

| Command          | Current Behavior               | After This Change          |
| ---------------- | ------------------------------ | -------------------------- |
| `pick`           | Shows projects only            | Shows projects + worktrees |
| `pick wt`        | N/A (not implemented)          | Shows all worktrees        |
| `pick wt scribe` | N/A                            | Shows scribe's worktrees   |
| `cc wt pick`     | Shows current repo's worktrees | Keep as-is (repo-scoped)   |
| `wt list`        | Shows current repo's worktrees | Keep as-is                 |

---

## Acceptance Criteria

- [ ] `pick wt` lists all worktrees across all projects
- [ ] `pick wt <project>` filters to specific project's worktrees
- [ ] Worktrees display as `project (branch) 🌳 wt`
- [ ] Session status shows: 🟢 recent / 🟡 old / ⚪ none + time
- [ ] `cd` to worktree shows git status
- [ ] Resume feature works with worktrees (unified tracking)
- [ ] Ctrl-W toggles between projects and worktrees view
- [ ] Ctrl-D deletes worktree from picker (with confirmation)
- [ ] Ctrl-R resumes Claude session if available
- [ ] Ctrl-O launches Claude Code (cc) in selected directory
- [ ] Ctrl-Y launches Claude Code YOLO (ccy) in selected directory
- [ ] `--no-claude` flag disables Ctrl-O/Ctrl-Y (for cc dispatcher)
- [ ] `pickwt` alias added

---

## Files to Modify

| File                                        | Changes                                                           |
| ------------------------------------------- | ----------------------------------------------------------------- |
| `commands/pick.zsh`                         | Add wt category, worktree lister, keybindings, `--no-claude` flag |
| `lib/dispatchers/cc-dispatcher.zsh`         | Pass `--no-claude` to all `pick` calls                            |
| `completions/_pick`                         | Add `wt` to completions, `--no-claude` option                     |
| `docs/reference/COMMAND-QUICK-REFERENCE.md` | Document `pick wt`                                                |
| `CLAUDE.md`                                 | Update Quick Reference section                                    |

---

*Generated by /workflow:brainstorm deep feat save*
