---
tags:
  - tutorial
  - getting-started
  - commands
---

# Tutorial: Your First Flow Session

> **What you'll build:** Track and complete your first focused work session using Flow CLI
>
> **Time:** ~15 minutes | **Level:** Beginner

---

## Prerequisites

Before starting, you should:

- [ ] Have Flow CLI installed (`~/.config/zsh/` directory exists)
- [ ] Have at least one project in `~/projects/`
- [ ] Know how to use terminal and ZSH

**Verify your setup:**

```bash
# Check Flow CLI is installed
ls ~/.config/zsh/functions/adhd-helpers.zsh

# Check you have projects
ls ~/projects/
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Start a focused work session on a project
2. Track your progress during the session
3. Use project context commands
4. End the session and save your work

---

## Overview

Flow CLI helps you stay focused by tracking work sessions. Here's the workflow:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Pick Project  │ --> │   Work on It   │ --> │  End Session   │
│  (just-start)  │     │   (commands)   │     │   (finish)     │
└────────────────┘     └────────────────┘     └────────────────┘
```

---

## Part 1: Starting Your First Session

### Step 1.1: Check What's Available

Let's see what projects you can work on:

```bash
dash
```

**What happened:** You see a dashboard showing all your projects organized by status (Active, Ready, Paused, Blocked).

Example output:

```
╭─────────────────────────────────────────────╮
│ 🎯 YOUR WORK DASHBOARD                      │
╰─────────────────────────────────────────────╯

🔥 ACTIVE NOW (2):
  📦 flow-cli [P0] 95% - Documentation improvements
  📚 stat-440 [P1] 60% - Grade assignments

📋 READY TO START (1):
  📊 research-project [P2] 20% - Literature review
```

### Step 1.2: Let Flow Pick For You

Instead of deciding, let Flow choose based on priority:

```bash
just-start
```

**What happened:** Flow automatically selects your highest-priority active project and shows you the details:

```
🎲 Finding your next task...

┌─────────────────────────────────────────────┐
│ 🎯 DECISION MADE FOR YOU                    │
├─────────────────────────────────────────────┤
│ Project: 📦 flow-cli                        │
│ Type:    dev-tools                          │
│ Reason:  P0 priority (critical)             │
│ Next:    Documentation improvements         │
└─────────────────────────────────────────────┘

💡 Quick actions:
   work .        = Start session
   work . -e     = Start session + open editor
   status .      = Update status
   dash          = See all projects

📁 /Users/dt/projects/dev-tools/flow-cli
```

> **Note:** Flow picks based on: P0 active → P1 active → any active → most recent

### Step 1.3: Start Working

Now start a session on the project:

```bash
work .
```

**What happened:** Flow starts a work session — it `cd`s into the project, shows context, and begins session tracking.

> **Want an editor too?** Add `-e` to open one:
>
> ```bash
> work . -e          # Opens your $EDITOR
> work . -e code     # Opens VS Code
> work . -e cc       # Opens Claude Code
> ```

### Checkpoint

At this point, you should have:

- [x] Viewed your dashboard
- [x] Let Flow pick a project
- [x] Started a session on the project

**Verify:**

```bash
pwd
# Expected: You're in the project directory
```

---

## Part 2: Working in the Session

### Step 2.1: Start a Timed Session

Now set a focus timer to stay on track:

```bash
f25
```

**What happened:** A 25-minute Pomodoro timer starts. Your terminal shows a countdown.

Example output:

```
🍅 Pomodoro Timer Started!
⏱️  25:00 remaining...

[Terminal shows countdown in prompt]
```

> **Tip:** Use `f50` for a 50-minute deep work session instead

### Step 2.2: Check Your Context

If you forget what you're working on:

```bash
why
```

**What happened:** Shows your current project context:

```
📍 CURRENT CONTEXT

Project:  flow-cli
Type:     dev-tools
Location: /Users/dt/projects/dev-tools/flow-cli
Status:   ACTIVE (P0)
Task:     Documentation improvements
Progress: 95%

Active since: 14 minutes ago
```

### Step 2.3: Work on Your Task

Now do your actual work! For example:

- Edit files in your editor
- Run tests
- Write documentation
- Code features

**Project-specific commands:**

```bash
# For R packages
rload        # Load package
rtest        # Run tests
rdoc         # Generate docs

# For development projects
npm test     # Run tests
npm run build # Build project

# Git workflow
gst          # Check status (git status)
ga .         # Stage changes (git add .)
gcmsg "msg"  # Commit (git commit -m "msg")
```

### Step 2.4: Log Your Wins

When you accomplish something:

```bash
win "Completed first Flow tutorial"
```

**What happened:** Your accomplishment is logged to track progress.

### Checkpoint

At this point, you should have:

- [x] Started a focus timer
- [x] Checked your context
- [x] Done actual work
- [x] Logged at least one win

**Verify:**

```bash
wins
# Expected: See your logged wins for today
```

---

## Part 3: Ending Your Session

### Step 3.1: Update Your Progress

Before ending, update the project status:

```bash
status .
```

**What happened:** Flow asks for updates interactively:

```
📋 UPDATE STATUS: flow-cli
═══════════════════════════════════════════

Current values shown in [brackets]

Status? [active]
   (active/paused/blocked/ready)
> active

Priority? [P0]
   (P0=critical, P1=important, P2=normal)
> P0

Next task? [Documentation improvements]
> Complete tutorial files

Progress? [95]
   (0-100)
> 100

✅ Updated! Press Enter to continue...
```

> **Tip:** Press Enter to keep current values, only type when you want to change something

### Step 3.2: Commit Your Changes

If you made code changes, commit them:

```bash
gst          # Check what changed
gaa          # Stage all changes
gcmsg "docs: add first session tutorial"
gp           # Push to remote
```

### Step 3.3: View Today's Wins

See what you accomplished:

```bash
wins
```

**What happened:** Lists all wins you logged today:

```
🎉 TODAY'S WINS (2025-12-24)
═══════════════════════════════════════════
1. ✅ Completed first Flow tutorial
2. ✅ Updated project documentation

💪 Great work today!
```

### Understanding Session Tracking

Flow CLI tracks your work sessions in `~/.config/zsh/.worklog`:

| Field        | Meaning                      |
| ------------ | ---------------------------- |
| `project`    | Current project name         |
| `start_time` | When you started working     |
| `duration`   | How long you've been working |
| `task`       | What you're currently doing  |

This helps you:

- Remember where you left off
- Track time spent on projects
- Generate progress reports

---

## Putting It All Together

Here's the complete workflow you just learned:

```bash
# Morning: Start your day
dash                    # See all projects
just-start             # Auto-pick highest priority
work .                 # Start session
work . -e              # Start + open editor (optional)

# During work
f25                    # Start 25-min timer
# ... do your work ...
win "Completed feature X"

# Check context if needed
why                    # Where am I? What am I doing?

# End of session
status .               # Update progress
gaa && gcmsg "msg"     # Commit changes
wins                   # See accomplishments
```

**Time:** <3 minutes to start/end, focused time in between

---

## Exercises

Practice what you learned with these challenges:

### Exercise 1: Start a Session on a Different Project

Try starting a session on a different project.

<details>
<summary>Hint</summary>

Use `work <project-name>` to switch projects, or `pick` for fuzzy search.

</details>

<details>
<summary>Solution</summary>

```bash
# Option 1: Direct name
work research-project

# Option 2: Fuzzy search
pick
# Type partial name, select with arrows, press Enter

# Option 3: Use dashboard
dash research        # Filter by category
work research-project
```

</details>

### Exercise 2: Update Multiple Projects

Update the status of 2-3 projects.

<details>
<summary>Solution</summary>

```bash
status flow-cli active P0 "Next task" 100
status research-project paused P2 "Resume next week" 20
status stat-440 active P1 "Grade final exams" 80

# Verify
dash
```

</details>

### Exercise 3: Create a New Project

Create a `.STATUS` file for a new project.

<details>
<summary>Solution</summary>

```bash
# Navigate to project
cd ~/projects/your-category/new-project

# Create .STATUS file
status new-project --create

# Answer prompts or use quick mode
status new-project ready P2 "Initial setup" 0

# Verify it appears in dashboard
dash
```

</details>

---

## Common Issues

### "command not found: dash"

**Cause:** Flow CLI functions not loaded in your shell

**Fix:**

```bash
# Reload your shell configuration
source ~/.zshrc

# Or check if functions exist
ls ~/.config/zsh/functions/adhd-helpers.zsh
```

### "No projects found"

**Cause:** Projects not in expected locations or missing `.STATUS` files

**Fix:**

```bash
# Create .STATUS for existing projects
cd ~/projects/your-project
status your-project --create

# Check project structure
ls ~/projects/
```

### "Editor didn't open"

**Cause:** You need the `-e` flag to open an editor (v7.2.1+)

**Fix:**

```bash
# Use -e to open an editor
work . -e          # Uses $EDITOR
work . -e code     # VS Code
work . -e positron # Positron

# Or open manually
code .     # VS Code
rstudio .  # RStudio
```

---

## Summary

In this tutorial, you learned:

| Concept       | What You Did                      |
| ------------- | --------------------------------- |
| Dashboard     | Viewed all projects with `dash`   |
| Auto-pick     | Let Flow choose with `just-start` |
| Start work    | Started session with `work`       |
| Focus timer   | Used `f25` for Pomodoro           |
| Track wins    | Logged accomplishments with `win` |
| Update status | Used `status` to track progress   |
| Check context | Used `why` to see current state   |

**Key commands:**

```bash
dash           # View all projects
just-start     # Auto-pick project
work .         # Start session
work . -e      # Start + open editor
f25            # Start 25-min timer
why            # Check context
win "msg"      # Log accomplishment
wins           # See today's wins
status .       # Update progress
```

---

## Next Steps

Continue your learning:

1. **[Tutorial 2: Tracking Multiple Projects](02-multiple-projects.md)** — Manage multiple active projects
2. **[Tutorial 3: Using Status Visualizations](03-status-visualizations.md)** — Understand progress bars and charts
3. **[Workflow Quick Reference](../help/WORKFLOWS.md)** — Daily workflows

---

## Quick Reference

```
┌─────────────────────────────────────────────────────┐
│  FIRST SESSION WORKFLOW                             │
├─────────────────────────────────────────────────────┤
│  dash          View all projects                    │
│  just-start    Auto-pick highest priority           │
│  work .        Start session                         │
│  work . -e     Start + open editor                   │
│  f25           Start 25-min timer                   │
│  why           Check current context                │
│  win "..."     Log accomplishment                   │
│  status .      Update progress                      │
│  wins          See today's wins                     │
├─────────────────────────────────────────────────────┤
│  Workflow: dash → just-start → work [-e] → f25      │
└─────────────────────────────────────────────────────┘
```
