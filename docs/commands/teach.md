# teach - Teaching Workflow Dispatcher

Unified command interface for managing course websites and teaching workflows.

## Quick Start

```bash
# Initialize a new course
teach init "STAT 545"

# Non-interactive mode (accept defaults)
teach init -y "STAT 440"

# Check project status
teach status

# Deploy changes to production
teach deploy
```

---

## Synopsis

```bash
teach <command> [args]
```

---

## Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `init [name]` | `i` | Initialize teaching workflow (with git) |
| `exam [name]` | `e` | Create exam (with auto-commit) |
| `quiz [name]` | `q` | Create quiz (with auto-commit) |
| `slides [name]` | `sl` | Create slides (with auto-commit) |
| `lecture [name]` | `l` | Create lecture notes (with auto-commit) |
| `assignment [name]` | `as` | Create assignment (with auto-commit) |
| `deploy` | `d` | Deploy draft → production (creates PR) |
| `archive` | `a` | Archive semester |
| `config` | `c` | Edit teach-config.yml |
| `status` | `s` | Show project status + git changes |
| `week` | `w` | Show current week number |
| `help` | `-h` | Show help |

---

## Examples

### Initialize a New Course

```bash
# Interactive mode (prompts for options, initializes git)
teach init "STAT 545"

# Non-interactive mode (uses safe defaults)
teach init -y "STAT 545"

# Skip git initialization (v5.12.0)
teach init --no-git "TEST 101"

# Preview migration plan without changes
teach init --dry-run "STAT 545"
```

### Daily Workflow with Git Integration (v5.12.0)

```bash
# Start working
work stat-545

# Check current week
teach week

# Create exam (auto-commit prompt)
teach exam "Midterm 1"
# ✓ Generated exams/midterm1.qmd
#
# 📝 Teaching content created
#
# What would you like to do?
#   1) Review in editor, then commit
#   2) Commit now with auto-generated message
#   3) Skip commit (do it manually later)
# Choice: 2
# ✓ Committed: teach: add exam for Midterm 1

# Check status (shows uncommitted files)
teach status
# Course: STAT 545 (Fall 2024)
# Week: 8 of 15
#
# 📝 Uncommitted Teaching Files:
#   • slides/week08.qmd

# Deploy when ready (creates PR)
teach deploy
# Pre-flight checks:
#   ✓ On draft branch
#   ✓ No uncommitted changes
#   ✓ No unpushed commits
#   ✓ No production conflicts
#
# Creating PR: draft → main
```

### Teaching Mode Workflow (v5.12.0)

```bash
# Enable teaching mode for streamlined auto-commit
teach config
# Edit workflow section:
#   teaching_mode: true
#   auto_commit: true
#   auto_push: false

# Now content auto-commits without prompts
teach exam "Midterm"
# ✓ Generated exams/midterm.qmd
# 🎓 Teaching Mode: Auto-committing...
# ✓ Committed: teach: add exam for Midterm

teach quiz "Chapter 5"
# ✓ Generated quizzes/quiz05.qmd
# 🎓 Teaching Mode: Auto-committing...
# ✓ Committed: teach: add quiz for Chapter 5

# Deploy all commits at once
teach deploy
```

### End of Semester

```bash
# Archive the semester
teach archive

# This creates a tagged snapshot and prepares for next semester
```

### Content Creation Examples (v5.12.0)

```bash
# Create exam with Scholar
teach exam "Midterm 1"

# Create quiz
teach quiz "Chapter 5 Review"

# Create slides
teach slides "Introduction to Regression"

# Create lecture notes
teach lecture "Week 3 - Linear Models"

# Create assignment
teach assignment "Homework 1"

# All commands support --dry-run preview
teach exam "Topic" --dry-run --verbose
```

---

## Subcommand Details

### `teach init`

Initialize teaching workflow for a course repository. Creates:
- `.flow/teach-config.yml` - Course configuration
- `scripts/quick-deploy.sh` - Deployment script
- `scripts/semester-archive.sh` - Archive script
- Git repository (if not exists) - v5.12.0
- Branch structure (`draft` / `main`) - v5.12.0
- Teaching-specific `.gitignore` - v5.12.0

**Flags:**
- `-y`, `--yes` - Non-interactive mode (accept safe defaults)
- `--dry-run` - Preview migration plan without changes
- `--no-git` - Skip git initialization (v5.12.0)
- `-h`, `--help` - Show help

**Git Integration (v5.12.0):**
- Auto-initializes git repository for fresh projects
- Creates `draft` and `main` branches
- Copies teaching-specific `.gitignore` template
- Makes initial commit with conventional commits format
- Offers GitHub repo creation via `gh` CLI

**See:** [teach-init](teach-init.md) for full documentation.

### `teach deploy`

Deploy changes from `draft` branch to `main` branch. (v5.12.0: Creates GitHub PR)

```bash
teach deploy
# Pre-flight checks:
#   ✓ On draft branch
#   ✓ No uncommitted changes
#   ✓ No unpushed commits
#   ✓ No production conflicts
#
# Creating PR: draft → main
# → Auto-generated PR body with commit list
# → Deploy checklist included
```

**Pre-flight checks:**
- Verifies on `draft` branch
- Ensures no uncommitted changes
- Detects unpushed commits
- Checks for production branch conflicts

**Interactive rebase support:**
- Offers to rebase if production has new commits
- Prevents merge conflicts during deployment

### `teach archive`

Archive the current semester before starting a new one.

```bash
teach archive
# Runs ./scripts/semester-archive.sh
```

### `teach status`

Show teaching project status including:
- Course name and semester
- Current branch
- Safety warnings (if on production)
- **Uncommitted teaching files (v5.12.0)**
- **Interactive cleanup workflow (v5.12.0)**

```bash
teach status
# 📚 Teaching Project Status
# ━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Course:   STAT 545
#   Semester: Spring 2026
#   Branch:   draft
#   ✓ Safe to edit (draft branch)
#
# 📝 Uncommitted Teaching Files:
#   • exams/exam02.qmd
#   • slides/week08.qmd
#
# What would you like to do?
#   1) Commit all teaching files
#   2) Stash changes
#   3) View diff
#   4) Skip
```

**Git Integration (v5.12.0):**
- Detects uncommitted teaching content (exams, slides, assignments, etc.)
- Filters non-teaching files (shows only relevant content)
- Interactive cleanup workflow:
  - Commit with auto-generated message
  - Stash with timestamp
  - View diff
  - Skip (manual handling)

### `teach week`

Show current week number based on semester start date.

```bash
teach week
# 📅 Week 8
#   Semester started: 2026-01-13
#   Days elapsed: 52
```

### `teach config`

Open the teaching configuration file in your editor.

```bash
teach config
# Opens .flow/teach-config.yml in $EDITOR
```

---

## Configuration

Teaching projects use `.flow/teach-config.yml`:

```yaml
course:
  name: STAT 545
  code: stat-545
  semester: Spring 2026

semester:
  start_date: 2026-01-13
  end_date: 2026-05-08

# Git configuration (v5.12.0)
git:
  draft_branch: draft           # Development branch
  production_branch: main       # Deployment branch
  auto_pr: true                 # Auto-create PRs
  require_clean: true           # Block deploy if uncommitted changes

# Workflow configuration (v5.12.0)
workflow:
  teaching_mode: false          # Streamlined auto-commit workflow
  auto_commit: false            # Auto-commit after content generation
  auto_push: false              # Auto-push commits (safety: false)
```

**Git Settings (v5.12.0):**
- `draft_branch` - Branch for development work (default: "draft")
- `production_branch` - Branch for deployed content (default: "main")
- `auto_pr` - Auto-create PRs during deployment (default: true)
- `require_clean` - Block deploy if uncommitted changes (default: true)

**Workflow Settings (v5.12.0):**
- `teaching_mode` - Enable streamlined auto-commit workflow (default: false)
- `auto_commit` - Auto-commit after content generation (default: false)
- `auto_push` - Auto-push commits to remote (default: false - safety)

All settings are backward compatible and default to false for safety.

---

## Related Commands

| Command | Purpose |
|---------|---------|
| [teach-init](teach-init.md) | Full initialization docs |
| [work](work.md) | Start work session |
| [finish](finish.md) | End work session |

---

## See Also

- [Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)
- [Teaching Reference Card](../reference/REFCARD-TEACHING.md)
- [TEACH Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE.md)
