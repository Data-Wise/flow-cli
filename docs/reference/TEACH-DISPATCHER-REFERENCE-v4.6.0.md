# Teach Dispatcher API Reference

**Version:** 4.6.0 (Phase 1 - Validation, Caching, Deployment)
**Last Updated:** 2026-01-20

---

## Table of Contents

- [Overview](#overview)
- [teach validate](#teach-validate)
- [teach cache](#teach-cache)
- [teach doctor](#teach-doctor)
- [teach deploy](#teach-deploy)
- [teach backup](#teach-backup)
- [teach status](#teach-status)
- [teach hooks](#teach-hooks)
- [teach clean](#teach-clean)
- [Return Codes](#return-codes)
- [Environment Variables](#environment-variables)
- [Configuration Files](#configuration-files)

---

## Overview

The `teach` dispatcher provides 21 commands for Quarto teaching workflow management. All commands follow consistent patterns and support `--help` flags.

### Command Categories

| Category | Commands | Purpose |
|----------|----------|---------|
| **Validation** | `validate` | YAML, syntax, render validation |
| **Cache** | `cache`, `clean` | Freeze cache management |
| **Deployment** | `deploy` | Git-based deployment |
| **Health** | `doctor` | Environment checks |
| **Backup** | `backup`, `archive` | Content snapshots |
| **Status** | `status` | Project dashboard |
| **Hooks** | `hooks` | Git hook management |

### Global Flags

All commands support:
- `-h, --help`: Show command help
- `--quiet, -q`: Suppress non-essential output

---

## teach validate

Granular validation with watch mode support.

### Synopsis

```bash
teach validate [OPTIONS] [FILES...]
```

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--yaml` | Boolean | - | YAML frontmatter validation only |
| `--syntax` | Boolean | - | YAML + Quarto syntax validation |
| `--render` | Boolean | - | Full render validation |
| `--watch` | Boolean | `false` | Continuous validation on file changes |
| `--stats` | Boolean | `false` | Show performance statistics |
| `--quiet, -q` | Boolean | `false` | Minimal output |
| `--help, -h` | Boolean | - | Show help message |

### Arguments

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `FILES` | Path[] | No | Quarto files to validate (.qmd) |

**Default behavior:** If no files specified, validates all `.qmd` files in current directory.

### Validation Layers

| Layer | Flag | Time | What It Checks |
|-------|------|------|----------------|
| 1. YAML | `--yaml` | ~100ms | YAML frontmatter syntax |
| 2. Syntax | `--syntax` | ~500ms | Layer 1 + Quarto structure |
| 3. Render | `--render` | 3-15s | Layer 2 + full document render |
| 4. Chunks | (auto) | ~50ms | Empty code chunks (warning) |
| 5. Images | (auto) | ~100ms | Missing image references (warning) |

**Full validation:** Uses all 5 layers.

### Examples

```bash
# Fast YAML validation
teach validate --yaml lectures/week-01.qmd

# Syntax check (YAML + structure)
teach validate --syntax lectures/week-01.qmd

# Full render validation
teach validate --render lectures/week-01.qmd

# Validate all files in directory
teach validate

# Validate specific files
teach validate lectures/week-0{1..5}*.qmd

# Watch mode (auto-validate on save)
teach validate --watch lectures/week-01.qmd

# Syntax validation with performance stats
teach validate --syntax --stats

# Quiet mode (errors only)
teach validate --quiet lectures/week-01.qmd
```

### Output

**Standard output:**
```
Running full validation for 1 file(s)...

Validating: lectures/week-01.qmd
✓ YAML valid: lectures/week-01.qmd
✓ Syntax valid: lectures/week-01.qmd
✓ Render valid: lectures/week-01.qmd (4s)

✓ All 1 files passed validation (4.2s)
```

**With --stats:**
```
Total: 4200ms | Files: 1 | Avg: 4200ms/file
```

**Watch mode output:**
```
Starting watch mode for 1 file(s)...
Press Ctrl+C to stop

Running initial validation...
✓ lectures/week-01.qmd (1.2s)

Watching for changes...

File changed: lectures/week-01.qmd
Validating...
✓ Validation passed (523ms)

Watching for changes...
```

### Validation Status File

Creates `.teach/validation-status.json`:

```json
{
  "files": {
    "lectures/week-01.qmd": {
      "status": "pass",
      "error": "",
      "timestamp": "2026-01-20T12:00:00Z"
    }
  }
}
```

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | All validations passed |
| 1+ | Number of files that failed validation |

### Watch Mode Behavior

**File watcher:** Uses `fswatch` (macOS) or `inotifywait` (Linux)

**Debouncing:** Waits 500ms after file change before validating

**Conflict detection:** Skips validation if `quarto preview` is running

**Validation layers in watch mode:** YAML + Syntax (render skipped for speed)

### Related Commands

- `teach doctor` - Check if dependencies installed
- `teach hooks install` - Auto-validate on commits

---

## teach cache

Interactive freeze cache management.

### Synopsis

```bash
teach cache [SUBCOMMAND] [OPTIONS]
```

### Subcommands

| Command | Alias | Description |
|---------|-------|-------------|
| (none) | - | Interactive TUI menu |
| `status` | `s` | Show cache size and file count |
| `clear` | `c` | Delete _freeze/ directory |
| `rebuild` | `r` | Clear cache and re-render |
| `analyze` | `a`, `details`, `d` | Detailed cache breakdown |
| `help` | - | Show help message |

### Options

| Flag | Applies To | Description |
|------|------------|-------------|
| `--force` | `clear` | Skip confirmation prompt |

### Examples

```bash
# Interactive menu
teach cache

# Quick status check
teach cache status

# Clear cache with confirmation
teach cache clear

# Force clear without confirmation
teach cache clear --force

# Rebuild from scratch
teach cache rebuild

# Detailed analysis
teach cache analyze
```

### Interactive Menu

```
┌─────────────────────────────────────────────────────────────┐
│ Freeze Cache Management                                     │
├─────────────────────────────────────────────────────────────┤
│ Cache: 71MB (342 files)                                     │
│ Last render: 2 hours ago                                    │
│                                                             │
│ 1. View cache details                                       │
│ 2. Clear cache (delete _freeze/)                            │
│ 3. Rebuild cache (force re-render)                          │
│ 4. Clean all (delete _freeze/ + _site/)                     │
│ 5. Exit                                                     │
│                                                             │
│ Choice: _                                                   │
└─────────────────────────────────────────────────────────────┘
```

### teach cache status

**Output:**
```
Freeze Cache Status

  Location:     /Users/dt/stat-440/_freeze
  Size:         71MB
  Files:        342
  Last render:  2 hours ago
```

### teach cache clear

**Output:**
```
Cache to be deleted:
  Location:   /Users/dt/stat-440/_freeze
  Size:       71MB
  Files:      342

Delete freeze cache? [y/N]: y

✓ Freeze cache cleared (71MB freed)
```

### teach cache rebuild

**Output:**
```
Rebuilding freeze cache...

✓ Freeze cache cleared (71MB freed)

Re-rendering all content...
Rendering Quarto project (~30-60s)
████████████████████ 100%

✓ Cache rebuilt successfully

New cache: 73MB (348 files)
```

### teach cache analyze

**Output:**
```
╭─ Freeze Cache Analysis ────────────────────────────╮
│
│ Overall:
│   Total size:  71MB
│   Files:       342
│   Last render: 2 hours ago
│
│ By Content Directory:
│
│   lectures                       45MB     (187 files)
│   assignments                    18MB     (98 files)
│   exams                          8MB      (57 files)
│
│ By Age:
│
│   Last hour:       23 files
│   Last day:       156 files
│   Last week:      163 files
│   Older:            0 files
│
╰────────────────────────────────────────────────────╯
```

### Cache Status Structure

The cache status helper `_cache_status` returns:

```bash
cache_status=exists|none
size=<bytes>
size_human=<human-readable>
file_count=<number>
last_render=<time-ago>
last_render_timestamp=<unix-timestamp>
```

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Cache not found or operation failed |

### Related Commands

- `teach clean` - Clean cache + site
- `teach status` - View cache in dashboard

---

## teach doctor

Environment health check with auto-fix.

### Synopsis

```bash
teach doctor [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--quiet, -q` | Only show warnings and failures |
| `--fix` | Interactive install of missing dependencies |
| `--json` | Output results as JSON |
| `--help, -h` | Show help message |

### Health Checks

#### 1. Dependencies

**Required:**
- `yq` - YAML processing
- `git` - Version control
- `quarto` - Document rendering
- `gh` - GitHub CLI

**Optional:**
- `examark` - Exam generation
- `claude` - Claude Code CLI

**R packages (if R available):**
- `ggplot2`, `dplyr`, `tidyr`, `knitr`, `rmarkdown`

#### 2. Project Configuration

- `.flow/teach-config.yml` exists
- Config validates against schema
- Course name set
- Semester set
- Dates configured

#### 3. Git Setup

- Repository initialized
- Draft branch exists
- Production branch exists
- Remote configured
- Working tree clean

#### 4. Scholar Integration

- Claude Code available
- Scholar skills accessible
- Lesson plan file (optional)

#### 5. Git Hooks

- `pre-commit` installed and versioned
- `pre-push` installed and versioned
- `prepare-commit-msg` installed and versioned

#### 6. Cache Health

- `_freeze/` directory exists
- Cache size
- Last render time
- Cache freshness

### Examples

```bash
# Full health check
teach doctor

# Quiet mode (warnings/failures only)
teach doctor --quiet

# Interactive fix mode
teach doctor --fix

# JSON output for CI/CD
teach doctor --json
```

### Output

**Standard output:**
```
╭────────────────────────────────────────────────────────────╮
│  📚 Teaching Environment Health Check                       │
╰────────────────────────────────────────────────────────────╯

Dependencies:
  ✓ yq (4.35.1)
  ✓ git (2.43.0)
  ✓ quarto (1.4.550)
  ✓ gh (2.40.1)
  ✓ examark (0.6.6)
  ⚠ claude (not found - optional)

Project Configuration:
  ✓ .flow/teach-config.yml exists
  ✓ Config validates against schema
  ✓ Course name: STAT 440
  ✓ Semester: Spring 2026
  ✓ Dates configured (2026-01-15 - 2026-05-08)

Git Setup:
  ✓ Git repository initialized
  ✓ Draft branch exists
  ✓ Production branch exists: main
  ✓ Remote configured: origin
  ⚠ 3 uncommitted changes

Scholar Integration:
  ⚠ Claude Code not found
  ⚠ Scholar skills not detected
  ✓ Lesson plan found: lesson-plan.yml

Git Hooks:
  ✓ Hook installed: pre-commit (flow-cli managed)
  ✓ Hook installed: pre-push (flow-cli managed)
  ✓ Hook installed: prepare-commit-msg (flow-cli managed)

Cache Health:
  ✓ Freeze cache exists (71MB)
  ✓ Cache is recent (2 days old)
      → 342 cached files

────────────────────────────────────────────────────────────
Summary: 18 passed, 4 warnings, 0 failures
────────────────────────────────────────────────────────────
```

**JSON output:**
```json
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
    {"check":"course_name","status":"pass","message":"STAT 440"}
  ]
}
```

### Interactive Fix Mode

With `--fix`, prompts to install missing dependencies:

```
✗ examark (not found)
  → Install examark? [Y/n]: y
  → npm install -g examark
  ✓ examark installed
```

**Optional dependencies:**
```
⚠ claude (not found - optional)
  → Install claude (optional)? [y/N]: n
```

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed (warnings OK) |
| 1 | One or more checks failed |

### CI/CD Integration

```bash
# GitHub Actions example
teach doctor --json > health.json

STATUS=$(jq -r '.summary.status' health.json)
if [[ "$STATUS" != "healthy" ]]; then
  exit 1
fi
```

### Related Commands

- `teach hooks status` - Check hook versions
- `teach cache status` - Check cache health
- `teach validate` - Check if validation tools work

---

## teach deploy

Git-based deployment with partial deployment support.

### Synopsis

```bash
teach deploy [FILES...] [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--auto-commit` | Auto-commit uncommitted changes |
| `--auto-tag` | Create timestamped git tag |
| `--skip-index` | Skip index management prompts |
| `--direct-push` | Bypass PR (advanced) |
| `--help, -h` | Show help message |

### Arguments

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `FILES` | Path[] | No | Files or directories to deploy |

**Default behavior:** If no files specified, performs full site deployment.

### Deployment Modes

#### Full Site Deployment

```bash
teach deploy
```

**Process:**
1. Pre-flight checks (branch, uncommitted, conflicts)
2. Generate PR details
3. Show changes preview
4. Create PR to production

#### Partial Deployment

```bash
teach deploy lectures/week-05.qmd
```

**Process:**
1. Pre-flight checks
2. Dependency tracking
3. Cross-reference validation
4. Index management (ADD/UPDATE/REMOVE)
5. Backup creation
6. Push and PR

### Pre-Flight Checks

| Check | Behavior |
|-------|----------|
| **Branch** | Must be on draft branch (prompts to switch) |
| **Uncommitted changes** | Blocks if `require_clean: true` |
| **Unpushed commits** | Prompts to push |
| **Production conflicts** | Prompts to rebase |

### Dependency Tracking

Automatically finds:
- **Sourced files:** `source("scripts/helpers.R")`
- **Cross-references:** `@sec-introduction`, `@fig-plot`, `@tbl-results`

**Prompt:**
```
🔍 Finding dependencies...
  Dependencies for lectures/week-05-mlr.qmd:
    • lectures/week-04-slr.qmd
    • scripts/regression-utils.R

Found 2 additional dependencies
Include dependencies in deployment? [Y/n]:
```

### Index Management

Detects changes to index files:

**ADD:**
```
📄 New content detected:
  week-05-mlr.qmd: Multiple Linear Regression

Add to index file? [Y/n]:
```

**UPDATE:**
```
📝 Title changed:
  Old: Multiple Linear Regression
  New: Multiple Regression and Interactions

Update index link? [y/N]:
```

**REMOVE:**
```
🗑  Content deleted:
  week-05-mlr.qmd

Remove from index? [Y/n]:
```

### Examples

```bash
# Full site deployment
teach deploy

# Partial: single file
teach deploy lectures/week-05.qmd

# Partial: multiple files
teach deploy lectures/week-05.qmd lectures/week-06.qmd

# Partial: entire directory
teach deploy lectures/

# Auto-commit uncommitted changes
teach deploy lectures/week-05.qmd --auto-commit

# Auto-commit with tag
teach deploy lectures/week-05.qmd --auto-commit --auto-tag

# Skip index prompts
teach deploy lectures/week-05.qmd --skip-index
```

### Full Site Deployment Output

```
🔍 Pre-flight Checks
─────────────────────────────────────────────────
✓ On draft branch
✓ No uncommitted changes
✓ Remote is up-to-date
✓ No conflicts with production

📋 Pull Request Preview
─────────────────────────────────────────────────

Title: Deploy: STAT 440 Updates
From: draft → main
Commits: 5

📋 Changes Preview
─────────────────────────────────────────────────

Files Changed:
  M  lectures/week-01-intro.qmd
  M  lectures/week-02-regression.qmd
  A  lectures/week-03-diagnostics.qmd
  M  home_lectures.qmd

Summary: 4 files (1 added, 3 modified, 0 deleted)

Create pull request?

  [1] Yes - Create PR (Recommended)
  [2] Push to draft only (no PR)
  [3] Cancel

Your choice [1-3]:
```

### Partial Deployment Output

```
📦 Partial Deploy Mode
─────────────────────────────────────────────────

Files to deploy:
  • lectures/week-05-mlr.qmd

🔗 Validating cross-references...
✓ All cross-references valid

🔍 Finding dependencies...
  Dependencies for lectures/week-05-mlr.qmd:
    • lectures/week-04-slr.qmd
    • scripts/regression-utils.R

Found 2 additional dependencies
Include dependencies in deployment? [Y/n]: y

⚠️  Uncommitted changes detected

  • lectures/week-05-mlr.qmd

Commit message (or Enter for auto): Add MLR examples

✓ Committed changes

🔍 Checking index files...

📄 New content detected:
  week-05-mlr.qmd: Multiple Linear Regression

Add to index file? [Y/n]: y
✓ Added link to home_lectures.qmd

📝 Committing index changes...
✓ Index changes committed

Push to origin/draft? [Y/n]: y
✓ Pushed to origin/draft

Create pull request? [Y/n]: y
✅ Pull Request Created

View at: https://github.com/user/stat-440/pull/42
```

### Configuration

Set in `.flow/teach-config.yml`:

```yaml
git:
  draft_branch: "draft"          # Default: draft
  production_branch: "main"      # Default: main
  auto_pr: true                  # Create PR automatically
  require_clean: true            # Block if uncommitted changes
```

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | Deployment successful |
| 1 | Pre-flight check failed or user cancelled |

### Related Commands

- `teach validate` - Pre-deployment validation
- `teach status` - Check deployment history
- `teach doctor` - Verify git setup

---

## teach backup

Manual backup operations (automatic backups happen during deploy).

### Synopsis

```bash
teach backup [SUBCOMMAND] [OPTIONS]
```

### Subcommands

| Command | Description |
|---------|-------------|
| `create <path>` | Create backup of content folder |
| `list <path>` | List backups for content folder |
| `restore <backup>` | Restore from backup |
| `delete <backup>` | Delete specific backup |
| `archive <semester>` | Archive semester backups |

### Automatic Backups

Backups are created automatically during:
- `teach deploy` operations
- Scholar content generation
- Content modification commands

**Location:** `<content-dir>/.backups/<content-name>.<timestamp>/`

### Retention Policies

Configured in `.flow/teach-config.yml`:

```yaml
backups:
  retention:
    assessments: "archive"    # Keep forever
    syllabi: "archive"        # Keep forever
    lectures: "semester"      # Delete at semester end
  archive_dir: ".flow/archives"
```

### Examples

```bash
# Create manual backup
teach backup create lectures/week-05-mlr.qmd

# List backups
teach backup list lectures/week-05-mlr.qmd

# Restore from backup
teach backup restore lectures/.backups/week-05-mlr.2026-01-20-1030/

# Delete backup (with confirmation)
teach backup delete lectures/.backups/week-05-mlr.2026-01-20-1030/

# Archive semester
teach backup archive Fall-2025
```

### teach backup create

**Output:**
```
💾 Creating backup...
✓ Backup created: lectures/.backups/week-05-mlr.2026-01-20-1534/
```

### teach backup list

**Output:**
```
Backups for lectures/week-05-mlr.qmd:

  1. 2026-01-20-1730  (2 hours ago)    12MB
  2. 2026-01-20-1445  (5 hours ago)    11MB
  3. 2026-01-20-1030  (9 hours ago)    11MB

Total: 3 backups, 34MB
```

### teach backup restore

**Output:**
```
⚠ Restore Backup?
────────────────────────────────────────────────

  Source:      lectures/.backups/week-05-mlr.2026-01-20-1030/
  Destination: lectures/week-05-mlr.qmd
  Size:        11MB
  Files:       1

⚠ This will overwrite current content!

Restore this backup? [y/N]: y

✓ Backup restored
```

### teach backup delete

**Output:**
```
⚠ Delete Backup?
────────────────────────────────────────────────

  Path:     lectures/.backups/week-05-mlr.2026-01-20-1030/
  Name:     week-05-mlr.2026-01-20-1030
  Size:     11MB
  Files:    1

⚠ This action cannot be undone!

Delete this backup? [y/N]: y

✓ Backup deleted
```

### teach backup archive

**Output:**
```
Archiving Fall-2025...

✓ Archive complete: .flow/archives/Fall-2025

  Archived: 12 content folders
  Deleted:  8 content folders (semester retention)
```

**Archive structure:**
```
.flow/archives/Fall-2025/
├── midterm-backups/
├── final-backups/
├── assignment-01-backups/
└── assignment-02-backups/
```

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Backup not found or operation failed |

### Related Commands

- `teach status` - View backup summary
- `teach deploy` - Triggers automatic backups

---

## teach status

Comprehensive project dashboard.

### Synopsis

```bash
teach status [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--full` | Show additional details |
| `--help, -h` | Show help message |

### Examples

```bash
# Standard dashboard
teach status

# Full details
teach status --full
```

### Output

```
┌─────────────────────────────────────────────────────────────────┐
│              STAT 440 - Spring 2026                             │
├─────────────────────────────────────────────────────────────────┤
│  📁 Project:      ~/teaching/stat-440                           │
│  🔧 Quarto:       Freeze ✓ (71MB, 342 files)                    │
│  🎣 Hooks:        Pre-commit ✓ (v1.0.0), Pre-push ✓ (v1.0.0)   │
│  🚀 Deployments:  Last 2 hours ago (deploy-2026-01-20-1430)    │
│  📚 Index:        12 lectures, 8 assignments linked             │
│  💾 Backups:      23 backups (156MB)                            │
│  ⏱️  Performance:  Last render 4s (avg 6s)                       │
└─────────────────────────────────────────────────────────────────┘

Current Branch: draft
  ✓ Safe to edit (draft branch)

✓ Project health: Good
```

### Dashboard Sections

#### Course Info (Header)
- Course name
- Semester
- Year (if configured)

#### Project
- Current working directory path

#### Quarto
- Freeze cache status
- Cache size
- File count

#### Hooks
- Installed hooks
- Hook versions

#### Deployments
- Last deployment time
- Deployment tag (if available)
- Open PRs (if `gh` available)

#### Index
- Linked lectures count
- Linked assignments count

#### Backups
- Total backup count
- Total backup size

#### Performance (optional)
- Last render time
- Average render time

### Branch Status

Displays current git branch with context:

```
Current Branch: draft
  ✓ Safe to edit (draft branch)
```

```
Current Branch: production
  ⚠ On production - changes are live!
```

### Health Warnings

Shows warnings if detected:

```
⚠ Config validation issues detected
  Run teach doctor for details

⚠ Uncommitted changes: 3 teaching files
  Run g status to review
```

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Not a teaching project (no config file) |

### Related Commands

- `teach doctor` - Full health check
- `teach cache status` - Detailed cache info
- `teach backup list` - Detailed backup info

---

## teach hooks

Git hook installation and management.

### Synopsis

```bash
teach hooks [SUBCOMMAND] [OPTIONS]
```

### Subcommands

| Command | Description |
|---------|-------------|
| `install` | Install all git hooks |
| `upgrade` | Upgrade hooks to latest version |
| `status` | Show hook installation status |
| `uninstall` | Remove all hooks |

### Options

| Flag | Applies To | Description |
|------|------------|-------------|
| `--force, -f` | `install` | Overwrite existing hooks |

### Available Hooks

| Hook | File | Version | Purpose |
|------|------|---------|---------|
| `pre-commit` | `.git/hooks/pre-commit` | 1.0.0 | YAML + Syntax validation |
| `pre-push` | `.git/hooks/pre-push` | 1.0.0 | Full render validation |
| `prepare-commit-msg` | `.git/hooks/prepare-commit-msg` | 1.0.0 | Add timing metadata |

### Examples

```bash
# Install all hooks
teach hooks install

# Force reinstall (overwrite existing)
teach hooks install --force

# Check installation status
teach hooks status

# Upgrade outdated hooks
teach hooks upgrade

# Uninstall all hooks
teach hooks uninstall
```

### teach hooks install

**Output:**
```
Installing git hooks for Quarto workflow...

✓ Installed pre-commit (v1.0.0)
✓ Installed pre-push (v1.0.0)
✓ Installed prepare-commit-msg (v1.0.0)

✓ All hooks installed successfully (3 hooks)

Configuration options:
   QUARTO_PRE_COMMIT_RENDER=1    # Enable full rendering on commit
   QUARTO_PARALLEL_RENDER=1      # Enable parallel rendering (default: on)
   QUARTO_MAX_PARALLEL=4         # Max parallel jobs (default: 4)
   QUARTO_COMMIT_TIMING=1        # Add timing to commit messages (default: on)
   QUARTO_COMMIT_SUMMARY=1       # Add validation summary to commits

To set environment variables:
   export QUARTO_PRE_COMMIT_RENDER=1
   # Or add to ~/.zshrc for persistence
```

### teach hooks status

**Output:**
```
Hook status:

✓ pre-commit: v1.0.0 (up to date)
✓ pre-push: v1.0.0 (up to date)
✓ prepare-commit-msg: v1.0.0 (up to date)

Summary: 3 up to date, 0 outdated, 0 missing
```

**With outdated hooks:**
```
Hook status:

⚠ pre-commit: v0.9.0 (upgrade to v1.0.0)
⚠ pre-push: v0.9.0 (upgrade to v1.0.0)
✓ prepare-commit-msg: v1.0.0 (up to date)

Summary: 1 up to date, 2 outdated, 0 missing

Run teach hooks upgrade to update outdated hooks
```

### teach hooks upgrade

**Output:**
```
Checking for hook upgrades...

Hooks to upgrade: 2
   - pre-commit (v0.9.0 → v1.0.0)
   - pre-push (v0.9.0 → v1.0.0)

Upgrade these hooks? [Y/n]: y

✓ Installed pre-commit (v1.0.0)
✓ Installed pre-push (v1.0.0)

✓ All hooks upgraded successfully (2 hooks)
```

### teach hooks uninstall

**Output:**
```
⚠ This will remove all flow-cli managed hooks
Continue? [y/N]: y

✓ Removed pre-commit
✓ Removed pre-push
✓ Removed prepare-commit-msg

✓ Uninstalled 3 hook(s)
```

### Hook Backup

Non-flow-managed hooks are automatically backed up:

```
Backed up existing hook to: pre-commit.backup-20260120-143045
```

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Not in git repository or operation failed |

### Related Commands

- `teach doctor` - Check if hooks installed
- `teach validate` - Manual validation

---

## teach clean

Clean build artifacts (freeze cache + site output).

### Synopsis

```bash
teach clean [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation prompt |
| `--help, -h` | Show help message |

### Examples

```bash
# Clean with confirmation
teach clean

# Force clean without confirmation
teach clean --force
```

### Output

```
Directories to be deleted:
  _freeze/ (71MB)
  _site/ (23MB)

  Total files: 512

Delete all build artifacts? [y/N]: y

✓ Deleted _freeze/
✓ Deleted _site/

✓ Clean complete (2 directories deleted)
```

### What Gets Deleted

| Directory | Purpose | When Created |
|-----------|---------|--------------|
| `_freeze/` | Quarto freeze cache | First render with `freeze: auto` |
| `_site/` | Rendered site output | `quarto render` |

### When to Use

- **Free disk space:** Cache can grow to 100s of MB
- **Fresh render:** Before final deployment
- **Troubleshooting:** Rule out cache issues
- **Major refactor:** Many files changed

### Return Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | No directories to clean or operation failed |

### Related Commands

- `teach cache clear` - Clear freeze cache only
- `teach cache rebuild` - Clear and re-render

---

## Return Codes

### Standard Return Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error or operation failed |
| 2 | Configuration error |
| 3 | Git error |
| 4 | Dependency missing |

### Command-Specific Return Codes

#### teach validate

| Code | Meaning |
|------|---------|
| 0 | All validations passed |
| 1+ | Number of files that failed |

**Example:** If 3 files fail validation, returns code 3.

#### teach doctor

| Code | Meaning |
|------|---------|
| 0 | All checks passed (warnings OK) |
| 1 | One or more critical failures |

---

## Environment Variables

### Hook Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `QUARTO_PRE_COMMIT_RENDER` | `0` | Enable full render on commit |
| `QUARTO_PARALLEL_RENDER` | `1` | Enable parallel rendering |
| `QUARTO_MAX_PARALLEL` | `4` | Max parallel jobs |
| `QUARTO_COMMIT_TIMING` | `1` | Add timing to commit messages |
| `QUARTO_COMMIT_SUMMARY` | `0` | Add validation summary to commits |

**Example:**
```bash
# In ~/.zshrc
export QUARTO_PRE_COMMIT_RENDER=0
export QUARTO_PARALLEL_RENDER=1
export QUARTO_MAX_PARALLEL=8
export QUARTO_COMMIT_TIMING=1
export QUARTO_COMMIT_SUMMARY=0
```

### Hook Version

| Variable | Value | Description |
|----------|-------|-------------|
| `FLOW_HOOK_VERSION` | `1.0.0` | Current hook version |

---

## Configuration Files

### .flow/teach-config.yml

Main project configuration file.

```yaml
course:
  name: "STAT 440"
  semester: "Spring 2026"
  year: 2026

semester_info:
  start_date: "2026-01-15"
  end_date: "2026-05-08"
  holidays:
    - "2026-03-16"  # Spring break
    - "2026-03-17"

git:
  draft_branch: "draft"
  production_branch: "main"
  auto_pr: true
  require_clean: true

backups:
  retention:
    assessments: "archive"
    syllabi: "archive"
    lectures: "semester"
  archive_dir: ".flow/archives"
```

### .teach/validation-status.json

Validation cache file (auto-generated).

```json
{
  "files": {
    "lectures/week-01.qmd": {
      "status": "pass",
      "error": "",
      "timestamp": "2026-01-20T12:00:00Z"
    },
    "lectures/week-02.qmd": {
      "status": "fail",
      "error": "Validation failed",
      "timestamp": "2026-01-20T12:05:00Z"
    }
  }
}
```

### .git/hooks/*

Git hook files (auto-generated via `teach hooks install`).

**Header format:**
```bash
#!/usr/bin/env zsh
# Auto-generated by: teach hooks install
# Version: 1.0.0
# Date: 2026-01-20
```

---

## Shortcuts

Quick reference for common operations:

| Task | Command |
|------|---------|
| **Health check** | `teach doctor` |
| **Quick validation** | `teach validate --yaml` |
| **Full validation** | `teach validate --render` |
| **Watch mode** | `teach validate --watch` |
| **Cache status** | `teach cache status` |
| **Clear cache** | `teach cache clear --force` |
| **Deploy single file** | `teach deploy <file> --auto-commit` |
| **Deploy with tag** | `teach deploy <file> --auto-tag` |
| **Install hooks** | `teach hooks install` |
| **Check hooks** | `teach hooks status` |
| **Project dashboard** | `teach status` |

---

## See Also

- [Teaching Quarto Workflow Guide](../guides/TEACHING-QUARTO-WORKFLOW-GUIDE.md) - Complete workflow documentation
- [Backup System Guide](../guides/BACKUP-SYSTEM-GUIDE.md) - Backup and retention details
- [flow-cli Documentation](https://Data-Wise.github.io/flow-cli/) - Main documentation site

---

**Last Updated:** 2026-01-20
**Version:** 4.6.0
**License:** MIT
