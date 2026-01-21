# BRAINSTORM: Worktree Detection Fix

**Date:** 2026-01-15
**Mode:** Architecture | **Depth:** Deep (8 questions)
**Status:** Ready for implementation

---

## Problem Statement

flow-cli fails to detect worktrees with **flat naming convention** (e.g., `~/.git-worktrees/scholar-github-actions/`).

### Root Cause

`_proj_list_worktrees()` in `commands/pick.zsh` only scans **level 2** directories:

```zsh
for project_dir in "$PROJ_WORKTREE_DIR"/*/; do      # Level 1
    for wt_dir in "${project_dir%/}"/*/; do         # Level 2 ONLY
        [[ -e "$wt_dir/.git" ]] || continue         # Never checks level 1
```

### Affected Worktrees

| Directory                 | Structure    | Detected? |
| ------------------------- | ------------ | --------- |
| `scholar-github-actions/` | FLAT         | ❌ No     |
| `scribe/quarto-v115/`     | HIERARCHICAL | ✅ Yes    |
| `scribe/latex-v2/`        | HIERARCHICAL | ✅ Yes    |
| `medfit/hardcore-cerf/`   | HIERARCHICAL | ✅ Yes    |
| `aiterm/`                 | EMPTY        | ⚠️ Stale  |

---

## Requirements (From Interactive Session)

| Requirement   | Answer                             |
| ------------- | ---------------------------------- |
| Use case      | Both listing AND navigation        |
| Structure     | Mixed (Hierarchical + Flat)        |
| Frequency     | Multiple worktrees/day             |
| Detection     | Immediate (no cache delay)         |
| Performance   | < 100ms                            |
| Scope         | Only `~/.git-worktrees/`           |
| Display       | Configurable mapping               |
| Priority      | Robustness over simplicity         |
| Config        | `~/.config/flow-cli/worktrees.yml` |
| Cache         | Auto-invalidate on `wt create`     |
| Empty dirs    | Show as stale                      |
| Special chars | Warn and suggest rename            |

---

## Chosen Solution: Option A (Hybrid Scanner)

**Approach:** Check level 1 for `.git` file first (flat), then level 2 (hierarchical).

### Implementation Plan

#### Phase 1: Core Fix (Quick Win) ← IMPLEMENTING NOW

Modify `_proj_list_worktrees()` to:

1. Check if level-1 directory has `.git` FILE (flat worktree)
2. Parse `gitdir:` to extract project name
3. Fall back to level-2 scan (hierarchical)

**Files to modify:**

- `commands/pick.zsh` - `_proj_list_worktrees()` function

#### Phase 2: Cache Invalidation (Future)

- Add `_proj_cache_invalidate` call to `wt create`
- Ensures immediate detection of new worktrees

#### Phase 3: Config File (Future)

- `~/.config/flow-cli/worktrees.yml` for display name overrides
- Ignore patterns for special directories

#### Phase 4: Stale Detection (Future)

- Warn about empty/orphaned directories
- Cleanup hints via `wt prune`

---

## Technical Design

### New `_proj_list_worktrees()` Algorithm

```
FOR each dir in ~/.git-worktrees/*/:
    IF dir/.git is a FILE:
        → FLAT worktree detected
        → Parse gitdir to get project name
        → Add to list
    ELSE:
        FOR each subdir in dir/*/:
            IF subdir/.git exists:
                → HIERARCHICAL worktree detected
                → Use dir name as project, subdir as branch
                → Add to list
        IF no worktrees found:
            → Mark as STALE (empty directory)
```

### Display Name Resolution

```
1. Check config override (future)
2. Parse from gitdir: .../PROJECT/.git/worktrees/BRANCH
3. Format as: "PROJECT (BRANCH)"
4. Fallback: directory name as-is
```

---

## Acceptance Criteria

- [ ] `pick wt` shows `scholar-github-actions`
- [ ] `pick wt scholar` filters to show it
- [ ] `cc wt feature/github-actions` navigates to it
- [ ] All existing hierarchical worktrees still work
- [ ] Performance < 100ms

---

## Related Files

- `commands/pick.zsh` - `_proj_list_worktrees()`
- `lib/dispatchers/wt-dispatcher.zsh` - `_wt_get_path()`
- `lib/project-cache.zsh` - Cache invalidation

---

## History

- 2026-01-15: Brainstorm completed, Phase 1 ready for implementation
