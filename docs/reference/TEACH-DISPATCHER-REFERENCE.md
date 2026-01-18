# Teach Dispatcher Reference

**Command:** `teach`
**Purpose:** Teaching workflow management for course websites
**Version:** v5.13.0 (Legacy) → **v5.14.0 (Current)**

> **⚠️ DEPRECATION NOTICE**
>
> This document covers flow-cli v5.13.0 and earlier.
>
> **For Teaching Workflow v3.0 (flow-cli v5.14.0+), see:**
> - **[TEACH-DISPATCHER-REFERENCE-v3.0.md](TEACH-DISPATCHER-REFERENCE-v3.0.md)** - Complete v3.0 reference
> - **[TEACHING-WORKFLOW-V3-GUIDE.md](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)** - v3.0 user guide
> - **[BACKUP-SYSTEM-GUIDE.md](../guides/BACKUP-SYSTEM-GUIDE.md)** - Backup system guide
>
> **What's New in v3.0:**
> - ✅ `teach doctor` - Health checks with `--fix`, `--json`, `--quiet`
> - ✅ Enhanced `teach status` - Deployment status, backup summary
> - ✅ Enhanced `teach deploy` - Changes preview, diff viewing
> - ✅ Backup system - Automated backups with retention policies
> - ✅ Scholar templates - `--template` flag for all Scholar commands
> - ✅ Lesson plan auto-loading - Automatic context integration
> - ✅ `teach init` flags - `--config` and `--github` options

---

## Overview (Legacy v5.13.0)

The `teach` dispatcher provides unified commands for managing teaching workflows, including course initialization, exam creation, deployment, and semester management.

### Key Features

- **Course initialization** - Set up new courses with `teach init`
- **Exam management** - Create exams with `teach exam`
- **Quick deployment** - Deploy to production with `teach deploy`
- **Semester archive** - Archive completed semesters
- **Status tracking** - View course status and current week

---

## Quick Start

```bash
# Initialize a new teaching project
teach init "STAT 440"

# Non-interactive mode (safe defaults)
teach init -y "STAT 440"

# Show current status
teach status

# Show current week
teach week

# Deploy to production
teach deploy

# Create an exam
teach exam "Midterm"
```

---

## Commands

### `teach init` / `teach i`

Initialize a new teaching project.

```bash
teach init "Course Name"
teach init -y "Course Name"    # Non-interactive mode
teach init --yes "Course Name" # Non-interactive mode
```

**Options:**
- `-y`, `--yes` - Use safe defaults without prompts

**What it does:**
1. Creates `.flow/teach-config.yml` configuration
2. Sets up deployment scripts
3. Configures semester schedule
4. Creates necessary directories

**Safe defaults (non-interactive):**
- Strategy 1: In-place conversion (preserves git history)
- Auto-exclude `renv/` from git
- Skip GitHub push (do manually later)
- Use suggested semester start date
- Skip break configuration

### `teach exam` / `teach e`

Create a new exam.

```bash
teach exam "Midterm"
teach exam "Final Exam"
```

### `teach deploy` / `teach d`

Deploy course website to production via PR workflow.

```bash
teach deploy              # Standard PR workflow
teach deploy --direct-push # Bypass PR (advanced)
```

**Requirements:**
- Must be in a git repository
- Config file must exist at `.flow/teach-config.yml`
- Must be on the draft branch (or will prompt to switch)

**Pre-flight Checks:**
1. Verifies you're on the draft branch
2. Checks for uncommitted changes
3. Verifies remote is up-to-date
4. Checks if production has new commits (offers rebase)

**Branch Configuration:**
The deploy command reads branch names from `.flow/teach-config.yml`:

```yaml
# Format 1: Under 'branches' key
branches:
  draft: draft
  production: main

# Format 2: Under 'git' key (legacy)
git:
  draft_branch: draft
  production_branch: main
```

**Troubleshooting:**
- "`.flow/teach-config.yml` not found" → Run `teach init` first
- "Not on draft branch" → Switch to draft or let the command switch for you
- "Uncommitted changes" → Commit or stash changes first

### `teach archive` / `teach a`

Archive a completed semester.

```bash
teach archive
```

Runs `./scripts/semester-archive.sh` if available.

### `teach config` / `teach c`

Edit the teaching configuration file.

```bash
teach config
```

Opens `.flow/teach-config.yml` in your editor.

### `teach status` / `teach s`

Show current teaching project status.

```bash
teach status
```

**Output:**
```
╭────────────────────────────────────────────────────╮
│  📚 STAT 440 - Regression Analysis                 │
├────────────────────────────────────────────────────┤
│  Semester: Spring 2026                             │
│  Week: 3 of 15                                     │
│  Status: Active                                    │
│                                                    │
│  Draft → Production sync: Up to date              │
│  Last deploy: 2026-01-10 14:30                     │
╰────────────────────────────────────────────────────╯
```

### `teach week` / `teach w`

Show current week information.

```bash
teach week        # Current week
teach week 5      # Week 5 info
```

### `teach help`

Show help information.

```bash
teach help
teach --help
teach -h
```

---

## Configuration

Teaching projects use `.flow/teach-config.yml` (created by `teach init`):

```yaml
# Course information
course:
  name: "STAT 440"
  full_name: "Regression Analysis"
  semester: Spring
  year: 2026
  instructor: "Dr. Smith"

# Semester schedule
semester_info:
  start_date: "2026-01-13"
  end_date: "2026-05-01"
  weeks:
    - number: 1
      start_date: "2026-01-13"
      topic: "Course Introduction"
  holidays:
    - name: "Spring Break"
      date: "2026-03-16"
      type: break

# Branch configuration (used by teach deploy)
branches:
  draft: draft
  production: main

# Git workflow settings
git:
  require_clean: true
  auto_pr: true

# Workflow settings
workflow:
  teaching_mode: false
  auto_push: false
```

**Config File Location:**
- **Standard:** `.flow/teach-config.yml` (inside project)
- Created automatically by `teach init`
- Edit with `teach config` command

**Important:** The `teach deploy` command requires this file to exist. If you see "`.flow/teach-config.yml` not found", run `teach init` first.

---

## Workflow

### Setting Up a New Course

```bash
# 1. Navigate to course directory
cd ~/teaching/stat-440

# 2. Initialize teaching workflow
teach init "STAT 440"

# 3. Review configuration
teach config

# 4. Check status
teach status
```

### Weekly Workflow

```bash
# Start of week
teach week              # See what's scheduled

# During week
teach status            # Check deployment status

# End of week
teach deploy            # Push to production
```

### End of Semester

```bash
# Archive the semester
teach archive

# Review and confirm
teach status
```

---

## Related Commands

| Command | Purpose |
|---------|---------|
| `work teaching` | Start teaching session |
| `dash teach` | Teaching dashboard |
| `qu preview` | Preview Quarto site |
| `qu render` | Render course materials |

---

## See Also

- [Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)
- [teach-init Command Reference](../commands/teach-init.md)
- [Quick Reference Card](REFCARD-TEACHING.md)

---

**Version:** v5.13.0
**Last Updated:** 2026-01-18
