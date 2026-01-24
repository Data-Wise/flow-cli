# SPEC: CI Optimization & Pick Worktree Fix

**Status:** implemented
**Created:** 2025-12-31
**From Brainstorm:** In-session analysis

---

## Overview

Two issues to address:
1. **CI takes too long** - PR tests taking 5+ minutes, goal is <5 minutes
2. **`pick wt` not showing worktrees** - `PROJ_WORKTREE_DIR` not configured

---

## Issue 1: CI Optimization

### Current State

| Job | Time | Notes |
|-----|------|-------|
| Main branch CI | ~31s | Fast |
| PR ZSH Tests | 5+ min | macOS tests slow |
| PR macOS Tests | 5+ min | Duplicate coverage |

### Root Causes

1. **macOS runner slow startup** - macOS runners take 30-60s just to start
2. **Duplicate test coverage** - macOS runs same tests as Ubuntu
3. **Sequential test steps** - Already optimized in latest commit
4. **Long-running optional tests** - sync, AI features, etc.

### Quick Wins (< 30 min each)

| # | Action | Impact | Effort |
|---|--------|--------|--------|
| ⚡1 | **Make macOS tests optional** - Use `continue-on-error: true` for entire macOS job | -3 min | 5 min |
| ⚡2 | **Remove macOS job entirely** - ZSH is cross-platform, Ubuntu coverage sufficient | -5 min | 2 min |
| ⚡3 | **Skip slow tests on PR** - Only run full suite on main branch | -2 min | 10 min |

### Medium Effort (1-2 hours)

| # | Action | Impact | Effort |
|---|--------|--------|--------|
| 1 | **Matrix strategy with fail-fast** - Run Ubuntu and macOS in parallel matrix | -1 min | 30 min |
| 2 | **Cache mock project structure** - Pre-build the mock dirs | -30s | 1 hr |
| 3 | **Split critical vs optional** - Fast critical path, slow optional path | -2 min | 1 hr |

### Recommended Approach

**Option A: Remove macOS job (Fastest)**

```yaml
# Only keep zsh-tests job, remove macos-tests entirely
# ZSH is platform-agnostic, cross-platform stat already fixed
```

**Option B: Make macOS non-blocking**

```yaml
macos-tests:
  name: macOS Tests
  runs-on: macos-latest
  continue-on-error: true  # Don't block PR merge
```

**Option C: Run macOS only on main**

```yaml
macos-tests:
  if: github.ref == 'refs/heads/main'
```

---

## Issue 2: Pick Worktree Not Working

### Root Cause

`PROJ_WORKTREE_DIR` environment variable not set in user's shell.

### User Story

> As a user, when I run `pick wt`, I want to see my worktrees listed so I can quickly switch between them.

### Acceptance Criteria

- [ ] `pick wt` shows worktrees when `PROJ_WORKTREE_DIR` is configured
- [ ] Clear error message when `PROJ_WORKTREE_DIR` is not set
- [ ] Documentation explains how to configure worktree directory

### Fix

1. **Add error message in pick.zsh:**

```zsh
if [[ "$category" == "wt" ]]; then
    if [[ -z "$PROJ_WORKTREE_DIR" ]]; then
        echo "Error: PROJ_WORKTREE_DIR not set"
        echo "Add to .zshrc: export PROJ_WORKTREE_DIR=~/projects/.worktrees"
        return 1
    fi
fi
```

1. **Update documentation:**
   - Add setup instructions to `docs/getting-started/quick-start.md`
   - Add to `docs/reference/PICK-REFERENCE.md`

2. **User configuration:**

```zsh
# In ~/.zshrc
export PROJ_WORKTREE_DIR="$HOME/projects/.worktrees"
```

---

## Implementation Plan

### Phase 1: CI Optimization (Immediate)

1. Remove or make macOS job optional
2. Move optional tests to `continue-on-error`
3. Verify PR CI completes in <3 minutes

### Phase 2: Pick Worktree Fix

1. Add error message for missing `PROJ_WORKTREE_DIR`
2. Update documentation
3. Test `pick wt` with configured directory

---

## Open Questions

1. **Keep macOS tests at all?** - Do we need platform-specific testing?
2. **Default worktree location?** - Should we auto-detect or require config?

---

## Review Checklist

- [ ] CI completes in <5 minutes
- [ ] `pick wt` shows helpful error when unconfigured
- [ ] Documentation updated
- [ ] All existing tests still pass

---

## History

| Date | Change |
|------|--------|
| 2025-12-31 | Initial spec from brainstorm |
