# STAT 545 Comprehensive Migration & Workflow Plan

**Version:** 1.0  
**Date:** January 11, 2026  
**Course:** STAT 545 - Design of Experiments  
**Teaching Schedule:** Spring only (annual)

---

## Executive Summary

**Goal:** Migrate existing STAT 545 course to two-branch workflow with full automation (Tiers 1-3)

**Key Decisions Made:**
- ✅ Two-branch strategy (draft + production)
- ✅ Spring-only teaching (simplified from semester model)
- ✅ Automation Tiers 1-3 (full quality assurance)
- ✅ Both .md and .qmd quiz formats
- ✅ .gitignore .qti.zip files (regenerate as needed)

**Migration Scenarios:**
- **Scenario A:** In-place conversion (if git repo exists with history)
- **Scenario B:** Fresh start (if no git or minimal history)

**Timeline:** 7-8 hours over 3 weeks

---

## Table of Contents

1. [Migration Scenarios](#migration-scenarios)
2. [Spring-Only Workflow](#spring-only-workflow)
3. [Branch Architecture](#branch-architecture)
4. [Daily Workflows](#daily-workflows)
5. [Semester Lifecycle](#semester-lifecycle)
6. [Automation Tiers](#automation-tiers)
7. [examark Integration](#examark-integration)
8. [Transition Day Protocol](#phase-3-transition-day-annual-event)
9. [Implementation Plan](#implementation-plan)
10. [Files to Generate](#files-to-generate)
11. [Next Steps](#next-steps)

---

## Migration Scenarios

### Scenario A: In-Place Conversion (Existing Git Repo)

**When to Use:**
- Git repository already initialized
- Valuable commit history to preserve
- Multiple semesters of evolution tracked

**Migration Steps:**

```bash
# 1. Tag previous semester
git tag -a spring-2025-final -m "Spring 2025 Complete"
git push --tags

# 2. Rename current branch to production
git branch -m main production  # or master → production
git push -u origin production
git push origin --delete main

# 3. Create draft branch
git checkout -b draft production
git push -u origin draft

# 4. Add .gitignore for QTI files
cat >> .gitignore << 'EOF'

# Examark outputs
*.qti.zip
*_qti/
*_files/
EOF

git add .gitignore
git commit -m "chore: Ignore examark outputs"
git push origin draft

# 5. Prepare for Spring 2026
vim _quarto.yml  # Update semester metadata
vim index.qmd    # Update welcome message
git commit -m "chore: Prepare for Spring 2026"
git push origin draft
```

**Timeline:** 30 minutes

**Result:**
- ✅ All history preserved
- ✅ Previous semester tagged
- ✅ Two-branch workflow established
- ✅ Ready for automation

---

### Scenario B: Fresh Start (No Git or Minimal History)

**When to Use:**
- No .git directory exists
- Minimal/unimportant commit history
- Want cleanest possible setup

**Migration Steps:**

```bash
# 1. Initialize repository
cd ~/projects/teaching/stat-545
git init

# 2. Create .gitignore
cat > .gitignore << 'EOF'
# Quarto outputs
_site/
_freeze/
.quarto/

# R
.Rproj.user/
.Rhistory
.RData
.Ruserdata
renv/library/
renv/staging/

# Examark outputs
*.qti.zip
*_qti/
*_files/

# macOS
.DS_Store

# IDE
.vscode/
*.code-workspace

# Temporary files
*.log
*.aux
*.toc
*.tex
EOF

# 3. Initial commit (Spring 2025 final)
git add .
git commit -m "Initial commit: Spring 2025 final version"

# 4. Rename to production
git branch -m main production

# 5. Tag previous semester
git tag -a spring-2025-final -m "Spring 2025 Complete"

# 6. Create draft branch
git checkout -b draft production

# 7. Add remote (GitHub)
git remote add origin git@github.com:Data-Wise/doe.git
git push -u origin production
git push -u origin draft
git push --tags

# 8. Prepare for Spring 2026
vim _quarto.yml  # Update metadata
vim index.qmd    # Update welcome
git commit -m "chore: Prepare for Spring 2026"
git push origin draft
```

**Timeline:** 20 minutes

**Result:**
- ✅ Clean git history starting now
- ✅ Previous work preserved and tagged
- ✅ Two-branch workflow from day one
- ✅ Ready for automation

---

## Spring-Only Workflow

### Annual Cycle

**Spring-only teaching dramatically simplifies workflow:**

```
January-May: SPRING 2026 ACTIVE
├── High activity (daily commits)
├── Weekly deployments
├── draft → production (frequent merges)
└── Student-facing production branch

June-December: BETWEEN SEMESTERS (9 months!)
├── Major content overhaul
├── All work on draft branch only
├── No deployment pressure
├── No parallel semester to manage
└── Prepare Spring 2027

January 10-12: TRANSITION DAY
├── Merge draft → production
├── Tag spring-2026-final
├── Tag spring-2027-start
└── Spring 2027 begins
```

**Key Simplifications:**

✅ **No Future Semester Branch Needed**
- Never teaching Fall and Spring simultaneously
- Don't need spring-2027 branch during Spring 2026
- All future work stays on draft

✅ **Extended Prep Period (9 months)**
- Summer: Rest, reflect, plan (3 months)
- Fall: Intensive content creation (4 months)
- Winter: Final polish (1 month)
- No rush, no pressure

✅ **Relaxed Between-Semester Work**
- Experiment freely
- Rewrite entire sections
- Change technology
- Test new tools

✅ **Simplified Branch Strategy**
- During semester: draft → production (frequent)
- Between semesters: draft only (no merges)

---

## Branch Architecture

### Structure

```
draft              # Your daily workspace
├── All commits here first
├── Push freely for backup
└── Experimental, unfinished content OK

production         # Students see this
├── Only updated via explicit merge
├── Stable, tested content only
└── Deploys automatically to GitHub Pages

Tags (no branches)
├── spring-2025-final
├── spring-2026-final
└── spring-2027-final
```

### Mental Model

**draft** = Unrestricted workspace
- Commit anything, anytime
- Push for backup (no deployment)
- Can break things safely

**production** = Locked gate
- Only merge when ready
- Students see immediately
- Must be working content

**Tags** = Semester snapshots
- Permanent historical record
- Can always recover old versions
- Branches deleted after tagging

---

## Daily Workflows

### Pattern 1: Quick Fix (90% of commits)

**Scenario:** Student emails: "Week 8 has typo"

**Workflow:**

```bash
[2 minutes total]

work stat-545                    # Start session
git checkout draft               # Ensure on draft
vim lectures/week-08_rcbd-blocking.qmd
# Fix: "variabiltiy" → "variability"

git commit -m "fix: Correct typo in Week 8"
./scripts/quick-deploy.sh "Week 8 typo"
# → Script merges to production, pushes
# → GitHub Actions deploys in 2 min
# → Students see fix in 3 min total

win "Fixed Week 8 typo"
```

**Key Points:**
- No need to switch branches manually
- One script call deploys
- Students see fix immediately
- Flow-cli tracks progress

---

### Pattern 2: Weekly Assignment Prep

**Scenario:** Friday, preparing Assignment 5 for Tuesday

**Workflow:**

```bash
[30 minutes prep, deploy Tuesday]

# Friday - Create
work stat-545
git checkout draft
claude /teaching:assignment "Incomplete Block Designs" "intermediate"
# → scholar generates assignment

vim assignments/assignment-05.qmd
# → Edit scholar output, customize

git commit -m "feat: Create Assignment 5"
quarto preview  # Preview locally (not deployed)
win "Created Assignment 5"

# Monday - Review
vim assignments/assignment-05.qmd
# → Minor tweaks
git commit -m "feat: Finalize Assignment 5"

# Tuesday morning - Deploy
./scripts/quick-deploy.sh "Assignment 5"
win "Published Assignment 5"
```

**Key Points:**
- Work ahead safely (draft branch)
- Review before deployment
- Deploy exactly when ready
- No accidental early release

---

### Pattern 3: Quiz Creation & Canvas Integration

**Scenario:** Creating Week 12 quiz

**Complete Workflow:**

```bash
[45 minutes total]

# Phase 1: Generate with scholar (10 min)
work stat-545
git checkout draft
claude /teaching:quiz "Mixed Models ANOVA"
# → scholar generates 8-10 questions

vim quizzes/week-12-quiz.md
# → Paste scholar output, customize
git commit -m "wip: Week 12 quiz draft"
win "Generated quiz questions"

# Phase 2: Convert with examark (5 min)
cd ~/projects/apps/examark
examark ~/projects/teaching/stat-545/quizzes/week-12-quiz.md \
  -o ~/projects/teaching/stat-545/quizzes/week-12-quiz.qti.zip

cd ~/projects/teaching/stat-545
git add quizzes/week-12-quiz.qti.zip
git commit --amend --no-edit  # Add .qti.zip to commit

# Phase 3: Test in Canvas sandbox (15 min)
# → Upload to Canvas sandbox
# → Preview quiz
# → Take practice quiz
# → Verify answers correct
# → Iterate if needed

# Phase 4: Deploy to production (5 min)
./scripts/quick-deploy.sh "Week 12 quiz"
# → Upload .qti.zip to real Canvas course
# → Set availability dates
win "Published Week 12 quiz"

# Phase 5: Students access (automatic)
# → Quiz appears in Canvas at scheduled time
# → Website shows quiz in schedule
```

**Key Points:**
- scholar accelerates question generation
- examark handles Canvas format conversion
- Test in sandbox before production
- Both .md and .qti.zip tracked in git
- .qti.zip regenerated as needed (in .gitignore)

---

### Pattern 4: Exam Preparation (High Stakes)

**Scenario:** Creating final exam

**Extended Workflow:**

```bash
[2-3 hours spread over several days]

# Week 1: Content generation
git checkout draft
claude /teaching:exam "cumulative" "covering weeks 1-15"
vim exams/final-exam.md
# → Customize, add specific problems
git commit -m "wip: Final exam initial draft"
win "Started final exam"

# Week 2: Iteration & review
vim exams/final-exam.md  # Refine questions
git commit -m "wip: Refine final exam"
examark exams/final-exam.md -o exams/final-exam.qti.zip
# → Import to Canvas sandbox
# → Take practice exam
# → Fix issues
git commit -m "wip: Final exam v2"
win "Refined final exam"

# Week 3: Final version
vim exams/final-exam.md  # Last tweaks
git commit -m "feat: Finalize exam"
examark exams/final-exam.md -o exams/final-exam.qti.zip
git add exams/final-exam.*
git commit --amend --no-edit

# Finals Week: Deploy
./scripts/quick-deploy.sh "Final exam"
# → Upload to Canvas
# → Set exam window (e.g., Dec 15, 2-5pm)
# → Lock settings
win "Published final exam"

# Post-Exam: Solutions (optional)
vim exams/final-exam-solutions.qmd
git commit -m "docs: Final exam solutions"
# → Render to PDF
# → Store in _private/ (not deployed to students)
```

**Security Note:**
- Keep exams in draft branch only (don't merge until exam day)
- Use _private/ folder for sensitive content (not rendered)
- Consider storing exams outside git entirely for max security

---

## Semester Lifecycle

### Phase 1: Active Semester (January-May)

**Week 1-2: Syllabus Week**

```
Deploy Frequency: High (2-3 times/week)
Activities:
  - Daily quick fixes
  - Syllabus updates
  - Assignment releases
  
Branch Usage: draft → production (frequent)
```

**Week 3-13: Core Content**

```
Deploy Frequency: Moderate (1-2 times/week)
Activities:
  - Weekly lecture updates
  - Quiz releases
  - Assignment feedback
  
Branch Usage: draft → production (regular)
```

**Week 14-16: Final Exam Period**

```
Deploy Frequency: Low (critical fixes only)
Activities:
  - Freeze production
  - Exam materials in draft only
  
Branch Usage: draft only (production frozen)
```

---

### Phase 2: Between Semesters (June-December)

**Summer Relaxation (June-August) - 3 months**

```
Focus: Rest, reflect, plan
Pressure: Zero

Optional:
  - Review course evaluations
  - Identify content gaps
  - Research new topics
  - Update technology stack
  
Branch: draft only (experimental commits)
```

**Fall Intensive (September-December) - 4 months**

```
Focus: Build Spring 2027 content

Week 1-4 (Sep): Major overhaul
  - Rewrite weak lectures
  - Add new datasets/examples
  - Update R code packages

Week 5-8 (Oct): Assessment creation
  - Generate all quizzes (scholar)
  - Create exams (scholar + examark)
  - Test in Canvas sandbox

Week 9-12 (Nov): Polish and review
  - Review all lectures
  - Update syllabus/schedule
  - Generate assignments

Week 13-16 (Dec): Final prep
  - Test complete workflow
  - Fix broken links/images
  - Prepare deployment

Branch: draft only (100+ commits)
Pressure: Self-imposed deadlines
```

**Winter Break (December-January) - 1 month**

```
Focus: Final checks

Activities:
  - Final review of content
  - Test quarto render
  - Verify Canvas materials ready
  - Mental preparation

Branch: draft (final commits)
Transition: January 10-12 (3 days before semester)
```

---

### Phase 3: Transition Day (Annual Event)

**January 10, 2027 - Three Days Before Spring 2027**

**Morning (9am-12pm): Final Review**

```bash
work stat-545
git checkout draft

quarto render           # Final build check
# Review _site/ directory
# Test all links
# Verify images load

vim lectures/week-01_intro.qmd  # Last-minute tweaks
git commit -m "fix: Final pre-semester tweaks"

git log production..draft --oneline | wc -l
# Example: 127 commits since last semester
```

**Afternoon (1pm-3pm): Archival**

```bash
# Archive Spring 2026
git checkout production
git tag -a spring-2026-final -m "Spring 2026 Complete - May 2026"
git push --tags

# Create GitHub Release
gh release create spring-2026-final \
  --title "Spring 2026 - Final Version" \
  --notes "Complete course materials from Spring 2026.
  
  Stats:
  - Students: 38
  - Lectures: 15 weeks
  - Assignments: 8
  - Quizzes: 12
  - Exams: 2
  
  Major Changes:
  - Added Bayesian methods lecture
  - Updated all R code to tidyverse
  - New blocking datasets
  - Improved quiz quality"
```

**Afternoon (3pm-4pm): Transition**

```bash
# Replace production with draft
git checkout production
git reset --hard draft
git push --force origin production

# Tag new semester start
git tag -a spring-2027-start -m "Spring 2027 begins"
git push --tags

# Sync draft to production
git checkout draft
git reset --hard production
git push --force origin draft

# Confirm identical
git log production..draft  # Should be empty
```

**Evening (4pm-5pm): Verification**

```bash
# Wait for GitHub Actions (2-3 min)

# Verify deployment
curl -I https://data-wise.github.io/doe/
# → HTTP 200 OK

# Spot check in browser:
#   - Homepage shows Spring 2027
#   - Syllabus has correct dates
#   - Week 1 lecture loads
#   - Images display

# If issues: Quick fix
git checkout production
vim index.qmd
git commit -m "fix: Deployment issue"
git push origin production
```

**Evening (5pm): Celebrate**

```bash
win "Successfully transitioned to Spring 2027"
finish "Spring 2027 deployment complete"
yay

# Done! Relax until January 13.
```

---

## Automation Tiers

### Tier 1: Scripted Helpers

**Scripts to Create:**

**1. quick-deploy.sh** - Deploy single commit

```bash
#!/bin/bash
# Deploy current draft commit to production immediately

DESCRIPTION="$1"
CURRENT_COMMIT=$(git rev-parse HEAD)

git checkout production
git merge $CURRENT_COMMIT --no-ff -m "📦 $DESCRIPTION"
git push origin production
git checkout draft

echo "✅ Deployed: $DESCRIPTION"
```

**Usage:**

```bash
./scripts/quick-deploy.sh "Week 8 typo fix"
```

**2. publish-batch.sh** - Deploy multiple commits

```bash
#!/bin/bash
# Show unpublished commits, confirm, then deploy all

echo "📊 Changes to publish:"
git log production..draft --oneline

echo "Publish these? (y/n)"
read response

if [[ "$response" == "y" ]]; then
  git checkout production
  git merge draft --no-ff -m "📦 Batch: $(date +%Y-%m-%d)"
  git push origin production
  git checkout draft
  echo "✅ Published to students"
fi
```

**Usage:**

```bash
./scripts/publish-batch.sh
```

**3. quiz-to-qti.sh** - examark wrapper with auto-commit

```bash
#!/bin/bash
# Generate .qti.zip from .md and commit both

QUIZ_MD="$1"
QUIZ_NAME=$(basename "$QUIZ_MD" .md)

examark "$QUIZ_MD" -o "${QUIZ_MD%.md}.qti.zip"

git add "$QUIZ_MD" "${QUIZ_MD%.md}.qti.zip"
git commit -m "feat: Add $QUIZ_NAME"

echo "✅ Quiz ready for deployment"
echo "Next: ./scripts/quick-deploy.sh '$QUIZ_NAME'"
```

**Usage:**

```bash
./scripts/quiz-to-qti.sh quizzes/week-12-quiz.md
```

**4. semester-archive.sh** - Annual transition helper

```bash
#!/bin/bash
# Guide through semester transition

SEMESTER_TAG="$1"
NEXT_SEMESTER="$2"

echo "📦 Archiving $SEMESTER_TAG..."

git checkout production
git tag -a "$SEMESTER_TAG" -m "Semester complete"
git push --tags

echo "✅ Tagged as $SEMESTER_TAG"
echo ""
echo "Next steps:"
echo "1. Review draft branch"
echo "2. git reset --hard draft on production"
echo "3. Force push production"
echo "4. Tag new semester start"
```

**Usage:**

```bash
./scripts/semester-archive.sh "spring-2026-final" "Spring 2027"
```

**Time Savings:**
- Quick fix: 2 min (was 5 min) → 60% faster
- Batch publish: 3 min (was 10 min) → 70% faster
- Quiz creation: 10 min (was 15 min) → 33% faster

**Implementation:** 1 hour (write + test)

---

### Tier 2: flow-cli Integration

**Configuration File: `.flow/config.yml`**

```yaml
project:
  name: "STAT 545 - Design of Experiments"
  type: teaching
  course_code: STAT-545
  default_branch: draft
  
  versioning:
    strategy: two-branch
    branches:
      work: draft
      published: production
    
shortcuts:
  # Content creation
  assignment: "claude /teaching:assignment"
  quiz: "claude /teaching:quiz"
  exam: "claude /teaching:exam"
  
  # Conversion & deployment
  qti: "scripts/quiz-to-qti.sh"
  deploy: "scripts/quick-deploy.sh"
  publish: "scripts/publish-batch.sh"
  
  # Session helpers
  current: "git checkout production && quarto preview --port 4321"
  draft-preview: "git checkout draft && quarto preview"

automation:
  auto_push_draft: true          # Auto-push draft for backup
  remind_canvas_upload: true     # Reminder after qti generation
  
hooks:
  pre_deploy: "quarto render"    # Ensure site builds
  post_deploy: "echo '✅ https://data-wise.github.io/doe/'"

goals:
  daily_commits: 2               # Target: 2 commits/day

reminders:
  - "Students see: https://data-wise.github.io/doe/"
  - "Publish weekly on Fridays"
```

**Custom Aliases: `~/.zshrc`**

```bash
# STAT 545 shortcuts
alias s545="work stat-545"
alias s545q="work stat-545 && flow qti"
alias s545d="work stat-545 && flow deploy"
alias s545p="work stat-545 && flow publish"

# Quick git status
alias s545s="cd ~/projects/teaching/stat-545 && git status"

# View unpublished commits
alias s545u="cd ~/projects/teaching/stat-545 && git log production..draft --oneline"
```

**Enhanced Workflow:**

```bash
# All one-liners:
s545                              # Start session
claude /teaching:quiz "Topic"     # Generate quiz
flow qti quizzes/week-12-quiz.md  # Convert to QTI
flow deploy "Week 12 quiz"        # Deploy to students
```

**Benefits:**
- ✅ ADHD-optimized (minimal steps)
- ✅ Context-aware shortcuts
- ✅ Auto-backup (auto_push_draft)
- ✅ Progress tracking (wins, goals)
- ✅ Reminders when needed

**Implementation:** 2 hours (config + aliases + testing)

---

### Tier 3: GitHub Actions CI/CD

**Workflow 1: Production Deployment**

**File: `.github/workflows/deploy.yml`**

```yaml
name: Deploy to Students

on:
  push:
    branches: [production]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2
        with:
          version: 1.4.550
      
      - name: Setup R
        uses: r-lib/actions/setup-r@v2
        with:
          r-version: '4.3.2'
      
      - name: Restore renv packages
        uses: r-lib/actions/setup-renv@v2
      
      - name: Render site
        run: quarto render
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./_site
          cname: data-wise.github.io
```

**Workflow 2: Quality Checks**

**File: `.github/workflows/test.yml`**

```yaml
name: Quality Checks

on:
  push:
    branches: [draft, production]
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2
      
      - name: Check Quarto syntax
        run: quarto check
      
      - name: Render site (dry run)
        run: quarto render --dry-run
      
      - name: Setup Node (for examark)
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Validate quiz syntax
        run: |
          npm install -g examark
          for quiz in quizzes/*.md; do
            [ -f "$quiz" ] && examark check "$quiz"
          done
      
      - name: Check for broken links
        run: |
          quarto render
          npm install -g markdown-link-check
          find _site -name "*.html" -exec markdown-link-check {} \; || true
      
      - name: R package dependencies
        run: Rscript -e "renv::status()"
```

**Workflow 3: Draft Preview (Optional)**

**File: `.github/workflows/preview-draft.yml`**

```yaml
name: Preview Draft Branch

on:
  push:
    branches: [draft]
  workflow_dispatch:

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2
      
      - name: Setup R
        uses: r-lib/actions/setup-r@v2
      
      - name: Restore renv
        uses: r-lib/actions/setup-renv@v2
      
      - name: Render site
        run: quarto render
      
      - name: Deploy to preview
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./_site
          destination_dir: preview
```

**Benefits:**
- ✅ Catches errors before students see them
- ✅ Validates quiz syntax automatically
- ✅ Checks for broken links
- ✅ Ensures R packages consistent
- ✅ Runs on every push (draft or production)
- ✅ Optional draft preview at /preview URL

**Time Impact:**
- No manual steps removed
- Same workflow, higher quality
- Auto-detects errors
- Prevents broken deployments

**Implementation:** 3 hours (write workflows + test + debug)

---

## examark Integration

### File Organization

**Directory Structure:**

```
quizzes/
├── week-08-quiz.md          # Source (version controlled)
├── week-08-quiz.qti.zip     # Generated (in .gitignore)
├── week-09-quiz.md
├── week-09-quiz.qti.zip
└── ...

exams/
├── midterm-exam.md
├── midterm-exam.qti.zip
├── final-exam.md
└── final-exam.qti.zip
```

**Why .gitignore .qti.zip files:**
- ✅ Binary files cause merge conflicts
- ✅ Easy to regenerate from .md source
- ✅ Keeps git history clean
- ✅ Reduces repository size
- ❌ Must regenerate before Canvas upload

**Regeneration Workflow:**

```bash
# When switching machines or after clone
cd ~/projects/apps/examark

# Regenerate all quizzes
for quiz in ~/projects/teaching/stat-545/quizzes/*.md; do
  examark "$quiz" -o "${quiz%.md}.qti.zip"
done

# Regenerate all exams
for exam in ~/projects/teaching/stat-545/exams/*.md; do
  examark "$exam" -o "${exam%.md}.qti.zip"
done
```

---

### Two Workflows: Static vs Dynamic

**Workflow A: Static Markdown Quizzes**

```
File: quizzes/week-08-quiz.md (plain Markdown)

Process:
  .md → examark → .qti.zip → Canvas

Advantages:
  - Simple, no R execution
  - Fast to write and edit
  - examark processes directly
  
Use case: Theory questions, conceptual quizzes
```

**Workflow B: Dynamic Quarto Quizzes**

```
File: quizzes/week-08-quiz.qmd (Quarto + R)

Process:
  .qmd → quarto render → .md → examark → .qti.zip → Canvas

Advantages:
  - Generate questions from R code
  - Randomize numbers/datasets
  - Include plots/figures
  - Compute correct answers programmatically
  
Example:
---
title: "Week 8 Quiz"
---

```{r}
#| echo: false
set.seed(42)
data <- rnorm(20, mean=100, sd=15)
correct_mean <- round(mean(data), 2)
```

1. [Num] What is the mean? [2pts]
   Correct: `r correct_mean` ± 0.5

Use case: Stats quizzes with calculations

```

**Recommendation:**
- Start with Workflow A (simpler)
- Add Workflow B for specific needs
- Keep both options available

---

### Integration with scholar + examark + flow-cli

**Complete Content Pipeline:**

```

┌─────────────┐
│   scholar   │  Generate content with AI
│ /teaching:* │  (assignments, quizzes, exams)
└──────┬──────┘
       │ .md file
       ↓
┌─────────────┐
│   Manual    │  Edit, customize
│   Editing   │  (add problems, adjust)
└──────┬──────┘
       │ .md file
       ↓
┌─────────────┐
│  examark    │  Convert to Canvas format
│  (Quarto)   │  (.qti.zip for import)
└──────┬──────┘
       │ .qti.zip
       ↓
┌─────────────┐
│   Canvas    │  Upload and configure
│   Manual    │  (set dates, attempts)
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  flow-cli   │  Track progress
│    win      │  Celebrate completion
└─────────────┘

```

**Example Session:**
```bash
# Morning: Create Assignment 6
work stat-545
git checkout draft
claude /teaching:assignment "ANCOVA" "advanced"
vim assignments/assignment-06.qmd  # Customize
git commit -m "feat: Assignment 6"
win "Created Assignment 6"

# Afternoon: Create Week 13 quiz
claude /teaching:quiz "Nested Designs"
vim quizzes/week-13-quiz.md  # Edit
./scripts/quiz-to-qti.sh quizzes/week-13-quiz.md
win "Created Week 13 quiz"

# End of day
yay                           # See today's wins (2)
finish "Created Assignment 6 + Week 13 quiz"

# Next day: Deploy both
work stat-545
./scripts/publish-batch.sh    # Shows 2 commits
# → Confirm? y → Deploys to students
win "Published Assignment 6 and Week 13 quiz"
```

---

## Implementation Plan

### Week 1: Foundation (4 hours)

**Day 1 (1 hour): Repository Migration**
- [ ] Determine migration scenario (A or B)
- [ ] Execute migration steps
- [ ] Verify production + draft branches exist
- [ ] Tag spring-2025-final
- [ ] Push to GitHub

**Day 2 (1 hour): Tier 1 Scripts**
- [ ] Create scripts/ directory
- [ ] Write quick-deploy.sh
- [ ] Write publish-batch.sh
- [ ] Write quiz-to-qti.sh
- [ ] Write semester-archive.sh
- [ ] Make all executable (chmod +x)
- [ ] Test quick-deploy.sh (dry run)

**Day 3 (1 hour): Tier 2 Integration**
- [ ] Create .flow/ directory
- [ ] Write .flow/config.yml
- [ ] Add custom aliases to ~/.zshrc
- [ ] Source ~/.zshrc
- [ ] Test: s545, s545q, s545d
- [ ] Verify flow-cli shortcuts work

**Day 4 (1 hour): Testing & Validation**
- [ ] Make test commit on draft
- [ ] Test quick-deploy.sh
- [ ] Verify students see update
- [ ] Test publish-batch.sh
- [ ] Document any issues
- [ ] Refine scripts if needed

---

### Week 2: Automation (3 hours)

**Day 1 (2 hours): Tier 3 GitHub Actions**
- [ ] Create .github/workflows/ directory
- [ ] Write deploy.yml
- [ ] Write test.yml
- [ ] Write preview-draft.yml (optional)
- [ ] Push workflows to draft
- [ ] Merge to production (trigger deploy)
- [ ] Verify deployment successful
- [ ] Check GitHub Actions logs

**Day 2 (1 hour): End-to-End Testing**
- [ ] Create test quiz with scholar
- [ ] Convert with examark
- [ ] Commit to draft
- [ ] Verify CI passes
- [ ] Deploy with quick-deploy.sh
- [ ] Verify deployment
- [ ] Upload to Canvas sandbox
- [ ] Full workflow validation

**Day 3 (bonus): Documentation**
- [ ] Write WORKFLOW.md
- [ ] Update README.md
- [ ] Document migration steps
- [ ] Create quick reference card

---

### Week 3: Production Use

**Daily:**
- [ ] Use workflow for real work
- [ ] Log friction points
- [ ] Note improvement ideas
- [ ] Track time savings

**End of Week:**
- [ ] Review lessons learned
- [ ] Adjust scripts if needed
- [ ] Finalize process
- [ ] Celebrate success!

---

## Files to Generate

### Tier 1: Scripts (4 files)

```
scripts/
├── quick-deploy.sh       # Deploy single commit (50 lines)
├── publish-batch.sh      # Deploy multiple commits (40 lines)
├── quiz-to-qti.sh        # examark wrapper (30 lines)
└── semester-archive.sh   # Annual transition helper (60 lines)
```

### Tier 2: Configuration (2 files)

```
.flow/
└── config.yml            # flow-cli configuration (50 lines)

~/.zshrc additions        # Custom aliases (10 lines)
```

### Tier 3: GitHub Actions (3 files)

```
.github/workflows/
├── deploy.yml            # Production deployment (40 lines)
├── test.yml              # Quality checks (60 lines)
└── preview-draft.yml     # Draft preview (optional, 35 lines)
```

### Documentation (3 files)

```
WORKFLOW.md               # Daily usage guide (500 lines)
MIGRATION-COMPLETE.md     # Migration record (100 lines)
.gitignore               # Updated exclusions (30 lines)
```

**Total: 12 files + documentation**

---

## Next Steps

### Critical Decision Needed

**To finalize migration path, please run:**

```bash
cd ~/projects/teaching/stat-545

# Check if git exists
ls -la .git

# If git exists, check history
git log --oneline -20
git branch -a
git tag -l

# Check current content
ls -la lectures/ | head -10
ls -la quizzes/ | head -10
```

**Share output to determine:**
- Scenario A (preserve history) vs. Scenario B (fresh start)
- What semester is currently in the repo
- If multiple past semesters need tagging

---

### Additional Questions

**1. GitHub Repository**
- Does github.com/Data-Wise/doe exist?
- If yes, empty or has content?
- Do you have admin access?

**2. Current Semester Content**
- What semester is in ~/projects/teaching/stat-545/?
- Spring 2025? Older?
- Complete or in-progress?

**3. Previous Semesters**
- Taught this course before Spring 2025?
- Materials archived elsewhere?
- Should we tag multiple past semesters?

**4. Timeline**
- When do you want this operational?
- Actively working on Spring 2026 content now?
- Or waiting until summer/fall?

---

### Ready to Generate Files

**Once you confirm migration scenario, I'll generate:**

✅ All 4 Tier 1 scripts (production-ready)  
✅ Tier 2 flow-cli configuration  
✅ All 3 Tier 3 GitHub Actions workflows  
✅ Complete documentation  
✅ Step-by-step migration guide  
✅ Testing instructions  

**With:**
- Detailed inline comments
- Error handling
- Progress indicators
- Rollback procedures
- ADHD-friendly formatting

**Estimated generation time:** 15-30 minutes

**Estimated execution time:** 2 hours for complete setup

---

## Success Metrics

### Quantitative Targets

| Metric | Baseline | After Tier 1-3 |
|--------|----------|----------------|
| Deploy time | 5 min | 2 min |
| Quiz creation | 45 min | 15 min |
| Weekly prep | 3 hours | 1.5 hours |
| Errors pre-deploy | 0% | 80% caught |
| Student downtime | <1 min | 0 min |
| Commits/week | 10 | 20+ |

### Qualitative Goals

**ADHD-Friendly:**
- ✅ Clear mental model (draft = work, production = live)
- ✅ Minimal context switching
- ✅ Visible progress (flow-cli wins)
- ✅ Low cognitive load (scripts handle complexity)
- ✅ Quick feedback loops

**Content Quality:**
- ✅ Version controlled
- ✅ Peer reviewable
- ✅ Reproducible
- ✅ Portable

**Student Experience:**
- ✅ Stable URLs
- ✅ Fast fixes (same-day)
- ✅ Consistent quality
- ✅ Accessible archives

---

## Contact & Support

**Questions or Issues?**
- Review this plan document
- Check WORKFLOW.md (after generation)
- Consult individual script comments

**Ready to proceed when you confirm:**
1. Migration scenario (A or B)
2. Answers to additional questions
3. Preferred file generation approach

---

**End of Comprehensive Plan**

**Version:** 1.0  
**Last Updated:** January 11, 2026  
**Status:** Awaiting migration scenario confirmation
