# Teaching Workflow v3.0 Guide

**Version:** v5.14.0
**Last Updated:** 2026-01-18
**Target Audience:** Instructors using flow-cli for course management

---

## Table of Contents

1. [Overview](#overview)
2. [What's New in v3.0](#whats-new-in-v30)
3. [Getting Started](#getting-started)
4. [Health Checks](#health-checks)
5. [Content Creation Workflow](#content-creation-workflow)
6. [Deployment Workflow](#deployment-workflow)
7. [Backup Management](#backup-management)
8. [End of Semester](#end-of-semester)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Overview

Teaching Workflow v3.0 provides a complete solution for managing course content from creation to deployment, with automated backups, health monitoring, and safe deployment previews.

### Design Philosophy

- **Safety First** - Preview changes before deploying, backup before modifying
- **Context-Aware** - Auto-load lesson plans for better Scholar integration
- **ADHD-Friendly** - Clear status, visual feedback, minimal cognitive load
- **Automated** - Backups happen automatically, retention policies apply at semester end

---

## What's New in v3.0

### 1. Environment Health Checks

```bash
teach doctor
```

Validates your entire teaching environment:
- Required dependencies (yq, git, quarto, gh)
- Optional tools (examark, claude)
- Project configuration
- Git setup (branches, remote)
- Scholar integration

**Why it matters:** Catch setup issues before they cause problems during content creation.

### 2. Automated Backup System

Every content modification creates a timestamped backup:

```
lectures/week-05-regression.qmd
lectures/.backups/
  └── week-05-regression.2026-01-18-1430/
  └── week-05-regression.2026-01-17-0915/
  └── week-05-regression.2026-01-15-1620/
```

**Retention policies:**
- **Archive** - Keep forever, move to `.flow/archives/` at semester end
- **Semester** - Delete at semester end (with confirmation)

**Why it matters:** Accidentally deleted a paragraph? Restore from any backup point in seconds.

### 3. Enhanced Status Dashboard

![teach status demo](../demos/tutorials/tutorial-teach-status.gif)

*Demo: Enhanced status showing comprehensive project overview*

```bash
teach status
```

Shows everything at a glance:
- Course and semester info
- Current branch (draft/production)
- Config validation status
- **Deployment status** - Last deploy commit, open PRs
- **Backup summary** - Total backups, sizes, last backup time
- Content inventory

**Why it matters:** Complete situational awareness in one command.

### 4. Deploy Preview

```bash
teach deploy
```

Before creating a PR, see exactly what changed:

```
📦 Changes Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files changed since last deployment:

  🟢 A lectures/week-05-multiple-regression.qmd
  🔵 M lectures/week-04-diagnostics.qmd
  🔴 D _old/draft-notes.txt

Summary: 1 added, 2 modified, 1 deleted

View full diff? [y/N]
```

**Why it matters:** No surprises. Know exactly what students will see.

### 5. Scholar Template Selection

![Scholar integration demo](../demos/tutorials/tutorial-scholar-integration.gif)

*Demo: Using Scholar with templates and lesson plan auto-loading*

```bash
teach exam "Midterm" --template typst
teach assignment "HW4" --template docx
```

Choose output format for generated content:
- `markdown` - Standard Markdown (default)
- `quarto` - Quarto document
- `typst` - Academic paper format
- `pdf` - Direct PDF output
- `docx` - Microsoft Word format

**Why it matters:** Generate content in your preferred format without manual conversion.

### 6. Lesson Plan Integration

Create `lesson-plan.yml` in your project root:

```yaml
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
      - "VIF"
```

Scholar commands automatically load this for enhanced context.

**Why it matters:** More targeted, course-specific content generation.

### 7. Smart Initialization

```bash
# Load departmental template
teach init --config ~/templates/stats-course.yml

# Create and push to GitHub in one step
teach init "STAT 440" --github
```

**Why it matters:** Faster setup, consistent configuration across courses.

---

## Getting Started

### Step 1: Verify Environment

Before creating your first course:

```bash
teach doctor
```

If any checks fail:

```bash
# Interactive install mode
teach doctor --fix

# Manual install
brew install yq gh quarto
```

### Step 2: Initialize Course

![teach init demo](../demos/tutorials/tutorial-teach-init.gif)

*Demo: Initializing a new teaching project with teach init*

```bash
# Interactive mode (recommended for first time)
teach init "STAT 440 - Regression Analysis"

# Or use a template
teach init "STAT 440" --config ~/templates/stats-course.yml

# With GitHub repo creation
teach init "STAT 440" --github
```

**What gets created:**

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

### Step 3: Create Lesson Plan (Optional but Recommended)

```bash
cat > lesson-plan.yml <<EOF
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
      - "Residuals"
EOF
```

Scholar will automatically use this for enhanced context.

### Step 4: Verify Setup

```bash
teach status
```

Expected output:

```
📚 Teaching Project Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Course:   STAT 440 - Regression Analysis
  Term:     Spring 2026
  Branch:   draft
  ✓ Safe to edit (draft branch)

Config Validation:
  ✓ Valid (v1.2.0)

Content Inventory:
  • Lectures:    0
  • Exams:       0
  • Assignments: 0
```

---

## Health Checks

![teach doctor demo](../demos/tutorials/tutorial-teach-doctor.gif)

*Demo: Running teach doctor to validate teaching environment*

### When to Run

- **Initial setup** - Before creating content
- **Semester start** - Verify environment ready
- **After system updates** - Check dependencies still work
- **Troubleshooting** - Diagnose issues

### Basic Health Check

```bash
teach doctor
```

Output:

```
╭────────────────────────────────────────────────────────────╮
│  📚 Teaching Environment Health Check                       │
╰────────────────────────────────────────────────────────────╯

Dependencies:
  ✓ yq (4.35.1)
  ✓ git (2.43.0)
  ✓ quarto (1.4.550)
  ✓ gh (2.42.1)
  ⚠ examark (not found - optional)
  ✓ claude (2.1.12)

Project Configuration:
  ✓ .flow/teach-config.yml exists
  ✓ Config validates against schema
  ✓ Course name: STAT 440
  ✓ Semester: Spring 2026
  ✓ Dates configured (2026-01-13 - 2026-05-01)

Git Setup:
  ✓ Git repository initialized
  ✓ Draft branch exists
  ✓ Production branch exists: main
  ✓ Remote configured: origin
  ✓ Working tree clean

Scholar Integration:
  ✓ Claude Code available
  ⚠ Scholar skills not detected
  ✓ Lesson plan found: lesson-plan.yml

────────────────────────────────────────────────────────────
Summary: 15 passed, 2 warnings, 0 failures
────────────────────────────────────────────────────────────
```

### CI/CD Mode

For scripts and automation:

```bash
# Only show problems
teach doctor --quiet

# Machine-readable output
teach doctor --json | jq '.summary.status'
```

### Interactive Fix Mode

```bash
teach doctor --fix
```

Offers to install missing dependencies interactively.

---

## Content Creation Workflow

### Weekly Pattern

**Monday:** Plan week's content

```bash
# Check current week
teach week

# View lesson plan
cat lesson-plan.yml | yq ".weeks[] | select(.number == 5)"
```

**Tuesday-Thursday:** Create content

```bash
# Create lecture
teach lecture "Multiple Regression" --week 5

# Content is automatically backed up
# Scholar auto-loads lesson-plan.yml for context
```

**Friday:** Create assessments

```bash
# Create quiz
teach quiz "Week 5 Quiz" --questions 10 --time-limit 15

# Create homework
teach assignment "Homework 4" \
  --due-date "2026-02-18" \
  --points 100
```

**Weekend:** Review and deploy

```bash
# Check status
teach status

# Deploy with preview
teach deploy
```

### Creating Exams

**Midterm exam:**

```bash
teach exam "Midterm - Chapters 1-5" \
  --questions 30 \
  --duration 120 \
  --types "mc,short,essay" \
  --template typst
```

**What happens:**

1. Scholar loads `lesson-plan.yml` for context
2. Generates exam in `exams/midterm.typ`
3. Creates timestamped backup in `exams/.backups/`
4. Offers to commit with auto-generated message

**Final exam:**

```bash
teach exam "Final Exam - Comprehensive" \
  --questions 50 \
  --duration 180 \
  --format quarto
```

### Creating Assignments

```bash
teach assignment "Problem Set 3 - Diagnostics" \
  --due-date "2026-03-01" \
  --points 100 \
  --template docx
```

**Scholar will include:**

- Problem statements from lesson plan
- Relevant course concepts
- Grading criteria
- Due date in YAML frontmatter

### Creating Lecture Materials

**Lecture notes:**

```bash
teach lecture "Collinearity and VIF" --week 6
```

**Slides from lecture:**

```bash
teach slides "Week 6 Slides" \
  --from-lecture lectures/week-06-collinearity.qmd \
  --theme academic
```

**Guest lecture (custom styling):**

```bash
teach slides "Guest: Machine Learning in Stats" \
  --theme minimal \
  --template typst
```

### Template Selection Guide

| Format | Use Case | Command |
|--------|----------|---------|
| `markdown` | Web content, GitHub | Default |
| `quarto` | Academic papers, reports | `--template quarto` |
| `typst` | LaTeX alternative, clean PDFs | `--template typst` |
| `pdf` | Direct PDF generation | `--template pdf` |
| `docx` | Sharing with non-technical collaborators | `--template docx` |

---

## Deployment Workflow

![teach deploy demo](../demos/tutorials/tutorial-teach-deploy.gif)

*Demo: Deploying to preview branch with teach deploy --preview*

### Overview

Teaching Workflow v3.0 uses a **draft → production** PR-based workflow:

1. Work on `draft` branch
2. Preview changes before deploying
3. Create PR (draft → main/production)
4. Review and merge on GitHub
5. Site automatically rebuilds

### Standard Deployment

```bash
# 1. Check current status
teach status

# 2. Ensure on draft branch
git checkout draft

# 3. Commit any changes
g status
g commit "feat: add Week 6 content"

# 4. Deploy with preview
teach deploy
```

### Deploy Preview

```
📦 Changes Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files changed since last deployment:

  🟢 A lectures/week-06-collinearity.qmd
  🟢 A assignments/homework-05.qmd
  🔵 M syllabi/schedule.qmd
  🔵 M _quarto.yml
  🔴 D _old/scratch.txt

Summary: 2 added, 2 modified, 1 deleted

View full diff? [y/N]
```

**Options:**

- `y` - View full diff with syntax highlighting
- `n` - Skip and proceed to PR creation

### Pull Request Creation

After preview, PR is automatically created:

```
✓ Pull request created: #42
  Title: Week 6 content deployment
  URL: https://github.com/user/course/pull/42

Commits included:
  • a1b2c3d - feat: add Week 6 lecture on collinearity
  • e4f5g6h - feat: add Homework 5
  • i7j8k9l - docs: update schedule

Review and merge on GitHub when ready.
```

### Pre-flight Checks

`teach deploy` automatically checks:

1. ✅ On draft branch
2. ✅ No uncommitted changes
3. ✅ Remote up-to-date
4. ✅ No conflicts with production

If any check fails, you'll get clear instructions:

```
✗ Error: Uncommitted changes detected

You have 3 uncommitted files:
  M lectures/week-06.qmd
  M _quarto.yml
  ?? scratch.txt

→ Commit or stash changes first:
    g commit "your message"
    g stash
```

### Direct Push (Advanced)

Bypass PR workflow for hotfixes:

```bash
teach deploy --direct-push
```

⚠️ **Warning:** Use sparingly. PR workflow provides:
- Change review before going live
- Deployment history
- Rollback capability

---

## Backup Management

![Backup system demo](../demos/tutorials/tutorial-backup-system.gif)

*Demo: Automated backup system with retention policies*

### How Backups Work

**Automatic backups:**

Every time you modify content (via Scholar or manual edit), a backup is created:

```
lectures/week-05.qmd
lectures/.backups/
  └── week-05.2026-01-18-1430/  # Latest
  └── week-05.2026-01-17-0915/  # Yesterday
  └── week-05.2026-01-15-1620/  # Last week
```

**Retention policies:**

Configure in `.flow/teach-config.yml`:

```yaml
backups:
  retention:
    assessments: archive    # Keep exam/quiz backups
    lectures: semester      # Delete at semester end
    syllabi: archive        # Keep syllabus backups
```

### View Backup Status

```bash
teach status
```

Output includes:

```
Backup Summary:
  Total backups:  12 across all content
  Last backup:    2026-01-18 10:15 (4 hours ago)

  By content type:
    • Exams:       3 backups (4.2 MB)
    • Lectures:    5 backups (8.1 MB)
    • Assignments: 4 backups (2.3 MB)
```

### Restore from Backup

**Manual restore:**

```bash
# 1. Find backup you want
ls -lt lectures/.backups/

# 2. Copy content back
cp -R lectures/.backups/week-05.2026-01-15-1620/* \
      lectures/week-05.qmd
```

**Using git (if backed up):**

```bash
# Find when file was good
git log --oneline lectures/week-05.qmd

# Restore specific version
git checkout <commit-hash> lectures/week-05.qmd
```

### Delete Old Backups

**Safe deletion (with confirmation):**

```bash
# Will prompt before deleting
rm -rf lectures/.backups/week-05.2026-01-15-1620
```

**Force deletion (scripts):**

```bash
_teach_delete_backup lectures/.backups/week-05.2026-01-15-1620 --force
```

### Archive at Semester End

```bash
teach archive "Spring 2025"
```

**What happens:**

1. Applies retention policies:
   - **Archive** - Moves to `.flow/archives/Spring-2025/`
   - **Semester** - Deletes after confirmation

2. Generates summary:

```
✓ Archive complete: .flow/archives/Spring-2025

  Archived: 8 content folders
  Deleted:  5 content folders (semester retention)
```

---

## End of Semester

### Checklist

- [ ] Deploy final content
- [ ] Grade and release final exams
- [ ] Archive backups
- [ ] Update `.STATUS` files
- [ ] Create semester tag
- [ ] Prepare for next semester

### Step-by-Step

**1. Final deployment**

```bash
# Check everything is committed
g status

# Deploy
teach deploy

# Verify PR merged
gh pr list --state merged
```

**2. Archive backups**

```bash
teach archive "Spring 2025"
```

**3. Create semester tag**

```bash
# Tag final state
git tag -a spring-2025-final -m "End of Spring 2025 semester"
git push origin spring-2025-final
```

**4. Update .STATUS**

```yaml
# .STATUS
status: complete
progress: 100
archived: 2025-05-15
next_semester: Fall 2025
notes: |
  Spring 2025 semester complete.
  Archive: .flow/archives/Spring-2025
```

**5. Prepare for next semester**

```bash
# Update config for new semester
teach config

# Update these fields:
#   course.semester: Fall
#   course.year: 2025
#   semester_info.start_date: 2025-08-25

# Initialize dates
teach dates init
```

---

## Best Practices

### 1. Use Lesson Plans

**Create at semester start:**

```yaml
# lesson-plan.yml
course: STAT 440
semester: Spring 2026

weeks:
  - number: 1
    topic: "Introduction"
    learning_objectives: [...]
    key_concepts: [...]
```

**Benefits:**

- Scholar generates more targeted content
- Consistent terminology across materials
- Easy to revise and reuse

### 2. Regular Health Checks

```bash
# Weekly check (Friday before deploy)
teach doctor --quiet

# Monthly full check
teach doctor
```

### 3. Commit Often

```bash
# After creating each piece of content
g commit "feat: add Week 5 lecture"
g commit "feat: add Homework 4"

# Not this
g commit "added a bunch of stuff"
```

**Why:** Easy to track what changed, revert if needed.

### 4. Preview Before Deploy

```bash
# Always review changes
teach deploy   # Don't skip the preview!
```

### 5. Backup Configuration

**Conservative settings (default):**

```yaml
backups:
  retention:
    assessments: archive   # Safe: keep forever
    lectures: archive      # Safe: keep forever
    syllabi: archive       # Safe: keep forever
```

**Aggressive settings (if disk space limited):**

```yaml
backups:
  retention:
    assessments: archive   # Keep exams
    lectures: semester     # Delete lecture backups
    syllabi: archive       # Keep syllabus
```

### 6. Use Templates

**Department template:**

```yaml
# ~/templates/stats-course.yml
course:
  department: "Statistics"
  level: "400"
  credits: 3
  instructor: "Dr. Smith"

branches:
  draft: draft
  production: main

backups:
  retention:
    assessments: archive
    lectures: semester
    syllabi: archive
```

**Use it:**

```bash
teach init "STAT 440" --config ~/templates/stats-course.yml
```

---

## Troubleshooting

### teach doctor Fails

**Issue:** Missing dependencies

```bash
# View what's missing
teach doctor

# Install missing tools
brew install yq gh quarto

# Verify fix
teach doctor
```

**Issue:** Config validation fails

```bash
# Check syntax
yq eval .flow/teach-config.yml

# View schema
cat lib/templates/teaching/teach-config.schema.json

# Common issues:
# - Invalid date format (use YYYY-MM-DD)
# - Missing required fields (course.name, semester_info)
# - Invalid YAML syntax
```

### teach deploy Fails

**Issue:** Not on draft branch

```bash
# Switch to draft
git checkout draft

# Try again
teach deploy
```

**Issue:** Uncommitted changes

```bash
# View changes
g status

# Commit
g commit "your message"

# Or stash
g stash
```

**Issue:** Conflicts with production

```bash
# Fetch latest
git fetch origin main

# Rebase
git rebase origin/main

# Resolve conflicts
# Edit conflicted files
g add .
git rebase --continue

# Deploy
teach deploy
```

**Issue:** Config file not found

```bash
# Initialize project
teach init "Course Name"

# Verify
ls -la .flow/teach-config.yml
```

### Backup Issues

**Issue:** Backups taking too much space

```bash
# View sizes
teach status

# Archive old semester
teach archive "Fall 2024"

# Or manual cleanup
rm -rf lectures/.backups/*2024*
```

**Issue:** Can't restore backup

```bash
# Verify backup exists
ls -la lectures/.backups/

# Check permissions
ls -ld lectures/.backups/

# Restore manually
cp -R lectures/.backups/week-05.LATEST/* lectures/
```

### Scholar Integration Issues

**Issue:** Lesson plan not loading

```bash
# Verify file exists
ls -la lesson-plan.yml

# Check syntax
yq eval lesson-plan.yml

# Validate against schema
teach doctor
```

**Issue:** Scholar not generating context-aware content

```bash
# Check Scholar installed
teach doctor

# Verify lesson plan format
cat lesson-plan.yml

# Try explicit context
teach exam "Topic" --context
```

---

## Advanced Usage

### Automation Scripts

**Weekly deployment script:**

```bash
#!/usr/bin/env zsh
# weekly-deploy.sh

# Health check
teach doctor --quiet || exit 1

# Ensure clean state
if [[ -n "$(git status --porcelain)" ]]; then
  g commit "feat: week $(date +%V) content"
fi

# Deploy
teach deploy --dry-run

# Prompt for confirmation
read -q "REPLY?Deploy to production? [y/N] "
[[ "$REPLY" = "y" ]] && teach deploy
```

**Backup verification script:**

```bash
#!/usr/bin/env zsh
# verify-backups.sh

# Get backup summary
summary=$(teach status | grep -A 10 "Backup Summary")

# Check backup count
count=$(echo "$summary" | grep "Total backups" | awk '{print $3}')

if (( count < 5 )); then
  echo "⚠️ Warning: Only $count backups found"
  echo "Expected at least 5 backups"
  exit 1
fi

echo "✓ Backup verification passed: $count backups"
```

### Custom Workflows

**Exam creation workflow:**

```bash
# 1. Create exam
teach exam "Midterm" --template typst --dry-run

# 2. Review generated content
# Edit if needed

# 3. Create solution key
teach solution "Midterm" --template typst

# 4. Create rubric
teach rubric "Midterm" --criteria 5

# 5. Commit all together
g add exams/
g commit "feat: add midterm exam with solutions and rubric"
```

**Lecture workflow:**

```bash
# 1. Create lecture notes
teach lecture "Topic" --week N

# 2. Generate slides
teach slides "Topic Slides" \
  --from-lecture lectures/week-N-topic.qmd

# 3. Create practice problems
teach assignment "Practice Problems N" \
  --points 0  # Ungraded

# 4. Deploy together
g commit "feat: complete Week N materials"
teach deploy
```

---

## Migration Guide

### From v2.x to v3.0

**No breaking changes!** v3.0 is fully backward compatible.

**New features to adopt:**

1. **Run health check:**

```bash
teach doctor
```

2. **Enable backups:**

Already enabled by default! Check status:

```bash
teach status  # See "Backup Summary" section
```

3. **Configure retention policies:**

Edit `.flow/teach-config.yml`:

```yaml
backups:
  retention:
    assessments: archive
    lectures: semester   # New option
    syllabi: archive
```

4. **Create lesson plan (optional):**

```bash
cat > lesson-plan.yml <<EOF
course: STAT 440
semester: Spring 2026
weeks:
  - number: 1
    topic: "Introduction"
EOF
```

5. **Use new features:**

```bash
# Deploy preview
teach deploy   # Now shows changes preview

# Template selection
teach exam "Test" --template typst

# External config
teach init --config template.yml
```

**That's it!** All existing workflows continue to work.

---

## Reference

- [Teach Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE-v3.0.md)
- [Backup System Guide](BACKUP-SYSTEM-GUIDE.md)
- [Migration Guide](TEACHING-V3-MIGRATION-GUIDE.md)
- [Quick Reference Card](../reference/REFCARD-TEACHING-V3.md)

---

**Version:** v5.14.0 (Teaching Workflow v3.0)
**Last Updated:** 2026-01-18
