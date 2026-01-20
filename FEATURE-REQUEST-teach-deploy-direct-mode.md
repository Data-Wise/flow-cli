# Feature Request: Direct Deploy Mode for `teach deploy`

**Date:** 2026-01-19
**Author:** Davood Tofighi, Ph.D.
**Priority:** Medium
**Effort:** Small (~2-4 hours)

---

## Executive Summary

Add a `--direct` flag to `teach deploy` that combines the robust pre-flight checks of the PR workflow with the speed of direct merge deployment, optimized for solo instructors.

**Current behavior:**

```bash
flow teach deploy    # Creates PR, requires manual merge (7+ steps)
```

**Proposed behavior:**

```bash
flow teach deploy --direct    # Direct merge with validation (3 steps)
```

---

## Problem Statement

### Current Limitation

The `teach deploy` command always uses a PR-based workflow, which is excellent for teams but inefficient for solo instructors:

- **Overhead:** Creates PR → opens browser → manual merge → cleanup (7 steps)
- **Time:** 45-90 seconds for deployment
- **Context switching:** Forces instructor out of terminal into browser
- **GitHub API costs:** 4-5 API calls per deployment

### Real-World Impact

**STAT 545 case study** ([analysis](../../../teaching/stat-545/docs/FLOW-CLI-TEACH-DEPLOY-ANALYSIS.md)):

- Solo instructor deploys 2-3 times per week
- Created standalone `quick-deploy.sh` script (8-15 sec deployment)
- 3-10x faster than PR workflow
- Lost access to flow-cli's superior pre-flight checks

**Trade-off currently faced:**

- Use `teach deploy` → Robust but slow
- Use standalone script → Fast but less safe

---

## Proposed Solution

### New Flag: `--direct`

Add direct merge mode that preserves safety checks while eliminating PR overhead:

```bash
flow teach deploy --direct
```

### Workflow Comparison

| Step               | Current (PR) | Proposed (--direct) |
| ------------------ | ------------ | ------------------- |
| Pre-flight checks  | ✅ 7 checks  | ✅ 7 checks         |
| Conflict detection | ✅ Yes       | ✅ Yes              |
| Merge strategy     | PR creation  | Direct merge        |
| Browser required   | ✅ Yes       | ❌ No               |
| Manual merge       | ✅ Required  | ❌ Auto             |
| Time               | 45-90 sec    | 8-15 sec            |

### Implementation Approach

**Modify:** `lib/dispatchers/teach-dispatcher.zsh` → `_teach_deploy()` function

**Add conditional branch after pre-flight checks (line ~1500):**

```zsh
_teach_deploy() {
  # ... existing pre-flight checks (lines 1407-1500) ...

  # NEW: Check for --direct flag
  local DIRECT_MODE=false
  if [[ "$1" == "--direct" ]]; then
    DIRECT_MODE=true
  fi

  # ... existing conflict detection (lines 1500-1550) ...

  if [[ "$DIRECT_MODE" == "true" ]]; then
    # Direct merge workflow
    _teach_deploy_direct "$DRAFT_BRANCH" "$PRODUCTION_BRANCH"
  else
    # Existing PR workflow
    _teach_deploy_pr "$DRAFT_BRANCH" "$PRODUCTION_BRANCH"
  fi
}

_teach_deploy_direct() {
  local draft_branch="$1"
  local prod_branch="$2"

  print -P "%F{cyan}⚡ Direct deploy mode (fast merge)%f"

  # Switch to production
  git checkout "$prod_branch" || {
    _teach_error "Failed to checkout $prod_branch"
    return 1
  }

  # Merge draft → production
  if ! git merge "$draft_branch" --no-edit; then
    _teach_error "Merge failed - conflicts detected"
    git merge --abort
    git checkout "$draft_branch"
    return 1
  fi

  # Push to remote
  if ! git push origin "$prod_branch"; then
    _teach_error "Push failed"
    git checkout "$draft_branch"
    return 1
  fi

  # Return to draft
  git checkout "$draft_branch"

  # Success message
  local deploy_url=$(yq e '.deployment.web.url' "$TEACH_CONFIG")
  print -P "%F{green}✓ Deployed to production%f"
  print -P "%F{cyan}→ Live site: $deploy_url%f"
  print -P "%F{yellow}→ Monitor: $(gh run list --workflow=deploy.yml --limit=1 --json url -q '.[0].url')%f"
}
```

---

## Benefits

### For Solo Instructors

- ✅ **3-10x faster** deployment (8-15 sec vs 45-90 sec)
- ✅ **No browser switching** - stay in terminal
- ✅ **Preserve safety** - all pre-flight checks still run
- ✅ **Unified tooling** - no need for standalone scripts

### For flow-cli

- ✅ **Increased adoption** - attracts solo instructors to flow-cli
- ✅ **Better UX** - flexibility for different workflows
- ✅ **Maintains defaults** - PR workflow still default (safest option)

### For Teams

- ✅ **No impact** - default behavior unchanged
- ✅ **Optional express lane** - can use `--direct` for urgent fixes
- ✅ **Backward compatible** - existing scripts unaffected

---

## User Stories

### Story 1: Urgent Typo Fix

**As a** solo instructor,
**I want to** quickly fix a typo on the live syllabus,
**So that** students see the correction immediately without PR overhead.

```bash
# Current: 60-90 seconds
flow teach deploy    # Creates PR, opens browser, manual merge

# Proposed: 10 seconds
flow teach deploy --direct
```

### Story 2: Frequent Updates

**As an** instructor updating lecture notes 3x/week,
**I want to** deploy without context-switching to browser,
**So that** I can maintain focus and iterate quickly.

### Story 3: Emergency Fix

**As a** team member,
**I want to** bypass PR review for critical production hotfixes,
**So that** I can deploy emergency corrections in seconds, not minutes.

---

## Technical Details

### Safety Preserved

All existing pre-flight checks still run in `--direct` mode:

1. ✅ Verify teach-config.yml exists
2. ✅ Check yq installed
3. ✅ Validate branch names
4. ✅ Confirm on draft branch
5. ✅ Check uncommitted changes
6. ✅ Detect merge conflicts
7. ✅ Validate remote branch exists

**Key difference:** Skip PR creation/merge, use direct `git merge` instead.

### Error Handling

Direct mode has identical error handling:

- **Merge conflicts:** Abort merge, return to draft, exit
- **Push failures:** Return to draft, show error
- **Pre-flight failures:** Exit before any git operations

### Configuration

No new config required - uses existing teach-config.yml:

```yaml
branches:
  draft: 'draft'
  production: 'production'

deployment:
  web:
    url: 'https://example.com'
```

Optional enhancement (future):

```yaml
deployment:
  default_mode: 'direct' # or "pr" (default: "pr")
```

---

## Implementation Plan

### Phase 1: Core Functionality (2 hours)

- [ ] Add `--direct` flag parsing
- [ ] Implement `_teach_deploy_direct()` function
- [ ] Add conditional branch in `_teach_deploy()`
- [ ] Update error handling for direct mode

### Phase 2: Polish (1 hour)

- [ ] Add progress indicators
- [ ] Improve success messages
- [ ] Add GitHub Actions monitoring link

### Phase 3: Documentation (1 hour)

- [ ] Update README.md with `--direct` flag
- [ ] Add use case examples
- [ ] Document when to use PR vs direct mode

### Testing Checklist

- [ ] Direct merge success path
- [ ] Merge conflict handling
- [ ] Push failure handling
- [ ] Pre-flight check failures
- [ ] Branch validation
- [ ] Return to draft after errors

---

## Comparison with Standalone Script

STAT 545's `quick-deploy.sh` (56 lines) vs proposed `teach deploy --direct`:

| Feature            | quick-deploy.sh | teach deploy --direct |
| ------------------ | --------------- | --------------------- |
| Pre-flight checks  | 2 basic         | 7 comprehensive       |
| Conflict detection | ⚠️ Basic        | ✅ Advanced           |
| Error messages     | Plain text      | Colored, structured   |
| Remote validation  | ❌ No           | ✅ Yes                |
| gh CLI integration | ❌ No           | ✅ Yes                |
| Monitoring links   | ❌ No           | ✅ Yes                |
| Config-driven      | ✅ Yes          | ✅ Yes                |
| Speed              | 8-15 sec        | 10-18 sec             |

**Verdict:** `teach deploy --direct` would be superior while only marginally slower.

---

## Migration Path

For existing `quick-deploy.sh` users:

```bash
# Before (standalone script)
./scripts/quick-deploy.sh

# After (flow-cli)
flow teach deploy --direct

# Benefits of switching:
# + Better pre-flight validation
# + Automatic conflict detection
# + Monitoring link generation
# + Consistent with other flow-cli commands
# - 2-3 seconds slower (acceptable trade-off)
```

---

## Alternative Designs Considered

### 1. Separate Command: `flow teach deploy-direct`

**Pros:** Clear separation of workflows
**Cons:** More commands to remember, violates DRY
**Verdict:** ❌ Flag is more intuitive

### 2. Config File Setting: `default_mode: direct`

**Pros:** No flag needed per-deployment
**Cons:** Less explicit, harder to override
**Verdict:** ⚠️ Could add as enhancement later

### 3. Alias: `flow teach quickdeploy`

**Pros:** Memorable name
**Cons:** Duplicates functionality, harder to maintain
**Verdict:** ❌ Flag is cleaner

---

## Success Metrics

**Adoption:**

- 3+ solo instructors switch from standalone scripts to `teach deploy --direct`
- 5+ "express lane" deployments by teams (urgent fixes)

**Performance:**

- Direct mode completes in <20 seconds (vs 45-90 for PR mode)
- Zero regression in safety (same pre-flight checks pass/fail rate)

**Satisfaction:**

- Positive feedback from STAT 545 instructor (pilot user)
- No requests to remove the feature within 6 months

---

## Risks and Mitigations

### Risk 1: Users skip code review

**Impact:** Lower code quality in team environments
**Mitigation:** Keep PR mode as default, require explicit `--direct` flag
**Probability:** Low (teams understand review value)

### Risk 2: Direct mode has bugs

**Impact:** Failed deployments, user frustration
**Mitigation:** Comprehensive testing, pilot with STAT 545 first
**Probability:** Low (simple git operations)

### Risk 3: Maintenance burden

**Impact:** Two code paths to maintain
**Mitigation:** Share 90% of code (pre-flight checks), only merge differs
**Probability:** Very low (well-isolated change)

---

## Open Questions

1. **Should we add a confirmation prompt for direct mode?**
   - Pro: Extra safety for destructive operation
   - Con: Slows down deployment (defeats purpose)
   - **Recommendation:** No prompt - pre-flight checks are sufficient

2. **Should direct mode auto-open monitoring URL?**
   - Pro: Easy to track deployment progress
   - Con: Opens browser (defeats "stay in terminal" goal)
   - **Recommendation:** Print URL, don't auto-open

3. **Should we support both `--direct` and `-d` flags?**
   - Pro: Faster to type
   - Con: `-d` might be ambiguous (debug?)
   - **Recommendation:** Support both for flexibility

---

## Related Work

- **STAT 545 quick-deploy.sh:** [scripts/quick-deploy.sh](../../../teaching/stat-545/scripts/quick-deploy.sh)
- **Analysis document:** [FLOW-CLI-TEACH-DEPLOY-ANALYSIS.md](../../../teaching/stat-545/docs/FLOW-CLI-TEACH-DEPLOY-ANALYSIS.md)
- **Deployment architecture:** [DEPLOYMENT-ARCHITECTURE.md](../../../teaching/stat-545/docs/DEPLOYMENT-ARCHITECTURE.md)
- **Current teach deploy implementation:** [lib/dispatchers/teach-dispatcher.zsh](lib/dispatchers/teach-dispatcher.zsh#L1407-L1753)

---

## Conclusion

Adding `--direct` mode to `teach deploy` would:

1. ✅ **Solve real pain point** for solo instructors (3-10x faster)
2. ✅ **Preserve safety** (all pre-flight checks still run)
3. ✅ **Low implementation cost** (~2-4 hours)
4. ✅ **High value** (enables migration from standalone scripts)
5. ✅ **Zero breaking changes** (PR mode remains default)

**Recommendation:** Implement in next flow-cli release.

---

## Appendix: Code Sketch

### Minimal Implementation (35 lines)

```zsh
# Add to lib/dispatchers/teach-dispatcher.zsh

_teach_deploy_direct() {
  local draft="$1"
  local prod="$2"

  print -P "%F{cyan}⚡ Direct deploy mode%f"

  # Merge
  git checkout "$prod" || return 1
  if ! git merge "$draft" --no-edit; then
    git merge --abort
    git checkout "$draft"
    _teach_error "Merge conflict - resolve manually"
    return 1
  fi

  # Push
  if ! git push origin "$prod"; then
    git checkout "$draft"
    _teach_error "Push failed"
    return 1
  fi

  git checkout "$draft"

  # Success
  local url=$(yq e '.deployment.web.url' "$TEACH_CONFIG")
  print -P "%F{green}✓ Deployed%f → $url"
}

# Modify _teach_deploy() to add flag handling (line ~1450)
if [[ "$1" == "--direct" || "$1" == "-d" ]]; then
  _teach_deploy_direct "$DRAFT_BRANCH" "$PRODUCTION_BRANCH"
else
  _teach_deploy_pr "$DRAFT_BRANCH" "$PRODUCTION_BRANCH"
fi
```

---

**Next Steps:**

1. Review feature request with flow-cli maintainer
2. Create GitHub issue if approved
3. Implement feature in new branch
4. Pilot with STAT 545 for 2 weeks
5. Merge if successful
