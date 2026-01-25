# BRAINSTORM: WT Workflow Enhancement

**Date:** 2026-01-17
**Mode:** Feature | **Depth:** Deep | **Duration:** ~10 min

---

## Topic

Enhance the `wt` workflow:
- Which is more reliable to show worktree list: `wt list` or `wt`?
- Add "delete" and "update" options to `pick wt`

---

## Context Analysis

### Current Behavior

| Command | Behavior | Reliability |
|---------|----------|-------------|
| `wt` (no args) | `cd ~/.git-worktrees` + `ls -la` | ❌ Raw listing, no structure |
| `wt list` | `git worktree list` | ✅ Reliable (git native) |
| `wt status` | Formatted table with icons | ✅ Best formatted view |
| `pick wt` | fzf picker with session indicators | ✅ Interactive selection |

### Problem

- `wt` alone is not useful (just navigates + raw ls)
- No quick way to delete worktrees from `pick wt`
- Cache doesn't refresh automatically after create/remove

---

## Questions & Answers (8 Expert Questions)

### Q1: When you run `wt` with no args, what should happen?

**A:** Show formatted list (like `wt status` lite) - Quick overview with branch, status icons, path

### Q2: For `pick wt` delete action, what should happen after selection?

**A:** Confirm each deletion individually - Safe: 'Delete feature/auth? [y/N]'

### Q3: What should 'update' mean for `pick wt`?

**A:** Refresh cache + rescan worktrees - Force cache invalidation

### Q4: Should delete/update work on multiple worktrees at once?

**A:** Yes - fzf multi-select with Tab - Power user: select multiple, act on all

### Q5: Should `wt` (formatted list) also show session indicators like `pick wt`?

**A:** Yes - show 🟢/🟡/⚪ Claude session status - Match pick wt display

### Q6: Where should delete confirmation happen?

**A:** Inside fzf preview pane - See details before confirming

### Q7: Should deleted worktrees also delete the branch?

**A:** Ask each time: 'Also delete branch? [y/N]' - User decides per deletion

### Q8: For the 'update' (cache refresh), should it also show the refreshed list?

**A:** Yes - refresh then show wt (formatted list) - Quick view after refresh

### Q9 (Bonus): What keybindings should trigger delete/update in pick wt?

**A:** ctrl-x for delete, ctrl-r for refresh - x=remove, r=refresh

### Q10 (Bonus): Should `wt` also accept a filter argument like `pick wt`?

**A:** Yes - `wt flow` shows only flow-cli worktrees - Match pick wt filter behavior

---

## Quick Wins (< 30 min each)

1. ⚡ **Change `wt` default** - Call `_wt_overview()` instead of `cd + ls`
2. ⚡ **Add filter argument** - `wt <project>` filters by project name
3. ⚡ **Add fzf keybindings** - `--bind 'ctrl-x:...,ctrl-r:...'`

## Medium Effort (1-2 hours)

- [ ] Implement `_wt_overview()` with session indicators
- [ ] Implement `_pick_wt_delete()` with confirmation flow
- [ ] Implement `_pick_wt_refresh()` with formatted output

## Long-term (Future sessions)

- [ ] Add worktree archiving (move to `.archive/` before delete)
- [ ] Add `wt diff` to show changes across all worktrees
- [ ] Add `wt sync` to rebase all worktrees onto base branch

---

## Recommended Path

→ **Start with Phase 1** (enhanced `wt` default) because:
- Immediate improvement to daily workflow
- Low risk (doesn't change existing commands)
- Foundation for Phase 2 (shares session detection code)

---

## Spec Captured

✅ **SPEC-wt-workflow-enhancement-2026-01-17.md** created with:
- 3 implementation phases (6-8 hours total)
- Full UI/UX specifications
- Delete and refresh flows documented
- Keybindings defined (ctrl-x, ctrl-r)
- Testing strategy included

---

## Next Steps

1. Review spec: `docs/specs/SPEC-wt-workflow-enhancement-2026-01-17.md`
2. Create worktree: `wt create feature/wt-enhancement`
3. Start Phase 1: Enhanced `wt` default (2h)
