---
tags:
  - tutorial
  - teaching
  - dispatchers
---

# Tutorial: Teaching Workflow with Teach Dispatcher

> **What you'll learn:** Manage course websites with fast deployment, config validation, and AI-assisted content creation
>
> **Time:** ~20 minutes | **Level:** Beginner
> **Version:** v5.14.0

---

## Prerequisites

Before starting, you should:

- [ ] Have a Quarto course website repository
- [ ] Have GitHub Pages set up for deployment
- [ ] Optionally have Claude Code CLI for Scholar integration

**Verify your setup:**

```bash
# Check teach dispatcher is available
teach help

# Check if you're in a course directory
pwd
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Initialize a teaching workflow for your course
2. Understand config validation and fix common errors
3. Deploy changes to production in seconds (`-d`) or via PR
4. Use the branch-based draft/production workflow
5. Generate teaching content with Scholar integration
6. Archive semesters for future reference

---

## Part 1: Understanding the Teaching Workflow

### The Problem

Deploying course website updates typically takes 5-15 minutes:
- Edit locally → commit → push → wait for build → verify

**The Solution:**
- Branch-based workflow with draft (development) and production (live)
- One-command deployment: `teach deploy`
- < 2 minute turnaround from typo fix to live

### The Workflow

```
draft branch              production branch
     │                           │
     │  ┌─ teach deploy ─┐       │
     │  │                │       │
     ▼  │                ▼       ▼
[Edit] ─┴──→ [Merge] ──→ [Push] ──→ [GitHub Pages]
                                         │
                                         ▼
                                   [Students see it!]
```

**Demo:**

![Teaching Workflow Demo](../demos/tutorials/tutorial-14-teach-workflow.gif)

!!! info "Updated for v3.0"
    This tutorial covers the legacy workflow. For the current v3.0 workflow, see:
    - [Teaching Workflow v3.0 Guide](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)

---

## Part 2: Initialize Your Course

### Step 2.1: Run teach init

Navigate to your course repository and initialize:

```bash
cd ~/projects/teaching/my-course
teach init "STAT 545"
```

**What happens:**
1. Creates `draft` and `production` branches
2. Generates `.flow/teach-config.yml` configuration
3. Installs automation scripts in `scripts/`
4. Sets up GitHub Actions workflow
5. Commits the setup

### Step 2.2: Non-Interactive Mode

For scripting or when you know the defaults are fine:

```bash
teach init -y "STAT 545"
```

The `-y` flag accepts all defaults without prompting.

### Step 2.3: Verify Setup

```bash
teach status
```

**Example output:**

```
📚 STAT 545 - Statistical Programming
═══════════════════════════════════════════════════
Branch: draft ✓
Week: 3 of 15
Status: Ready to edit

Quick Commands:
  teach deploy    Push changes to production
  teach week      Show current week info
```

---

## Part 3: Config Validation (v5.9.0+)

Flow-cli automatically validates your `teach-config.yml` to catch errors early.

### Step 3.1: Understanding Validation

When you run `teach status` or any Scholar command, flow-cli validates:

| Check | Example | Valid Values |
|-------|---------|--------------|
| **Required field** | `course.name` | Any non-empty string |
| **Semester** | `course.semester` | `Spring`, `Summer`, `Fall`, `Winter` |
| **Year** | `course.year` | 2020-2100 |
| **Date format** | `semester_info.start_date` | `YYYY-MM-DD` |
| **Level** | `scholar.course_info.level` | `undergraduate`, `graduate`, `both` |
| **Difficulty** | `scholar.course_info.difficulty` | `beginner`, `intermediate`, `advanced` |
| **Tone** | `scholar.style.tone` | `formal`, `conversational` |
| **Grading** | `scholar.grading.*` | Must sum to ~100% |

### Step 3.2: Check Validation Status

```bash
teach status
```

**When config is valid:**

```
📚 STAT 545
📅 Spring 2026
🎓 Level: graduate
🔗 Scholar: configured
✅ Config: valid
```

**When config has issues:**

```
📚 STAT 545
⚠️  Config: has issues
```

### Step 3.3: See Validation Details

For verbose output with specific errors:

```bash
teach status --verbose
```

**Example with errors:**

```
❌ Config validation failed:
  • Invalid semester 'fall' - must be Spring, Summer, Fall, or Winter
  • Invalid year '25' - must be between 2020 and 2100
  • Grading percentages sum to 80% - should be ~100%
```

### Step 3.4: Hash-Based Change Detection

Flow-cli uses SHA-256 hashing to skip re-validation when your config hasn't changed:

```
teach status          # First run: validates config
teach status          # Second run: skips validation (unchanged)
# Edit teach-config.yml
teach status          # Re-validates (change detected)
```

This keeps commands fast even with complex validation rules.

### Step 3.5: Config Ownership

Your `teach-config.yml` has two owners:

| Section | Owner | Purpose |
|---------|-------|---------|
| `course`, `semester_info`, `branches`, `deployment` | **flow-cli** | Workflow automation |
| `scholar` | **Scholar** | AI content generation |
| `examark`, `shortcuts` | **Shared** | Both tools can read |

**Tip:** Don't manually edit `scholar` sections unless you understand Scholar's expectations.

---

## Part 4: Daily Workflow

### Step 4.1: Start Working

```bash
work stat-545
```

**What happens:**
- Checks you're on the `draft` branch
- **Warns if on production** (students see this!)
- Loads course context
- Opens your editor

### Step 4.2: Make Edits

Edit your lecture notes, slides, or assignments as usual.

### Step 4.3: Deploy to Production

When you're ready for students to see your changes:

```bash
teach deploy
```

**What happens:**
1. Commits any uncommitted changes
2. Merges `draft` → `production`
3. Pushes to GitHub
4. GitHub Actions builds the site
5. Students see updates in seconds (direct) or < 2 minutes (PR)

### Step 4.4: Check Current Week

```bash
teach week
```

**Example output:**

```
📅 Week 3 of 15 (Jan 20 - Jan 24)
   Topic: Data Wrangling with dplyr
   Lecture: lectures/week-03/
   Due this week: Assignment 2
```

---

## Part 5: Scholar Integration (AI Content)

The teach dispatcher wraps Scholar commands for AI-assisted content generation.

> **📚 Want to learn more?** Check out the comprehensive [Scholar Enhancement Tutorial Series](scholar-enhancement/index.md) to master all 47 flags, style presets, lesson plans, and advanced workflows.

### Step 5.1: Generate Exam Questions

```bash
teach exam "Midterm 1" --questions 25
```

**What happens:**
- Invokes Scholar's `/teaching:exam` command
- Generates questions based on your course config
- Outputs to `exams/midterm-1.md`

### Step 5.2: Create Quiz

```bash
teach quiz "Week 3" --questions 10
```

### Step 5.3: Generate Lecture Outline

```bash
teach lecture "Data Wrangling"
```

### Step 5.4: Create Assignment

```bash
teach assignment "Homework 3" --due-date "2026-01-31"
```

### Available Scholar Commands

| Command | What It Does |
|---------|--------------|
| `teach exam "Topic"` | Generate exam questions |
| `teach quiz "Topic"` | Create quick quiz |
| `teach lecture "Topic"` | Generate lecture outline |
| `teach slides "Topic"` | Create slide deck |
| `teach assignment "Topic"` | Design assignment |
| `teach syllabus` | Generate full syllabus |
| `teach rubric "Assignment"` | Create grading rubric |

---

## Part 7: Date Management (v5.11.0+)

Flow-cli can centralize all semester dates in `teach-config.yml` and automatically sync them across your entire course repository.

### Step 7.1: Initialize Date Configuration

```bash
teach dates init
```

**Interactive wizard:**

```
Semester start date (YYYY-MM-DD): 2025-01-13

Generating 15 weeks starting from 2025-01-13...
✓ Date configuration initialized!
  Start: 2025-01-13
  End:   2025-05-02
  Weeks: 15
```

### Step 7.2: Configure Dates

Edit `teach-config.yml` to add deadlines:

```yaml
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"

  weeks:
    - number: 1
      start_date: "2025-01-13"
      topic: "Introduction to R"
    # ... weeks 2-15

  deadlines:
    hw1:
      week: 2              # Week 2 start date
      offset_days: 4       # + 4 days = Friday

    final_project:
      due_date: "2025-05-08"  # Absolute date

  exams:
    - name: "Midterm"
      date: "2025-03-05"
      time: "2:00 PM - 3:50 PM"
```

### Step 7.3: Sync Dates to Files

Preview changes first:

```bash
teach dates sync --dry-run
```

**Output:**

```
⚠️  Date Mismatches Found
1. assignments/hw1.qmd (1 mismatch)
   due: 2025-01-20 → 2025-01-22

ℹ  Dry-run mode: No changes made
```

Apply changes:

```bash
teach dates sync
```

**Interactive prompts:**

```
File: assignments/hw1.qmd
│ YAML Frontmatter:
│   due: 2025-01-20 → 2025-01-22
Apply changes? [y/n/d/q] y
✓ Updated: assignments/hw1.qmd
```

### Step 7.4: Selective Sync

Sync only specific file types:

```bash
# Assignments only
teach dates sync --assignments

# Lectures only
teach dates sync --lectures

# Single file
teach dates sync --file assignments/hw3.qmd
```

### Step 7.5: Check Date Status

```bash
teach dates status
```

**Output:**

```
📅 Date Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Config Dates Loaded: 23
Teaching Files Found: 18
Date Sync Status: ✅ All files in sync
```

### Why Use Date Automation?

**Problem:** Teaching involves dates in many places:
- Syllabus: "Homework 1 due Jan 22"
- Assignment file: `due: "2025-01-20"`  ← Mismatch!
- Schedule: "Week 2: January 22, 2025"

**Solution:** Define once in config, sync everywhere automatically.

**Benefits:**
- ✅ Consistency: All dates match
- ✅ Speed: Semester rollover in 5 minutes (vs 2 hours)
- ✅ Safety: Preview changes with --dry-run

**See:** [Teaching Dates Guide](../guides/TEACHING-DATES-GUIDE.md) for complete documentation.

---


## Part 6: Semester Management

### Step 6.1: Archive Current Semester

At the end of the semester:

```bash
teach archive
```

**What happens:**
- Creates a git tag: `fall-2025` (or current semester)
- Preserves the semester snapshot
- You can restore later if needed

### Step 6.2: Prepare for New Semester

```bash
teach config
```

Update semester dates, week count, and topics for the new term.

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `teach init "Course"` | Initialize teaching workflow |
| `teach status` | Show course dashboard + validation |
| `teach status --verbose` | Show detailed validation errors |
| `teach deploy` | Push to production |
| `teach week` | Current week info |
| `teach archive` | Snapshot semester |
| `teach config` | Edit configuration |
| `teach help` | Show all commands |

### Scholar Wrappers

| Command | Scholar Skill |
|---------|---------------|
| `teach exam` | `/teaching:exam` |
| `teach quiz` | `/teaching:quiz` |
| `teach lecture` | `/teaching:lecture` |
| `teach slides` | `/teaching:slides` |
| `teach assignment` | `/teaching:assignment` |

---

## Common Workflows

### Morning Prep

```bash
work stat-545          # Start session
teach week             # See today's topic
# Edit lecture notes
teach deploy           # Push before class
```

### Creating an Exam

```bash
teach exam "Final" --questions 40 --duration 180
# Review and edit generated questions
teach deploy           # (when ready to post)
```

### End of Semester

```bash
teach archive          # Snapshot everything
teach config           # Update for next semester
```

---

## Troubleshooting

### "Config validation failed"

```bash
# Check what's wrong
teach status --verbose

# Common fixes:
# 1. Semester must be capitalized: Fall, not fall
# 2. Year must be 4 digits: 2026, not 26
# 3. Dates must be YYYY-MM-DD: 2026-01-15
# 4. Grading percentages should sum to ~100%
```

### "Not a teaching project"

```bash
# Initialize first
teach init "Course Name"
```

### "On production branch"

```bash
# Switch to draft for editing
git checkout draft
```

### "Scholar command failed"

```bash
# Check Claude CLI is available
claude --version

# Check config has scholar section
cat .flow/teach-config.yml
```

### Deploy takes too long

- Check GitHub Actions tab for build status
- Verify `_quarto.yml` has no errors
- Try `quarto preview` locally first

---

## What's Next?

### Learn More About Teaching Workflow

- **[Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)** - Comprehensive workflow documentation
- **[Scholar Wrappers Guide](../guides/SCHOLAR-WRAPPERS-GUIDE.md)** - Complete guide to all 9 AI content generation commands
- **[Teaching System Architecture](../guides/TEACHING-SYSTEM-ARCHITECTURE.md)** - How flow-cli and Scholar work together
- **[Teach Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher)** - Complete command reference
- **[All Commands Quick Reference](../reference/REFCARD-TEACH-DISPATCHER.md)** - All 29 teach subcommands at a glance
- **[Config Schema Reference](../reference/TEACH-CONFIG-SCHEMA.md)** - Every teach-config.yml field documented
- **[Deployment Guide](../guides/TEACH-DEPLOY-GUIDE.md)** - Local preview to production deployment

### Master Scholar Enhancement (AI Content Generation)

The Scholar Enhancement provides powerful AI-assisted content generation with 47 flags and 4 style presets. Learn through our progressive tutorial series:

- **[🎓 Scholar Enhancement Overview](scholar-enhancement/index.md)** - Start here! (~65 min total)
  - **[Level 1: Getting Started](scholar-enhancement/01-getting-started.md)** - Style presets & content flags (10 min)
  - **[Level 2: Intermediate](scholar-enhancement/02-intermediate.md)** - Lesson plans & interactive mode (20 min)
  - **[Level 3: Advanced](scholar-enhancement/03-advanced.md)** - Revision workflow & context integration (35 min)

### Deep Dive into Scholar

- **[Scholar Enhancement API Reference](../reference/MASTER-API-REFERENCE.md#teaching-libraries)** - All 47 flags, 50+ examples
- **[Scholar Enhancement Architecture](../architecture/SCHOLAR-ENHANCEMENT-ARCHITECTURE.md)** - System design with 15+ diagrams

---

**Tip:** Start with `teach status` to see your course dashboard, and `teach deploy` whenever you're ready to go live!
