# Teaching Workflow v3.0 - Quick Reference Card

**Version:** flow-cli v5.14.0+
**Release:** 2026-01-18

---

## 🆕 What's New in v3.0

| Feature | Command | Description |
|---------|---------|-------------|
| **Health Checks** | `teach doctor` | Verify dependencies, config, git setup |
| **Enhanced Status** | `teach status` | See deployment status + backup summary |
| **Deploy Preview** | `teach deploy` | Preview changes before creating PR |
| **Backup System** | Auto-enabled | Timestamped backups with retention policies |
| **Scholar Templates** | `--template` flag | Customize output format |
| **Lesson Plans** | Auto-loaded | Context from `lesson-plan.yml` |
| **Init Flags** | `--config`, `--github` | Load external config, create repo |

---

## Essential Commands

### Health & Status

```bash
# Check teaching environment
teach doctor                    # Full health check
teach doctor --fix              # Interactive install missing deps
teach doctor --json             # Machine-readable output
teach doctor --quiet            # CI-friendly (errors only)

# View project status (ENHANCED v3.0)
teach status                    # Shows deployment + backups
teach week                      # Current week info
```

### Content Generation (Scholar Integration)

```bash
# Generate with template selection (NEW v3.0)
teach exam "Midterm" --template formal
teach quiz "Week 3" --template casual
teach lecture "Regression" --template slides

# Auto-loads lesson-plan.yml if present (NEW v3.0)
teach lecture "ANOVA"          # Uses lesson plan context

# Available Scholar commands
teach exam [topic]             # Generate exam
teach quiz [topic]             # Generate quiz
teach lecture [topic]          # Generate lecture
teach assignment [topic]       # Generate assignment
teach rubric [topic]           # Generate rubric
teach syllabus                 # Generate syllabus
teach slides [topic]           # Generate slides
teach feedback [student]       # Generate feedback
teach plan [course]            # Generate lesson plan
```

### Deployment Workflow

```bash
# Deploy with preview (ENHANCED v3.0)
teach deploy                   # Shows changes preview first
                               # Offers to view full diff
                               # Confirms before PR creation

# Check deployment status (NEW v3.0)
teach status                   # Shows last deploy + open PRs
```

### Project Setup

```bash
# Initialize with new flags (ENHANCED v3.0)
teach init "Course Name"                      # Basic init
teach init --config external.yml             # Load external config
teach init --github                          # Create GitHub repo
teach init --config course.yml --github      # Both options
```

---

## Backup System (NEW v3.0)

### Automatic Backups

Backups are created automatically before:
- Overwriting existing content
- Deleting content
- Semester archiving

**Location:** `.backups/<content-type>.<YYYY-MM-DD-HHMM>/`

**Example:**
```
exams/.backups/
├── midterm.2026-01-15-1430/
│   └── midterm.qmd
└── final.2026-01-18-0930/
    └── final.qmd
```

### Retention Policies

Configured in `.flow/teach-config.yml`:

```yaml
backups:
  retention:
    exams: archive        # Keep forever (archive per semester)
    quizzes: archive      # Keep forever
    lectures: semester    # Keep current semester only
    assignments: archive  # Keep forever
    syllabi: archive      # Keep forever
    rubrics: semester     # Keep current semester only
```

### Backup Commands

```bash
# List backups
ls exams/.backups/

# Restore a backup
cp exams/.backups/midterm.2026-01-15-1430/midterm.qmd exams/

# Delete old backups (with confirmation)
rm -rf exams/.backups/old-backup.*/

# Archive semester (handles retention automatically)
teach archive
```

---

## Scholar Template Selection (NEW v3.0)

All Scholar commands now support `--template` flag:

```bash
# Formal academic style
teach exam "Midterm" --template formal

# Casual conversational style
teach lecture "Intro" --template casual

# Slide-optimized format
teach slides "ANOVA" --template slides

# Custom template (if configured)
teach assignment "HW1" --template custom
```

**Available Templates:**
- `formal` - Academic, professional tone
- `casual` - Conversational, accessible
- `slides` - Optimized for presentations
- `custom` - User-defined templates

---

## Lesson Plan Auto-Loading (NEW v3.0)

Create `lesson-plan.yml` in your project root:

```yaml
course:
  code: STAT 440
  name: Regression Analysis
  semester: Spring 2026

topics:
  - week: 1
    topic: "Simple Linear Regression"
    objectives:
      - "Understand the concept of linear relationships"
      - "Fit a simple linear regression model"

  - week: 2
    topic: "Multiple Regression"
    objectives:
      - "Extend to multiple predictors"
      - "Interpret coefficients"
```

**Automatic Context:**
When `lesson-plan.yml` exists, all Scholar commands automatically include it as context:

```bash
# This command automatically loads lesson plan context
teach lecture "Simple Linear Regression"

# No need to specify context files manually
```

---

## teach doctor Health Checks (NEW v3.0)

### Check Categories

| Category | What's Checked |
|----------|----------------|
| **Dependencies** | yq, git, quarto, gh, examark, claude |
| **Configuration** | `.flow/teach-config.yml` validation |
| **Git Setup** | Repository, branches, remote, clean state |
| **Scholar** | Claude API availability |

### Usage Modes

```bash
# Interactive mode (default)
teach doctor
# Output: Colorful, detailed, user-friendly

# CI/CD mode
teach doctor --quiet
# Output: Errors only, exit code 0/1

# Machine-readable mode
teach doctor --json
# Output: JSON with status of each check

# Fix mode (interactive install)
teach doctor --fix
# Offers to install missing dependencies
```

### Example Output

```
📋 Teaching Environment Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dependencies:
  ✅ yq (4.35.1)
  ✅ git (2.42.0)
  ✅ quarto (1.4.550)
  ✅ gh (2.40.1)
  ❌ examark (not found)
  ✅ claude (available)

Configuration:
  ✅ .flow/teach-config.yml (valid)
  ✅ Schema validation passed

Git Setup:
  ✅ Repository initialized
  ✅ Draft branch (draft)
  ✅ Production branch (main)
  ⚠️  Uncommitted changes (3 files)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: ⚠️  Some issues found

Run with --fix to install missing dependencies.
```

---

## Enhanced teach status (ENHANCED v3.0)

### New Sections

#### Deployment Status
- Last deployment commit
- Open pull requests
- PR status and age

#### Backup Summary
- Total backup count
- Last backup timestamp
- Breakdown by content type

### Example Output

```
📊 Teaching Project Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Course Info:
  Name:     STAT 440 - Regression Analysis
  Semester: Spring 2026
  Week:     3 of 16

🚀 Deployment Status:                      ← NEW v3.0
  Last Deploy:  abc1234 Publish week 3 content (2 days ago)
  Open PRs:     1 (feat: Add week 4 materials - #42)

💾 Backup Summary:                         ← NEW v3.0
  Total Backups: 12
  Last Backup:   2026-01-18 14:30 (exams/midterm)
  Breakdown:
    - exams: 3 backups
    - lectures: 5 backups
    - quizzes: 4 backups

Recent Content:
  - lectures/week3-multiple-regression.qmd (modified 2 hours ago)
  - assignments/hw3.qmd (modified yesterday)

Git Status:
  Branch: draft (3 commits ahead of production)
  Clean: No (2 uncommitted changes)
```

---

## Enhanced teach deploy (ENHANCED v3.0)

### Changes Preview

Before creating a PR, `teach deploy` now shows:

1. **Files Changed Summary**
   - Modified (M), Added (A), Deleted (D), Renamed (R)
   - Color-coded for easy scanning

2. **Full Diff Option**
   - View complete diff before proceeding
   - Uses pager (delta/less) for large diffs

3. **Confirmation Prompt**
   - Confirm before PR creation
   - Cancel if changes need review

### Example Workflow

```bash
$ teach deploy

📋 Changes Preview                         ← NEW v3.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files Changed (draft → production):
  M  lectures/week4-inference.qmd
  M  assignments/hw4.qmd
  A  quizzes/quiz4.qmd
  M  _quarto.yml

View full diff? [y/N]: y
(Shows full diff with pager)

Create PR with these changes? [y/N]: y
✅ PR created: https://github.com/user/course/pull/45
```

---

## Migration from v2.x to v3.0

### Breaking Changes

❌ **Removed:**
- Standalone `commands/teach-init.zsh` (now in dispatcher)

✅ **Enhanced (backward compatible):**
- `teach status` - New sections, old functionality intact
- `teach deploy` - Preview added, old workflow works
- `teach init` - New flags optional, old usage works
- All Scholar commands - `--template` flag optional

### Migration Steps

1. **Update flow-cli:**
   ```bash
   antidote update
   # or
   zinit update Data-Wise/flow-cli
   ```

2. **Run health check:**
   ```bash
   teach doctor
   teach doctor --fix  # Install missing dependencies
   ```

3. **Review new features:**
   ```bash
   teach status        # See new deployment/backup sections
   teach deploy        # Try new preview workflow
   teach help          # Check updated help
   ```

4. **Optional: Configure backups:**
   ```bash
   # Edit .flow/teach-config.yml
   # Add retention policies (defaults are safe)
   ```

5. **Optional: Add lesson plan:**
   ```bash
   # Create lesson-plan.yml
   # All Scholar commands will auto-load it
   ```

### No Action Required

- Existing workflows continue to work
- Backups are automatic (safe defaults)
- New features are opt-in via flags

---

## Configuration Reference

### .flow/teach-config.yml (v3.0 Schema)

```yaml
course:
  name: "STAT 440 - Regression Analysis"
  semester: "Spring 2026"
  year: 2026
  instructor: "Dr. Smith"

git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  pr_template: ".github/pull_request_template.md"

backups:                              # NEW v3.0
  gitignore: true                     # Add .backups/ to .gitignore
  retention:
    exams: archive                    # archive = keep forever
    quizzes: archive
    lectures: semester                # semester = current only
    assignments: archive
    syllabi: archive
    rubrics: semester
    slides: semester
  archive_dir: ".flow/archives"       # Archive location

scholar:                              # ENHANCED v3.0
  default_template: formal            # Default template
  custom_templates:                   # Custom templates
    slides: "path/to/slides.md"
    handout: "path/to/handout.md"
  auto_load_lesson_plan: true         # Auto-load lesson-plan.yml
  context_files:                      # Additional context files
    - "lesson-plan.yml"
    - "course-info.md"

dates:
  semester_start: "2026-01-20"
  semester_end: "2026-05-15"
  breaks:
    - start: "2026-03-09"
      end: "2026-03-13"
      name: "Spring Break"
```

---

## Troubleshooting

### teach doctor Issues

**Problem:** `examark not found`
```bash
# Install examark
npm install -g @data-wise/examark

# Or use --fix flag
teach doctor --fix
```

**Problem:** `Config validation failed`
```bash
# Check config syntax
yq eval .flow/teach-config.yml

# Use default config
teach init "Course Name"  # Regenerates config
```

### Backup Issues

**Problem:** Too many backups
```bash
# Backups are cleaned automatically based on retention policy
# For semester content, old backups are removed on archive

# Manual cleanup (with confirmation)
teach archive  # Cleans semester backups automatically
```

**Problem:** Backup not created
```bash
# Backups are created automatically before overwrites
# Check .backups/ directory exists:
ls -la lectures/.backups/

# If missing, it will be created on next overwrite
```

### Deploy Preview Issues

**Problem:** Diff too large
```bash
# Preview shows summary by default
# Full diff is optional (press 'n' to skip)

# Or use git directly
git diff production..draft
```

---

## See Also

### Documentation

- [TEACH-DISPATCHER-REFERENCE-v3.0.md](TEACH-DISPATCHER-REFERENCE-v3.0.md) - Complete v3.0 API reference
- [TEACHING-WORKFLOW-V3-GUIDE.md](../guides/TEACHING-WORKFLOW-V3-GUIDE.md) - Comprehensive v3.0 guide
- [BACKUP-SYSTEM-GUIDE.md](../guides/BACKUP-SYSTEM-GUIDE.md) - Backup system deep dive
- [SCHOLAR-INTEGRATION.md](../guides/SCHOLAR-INTEGRATION.md) - Scholar integration guide
- [TEACHING-COMMANDS-DETAILED.md](../guides/TEACHING-COMMANDS-DETAILED.md) - Detailed command usage

### Related Commands

- `flow doctor` - Check flow-cli installation
- `pick` - Project picker (alternative to `work`)
- `dash` - Project dashboard
- `g` - Git workflows

---

**Teaching Workflow v3.0** | flow-cli v5.14.0+ | Released 2026-01-18
