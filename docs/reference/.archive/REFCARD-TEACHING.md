# Teaching Workflow - Quick Reference Card

**Version:** 2.1 | **Last Updated:** 2026-01-12

---

## 🚀 Quick Start (3 Steps)

```bash
# 1. Initialize (interactive)
cd ~/teaching/my-course
teach-init "Course Name"

# 1b. Or non-interactive (accept defaults)
teach-init -y "Course Name"

# 2. Start working
work course-name

# 3. Deploy
./scripts/quick-deploy.sh
```diff

**Result:** Typo to live in < 2 minutes

---

## 📋 Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `teach-init <name>` | Initialize teaching workflow | `teach-init "STAT 545"` |
| `teach-init -y <name>` | Initialize (non-interactive) | `teach-init -y "STAT 545"` |
| `teach-init --dry-run <name>` | Preview migration plan | `teach-init --dry-run "STAT 545"` |
| `work <course>` | Start teaching session | `work stat-545` |
| `./scripts/quick-deploy.sh` | Deploy draft → production | `./scripts/quick-deploy.sh` |
| `./scripts/semester-archive.sh` | Archive semester | `./scripts/semester-archive.sh` |
| `teach-exam <topic>` | Create exam template (optional) | `teach-exam "Midterm 1"` |
| `./scripts/exam-to-qti.sh <file>` | Convert to Canvas QTI (optional) | `./scripts/exam-to-qti.sh exams/midterm1.md` |

---

## 🔑 Auto-Loaded Shortcuts

Shortcuts are **loaded automatically** when you run `work <course>`:

| Shortcut | Action | Configured In |
|----------|--------|---------------|
| `{slug}` | `work <course>` | `.flow/teach-config.yml` |
| `{slug}d` | `./scripts/quick-deploy.sh` | `.flow/teach-config.yml` |

**Example:**

```yaml
# .flow/teach-config.yml
shortcuts:
  s545: "work stat-545"
  s545d: "./scripts/quick-deploy.sh"
```text

**Usage:**

```bash
work stat-545   # Loads shortcuts
s545d           # Deploy (shortcut active!)
```yaml

---

## ⚙️ Configuration (.flow/teach-config.yml)

### Required Fields

```yaml
course:
  name: "STAT 545"                    # Display name

branches:
  draft: "draft"                      # Edit here
  production: "production"            # Students see this
```yaml

### Optional Fields

```yaml
course:
  full_name: "Design of Experiments"
  semester: "spring"                  # spring|summer|fall
  year: 2026
  instructor: "Your Name"

# Increment 2: Semester scheduling for week calculation
semester_info:
  start_date: "2026-01-13"            # YYYY-MM-DD format
  end_date: "2026-05-05"              # Auto-calculated: 16 weeks
  breaks:
    - name: "Spring Break"
      start: "2026-03-10"
      end: "2026-03-17"

deployment:
  web:
    type: "github-pages"
    branch: "production"
    url: "https://example.com/course"

automation:
  quick_deploy: "scripts/quick-deploy.sh"

shortcuts:
  s545: "work stat-545"               # Custom shortcuts
  s545d: "./scripts/quick-deploy.sh"
```text

---

## 📁 File Structure

```bash
my-course/
├── .flow/
│   └── teach-config.yml           # Course configuration
│
├── scripts/
│   ├── quick-deploy.sh            # Deployment automation
│   └── semester-archive.sh        # Semester archival
│
├── .github/workflows/
│   └── deploy.yml                 # GitHub Actions
│
└── [course content]
```text

---

## 🌿 Branch Workflow

```text
draft          →  Edit, commit, test
   ↓
production     →  Students see (deployed via GitHub Pages)
   ↓
Live Website   →  Auto-deployed by GitHub Actions
```bash

**Rule:** Always edit on `draft` branch!

**Safety:** `work` command warns if on `production`

---

## 🔄 Daily Workflow

```bash
# 1. Start session (branch check happens automatically)
work stat-545

# 2. Edit files
# Make changes in editor...

# 3. Commit
git add .
git commit -m "Fix typo"

# 4. Deploy (using shortcut)
s545d

# Total time: < 2 min
```yaml

---

## ⚠️ Branch Safety

### On Production Branch (Warning)

```bash
$ work stat-545

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  WARNING: You are on PRODUCTION branch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Branch: production
  Students see this branch!

  Recommended: Switch to draft branch for edits
  Draft branch: draft

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Continue on production anyway? [y/N]
```bash

**Best Practice:** Say `n` to auto-switch to `draft`

---

## 🎯 Common Tasks

### Fix Typo on Website

```bash
work stat-545      # Auto-checks branch
# Edit file
git add file.qmd && git commit -m "Fix typo"
s545d              # Deploy
```diff

**Time:** < 2 minutes

---

### Publish Weekly Lecture

```bash
work stat-545
cat > lectures/week05.qmd <<EOF
---
title: "Week 5: Linear Models"
---
# Content here
EOF
git add lectures/week05.qmd
git commit -m "Add week 5 lecture"
s545d
```bash

---

### Archive Semester

```bash
./scripts/semester-archive.sh
# Creates tag: spring-2026-final

# Update config for next semester
$EDITOR .flow/teach-config.yml
# Change: course.semester, course.year
git add .flow/teach-config.yml
git commit -m "Update for Fall 2026"
./scripts/quick-deploy.sh
```bash

---

### Create Exam (Optional)

**Requires:** `npm install -g examark`

```bash
# Enable exam workflow
yq -i '.examark.enabled = true' .flow/teach-config.yml

# Create exam
teach-exam "Midterm 1"
# Duration: 90
# Points: 100
# Filename: midterm1

# Edit exam
$EDITOR exams/midterm1.md

# Convert to Canvas QTI
./scripts/exam-to-qti.sh exams/midterm1.md

# Upload to Canvas:
# Quizzes → Import → QTI 1.2 format → exams/midterm1.zip
```diff

---

## 🛠️ Scripts Reference

### quick-deploy.sh

**Safety Checks:**
- ✅ Validates on `draft` branch
- ✅ Checks for uncommitted changes
- ✅ Handles merge conflicts
- ✅ Returns to `draft` after deploy

**Output:**

```bash
✅ Deployed to production in 47s
🌐 Site: https://example.com/course
⏳ GitHub Actions deploying (usually < 2 min)
```text

**Error:**

```bash
❌ Must be on draft branch
Current branch: production
Run: git checkout draft
```yaml

---

### semester-archive.sh

**Usage:**

```bash
./scripts/semester-archive.sh

Semester: spring 2026
Tag: spring-2026-final

Create archive tag? [Y/n] y

✅ Archived: spring-2026-final
```diff

**Next Steps (Displayed):**
1. Update `.flow/teach-config.yml` for next semester
2. Update `course.year` or `course.semester`
3. Commit config changes to `draft` branch

---

## 🔍 Troubleshooting

| Problem | Solution |
|---------|----------|
| "yq is required" | `brew install yq` |
| "Must be on draft branch" | `git checkout draft` |
| Merge conflict during deploy | Merge production into draft first, resolve conflicts |
| Shortcuts not loading | Run `work <course>` to load them |
| Production warning every time | You're on production branch → `git checkout draft` |
| GitHub Pages not deploying | Check Actions tab, verify Pages enabled |

---

## 🌐 GitHub Setup

### Enable GitHub Pages

1. Go to repo Settings → Pages
2. **Source:** `production` branch
3. **Folder:** `/ (root)`
4. Save

### Verify Deployment

```bash
# Check deployment status
gh run list --limit 5

# Or visit
https://github.com/<user>/<repo>/actions
```bash

---

## 📊 Integration

### With Other Commands

```bash
# Pick command (shows teaching icon)
pick teach
🎓 stat-545

# Dash command (shows course context)
dash teach
╭─────────────────────────────╮
│ Teaching Projects           │
│ 🎓 STAT 545  (draft)        │
╰─────────────────────────────╯

# Regular work (no teaching config)
work my-r-package
# → Standard session

# Teaching work (has .flow/teach-config.yml)
work stat-545
# → Teaching session (branch check + shortcuts + context)
#
# 📚 STAT 545 - Design of Experiments
#   Branch: draft
#   Semester: Spring 2026
#   Current Week: Week 8
#
#   Recent Changes:
#     Add week 8 lecture notes
#     Update assignment rubric
```yaml

---

## 🎓 Best Practices

### ✅ Do

- Edit on `draft` branch only
- Use `quick-deploy.sh` for deployment
- Commit frequently with clear messages
- Test locally before deploying
- Archive semester at end of term

### ❌ Don't

- Edit directly on `production` branch
- Push to `production` manually
- Skip branch safety warnings
- Deploy with uncommitted changes
- Forget to update config for new semester

---

## 📚 See Also

- [Complete Guide](../guides/TEACHING-WORKFLOW.md) - Comprehensive documentation
- [TEACH Dispatcher Reference](./TEACH-DISPATCHER-REFERENCE.md) - Full command reference
- [teach-init Command](../commands/teach-init.md) - Initialize teaching projects

---

## 🆘 Quick Help

```bash
# Get help
teach-init --help
work --help

# Check configuration
cat .flow/teach-config.yml

# Verify branches
git branch -a

# Check current branch
git branch --show-current

# View deployment history
git log production --oneline -5

# Check GitHub Actions
gh run list
```

---

**Need more help?**
https://github.com/Data-Wise/flow-cli/issues

---

**Version:** Teaching Workflow v2.1 (UX Enhancements)
**Status:** Production Ready ✅
**New in 2.1:** `-y`/`--yes` flag, ADHD-friendly completion summary
