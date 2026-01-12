# Tutorial: Tracking Multiple Projects

> **What you'll build:** Manage and switch between multiple active projects efficiently
>
> **Time:** ~20 minutes | **Level:** Intermediate

---

## Prerequisites

Before starting, you should:

- [ ] Completed: [Tutorial 1: Your First Flow Session](01-first-session.md)
- [ ] Have 3+ projects in `~/projects/`
- [ ] Understand basic `dash` and `status` commands

**Verify your setup:**

```bash
# Check you have multiple projects
dash | grep -E "ACTIVE|READY"

# Should see at least 2-3 projects
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Organize projects by category and priority
2. Switch between projects efficiently
3. Use filtering to focus on specific work
4. Balance multiple projects without overwhelm

---

## Overview

Managing multiple projects is common - you might have:

- Teaching + Research + Package development
- Multiple client projects
- Personal projects + Work projects

Flow CLI helps you juggle these without losing track:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  All Projects│ --> │Filter Category│ --> │ Work on One │
│   (dash)     │     │  (dash X)     │     │   (work X)   │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## Part 1: Organizing Projects

### Step 1.1: View All Projects

Start by seeing everything:

```bash
dash
```

**What happened:** You see projects grouped by status:

```
╭─────────────────────────────────────────────╮
│ 🎯 YOUR WORK DASHBOARD                      │
╰─────────────────────────────────────────────╯

🔥 ACTIVE NOW (5):
  📦 mediationverse [P0] 85% - Final simulations
  📚 stat-440 [P0] 60% - Grade midterms
  🔧 flow-cli [P1] 95% - Documentation
  📊 collider [P1] 90% - Waiting for review
  📦 medfit [P2] 30% - Add vignettes

📋 READY TO START (3):
  📊 product-of-three [P1] 60% - Review simulations
  📦 rmediation [P2] 0% - Add new feature
  📚 causal-inference [P2] 0% - Prep next semester
```

> **Note:** Too many active projects? This is common - we'll fix it!

### Step 1.2: Filter by Category

Focus on one type of work:

```bash
# Teaching projects only
dash teaching
```

**What happened:** Shows only teaching-related projects:

```
╭─────────────────────────────────────────────╮
│ 🎯 TEACHING PROJECTS                        │
╰─────────────────────────────────────────────╯

🔥 ACTIVE (2):
  📚 stat-440 [P0] 60% - Grade midterms
  📚 causal-inference [P2] 0% - Prep next semester
```

**Other category filters:**

```bash
dash research      # Research projects only
dash packages      # R packages only
dash dev           # Development tools
```

### Step 1.3: Prioritize What Matters

Identify which projects should be active:

```bash
# View by priority
dash | grep P0     # Critical projects
dash | grep P1     # Important projects
dash | grep P2     # Normal projects
```

### Checkpoint

At this point, you should have:

- [x] Viewed all projects
- [x] Filtered by category
- [x] Identified priorities

**Verify:**

```bash
# Count active projects
dash | grep "ACTIVE NOW" -A 20 | grep -c "%"
# Expected: Number of your active projects (should be 2-4 ideally)
```

---

## Part 2: Project Switching Strategies

### Step 2.1: Context-Based Switching

Switch based on what you're doing:

```bash
# Morning: Teaching focus
dash teaching
work stat-440

# Afternoon: Research focus
dash research
work collider

# Evening: Package development
dash packages
work mediationverse
```

### Step 2.2: Priority-Based Switching

Let Flow pick based on priority:

```bash
just-start
```

**What happened:** Flow selects the highest-priority project automatically:

```
🎲 Finding your next task...

┌─────────────────────────────────────────────┐
│ 🎯 DECISION MADE FOR YOU                    │
├─────────────────────────────────────────────┤
│ Project: 📚 stat-440                        │
│ Type:    teaching                           │
│ Reason:  P0 priority + active               │
│ Next:    Grade midterms                     │
└─────────────────────────────────────────────┘
```

**How it picks:**

1. P0 + active (most urgent)
2. P1 + active (important)
3. Any active (current work)
4. Most recent (what you touched last)

### Step 2.3: Manual Project Selection

Use the project picker for fuzzy search:

```bash
pick
```

**What happened:** Interactive fuzzy finder shows all projects. Type to filter:

!!! tip "⚡ Instant Performance"
    The `pick` command is cached (5-minute TTL) for 40x faster response (<10ms). You won't notice any delay even with 100+ projects.

```
> med_
  📦 mediationverse
  📦 medfit
  📦 rmediation
  📚 mediation-planning
```

Use arrow keys to select, press Enter to navigate.

### Step 2.4: Quick Navigation

For projects you know:

```bash
# Full name
work mediationverse

# Partial name (fuzzy match)
work med           # → mediationverse
work stat          # → stat-440
work coll          # → collider
```

### Checkpoint

At this point, you should have:

- [x] Switched between categories
- [x] Used priority-based selection
- [x] Tried the project picker
- [x] Navigated by name

**Verify:**

```bash
pwd
# Expected: You're in a different project than you started
```

---

## Part 3: Managing Project States

### Step 3.1: Pause Projects

Too many active projects? Pause the less urgent ones:

```bash
# Pause a project
status medfit
```

Interactive prompt:

```
Status? [active]
> paused

Priority? [P2]
> P2

Next task? [Add vignettes]
> Resume when time allows

Progress? [30]
> 30

✅ Updated!
```

Or quick mode:

```bash
status medfit paused P2 "Resume later" 30
```

### Step 3.2: Reactivate Projects

When ready to resume:

```bash
status medfit active P1 "Add package vignettes" 30
```

### Step 3.3: Mark Projects as Blocked

If waiting on something:

```bash
status collider blocked P1 "Waiting for reviewer comments" 90
```

**What happened:** Project moves to BLOCKED section in dashboard:

```
🚫 BLOCKED (1):
  📊 collider [P1] 90% - Waiting for reviewer comments
```

### Step 3.4: Set Realistic Priorities

Review and adjust priorities:

```bash
# Critical (do today)
status mediationverse active P0 "Final simulations" 85

# Important (this week)
status product-of-three active P1 "Review sims" 60

# Normal (when you can)
status medfit paused P2 "Resume later" 30
```

**Priority guidelines:**

| Priority | Meaning          | How many? |
| -------- | ---------------- | --------- |
| P0       | Critical, urgent | 1-2 max   |
| P1       | Important        | 2-3       |
| P2       | Normal           | Unlimited |

> **Warning:** More than 2 P0 projects = everything is urgent = nothing is urgent

### Checkpoint

At this point, you should have:

- [x] Paused at least one project
- [x] Updated priorities realistically
- [x] Marked a blocked project (if applicable)

**Verify:**

```bash
dash
# Expected: Fewer ACTIVE projects, some PAUSED/BLOCKED
```

---

## Part 4: Daily Workflows

### Workflow 1: Morning Routine (Teaching Day)

```bash
# 1. See teaching work
dash teaching

# 2. Auto-select highest priority
just-start

# 3. Start working
work .

# 4. Set focus timer
f25
```

**Time:** <30 seconds
**Result:** Working on most important teaching task

### Workflow 2: Research Block

```bash
# 1. Filter research projects
dash research

# 2. Pick specific project
work collider

# 3. Long focus session
f50

# 4. Work, then update
status . active P1 "Completed analysis" 95
```

**Time:** <20 seconds
**Result:** Focused research session

### Workflow 3: Package Development

```bash
# 1. View R packages
dash packages

# 2. Select by name
work mediationverse

# 3. R package workflow
rload
rtest
rdoc

# 4. Commit progress
gaa && gcmsg "feat: add new mediator"
status . active P0 "Testing complete" 90
```

**Time:** Varies by development
**Result:** Incremental package progress

### Workflow 4: Weekly Review

```bash
# 1. See everything
dash

# 2. Review each category
dash teaching
dash research
dash packages

# 3. Update all statuses
status stat-440 active P0 "Grade finals" 80
status collider blocked P1 "Waiting" 90
status mediationverse active P0 "Almost done" 95

# 4. Pause what you can't do this week
status medfit paused P2 "Next week" 30
```

**Time:** 5-10 minutes weekly
**Result:** Realistic priorities set

### Workflow 5: Context Switching

When interrupted:

```bash
# 1. Update current project
status . paused P0 "Resume after meeting" 75

# 2. Switch to urgent task
just-start

# 3. Work on it
work .
f25

# 4. Return to original
work mediationverse
status . active P0 "Resume work" 75
```

---

## Exercises

### Exercise 1: Balance Your Projects

Review your active projects and balance them.

**Goal:** 2-4 active projects max, rest paused/ready

<details>
<summary>Hint</summary>

Run `dash`, count active projects. Pause anything not P0/P1 or not immediately actionable.

</details>

<details>
<summary>Solution</summary>

```bash
# 1. View current state
dash

# 2. Pause low-priority active projects
status medfit paused P2 "Do later" 30
status causal-inference paused P2 "Next semester" 0

# 3. Keep only critical/important active
status mediationverse active P0 "Final push" 85
status stat-440 active P0 "Urgent grading" 60
status flow-cli active P1 "Documentation" 95

# 4. Verify
dash
# Should see 2-4 active, rest paused
```

</details>

### Exercise 2: Category-Based Day

Plan a day focusing on one category.

<details>
<summary>Solution</summary>

```bash
# Morning: Teaching focus
dash teaching
work stat-440
f50
# ... work ...
status . active P0 "Graded 20 exams" 70

# Afternoon: Research focus
dash research
work collider
f50
# ... work ...
status . active P1 "Finished analysis" 95

# Evening: Package development
dash packages
work mediationverse
f25
# ... work ...
status . active P0 "All tests pass" 90
```

</details>

### Exercise 3: Emergency Project

Handle an urgent new project without losing track of current work.

<details>
<summary>Solution</summary>

```bash
# 1. Pause current project
cd ~/projects/current-project
status . paused P1 "Emergency interrupt - resume ASAP" 60

# 2. Create new urgent project
cd ~/projects/urgent-project
status urgent-project --create
status urgent-project active P0 "Critical fix" 0

# 3. Work on it
work .
# ... fix the issue ...
status . active P0 "Fixed critical bug" 100

# 4. Mark complete and return
status . ready P2 "Done - archive if needed" 100

# 5. Resume original work
work current-project
status . active P1 "Resume work" 60
```

</details>

---

## Common Issues

### "Too many active projects"

**Cause:** Everything marked as active

**Fix:**

```bash
# Pause non-urgent projects
dash | grep ACTIVE
# Pick 2-3 most important
# Pause the rest
status project-name paused P2 "Do later" X
```

### "Can't decide what to work on"

**Cause:** Unclear priorities

**Fix:**

```bash
# Let Flow decide
just-start

# Or filter and pick
dash teaching      # Focus on one category
work stat-440      # Pick the urgent one
```

### "Switching too frequently"

**Cause:** No time blocks

**Fix:**

```bash
# Set category-based time blocks
# Morning: Teaching
dash teaching && work . && f50

# Afternoon: Research
dash research && work . && f50

# Use timers to enforce focus
```

---

## Summary

In this tutorial, you learned:

| Concept    | What You Did                        |
| ---------- | ----------------------------------- |
| Filtering  | Used `dash <category>` to focus     |
| Switching  | Used `work`, `pick`, `just-start`   |
| States     | Paused, blocked, activated projects |
| Priorities | Set P0/P1/P2 realistically          |
| Workflows  | Category-based and priority-based   |

**Key commands:**

```bash
dash <category>    # Filter by category
just-start         # Auto-pick by priority
pick               # Fuzzy search projects
work <name>        # Switch to project
status . paused    # Pause current
status . active    # Activate project
status . blocked   # Mark blocked
```

**Key insights:**

- **2-4 active projects max** - Rest should be paused/ready
- **Use categories** - Focus time on one area
- **Let Flow pick** - Reduces decision fatigue
- **Update statuses** - Keeps dashboard accurate

---

## Next Steps

Continue your learning:

1. **[Tutorial 3: Using Status Visualizations](03-status-visualizations.md)** — Understand progress bars and charts
2. **[Tutorial 4: Web Dashboard Deep Dive](04-web-dashboard.md)** — Use the browser-based dashboard
3. **[Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)** — Advanced workflows

---

## Quick Reference

```
┌───────────────────────────────────────────────────────┐
│  MULTIPLE PROJECTS WORKFLOW                           │
├───────────────────────────────────────────────────────┤
│  dash              View all projects                  │
│  dash <category>   Filter by category                 │
│  just-start        Auto-pick highest priority         │
│  pick              Fuzzy search all projects          │
│  work <name>       Switch to specific project         │
│  status . paused   Pause current project              │
│  status . active   Activate project                   │
│  status . blocked  Mark as blocked                    │
├───────────────────────────────────────────────────────┤
│  Priorities:                                          │
│    P0 = Critical (1-2 max)                            │
│    P1 = Important (2-3)                               │
│    P2 = Normal (unlimited)                            │
├───────────────────────────────────────────────────────┤
│  Golden Rule: Keep 2-4 active max, pause the rest!   │
└───────────────────────────────────────────────────────┘
```
