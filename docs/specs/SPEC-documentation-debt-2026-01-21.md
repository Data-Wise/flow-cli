# SPEC: Documentation Debt Remediation

**Created:** 2026-01-21
**Status:** Phase 1 Complete ✅
**Branch:** `feature/documentation-debt`
**Worktree:** `~/.git-worktrees/flow-cli/documentation-debt`
**Priority:** Low (non-blocking, quality improvement)

---

## Executive Summary

flow-cli has grown to 853 functions but only 8.6% have help text. While user-facing documentation is excellent (100% dispatcher coverage), the internal API documentation for helper libraries is nearly non-existent (0.5% coverage). This creates barriers for contributors and makes the codebase harder to maintain.

### Key Metrics

| Metric | Current | Target | Gap |
|--------|---------|--------|-----|
| Total functions | 853 | - | - |
| Functions with help | 73 | 200+ | 127+ |
| Dispatcher coverage | 100% | 100% | ✅ Done |
| Helper library coverage | 0.5% | 50%+ | ~170 functions |
| API reference docs | 0 pages | 3 pages | 3 pages |

---

## Problem Statement

### 1. Developer Experience Issues

- **No API reference**: Contributors must read source code to understand helper functions
- **Inconsistent patterns**: Some functions have comments, most don't
- **Discovery barrier**: No way to find available utilities without grep-ing

### 2. Maintenance Challenges

- **Function duplication**: Similar functions exist because developers don't know utilities exist
- **Inconsistent usage**: Same task done different ways across codebase
- **Refactoring risk**: Hard to know what's public API vs internal

### 3. Specific Gaps

| Library | Functions | Documented | Impact |
|---------|-----------|------------|--------|
| `dotfile-helpers.zsh` | 27 | 0 | High - complex |
| `atlas-bridge.zsh` | 23 | 0 | Medium - optional |
| `plugin-loader.zsh` | 23 | 0 | Low - internal |
| `validation-helpers.zsh` | 19 | 0 | High - teaching |
| `git-helpers.zsh` | 17 | 0 | **Critical** |
| `tui.zsh` | 16 | 0 | **Critical** |
| `config.zsh` | 16 | 0 | Medium |
| `core.zsh` | 14 | 0 | **Critical** |
| Other (24 files) | 207 | 2 | Varies |
| **Total** | **342** | **2** | **0.6%** |

---

## Proposed Solution

### Phase 1: Core Libraries (Priority: Critical)

**Scope:** 47 functions across 3 files
**Effort:** 4-6 hours
**Deliverable:** `docs/reference/CORE-API-REFERENCE.md`

#### 1.1 lib/core.zsh (14 functions)

| Function | Purpose | Priority |
|----------|---------|----------|
| `_flow_log()` | Base logging function | P1 |
| `_flow_log_success()` | Success message (green ✓) | P1 |
| `_flow_log_warning()` | Warning message (yellow ⚠) | P1 |
| `_flow_log_error()` | Error message (red ✗) | P1 |
| `_flow_log_info()` | Info message (blue ℹ) | P1 |
| `_flow_log_muted()` | Muted/gray text | P2 |
| `_flow_log_debug()` | Debug output (FLOW_DEBUG) | P2 |
| `_flow_status_icon()` | Status → emoji mapping | P1 |
| `_flow_project_name()` | Extract project name from path | P1 |
| `_flow_find_project_root()` | Find .STATUS or .git root | P1 |
| `_flow_in_project()` | Check if in project | P2 |
| `_flow_format_duration()` | Format seconds as "Xh Ym" | P1 |
| `_flow_time_ago()` | Format timestamp as "2 hours ago" | P2 |
| `_flow_confirm()` | Y/N confirmation prompt | P1 |

#### 1.2 lib/tui.zsh (16 functions)

| Function | Purpose | Priority |
|----------|---------|----------|
| `_flow_progress_bar()` | ASCII progress bar | P1 |
| `_flow_sparkline()` | Sparkline graph ▁▂▃▅▇ | P2 |
| `_flow_table()` | Formatted table output | P1 |
| `_flow_box()` | Box around content | P1 |
| `_flow_has_fzf()` | Check fzf availability | P2 |
| `_flow_pick_project()` | fzf project picker | P1 |
| `_flow_show_project_preview()` | Preview for picker | P2 |
| `_flow_has_gum()` | Check gum availability | P2 |
| `_flow_input()` | Styled text input | P1 |
| `_flow_confirm_styled()` | Styled Y/N prompt | P1 |
| `_flow_choose()` | Selection menu | P1 |
| `_flow_widget_status()` | Status widget | P2 |
| `_flow_widget_timer()` | Timer widget | P2 |
| `_flow_spinner_start()` | Start spinner | P1 |
| `_flow_spinner_stop()` | Stop spinner | P1 |
| `_flow_with_spinner()` | Run command with spinner | P1 |

#### 1.3 lib/git-helpers.zsh (17 functions)

| Function | Purpose | Priority |
|----------|---------|----------|
| `_git_in_repo()` | Check if in git repo | P1 |
| `_git_current_branch()` | Get current branch name | P1 |
| `_git_remote_branch()` | Get remote tracking branch | P2 |
| `_git_is_clean()` | Check for uncommitted changes | P1 |
| `_git_is_synced()` | Check if synced with remote | P1 |
| `_git_has_unpushed_commits()` | Check for local commits | P1 |
| `_git_get_commit_count()` | Count commits since ref | P2 |
| `_git_get_commit_list()` | List commits since ref | P2 |
| `_git_teaching_files()` | Get teaching-related files | P3 |
| `_git_teaching_commit_message()` | Generate teaching commit msg | P3 |
| `_git_interactive_commit()` | Interactive commit flow | P2 |
| `_git_commit_teaching_content()` | Commit teaching content | P3 |
| `_git_push_current_branch()` | Push with upstream | P2 |
| `_git_create_deploy_pr()` | Create deployment PR | P3 |
| `_git_generate_pr_body()` | Generate PR description | P3 |
| `_git_detect_production_conflicts()` | Check for conflicts | P2 |
| `_git_rebase_onto_production()` | Rebase workflow | P2 |

### Phase 2: Teaching Libraries (Priority: High)

**Scope:** ~60 functions across 5 files
**Effort:** 6-8 hours
**Deliverable:** `docs/reference/TEACHING-API-REFERENCE.md`

| Library | Functions | Description |
|---------|-----------|-------------|
| `validation-helpers.zsh` | 19 | YAML, frontmatter validation |
| `backup-helpers.zsh` | 11 | Backup system |
| `cache-helpers.zsh` | 9 | Cache management |
| `index-helpers.zsh` | 11 | Index manipulation |
| `teaching-utils.zsh` | ~10 | Teaching utilities |

### Phase 3: Integration Libraries (Priority: Medium)

**Scope:** ~80 functions across 6 files
**Effort:** 8-10 hours
**Deliverable:** `docs/reference/INTEGRATION-API-REFERENCE.md`

| Library | Functions | Description |
|---------|-----------|-------------|
| `atlas-bridge.zsh` | 23 | Atlas state engine |
| `plugin-loader.zsh` | 23 | Plugin system |
| `config.zsh` | 16 | Configuration |
| `keychain-helpers.zsh` | ~8 | macOS Keychain |
| `project-detector.zsh` | ~8 | Project type detection |
| `project-cache.zsh` | ~6 | Project caching |

### Phase 4: Specialized Libraries (Priority: Low)

**Scope:** ~155 functions across remaining files
**Effort:** 10-12 hours
**Deliverable:** Individual API sections or appendix

---

## Documentation Format

### Inline Documentation Standard

```zsh
# =============================================================================
# Function: _flow_example
# Purpose: Brief one-line description
# =============================================================================
# Arguments:
#   $1 - (required) First argument description
#   $2 - (optional) Second argument description [default: "value"]
#
# Returns:
#   0 - Success
#   1 - Error (describe when)
#
# Output:
#   stdout - What it prints (if any)
#   stderr - Error messages (if any)
#
# Example:
#   _flow_example "arg1" "arg2"
#   result=$(_flow_example "arg1")
#
# Dependencies:
#   - _flow_log (from core.zsh)
#   - fzf (optional)
#
# Notes:
#   - Additional context or gotchas
# =============================================================================
_flow_example() {
    local required_arg="$1"
    local optional_arg="${2:-default}"
    # implementation
}
```

### API Reference Format

```markdown
## _flow_example

Brief description of what the function does.

### Signature

\`\`\`zsh
_flow_example <required_arg> [optional_arg]
\`\`\`

### Arguments

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | Yes | - | Description |
| `$2` | string | No | `"default"` | Description |

### Returns

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error condition |

### Example

\`\`\`zsh
# Basic usage
_flow_example "value"

# With optional arg
_flow_example "value" "custom"

# Capture output
result=$(_flow_example "value")
\`\`\`

### See Also

- `_flow_related` - Related function
- `core.zsh` - Parent library
```

---

## Implementation Plan

### Wave 1: Foundation (2-3 hours)

1. **Create API reference template**
   - `docs/reference/API-TEMPLATE.md`
   - Consistent structure for all libraries

2. **Document core.zsh** (14 functions)
   - Add inline docstrings
   - Create `CORE-API-REFERENCE.md`

3. **Update mkdocs.yml**
   - Add API Reference section

### Wave 2: TUI Library (2 hours)

1. **Document tui.zsh** (16 functions)
   - Focus on user-facing utilities
   - Include visual examples

2. **Add to CORE-API-REFERENCE.md**

### Wave 3: Git Helpers (2-3 hours)

1. **Document git-helpers.zsh** (17 functions)
   - Separate teaching-specific from general
   - Include workflow examples

2. **Add to CORE-API-REFERENCE.md**

### Wave 4: Testing & Review (1-2 hours)

1. **Verify documentation accuracy**
   - Test each example
   - Check for outdated info

2. **Add to DOCUMENTATION-COVERAGE.md**
   - Update metrics
   - Mark Phase 1 complete

---

## Success Criteria

### Phase 1 Complete When: ✅ COMPLETE (2026-01-22)

- [x] `docs/reference/CORE-API-REFERENCE.md` exists (~2,000 lines) → **1,661 lines**
- [x] 47 functions documented (core.zsh + tui.zsh + git-helpers.zsh) → **47 functions**
- [x] All P1 functions have inline docstrings → **All 47 functions**
- [x] mkdocs.yml updated with API Reference section → **Added**
- [x] DOCUMENTATION-COVERAGE.md updated to reflect progress → **Updated**

### Quality Checklist: ✅ VERIFIED

- [x] Every function has: purpose, args, returns, example
- [x] Examples are copy-pasteable and tested
- [x] Cross-references between related functions
- [x] Consistent formatting throughout

---

## Estimated Timeline

| Phase | Scope | Effort | Priority |
|-------|-------|--------|----------|
| Phase 1 | Core libraries (47 funcs) | 4-6 hours | Critical |
| Phase 2 | Teaching libraries (~60 funcs) | 6-8 hours | High |
| Phase 3 | Integration libraries (~80 funcs) | 8-10 hours | Medium |
| Phase 4 | Specialized libraries (~155 funcs) | 10-12 hours | Low |
| **Total** | **342 functions** | **28-36 hours** | - |

### Recommended Approach

1. **Start with Phase 1** - Maximum impact, minimal effort
2. **Defer Phase 2-4** - Do incrementally as you touch those files
3. **Automate where possible** - Consider docstring extraction script

---

## Alternatives Considered

### 1. Auto-generate from Source

**Pros:** Fast, always up-to-date
**Cons:** No semantic understanding, poor examples
**Decision:** Rejected - quality matters more than coverage

### 2. Document Only Public API

**Pros:** Less work, cleaner interface
**Cons:** Need to define "public" vs "internal"
**Decision:** Partially adopted - mark internal functions as such

### 3. Use TypeScript/JSDoc Style

**Pros:** Tooling support, IDE integration
**Cons:** ZSH has no standard, would be custom
**Decision:** Rejected - stick to shell conventions

---

## Dependencies

- None blocking
- Nice to have: docstring extraction tool (future)

---

## Risks

| Risk | Mitigation |
|------|------------|
| Documentation gets stale | Add to PR checklist |
| Too much effort | Start small (Phase 1 only) |
| Inconsistent style | Create and enforce template |

---

## Related Documents

- `docs/reference/DOCUMENTATION-COVERAGE.md` - Current metrics
- `docs/reference/ARCHITECTURE-OVERVIEW.md` - System context
- `CLAUDE.md` - Project guidelines (documentation standards section)

---

## Appendix: Full Function Inventory

### lib/core.zsh (14 functions)

```
_flow_log()
_flow_log_success()
_flow_log_warning()
_flow_log_error()
_flow_log_info()
_flow_log_muted()
_flow_log_debug()
_flow_status_icon()
_flow_project_name()
_flow_find_project_root()
_flow_in_project()
_flow_format_duration()
_flow_time_ago()
_flow_confirm()
```

### lib/tui.zsh (16 functions)

```
_flow_progress_bar()
_flow_sparkline()
_flow_table()
_flow_box()
_flow_has_fzf()
_flow_pick_project()
_flow_show_project_preview()
_flow_has_gum()
_flow_input()
_flow_confirm_styled()
_flow_choose()
_flow_widget_status()
_flow_widget_timer()
_flow_spinner_start()
_flow_spinner_stop()
_flow_with_spinner()
```

### lib/git-helpers.zsh (17 functions)

```
_git_in_repo()
_git_current_branch()
_git_remote_branch()
_git_is_clean()
_git_is_synced()
_git_has_unpushed_commits()
_git_get_commit_count()
_git_get_commit_list()
_git_teaching_files()
_git_teaching_commit_message()
_git_interactive_commit()
_git_commit_teaching_content()
_git_push_current_branch()
_git_create_deploy_pr()
_git_generate_pr_body()
_git_detect_production_conflicts()
_git_rebase_onto_production()
```

### All Libraries Summary

| Library | Functions |
|---------|-----------|
| dotfile-helpers.zsh | 27 |
| atlas-bridge.zsh | 23 |
| plugin-loader.zsh | 23 |
| validation-helpers.zsh | 19 |
| git-helpers.zsh | 17 |
| tui.zsh | 16 |
| config.zsh | 16 |
| core.zsh | 14 |
| render-queue.zsh | 11 |
| index-helpers.zsh | 11 |
| backup-helpers.zsh | 11 |
| ai-recipes.zsh | 11 |
| performance-monitor.zsh | 10 |
| parallel-helpers.zsh | 10 |
| date-parser.zsh | 10 |
| r-helpers.zsh | 9 |
| profile-helpers.zsh | 9 |
| parallel-progress.zsh | 9 |
| cache-helpers.zsh | 9 |
| ai-usage.zsh | 9 |
| custom-validators.zsh | 8 |
| cache-analysis.zsh | 8 |
| config-validator.zsh | 7 |
| help-browser.zsh | 7 |
| project-detector.zsh | 7 |
| inventory.zsh | 6 |
| status-dashboard.zsh | 6 |
| keychain-helpers.zsh | 5 |
| project-cache.zsh | 5 |
| hook-installer.zsh | 5 |
| teaching-utils.zsh | 4 |
| renv-integration.zsh | 4 |
| **Total** | **342** |

---

**Last Updated:** 2026-01-21
**Author:** Claude Opus 4.5
