---
tags:
  - guide
  - teaching
---

# Teaching Deployment Guide

> Deploy your course website from local preview to production with confidence.
>
> **Version:** v6.4.1+ | **Command:** `teach deploy`

![teach deploy v2 Demo](../demos/tutorials/tutorial-teach-deploy.gif)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Modes](#deployment-modes)
4. [Full Site Deployment](#full-site-deployment)
5. [Partial Deployment](#partial-deployment)
6. [Pre-Flight Checks](#pre-flight-checks)
7. [Deployment Options](#deployment-options)
8. [GitHub Pages Configuration](#github-pages-configuration)
9. [Post-Deploy Verification](#post-deploy-verification)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The `teach deploy` command provides a safe, validated deployment workflow that:

- **Validates environment** - Checks git status, branch configuration, uncommitted changes
- **Tracks dependencies** - Automatically includes sourced files and cross-references
- **Manages indexes** - Updates navigation links (ADD/UPDATE/REMOVE)
- **Creates PRs** - Uses draft → production branch workflow (no direct pushes)
- **Validates prerequisites** - Ensures concepts are introduced before use (optional)
- **Direct merge mode** - 8-15s deploys without PR overhead (`--direct`)
- **Smart commit messages** - Auto-categorized from changed file paths
- **Deploy history** - Tracks every deployment in `.flow/deploy-history.yml`
- **Rollback** - Forward rollback via `git revert` (`--rollback`)
- **Dry-run preview** - Preview without mutation (`--dry-run`)
- **CI mode** - Non-interactive for automated pipelines (`--ci`)

### Design Philosophy

- **Safety First** - Multiple confirmation prompts, preview changes before deployment
- **Incremental** - Support partial deploys (single file or directory)
- **Context-Aware** - Auto-detect dependencies, validate cross-references
- **ADHD-Friendly** - Clear status indicators, visual change previews

---

## Prerequisites

### Required Tools

1. **Git** - Version control
2. **yq** - YAML processing (for config file)
3. **GitHub CLI (gh)** - For creating pull requests

Install missing tools:

```bash
# Check what's missing
teach doctor

# Install homebrew packages
brew install gh yq
```

### Project Setup

1. **Git repository initialized**

   ```bash
   git init
   git remote add origin https://github.com/username/course-repo.git
   ```

2. **Branches configured**

   Default branch structure (configurable in `.flow/teach-config.yml`):
   - `draft` - Working branch for content development
   - `main` - Production branch (GitHub Pages source)

3. **Configuration file exists**

   `.flow/teach-config.yml` must be present:

   ```bash
   teach init  # Creates config if missing
   ```

### First-Time Setup

For new repositories:

```bash
# Initialize project
teach init

# Create draft branch
git checkout -b draft

# First commit
git add .
git commit -m "Initial commit"
git push -u origin draft

# Create main branch
git checkout -b main
git push -u origin main

# Return to draft
git checkout draft
```

---

## Deployment Modes

`teach deploy` supports multiple modes:

| Mode | Trigger | Speed | Use Case |
|------|---------|-------|----------|
| **Full Site (PR)** | `teach deploy` | 45-90s | Review before production |
| **Direct Merge** | `teach deploy -d` | 8-15s | Quick fixes, solo instructor |
| **Partial** | `teach deploy <files>` | Varies | Deploy specific files/directories |
| **Dry-Run** | `teach deploy --dry-run` | <1s | Preview all operations |

### Full Site Deployment

Deploys all changes between `draft` and `main` branches:

```bash
teach deploy
```

**Process:**
1. Verify on draft branch
2. Check for uncommitted changes
3. Detect conflicts with production
4. Generate PR preview
5. Create pull request to main
6. Deploy via GitHub Pages after merge

### Partial Deployment

Deploy specific files or directories:

```bash
# Single file
teach deploy lectures/week-05.qmd

# Multiple files
teach deploy lectures/week-05.qmd lectures/week-06.qmd

# Entire directory
teach deploy lectures/
```

**Process:**
1. Find dependencies (sourced files, cross-references)
2. Validate cross-references
3. Auto-commit changes (with prompts)
4. Update index files (navigation)
5. Push to draft branch
6. Create PR to main (optional)

---

## Direct Merge Mode (v6.4.0)

Skip the PR workflow for fast, direct deployment:

```bash
# Basic direct deploy
teach deploy --direct

# With custom commit message
teach deploy -d -m "Week 5 lecture updates"

# CI-friendly direct deploy
teach deploy --ci -d
```

**Process (with step progress):**

```
  ✓ [1/5] Push draft to origin
  ✓ [2/5] Switch to production
  ✓ [3/5] Merge draft → production
  ✓ [4/5] Push production to origin
  ✓ [5/5] Switch back to draft
```

After completion, a deployment summary box is displayed:

```
╭─ Deployment Summary ─────────────────────────────────╮
│  🚀 Mode:     Direct merge                            │
│  📦 Files:    3 changed (+45 / -12)                   │
│  ⏱  Duration: 11s                                     │
│  🔀 Commit:   a1b2c3d4                                │
│  🌐 URL:      https://example.github.io/stat-545/    │
╰──────────────────────────────────────────────────────╯
```

**When to use:**
- Solo instructor (no review needed)
- Quick fixes (typos, minor updates)
- CI/CD pipelines
- When 45-90s PR workflow is too slow

---

## Deploy History & Rollback (v6.4.0)

### Viewing History

```bash
# Show last 10 deployments
teach deploy --history

# Show last 20
teach deploy --history 20
```

**Output:**
```
Recent deployments:

#  When              Mode     Files  Message
1  2026-02-03 14:30  direct   3      content: week-05 lecture
2  2026-02-02 09:15  pr       15     deploy: full site update
3  2026-02-01 16:45  partial  2      content: assignment 3
```

### Rollback

Revert any deployment safely using forward rollback (`git revert`):

```bash
# Interactive picker
teach deploy --rollback

# Rollback most recent deployment
teach deploy --rollback 1

# Rollback 2nd most recent (CI mode)
teach deploy --rollback 2 --ci
```

**Safety:** Rollback uses `git revert` (not `git reset`), preserving full history. The rollback itself is recorded in deploy history with mode "rollback".

### History File

Stored at `.flow/deploy-history.yml` (git-tracked, append-only):

```yaml
deploys:
  - timestamp: '2026-02-03T14:30:22-06:00'
    mode: 'direct'
    commit_hash: 'a1b2c3d4'
    commit_before: 'e5f6g7h8'
    branch_from: 'draft'
    branch_to: 'main'
    file_count: 15
    commit_message: 'content: week-05 lecture'
```

---

## Dry-Run Preview (v6.4.0)

Preview deployment without making any changes:

```bash
# Preview full site deploy
teach deploy --dry-run

# Preview direct merge
teach deploy --dry-run --direct

# Preview with custom message
teach deploy --preview -m "Week 5"
```

**Output:**
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

---

## Full Site Deployment

### Step-by-Step Workflow

**1. Start from draft branch**

```bash
# Verify current branch
git branch --show-current  # Should output: draft

# If on wrong branch
git checkout draft
```

**2. Run deploy command**

```bash
teach deploy
```

**3. Pre-flight checks**

The command validates:

```
🔍 Pre-flight Checks
─────────────────────────────────────────────────
✓ On draft branch
✓ No uncommitted changes
✓ Remote is up-to-date
✓ No conflicts with production
```

**4. Review changes**

```
📋 Changes Preview
─────────────────────────────────────────────────

Files Changed:
  M  lectures/week-05-regression.qmd
  A  lectures/week-06-inference.qmd
  M  home_lectures.qmd

Summary: 3 files (1 added, 2 modified, 0 deleted)
```

**5. Create pull request**

```
Create pull request?

  [1] Yes - Create PR (Recommended)
  [2] Push to draft only (no PR)
  [3] Cancel

Your choice [1-3]: 1
```

**6. Verify PR created**

```
✅ Pull Request Created

View PR: https://github.com/username/course-repo/pull/42
```

### Handling Conflicts

If production branch (`main`) has new commits:

```
⚠️  Production (main) has new commits

Production branch has updates. Rebase first?

  [1] Yes - Rebase draft onto main (Recommended)
  [2] No - Continue anyway (may have merge conflicts in PR)
  [3] Cancel deployment

Your choice [1-3]: 1
```

**Recommended:** Always choose option [1] to rebase before deploying.

---

## Partial Deployment

### Use Cases

Deploy before entire course is ready:

- Week 5 content is ready, but week 6-15 are still drafts
- Fix typo in single lecture
- Add new lab without re-deploying entire site

### Example: Deploy Single File

```bash
teach deploy lectures/week-05.qmd
```

**Output:**

```
📦 Partial Deploy Mode
─────────────────────────────────────────────────

Files to deploy:
  • lectures/week-05.qmd

🔗 Validating cross-references...
✓ All cross-references valid

🔍 Finding dependencies...
  Dependencies for lectures/week-05.qmd:
    • _macros.qmd
    • data/regression-example.csv

Found 2 additional dependencies
Include dependencies in deployment? [Y/n]: y
```

### Dependency Tracking

`teach deploy` automatically finds:

1. **Sourced files** - `{{< include _macros.qmd >}}`
2. **Data files** - Referenced in code chunks
3. **Cross-references** - `@fig-regression`, `@tbl-anova`

**Control dependency inclusion:**

```bash
# Include dependencies (recommended)
Include dependencies in deployment? [Y/n]: y

# Skip dependencies (deploy only specified file)
Include dependencies in deployment? [Y/n]: n
```

### Index Management

When deploying lectures, the command updates navigation files:

**Before deployment:**

```yaml
# home_lectures.qmd
lectures:
  - week-01.qmd
  - week-02.qmd
  - week-03.qmd
  - week-04.qmd
```

**After deploying week-05.qmd:**

```yaml
lectures:
  - week-01.qmd
  - week-02.qmd
  - week-03.qmd
  - week-04.qmd
  - week-05.qmd  # ← ADDED
```

**Skip index updates:**

```bash
teach deploy lectures/week-05.qmd --skip-index
```

### Auto-Commit Workflow

If deploying files have uncommitted changes:

```
⚠️  Uncommitted changes detected

  • lectures/week-05.qmd

Commit message (or Enter for auto): Fix regression example
✓ Committed changes
```

**Auto-commit mode:**

```bash
teach deploy lectures/week-05.qmd --auto-commit
```

Uses default message: `Update: 2026-02-02`

---

## Pre-Flight Checks

Before deployment, `teach deploy` validates:

### Check 1: Branch Verification

Ensures you're on the draft branch:

```
✓ On draft branch
```

If on wrong branch:

```
✗ Not on draft branch (currently on: main)

Switch to draft branch? [Y/n]: y
✓ Switched to draft
```

### Check 2: Uncommitted Changes

Ensures working directory is clean (configurable):

```
✓ No uncommitted changes
```

If uncommitted changes exist:

```
✗ Uncommitted changes detected

  Commit or stash changes before deploying
  Or disable with: git.require_clean: false
```

**Disable check** in `.flow/teach-config.yml`:

```yaml
git:
  require_clean: false  # Allow deploying with uncommitted changes
```

### Check 3: Unpushed Commits

Ensures draft branch is synced with remote:

```
✓ Remote is up-to-date
```

If unpushed commits exist:

```
⚠️  Unpushed commits detected

Push to origin/draft first? [Y/n]: y
✓ Pushed to origin/draft
```

### Check 4: Production Conflicts

Detects if production has diverged:

```
✓ No conflicts with production
```

If conflicts exist, see [Handling Conflicts](#handling-conflicts).

---

## Deployment Options

### Prerequisite Validation

Block deployment if concepts are used before introduction:

```bash
teach deploy --check-prereqs
```

**Validation process:**

```
🔍 Prerequisite Validation
─────────────────────────────────────────────────
  Building concept graph...
  Checking 42 concepts...
✓ All prerequisites satisfied
```

**If violations found:**

```
✗ Found 2 missing prerequisite(s)
  • simple_linear_regression requires normal_distribution (not defined)
  • hypothesis_testing requires probability (not defined)

Deploy blocked: Prerequisite validation failed
Fix missing prerequisites before deploying

Tip: Run 'teach validate --deep' to see full details
```

### Auto-Commit

Automatically commit changes without prompts:

```bash
teach deploy lectures/week-05.qmd --auto-commit
```

Uses default commit message: `Update: YYYY-MM-DD`

### Auto-Tag

Tag deployment with timestamp:

```bash
teach deploy --auto-tag
```

Creates tag: `deploy-2026-02-02-1430`

### Skip Index Management

Deploy without updating navigation files:

```bash
teach deploy lectures/week-05.qmd --skip-index
```

Use when:
- File isn't listed in navigation
- Manual index management preferred
- Testing deployment workflow

### Combined Options

```bash
teach deploy lectures/week-05.qmd \
  --auto-commit \
  --auto-tag \
  --skip-index \
  --check-prereqs
```

---

## GitHub Pages Configuration

### Configuration File

Edit `.flow/teach-config.yml`:

```yaml
git:
  draft_branch: draft         # Development branch
  production_branch: main     # GitHub Pages source branch
  auto_pr: true              # Auto-create PRs
  require_clean: true        # Require clean working directory

course:
  name: "STAT-101 Regression Analysis"
```

### Branch Setup

GitHub Pages deploys from `main` branch:

**1. Configure in GitHub repository settings:**

```
Settings → Pages → Source → Deploy from a branch
Branch: main
Folder: / (root)
```

**2. Verify deployment:**

After merging PR to main, GitHub Actions builds and deploys:

```
https://username.github.io/course-repo/
```

### Custom Domain

**1. Add CNAME file to repository:**

```bash
echo "stat101.university.edu" > CNAME
git add CNAME
git commit -m "Add custom domain"
```

**2. Configure DNS:**

```
CNAME record: www → username.github.io
A records: @ → 185.199.108.153
           @ → 185.199.109.153
           @ → 185.199.110.153
           @ → 185.199.111.153
```

**3. Update GitHub Pages settings:**

```
Settings → Pages → Custom domain → stat101.university.edu
```

### First-Time Deployment

For new repositories without GitHub Pages:

**1. Create gh-pages branch:**

```bash
git checkout --orphan gh-pages
git rm -rf .
echo "GitHub Pages placeholder" > index.html
git add index.html
git commit -m "Initialize GitHub Pages"
git push origin gh-pages
```

**2. Configure GitHub Pages source:**

```
Settings → Pages → Source → gh-pages branch
```

**3. Run first deployment:**

```bash
git checkout draft
teach deploy
```

---

## Post-Deploy Verification

### Check Deployment Status

**1. Verify PR created:**

```bash
gh pr list
```

**2. Review PR on GitHub:**

Click link from deploy output:

```
View PR: https://github.com/username/course-repo/pull/42
```

**3. Check CI/CD status:**

GitHub Actions runs on PR creation:

```
✓ Build Quarto site (2m 34s)
✓ Deploy preview (15s)
```

### Merge Pull Request

**Option 1: Via GitHub web interface**

1. Review changes in PR
2. Click "Merge pull request"
3. Wait for GitHub Pages deployment

**Option 2: Via command line**

```bash
gh pr merge 42 --squash --delete-branch
```

### Verify Live Site

**1. Wait for GitHub Pages deployment:**

```bash
# Check deployment status
gh api repos/:owner/:repo/pages/builds/latest

# Typical deployment time: 30-60 seconds
```

**2. Visit deployed site:**

```
https://username.github.io/course-repo/
```

**3. Verify changes:**

- Navigate to deployed content
- Check updated index pages
- Verify cross-references work
- Test interactive elements

---

## Troubleshooting

### Common Issues

#### 1. Not on draft branch

**Error:**

```
✗ Not on draft branch (currently on: main)
```

**Solution:**

```bash
git checkout draft
teach deploy
```

#### 2. Uncommitted changes

**Error:**

```
✗ Uncommitted changes detected
```

**Solution:**

```bash
# Option 1: Commit changes
git add .
git commit -m "Update content"

# Option 2: Stash changes
git stash

# Option 3: Allow uncommitted (in config)
# Edit .flow/teach-config.yml:
#   git.require_clean: false
```

#### 3. Permission denied (GitHub Pages)

**Error:**

```
gh: Permission denied (publickey)
```

**Solution:**

```bash
# Setup SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy output to GitHub Settings → SSH Keys
```

#### 4. Build failures (Quarto errors)

**Error:**

```
Error: Quarto render failed
```

**Solution:**

```bash
# Validate locally first
teach validate --render lectures/week-05.qmd

# Check Quarto version
quarto --version

# Update Quarto if needed
brew upgrade quarto
```

#### 5. Missing content after deploy

**Symptom:** File deployed but not visible on site

**Causes:**

1. **Not in index file:**

   ```bash
   # Check navigation
   cat home_lectures.qmd

   # Manually add if missing
   teach deploy lectures/week-05.qmd  # Re-deploy with index update
   ```

2. **YAML frontmatter issue:**

   ```yaml
   # Ensure file has proper frontmatter
   ---
   title: "Week 5: Regression"
   ---
   ```

3. **File not in _quarto.yml:**

   ```yaml
   # Check project config
   project:
     type: website
   website:
     navbar:
       left:
         - href: home_lectures.qmd
           text: Lectures
   ```

#### 6. Git conflicts on gh-pages branch

**Error:**

```
! [rejected] main -> main (non-fast-forward)
```

**Solution:**

```bash
# Fetch latest
git fetch origin main

# Rebase draft onto main
git checkout draft
git rebase origin/main

# Re-run deploy
teach deploy
```

#### 7. Cross-reference validation failures

**Error:**

```
✗ Broken reference: @fig-does-not-exist in lectures/week-05.qmd
```

**Solution:**

```bash
# Fix broken references in source file
# Either:
#   1. Add missing figure label
#   2. Remove invalid reference

# Re-validate
teach validate lectures/week-05.qmd

# Re-deploy
teach deploy lectures/week-05.qmd
```

#### 8. Dependency tracking issues

**Symptom:** Deployed file missing included content

**Solution:**

```bash
# Check dependencies
teach deploy lectures/week-05.qmd
# Review "Finding dependencies..." output

# If dependencies missed:
#   1. Check include syntax: {{< include _macros.qmd >}}
#   2. Verify file paths are relative
#   3. Use --verbose for debugging (future feature)

# Manual workaround: deploy dependencies separately
teach deploy lectures/week-05.qmd _macros.qmd
```

---

## Advanced Workflows

### CI/CD Automation

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Course Site

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: quarto-dev/quarto-actions/setup@v2

      - name: Validate content
        run: |
          quarto render --dry-run

  deploy:
    needs: validate
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: quarto-dev/quarto-actions/publish@v2
        with:
          target: gh-pages
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Benefits:**

- Auto-validate on PR
- Auto-deploy on main branch push
- Preview deployments for PRs

### Preview Deployments for PRs

Use Netlify/Vercel for PR previews:

```yaml
# netlify.toml
[build]
  command = "quarto render"
  publish = "_site"

[context.deploy-preview]
  command = "quarto render"
```

Deploy preview URL appears in PR comments:

```
✓ Deploy Preview ready!
https://deploy-preview-42--course-site.netlify.app
```

### Rollback Procedure

**Using teach deploy (v6.4.0+):**

```bash
# View recent deployments
teach deploy --history

# Rollback most recent
teach deploy --rollback 1

# Verify site
open https://username.github.io/course-repo/
```

**Manual rollback (if needed):**

```bash
git log --oneline main | head -5
git revert -m 1 <merge-commit-hash>
git push origin main
```

---

## See Also

- [Teaching Workflow v3.0 Guide](TEACHING-WORKFLOW-V3-GUIDE.md) - Complete workflow overview
- [Teach Dispatcher Reference](../reference/REFCARD-TEACH-DISPATCHER.md) - Command reference
- [Validation Guide](../reference/REFCARD-LINT.md) - Content validation
- [GitHub Pages Documentation](https://docs.github.com/en/pages) - Official GitHub Pages docs
- [Quarto Publishing](https://quarto.org/docs/publishing/github-pages.html) - Quarto GitHub Pages guide

---

**Last Updated:** 2026-02-04
**Version:** v6.4.1
