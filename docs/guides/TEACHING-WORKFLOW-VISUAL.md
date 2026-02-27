# Teaching Workflow - Visual Step-by-Step Guide

**Purpose:** Visual, step-by-step walkthroughs of common teaching tasks
**Last Updated:** 2026-02-27

---

## Workflow 1: Initialize a New Course

### Scenario

You have a new course repository and want to set up the teaching workflow.

### Step 1: Navigate to course repository

```bash
$ cd ~/projects/teaching/stat-545
$ pwd
/Users/you/projects/teaching/stat-545

$ ls -la
total 16
drwxr-xr-x   5 you  staff   160 Jan 13 10:00 .
drwxr-xr-x   3 you  staff    96 Jan 13 09:55 ..
drwxr-xr-x   9 you  staff   288 Jan 13 09:55 .git
-rw-r--xr-x   1 you  staff  1024 Jan 13 10:00 README.md
```

### Step 2: Initialize teaching workflow

```bash
$ teach init -y "STAT 545"
```

**What happens behind the scenes:**

```bash
teach init command
    ├── Read: Course name (STAT 545)
    ├── Create: .flow/teach-config.yml
    │   ├── Course metadata
    │   ├── Semester dates
    │   └── Branch names
    ├── Create: scripts/quick-deploy.sh
    │   └── Makes executable
    ├── Create: scripts/semester-archive.sh
    │   └── Makes executable
    ├── Create: .github/workflows/deploy.yml
    │   └── GitHub Actions config
    ├── Create: git branches
    │   ├── draft branch (where you work)
    │   └── production branch (students see)
    ├── Git: git add .
    ├── Git: git commit -m "init: teaching workflow"
    └── Display: Success message
```

### Step 3: Verify setup

```bash
$ ls -la .flow/
total 8
-rw-r--r--  1 you  staff  512 Jan 13 10:01 teach-config.yml

$ cat .flow/teach-config.yml
course:
  name: "STAT 545"
  semester: "spring"
  year: 2026

branches:
  draft: "draft"
  production: "production"

semester_info:
  start_date: "2026-01-13"
  end_date: "2026-05-08"
```

### Step 4: Verify branches created

```bash
$ git branch -a
  draft
  production
* main

$ git checkout draft
Switched to branch 'draft'

$ git log --oneline | head -3
a1b2c3d init: teaching workflow
f4e5d6c initial commit
```

### Result ✓

Your teaching workflow is ready:
- ✅ Draft branch: where you edit
- ✅ Production branch: what students see
- ✅ Deployment scripts: one-command publish
- ✅ GitHub Actions: automatic deployment
- ✅ Configuration: semester info stored

---

## Workflow 2: Daily Edit and Deploy

### Scenario

It's Monday morning. You want to publish this week's lecture and assignments.

### Step 1: Start work session

```bash
$ work stat-545

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📚 STAT 545 - Statistical Methods I
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# Branch: draft ✓
# Week: 9
#
# Editor opening: /Users/you/projects/teaching/stat-545
```

**What `work` command does:**

```text
work stat-545
    ├── Detect: teaching project (finds .flow/teach-config.yml)
    ├── Git: Check current branch
    ├── Validate: Are we on draft? (if not, warn!)
    ├── Load: Course shortcuts from config
    ├── Display: 📚 Course name, week number, branch
    ├── Open: Your editor ($EDITOR)
    └── Ready: Start editing!
```

### Step 2: Create course materials

**In your editor, create files:**

```markdown
# lectures/week09.qmd
---
title: "Week 9: Hypothesis Testing"
---

## Learning Objectives
- Understand Type I and Type II errors
- Perform t-tests
- Interpret p-values

## Lecture Notes
...
```

```markdown
# assignments/week09.qmd
---
title: "Assignment 9"
due: "Friday, March 7"
points: 20
---

## Instructions
Complete the following exercises...

## Submission
Submit your R Markdown file...
```

### Step 3: Check what changed

```bash
$ git status
On branch draft

Untracked files:
  (use "git add <file>..." to include in what will be committed)
    lectures/week09.qmd
    assignments/week09.qmd

nothing added to commit but untracked files present (tracking will use 'git commit' to list all)
```

### Step 4: Stage changes

```bash
$ git add lectures/ assignments/
```

### Step 5: Commit with descriptive message

```bash
$ git commit -m "feat: add week 9 course materials"

[draft a1b2c3d] feat: add week 9 course materials
 2 files changed, 45 insertions(+)
 create mode 100644 assignments/week09.qmd
 create mode 100644 lectures/week09.qmd
```

### Step 6: Deploy to students

```bash
$ teach deploy
```

**What happens:**

```text
teach deploy
    ├── Safety Checks:
    │   ├── ✓ Are we on draft branch?
    │   ├── ✓ Any uncommitted changes? No.
    │   └── ✓ Can merge to production? Yes.
    │
    ├── Git Operations:
    │   ├── git checkout production
    │   ├── git merge draft
    │   ├── git push origin production
    │   └── git checkout draft
    │
    ├── GitHub Actions:
    │   ├── Triggered automatically
    │   ├── Builds your site (Quarto, Jekyll, etc)
    │   └── Deploys to GitHub Pages
    │
    └── Result:
        ├── Students see materials in ~2 minutes
        ├── No manual steps needed
        └── You're back on draft branch ready for more edits
```

### Output

```bash
✅ Validating deployment...
✅ On draft branch
✅ No uncommitted changes
✅ Merging draft → production...
✅ Pushing to GitHub...

Deployment Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files changed: 2
Insertions: 45
✅ Deployed in 12 seconds

🌐 Site: https://yourname.github.io/stat-545
⏳ Direct mode: live in ~15 seconds | PR mode: GitHub Actions (< 2 minutes)

💡 Tip: Check Actions tab to monitor build progress
```

### Step 7: Verify students can access

```bash
$ open https://yourname.github.io/stat-545
# → Browser opens
# → Week 9 materials visible
# → Links working
# → Ready for students
```

### Result ✓

**Timeline:**
- 0:00 - Start work session
- 0:30 - Create lecture notes (5 min)
- 5:30 - Create assignment (5 min)
- 10:30 - Commit changes (< 1 min)
- 11:00 - Deploy (< 2 min)
- 12:00-14:00 - GitHub Actions builds and deploys
- 14:00 - Students see everything

**Total time: 15-20 minutes for week's materials**

---

## Workflow 3: Emergency Fix (Typo Fix)

### Scenario

A student found a typo in assignment 8 answer key. Fix ASAP!

### Step 1: Quick work session

```bash
$ work stat-545
# → Already on draft
# → Editor opens
```

### Step 2: Find and fix typo

```bash
# Search for the file
$ grep -r "regression coefficients" .
solutions/assignment-08.qmd:The regression coefficients is [0.42, -1.3]
#                                    ↑↑ Should be "are", not "is"

# Edit in editor
# Change: "coefficients is" → "coefficients are"
```

### Step 3: Quick commit

```bash
$ git add solutions/assignment-08.qmd
$ git commit -m "fix: grammar in assignment 8 answer key"
```

### Step 4: Deploy immediately

```bash
$ teach deploy

# Output: (same as before)
✅ Deployed in 8 seconds
```

### Result ✓

**Timeline:**
- Noticed at 2:00 PM
- Fixed at 2:01 PM
- Students see at 2:03 PM

**No need to email students - they'll see it when they check the site**

---

## Workflow 4: End of Semester Wrap-Up

### Scenario

Last day of spring semester. Need to archive everything and prep for fall.

### Step 1: Verify everything is deployed

```bash
$ teach status

╭────────────────────────────────────────────────────╮
│  📚 STAT 545                                       │
├────────────────────────────────────────────────────┤
│  Semester: Spring 2026 (Jan 13 - May 8)            │
│  Current: Week 16 of 16 ✓ Complete                │
│  Status: 🟢 Final materials deployed               │
│  Branch: draft                                     │
│  Last deploy: May 8, 2026 @ 14:30                  │
│  Files pending: 0                                  │
│                                                    │
│  ✓ All materials live                             │
│  ✓ No pending changes                             │
│  ✓ Ready to archive                               │
╰────────────────────────────────────────────────────╯
```

### Step 2: Archive semester

```bash
$ teach archive

📦 Archiving Semester
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Course: STAT 545
Semester: Spring 2026 (Jan 13 - May 8)

Archive tag: spring-2026-final
Create archive? [Y/n] y

✅ Archive created: spring-2026-final
```

**What happened:**

```text
teach archive
    ├── Git: Create annotated tag
    │   └── Tag name: spring-2026-final
    ├── Git: Tag points to current commit
    │   └── Captures exact state at archival
    ├── Git: Push tag to GitHub
    │   └── Accessible forever
    │
    └── Result:
        ├── Complete semester snapshot
        ├── Browse at: github.com/you/repo/releases/tag/spring-2026-final
        └── Can restore if needed
```

### Step 3: Verify tag created

```bash
$ git tag -l | grep final
spring-2026-final

$ git show spring-2026-final | head -10
tag spring-2026-final
Tagger: Your Name <you@email.com>
Date:   May 8, 2026 14:45:00 +0000

    Semester archive for Spring 2026
```

### Step 4: Update config for next semester

```bash
$ teach config

# Edit .flow/teach-config.yml:
# Change from:
#   semester: "spring"
#   year: 2026
#   start_date: "2026-01-13"
#
# Change to:
#   semester: "fall"
#   year: 2026
#   start_date: "2026-08-25"
```

### Step 5: Commit and deploy

```bash
$ git add .flow/teach-config.yml
$ git commit -m "prep: configure for Fall 2026"
$ teach deploy

# Result:
# ✅ Config updated
# ✅ Semester metadata updated
# ✅ New semester ready to go
```

### Result ✓

**Archive complete:**
- ✅ Spring 2026 snapshot: `spring-2026-final`
- ✅ Ready for Fall 2026
- ✅ Complete history preserved
- ✅ Can teach both semesters independently

---

## Workflow 5: Check Course Status Anytime

### Scenario

You want a quick dashboard of where you are in the semester.

### Step 1: Get status

```bash
$ teach status

╭────────────────────────────────────────────────────╮
│  📚 STAT 545 - Statistical Methods I               │
├────────────────────────────────────────────────────┤
│                                                    │
│  📅 Semester: Spring 2026                          │
│  📊 Progress: Week 8 of 16 (50%)                   │
│  ✓ Status: On Schedule                             │
│                                                    │
│  🌿 Branch: draft (✅ Safe to edit)                 │
│  👤 Last work: "Add week 8 materials" (2h ago)     │
│                                                    │
│  🚀 Deployment:                                    │
│     ├─ Last: May 1 @ 14:30                         │
│     ├─ Pending: 0 files                            │
│     └─ Status: Up to date ✓                        │
│                                                    │
│  ⏰ Upcoming:                                       │
│     ├─ Spring Break: Mar 10-17                     │
│     └─ End of semester: May 8                      │
│                                                    │
│  💡 Tip: Use 'teach deploy' to publish changes    │
│                                                    │
╰────────────────────────────────────────────────────╯
```

### Step 2: Check current week details

```bash
$ teach week

📅 Current Week: 8

Semester Timeline:
  Started: Jan 13, 2026
  Weeks elapsed: 7
  Current week: 8 of 16
  Weeks remaining: 8
  Expected end: May 8, 2026

⚡ No breaks this week
💡 Coming up: Spring Break (Mar 10-17)
```

### Result ✓

**Quick information at a glance:**
- ✅ Know exactly where you are in semester
- ✅ Check what's coming next
- ✅ Verify deployment status
- ✅ Branch safety check all in one command

---

## Command Quick Map

```bash
┌─────────────────────────────────────┐
│  ONE-TIME SETUP                     │
├─────────────────────────────────────┤
│  teach init "Course Name"           │
│  ↓                                  │
│  ✓ Branches created                 │
│  ✓ Config file created              │
│  ✓ Deployment scripts installed     │
│  ✓ GitHub Actions configured        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  DAILY WORKFLOW (repeat)            │
├─────────────────────────────────────┤
│  work stat-545                      │
│  (edit files)                       │
│  git add . && git commit            │
│  teach deploy                       │
│  (students see updates)             │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  ANYTIME CHECKS                     │
├─────────────────────────────────────┤
│  teach status     (see dashboard)   │
│  teach week       (current week)    │
│  teach config     (edit settings)   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  END OF SEMESTER                    │
├─────────────────────────────────────┤
│  teach archive                      │
│  (create snapshot)                  │
│  teach config                       │
│  (update for next semester)         │
│  git commit && teach deploy         │
│  (ready for new semester)           │
└─────────────────────────────────────┘
```

---

## Time Estimates

| Task | Time | Frequency |
|------|------|-----------|
| `teach init` | 30-60 sec | Once per course |
| `teach deploy` | < 2 min | 1-10 times/week |
| `teach status` | 10 sec | Daily |
| `teach week` | 5 sec | Daily |
| `teach config` | 2-5 min | Once per semester |
| `teach archive` | 1-2 min | Once per semester |
| **Daily maintenance** | 15-20 min | Daily |

---

## Troubleshooting Guide

### "I'm on production branch - help!"

**Problem:**

```bash
$ git branch --show-current
production
```

**Solution:**

```bash
# Switch to draft
$ git checkout draft

# Verify
$ git branch --show-current
draft

# Next time: use 'work' command which auto-warns
$ work stat-545
# → Would show warning if on production
```

---

### "Deployment failed - what happened?"

**Check GitHub Actions:**

```bash
# View recent runs
$ gh run list

# View specific run details
$ gh run view {run-id}

# Common issues:
# - Build failed: Check Quarto/site build
# - Deploy failed: Check GitHub Pages settings
# - Large files: Check file size limits
```

---

### "I forgot to commit before deploy"

**No problem:**

```bash
$ git status  # See what's changed
$ git add .
$ git commit -m "fix: latest changes"
$ teach deploy
```

---

### "How do I undo a deploy?"

**Option 1: Revert in git**

```bash
git revert HEAD  # Creates new commit that undoes previous
teach deploy     # Deploys the revert
```

**Option 2: Go back to previous version**

```bash
git log --oneline | head -5
# a1b2c3d current
# f4e5d6c previous
# g7h8i9j before that

git revert a1b2c3d
teach deploy
```

---

## See Also

- [Detailed Command Reference](./TEACHING-COMMANDS-DETAILED.md) - Deep dive into each command
- [Demo Guide](./TEACHING-DEMO-GUIDE.md) - Recording visual demonstrations
- [Quick Reference Card](../reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher) - Command cheat sheet
- [Teaching Workflow Guide](./TEACHING-WORKFLOW.md) - Architecture and design
