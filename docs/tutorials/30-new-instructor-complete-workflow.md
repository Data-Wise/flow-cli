# Tutorial 30: New Instructor Complete Workflow

> **What you'll learn:** Go from an empty directory to a deployed course website with AI-powered content
>
> **Time:** ~30 minutes | **Level:** Beginner
> **Version:** v6.1.0+

---

## Prerequisites

Before starting, ensure you have:

- [ ] flow-cli installed (`brew install data-wise/tap/flow-cli`)
- [ ] Quarto installed (`brew install quarto` or [download](https://quarto.org/docs/get-started/))
- [ ] Git configured (`git config --global user.name "Your Name"`)
- [ ] GitHub account (for deployment)
- [ ] (Optional) Claude Code with Scholar plugin (for AI content generation)

**Verify your setup:**

```bash
# Check flow-cli is installed
teach help

# Check Quarto
quarto --version

# Check git
git config user.name
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. ✅ Create a new course from scratch
2. ✅ Set up a proper teaching workflow with git branches
3. ✅ Generate lesson plans for your semester
4. ✅ Create your first lecture content (manual + AI-assisted)
5. ✅ Preview your course website locally
6. ✅ Deploy to GitHub Pages for students to access
7. ✅ Understand the weekly content creation workflow

---

## Overview: The Complete Journey

This tutorial uses **checkpoints** to ensure you're on track. Each section ends with a verification step.

```mermaid
graph LR
    A[Empty Directory] --> B[teach init]
    B --> C[Configure Course]
    C --> D[Create Lesson Plans]
    D --> E[Generate Content]
    E --> F[Validate & Preview]
    F --> G[Deploy to GitHub Pages]
    G --> H[Live Course Website!]

    style A fill:#e1e4e8
    style B fill:#0366d6,color:#fff
    style C fill:#0366d6,color:#fff
    style D fill:#0366d6,color:#fff
    style E fill:#0366d6,color:#fff
    style F fill:#0366d6,color:#fff
    style G fill:#0366d6,color:#fff
    style H fill:#28a745,color:#fff
```

---

## Checkpoint 1: Initialize Your Course (5 min)

### Step 1.1: Create Project Directory

```bash
# Create a new directory for your course
mkdir stat-201-spring-2026
cd stat-201-spring-2026
```

### Step 1.2: Initialize Teaching Project

```bash
# Initialize with interactive setup
teach init "STAT-201"
```

**What this does:**
- Creates `.flow/teach-config.yml` with default settings
- Sets up git repository (if not already initialized)
- Creates `draft` branch for development
- Commits the initial configuration

**Example output:**
```
🎓 Initializing Teaching Project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ Created .flow/teach-config.yml
  ✓ Initialized git repository
  ✓ Created draft branch

✅ Teaching project initialized!

  Next steps:
    1. Review config: teach config
    2. Check environment: teach doctor
    3. Generate content: teach exam "Topic"
```

### Step 1.3: Initialize with Templates (Optional)

If you prefer working with content templates:

```bash
teach init "STAT-201" --with-templates
```

This adds:
- `.flow/templates/content/` - Content starters (lecture, lab, slides)
- `.flow/templates/prompts/` - AI generation prompts
- `.flow/templates/metadata/` - Quarto metadata files
- `.flow/templates/checklists/` - QA checklists

### ✅ Verification: Checkpoint 1

```bash
# Verify config file exists
ls -la .flow/teach-config.yml

# Should show: .flow/teach-config.yml exists
# If not, run: teach init again
```

**Expected result:** `.flow/teach-config.yml` file exists

---

## Checkpoint 2: Configure Your Course (5 min)

### Step 2.1: Edit Course Configuration

```bash
# Open config in your default editor
teach config
```

This opens `.flow/teach-config.yml` in your `$EDITOR` (defaults to `code` if not set).

### Step 2.2: Key Configuration Fields

Update these sections in the config file:

```yaml
course:
  name: "STAT-201"
  full_name: "STAT 201 - Intermediate Statistics"
  semester: "Spring 2026"
  year: 2026
  credits: 3
  instructor: "Your Name"
  description: "A second course in statistics covering ANOVA, regression, and experimental design."

# Location settings
locations:
  lectures: 'lectures'        # Where lecture .qmd files live
  concepts: '.teach/concepts.json'
  slides_output: '_site/slides'

# Git workflow settings
git:
  draft_branch: draft         # Development branch
  production_branch: main     # Live website branch
  auto_pr: true              # Auto-create PRs on deploy
  require_clean: true        # Require clean working tree

# Teaching mode (for live editing during class)
workflow:
  teaching_mode: false       # Set true during class
  auto_commit: false         # Auto-commit after each change
  auto_push: false           # Auto-push to draft branch

# Backup retention
backups:
  retention:
    assessments: archive     # Keep exam/quiz backups forever
    syllabi: archive         # Keep syllabus backups forever
    lectures: semester       # Delete lecture backups at semester end
  archive_dir: .flow/archives
```

### Step 2.3: Add Scholar Settings (If Using AI)

If you plan to use Scholar for AI-powered content generation, add:

```yaml
scholar:
  latex_macros:
    enabled: true
    sources:
      - path: "_macros.qmd"
        format: "qmd"
    auto_discover: false
```

### Step 2.4: Add Semester Calendar

Add your semester dates:

```yaml
semester_info:
  start_date: '2026-01-15'
  end_date: '2026-05-10'
  break_weeks: [9]  # Spring break
```

### ✅ Verification: Checkpoint 2

```bash
# Validate your configuration
teach doctor

# Expected output: All checks should be green
# If errors, fix them and run teach doctor again
```

**Expected result:**
```
✅ Teaching Environment Status

Course Configuration:
  ✓ .flow/teach-config.yml exists
  ✓ Config is valid YAML
  ✓ Required fields present

Git Setup:
  ✓ In git repository
  ✓ Draft branch exists
  ✓ Production branch exists

Dependencies:
  ✓ Quarto installed (v1.4.550)
  ✓ yq installed (v4.35.1)
```

---

## Checkpoint 3: Create Lesson Plans (10 min)

Lesson plans define your weekly topics and serve as the source of truth for AI content generation.

### Step 3.1: Create Your First Week

```bash
# Create week 1 with conceptual style
teach plan create 1 --topic "Introduction to Statistics" --style conceptual
```

**What this does:**
- Creates `.flow/lesson-plans.yml` (if it doesn't exist)
- Adds a week entry with auto-populated objectives from config
- Sets the pedagogical style for AI generation

**Output:**
```
✅ Created week 1: Introduction to Statistics

  Topic: Introduction to Statistics
  Style: conceptual
  Date: 2026-01-15 (auto-calculated from start_date)

  View: teach plan show 1
```

### Step 3.2: Create Multiple Weeks

```bash
# Week 2 - Computational style (more code/examples)
teach plan create 2 --topic "Probability Fundamentals" --style computational

# Week 3 - Rigorous style (proofs and theory)
teach plan create 3 --topic "Hypothesis Testing" --style rigorous

# Week 4 - Applied style (real-world applications)
teach plan create 4 --topic "Simple Linear Regression" --style applied
```

### Step 3.3: Understanding Styles

| Style | Focus | Use When |
|-------|-------|----------|
| `conceptual` | Intuition, analogies, visual explanations | Introducing new topics |
| `computational` | Code examples, step-by-step calculations | Teaching R/Python implementation |
| `rigorous` | Mathematical proofs, formal definitions | Advanced theory sections |
| `applied` | Real-world examples, case studies | Showing practical applications |

### Step 3.4: Review Your Lesson Plans

```bash
# List all weeks in a table
teach plan list
```

**Output:**
```
Week | Topic                        | Style         | Date       | Status
-----|------------------------------|---------------|------------|-------
1    | Introduction to Statistics   | conceptual    | 2026-01-15 | ✓
2    | Probability Fundamentals     | computational | 2026-01-22 | ✓
3    | Hypothesis Testing          | rigorous      | 2026-01-29 | ✓
4    | Simple Linear Regression    | applied       | 2026-02-05 | ✓

4 weeks defined, 0 gaps detected
```

### Step 3.5: View Week Details

```bash
# Show detailed info for week 1
teach plan show 1

# Shortcut
teach plan 1
```

### ✅ Verification: Checkpoint 3

```bash
# Verify lesson plans file exists
cat .flow/lesson-plans.yml

# List all weeks
teach plan list

# Expected: 4 weeks defined with no gaps
```

**Expected result:** `.flow/lesson-plans.yml` exists with 4 week entries

---

## Checkpoint 4: Generate Your First Content (5 min)

Now let's create actual lecture content. You have two options: **manual creation** or **AI-assisted generation**.

### Option A: Manual Creation with Templates

If you initialized with `--with-templates`:

```bash
# Create lecture from template
teach templates new lecture week-01 --topic "Introduction"

# This creates: lectures/week-01.qmd with boilerplate
```

Then edit `lectures/week-01.qmd` in your editor:

```bash
# Open for editing
code lectures/week-01.qmd
```

### Option B: AI-Assisted Generation with Scholar

If you have Claude Code + Scholar plugin:

```bash
# Generate lecture for week 1
teach lecture 1

# Or specify custom topic
teach lecture 1 --topic "Getting Started with Statistics"
```

**What this does:**
- Reads lesson plan for week 1
- Injects course-specific prompts from `.flow/templates/prompts/`
- Calls Scholar plugin to generate content
- Extracts LaTeX macros from `_macros.qmd` (if enabled)
- Saves to `lectures/week-01.qmd`

**Interactive prompts:**
```
📝 Generating lecture for Week 1...

Topic: Introduction to Statistics
Style: conceptual

Include sections:
  [x] Learning objectives
  [x] Key concepts
  [x] Examples
  [ ] Practice problems
  [x] Summary

Generating... (this takes 1-2 minutes)

✅ Created: lectures/week-01.qmd
```

### Step 4.3: Create Additional Content Types

```bash
# Generate slides for week 1
teach slides 1

# Generate lab assignment
teach assignment 1 --topic "Descriptive Statistics Lab"

# Generate quiz
teach quiz 1 --questions 10
```

### ✅ Verification: Checkpoint 4

```bash
# Verify lecture file exists
ls -la lectures/week-01.qmd

# Preview the content
head -n 20 lectures/week-01.qmd

# Expected: Valid Quarto document with YAML header
```

**Expected result:** `lectures/week-01.qmd` exists with proper YAML frontmatter

---

## Checkpoint 5: Add Templates and Macros (5 min)

### Step 5.1: List Available Templates

```bash
# Show all templates
teach templates list

# Filter by type
teach templates list --type content
```

**Output:**
```
📚 Available Templates

Content Templates (.flow/templates/content/):
  - lecture.qmd         (Lecture starter)
  - lab.qmd            (Lab assignment)
  - slides.qmd         (Reveal.js slides)
  - assignment.qmd     (Homework)

Prompt Templates (.flow/templates/prompts/):
  - lecture-prompt.md   (Lecture generation)
  - exam-prompt.md     (Exam generation)
  - quiz-prompt.md     (Quiz generation)

Total: 7 templates (4 content, 3 prompts)
```

### Step 5.2: Create from Template

```bash
# Create lecture for week 2 from template
teach templates new lecture week-02 --topic "Probability"

# This creates: lectures/week-02.qmd with:
#   - {{WEEK}} replaced with "2"
#   - {{TOPIC}} replaced with "Probability"
#   - {{COURSE}} replaced with "STAT-201"
#   - {{DATE}} auto-calculated
```

### Step 5.3: Set Up LaTeX Macros (If Using Math)

If your course uses mathematical notation, set up consistent macros:

```bash
# List available macros
teach macros list

# Example output:
# Category: operators
#   \E{...}     - Expectation E[Y]
#   \Var{...}   - Variance Var(Y)
#   \Cov{...}   - Covariance Cov(X,Y)
#
# Category: distributions
#   \Normal     - Normal distribution
#   \Binom      - Binomial distribution
```

Create `_macros.qmd` in your project root:

```markdown
---
title: "LaTeX Macros"
---

$$
\newcommand{\E}[1]{\mathbb{E}\left[#1\right]}
\newcommand{\Var}[1]{\text{Var}\left(#1\right)}
\newcommand{\Cov}[2]{\text{Cov}\left(#1, #2\right)}
\newcommand{\Normal}{\mathcal{N}}
$$
```

Then sync macros to your config:

```bash
# Update teach-config.yml with macro sources
teach macros sync
```

### ✅ Verification: Checkpoint 5

```bash
# Verify templates work
teach templates validate

# Verify macros are detected
teach macros list

# Expected: No validation errors
```

---

## Checkpoint 6: Preview and Deploy (10 min)

### Step 6.1: Local Preview

Before deploying, preview your site locally:

```bash
# Preview in browser (Quarto's preview server)
teach deploy --preview

# Or use Quarto directly
quarto preview
```

**What happens:**
- Quarto starts a local web server
- Opens browser to http://localhost:4200
- Auto-refreshes when you edit files
- Press Ctrl+C to stop

### Step 6.2: Validate Content

```bash
# Validate all lectures
teach validate lectures/*.qmd

# Validate specific file
teach validate lectures/week-01.qmd
```

**Validation checks:**
- YAML frontmatter is valid
- Cross-references resolve
- Code chunks execute without errors
- Images exist

### Step 6.3: Understanding the Git Workflow

flow-cli uses a **dual-branch workflow**:

```
draft branch (development)
    │
    │  teach deploy (creates PR)
    │
    ▼
main branch (production/live site)
    │
    │  GitHub Actions builds & deploys
    │
    ▼
GitHub Pages (students see this)
```

**Benefits:**
- Test changes on `draft` before going live
- Quick rollbacks if needed
- Clear separation between development and production

### Step 6.4: Deploy to GitHub (Initial Setup)

First time only - create GitHub repository:

```bash
# Create GitHub repo and push (requires gh CLI)
gh repo create stat-201-spring-2026 --public --source=. --push
```

Enable GitHub Pages:
1. Go to your repo on GitHub
2. Settings → Pages
3. Source: Deploy from a branch
4. Branch: `main`, folder: `/` or `/_site`
5. Save

### Step 6.5: Deploy Changes

```bash
# Deploy to production (creates PR from draft → main)
teach deploy
```

**What this does:**
1. Validates you're on `draft` branch
2. Runs `quarto render` to build the site
3. Commits changes to `draft`
4. Creates PR to merge `draft` → `main`
5. (If `auto_pr: true`) Auto-merges the PR
6. Pushes to GitHub
7. GitHub Actions builds and deploys to Pages

**Output:**
```
🚀 Deploying Course Website
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pre-flight checks:
  ✓ In git repository
  ✓ teach-config.yml found
  ✓ On draft branch
  ✓ Working tree is clean

Building site:
  ✓ Quarto render successful
  ✓ Generated 12 pages

Committing changes:
  ✓ Staged _site/
  ✓ Committed to draft

Creating PR:
  ✓ PR #1 created: draft → main
  ✓ Auto-merged (auto_pr: true)

Pushing to GitHub:
  ✓ Pushed main branch

✅ Deployed! Site will be live in ~2 minutes
   https://yourusername.github.io/stat-201-spring-2026
```

### Step 6.6: Partial Deployment (Advanced)

Deploy only specific files:

```bash
# Deploy only week 1 lecture
teach deploy lectures/week-01.qmd

# Deploy all lectures
teach deploy lectures/

# Deploy with flags
teach deploy lectures/week-01.qmd --skip-index --auto-commit
```

### ✅ Verification: Checkpoint 6

```bash
# Check git branches
git branch -a

# Expected: draft, main, origin/main

# Check GitHub Pages
# Visit: https://yourusername.github.io/stat-201-spring-2026
# Expected: Your course website is live!
```

**Success indicators:**
- ✅ PR created and merged on GitHub
- ✅ GitHub Actions workflow completed (green checkmark)
- ✅ Site is accessible at your GitHub Pages URL

---

## What's Next?

Congratulations! You've set up a complete course website workflow. Here's what to do next:

### 1. Weekly Content Creation Workflow

```bash
# Every week:

# 1. Generate new lecture
teach lecture 2

# 2. Preview locally
teach deploy --preview

# 3. Deploy to students
teach deploy

# 4. Check it's live
open https://yourusername.github.io/stat-201-spring-2026
```

### 2. Generate Assessments

```bash
# Create midterm exam
teach exam 1 --topic "Chapters 1-5" --questions 25 --points 100

# Create weekly quiz
teach quiz 3 --questions 10

# Create homework assignment
teach assignment 3 --topic "Regression Analysis"
```

### 3. Use Scholar AI Integration

If you have Claude Code + Scholar:

```bash
# All teach commands support AI generation:
teach lecture 5 --style rigorous
teach slides 5 --format "revealjs"
teach exam "Final Exam" --questions 50 --difficulty hard
```

### 4. Archive at Semester End

```bash
# Archive entire semester
teach archive --semester "Spring 2026"

# Creates: .flow/archives/spring-2026/
#   - All lectures
#   - All assessments
#   - Lesson plans
#   - Configuration snapshot
```

### 5. Set Up Weekly Routine

Create an alias in your `.zshrc`:

```bash
# Weekly teaching workflow
alias teach-week='teach lecture $1 && teach slides $1 && teach deploy --preview'

# Usage: teach-week 5
```

---

## Troubleshooting

### "teach doctor shows errors"

**Problem:** Configuration validation fails

**Solution:**
```bash
# View detailed errors
teach doctor --verbose

# Common fixes:
# - Missing yq: brew install yq
# - Invalid YAML: teach config (fix syntax)
# - Missing branches: git branch draft
```

### "deploy fails with 'not in git repository'"

**Problem:** No git repository initialized

**Solution:**
```bash
# Initialize git
git init
git add .
git commit -m "Initial commit"
git branch draft
```

### "Scholar not found"

**Problem:** Scholar plugin not installed or not accessible

**Solution:**
```bash
# Install Scholar plugin
# (This requires Claude Code CLI)

# Alternative: Use manual content creation
teach templates new lecture week-01
```

### "GitHub Pages shows 404"

**Problem:** Site not deploying correctly

**Solution:**
1. Check GitHub Actions workflow completed (green checkmark)
2. Verify Pages settings: Settings → Pages
3. Ensure branch is `main` and folder is `/` or `/_site`
4. Check `_quarto.yml` has correct `output-dir`

### "teach deploy creates PR but doesn't merge"

**Problem:** `auto_pr: false` in config

**Solution:**
```bash
# Option 1: Enable auto-merge
teach config
# Set: git.auto_pr: true

# Option 2: Manually merge PR
gh pr merge --merge
```

### "LaTeX macros not working in Scholar output"

**Problem:** Macros not being injected into prompts

**Solution:**
```bash
# Verify macro configuration
teach config
# Check: scholar.latex_macros.enabled: true

# Sync macros
teach macros sync

# Verify Scholar can see them
teach macros export --format json
```

---

## See Also

**Core Tutorials:**
- [Tutorial 14: Teaching Workflow](14-teach-dispatcher.md) - Deep dive into teach commands
- [Tutorial 24: Template Management](24-template-management.md) - Advanced template usage
- [Tutorial 25: Lesson Plan Migration](25-lesson-plan-migration.md) - Migrating old courses

**Reference Docs:**
- [Quick Reference: teach commands](../reference/REFCARD-TEACH-DISPATCHER.md)
- [Quick Reference: Templates](../reference/REFCARD-TEMPLATES.md)
- [Quick Reference: Lesson Plans](../reference/REFCARD-TEACH-PLAN.md)
- [Quick Reference: LaTeX Macros](../reference/REFCARD-MACROS.md)

**Guides:**
- [Teaching Workflow v3.0 Guide](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)
- [Scholar Wrappers Guide](../guides/SCHOLAR-WRAPPERS-GUIDE.md)

**Advanced Topics:**
- [Deployment Guide](../guides/TEACH-DEPLOY-GUIDE.md)
- [Teaching Workflow v3.0 Guide](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)
- [Backup System Guide](../guides/BACKUP-SYSTEM-GUIDE.md)

---

## Summary

You've learned how to:

- ✅ Initialize a new teaching project (`teach init`)
- ✅ Configure course settings (`teach config`)
- ✅ Create lesson plans (`teach plan create`)
- ✅ Generate content (manual templates + AI with Scholar)
- ✅ Preview locally (`teach deploy --preview`)
- ✅ Deploy to GitHub Pages (`teach deploy`)
- ✅ Set up weekly workflows

**Key Commands:**
```bash
teach init "STAT-201"              # Initialize
teach config                       # Configure
teach plan create 1 --topic "..."  # Create lesson plans
teach lecture 1                    # Generate content
teach deploy --preview             # Preview locally
teach deploy                       # Deploy to production
```

**Next Session:**
- Generate week 2 content
- Create your first assessment
- Set up Scholar prompts

Happy teaching! 🎓
