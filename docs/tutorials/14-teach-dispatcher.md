# Tutorial: Teaching Workflow with Teach Dispatcher

> **What you'll learn:** Manage course websites with fast deployment and AI-assisted content creation
>
> **Time:** ~15 minutes | **Level:** Beginner
> **Version:** v5.8.0+

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
2. Deploy changes to production in < 2 minutes
3. Use the branch-based draft/production workflow
4. Generate teaching content with Scholar integration
5. Archive semesters for future reference

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

## Part 3: Daily Workflow

### Step 3.1: Start Working

```bash
work stat-545
```

**What happens:**
- Checks you're on the `draft` branch
- **Warns if on production** (students see this!)
- Loads course context
- Opens your editor

### Step 3.2: Make Edits

Edit your lecture notes, slides, or assignments as usual.

### Step 3.3: Deploy to Production

When you're ready for students to see your changes:

```bash
teach deploy
```

**What happens:**
1. Commits any uncommitted changes
2. Merges `draft` → `production`
3. Pushes to GitHub
4. GitHub Actions builds the site
5. Students see updates in < 2 minutes

### Step 3.4: Check Current Week

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

## Part 4: Scholar Integration (AI Content)

The teach dispatcher wraps Scholar commands for AI-assisted content creation.

### Step 4.1: Generate Exam Questions

```bash
teach exam "Midterm 1" --questions 25
```

**What happens:**
- Invokes Scholar's `/teaching:exam` command
- Generates questions based on your course config
- Outputs to `exams/midterm-1.md`

### Step 4.2: Create Quiz

```bash
teach quiz "Week 3" --questions 10
```

### Step 4.3: Generate Lecture Outline

```bash
teach lecture "Data Wrangling"
```

### Step 4.4: Create Assignment

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

## Part 5: Semester Management

### Step 5.1: Archive Current Semester

At the end of the semester:

```bash
teach archive
```

**What happens:**
- Creates a git tag: `fall-2025` (or current semester)
- Preserves the semester snapshot
- You can restore later if needed

### Step 5.2: Prepare for New Semester

```bash
teach config
```

Update semester dates, week count, and topics for the new term.

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `teach init "Course"` | Initialize teaching workflow |
| `teach status` | Show course dashboard |
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

- **[Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)** - Comprehensive workflow documentation
- **[Teaching System Architecture](../guides/TEACHING-SYSTEM-ARCHITECTURE.md)** - How flow-cli and Scholar work together
- **[Teach Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE.md)** - Complete command reference

---

**Tip:** Start with `teach status` to see your course dashboard, and `teach deploy` whenever you're ready to go live!
