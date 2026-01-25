# Teaching Quarto Workflow Guide

**Version:** 4.6.0 (Phase 1 - Validation, Caching, Deployment)
**Last Updated:** 2026-01-20
**Status:** Production Ready

---

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Complete Workflows](#complete-workflows)
- [Validation System](#validation-system)
- [Cache Management](#cache-management)
- [Deployment Workflows](#deployment-workflows)
- [Index Management](#index-management)
- [Hook System](#hook-system)
- [Backup & Restore](#backup--restore)
- [Health Checks](#health-checks)
- [Performance Optimization](#performance-optimization)
- [Common Recipes](#common-recipes)
- [Troubleshooting](#troubleshooting)

---

## Overview

The Teaching Quarto Workflow provides a comprehensive, ADHD-friendly system for managing course content with Quarto. Phase 1 introduces validation, caching, partial deployments, index management, and automated git hooks.

### What Phase 1 Delivers

| Feature | Commands | Purpose |
|---------|----------|---------|
| **Granular Validation** | `teach validate` | Layer-based validation (YAML → Syntax → Render) |
| **Cache Management** | `teach cache` | Interactive freeze cache control |
| **Enhanced Deployment** | `teach deploy` | Partial deployments with dependencies |
| **Index Management** | Auto-prompts | ADD/UPDATE/REMOVE links in index files |
| **Git Hooks** | `teach hooks` | Pre-commit, pre-push validation |
| **Backup System** | Auto-backups | Timestamped snapshots with retention |
| **Health Checks** | `teach doctor` | Environment validation |
| **Enhanced Status** | `teach status` | Comprehensive dashboard |

### Why This Matters (ADHD-Friendly Design)

**Problem:** Traditional Quarto workflows force "all-or-nothing" rendering that takes 15+ minutes for large courses.

**Solution:** Granular control lets you validate and deploy just what changed.

- **Fast validation** (YAML only): < 1 second
- **Partial deploys**: Deploy single lectures without full site build
- **Dependency tracking**: Automatically includes referenced files
- **Interactive prompts**: Never forget to update index files
- **Automated backups**: Safety net for content changes

---

## Quick Start

### 1. Setup Project

```bash
# Create and initialize project
mkdir stat-440 && cd stat-440
teach init --course "STAT 440" --semester "Spring 2026"

# Install git hooks
teach hooks install
```

### 2. Health Check

```bash
# Verify environment
teach doctor

# Sample output:
# ✓ yq (4.35.1)
# ✓ git (2.43.0)
# ✓ quarto (1.4.550)
# ✓ .flow/teach-config.yml exists
# ✓ Git repository initialized
# ✓ Pre-commit hook installed (v1.0.0)
```

### 3. Create Content

```bash
# Generate lecture using Scholar
teach lecture "Linear Regression" --week 5

# Validate YAML (fast check)
teach validate --yaml lectures/week-05-linear-regression.qmd

# Full validation (YAML + Syntax + Render)
teach validate lectures/week-05-linear-regression.qmd
```

### 4. Partial Deploy

```bash
# Deploy single lecture with dependencies
teach deploy lectures/week-05-linear-regression.qmd --auto-commit

# System will:
# 1. Find cross-references and sourced files
# 2. Prompt to include dependencies
# 3. Check for index changes (ADD/UPDATE/REMOVE)
# 4. Create backup
# 5. Push to draft branch
# 6. Create PR to production
```

### 5. View Status

```bash
teach status

# Output:
# ┌─────────────────────────────────────────────────────────────────┐
# │              STAT 440 - Spring 2026                             │
# ├─────────────────────────────────────────────────────────────────┤
# │  📁 Project:      ~/teaching/stat-440                           │
# │  🔧 Quarto:       Freeze ✓ (71MB, 342 files)                    │
# │  🎣 Hooks:        Pre-commit ✓ (v1.0.0), Pre-push ✓ (v1.0.0)   │
# │  🚀 Deployments:  Last 2 hours ago (deploy-2026-01-20-1430)    │
# │  📚 Index:        12 lectures, 8 assignments linked             │
# │  💾 Backups:      23 backups (156MB)                            │
# └─────────────────────────────────────────────────────────────────┘
```

---

## Architecture

### Validation Layers (Pyramid Model)

```
                    ┌─────────────────┐
                    │  Layer 5        │
                    │  Images         │  Check missing images
                    │  (warnings)     │  ~100ms per file
                    ├─────────────────┤
                ┌───┤  Layer 4        │
                │   │  Empty Chunks   │  Detect empty code blocks
                │   │  (warnings)     │  ~50ms per file
                │   ├─────────────────┤
            ┌───┤   │  Layer 3        │
            │   │   │  Render         │  Full quarto render
            │   │   │  (3-15s)        │  Slowest, most thorough
            │   │   ├─────────────────┤
        ┌───┤   │   │  Layer 2        │
        │   │   │   │  Syntax         │  quarto inspect
        │   │   │   │  (~500ms)       │  Structure validation
        │   │   │   ├─────────────────┤
    ┌───┤   │   │   │  Layer 1        │
    │   │   │   │   │  YAML           │  yq validation
    │   │   │   │   │  (~100ms)       │  Fastest check
    └───┴───┴───┴───┴─────────────────┘
```

**Strategy:**
- Use **YAML-only** for quick pre-commit checks
- Use **Syntax** during active development
- Use **Render** before deployment
- Use **Full** (all layers) for comprehensive validation

### File Structure

```
stat-440/
├── .flow/
│   ├── teach-config.yml          # Project configuration
│   └── archives/                 # Semester archives
│       └── Fall-2025/
├── .teach/
│   ├── validation-status.json    # Validation cache
│   └── last-change-*.timestamp   # Debounce tracking
├── _freeze/                       # Quarto freeze cache
│   ├── lectures/
│   └── assignments/
├── lectures/
│   ├── week-01-intro.qmd
│   ├── week-02-regression.qmd
│   └── .backups/                 # Auto-created backups
│       ├── week-01-intro.2026-01-20-1030/
│       └── week-01-intro.2026-01-20-1445/
├── assignments/
├── exams/
├── home_lectures.qmd             # Index files (auto-managed)
├── home_assignments.qmd
└── .git/hooks/
    ├── pre-commit                # YAML + Syntax validation
    ├── pre-push                  # Full validation
    └── prepare-commit-msg        # Add timing metadata
```

---

## Complete Workflows

### Workflow 1: New Lecture Creation

```bash
# 1. Generate lecture from template
teach lecture "Multiple Linear Regression" --week 7

# File created: lectures/week-07-multiple-linear-regression.qmd

# 2. Edit in VS Code or RStudio
code lectures/week-07-multiple-linear-regression.qmd

# 3. Quick YAML validation (while editing)
teach validate --yaml lectures/week-07-multiple-linear-regression.qmd
# ✓ YAML valid: lectures/week-07-multiple-linear-regression.qmd

# 4. Syntax check (before render)
teach validate --syntax lectures/week-07-multiple-linear-regression.qmd
# ✓ YAML valid: lectures/week-07-multiple-linear-regression.qmd
# ✓ Syntax valid: lectures/week-07-multiple-linear-regression.qmd

# 5. Full validation (before commit)
teach validate --render lectures/week-07-multiple-linear-regression.qmd
# ✓ YAML valid
# ✓ Syntax valid
# ✓ Render valid: lectures/week-07-multiple-linear-regression.qmd (4s)

# 6. Commit (pre-commit hook runs automatically)
git add lectures/week-07-multiple-linear-regression.qmd
git commit -m "Add Week 7: Multiple Linear Regression lecture"

# Pre-commit hook output:
# Validating 1 staged .qmd file(s)...
# ✓ lectures/week-07-multiple-linear-regression.qmd (782ms)
# All 1 files passed validation (782ms)

# 7. Deploy to draft branch
teach deploy lectures/week-07-multiple-linear-regression.qmd
```

**What Happens During Deploy:**

1. **Dependency Detection:**

   ```
   🔍 Finding dependencies...
     Dependencies for lectures/week-07-multiple-linear-regression.qmd:
       • lectures/week-06-simple-regression.qmd (cross-reference @sec-simple-model)
       • scripts/regression-helpers.R (sourced)

   Found 2 additional dependencies
   Include dependencies in deployment? [Y/n]: y
   ```

2. **Index Management:**

   ```
   📄 New content detected:
     week-07-multiple-linear-regression.qmd: Multiple Linear Regression

   Add to index file? [Y/n]: y
   ✓ Added link to home_lectures.qmd
   ```

3. **Backup Creation:**

   ```
   💾 Creating backup...
   ✓ Backup created: lectures/.backups/week-07-multiple-linear-regression.2026-01-20-1534/
   ```

4. **Push & PR:**

   ```
   Push to origin/draft? [Y/n]: y
   ✓ Pushed to origin/draft

   Create pull request? [Y/n]: y
   ✅ Pull Request Created

   View at: https://github.com/user/stat-440/pull/42
   ```

### Workflow 2: Bulk Content Updates

```bash
# Scenario: Update all Week 1-5 lectures with new branding

# 1. Make changes to lectures/week-0{1..5}*.qmd files in editor

# 2. Validate all changed files
teach validate lectures/week-01*.qmd lectures/week-02*.qmd \
              lectures/week-03*.qmd lectures/week-04*.qmd \
              lectures/week-05*.qmd --syntax

# 3. Deploy multiple files at once
teach deploy lectures/week-0{1..5}*.qmd --auto-commit --auto-tag

# System will:
# - Find dependencies for all 5 files
# - Check for title changes (UPDATE prompts)
# - Auto-commit with message "Update: 2026-01-20"
# - Create tag: deploy-2026-01-20-1545
# - Create PR with all changes
```

### Workflow 3: Watch Mode Development

```bash
# Start watch mode for active development
teach validate --watch lectures/week-08-diagnostics.qmd

# Output:
# Starting watch mode for 1 file(s)...
# Running initial validation...
# ✓ lectures/week-08-diagnostics.qmd (1.2s)
#
# Watching for changes...

# Now edit the file in your editor
# On save, automatic validation:

# File changed: lectures/week-08-diagnostics.qmd
# Validating...
# ✓ Validation passed (523ms)
#
# Watching for changes...
```

**Watch Mode Features:**
- **Debounced**: Waits 500ms for additional changes
- **Conflict detection**: Skips if `quarto preview` is running
- **Fast validation**: YAML + Syntax only (no render)
- **Status tracking**: Updates `.teach/validation-status.json`

### Workflow 4: Cache Management

```bash
# Interactive cache menu
teach cache

# ┌─────────────────────────────────────────────────────────────┐
# │ Freeze Cache Management                                     │
# ├─────────────────────────────────────────────────────────────┤
# │ Cache: 71MB (342 files)                                     │
# │ Last render: 2 hours ago                                    │
# │                                                             │
# │ 1. View cache details                                       │
# │ 2. Clear cache (delete _freeze/)                            │
# │ 3. Rebuild cache (force re-render)                          │
# │ 4. Clean all (delete _freeze/ + _site/)                     │
# │ 5. Exit                                                     │
# │                                                             │
# │ Choice: _                                                   │
# └─────────────────────────────────────────────────────────────┘

# Choice: 1 (View details)

# ╭─ Freeze Cache Analysis ────────────────────────────╮
# │
# │ Overall:
# │   Total size:  71MB
# │   Files:       342
# │   Last render: 2 hours ago
# │
# │ By Content Directory:
# │
# │   lectures                       45MB     (187 files)
# │   assignments                    18MB     (98 files)
# │   exams                          8MB      (57 files)
# │
# │ By Age:
# │
# │   Last hour:       23 files
# │   Last day:       156 files
# │   Last week:      163 files
# │   Older:            0 files
# │
# ╰────────────────────────────────────────────────────╯

# Non-interactive cache operations
teach cache status              # Quick size check
teach cache clear --force       # Clear without confirmation
teach cache rebuild             # Clear + render
teach clean --force             # Delete _freeze + _site
```

---

## Validation System

### Validation Layers Explained

#### Layer 1: YAML Frontmatter (~100ms)

**What it checks:**
- YAML syntax validity
- Proper delimiter markers (`---`)
- Non-empty frontmatter

**When to use:**
- Quick pre-commit checks
- While actively editing
- Watch mode

**Example:**

```bash
teach validate --yaml lectures/week-01.qmd

# ✓ YAML valid: lectures/week-01.qmd
```

**Common errors:**

```yaml
---
title: "Week 1: Introduction
author: "Dr. Smith"  # Missing closing quote on title
date: 2026-01-20
---
```

#### Layer 2: Quarto Syntax (~500ms)

**What it checks:**
- Quarto document structure
- Code chunk syntax
- Shortcode validity
- Cross-reference format

**When to use:**
- Before rendering
- After adding complex code chunks
- Before deployment

**Example:**

```bash
teach validate --syntax lectures/week-02.qmd

# ✓ YAML valid: lectures/week-02.qmd
# ✓ Syntax valid: lectures/week-02.qmd
```

**Common errors:**

```markdown
```{r}
#| label: fig-plot
#| echo false  # Missing colon after 'echo'

plot(mtcars)
```

```

#### Layer 3: Full Render (3-15s)

**What it checks:**
- Code execution
- Package availability
- Data file accessibility
- Image generation
- Cross-references resolution

**When to use:**
- Before deployment
- Final validation
- Troubleshooting render errors

**Example:**
```bash
teach validate --render lectures/week-03.qmd

# ✓ YAML valid: lectures/week-03.qmd
# ✓ Syntax valid: lectures/week-03.qmd
# ✓ Render valid: lectures/week-03.qmd (8s)
```

**Common errors:**

```r
# File not found
data <- read.csv("../data/regression-data.csv")  # Wrong path

# Package not installed
library(nonexistent_package)

# Undefined variable
model <- lm(y ~ x1 + x2 + missing_var, data = df)
```

#### Layer 4: Empty Code Chunks (warnings)

**What it checks:**
- Code chunks with no content
- Chunks with only whitespace

**Why it matters:**
- Indicates incomplete content
- May confuse students

**Example:**

```markdown
```{r}
#| label: setup
#| include: false

# Empty chunk - triggers warning

```

```

#### Layer 5: Missing Images (warnings)

**What it checks:**
- `![](path/to/image.png)` references
- Relative and absolute paths
- Skips external URLs

**Why it matters:**
- Broken image links
- Missing figures

**Example:**
```markdown
![Regression plot](figures/regression.png)
# Warning if figures/regression.png doesn't exist
```

### Validation Strategies

#### Strategy 1: Iterative Development

```bash
# Rapid iteration during content creation
while editing:
  save file
  teach validate --yaml file.qmd     # < 1s
  if errors: fix and repeat

# When section complete:
teach validate --syntax file.qmd     # ~500ms

# When entire lecture complete:
teach validate --render file.qmd     # 3-15s
```

#### Strategy 2: Pre-Commit Safety

```bash
# Automatic validation via git hooks
git add lectures/week-04.qmd
git commit -m "Add week 4 lecture"

# Pre-commit hook runs:
# - YAML validation (fast)
# - Syntax validation (medium)
# - Skips render (too slow for commits)

# If validation fails, commit is blocked
```

#### Strategy 3: CI/CD Integration

```bash
# Use JSON output for automation
teach doctor --json > health-check.json
teach validate --render --quiet --json > validation-results.json

# Parse results in CI script:
if jq '.summary.failures' validation-results.json | grep -q '0'; then
  echo "All validations passed"
else
  echo "Validation failures detected"
  exit 1
fi
```

### Watch Mode Usage

**Start watch mode:**

```bash
teach validate --watch lectures/*.qmd
```

**What happens:**
1. Initial validation runs
2. File watcher starts (fswatch on macOS, inotifywait on Linux)
3. On file save:
   - Debounce 500ms (wait for more changes)
   - Check if `quarto preview` running (skip if yes)
   - Run YAML + Syntax validation (fast)
   - Update `.teach/validation-status.json`
   - Show results

**Conflict prevention:**

```
# If quarto preview is running:
⚠️ Quarto preview is running - validation may conflict
Consider using separate terminal for validation

Continue anyway? [y/N]:
```

**Why this matters:** Quarto preview locks files and may conflict with validation.

---

## Cache Management

### Understanding Freeze Cache

Quarto's `freeze: auto` feature caches computation results to avoid re-running expensive code on every render.

**How it works:**
1. First render: Executes all code chunks, stores results in `_freeze/`
2. Subsequent renders: Reuses cached results unless source changed
3. Detects changes: MD5 hash of source code

**Benefits:**
- **Speed**: 30s render vs 15min full execution
- **Consistency**: Same results across renders
- **Incremental**: Only re-runs changed chunks

**Tradeoffs:**
- **Disk space**: Cache can grow to 100s of MB
- **Staleness**: May miss external data changes
- **Debugging**: Cached results hide execution errors

### When to Clear Cache

| Scenario | Reason | Command |
|----------|--------|---------|
| **Code changes not reflecting** | Stale cache | `teach cache clear` |
| **External data updated** | Cache doesn't detect data changes | `teach cache rebuild` |
| **Before final render** | Ensure fresh results | `teach cache rebuild` |
| **Low disk space** | Cache consuming space | `teach cache clear` |
| **After major refactor** | Multiple files changed | `teach cache rebuild` |
| **Debugging render issues** | Rule out cache problems | `teach cache clear` |

### Cache Operations

#### View Cache Status

```bash
teach cache status

# Output:
# Freeze Cache Status
#
#   Location:     /Users/dt/stat-440/_freeze
#   Size:         71MB
#   Files:        342
#   Last render:  2 hours ago
```

#### Detailed Analysis

```bash
teach cache analyze

# ╭─ Freeze Cache Analysis ────────────────────────────╮
# │
# │ Overall:
# │   Total size:  71MB
# │   Files:       342
# │   Last render: 2 hours ago
# │
# │ By Content Directory:
# │
# │   lectures                       45MB     (187 files)
# │   assignments                    18MB     (98 files)
# │   exams                          8MB      (57 files)
# │
# │ By Age:
# │
# │   Last hour:       23 files
# │   Last day:       156 files
# │   Last week:      163 files
# │   Older:            0 files
# │
# ╰────────────────────────────────────────────────────╯
```

**Interpretation:**
- **Last hour**: Recently rendered (likely current work)
- **Last day**: Active content
- **Last week**: Less frequently changed
- **Older**: Consider checking if still needed

#### Clear Cache (Interactive)

```bash
teach cache clear

# Cache to be deleted:
#   Location:   /Users/dt/stat-440/_freeze
#   Size:       71MB
#   Files:      342
#
# Delete freeze cache? [y/N]: y
#
# ✓ Freeze cache cleared (71MB freed)
```

#### Clear Cache (Force)

```bash
teach cache clear --force

# ✓ Freeze cache cleared (71MB freed)
```

#### Rebuild Cache

```bash
teach cache rebuild

# Rebuilding freeze cache...
#
# ✓ Freeze cache cleared (71MB freed)
#
# Re-rendering all content...
# Rendering Quarto project (~30-60s)
# ████████████████████ 100%
#
# ✓ Cache rebuilt successfully
#
# New cache: 73MB (348 files)
```

**When rebuilding:**
- All code chunks execute from scratch
- Fresh computation results
- Longer than normal render
- New cache may be slightly different size

#### Clean All (Freeze + Site)

```bash
teach clean

# Directories to be deleted:
#   _freeze/ (71MB)
#   _site/ (23MB)
#
#   Total files: 512
#
# Delete all build artifacts? [y/N]: y
#
# ✓ Deleted _freeze/
# ✓ Deleted _site/
#
# ✓ Clean complete (2 directories deleted)
```

**Use cases:**
- Fresh start before deployment
- Disk space cleanup
- Troubleshooting mysterious issues

### Interactive Cache Menu

```bash
teach cache

# Opens TUI menu with real-time status updates
# Navigate with number keys (1-5)
# Auto-refreshes cache info on each loop
```

---

## Deployment Workflows

### Full Site Deployment

**Traditional workflow** (pre-Phase 1):

```bash
# 1. Commit all changes
git add .
git commit -m "Update all lectures"

# 2. Push to draft
git push origin draft

# 3. Create PR manually on GitHub
# 4. Review and merge
# 5. Deploy via GitHub Actions
```

**Enhanced workflow** (Phase 1):

```bash
teach deploy

# 🔍 Pre-flight Checks
# ─────────────────────────────────────────────────
# ✓ On draft branch
# ✓ No uncommitted changes
# ✓ Remote is up-to-date
# ✓ No conflicts with production
#
# 📋 Changes Preview
# ─────────────────────────────────────────────────
#
# Files Changed:
#   M  lectures/week-01-intro.qmd
#   M  lectures/week-02-regression.qmd
#   A  lectures/week-03-diagnostics.qmd
#   M  home_lectures.qmd
#
# Summary: 4 files (1 added, 3 modified, 0 deleted)
#
# Create pull request?
#
#   [1] Yes - Create PR (Recommended)
#   [2] Push to draft only (no PR)
#   [3] Cancel
#
# Your choice [1-3]: 1
#
# ✅ Pull Request Created
#
# View at: https://github.com/user/stat-440/pull/43
```

### Partial Deployment

**Why partial deployments?**
- **Speed**: Deploy one lecture without rendering entire site
- **Granularity**: Update specific content
- **Dependencies**: Automatic inclusion of referenced files
- **Index management**: Prompts for index updates

#### Single File Deployment

```bash
teach deploy lectures/week-05-mlr.qmd

# 📦 Partial Deploy Mode
# ─────────────────────────────────────────────────
#
# Files to deploy:
#   • lectures/week-05-mlr.qmd
#
# 🔗 Validating cross-references...
# ✓ All cross-references valid
#
# 🔍 Finding dependencies...
#   Dependencies for lectures/week-05-mlr.qmd:
#     • lectures/week-04-slr.qmd
#     • scripts/regression-utils.R
#
# Found 2 additional dependencies
# Include dependencies in deployment? [Y/n]: y
#
# 🔍 Checking index files...
#
# 📄 New content detected:
#   week-05-mlr.qmd: Multiple Linear Regression
#
# Add to index file? [Y/n]: y
# ✓ Added link to home_lectures.qmd
#
# Push to origin/draft? [Y/n]: y
# ✓ Pushed to origin/draft
#
# Create pull request? [Y/n]: y
# ✅ Pull Request Created
```

#### Multiple File Deployment

```bash
teach deploy lectures/week-05*.qmd lectures/week-06*.qmd

# 📦 Partial Deploy Mode
# ─────────────────────────────────────────────────
#
# Files to deploy:
#   • lectures/week-05-mlr.qmd
#   • lectures/week-06-inference.qmd
#
# (continues with dependency detection, etc.)
```

#### Directory Deployment

```bash
teach deploy lectures/

# Deploys all .qmd files in lectures/ directory
# Includes dependency tracking and index management
```

### Auto-Commit Mode

```bash
teach deploy lectures/week-07.qmd --auto-commit

# ⚠️  Uncommitted changes detected
#
#   • lectures/week-07.qmd
#
# Auto-commit mode enabled
# ✓ Auto-committed changes
#
# Commit message: Update: 2026-01-20
```

**Custom commit message:**

```bash
# Without --auto-commit, you'll be prompted:

# ⚠️  Uncommitted changes detected
#
#   • lectures/week-07.qmd
#
# Commit message (or Enter for auto): Add example problems
#
# ✓ Committed changes
```

### Auto-Tag Mode

```bash
teach deploy lectures/week-08.qmd --auto-commit --auto-tag

# Creates git tag: deploy-2026-01-20-1545
# Pushes tag to remote
# Useful for tracking deployments
```

**List deployment tags:**

```bash
git tag -l "deploy-*" --sort=-version:refname

# deploy-2026-01-20-1545
# deploy-2026-01-19-0930
# deploy-2026-01-18-1420
```

### Skip Index Management

```bash
teach deploy lectures/week-09.qmd --skip-index

# Skips prompts for ADD/UPDATE/REMOVE
# Useful when you've already managed index files manually
```

---

## Index Management

### What Are Index Files?

Index files (`home_lectures.qmd`, `home_assignments.qmd`, etc.) provide navigation for students.

**Example index file:**

```markdown
---
title: "Lectures"
---

## Course Lectures

- [Week 1: Introduction](lectures/week-01-intro.qmd)
- [Week 2: Simple Linear Regression](lectures/week-02-slr.qmd)
- [Week 3: Multiple Linear Regression](lectures/week-03-mlr.qmd)
```

### Automatic Detection

During deployment, the system detects:

1. **ADD**: New file not in index
2. **UPDATE**: Existing file with changed title
3. **REMOVE**: Deleted file still in index

### ADD Operation

```bash
# You create: lectures/week-04-diagnostics.qmd
# Title in YAML: "Regression Diagnostics"

teach deploy lectures/week-04-diagnostics.qmd

# 📄 New content detected:
#   week-04-diagnostics.qmd: Regression Diagnostics
#
# Add to index file? [Y/n]: y
# ✓ Added link to home_lectures.qmd
```

**Result in `home_lectures.qmd`:**

```markdown
- [Week 1: Introduction](lectures/week-01-intro.qmd)
- [Week 2: Simple Linear Regression](lectures/week-02-slr.qmd)
- [Week 3: Multiple Linear Regression](lectures/week-03-mlr.qmd)
- [Week 4: Regression Diagnostics](lectures/week-04-diagnostics.qmd)  ← Added
```

**Auto-sorting:**
Links are inserted in week-number order based on filename pattern:
- `week-05.qmd` → sorts by 5
- `05-topic.qmd` → sorts by 5
- `lecture-week05.qmd` → sorts by 5

### UPDATE Operation

```bash
# You change title in lectures/week-03-mlr.qmd
# Old: "Multiple Linear Regression"
# New: "Multiple Regression and Interactions"

teach deploy lectures/week-03-mlr.qmd

# 📝 Title changed:
#   Old: Multiple Linear Regression
#   New: Multiple Regression and Interactions
#
# Update index link? [y/N]: y
# ✓ Updated link in home_lectures.qmd
```

### REMOVE Operation

```bash
# You delete lectures/week-02-slr.qmd

teach deploy

# 🗑  Content deleted:
#   week-02-slr.qmd
#
# Remove from index? [Y/n]: y
# ✓ Removed link from home_lectures.qmd
```

### Manual Index Management

If you prefer to manage index files manually:

```bash
# Skip index prompts
teach deploy lectures/week-05.qmd --skip-index
```

Or edit `home_lectures.qmd` directly and commit:

```bash
# Edit index file
code home_lectures.qmd

# Commit index changes
git add home_lectures.qmd
git commit -m "Update lecture index"
```

---

## Hook System

### Available Hooks

| Hook | Trigger | Validation | Speed |
|------|---------|------------|-------|
| `pre-commit` | Before commit | YAML + Syntax | Fast (~1s) |
| `pre-push` | Before push | Full render | Slow (3-15s per file) |
| `prepare-commit-msg` | During commit | None | Instant |

### Install Hooks

```bash
teach hooks install

# Installing git hooks for Quarto workflow...
#
# ✓ Installed pre-commit (v1.0.0)
# ✓ Installed pre-push (v1.0.0)
# ✓ Installed prepare-commit-msg (v1.0.0)
#
# ✓ All hooks installed successfully (3 hooks)
#
# Configuration options:
#   QUARTO_PRE_COMMIT_RENDER=1    # Enable full rendering on commit
#   QUARTO_PARALLEL_RENDER=1      # Enable parallel rendering (default: on)
#   QUARTO_MAX_PARALLEL=4         # Max parallel jobs (default: 4)
#   QUARTO_COMMIT_TIMING=1        # Add timing to commit messages (default: on)
#   QUARTO_COMMIT_SUMMARY=1       # Add validation summary to commits
```

### Check Hook Status

```bash
teach hooks status

# Hook status:
#
# ✓ pre-commit: v1.0.0 (up to date)
# ✓ pre-push: v1.0.0 (up to date)
# ✓ prepare-commit-msg: v1.0.0 (up to date)
#
# Summary: 3 up to date, 0 outdated, 0 missing
```

### Upgrade Hooks

```bash
teach hooks upgrade

# Checking for hook upgrades...
#
# Hooks to upgrade: 2
#    - pre-commit (v0.9.0 → v1.0.0)
#    - pre-push (v0.9.0 → v1.0.0)
#
# Upgrade these hooks? [Y/n]: y
#
# ✓ Installed pre-commit (v1.0.0)
# ✓ Installed pre-push (v1.0.0)
#
# ✓ All hooks upgraded successfully (2 hooks)
```

### Uninstall Hooks

```bash
teach hooks uninstall

# ⚠ This will remove all flow-cli managed hooks
# Continue? [y/N]: y
#
# ✓ Removed pre-commit
# ✓ Removed pre-push
# ✓ Removed prepare-commit-msg
#
# ✓ Uninstalled 3 hook(s)
```

### Hook Behavior

#### Pre-Commit Hook

**Runs automatically on:**

```bash
git commit -m "message"
```

**What it does:**
1. Find all staged `.qmd` files
2. Run YAML validation (fast)
3. Run Syntax validation (medium)
4. Block commit if validation fails

**Example output:**

```bash
git commit -m "Update week 5 lecture"

# Validating 1 staged .qmd file(s)...
# ✓ lectures/week-05-mlr.qmd (782ms)
# All 1 files passed validation (782ms)
#
# [draft 7f3a8b2] Update week 5 lecture
#  1 file changed, 42 insertions(+), 18 deletions(-)
```

**If validation fails:**

```bash
git commit -m "Update week 5 lecture"

# Validating 1 staged .qmd file(s)...
# ✗ lectures/week-05-mlr.qmd
# Error: Invalid YAML syntax
#
# 1/1 files failed validation
#
# Commit aborted. Fix errors and try again.
```

#### Pre-Push Hook

**Runs automatically on:**

```bash
git push origin draft
```

**What it does:**
1. Find all `.qmd` files changed since last push
2. Run full render validation (slow but thorough)
3. Block push if validation fails

**Example output:**

```bash
git push origin draft

# Validating 3 .qmd file(s) before push...
# ✓ lectures/week-05-mlr.qmd (4s)
# ✓ lectures/week-06-inference.qmd (6s)
# ✓ lectures/week-07-anova.qmd (5s)
#
# All 3 files passed validation (15s)
#
# Enumerating objects: 12, done.
# Counting objects: 100% (12/12), done.
# ...
```

#### Prepare-Commit-Msg Hook

**Runs automatically on:**

```bash
git commit
```

**What it does:**
1. Adds validation timing to commit message
2. Adds file count summary

**Example commit message:**

```
Update week 5 lecture

Validated: 1 file(s) in 782ms
```

### Configuration Options

Set environment variables to customize hook behavior:

```bash
# In ~/.zshrc or ~/.bashrc

# Enable full render on commit (default: off)
export QUARTO_PRE_COMMIT_RENDER=1

# Disable parallel rendering (default: on)
export QUARTO_PARALLEL_RENDER=0

# Change max parallel jobs (default: 4)
export QUARTO_MAX_PARALLEL=8

# Disable commit timing (default: on)
export QUARTO_COMMIT_TIMING=0

# Enable validation summary in commit (default: off)
export QUARTO_COMMIT_SUMMARY=1
```

### Bypass Hooks (Emergency)

```bash
# Skip all hooks
git commit --no-verify -m "Emergency fix"
git push --no-verify origin draft
```

**Warning:** Only use when absolutely necessary.

---

## Backup & Restore

### Automatic Backups

Backups are created automatically during:
- Content modification via Scholar commands
- Deployment operations
- Manual edits followed by deploy

**Backup location:**

```
lectures/
├── week-05-mlr.qmd
└── .backups/
    ├── week-05-mlr.2026-01-20-1030/
    │   └── (full snapshot)
    ├── week-05-mlr.2026-01-20-1445/
    └── week-05-mlr.2026-01-20-1730/
```

### Retention Policies

Configured in `.flow/teach-config.yml`:

```yaml
backups:
  retention:
    assessments: "archive"    # exams, quizzes, assignments
    syllabi: "archive"        # syllabi, rubrics
    lectures: "semester"      # lectures, slides
  archive_dir: ".flow/archives"
```

| Policy | Meaning | Applies To |
|--------|---------|------------|
| `archive` | Keep all backups forever | Exams, quizzes, assignments, syllabi |
| `semester` | Delete at semester end | Lectures, slides |

**Why different policies?**
- **Assessments**: Legal/accreditation requirements
- **Syllabi**: Historical record
- **Lectures**: Less critical, can be regenerated

### List Backups

```bash
# Via teach status
teach status

# Output includes:
# 💾 Backups:      23 backups (156MB)
```

**Detailed view:**

```bash
# Find backups for specific content
ls lectures/.backups/

# week-05-mlr.2026-01-20-1030/
# week-05-mlr.2026-01-20-1445/
# week-05-mlr.2026-01-20-1730/
```

### Restore Backup

```bash
# Manual restore
cp -R lectures/.backups/week-05-mlr.2026-01-20-1030/* lectures/week-05-mlr.qmd
```

**Or use git:**

```bash
# If you've committed since backup
git log --oneline lectures/week-05-mlr.qmd

# 7f3a8b2 Update week 5 lecture (most recent)
# 4c2e1a9 Add week 5 lecture
# 2b8f6d3 Initial import

# Restore to previous version
git checkout 4c2e1a9 -- lectures/week-05-mlr.qmd
```

### Archive Semester

At end of semester:

```bash
teach archive Fall-2025

# Creates: .flow/archives/Fall-2025/
#
# Archived:
#   - exams/midterm/.backups/ (archive policy)
#   - exams/final/.backups/ (archive policy)
#   - assignments/*/.backups/ (archive policy)
#
# Deleted:
#   - lectures/*/.backups/ (semester policy)
#   - slides/*/.backups/ (semester policy)
```

**Archive structure:**

```
.flow/archives/
└── Fall-2025/
    ├── midterm-backups/
    ├── final-backups/
    ├── assignment-01-backups/
    ├── assignment-02-backups/
    └── ...
```

---

## Health Checks

### Basic Health Check

```bash
teach doctor

# ╭────────────────────────────────────────────────────────────╮
# │  📚 Teaching Environment Health Check                       │
# ╰────────────────────────────────────────────────────────────╯
#
# Dependencies:
#   ✓ yq (4.35.1)
#   ✓ git (2.43.0)
#   ✓ quarto (1.4.550)
#   ✓ gh (2.40.1)
#   ✓ examark (0.6.6)
#   ⚠ claude (not found - optional)
#
# Project Configuration:
#   ✓ .flow/teach-config.yml exists
#   ✓ Config validates against schema
#   ✓ Course name: STAT 440
#   ✓ Semester: Spring 2026
#   ✓ Dates configured (2026-01-15 - 2026-05-08)
#
# Git Setup:
#   ✓ Git repository initialized
#   ✓ Draft branch exists
#   ✓ Production branch exists: main
#   ✓ Remote configured: origin
#   ⚠ 3 uncommitted changes
#
# Scholar Integration:
#   ⚠ Claude Code not found
#   ⚠ Scholar skills not detected
#   ✓ Lesson plan found: lesson-plan.yml
#
# Git Hooks:
#   ✓ Hook installed: pre-commit (flow-cli managed)
#   ✓ Hook installed: pre-push (flow-cli managed)
#   ✓ Hook installed: prepare-commit-msg (flow-cli managed)
#
# Cache Health:
#   ✓ Freeze cache exists (71MB)
#   ✓ Cache is recent (2 days old)
#       → 342 cached files
#
# ────────────────────────────────────────────────────────────
# Summary: 18 passed, 4 warnings, 0 failures
# ────────────────────────────────────────────────────────────
```

### Quiet Mode

```bash
teach doctor --quiet

# Only shows warnings and failures
#
# ⚠ 3 uncommitted changes
#   → Run: git status
# ⚠ Claude Code not found
#   → Install: https://code.claude.com
```

### Interactive Fix Mode

```bash
teach doctor --fix

# Dependencies:
#   ✓ yq (4.35.1)
#   ✓ git (2.43.0)
#   ✓ quarto (1.4.550)
#   ✓ gh (2.40.1)
#   ✗ examark (not found)
#       → Install examark? [Y/n]: y
#       → npm install -g examark
#       ✓ examark installed
```

### JSON Output (CI/CD)

```bash
teach doctor --json

{
  "summary": {
    "passed": 18,
    "warnings": 4,
    "failures": 0,
    "status": "healthy"
  },
  "checks": [
    {"check":"dep_yq","status":"pass","message":"4.35.1"},
    {"check":"dep_git","status":"pass","message":"2.43.0"},
    {"check":"dep_quarto","status":"pass","message":"1.4.550"},
    {"check":"config_exists","status":"pass","message":"exists"},
    {"check":"course_name","status":"pass","message":"STAT 440"},
    ...
  ]
}
```

**Use in CI:**

```bash
#!/bin/bash
# .github/workflows/health-check.yml

teach doctor --json > health.json

# Check status
STATUS=$(jq -r '.summary.status' health.json)

if [[ "$STATUS" != "healthy" ]]; then
  echo "Health check failed"
  exit 1
fi
```

---

## Performance Optimization

### Validation Performance

| Layer | Time per File | Strategy |
|-------|---------------|----------|
| YAML | ~100ms | Use during editing |
| Syntax | ~500ms | Use before commits |
| Render | 3-15s | Use before deployment |
| Full | ~15s | Use for critical checks |

**Optimization tips:**

1. **Use appropriate layers:**

   ```bash
   # During active editing (fast)
   teach validate --yaml

   # Before commit (medium)
   teach validate --syntax

   # Before deploy (slow but thorough)
   teach validate --render
   ```

2. **Validate changed files only:**

   ```bash
   # Instead of all files
   teach validate

   # Validate only staged files
   git diff --cached --name-only --diff-filter=ACM | \
     grep '\.qmd$' | \
     xargs teach validate --syntax
   ```

3. **Use watch mode efficiently:**

   ```bash
   # Watch only active file
   teach validate --watch lectures/week-05.qmd

   # Not entire directory
   teach validate --watch lectures/*.qmd  # Slower
   ```

### Cache Performance

**Freeze cache benefits:**
- **First render:** 15 minutes (full execution)
- **Cached render:** 30 seconds (no execution)
- **Speedup:** ~30x

**Optimization:**

```yaml
# _quarto.yml

execute:
  freeze: auto        # Cache by default
  cache: true         # Additional caching layer
  keep-md: true       # Keep intermediate files (faster re-renders)
```

**Selective freeze:**

```yaml
# In frontmatter of expensive lectures
---
title: "Week 8: Advanced Models"
execute:
  freeze: true        # Always freeze this file
---
```

### Deployment Performance

**Full site deployment:**
- **Time:** 2-5 minutes (all content)
- **When:** Major releases, semester start

**Partial deployment:**
- **Time:** 10-30 seconds (single file)
- **When:** Individual lecture updates

**Optimization:**

```bash
# Deploy only what changed
teach deploy lectures/week-05.qmd

# Not full site
teach deploy  # Slower
```

### Parallel Rendering

**Enable in hooks:**

```bash
export QUARTO_PARALLEL_RENDER=1
export QUARTO_MAX_PARALLEL=8  # Adjust based on CPU cores
```

**Performance:**
- **4 cores:** ~4x speedup
- **8 cores:** ~6x speedup (diminishing returns)

**Trade-offs:**
- Higher memory usage
- May interfere with other work

---

## Common Recipes

### Recipe 1: Weekly Lecture Workflow

```bash
# Monday: Create next week's lecture
teach lecture "ANOVA" --week 8
teach validate --yaml lectures/week-08-anova.qmd

# Tuesday-Thursday: Develop content
# (Edit in VS Code, save frequently)
teach validate --watch lectures/week-08-anova.qmd

# Friday: Final validation and deploy
teach validate --render lectures/week-08-anova.qmd
teach deploy lectures/week-08-anova.qmd --auto-commit --auto-tag
```

### Recipe 2: Bulk Update Existing Content

```bash
# Update branding across all lectures
for file in lectures/*.qmd; do
  # Make changes in editor
  sed -i 's/Spring 2025/Spring 2026/g' "$file"
done

# Validate all changed files
teach validate --syntax lectures/*.qmd

# Deploy with custom message
git add lectures/*.qmd
git commit -m "Update semester branding to Spring 2026"
teach deploy
```

### Recipe 3: Emergency Fix (Broken Link)

```bash
# Student reports broken link in Week 3
code lectures/week-03-mlr.qmd

# Fix link
# Before: [Dataset](data/regression.csv)
# After:  [Dataset](../data/regression-data.csv)

# Quick validation
teach validate --syntax lectures/week-03-mlr.qmd

# Emergency deploy (skip hooks)
git add lectures/week-03-mlr.qmd
git commit --no-verify -m "fix: correct dataset link in week 3"
git push origin draft --no-verify

# Create PR manually
gh pr create --base main --head draft --title "Fix: Week 3 dataset link"
```

### Recipe 4: Pre-Semester Setup

```bash
# 1. Initialize project
teach init --course "STAT 440" --semester "Spring 2026"

# 2. Configure dates
teach dates

# 3. Install hooks
teach hooks install

# 4. Health check
teach doctor --fix

# 5. Create lesson plan
code lesson-plan.yml

# 6. Generate syllabus
teach syllabus

# 7. Initial commit and deploy
git add .
git commit -m "Initial course setup for Spring 2026"
teach deploy
```

### Recipe 5: End-of-Semester Archive

```bash
# 1. Final validation
teach validate --render

# 2. Clear cache for fresh render
teach cache rebuild

# 3. Archive semester
teach archive Fall-2025

# 4. Tag final version
git tag -a fall-2025-final -m "Final Fall 2025 version"
git push origin fall-2025-final

# 5. Prepare for next semester
teach init --course "STAT 440" --semester "Spring 2026"
```

---

## Troubleshooting

### Validation Errors

#### "No YAML frontmatter found"

**Cause:** Missing `---` delimiters

**Fix:**

```markdown
---
title: "Week 1: Introduction"
author: "Dr. Smith"
---

# Content starts here
```

#### "Invalid YAML syntax"

**Cause:** Unquoted special characters, missing colons

**Common issues:**

```yaml
# Wrong
title: Week 1: Introduction   # Unquoted colon

# Right
title: "Week 1: Introduction"
```

```yaml
# Wrong
author Dr. Smith              # Missing colon

# Right
author: "Dr. Smith"
```

#### "Syntax error in code chunk"

**Cause:** Malformed chunk options

**Fix:**

```markdown
# Wrong
```{r}
#| label: fig-plot
#| echo false                  # Missing colon
```

# Right

```{r}
#| label: fig-plot
#| echo: false                 # Colon required
```

```

#### "Render failed"

**Causes:**
1. Missing packages
2. File not found
3. Code errors

**Debugging:**
```bash
# Run render manually to see full error
quarto render lectures/week-05-mlr.qmd

# Common fixes:
# 1. Install missing package
install.packages("package_name")

# 2. Fix file path
# Before: data/file.csv
# After:  ../data/file.csv

# 3. Check code for errors
# Use RStudio or VS Code debugger
```

### Cache Issues

#### "Results not updating after code changes"

**Cause:** Stale cache

**Fix:**

```bash
teach cache clear
teach cache rebuild
```

#### "Cache growing too large"

**Cause:** Many rendered files

**Fix:**

```bash
# Analyze cache
teach cache analyze

# Clear if needed
teach cache clear

# Or clean everything
teach clean --force
```

#### "Render still slow after caching"

**Possible causes:**
1. Cache disabled
2. External data changes
3. Dynamic dates

**Check freeze config:**

```yaml
# _quarto.yml
execute:
  freeze: auto  # Should be 'auto' or 'true'
```

**Check frontmatter:**

```yaml
---
title: "Week 5"
execute:
  freeze: false  # ← Problem: disables freeze for this file
---
```

### Deployment Issues

#### "Not on draft branch"

**Cause:** Working on wrong branch

**Fix:**

```bash
teach deploy

# System will prompt:
# Not on draft branch (currently on: main)
# Switch to draft branch? [Y/n]: y
```

#### "Uncommitted changes detected"

**Cause:** Files modified but not committed

**Fix:**

```bash
# Option 1: Auto-commit
teach deploy lectures/week-05.qmd --auto-commit

# Option 2: Commit manually
git add lectures/week-05.qmd
git commit -m "Update week 5"
teach deploy lectures/week-05.qmd
```

#### "Production branch has new commits"

**Cause:** Production (main) ahead of draft

**Fix:**

```bash
teach deploy

# System will prompt:
# Production branch has updates. Rebase first?
#
#   [1] Yes - Rebase draft onto main (Recommended)
#   [2] No - Continue anyway (may have merge conflicts in PR)
#   [3] Cancel deployment
#
# Your choice [1-3]: 1
```

#### "Dependency not found"

**Cause:** Cross-referenced file missing

**Example:**

```markdown
See @sec-introduction for background.
```

**Fix:**

```bash
# 1. Check if file exists
find . -name "*introduction*"

# 2. Fix cross-reference
# Before: @sec-introduction
# After:  @sec-intro

# Or add missing file to deployment
teach deploy lectures/week-05.qmd lectures/week-01-introduction.qmd
```

### Hook Issues

#### "Commit aborted: validation failed"

**Cause:** Invalid .qmd files staged

**Fix:**

```bash
# See what failed
teach validate --syntax <failed-file>

# Fix errors, then commit again
git add <fixed-file>
git commit -m "message"
```

#### "Hook not running"

**Possible causes:**
1. Hook not installed
2. Hook not executable
3. Wrong working directory

**Fix:**

```bash
# Check status
teach hooks status

# Reinstall if needed
teach hooks install --force

# Check permissions
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x (executable)

# If not executable:
chmod +x .git/hooks/pre-commit
```

#### "Hook running on wrong files"

**Cause:** Git cache issues

**Fix:**

```bash
# Refresh git index
git rm --cached -r .
git reset --hard
```

### Index Management Issues

#### "Index file not updating"

**Cause:** Skipped prompt or index file missing

**Fix:**

```bash
# Create index file if missing
touch home_lectures.qmd

# Add YAML frontmatter
cat > home_lectures.qmd <<EOF
---
title: "Lectures"
---

## Course Lectures

EOF

# Re-run deployment
teach deploy lectures/week-05.qmd
```

#### "Links in wrong order"

**Cause:** Week number not detected in filename

**Filename patterns that work:**
- `week-05-topic.qmd` ✓
- `05-topic.qmd` ✓
- `lecture-week05.qmd` ✓

**Patterns that don't:**
- `topic-week-five.qmd` ✗ (text numbers)
- `lecture05.qmd` ✗ (no separator)

**Fix:**
Rename files to use numeric week pattern:

```bash
mv lecture05.qmd week-05-lecture.qmd
```

### Watch Mode Issues

#### "Watch mode not detecting changes"

**Cause:** File watcher not installed

**Fix:**

```bash
# macOS
brew install fswatch

# Linux
sudo apt-get install inotify-tools
```

#### "Watch mode conflicts with quarto preview"

**Cause:** Both accessing same files

**Fix:**

```bash
# Use separate terminals:
# Terminal 1: quarto preview
quarto preview

# Terminal 2: validation watch
teach validate --watch
```

Or stop quarto preview:

```bash
# Find process
ps aux | grep "quarto preview"

# Kill it
pkill -f "quarto preview"
```

### Performance Issues

#### "Validation very slow"

**Possible causes:**
1. Using render validation on many files
2. Large code chunks
3. External data loading

**Solutions:**

```bash
# Use faster validation layers
teach validate --yaml    # Fastest
teach validate --syntax  # Medium

# Validate only changed files
git diff --name-only | grep '\.qmd$' | xargs teach validate --syntax

# Use parallel validation (future feature)
# Coming in Phase 2: Week 10-11
```

#### "Deployment takes too long"

**Cause:** Full site rebuild

**Solution:**

```bash
# Use partial deployment
teach deploy lectures/week-05.qmd

# Instead of full deploy
teach deploy  # Rebuilds entire site
```

---

## Advanced Topics

### Custom Validation Scripts

Create `.flow/validation-custom.zsh`:

```bash
#!/usr/bin/env zsh

# Custom validation for course-specific requirements

validate_custom() {
  local file="$1"

  # Check for required sections
  if ! grep -q "## Learning Objectives" "$file"; then
    echo "ERROR: Missing Learning Objectives section"
    return 1
  fi

  # Check for recommended length
  local word_count=$(wc -w < "$file")
  if [[ $word_count -lt 1000 ]]; then
    echo "WARNING: Lecture under 1000 words ($word_count)"
  fi

  return 0
}

# Run custom validation
validate_custom "$1"
```

Use in workflow:

```bash
teach validate lectures/week-05.qmd
.flow/validation-custom.zsh lectures/week-05.qmd
```

### CI/CD Integration

**GitHub Actions example:**

```yaml
# .github/workflows/validate.yml

name: Validate Teaching Content

on:
  push:
    branches: [draft]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          brew install yq
          curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
          sudo dpkg -i quarto-linux-amd64.deb

      - name: Health check
        run: teach doctor --json > health.json

      - name: Validate changed files
        run: |
          git diff --name-only origin/main | \
            grep '\.qmd$' | \
            xargs teach validate --render --quiet

      - name: Upload validation results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: validation-results
          path: .teach/validation-status.json
```

### Multiple Deployment Targets

**Scenario:** Deploy to staging and production

```yaml
# .flow/teach-config.yml

git:
  draft_branch: "draft"
  staging_branch: "staging"
  production_branch: "main"

deployments:
  staging:
    auto_pr: true
    require_clean: false

  production:
    auto_pr: true
    require_clean: true
    require_tests: true
```

**Workflow:**

```bash
# Deploy to staging
git checkout staging
teach deploy

# Test on staging site
# ...

# Deploy to production
git checkout main
git merge staging
teach deploy
```

---

## Appendix

### Keyboard Shortcuts

**Teach Cache Menu:**
- `1`: View cache details
- `2`: Clear cache
- `3`: Rebuild cache
- `4`: Clean all
- `5` or `q`: Exit

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Validation failed |
| 2 | Configuration error |
| 3 | Git error |
| 4 | Dependency missing |

### File Locations

| File | Purpose |
|------|---------|
| `.flow/teach-config.yml` | Project configuration |
| `.teach/validation-status.json` | Validation cache |
| `.git/hooks/pre-commit` | Pre-commit validation |
| `*/.backups/` | Timestamped backups |
| `_freeze/` | Quarto cache |

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `QUARTO_PRE_COMMIT_RENDER` | `0` | Enable render on commit |
| `QUARTO_PARALLEL_RENDER` | `1` | Parallel validation |
| `QUARTO_MAX_PARALLEL` | `4` | Max parallel jobs |
| `QUARTO_COMMIT_TIMING` | `1` | Add timing to commits |
| `QUARTO_COMMIT_SUMMARY` | `0` | Add summary to commits |

---

## Next Steps

After mastering Phase 1:

1. **Explore Scholar Integration**
   - Generate content with AI
   - Auto-generate exams and quizzes
   - Interactive lesson planning

2. **Learn Advanced Git Workflows**
   - Branch strategies
   - Conflict resolution
   - GitHub Actions

3. **Optimize Performance**
   - Parallel rendering (Phase 2)
   - Incremental builds
   - Cache strategies

4. **Contribute**
   - Report bugs
   - Suggest features
   - Submit PRs

---

**Questions?** Open an issue on GitHub: https://github.com/Data-Wise/flow-cli/issues

**Documentation:** https://Data-Wise.github.io/flow-cli/
