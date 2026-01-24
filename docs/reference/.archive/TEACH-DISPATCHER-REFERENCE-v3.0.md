# Teach Dispatcher Reference (v3.0)

**Command:** `teach`
**Purpose:** Teaching workflow management for course websites
**Version:** v5.14.0 (Teaching Workflow v3.0 Phase 1)

---

## Overview

The `teach` dispatcher provides unified commands for managing teaching workflows, including course initialization, exam creation, deployment, health checks, and semester management.

### What's New in v3.0

**🔍 Health Checks** - New `teach doctor` command validates your environment
**💾 Backup System** - Automated backups with retention policies
**📊 Enhanced Status** - Deployment status and backup summaries
**👁️ Deploy Preview** - See what changes before creating PR
**🎨 Scholar Templates** - Choose output templates for content generation
**📖 Lesson Plans** - Auto-load lesson-plan.yml for better context
**⚙️ Smart Init** - Load external configs and auto-create GitHub repos

---

## Quick Start

```bash
# Health check your teaching environment
teach doctor

# Initialize a new teaching project
teach init "STAT 440"

# Initialize with external config
teach init --config /path/to/config.yml

# Initialize and create GitHub repo
teach init "STAT 440" --github

# Show comprehensive status
teach status

# Deploy with preview
teach deploy

# Create content with template selection
teach exam "Midterm" --template typst
```

---

## Commands

### `teach doctor` 🆕

**Aliases:** None
**Purpose:** Validate teaching environment setup
**Version:** v5.14.0

Check your environment for all required and optional dependencies.

```bash
teach doctor                # Full health check
teach doctor --quiet        # Only show warnings/failures
teach doctor --fix          # Interactive install mode
teach doctor --json         # Machine-readable output
```

**Checks Performed:**

1. **Dependencies**
   - ✅ Required: yq, git, quarto, gh
   - ⚠️ Optional: examark, claude

2. **Project Configuration**
   - Config file exists (`.flow/teach-config.yml`)
   - Config validates against schema
   - Course name and semester set
   - Semester dates configured

3. **Git Setup**
   - Repository initialized
   - Draft branch exists
   - Production branch exists (main or production)
   - Remote configured
   - Working tree status

4. **Scholar Integration**
   - Claude Code available
   - Scholar skills accessible
   - Lesson plan file present (optional)

**Options:**

| Flag | Description |
|------|-------------|
| `--quiet`, `-q` | Only show warnings and failures (for CI/CD) |
| `--fix` | Interactive mode - offers to install missing dependencies |
| `--json` | JSON output for scripts and automation |
| `--help`, `-h` | Show help message |

**Exit Codes:**

- `0` - All checks passed (warnings OK)
- `1` - One or more checks failed

**Examples:**

```bash
# Basic health check
teach doctor

# CI/CD mode (only show problems)
teach doctor --quiet

# Scripting mode
teach doctor --json | jq '.summary.status'

# Interactive install
teach doctor --fix
```

**JSON Output Format:**

```json
{
  "summary": {
    "passed": 12,
    "warnings": 2,
    "failures": 0,
    "status": "healthy"
  },
  "checks": [
    {"check": "dep_yq", "status": "pass", "message": "4.35.1"},
    {"check": "config_exists", "status": "pass", "message": "exists"},
    {"check": "git_repo", "status": "pass", "message": "initialized"}
  ]
}
```

---

### `teach init`

**Aliases:** `teach i`
**Purpose:** Initialize a new teaching project
**Version:** v5.14.0 (Enhanced in v3.0)

Create a new teaching project with configuration, git setup, and directory structure.

```bash
teach init "Course Name"                       # Interactive mode
teach init "Course Name" --config FILE         # Load external config
teach init "Course Name" --github              # Create GitHub repo
teach init "Course Name" --config FILE --github  # Both options
```

**What it does:**

1. Creates `.flow/teach-config.yml` configuration
2. Sets up git repository (if not exists)
3. Creates draft and production branches
4. Creates directory structure (lectures/, exams/, etc.)
5. Optionally creates GitHub repository

**Options:**

| Flag | Description |
|------|-------------|
| `--config FILE` | Load configuration from external file 🆕 |
| `--github` | Automatically create GitHub repository 🆕 |
| `--help`, `-h` | Show help message |

**Configuration File (--config):**

Use an external YAML file as template:

```yaml
# template-config.yml
course:
  name: "STAT 440"
  full_name: "Regression Analysis"
  semester: "Spring"
  year: 2026
  instructor: "Dr. Smith"

semester_info:
  start_date: "2026-01-13"
  end_date: "2026-05-01"

branches:
  draft: draft
  production: main

backups:
  retention:
    assessments: archive
    lectures: semester
    syllabi: archive
```

Then:

```bash
teach init --config template-config.yml
```

**GitHub Integration (--github):**

Automatically creates and configures GitHub repository:

1. Creates repo via `gh repo create`
2. Sets up remote origin
3. Pushes initial commit
4. Requires `gh` CLI installed and authenticated

**Examples:**

```bash
# Standard interactive setup
teach init "STAT 440"

# Use department template
teach init "STAT 440" --config ~/templates/stats-course.yml

# Initialize and push to GitHub
teach init "STAT 440" --github

# Full automated setup
teach init "STAT 440" --config ~/templates/stats-course.yml --github
```

**Files Created:**

- `.flow/teach-config.yml` - Course configuration
- `.gitignore` - Teaching-specific patterns
- `README.md` - Course README
- Directory structure:
  - `lectures/`
  - `exams/`
  - `assignments/`
  - `quizzes/`
  - `slides/`
  - `syllabi/`
  - `rubrics/`

---

### `teach status`

**Aliases:** `teach s`
**Purpose:** Show comprehensive teaching project status
**Version:** v5.14.0 (Enhanced in v3.0)

Display current project status including git state, deployment info, and backup summaries.

```bash
teach status
```

**Output Sections:**

1. **Course Information**
   - Course name and semester
   - Current git branch
   - Safe-to-edit indicator

2. **Config Validation** ✅
   - Validation status
   - Schema version
   - Last validated timestamp

3. **Deployment Status** 🆕
   - Last deployment commit hash and message
   - Last deployment timestamp
   - Open PR count and details
   - Branch sync status (draft vs production)

4. **Backup Summary** 🆕
   - Total backup count across all content
   - Last backup timestamp
   - Backup breakdown by content type:
     - Exams (count, size)
     - Lectures (count, size)
     - Assignments (count, size)
     - etc.

5. **Content Inventory**
   - Count of lectures, exams, assignments
   - Recent additions

**Example Output:**

```
📚 Teaching Project Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Course:   STAT 440 - Regression Analysis
  Term:     Spring 2026
  Branch:   draft
  ✓ Safe to edit (draft branch)

Config Validation:
  ✓ Valid (v1.2.0)
  Last checked: 2 minutes ago

Deployment Status:
  Last deploy:  2026-01-18 14:30 (3 days ago)
  Commit:       a1b2c3d - "feat: add Week 5 lecture"
  Open PRs:     1 - #42: Week 6 content update

Backup Summary:
  Total backups:  12 across all content
  Last backup:    2026-01-18 10:15 (4 hours ago)

  By content type:
    • Exams:       3 backups (4.2 MB)
    • Lectures:    5 backups (8.1 MB)
    • Assignments: 4 backups (2.3 MB)

Content Inventory:
  • Lectures:    5
  • Exams:       2
  • Assignments: 4
```

---

### `teach deploy`

**Aliases:** `teach d`
**Purpose:** Deploy course website via PR workflow
**Version:** v5.14.0 (Enhanced in v3.0)

Deploy teaching content to production using pull request workflow with preview.

```bash
teach deploy              # Standard PR workflow with preview
teach deploy --direct-push # Bypass PR (advanced users)
```

**Workflow:**

1. **Pre-flight Checks**
   - Verify on draft branch
   - Check for uncommitted changes
   - Verify remote is up-to-date
   - Check for conflicts with production

2. **Changes Preview** 🆕
   - Shows all files changed since last deployment
   - Color-coded status indicators:
     - 🟢 `A` - Added files
     - 🔵 `M` - Modified files
     - 🔴 `D` - Deleted files
     - 🟡 `R` - Renamed files
   - File count summary
   - Optional: View full diff

3. **Pull Request Creation**
   - Auto-generates PR title and description
   - Lists all commits since last merge
   - Includes deployment checklist
   - Links to branch comparison on GitHub

**Options:**

| Flag | Description |
|------|-------------|
| `--direct-push` | Bypass PR workflow and push directly to production (advanced) |
| `--help`, `-h` | Show help message |

**Branch Configuration:**

Reads from `.flow/teach-config.yml`:

```yaml
branches:
  draft: draft           # Development branch
  production: main       # Production branch

git:
  require_clean: true    # Require clean working tree
  auto_pr: true          # Auto-create PR
```

**Changes Preview Example:**

```
📦 Changes Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files changed since last deployment:

  🟢 A lectures/week-05-multiple-regression.qmd
  🔵 M lectures/week-04-diagnostics.qmd
  🔵 M syllabi/schedule.qmd
  🔴 D _old/draft-notes.txt

Summary: 1 added, 2 modified, 1 deleted

View full diff? [y/N]
```

**Examples:**

```bash
# Standard deployment with preview
teach deploy

# Quick deployment (bypass preview)
teach deploy --direct-push

# After reviewing changes, create PR
teach deploy  # Answer 'y' to create PR
```

**Troubleshooting:**

| Error | Solution |
|-------|----------|
| "Not on draft branch" | Switch with `git checkout draft` |
| "Uncommitted changes" | Commit or stash changes first |
| "Conflicts detected" | Rebase with `git rebase main` |
| "Config not found" | Run `teach init` first |

---

### `teach exam`

**Aliases:** `teach e`
**Purpose:** Generate exam content
**Version:** v5.14.0 (Enhanced in v3.0)

Create exam content using Scholar plugin with enhanced context and templates.

```bash
teach exam "Exam Topic" [FLAGS]
```

**Scholar Integration:**

- Uses `scholar:teaching:exam` skill
- Auto-loads `lesson-plan.yml` if present 🆕
- Supports template selection 🆕
- Full context integration

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--questions N` | number | Number of questions |
| `--duration N` | number | Time limit in minutes |
| `--types LIST` | string | Question types (mc, short, essay) |
| `--format FORMAT` | choice | Output format (quarto, qti, markdown) |
| `--template NAME` | choice | Output template (typst, pdf, docx) 🆕 |
| `--dry-run` | flag | Preview without creating files |
| `--verbose` | flag | Show detailed progress |
| `--help`, `-h` | flag | Show help message |

**Template Options (--template):** 🆕

- `markdown` - Standard Markdown (default)
- `quarto` - Quarto document with YAML
- `typst` - Typst format for academic papers
- `pdf` - Direct PDF output
- `docx` - Microsoft Word format

**Examples:**

```bash
# Basic exam
teach exam "Midterm - Chapters 1-5"

# Exam with options
teach exam "Final Exam" \
  --questions 30 \
  --duration 120 \
  --types "mc,short,essay"

# Exam with Typst template
teach exam "Midterm" --template typst

# Preview without creating
teach exam "Quiz 1" --dry-run

# With lesson plan context
# (automatically loads lesson-plan.yml if present)
teach exam "Week 5 Quiz"
```

**Lesson Plan Integration:** 🆕

If `lesson-plan.yml` exists in the project root, Scholar will automatically use it for context:

```yaml
# lesson-plan.yml
course: STAT 440
semester: Spring 2026
weeks:
  - number: 5
    topic: "Multiple Regression"
    learning_objectives:
      - "Understand multicollinearity"
      - "Interpret regression coefficients"
    key_concepts:
      - "Adjusted R-squared"
      - "VIF (Variance Inflation Factor)"
```

---

### `teach quiz`

**Aliases:** `teach q`
**Purpose:** Generate quiz content
**Version:** v5.14.0 (Enhanced in v3.0)

Similar to `teach exam` but optimized for shorter assessments.

```bash
teach quiz "Quiz Topic" [FLAGS]
```

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--questions N` | number | Number of questions |
| `--time-limit N` | number | Time limit in minutes |
| `--format FORMAT` | choice | Output format (quarto, qti, markdown) |
| `--template NAME` | choice | Output template 🆕 |
| `--dry-run` | flag | Preview without creating files |
| `--verbose` | flag | Show detailed progress |
| `--help`, `-h` | flag | Show help message |

**Examples:**

```bash
# Basic quiz
teach quiz "Week 3 - Simple Regression"

# Timed quiz with specific format
teach quiz "Practice Quiz" \
  --questions 10 \
  --time-limit 15 \
  --format quarto

# With template
teach quiz "Quick Check" --template typst
```

---

### `teach assignment`

**Aliases:** `teach hw`
**Purpose:** Generate homework assignments
**Version:** v5.14.0 (Enhanced in v3.0)

Create homework assignments with Scholar integration.

```bash
teach assignment "Assignment Topic" [FLAGS]
```

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--due-date DATE` | date | Assignment due date |
| `--points N` | number | Total points possible |
| `--format FORMAT` | choice | Output format (quarto, markdown) |
| `--template NAME` | choice | Output template 🆕 |
| `--dry-run` | flag | Preview without creating files |
| `--verbose` | flag | Show detailed progress |
| `--help`, `-h` | flag | Show help message |

**Examples:**

```bash
# Basic assignment
teach assignment "Homework 3 - Diagnostics"

# Assignment with options
teach assignment "Problem Set 1" \
  --due-date "2026-02-15" \
  --points 100 \
  --format quarto

# With template
teach assignment "Homework 4" --template docx
```

---

### `teach slides`

**Aliases:** None
**Purpose:** Generate lecture slides
**Version:** v5.14.0 (Enhanced in v3.0)

Create presentation slides from lecture content.

```bash
teach slides "Slide Topic" [FLAGS]
```

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--theme THEME` | choice | Slide theme (default, academic, minimal) |
| `--from-lecture FILE` | string | Generate from existing lecture |
| `--format FORMAT` | choice | Output format (quarto, markdown) |
| `--template NAME` | choice | Output template 🆕 |
| `--dry-run` | flag | Preview without creating files |
| `--verbose` | flag | Show detailed progress |
| `--help`, `-h` | flag | Show help message |

**Examples:**

```bash
# Basic slides
teach slides "Week 5 - Multiple Regression"

# Generate from lecture
teach slides "Week 5 Slides" \
  --from-lecture lectures/week-05.qmd

# With custom theme and template
teach slides "Guest Lecture" \
  --theme academic \
  --template typst
```

---

### `teach lecture`

**Aliases:** `teach l`
**Purpose:** Generate lecture notes
**Version:** v5.14.0 (Enhanced in v3.0)

Create comprehensive lecture notes with Scholar.

```bash
teach lecture "Lecture Topic" [FLAGS]
```

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--week N` | number | Week number |
| `--format FORMAT` | choice | Output format (quarto, markdown) |
| `--template NAME` | choice | Output template 🆕 |
| `--dry-run` | flag | Preview without creating files |
| `--verbose` | flag | Show detailed progress |
| `--help`, `-h` | flag | Show help message |

**Examples:**

```bash
# Basic lecture
teach lecture "Multiple Regression"

# With week number
teach lecture "Diagnostics" --week 4

# With template
teach lecture "Final Review" --template quarto
```

---

### `teach syllabus`

**Aliases:** `teach syl`
**Purpose:** Generate course syllabus
**Version:** v5.14.0 (Enhanced in v3.0)

Create comprehensive course syllabus.

```bash
teach syllabus [FLAGS]
```

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--format FORMAT` | choice | Output format (quarto, markdown, pdf) |
| `--template NAME` | choice | Output template 🆕 |
| `--dry-run` | flag | Preview without creating files |
| `--verbose` | flag | Show detailed progress |
| `--help`, `-h` | flag | Show help message |

**Examples:**

```bash
# Basic syllabus
teach syllabus

# PDF output
teach syllabus --format pdf

# With template
teach syllabus --template docx
```

---

### `teach rubric`

**Aliases:** None
**Purpose:** Generate grading rubric
**Version:** v5.14.0 (Enhanced in v3.0)

Create grading rubrics for assignments and assessments.

```bash
teach rubric "Assignment Name" [FLAGS]
```

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--criteria N` | number | Number of criteria |
| `--format FORMAT` | choice | Output format (quarto, markdown) |
| `--template NAME` | choice | Output template 🆕 |
| `--dry-run` | flag | Preview without creating files |
| `--verbose` | flag | Show detailed progress |
| `--help`, `-h` | flag | Show help message |

**Examples:**

```bash
# Basic rubric
teach rubric "Homework 1"

# Detailed rubric
teach rubric "Final Project" \
  --criteria 5 \
  --format quarto

# With template
teach rubric "Essay Assignment" --template docx
```

---

### `teach feedback`

**Aliases:** None
**Purpose:** Generate student feedback
**Version:** v5.14.0

Provide constructive feedback for student work.

```bash
teach feedback "Student Name" [FLAGS]
```

**Examples:**

```bash
teach feedback "John Doe - HW3"
```

---

### `teach solution`

**Aliases:** None
**Purpose:** Generate solution keys
**Version:** v5.14.0

Create solution keys for assignments and exams.

```bash
teach solution "Assignment Name" [FLAGS]
```

**Examples:**

```bash
teach solution "Homework 3"
teach solution "Midterm Exam" --template typst
```

---

### `teach archive`

**Aliases:** `teach a`
**Purpose:** Archive completed semester
**Version:** v5.14.0 (Enhanced in v3.0)

Archive semester backups and clean up old content.

```bash
teach archive [SEMESTER_NAME]
```

**What it does:**

1. Moves backups to `.flow/archives/<semester>/`
2. Applies retention policies:
   - **Archive policy** - Moves to archive
   - **Semester policy** - Deletes after confirmation
3. Generates archive summary

**Examples:**

```bash
# Archive current semester
teach archive

# Archive specific semester
teach archive "Spring 2025"
```

**Archive Structure:**

```
.flow/archives/
└── Spring-2025/
    ├── exam-midterm-backups/
    ├── exam-final-backups/
    ├── lecture-week01-backups/
    └── ...
```

---

### `teach config`

**Aliases:** `teach c`
**Purpose:** Edit teaching configuration
**Version:** v5.14.0

Open teach-config.yml in your default editor.

```bash
teach config
```

Equivalent to:

```bash
${EDITOR:-code} .flow/teach-config.yml
```

---

### `teach week`

**Aliases:** `teach w`
**Purpose:** Show current week information
**Version:** v5.14.0

Display current week number and schedule.

```bash
teach week        # Current week
teach week 5      # Week 5 info
```

**Example Output:**

```
📅 Week 5 (Feb 12-18, 2026)

Topic: Multiple Regression

Scheduled Content:
  • Lecture: Week 5 - Multiple Regression
  • Assignment: Homework 4 (due Feb 18)
  • Office Hours: Wed 2-4pm
```

---

### `teach dates`

**Aliases:** None
**Purpose:** Date management commands
**Version:** v5.13.0

Manage semester dates and deadlines. See [Dates Quick Reference](TEACH-DATES-QUICK-REFERENCE.md) for details.

```bash
teach dates sync          # Sync dates from config
teach dates status        # Show date consistency
teach dates init          # Initialize date config
teach dates validate      # Validate date configuration
```

---

### `teach help`

**Aliases:** `--help`, `-h`
**Purpose:** Show help information
**Version:** v5.14.0

Display comprehensive help for the teach dispatcher.

```bash
teach help
teach --help
teach -h
```

---

## Backup System

### Overview

Teaching Workflow v3.0 introduces an automated backup system for all teaching content.

### Features

- **Timestamped Backups** - Every content modification creates a timestamped backup
- **Retention Policies** - Configure what to archive vs delete at semester end
- **Storage Efficiency** - Incremental backups, minimal disk usage
- **Easy Restore** - Quickly restore from any backup point

### Backup Location

```
content-folder/
└── .backups/
    ├── content-name.2026-01-18-1430/
    ├── content-name.2026-01-17-0915/
    └── content-name.2026-01-15-1620/
```

### Retention Policies

Configure in `.flow/teach-config.yml`:

```yaml
backups:
  retention:
    assessments: archive    # Keep exam/quiz backups forever
    lectures: semester      # Delete lecture backups at semester end
    syllabi: archive        # Keep syllabus backups forever
  archive_dir: .flow/archives
```

**Policy Options:**

- `archive` - Keep backups forever, move to archive at semester end
- `semester` - Delete backups at semester end after confirmation

### Backup Commands

```bash
# View backup summary
teach status   # Shows backup count and sizes

# Archive semester (respects retention policies)
teach archive "Spring 2025"

# Manual backup operations (advanced)
_teach_backup_content lectures/week-05.qmd
_teach_list_backups lectures/week-05.qmd
_teach_delete_backup <path> [--force]
```

### Safe Deletion

All backup deletions require confirmation:

```
⚠ Delete Backup?
────────────────────────────────────────────────
  Path:     lectures/week-05/.backups/week-05.2026-01-15-1620
  Name:     week-05.2026-01-15-1620
  Size:     1.2M
  Files:    15

⚠ This action cannot be undone!

Delete this backup? [y/N]
```

Use `--force` to skip confirmation (for scripts).

---

## Configuration

### Main Config File

`.flow/teach-config.yml` - Created by `teach init`

```yaml
# Course information
course:
  name: "STAT 440"
  full_name: "Regression Analysis"
  semester: Spring
  year: 2026
  instructor: "Dr. Smith"
  email: "smith@university.edu"

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

# Branch configuration
branches:
  draft: draft
  production: main

# Git workflow settings
git:
  require_clean: true
  auto_pr: true
  draft_branch: draft         # Legacy support
  production_branch: main     # Legacy support

# Workflow settings
workflow:
  teaching_mode: false
  auto_push: false

# Backup settings (v3.0)
backups:
  enabled: true
  retention:
    assessments: archive
    lectures: semester
    syllabi: archive
  archive_dir: .flow/archives
```

### Lesson Plan File (Optional)

`lesson-plan.yml` - Provides enhanced context to Scholar

```yaml
course: STAT 440
semester: Spring 2026
instructor: Dr. Smith

weeks:
  - number: 1
    topic: "Introduction to Regression"
    learning_objectives:
      - "Understand correlation vs causation"
      - "Learn simple linear regression"
    key_concepts:
      - "Least squares"
      - "R-squared"

  - number: 2
    topic: "Inference in Regression"
    learning_objectives:
      - "Hypothesis testing for coefficients"
      - "Confidence intervals"
    key_concepts:
      - "t-tests"
      - "Standard errors"
```

When present, Scholar commands automatically load this for better context.

---

## Workflow Examples

### Initial Setup

```bash
# 1. Create new teaching project
teach init "STAT 440 - Regression Analysis"

# 2. Verify environment
teach doctor

# 3. Create lesson plan (optional but recommended)
cat > lesson-plan.yml <<EOF
course: STAT 440
semester: Spring 2026
weeks:
  - number: 1
    topic: "Introduction"
EOF

# 4. Check status
teach status
```

### Weekly Content Creation

```bash
# Start of week
teach week              # See what's scheduled

# Create lecture
teach lecture "Week 5 - Multiple Regression" --week 5

# Create assignment
teach assignment "Homework 4" --due-date "2026-02-18"

# Create quiz
teach quiz "Week 5 Quiz" --questions 10

# Review and deploy
teach status
teach deploy
```

### End of Semester

```bash
# 1. Final deployment
teach deploy

# 2. Archive backups
teach archive "Spring 2025"

# 3. Verify archive
ls .flow/archives/Spring-2025/

# 4. Optional: Clean up
git worktree prune
```

---

## Troubleshooting

### Common Issues

**Issue:** `teach doctor` reports missing dependencies

```bash
# Option 1: Install manually
brew install yq gh quarto

# Option 2: Use --fix flag
teach doctor --fix
```

**Issue:** Config validation fails

```bash
# Check syntax
yq eval .flow/teach-config.yml

# Validate against schema
teach doctor --verbose
```

**Issue:** Deploy fails with conflicts

```bash
# Rebase onto production
git checkout draft
git fetch origin main
git rebase origin/main

# Resolve conflicts, then
teach deploy
```

**Issue:** Backup taking too much space

```bash
# View backup sizes
teach status

# Archive old semester
teach archive "Fall 2024"

# Manual cleanup (advanced)
rm -rf lectures/*/. backups/*2024*
```

---

## Related Commands

| Command | Purpose |
|---------|---------|
| `work teaching` | Start teaching session |
| `dash teach` | Teaching dashboard |
| `qu preview` | Preview Quarto site |
| `qu render` | Render course materials |
| `g status` | Git status |
| `g push` | Git push to remote |

---

## See Also

- [Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)
- [Backup System Guide](../guides/BACKUP-SYSTEM-GUIDE.md)
- [Teaching Dates Guide](../guides/TEACHING-DATES-GUIDE.md)
- [Scholar Enhancement API](SCHOLAR-ENHANCEMENT-API.md)
- [Quick Reference Card](REFCARD-TEACHING.md)

---

**Version:** v5.14.0 (Teaching Workflow v3.0)
**Last Updated:** 2026-01-18
