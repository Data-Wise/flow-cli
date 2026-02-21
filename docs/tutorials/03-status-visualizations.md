# Tutorial: Using Status Visualizations

> **What you'll build:** Understanding and using visual progress indicators effectively
>
> **Time:** ~15 minutes | **Level:** Intermediate

---

## Prerequisites

Before starting, you should:

- [ ] Completed: [Tutorial 2: Tracking Multiple Projects](02-multiple-projects.md)
- [ ] Have projects with progress tracked (0-100%)
- [ ] Understand basic `status` command

**Verify your setup:**

```bash
# Check you have projects with progress
dash | grep "%"

# Should see percentage values for projects
```diff

---

## What You'll Learn

By the end of this tutorial, you will:

1. Read and interpret progress bars
2. Use progress tracking to stay motivated
3. Understand project metrics and statistics
4. Create accurate progress estimates

---

## Overview

Flow CLI uses visual indicators to make progress tangible:

```text
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  Update %     │ --> │  See Progress │ --> │ Stay Motivated│
│  (status)     │     │   (dash)      │     │   (wins)      │
└───────────────┘     └───────────────┘     └───────────────┘
```diff

Visual feedback helps ADHD-friendly workflows by:

- Making abstract progress concrete
- Providing dopamine hits when bars fill up
- Showing momentum across multiple projects

---

## Part 1: Understanding Progress Indicators

### Step 1.1: Basic Progress Display

View a project's progress:

```bash
dash
```text

**What you'll see:**

```text
🔥 ACTIVE NOW (3):
  📦 mediationverse [P0] 85% - Final simulations
  📚 stat-440 [P1] 60% - Grade midterms
  🔧 flow-cli [P2] 95% - Documentation
```bash

**Progress breakdown:**

| Range  | Color        | Meaning         |
| ------ | ------------ | --------------- |
| 0-25%  | Red          | Just started    |
| 26-50% | Yellow       | Making progress |
| 51-75% | Cyan         | Over halfway    |
| 76-99% | Green        | Almost done     |
| 100%   | Bright Green | Complete!       |

### Step 1.2: Detailed Progress Bars

Some commands show full progress bars:

```bash
# View detailed status (if implemented)
status mediationverse --show
```text

**What you might see:**

```yaml
📦 mediationverse
═══════════════════════════════════════════

Status:   🔥 ACTIVE
Priority: [P0] Critical
Progress: ████████████████░░░░ 85%
Task:     Final simulations
Updated:  2025-12-24

Recent progress:
  Dec 20: 60% → 70% (+10%)
  Dec 22: 70% → 80% (+10%)
  Dec 24: 80% → 85% (+5%)
```text

### Step 1.3: Category Summaries

See aggregate progress:

```bash
dash teaching
```text

**What you'll see:**

```text
╭─────────────────────────────────────────────╮
│ 🎯 TEACHING PROJECTS (2)                    │
│ Average progress: 45%                       │
╰─────────────────────────────────────────────╯

🔥 ACTIVE (2):
  📚 stat-440 [P0] 60% - Grade midterms
  📚 causal-inference [P2] 30% - Prep syllabus
```diff

### Checkpoint

At this point, you should understand:

- [x] Progress percentage colors
- [x] How to view progress in dashboard
- [x] What different ranges mean

**Verify:**

```bash
dash | grep "%"
# Expected: See projects with different progress levels
```bash

---

## Part 2: Tracking Progress Effectively

### Step 2.1: Starting a New Project (0%)

When starting fresh:

```bash
cd ~/projects/new-project
status new-project --create
status new-project ready P2 "Initial setup" 0
```text

**What happened:** Project created at 0%:

```text
📋 READY TO START (1):
  📊 new-project [P2] 0% - Initial setup
```sql

### Step 2.2: Small Incremental Updates

Update progress in small chunks:

```bash
# First day: Basic setup
status new-project active P2 "Setup environment" 10

# Next day: Start coding
status new-project active P2 "First feature" 25

# Week later: Halfway
status new-project active P2 "Core complete" 50
```diff

**Why small increments?**

- More accurate than big jumps
- More frequent dopamine hits
- Easier to estimate remaining work

### Step 2.3: The 80-20 Rule

Many projects follow this pattern:

```text
0-80%:   Fast progress (easy work)
80-95%:  Slow progress (hard/tedious work)
95-100%: Very slow (polish, edge cases)
```bash

**Example progression:**

```bash
# Week 1-2: Fast progress
status project active P1 "Core features" 80

# Week 3: Slows down
status project active P1 "Bug fixes" 85

# Week 4: Tedious work
status project active P1 "Edge cases" 90

# Week 5: Final polish
status project active P1 "Documentation" 95

# Week 6: Complete
status project ready P2 "Done!" 100
```diff

> **Tip:** Don't be discouraged when 80-100% takes as long as 0-80%!

### Step 2.4: Progress Milestones

Set checkpoints:

| Progress | Milestone   | Task Example                    |
| -------- | ----------- | ------------------------------- |
| 0%       | Planning    | "Define scope and requirements" |
| 25%      | Foundation  | "Basic setup complete"          |
| 50%      | Core        | "Main features implemented"     |
| 75%      | Integration | "Everything connected"          |
| 90%      | Polish      | "Bug fixes and cleanup"         |
| 100%     | Done        | "Ready for release"             |

### Checkpoint

At this point, you should:

- [x] Know how to track new projects
- [x] Understand incremental updates
- [x] Recognize the 80-20 pattern

**Verify:**

```bash
# Update a project with new milestone
status . active P1 "Reached 75% milestone" 75
dash
# Expected: See updated progress
```bash

---

## Part 3: Staying Motivated with Progress

### Step 3.1: Celebrate Progress

When you cross milestones:

```bash
# Hit 50%!
status . active P0 "Halfway done!" 50
win "Reached 50% on mediationverse package!"

# Hit 75%!
status . active P0 "Almost there!" 75
win "75% complete - final push!"

# Hit 100%!
status . ready P2 "Complete!" 100
win "COMPLETED mediationverse package!!!"
```bash

### Step 3.2: Track Velocity

How fast are you progressing?

```bash
# Monday
status project active P1 "Start work" 10

# Friday
status project active P1 "Week complete" 30

# Velocity: 20% per week
# Estimate: 3.5 weeks to complete (70% remaining / 20% per week)
```text

**Track in your task description:**

```bash
status project active P1 "Week 2 - on track (+20%)" 30
```bash

### Step 3.3: Use Visual Momentum

Seeing multiple projects advance creates momentum:

```bash
# Before (Monday)
dash
# mediationverse: 65%
# stat-440: 40%
# flow-cli: 80%

# After (Friday)
dash
# mediationverse: 75% ⬆️ +10%
# stat-440: 60% ⬆️ +20%
# flow-cli: 90% ⬆️ +10%

win "Productive week! All projects advanced!"
```bash

### Step 3.4: Handle Setbacks

Sometimes progress goes backward:

```bash
# Discovered major bug, need to redo work
status project active P0 "Fix critical bug - set back" 70

# Previous was 85%, now 70% (-15%)
```diff

**This is OK!** Accurate progress > inflated numbers.

### Checkpoint

At this point, you should:

- [x] Celebrate milestones with `win`
- [x] Track velocity (% per week)
- [x] Use visual momentum
- [x] Handle setbacks honestly

**Verify:**

```bash
wins
# Expected: See celebration wins for milestones
```bash

---

## Part 4: Advanced Progress Techniques

### Technique 1: Sub-Project Breakdown

For large projects, track components:

```bash
# Main project
status mediationverse active P0 "Package development" 75

# Mental breakdown (not tracked in tool):
# - Core functions: 90% (mostly done)
# - Tests: 80% (good coverage)
# - Documentation: 60% (needs work)
# - Vignettes: 50% (in progress)
# Average: (90+80+60+50)/4 = 70%

# Update based on weighted average
status mediationverse active P0 "Focus on docs/vignettes" 70
```bash

### Technique 2: Must-Have vs Nice-to-Have

Adjust progress based on scope:

```bash
# Original plan (100% = everything)
status project active P1 "All features" 60

# Scope reduction (100% = must-haves only)
status project active P1 "Core features only" 85

# Suddenly much closer to done!
```bash

### Technique 3: Time-Based vs Work-Based

Two ways to track:

**Time-based (not recommended):**

```bash
# Week 1 of 10 = 10%
status project active P1 "Week 1" 10
```bash

**Work-based (recommended):**

```bash
# 3 of 10 features done = 30%
status project active P1 "3/10 features" 30
```bash

> **Tip:** Work-based is more accurate because work rarely distributes evenly over time.

### Technique 4: Done is Better Than Perfect

Don't wait for 100% perfection:

```bash
# 95% complete, could polish forever
status project active P1 "Good enough to ship" 95

# Ship it!
status project ready P2 "Shipped v1.0!" 100
win "Shipped project v1.0 - done is better than perfect!"

# Future improvements are a new project
status project-v2 ready P2 "Enhancements for v2" 0
```bash

---

## Exercises

### Exercise 1: Estimate a New Project

Break down and estimate a new project.

<details>
<summary>Hint</summary>

List all major tasks, estimate time for each, calculate total, set milestones.

</details>

<details>
<summary>Solution</summary>

```bash
# New R package project
cd ~/projects/r-packages/active/newpackage

# Break down tasks:
# 1. Setup (5%) - 1 day
# 2. Core functions (30%) - 1 week
# 3. Tests (20%) - 3 days
# 4. Documentation (20%) - 3 days
# 5. Vignettes (15%) - 2 days
# 6. Final checks (10%) - 1 day

# Start tracking
status newpackage ready P2 "Planning complete" 0

# After setup
status newpackage active P1 "Package skeleton created" 5

# After core
status newpackage active P1 "Main functions working" 35

# Continue incrementally...
```bash

</details>

### Exercise 2: Recover from Setback

Handle a project that went backwards.

<details>
<summary>Solution</summary>

```bash
# Before: thought you were at 80%
status project active P0 "Found major issue" 80

# After analysis: need to redo significant work
status project active P0 "Revising approach - realistic reset" 60

# Document why
win "Discovered issue early - better to fix now than later"

# Make steady progress forward
status project active P0 "Fixed root cause" 70
status project active P0 "Re-implemented correctly" 80
status project active P0 "Validated thoroughly" 90
status project ready P2 "Done right this time!" 100
```bash

</details>

### Exercise 3: Celebrate Milestones

Track and celebrate a project's key milestones.

<details>
<summary>Solution</summary>

```bash
# 0%: Start
status project active P1 "Project started" 0
win "Started new project - excited to build this!"

# 25%: Foundation
status project active P1 "Foundation solid" 25
win "25% complete - strong foundation!"

# 50%: Halfway
status project active P1 "Halfway there!" 50
win "50% COMPLETE! - past the hardest part!"

# 75%: Polish phase
status project active P1 "Polishing now" 75
win "75% done - can see the finish line!"

# 100%: Complete
status project ready P2 "DONE!" 100
win "PROJECT COMPLETE! Shipped and proud!"

# View all celebrations
wins
```bash

</details>

---

## Common Issues

### "Progress seems stuck"

**Cause:** Working on 80-100% phase (slow progress)

**Fix:**

```bash
# Break down remaining work into smaller tasks
# Update more frequently with smaller increments

# Instead of jumping from 85% to 90%:
status . active P1 "Fixed bug #1" 86
status . active P1 "Fixed bug #2" 87
status . active P1 "Added validation" 88

# Smaller wins feel better!
```bash

### "Not sure what percentage to use"

**Cause:** Unclear milestones

**Fix:**

```bash
# Use concrete milestones:
# 0%   = Planning
# 10%  = Setup complete
# 25%  = First feature working
# 50%  = Core features done
# 75%  = All features implemented
# 90%  = Testing/polish
# 100% = Complete and shipped

# Estimate based on work done vs work remaining
```bash

### "Progress feels arbitrary"

**Cause:** Not tracking concrete deliverables

**Fix:**

```bash
# Track specific completions:
status . active P1 "3 of 10 functions complete" 30
status . active P1 "7 of 15 tests passing" 47
status . active P1 "2 of 4 vignettes written" 80

# % = (completed / total) * 100
```bash

---

## Summary

In this tutorial, you learned:

| Concept              | What You Did                                   |
| -------------------- | ---------------------------------------------- |
| Progress ranges      | Understood 0-25%, 26-50%, 51-75%, 76-99%, 100% |
| Incremental tracking | Updated in small chunks for accuracy           |
| The 80-20 rule       | Expected 80-100% to be slow                    |
| Milestones           | Set and celebrated progress markers            |
| Motivation           | Used visual progress for dopamine              |
| Estimates            | Broke down work to calculate %                 |

**Key insights:**

```bash
# Track progress incrementally
status . active P1 "Task complete (+5%)" 35

# Celebrate milestones
win "Reached 50%!"

# Be honest about setbacks
status . active P0 "Reset to fix properly" 60

# Ship at 95-100%, don't wait for perfection
status . ready P2 "Good enough!" 100
```diff

**Progress tips:**

- **Small increments** - 5-10% updates feel more concrete
- **Celebrate milestones** - 25%, 50%, 75%, 100%
- **Accept setbacks** - Accurate % > inflated numbers
- **Ship it** - 95%+ is often "done enough"

---

## Next Steps

Continue your learning:

1. **[Tutorial 4: Web Dashboard Deep Dive](04-web-dashboard.md)** — Use browser-based visualizations
2. **[Command Reference: status](../commands/status.md)** — Complete status command guide
3. **[Workflows & Quick Wins](../guides/WORKFLOWS-QUICK-WINS.md)** — Advanced productivity tips

---

## Quick Reference

```text
┌─────────────────────────────────────────────────────┐
│  PROGRESS VISUALIZATION GUIDE                       │
├─────────────────────────────────────────────────────┤
│  Progress Colors:                                   │
│    0-25%   Red      (just started)                  │
│    26-50%  Yellow   (making progress)               │
│    51-75%  Cyan     (over halfway)                  │
│    76-99%  Green    (almost done)                   │
│    100%    Bright   (complete!)                     │
├─────────────────────────────────────────────────────┤
│  Milestones:                                        │
│    0%   Planning                                    │
│    25%  Foundation                                  │
│    50%  Core complete                               │
│    75%  Integration                                 │
│    90%  Polish                                      │
│    100% Done                                        │
├─────────────────────────────────────────────────────┤
│  Golden Rule: Update often, celebrate milestones!  │
└─────────────────────────────────────────────────────┘
```
