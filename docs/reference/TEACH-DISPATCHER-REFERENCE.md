# Teach Dispatcher Reference

**Command:** `teach`
**Purpose:** Teaching workflow management for course websites
**Version:** v5.4.1

---

## Overview

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

Deploy course website to production.

```bash
teach deploy
```

Runs `./scripts/quick-deploy.sh` if available.

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

Teaching projects use `.flow/teach-config.yml`:

```yaml
course:
  name: "STAT 440"
  title: "Regression Analysis"
  semester: "Spring 2026"

schedule:
  start_date: "2026-01-13"
  weeks: 15
  breaks:
    - week: 9
      name: "Spring Break"

deployment:
  draft_branch: "draft"
  production_branch: "main"
  auto_deploy: false
```

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

**Version:** v5.4.1
**Last Updated:** 2026-01-13
