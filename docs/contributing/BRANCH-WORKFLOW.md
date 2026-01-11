# Branch Workflow - flow-cli

**Status:** ✅ Established (v4.1.0+)
**Last Updated:** 2026-01-11

---

## Overview

flow-cli uses a **three-tier branch strategy** for safe, organized development.

```
feature/* ──► dev ──► main
hotfix/*       │        │
    │          │        │
    └── PR ────┘        │
               └── PR ──┘
```

---

## Branch Structure

### 1. `main` - Production

- **Purpose:** Stable, production-ready code
- **Updates:** Release PRs from `dev` only
- **Protection:** ⚠️ Direct pushes blocked by g dispatcher
- **Who can merge:** Maintainers only

### 2. `dev` - Integration

- **Purpose:** Integration branch for all development
- **Updates:** Feature PRs from `feature/*`, `fix/*`, `docs/*`
- **Protection:** ⚠️ Direct pushes blocked by g dispatcher
- **Who can merge:** Maintainers only
- **Testing:** All changes must pass CI before merge

### 3. `feature/*` - Development

- **Purpose:** Individual features, fixes, improvements
- **Created from:** `dev` branch
- **Merged to:** `dev` branch (via PR)
- **Who can push:** Contributors
- **Naming:** `feature/description`, `fix/bug-name`, `docs/topic`

### 4. `hotfix/*` - Emergency Fixes

- **Purpose:** Critical production bugs
- **Created from:** `main` branch
- **Merged to:** `main` branch directly (via PR)
- **Who can create:** Maintainers only
- **Protection:** Bypasses normal workflow

---

## Workflow Commands

### Starting Work

```bash
# Recommended: Use g dispatcher
g feature start my-feature

# What it does:
# 1. Fetches latest dev
# 2. Creates feature/my-feature from dev
# 3. Switches to new branch
```

### During Development

```bash
# Make changes, commit
git add .
git commit -m "feat: add new capability"

# Keep in sync with dev
g feature sync
```

### Finishing Work

```bash
# Create PR to dev
g feature finish

# What it does:
# 1. Pushes branch to origin
# 2. Creates PR with dev as base
# 3. Opens PR in browser
```

### Release Workflow

```bash
# After testing on dev, create release PR
g release

# What it does:
# 1. Creates PR: dev → main
# 2. Includes all merged features
# 3. Opens PR for maintainer review
```

---

## Workflow Guard

The `g` dispatcher **automatically blocks** direct pushes to protected branches:

```bash
# Example: Trying to push to main
$ git checkout main
$ g push

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔ Direct push to 'main' blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflow: feature/* → dev → main

Use instead:
  g feature start <name>  Start feature branch
  g promote               Create PR: feature → dev

Override: GIT_WORKFLOW_SKIP=1 git push
```

### Protected Branches

- `main`
- `master` (legacy)
- `dev`

### Bypass (Use Carefully)

```bash
# Only when absolutely necessary
GIT_WORKFLOW_SKIP=1 git push origin main
```

**Logged:** All blocked attempts are logged to `~/.claude/workflow-violations.log`

---

## Common Workflows

### 1. New Feature

```bash
# Start
g feature start auth-improvements

# Work
# ... make changes ...
git commit -m "feat: add OAuth support"

# Keep updated
g feature sync

# Finish
g feature finish
```

### 2. Bug Fix

```bash
# Start
g feature start fix-session-timeout

# Work
git commit -m "fix: resolve session timeout race condition"

# Finish
g feature finish
```

### 3. Documentation

```bash
# Start
g feature start docs-dispatcher-reference

# Work
git commit -m "docs: update dispatcher reference"

# Finish
g feature finish
```

### 4. Hotfix (Maintainers Only)

```bash
# Critical production bug
git checkout main
git pull origin main
git checkout -b hotfix/security-patch

# Fix
git commit -m "fix: patch security vulnerability"

# PR directly to main
git push origin hotfix/security-patch
gh pr create --base main --title "Security patch"
```

---

## Branch Protection Rules

### Current Setup (2026-01-11)

| Branch | GitHub Protection | g Dispatcher Guard |
|--------|-------------------|-------------------|
| `main` | ✅ Required PR + CI | ✅ Blocks direct push |
| `dev` | ⚠️ Recommended | ✅ Blocks direct push |
| `feature/*` | ❌ Not needed | ❌ No restrictions |

### Recommended GitHub Settings

**For `main`:**
- ✅ Require pull request before merging
- ✅ Require status checks to pass (CI)
- ✅ Require conversation resolution
- ✅ Do not allow bypassing

**For `dev`:**
- ✅ Require pull request before merging
- ✅ Require status checks to pass (CI)
- ⚠️ Allow maintainers to bypass (for urgent merges)

### Setup Branch Protection

```bash
# Using GitHub CLI
gh api repos/Data-Wise/flow-cli/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field required_status_checks='{"strict":true,"contexts":["ZSH Plugin Tests"]}' \
  --field enforce_admins=true

# Or via GitHub web UI:
# Settings → Branches → Add rule
```

---

## Verification

### Check Workflow is Enforced

```bash
# 1. Test workflow guard
git checkout main
g push  # Should be blocked

# 2. Verify branches exist
git branch -a | grep -E "main|dev"

# 3. Test feature workflow
g feature start test-workflow
g feature finish
```

### Monitor Violations

```bash
# Check log file
tail -f ~/.claude/workflow-violations.log
```

---

## Troubleshooting

### "Cannot fast-forward" Error

```bash
# Your branch is behind dev
g feature sync

# Or manually:
git fetch origin
git merge origin/dev
```

### Accidentally Committed to main/dev

```bash
# Move commit to feature branch
git checkout main
git checkout -b feature/rescued-work
git checkout main
git reset --hard origin/main
```

### Workflow Guard Not Working

```bash
# Verify g dispatcher is loaded
type g

# Reload plugin
source flow.plugin.zsh

# Check function exists
type _g_check_workflow
```

---

## Related Documentation

- [PR Workflow Guide](PR-WORKFLOW-GUIDE.md) - Complete PR process
- [Tutorial: Git Feature Workflow](../tutorials/08-git-feature-workflow.md) - Step-by-step guide
- [G Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md#g-git-workflows) - All g commands

---

**Established:** v4.1.0 (2025-12-29)
**Updated:** 2026-01-11
**Status:** ✅ Production Ready
