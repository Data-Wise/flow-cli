# Brainstorm: teach deploy Enhancements from quick-deploy.sh

**Generated:** 2026-02-08
**Context:** Comparison of STAT-545 `quick-deploy.sh` vs flow-cli `teach deploy`
**Depth:** Deep analysis
**Focus:** Feature gaps

---

## Already Covered (No Gap)

- **Smart commit messages** -- `_generate_smart_commit_message()` in `lib/git-helpers.zsh` already ported from stat-545, more comprehensive (handles labs, exams, projects, data, styles, media)
- **Non-interactive detection** -- Both use `[[ ! -t 0 ]]`
- **Duration tracking** -- Both track and display
- **Semester week detection** -- Both calculate from `semester_info.start_date`

---

## Actual Gaps (5 Enhancements)

### 1. Trap Handler for Branch Safety

**Problem:** `teach deploy` manually calls `git checkout $draft_branch` in each error path. If an unexpected error occurs (signal, ZSH crash, unhandled case), the user gets stranded on the production branch.

**What quick-deploy.sh does:**
```bash
trap return_to_draft EXIT
```

**What teach deploy should do:**
```zsh
# At the start of _deploy_direct_merge and PR mode
trap "git checkout '$draft_branch' 2>/dev/null" EXIT INT TERM
# ... do work ...
trap - EXIT INT TERM  # Clear trap before normal return
```

**Effort:** 15 min | **Risk:** Low (additive, no behavior change on happy path)
**Where:** `_deploy_direct_merge()` (line ~162) and PR mode section (line ~854)

---

### 2. Pre-Commit Hook Failure Recovery

**Problem:** When `teach deploy` auto-commits changes (partial deploy mode), if the pre-commit hook fails, the user gets a generic error. quick-deploy.sh shows a specific recovery menu.

**What quick-deploy.sh does:**
```
Commit failed (likely pre-commit hook)

Options:
  1. Fix the issues reported above, then run deploy again
  2. Skip validation: QUARTO_PRE_COMMIT_RENDER=0 ./scripts/quick-deploy.sh
  3. Force commit: git commit --no-verify -m "message"
```

**What teach deploy should do:**
Add hook failure detection after `git commit` calls in partial deploy mode (line ~670, ~683):
```zsh
if ! git commit -m "$commit_msg"; then
    echo ""
    _teach_error "Commit failed (likely pre-commit hook)"
    echo "  Options:"
    echo "    1. Fix issues, run teach deploy again"
    echo "    2. Skip hooks: QUARTO_PRE_COMMIT_RENDER=0 teach deploy ..."
    echo "    3. Force: git commit --no-verify -m \"message\""
    echo ""
    echo "  Your changes are still staged."
    return 1
fi
```

**Effort:** 20 min | **Risk:** Low
**Where:** `_teach_deploy_enhanced()` partial deploy commit blocks (lines ~664-686)

---

### 3. Production Divergence Auto-Reset

**Problem:** `teach deploy` detects production conflicts and offers rebase, but doesn't handle the case where local production has **diverged** from remote (not just behind). quick-deploy.sh detects this and offers `git reset --hard origin/production`.

**What quick-deploy.sh does:**
1. Fetch remote production
2. Compare local vs remote production hashes
3. Detect: behind (ff-ok), ahead (ok), **diverged** (needs reset)
4. Offer: reset local to match remote, or force-push local

**What teach deploy should add:**
In `_deploy_direct_merge()` after `git pull origin "$prod_branch" --ff-only` fails (line ~208):
```zsh
# Check for divergence specifically
if ! git merge-base --is-ancestor "$prod_branch" "origin/$prod_branch" &&
   ! git merge-base --is-ancestor "origin/$prod_branch" "$prod_branch"; then
    # True divergence
    if [[ "$ci_mode" == "true" ]]; then
        git reset --hard "origin/$prod_branch"
    else
        echo "Local $prod_branch diverged from remote."
        echo -n "Reset to match remote? [y/N]: "
        read -r reset_confirm
        [[ "$reset_confirm" == [yY] ]] && git reset --hard "origin/$prod_branch"
    fi
fi
```

**Effort:** 30 min | **Risk:** Medium (destructive operation, needs careful prompt)
**Where:** `_deploy_direct_merge()` (line ~208, after ff-only pull fails)

---

### 4. GitHub Actions Monitoring Link

**Problem:** After deploy, teach deploy shows a summary box with site URL. But doesn't show the GitHub Actions URL where the user can monitor the actual deployment pipeline.

**What quick-deploy.sh does:**
```bash
echo "Tip: Check deployment status at:"
echo "   https://github.com/<owner>/<repo>/actions"
```

**What teach deploy should add:**
In `_deploy_summary_box()`, add an optional actions URL:
```zsh
local repo_slug
repo_slug=$(git config --get remote.origin.url 2>/dev/null | sed 's/.*github.com[:\\/]\(.*\)\.git/\1/')
if [[ -n "$repo_slug" ]]; then
    printf "│  🔗 %-8s %-42s│\n" "Actions:" "https://github.com/${repo_slug}/actions"
fi
```

**Effort:** 10 min | **Risk:** None
**Where:** `_deploy_summary_box()` (line ~125)

---

### 5. Uncommitted Changes in Direct Mode

**Problem:** `teach deploy -d` (direct mode) requires a clean working tree and fails if there are uncommitted changes. quick-deploy.sh handles this gracefully: prompts to commit first with smart message, then continues the deploy.

**Current behavior:**
```
teach deploy -d
  [!!] Working tree dirty
  → FAILS
```

**Desired behavior (matching quick-deploy.sh):**
```
teach deploy -d
  [!!] Uncommitted changes detected (3 files)
  Smart commit: content: week-05 lecture
  Commit and continue? [Y/n]:
  → auto-commits, then proceeds with deploy
```

**Implementation:**
Move the uncommitted-change handling from partial deploy mode into the main `_teach_deploy_enhanced()` flow, before the mode dispatch:
```zsh
# After preflight checks, before mode dispatch
if ! _git_is_clean; then
    if [[ "$ci_mode" == "true" ]]; then
        _teach_error "Uncommitted changes. Commit before deploying."
        return 1
    fi
    local smart_msg=$(_generate_smart_commit_message)
    echo "  Uncommitted changes detected"
    echo "  Suggested: $smart_msg"
    echo -n "  Commit and continue? [Y/n]: "
    read -r commit_confirm
    case "$commit_confirm" in
        n|N) return 1 ;;
        *)
            git add -A
            git commit -m "$smart_msg" || {
                # Pre-commit hook failure recovery (Enhancement #2)
                _teach_error "Commit failed (pre-commit hook?)"
                return 1
            }
            ;;
    esac
fi
```

**Effort:** 30 min | **Risk:** Medium (changes default behavior — currently blocks, now would commit)
**Where:** `_teach_deploy_enhanced()` after preflight (line ~511), before dry-run check

---

## Priority Matrix

| # | Enhancement | Effort | Risk | Value | Priority |
|---|-------------|--------|------|-------|----------|
| 1 | Trap handler | 15 min | Low | High (safety) | **P1** |
| 4 | Actions link | 10 min | None | Medium (convenience) | **P1** |
| 2 | Hook failure recovery | 20 min | Low | Medium (DX) | **P2** |
| 5 | Uncommitted in direct mode | 30 min | Medium | High (workflow) | **P2** |
| 3 | Divergence auto-reset | 30 min | Medium | Low (rare case) | **P3** |

**Total effort:** ~2 hours for all 5
**Recommended batch:** #1 + #4 as quick wins (25 min), then #2 + #5 as a pair (50 min), then #3 if needed

---

## Recommended Path

Bundle #1, #2, #4, #5 into a single PR as `fix(deploy): port safety features from quick-deploy.sh`. Skip #3 (divergence auto-reset) for now -- it's rare and involves destructive operations.

## Next Steps

1. [ ] File GitHub issue with these 4 enhancements
2. [ ] Create worktree: `feature/teach-deploy-safety`
3. [ ] Implement in priority order
4. [ ] Update tests in `tests/test-teach-deploy-v2-unit.zsh`
