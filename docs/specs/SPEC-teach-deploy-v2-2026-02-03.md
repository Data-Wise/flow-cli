# SPEC: teach deploy v2 — STAT-545 Port + New Features

**Status:** draft
**Created:** 2026-02-03
**From Brainstorm:** BRAINSTORM-teach-deploy-v2-2026-02-03.md
**Target Version:** v6.4.0

---

## Overview

Enhance `teach deploy` with 8 features ported from STAT-545's battle-tested deploy workflow and new capabilities. Consolidate two deploy code paths into a single enhanced implementation. Adds direct merge mode (8-15s deploys), smart commit messages, deployment history with rollback, dry-run preview, CI support, and .STATUS auto-updates.

---

## Primary User Story

**As a** solo course instructor using flow-cli,
**I want** fast, safe, trackable deployments with smart defaults,
**So that** I can deploy course content in under 15 seconds with full history and rollback capability.

### Acceptance Criteria

- [ ] `teach deploy --direct` completes in <15 seconds (vs 45-90s PR mode)
- [ ] Smart commit messages generated automatically from changed files
- [ ] `teach deploy --dry-run` previews all operations without mutation
- [ ] `.flow/deploy-history.yml` records every deployment
- [ ] `teach deploy --rollback` reverts any recent deployment
- [ ] `teach deploy --ci` works without interactive prompts
- [ ] `.STATUS` auto-updates teaching week on deploy
- [ ] Old `_teach_deploy()` dead code removed from teach-dispatcher.zsh
- [ ] All existing tests pass (`./tests/run-all.sh`)
- [ ] 65+ new tests across 3 test files

---

## Secondary User Stories

**As a** CI/CD pipeline,
**I want** non-interactive deploy mode,
**So that** GitHub Actions can deploy without prompts.

**As an** instructor who made a mistake,
**I want** to rollback the last deployment,
**So that** students don't see broken content.

---

## Architecture

```
teach deploy [args]
  → teach-dispatcher.zsh (routing only)
  → _teach_deploy_enhanced()
      ├── Parse flags
      ├── _deploy_preflight_checks()
      ├── Mode dispatch:
      │   ├── --dry-run   → _deploy_dry_run_report()
      │   ├── --rollback  → _deploy_rollback()
      │   ├── --direct    → _deploy_direct_merge()
      │   ├── partial     → _deploy_partial()
      │   └── default     → _deploy_full_site()
      └── Post-deploy:
          ├── _deploy_history_append()
          └── _deploy_update_status_file()
```

---

## API Design

| Flag | Short | Purpose |
|------|-------|---------|
| `--direct` | `-d` | Direct merge mode (no PR) |
| `--dry-run` | `--preview` | Preview without executing |
| `--rollback [N]` | | Revert deployment N from history |
| `--ci` | | Force non-interactive mode |
| `--message "text"` | `-m` | Custom commit message |
| `--auto-commit` | | Auto-commit dirty files |
| `--auto-tag` | | Tag with timestamp |
| `--skip-index` | | Skip index management |
| `--check-prereqs` | | Validate prerequisites |
| `--direct-push` | | Alias for `--direct` (backward compat) |

---

## Data Models

### deploy-history.yml

```yaml
deploys:
  - timestamp: '2026-02-03T14:30:22-06:00'
    mode: 'direct'
    commit_hash: 'a1b2c3d4'
    commit_before: 'e5f6g7h8'
    branch_from: 'draft'
    branch_to: 'production'
    files_deployed: []
    file_count: 15
    commit_message: 'content: week-05 lecture'
    pr_number: null
    tag: null
    user: 'dt'
    duration_seconds: 12
```

---

## Dependencies

- `yq` — YAML parsing (already a teach dependency)
- `gh` — GitHub CLI for PR creation (already used)
- `git` — Core operations (already used)
- No new external dependencies

---

## UI/UX Specifications

### Deploy Output Format

```
  Deploying to production...

  Pre-flight:
    [ok] Git repository
    [ok] Config file found
    [ok] On draft branch
    [ok] Working tree clean
    [ok] No production conflicts

  Smart commit: content: week-05 lecture, assignment 3, config

  Direct merge: draft -> production
    [ok] Merged successfully
    [ok] Pushed to origin/production

  History logged: #12 (2026-02-03 14:30)
  .STATUS updated: week 5, deploy #12

  Done in 11s
  Site: https://example.github.io/stat-545/
```

### Dry-Run Output

```
  DRY RUN — No changes will be made

  Would deploy 3 files:
    lectures/week-05.qmd
    scripts/analysis.R (dependency)
    home_lectures.qmd (index update)

  Would commit: "content: week-05 lecture, analysis script"
  Would merge: draft -> production (direct mode)
  Would log: deploy #12 to .flow/deploy-history.yml
  Would update: .STATUS (teaching_week: 5)
```

### Rollback Interactive

```
  Recent deployments:

  #  When              Mode     Files  Message
  1  2026-02-03 14:30  direct   3      content: week-05 lecture
  2  2026-02-02 09:15  pr       15     deploy: full site update
  3  2026-02-01 16:45  partial  2      content: assignment 3

  Rollback which deployment? [1]:
```

### Accessibility

- All output uses existing `_flow_log_*` color functions with fallbacks
- `--ci` mode outputs plain text (no ANSI)
- Help follows CONVENTIONS.md 9-rule compliance

---

## Open Questions

1. Should `--rollback` of a PR deploy create a revert PR, or direct-push the revert?
2. Should deploy-history.yml be git-tracked or gitignored?

---

## Review Checklist

- [ ] All 9 features implemented
- [ ] Old dead code removed from teach-dispatcher.zsh
- [ ] Flag matrix interactions tested
- [ ] 65+ new tests pass
- [ ] Existing 462+ tests still pass
- [ ] Help compliance passes (`flow doctor --help-check`)
- [ ] CLAUDE.md updated
- [ ] Backward compatibility: `--direct-push` still works

---

## Implementation Notes

- Implementation follows 7 phases (see plan file)
- Phase 1 (CI mode) must come first — all other features depend on interactivity awareness
- Smart commit messages reuse STAT-545's `generate_smart_message()` categorization logic
- Deploy history uses append-only YAML (no full-file rewrite via yq)
- Rollback is "forward rollback" via `git revert`, not destructive `git reset`
- .STATUS updates are non-destructive: skip if file doesn't exist, skip teaching_week if no semester_info.start_date

---

## History

| Date | Change |
|------|--------|
| 2026-02-03 | Initial spec from deep brainstorm session |
