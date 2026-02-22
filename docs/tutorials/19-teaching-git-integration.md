# Tutorial 19: Teaching + Git Integration

**Level:** Intermediate
**Duration:** ~25 minutes
**Prerequisites:** Tutorial 14 (Teaching Workflow), basic Git knowledge

---

## What You'll Learn

By the end of this tutorial, you'll be able to:

- ✅ Set up a teaching course repository with Git
- ✅ Use the 3-option post-generation workflow
- ✅ Deploy teaching content via PR automation
- ✅ Track uncommitted files with git-aware status
- ✅ Enable teaching mode for rapid content creation
- ✅ Understand the complete 5-phase git workflow

---

## Overview

The teaching workflow in flow-cli integrates with Git across **5 phases**:

1. **Smart Post-Generation** - Choose how to commit after creating content
2. **Git Deployment** - Deploy from draft → production with PR automation
3. **Git-Aware Status** - See uncommitted teaching files instantly
4. **Teaching Mode** - Streamlined auto-commit for rapid creation
5. **Git Initialization** - Complete repository setup

---

## Part 1: Foundation - Initialize with Git

### Step 1: Create a New Course Repository

```bash
# Navigate to your teaching projects
cd ~/projects/teaching

# Initialize a new course WITH git
teach init "STAT 440"
```

**What happens:**

```text
┌─────────────────────────────────────────────────────────────┐
│ 🎓 Flow Teaching Workflow Initialization                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Course name: STAT 440                                       │
│                                                             │
│ → Initializing git repository...                            │
│ → Copying .gitignore template (95 lines, 18 patterns)       │
│ → Creating branches: draft, main                            │
│ → Making initial commit                                     │
│                                                             │
│ Would you like to create a GitHub repository? (y/N)         │
└─────────────────────────────────────────────────────────────┘
```

**Git structure created:**

```bash
stat-440/
├── .git/                          # Git repository
├── .gitignore                     # Teaching-specific patterns
├── .flow/
│   └── teach-config.yml          # Course config (with git settings)
├── exams/                        # (empty)
├── slides/                       # (empty)
└── scripts/
    ├── quick-deploy.sh
    └── semester-archive.sh
```

**Current branches:**

```bash
git branch -a
# * draft
#   main
```

### Step 2: Explore Git Configuration

```bash
# View config
teach config
```

**Git settings (`.flow/teach-config.yml`):**

```yaml
git:
  draft_branch: "draft"          # Development branch (default)
  production_branch: "main"      # Deployment branch (default)
  auto_pr: true                  # Auto-create PRs on deploy
  require_clean: true            # Block deploy if uncommitted changes

workflow:
  teaching_mode: false           # Manual workflow (default)
  auto_commit: false             # No auto-commit (default)
  auto_push: false               # Never auto-push (safety)
```

**Exercise:** Try changing `draft_branch` to `dev` and see what happens.

---

## Part 2: Phase 1 - Smart Post-Generation

The **3-option menu** appears after generating teaching content.

### Step 1: Create Your First Exam

```bash
# Make sure you're on draft branch
git branch
# * draft

# Create exam
teach exam "Syllabus Quiz"
```

**What you'll see:**

```text
✓ Generated exams/syllabus-quiz.qmd

📝 Teaching content created

What would you like to do?
  1) Review in editor, then commit
  2) Commit now with auto-generated message
  3) Skip commit (do it manually later)

Choice [1-3]:
```

### Step 2: Try Each Option

**Option 1: Review in editor, then commit**

```bash
Choice: 1

Opening exams/syllabus-quiz.qmd in nvim...

# (After closing editor)
Commit this file? (y/N): y

✓ Committed: teach: add exam for Syllabus Quiz
```

**Option 2: Commit now (auto-message)**

```yaml
Choice: 2

✓ Committed: teach: add exam for Syllabus Quiz

Commit message:
  teach: add exam for Syllabus Quiz

  Generated via: teach exam 'Syllabus Quiz'
  Course: STAT 440 (Fall 2024)

  Co-Authored-By: Scholar <scholar@example.com>
```

**Option 3: Skip commit**

```bash
Choice: 3

Skipped. File saved, not committed.
You can commit manually later:
  git add exams/syllabus-quiz.qmd
  git commit -m "teach: add exam for Syllabus Quiz"
```

### Step 3: View Your Commits

```bash
# See recent commits
git log --oneline -5

# Example output:
# a1b2c3d teach: add exam for Syllabus Quiz
# e4f5g6h Initial commit
```

**Exercise:** Create 3 more exams using different options each time.

---

## Part 3: Phase 3 - Git-Aware Status

Check which teaching files are uncommitted.

### Step 1: Create Files Without Committing

```bash
# Create slides (choose option 3 - skip)
teach slides "Week 1 Introduction"
# Choice: 3 (skip)

# Create quiz (choose option 3 - skip)
teach quiz "Chapter 1"
# Choice: 3 (skip)
```

### Step 2: Check Status

```bash
teach status
```

**Output:**

```text
┌─────────────────────────────────────────────────────────────┐
│ Course: STAT 440 (Fall 2024)                                │
│ Week: 1 of 15                                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 📝 Uncommitted Teaching Files:                              │
│   • slides/week01-introduction.qmd                          │
│   • quizzes/quiz01.qmd                                      │
│                                                             │
│ What would you like to do?                                  │
│   1) Commit all teaching files                              │
│   2) Stash changes                                          │
│   3) View diff                                              │
│   4) Skip                                                   │
│                                                             │
│ Choice [1-4]:                                               │
└─────────────────────────────────────────────────────────────┘
```

### Step 3: Try Each Status Option

**Option 1: Commit all**

```yaml
Choice: 1

✓ Added slides/week01-introduction.qmd
✓ Added quizzes/quiz01.qmd
✓ Committed: teach: add 2 teaching files

  - slides/week01-introduction.qmd
  - quizzes/quiz01.qmd
```

**Option 2: Stash changes**

```text
Choice: 2

✓ Stashed 2 files: WIP on draft
```

**Option 3: View diff**

```diff
Choice: 3

diff --git a/slides/week01-introduction.qmd b/slides/week01-introduction.qmd
new file mode 100644
index 0000000..abcdefg
--- /dev/null
+++ b/slides/week01-introduction.qmd
...

(Returns to menu after showing diff)
```

**Exercise:** Create 5 files, leave uncommitted, then use `teach status` to commit them all at once.

---

## Part 4: Phase 2 - Git Deployment

Deploy your changes from `draft` → `main` via Pull Request.

### Step 1: Push Your Draft Branch

```bash
# Make sure all changes are committed
teach status
# (should show clean)

# Push to GitHub (if you created remote repo)
git push origin draft
```

### Step 2: Deploy to Production

```bash
teach deploy
```

**Pre-flight checks:**

```text
┌─────────────────────────────────────────────────────────────┐
│ 🚀 Deployment Pre-Flight Checks                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ✓ On draft branch                                           │
│ ✓ No uncommitted changes                                    │
│ ✓ No unpushed commits                                       │
│ ✓ No conflicts with production branch                       │
│                                                             │
│ All checks passed. Creating PR...                           │
└─────────────────────────────────────────────────────────────┘
```

**PR creation:**

```diff
Creating Pull Request: draft → main

Title: Deploy STAT 440 teaching content

Body:
## Teaching Content Deployment

### Changes in this PR:
- teach: add exam for Syllabus Quiz (a1b2c3d)
- teach: add 2 teaching files (b2c3d4e)

### Files Changed: 3
- exams/syllabus-quiz.qmd
- slides/week01-introduction.qmd
- quizzes/quiz01.qmd

### Checklist:
- [ ] Content reviewed
- [ ] Links checked
- [ ] Assets uploaded
- [ ] Accessibility checked

✓ PR created: https://github.com/user/stat-440/pull/1
```

### Step 3: Review and Merge

```bash
# View PR in browser
gh pr view 1 --web

# Merge when ready
gh pr merge 1 --squash
```

**Exercise:** Create 5 new files, commit them, and deploy to production.

---

## Part 5: Phase 4 - Teaching Mode

Enable **streamlined auto-commit** for rapid content creation.

### Step 1: Enable Teaching Mode

```bash
# Edit config
teach config
```

**Change these settings:**

```yaml
workflow:
  teaching_mode: true      # Enable teaching mode
  auto_commit: true        # Auto-commit after generation
  auto_push: false         # Safety: never auto-push
```

Save and close.

### Step 2: Create Content (Auto-Commit)

```bash
# Create exam (no menu!)
teach exam "Midterm 1"
```

**Output:**

```text
✓ Generated exams/midterm1.qmd

🎓 Teaching Mode: Auto-committing...

✓ Committed: teach: add exam for Midterm 1
```

**No menu, instant commit!**

### Step 3: Rapid Content Creation

```bash
# Create multiple items rapidly
teach quiz "Chapter 2"
teach slides "Week 3"
teach lecture "Hypothesis Testing"
teach assignment "Homework 2"

# All auto-committed!
git log --oneline -5
```

**Output:**

```text
f1a2b3c teach: add assignment for Homework 2
e0d9c8b teach: add lecture for Hypothesis Testing
d9c8b7a teach: add slides for Week 3
c8b7a6f teach: add quiz for Chapter 2
b7a6d5e teach: add exam for Midterm 1
```

### Step 4: Deploy All Changes

```bash
# Push all commits
git push origin draft

# Deploy to production
teach deploy
# (Creates PR with all 5 commits)
```

**Exercise:** Enable teaching mode and create 10 pieces of content in under 5 minutes.

---

## Part 6: Advanced Workflows

### Workflow 1: Weekly Content Creation

**Monday morning routine:**

```bash
# Start session
work stat-440

# Check current week
teach week
# Week 8 of 15

# Create week's content (teaching mode enabled)
teach slides "Week 8 - ANOVA"
teach quiz "Week 7 Review"
teach assignment "Homework 8"

# Review changes
git log --oneline -3

# Deploy
git push origin draft
teach deploy
```

### Workflow 2: Exam Season

**Create and review exams:**

```bash
# Disable teaching mode temporarily
teach config
# → Set teaching_mode: false

# Create exam with review
teach exam "Final Exam"
# Choice: 1 (review in editor)

# Make edits...

# Commit after review
# Choice: y (commit)

# Create answer key
teach exam "Final Exam - Answer Key"
# Choice: 2 (commit now)
```

### Workflow 3: Collaborative Teaching

**Working with TAs:**

```bash
# Create feature branch for TA
git checkout -b ta-assignments draft

# TA creates assignments
teach assignment "Problem Set 1"
teach assignment "Problem Set 2"

# Push TA branch
git push origin ta-assignments

# Create PR for review
gh pr create --base draft --head ta-assignments \
  --title "TA Assignments - Week 3-4"

# After review, merge to draft
gh pr merge <PR-number>

# Then deploy to production
teach deploy
```

---

## Part 7: Troubleshooting

### Problem: "Not a git repository"

**Symptom:** Git commands fail

**Solution:**

```bash
# Check if git initialized
git status
# fatal: not a git repository

# Re-run teach init with --no-git flag
teach init --no-git "STAT 440"

# Then initialize git manually
git init
git add .
git commit -m "Initial commit"
```

### Problem: Deploy fails with uncommitted changes

**Symptom:**

```text
❌ Deployment blocked: uncommitted changes detected
```

**Solution:**

```bash
# Check what's uncommitted
teach status

# Either commit them
teach status
# Choice: 1 (commit all)

# Or stash them temporarily
git stash

# Then deploy
teach deploy
```

### Problem: Teaching mode not auto-committing

**Symptom:** Still seeing 3-option menu

**Solution:**

```bash
# Verify config
teach config

# Make sure BOTH are true:
workflow:
  teaching_mode: true
  auto_commit: true     # This must be true!
```

### Problem: PR creation fails

**Symptom:**

```text
Error: gh: command not found
```

**Solution:**

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Try again
teach deploy
```

---

## Part 8: Best Practices

### 1. Branch Strategy

```bash
# Always work on draft branch
git checkout draft

# Keep main clean (production only)
# Only merge to main via PR
```

### 2. Commit Hygiene

```bash
# Use teaching mode for rapid creation
# But review periodically:
git log --oneline -10

# Squash related commits if needed (before PR)
git rebase -i HEAD~5
```

### 3. Deployment Timing

```bash
# Deploy weekly (not daily)
# → Reduces PR noise
# → Easier to review

# Or deploy after major milestones:
# → After creating full exam
# → After completing week's content
```

### 4. Backup Strategy

```bash
# Push draft branch frequently
git push origin draft

# Even if not deploying yet
# → Protects against data loss
# → Enables collaboration
```

---

## Summary

You've learned the complete 5-phase git integration:

✅ **Phase 1:** Smart post-generation (3-option menu)
✅ **Phase 2:** Git deployment (PR automation)
✅ **Phase 3:** Git-aware status (uncommitted tracking)
✅ **Phase 4:** Teaching mode (auto-commit)
✅ **Phase 5:** Git initialization (repository setup)

**Key Commands:**

```bash
teach init "Course Name"    # Initialize with git
teach exam "Topic"          # Create content (3-option menu)
teach status                # Check uncommitted files
teach deploy                # Deploy to production
teach config                # Enable teaching mode
```

---

## Next Steps

1. **Practice the full workflow** - Create a test course and go through all 5 phases
2. **Customize your config** - Adjust git settings to match your workflow
3. **Try teaching mode** - Enable auto-commit for rapid content creation
4. **Set up GitHub** - Create remote repo for backup and collaboration

---

## See Also

- **Quick Reference:** [Teaching Git Workflow Refcard](../reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher)
- **Command Docs:** [teach command](../commands/teach.md)
- **Dispatcher Reference:** [DISPATCHER-REFERENCE.md](../reference/MASTER-DISPATCHER-GUIDE.md)
- **Git Helpers Source:** `lib/git-helpers.zsh` (311 lines, 20+ functions)
- **Tests:** `tests/test-teaching-mode.zsh`, `tests/test-teach-init-git.zsh`

---

**Tutorial Complete!** You're now ready to use the full teaching + git integration. 🎓
