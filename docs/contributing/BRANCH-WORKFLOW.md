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

## Mandatory Workflow Protocol (Claude Code Development)

When working with Claude Code on flow-cli, follow these **strict** steps to maintain code quality and branch integrity.

### 1. Planning Phase (Always on `dev`)

**Location:** Main repository on `dev` branch

**Steps:**
1. Analyze requirements and existing code on `dev` branch
2. Create comprehensive implementation plan
3. Document plan in spec file (`docs/specs/SPEC-*.md`)
4. **Wait for user approval** before proceeding
5. Commit approved plan to `dev` branch

**Example:**
```bash
# Ensure you're on dev
git checkout dev
git pull origin dev

# Create spec file
# [Claude analyzes code, writes plan]

# Commit plan to dev
git add docs/specs/SPEC-feature-name.md
git commit -m "docs: add feature X implementation plan"
git push origin dev
```

**Critical Rule:** ❌ **Never start coding during planning phase**

---

### 2. Worktree Creation (Isolation)

**After plan approval**, create an isolated worktree for implementation:

```bash
# Create worktree from dev
git worktree add ~/.git-worktrees/flow-cli-<feature-name> -b feature/<feature-name> dev

# Verify creation
git worktree list
```

**Worktree Location Convention:**
- Standard: `~/.git-worktrees/flow-cli-<feature-name>`
- Project-specific: `~/.git-worktrees/<project>-<feature>`

**Critical Rules:**
- ✅ Create worktree from `dev` branch
- ✅ Verify worktree was created successfully
- ❌ **DO NOT start working in the worktree from the planning session**
- ✅ Tell user to start **NEW Claude session** in worktree directory

**Correct Pattern:**
```bash
# In planning session (dev branch)
git worktree add ~/.git-worktrees/flow-cli-cache -b feature/cache dev

# STOP HERE - Do not continue working
# Tell user:
"Worktree created at ~/.git-worktrees/flow-cli-cache

To start implementation, please start a new session:
  cd ~/.git-worktrees/flow-cli-cache
  claude"
```

**Why?** Fresh session ensures:
- Clean context (no planning session baggage)
- Correct working directory
- Proper git state verification
- Isolated focus on implementation

---

### 3. Atomic Development (In Worktree)

**Location:** Worktree directory (`~/.git-worktrees/flow-cli-<feature>`)

**Commit Standards:**
- Use **Conventional Commits** format
- Keep commits small and functional
- Each commit must build successfully

**Conventional Commit Types:**
```bash
feat:      New feature
fix:       Bug fix
refactor:  Code restructure (no behavior change)
docs:      Documentation only
test:      Add/modify tests
chore:     Maintenance (deps, config)
perf:      Performance improvement
style:     Formatting, whitespace
```

**Examples:**
```bash
# Good commits
git commit -m "feat: add project cache layer with 5min TTL"
git commit -m "test: add 8 unit tests for cache validation"
git commit -m "docs: update CLAUDE.md with cache architecture"

# Bad commits (avoid)
git commit -m "WIP"
git commit -m "fixes stuff"
git commit -m "updated files"
```

**Before Each Commit:**
1. Run tests: `./tests/run-all.sh` or specific test suite
2. Check linting: `shellcheck` for zsh files (if applicable)
3. Verify builds: `source flow.plugin.zsh` (no errors)

---

### 4. Integration (feature/* → dev)

**Location:** Still in worktree

**Steps:**

1. **Rebase onto latest dev** (linear history)
   ```bash
   # Fetch latest dev
   git fetch origin dev

   # Rebase feature onto dev
   git rebase origin/dev

   # Resolve conflicts if any
   # Then: git rebase --continue
   ```

2. **Run full test suite**
   ```bash
   ./tests/run-all.sh
   # All tests must pass
   ```

3. **Push feature branch**
   ```bash
   git push -u origin feature/<feature-name>
   ```

4. **Create PR to dev**
   ```bash
   # Using gh CLI (recommended)
   gh pr create --base dev --title "feat: feature name" --body "..."

   # Or use g dispatcher
   g feature finish
   ```

5. **After PR merge, cleanup**
   ```bash
   # Remove worktree
   git worktree remove ~/.git-worktrees/flow-cli-<feature-name>

   # Delete local branch (if merged)
   git branch -d feature/<feature-name>

   # Delete remote branch (usually auto-deleted by GitHub)
   git push origin --delete feature/<feature-name>
   ```

---

### 5. Release (dev → main)

**Who:** Maintainers only

**Steps:**

1. **Verify dev stability**
   ```bash
   git checkout dev
   git pull origin dev

   # Run full test suite on dev
   ./tests/run-all.sh

   # Verify documentation is up to date
   mkdocs build
   ```

2. **Create release PR**
   ```bash
   # Using gh CLI
   gh pr create --base main --head dev \
     --title "Release v5.X.0" \
     --body "Release notes..."

   # Or use g dispatcher
   g release
   ```

3. **After PR approval and merge**
   ```bash
   # Tag release
   git tag -a v5.X.0 -m "Release v5.X.0"
   git push --tags

   # Sync dev with main
   git checkout dev
   git merge main
   git push origin dev
   ```

**Critical Rule:** ❌ **Never merge dev → main without PR**

---

## Tool Usage Constraints (Claude Code)

### Pre-Command Verification

**Always verify context before git operations:**

```bash
# Check current branch
git branch --show-current

# Check if in worktree
git worktree list | grep $(pwd)

# Check remote tracking
git status
```

### Abort Conditions

Claude Code must **ABORT** and redirect if:

1. **About to commit to main**
   ```
   ⛔ ABORT: Cannot commit directly to main

   Redirect to: Create feature branch or PR workflow
   ```

2. **About to commit to dev** (without explicit approval)
   ```
   ⚠️  WARNING: Committing to dev branch

   Expected: Work should be in feature/* branch
   Confirm: Is this a spec/planning commit? (Y/n)
   ```

3. **Push to main/dev without PR**
   ```
   ⛔ ABORT: Direct push to protected branch blocked

   Workflow: Use PR process instead
   Command: gh pr create --base dev
   ```

4. **Working in worktree from planning session**
   ```
   ⚠️  STOP: Do not implement features in planning session

   Action: Tell user to start NEW session in worktree:
     cd ~/.git-worktrees/flow-cli-<feature>
     claude
   ```

### Override (Emergency Only)

```bash
# Skip workflow guards (use with extreme caution)
GIT_WORKFLOW_SKIP=1 git push origin main

# Logged to: ~/.claude/workflow-violations.log
```

---

## Workflow Validation Checklist

Before any merge, verify:

- [ ] All tests passing (`./tests/run-all.sh`)
- [ ] No linting errors (`shellcheck` if applicable)
- [ ] Documentation updated (CLAUDE.md, README.md, relevant guides)
- [ ] Conventional commits used
- [ ] Linear history (rebased if needed)
- [ ] PR created (not direct push)
- [ ] CI checks passing (GitHub Actions)
- [ ] Branch protection rules followed

---

## Related Documentation

- [PR Workflow Guide](PR-WORKFLOW-GUIDE.md) - Complete PR process
- [Tutorial: Git Feature Workflow](../tutorials/08-git-feature-workflow.md) - Step-by-step guide
- [G Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md#g-git-workflows) - All g commands

---

**Established:** v4.1.0 (2025-12-29)
**Updated:** 2026-01-11
**Status:** ✅ Production Ready
