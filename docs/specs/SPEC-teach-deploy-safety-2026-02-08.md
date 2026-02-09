# SPEC: teach deploy Safety & DX Enhancements

**Status:** draft
**Created:** 2026-02-08
**From Brainstorm:** BRAINSTORM-teach-deploy-enhancements-2026-02-08.md
**Version Target:** v6.6.0
**PR Strategy:** Single PR with all 4 enhancements

---

## Overview

Port 4 safety and developer experience features from STAT-545's battle-tested `quick-deploy.sh` into flow-cli's `teach deploy`. These are additive improvements to error handling, recovery messaging, and workflow convenience. No breaking changes on happy path; CI mode remains fully non-interactive.

---

## Primary User Story

**As a** teaching instructor deploying course content,
**I want** `teach deploy` to recover gracefully from errors, handle uncommitted changes, and show me where to monitor deployments,
**So that** I spend less time debugging failed deploys and more time on course content.

### Acceptance Criteria

- [ ] Trap handler returns to draft branch on any error/signal in both direct and PR modes
- [ ] Deploy summary box includes GitHub Actions URL
- [ ] Pre-commit hook failures show actionable recovery message with 3 options
- [ ] `teach deploy -d` with uncommitted changes prompts to commit (smart message) instead of blocking
- [ ] `--ci` mode: uncommitted changes still fail (no prompt), hook failures exit non-zero
- [ ] All existing tests pass unchanged
- [ ] New tests cover trap, hook failure, uncommitted prompt paths

---

## Secondary User Stories

**As a** CI pipeline running `teach deploy --ci -d`,
**I want** deploy to fail fast on uncommitted changes with a clear error,
**So that** the pipeline gives actionable feedback without hanging on prompts.

**As an** instructor whose pre-commit hook catches a Quarto error,
**I want** to see exactly how to skip validation and retry,
**So that** I can deploy urgently without searching documentation.

---

## Architecture

```
_teach_deploy_enhanced()
    |
    +-- [NEW] Uncommitted change prompt (before mode dispatch)
    |     +-- _generate_smart_commit_message()  [existing]
    |     +-- git commit with hook failure recovery
    |
    +-- _deploy_preflight_checks()  [existing]
    |
    +-- Mode dispatch
         |
         +-- _deploy_direct_merge()
         |     +-- [NEW] trap "git checkout '$draft'" EXIT INT TERM
         |     +-- ... existing merge logic ...
         |     +-- [NEW] trap - EXIT INT TERM  (clear on success)
         |
         +-- PR mode
               +-- [NEW] trap "git checkout '$draft'" EXIT INT TERM
               +-- ... existing PR logic ...
               +-- [NEW] trap - EXIT INT TERM  (clear on success)

_deploy_summary_box()
    +-- [NEW] Actions URL line (always)
```

No new files. All changes in existing files.

---

## API Design

N/A -- No new flags or commands. Behavioral changes only.

### Environment Variables

| Variable | Purpose | Existing? |
|----------|---------|-----------|
| `QUARTO_PRE_COMMIT_RENDER=0` | Skip Quarto pre-commit render validation | Yes (from quick-deploy.sh) |

---

## Data Models

N/A -- No data model changes.

---

## Dependencies

No new dependencies. Uses existing:
- `_generate_smart_commit_message()` from `lib/git-helpers.zsh`
- `FLOW_COLORS` from `lib/core.zsh`
- `git config --get remote.origin.url` for Actions URL

---

## Implementation Details

### Enhancement 1: Trap Handler

**File:** `lib/dispatchers/teach-deploy-enhanced.zsh`

**In `_deploy_direct_merge()` (line ~162):**
```zsh
_deploy_direct_merge() {
    local draft_branch="$1"
    # ... existing locals ...

    # Safety: always return to draft on error
    trap "git checkout '$draft_branch' 2>/dev/null" EXIT INT TERM

    # ... existing merge logic (unchanged) ...

    # Clear trap before normal return
    trap - EXIT INT TERM
    return 0
}
```

**In PR mode section (line ~854):**
```zsh
# Before PR mode logic begins
trap "git checkout '$draft_branch' 2>/dev/null" EXIT INT TERM

# ... existing PR logic (unchanged) ...

# Clear trap before _deploy_cleanup_globals
trap - EXIT INT TERM
```

**Risk:** Low. Trap is additive. Existing manual checkout calls remain as belt-and-suspenders.

---

### Enhancement 2: Pre-Commit Hook Failure Recovery

**File:** `lib/dispatchers/teach-deploy-enhanced.zsh`

**After git commit calls in partial deploy mode (lines ~670, ~683) and the new uncommitted change handler:**

```zsh
if ! git commit -m "$commit_msg"; then
    echo ""
    _teach_error "Commit failed (likely pre-commit hook)"
    echo ""
    echo "  ${FLOW_COLORS[dim]}Options:${FLOW_COLORS[reset]}"
    echo "    1. Fix the issues above, then run ${FLOW_COLORS[info]}teach deploy${FLOW_COLORS[reset]} again"
    echo "    2. Skip validation: ${FLOW_COLORS[info]}QUARTO_PRE_COMMIT_RENDER=0 teach deploy ...${FLOW_COLORS[reset]}"
    echo "    3. Force commit: ${FLOW_COLORS[info]}git commit --no-verify -m \"message\"${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[dim]}Your changes are still staged. Nothing was lost.${FLOW_COLORS[reset]}"
    return 1
fi
```

**CI mode:** Same message, exits non-zero (no interactive options).

---

### Enhancement 3: GitHub Actions Link

**File:** `lib/dispatchers/teach-deploy-enhanced.zsh`

**In `_deploy_summary_box()` (line ~125), after the URL line:**

```zsh
# GitHub Actions monitoring link
local repo_slug
repo_slug=$(git config --get remote.origin.url 2>/dev/null | \
    sed 's|.*github\.com[:/]\(.*\)\.git$|\1|; s|.*github\.com[:/]\(.*\)$|\1|')
if [[ -n "$repo_slug" && "$repo_slug" != "$(git config --get remote.origin.url)" ]]; then
    printf "│  %-10s %-42s│\n" "Actions:" "https://github.com/${repo_slug}/actions"
fi
```

**Always shown.** If the remote URL isn't GitHub, the regex won't match and the line is skipped.

---

### Enhancement 4: Uncommitted Changes in Direct Mode

**File:** `lib/dispatchers/teach-deploy-enhanced.zsh`

**Insert after preflight checks (line ~511), before dry-run check (line ~523):**

```zsh
# Handle uncommitted changes (all modes)
if ! _git_is_clean; then
    if [[ "$ci_mode" == "true" ]]; then
        _teach_error "Uncommitted changes detected" \
            "Commit changes before deploying in CI mode"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[warn]}  Uncommitted changes detected${FLOW_COLORS[reset]}"

    local smart_msg
    smart_msg=$(_generate_smart_commit_message 2>/dev/null)
    [[ -z "$smart_msg" ]] && smart_msg="deploy: update content"

    echo "  ${FLOW_COLORS[info]}Suggested:${FLOW_COLORS[reset]} $smart_msg"
    echo ""
    echo -n "${FLOW_COLORS[prompt]}  Commit and continue? [Y/n]:${FLOW_COLORS[reset]} "
    read -r commit_confirm

    case "$commit_confirm" in
        n|N|no|No|NO)
            echo "  Deploy cancelled."
            return 1
            ;;
        *)
            git add -A
            if ! git commit -m "$smart_msg"; then
                # Enhancement #2: hook failure recovery
                echo ""
                _teach_error "Commit failed (likely pre-commit hook)"
                echo ""
                echo "  ${FLOW_COLORS[dim]}Options:${FLOW_COLORS[reset]}"
                echo "    1. Fix issues, then ${FLOW_COLORS[info]}teach deploy${FLOW_COLORS[reset]} again"
                echo "    2. Skip: ${FLOW_COLORS[info]}QUARTO_PRE_COMMIT_RENDER=0 teach deploy ...${FLOW_COLORS[reset]}"
                echo "    3. Force: ${FLOW_COLORS[info]}git commit --no-verify -m \"message\"${FLOW_COLORS[reset]}"
                echo ""
                echo "  ${FLOW_COLORS[dim]}Changes are still staged.${FLOW_COLORS[reset]}"
                return 1
            fi
            echo "  ${FLOW_COLORS[success]}[ok]${FLOW_COLORS[reset]} Committed: $smart_msg"
            ;;
    esac
fi
```

**Note:** This replaces the existing `require_clean` check for the prompt path. The `require_clean` config option is still respected: if set to `false`, this block is skipped entirely (already handled by preflight).

---

## UI/UX Specifications

### Uncommitted Change Prompt

```
  Uncommitted changes detected
  Suggested: content: week-05 lecture
  Commit and continue? [Y/n]:
```

Uses `FLOW_COLORS[warn]` for header, `FLOW_COLORS[info]` for suggested message, `FLOW_COLORS[prompt]` for input.

### Hook Failure Message

```
  ERROR: Commit failed (likely pre-commit hook)

  Options:
    1. Fix the issues above, then teach deploy again
    2. Skip validation: QUARTO_PRE_COMMIT_RENDER=0 teach deploy ...
    3. Force commit: git commit --no-verify -m "message"

  Changes are still staged.
```

### Deploy Summary Box (Updated)

```
+-- Deployment Summary ---------------------------+
|  Mode:     Direct merge                         |
|  Files:    3 changed (+45 / -12)                |
|  Duration: 8s                                   |
|  Commit:   a1b2c3d4                             |
|  URL:      https://data-wise.github.io/doe/     |
|  Actions:  https://github.com/Data-Wise/stat-545/actions  |  <-- NEW
+--------------------------------------------------+
```

### Accessibility

- No color-only information (text always conveys meaning)
- CI mode: no ANSI colors when `[[ ! -t 1 ]]`
- Matches existing FLOW_COLORS scheme throughout

---

## Open Questions

1. Should `git add -A` in the uncommitted prompt add ALL files, or only tracked files (`git add -u`)? Using `-A` matches quick-deploy.sh but could add unintended files.
2. Should the trap handler also handle `HUP` signal (terminal hangup)?

---

## Review Checklist

- [ ] Trap handler tested: kill -INT during deploy, verify return to draft
- [ ] Hook failure tested: create failing pre-commit, verify recovery message
- [ ] Actions link tested: verify URL is correct for GitHub repos
- [ ] Actions link tested: verify no output for non-GitHub remotes
- [ ] Uncommitted prompt tested: Y commits, n cancels, Enter defaults to Y
- [ ] CI mode tested: uncommitted → fails, hook failure → exits non-zero
- [ ] Backward compat: existing `teach deploy -d` on clean tree unchanged
- [ ] Backward compat: existing `teach deploy` (PR mode) on clean tree unchanged
- [ ] All 42 test suites pass

---

## Implementation Notes

- All changes in a single file: `lib/dispatchers/teach-deploy-enhanced.zsh`
- Plus one line in `_deploy_summary_box()` (same file)
- Estimated total: ~75 min implementation + ~30 min testing
- Enhancement #2 (hook recovery) is used in two places: the new uncommitted handler AND existing partial deploy commit blocks
- The trap handler must clear (`trap - EXIT INT TERM`) before normal return to avoid interfering with the caller's trap state

---

## Backward Compatibility

| Scenario | Before | After | Change? |
|----------|--------|-------|---------|
| `teach deploy -d` (clean tree) | Works | Works identically | None |
| `teach deploy -d` (dirty tree) | Fails with "working tree dirty" | Prompts to commit first | Improved (prompt before fail) |
| `teach deploy -d` (dirty, user presses n) | N/A | Fails with "Deploy cancelled" | Same outcome |
| `teach deploy --ci -d` (dirty) | Fails | Fails with clearer message | Same exit code |
| `teach deploy` (PR, clean) | Works | Works + Actions link in summary | Additive |
| Error during merge | Returns to draft (usually) | Returns to draft (guaranteed via trap) | Improved |
| Pre-commit hook fails | Generic error | Actionable 3-option recovery | Improved |

---

## History

| Date | Change |
|------|--------|
| 2026-02-08 | Initial spec from deep brainstorm (comparison with quick-deploy.sh) |
