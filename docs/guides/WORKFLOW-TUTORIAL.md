# Project Management Workflow - ADHD-Friendly Tutorial

**Last Updated:** 2025-12-21 (Updated for flow-cli rename and 28-alias system)
**Read Time:** 5 minutes (lots of examples!)

---

## 🎯 The Four Commands You Need

```text
┌──────────────────────────────────────────────┐
│                                              │
│  dash       → See all your projects          │
│  just-start → Pick one automatically         │
│  work       → Start working on it            │
│  status     → Update its status              │
│                                              │
└──────────────────────────────────────────────┘
```

**That's it!** Four commands.

---

## 📖 Tutorial Format

Each command below has:

- 🎯 **What it does** (one sentence)
- 💻 **How to use it** (examples)
- ✅ **When to use it** (scenarios)
- 🎨 **What you'll see** (output examples)

**Tip:** Try each command as you read!

---

## 1️⃣ `dash` - See All Projects

### 🎯 What it does

Shows all your projects with their status, priority, and progress.

### 💻 How to use it

```bash
# See everything
dash

# Filter by category
dash teaching        # Just teaching projects
dash research        # Just research projects
dash packages        # Just R packages
dash dev             # Just dev tools
```

### ✅ When to use it

- **Morning:** Start your day - see what's active
- **Mid-day:** Check what needs attention
- **Context switch:** Remind yourself what you're working on
- **Planning:** Review all projects at once

### 🎨 What you'll see

```text
╭─────────────────────────────────────────────╮
│ 🎯 YOUR WORK DASHBOARD                      │
╰─────────────────────────────────────────────╯

🔥 ACTIVE NOW (3):
  📦 mediationverse [P0] 85% - Run final simulations
  📚 stat-440 [P1] 30% - Grade assignment 3
  🔧 flow-cli [P2] 100% - Phase 1 complete

📋 READY TO START (2):
  📦 medfit [P1] 0% - Add vignette
  📊 product-of-three [P1] 60% - Review simulations

⏸️  PAUSED (1):
  📊 collider [P2] 90% - Waiting for review

💡 Quick: work <name> to start
```

**Colors:**

- 🔥 Red = ACTIVE
- 📋 Cyan = READY
- ⏸️ Yellow = PAUSED
- 🚫 Dim = BLOCKED

**Priorities:**

- [P0] = Critical (red)
- [P1] = Important (yellow)
- [P2] = Normal (blue)

---

## 2️⃣ `just-start` - Auto-Pick Project

### 🎯 What it does

Automatically picks your highest-priority project and takes you there.

### 💻 How to use it

```bash
just-start      # That's it!
```

### ✅ When to use it

- **Morning:** Let it pick for you (zero decisions!)
- **After break:** Resume work automatically
- **Context switch:** Jump to most important thing
- **Decision paralysis:** Can't decide? Let `just-start` decide!

### 🎨 What you'll see

```text
🎲 Finding your next task...

┌─────────────────────────────────────────────┐
│ 🎯 DECISION MADE FOR YOU                    │
├─────────────────────────────────────────────┤
│ Project: 📦 mediationverse                  │
│ Type:    r-package                          │
│ Reason:  P0 priority (critical)             │
│ Next:    Run final simulations              │
└─────────────────────────────────────────────┘

💡 Quick actions:
   work .        = Start working
   status .      = Update status
   dash          = See all projects

📁 /Users/dt/projects/r-packages/active/mediationverse
```

**How it picks:**

1. P0 + active → Highest priority
2. P1 + active → Important work
3. Any active → Current work
4. Most recent → What you touched last

**Zero decisions needed!**

---

## 3️⃣ `work` - Start Working

### 🎯 What it does

Opens your editor in a project directory.

### 💻 How to use it

```bash
# Full project name
work mediationverse

# Short name (fuzzy match)
work med            # → mediationverse
work stat           # → stat-440

# From current directory
cd ~/projects/r-packages/active/mediationverse
work .              # Open current project

# No args (not implemented yet)
work                # Would open current project or show picker
```

### ✅ When to use it

- **After `just-start`:** Pick a project → start working
- **After `dash`:** See all → pick one → start
- **Direct jump:** You know what you want to work on
- **Resume work:** Jump back to a project

### 🎨 What you'll see

```bash
work mediationverse
```

**What happens:**

1. Changes to project directory
2. Detects project type (R package, Quarto, etc.)
3. Opens appropriate editor:
   - R package → RStudio or Emacs
   - Quarto → VS Code or Cursor
   - Research → Emacs
   - Dev tools → VS Code

**Editor opens automatically!**

---

## 4️⃣ `status` - Update Project Status

### 🎯 What it does

Updates a project's status, priority, task, and progress.

### 💻 How to use it

**Interactive mode** (Recommended - it guides you):

```bash
# Update specific project
status mediationverse

# What you'll see:
📋 Current status: active
   New status? (active/paused/blocked/ready): active

📊 Current priority: P0
   New priority? (P0/P1/P2): P0

📝 Current task: Run final simulations
   New task: Complete final simulations

⏱️  Current progress: 85
   New progress (0-100): 95

✅ Updated mediationverse!
```

**Quick mode** (if you know all values):

```bash
status mediationverse active P0 "Complete sims" 95
```

**Create mode** (start tracking a new project):

```bash
status newproject --create
```

**Show mode** (just view, don't update):

```bash
status mediationverse --show
```

### ✅ When to use it

- **End of work session:** Update progress before stopping
- **Status change:** Mark as paused, blocked, or active
- **Priority change:** Adjust priority as things change
- **Task complete:** Update to next task
- **New project:** Create .STATUS file

### 🎨 What you'll see (Interactive)

```text
📋 UPDATE STATUS: mediationverse
═══════════════════════════════════════════

Current values shown in [brackets]

Status? [active]
   (active/paused/blocked/ready)
> active

Priority? [P0]
   (P0=critical, P1=important, P2=normal)
> P0

Next task? [Run final simulations]
> Complete final simulations and write up

Progress? [85]
   (0-100)
> 95

✅ Updated! Press Enter to continue...
```

**Fields explained:**

- **Status:** What stage is the project in?
  - `active` = Currently working on
  - `ready` = Ready to start
  - `paused` = On hold
  - `blocked` = Waiting for something

- **Priority:** How urgent?
  - `P0` = Critical (do today!)
  - `P1` = Important (this week)
  - `P2` = Normal (when you can)

- **Task:** What's the next action?
  - Be specific: "Run simulation" not "Work on it"

- **Progress:** How far along? (0-100%)

---

## 🚀 Common Workflows

### Morning Routine

```bash
# 1. See what's active
dash

# 2. Let it pick for you
just-start

# 3. Start working
work .
```

**Time:** <30 seconds
**Decisions:** Zero

---

### Check In During Day

```bash
# Quick status check
dash

# See specific category
dash teaching

# Jump to a project
work stat-440
```

**Time:** <10 seconds

---

### End of Work Session

```bash
# Update status before leaving
status mediationverse

> Status: paused
> Priority: P0
> Task: Resume tomorrow - almost done
> Progress: 95

✅ Updated!
```

**Time:** <30 seconds
**Benefit:** You'll remember where you left off!

---

### Starting a New Project

```bash
# Create .STATUS file
cd ~/projects/r-packages/active/newpackage
status newpackage --create

# It creates:
project: newpackage
type: r-package
status: ready
priority: P2
progress: 0
next: Define first task
updated: 2025-12-14
category: r-packages

# Now appears in dashboard!
dash
```

---

### Project Switching

```bash
# See all projects
dash

# Notice something urgent
# Jump to it
work mediationverse

# Update its status
status mediationverse active P0 "Critical fix" 0
```

---

## 📊 Command Cheat Sheet

| Command                  | Does                 | Example                             |
| ------------------------ | -------------------- | ----------------------------------- |
| `dash`                   | Show all projects    | `dash`                              |
| `dash teaching`          | Filter by category   | `dash research`                     |
| `just-start`             | Auto-pick project    | `just-start`                        |
| `work <name>`            | Start working        | `work mediationverse`               |
| `work med`               | Fuzzy match          | `work stat`                         |
| `status <name>`          | Update (interactive) | `status medfit`                     |
| `status <name> ...`      | Quick update         | `status medfit active P1 "Task" 50` |
| `status <name> --create` | Create .STATUS       | `status newproject --create`        |
| `status <name> --show`   | Just view            | `status medfit --show`              |

---

## 💡 Pro Tips

### Tip 1: Use Short Names

```bash
# Instead of:
work mediationverse

# Type:
work med
```

### Tip 2: Morning + Evening Routine

```bash
# Morning:
dash && just-start && work .

# Evening:
status . paused P0 "Resume here tomorrow" 90
```

### Tip 3: Categories for Focus

```bash
# Teaching time
dash teaching

# Research time
dash research

# Package work
dash packages
```

### Tip 4: Combine with `win` command

```bash
# After accomplishing something
win "Completed Phase 1 of help system"

# See today's wins
wins
```

### Tip 5: Use Dispatchers

```bash
# Smart context-aware commands:
cc               # Claude Code (project-aware)
gm               # Gemini (project-aware)
peek <file>      # Smart file viewer
qu               # Quarto operations
```

---

## ❓ Common Questions

**Q: Where is my project data stored?**
A: In each project's `.STATUS` file.

**Q: What if I don't have a .STATUS file?**
A: Use `status <project> --create` to create one.

**Q: Can I edit .STATUS manually?**
A: Yes, but use `status` command - it's easier!

**Q: What if I have many projects?**
A: Use category filters: `dash teaching`

**Q: How does `just-start` pick?**
A: Priority order: P0 active → P1 active → any active → most recent

**Q: Can I use this with my existing workflow?**
A: Yes! It works with `work`, `r`, `cc`, `qu`, etc.

---

## 🎨 Visual Summary

```yaml
YOUR DAY WITH THESE COMMANDS
════════════════════════════

Morning:
  dash          → See overview
    ↓
  just-start    → Pick project
    ↓
  work .        → Start working

During Day:
  dash teaching → Check teaching projects
    ↓
  work stat-440 → Switch to one
    ↓
  status .      → Update progress

Evening:
  status .      → Update before leaving
    ↓
  win "..."     → Log your win
    ↓
  wins          → Feel good about progress!
```

---

## 🚦 Traffic Light System

**Projects are color-coded by status:**

- 🔥 **ACTIVE** (red) = Working on now
- 📋 **READY** (cyan) = Ready to start
- ⏸️ **PAUSED** (yellow) = On hold
- 🚫 **BLOCKED** (dim) = Waiting for something

**Priorities are color-coded:**

- **[P0]** (red) = Do today!
- **[P1]** (yellow) = This week
- **[P2]** (blue) = When you can

**Scan in 3 seconds!**

---

## ✅ Quick Start Checklist

- [ ] Run `dash` to see current projects
- [ ] Create .STATUS for projects without one: `status <name> --create`
- [ ] Update statuses: `status <name>`
- [ ] Try `just-start` to auto-pick
- [ ] Use `work` to jump to projects
- [ ] Check `dash` throughout the day

---

## 📚 Related Commands

These work great together:

| Command     | Purpose               |
| ----------- | --------------------- |
| `why`       | Show current context  |
| `win "..."` | Log an accomplishment |
| `wins`      | See today's wins      |
| `gm`        | Morning routine       |
| `focus 25`  | Start focus timer     |

---

## 🎉 That's It

**You now know:**

- ✅ `dash` - See everything
- ✅ `just-start` - Auto-pick
- ✅ `work` - Start working
- ✅ `status` - Update projects

**Try it now:**

```bash
dash
```

**See your projects!** 🚀

---

*For detailed docs, see: WORKFLOW-IMPLEMENTATION-SUMMARY.md*
*For quick reference: WORKFLOW-QUICK-REFERENCE.md*
