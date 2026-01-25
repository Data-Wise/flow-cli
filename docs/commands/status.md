# Command Reference: flow status

> **Update and query project status with interactive prompts and .STATUS file management**

Complete reference for the `flow status` command - update and query project status.

---

## Synopsis

```bash
flow status [project] [options]
flow status [project] <status> <priority> <task> <progress>
flow status --help
```

---

## Description

The `flow status` command manages project metadata stored in `.STATUS` files. It tracks:

- Project status (active, ready, paused, blocked)
- Priority level (P0, P1, P2)
- Current task description
- Progress percentage (0-100)
- Last update timestamp
- Project category and type

---

## Usage Modes

### Interactive Mode (Recommended)

Prompts you for each field:

```bash
flow status mediationverse
```

**Example interaction:**

```
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
> Complete simulations and write up results

Progress? [85]
   (0-100)
> 90

✅ Updated! Press Enter to continue...
```

### Quick Mode

Provide all values at once:

```bash
flow status <project> <status> <priority> <task> <progress>
```

**Example:**

```bash
flow status mediationverse active P0 "Complete sims" 90
```

### Create Mode

Initialize a new `.STATUS` file:

```bash
flow status newproject --create
```

### Show Mode

View status without updating:

```bash
flow status mediationverse --show
```

---

## Arguments

### project

Project name to update (optional if in project directory):

```bash
# Update specific project
flow status mediationverse

# Update current project
cd ~/projects/r-packages/active/mediationverse
flow status .
```

### status

Project status (one of):

| Value     | Meaning              | When to Use                     |
| --------- | -------------------- | ------------------------------- |
| `active`  | Currently working on | Project is your focus right now |
| `ready`   | Ready to start       | All prerequisites met           |
| `paused`  | Temporarily on hold  | Will resume later               |
| `blocked` | Waiting on something | Can't proceed until X happens   |

**Examples:**

```bash
flow status proj active   # Working on it now
flow status proj paused   # On hold
flow status proj blocked  # Waiting for review/approval
flow status proj ready    # Ready when you are
```

### priority

Priority level (one of):

| Value | Meaning          | How Many? |
| ----- | ---------------- | --------- |
| `P0`  | Critical, urgent | 1-2 max   |
| `P1`  | Important        | 2-3       |
| `P2`  | Normal           | Unlimited |

**Examples:**

```bash
flow status proj active P0   # Critical priority
flow status proj active P1   # Important priority
flow status proj active P2   # Normal priority
```

**Guidelines:**

- **P0:** Must be done today/this week
- **P1:** Should be done this week/month
- **P2:** Nice to have, do when time permits

> **Warning:** Too many P0 projects = everything urgent = nothing urgent

### task

Next action description (quoted string):

```bash
flow status proj active P0 "Run final simulations" 85
```

**Good task descriptions:**

- ✅ "Grade 20 midterm exams"
- ✅ "Fix bug in calculation function"
- ✅ "Write introduction section"
- ✅ "Complete simulation study"

**Poor task descriptions:**

- ❌ "Work on it"
- ❌ "Continue"
- ❌ "More stuff"
- ❌ "TODO"

**Tips:**

- Be specific (what exactly?)
- Use action verbs (Grade, Fix, Write, Complete)
- Include quantities when relevant (20 exams, 3 bugs, 2 sections)

### progress

Progress percentage (0-100):

```bash
flow status proj active P0 "Task" 75
```

**Progress guidelines:**

| Range | Milestone               |
| ----- | ----------------------- |
| 0%    | Just started / Planning |
| 25%   | Foundation complete     |
| 50%   | Core features done      |
| 75%   | Integration complete    |
| 90%   | Polish and testing      |
| 100%  | Complete and shipped    |

**Tips:**

- Update in small increments (5-10%)
- Be honest (accurate > inflated)
- Expect 80-100% to be slow
- Celebrate milestones (25%, 50%, 75%, 100%)

---

## Options

### --create

Create new `.STATUS` file for project:

```bash
flow status newproject --create
```

**What it does:**

1. Detects project type (R package, Quarto, etc.)
2. Creates `.STATUS` file with defaults
3. Prompts for initial values

**Example:**

```bash
cd ~/projects/r-packages/active/newpackage
flow status newpackage --create

# Creates:
project: newpackage
type: r-package
status: ready
priority: P2
progress: 0
next: Define first task
updated: 2025-12-24
category: r-packages
```

### --show

Display status without updating:

```bash
flow status mediationverse --show
```

**Output:**

```
📦 mediationverse
═══════════════════════════════════════════
Status:   🔥 ACTIVE
Priority: [P0] Critical
Progress: ████████░░ 85%
Task:     Run final simulations
Updated:  2025-12-24 10:30 AM
Category: r-packages
Type:     r-package

Location: ~/projects/r-packages/active/mediationverse
```

### --json

Output in JSON format (useful for scripts):

```bash
flow status mediationverse --json
```

**Output:**

```json
{
  "project": "mediationverse",
  "status": "active",
  "priority": "P0",
  "progress": 85,
  "task": "Run final simulations",
  "updated": "2025-12-24T15:30:00Z",
  "category": "r-packages",
  "type": "r-package",
  "location": "~/projects/r-packages/active/mediationverse"
}
```

### --help, -h

Show help message:

```bash
flow status --help
```

---

## Examples

### Example 1: Start Tracking New Project

```bash
cd ~/projects/research/new-study
flow status new-study --create
flow status new-study ready P2 "Literature review" 0
```

### Example 2: Daily Updates

```bash
# Morning: Start work
flow status mediationverse active P0 "Begin simulations" 80

# Midday: Progress update
flow status mediationverse active P0 "Halfway through sims" 85

# End of day: Save state
flow status mediationverse paused P0 "Resume tomorrow - 2 sims left" 90
```

### Example 3: Project State Changes

```bash
# Start working
flow status proj ready P2 "Initial task" 0
flow status proj active P1 "Actually started!" 5

# Make progress
flow status proj active P1 "Core complete" 50

# Hit a blocker
flow status proj blocked P1 "Waiting for data from collaborator" 50

# Unblocked, resume
flow status proj active P0 "Got data - final push!" 75

# Complete
flow status proj ready P2 "Done!" 100
```

### Example 4: Batch Updates

```bash
# Update multiple projects (shell script)
flow status proj1 active P0 "Task A" 80
flow status proj2 paused P1 "On hold" 50
flow status proj3 active P1 "Task B" 60
flow status proj4 ready P2 "Not started" 0

# Verify
flow dash
```

### Example 5: Integration with Other Commands

```bash
# After working
work mediationverse
# ... do work ...
flow status . active P0 "Completed feature X" 90

# After git commit
git add . && git commit -m "feat: add feature X"
flow status . active P0 "Feature X committed" 95

# After testing
npm test
flow status . active P0 "All tests passing!" 100
```

---

## Files

### .STATUS File Format

Located at project root: `~/projects/category/project/.STATUS`

**Example file:**

```
project: mediationverse
type: r-package
status: active
priority: P0
progress: 85
next: Run final simulations
updated: 2025-12-24
category: r-packages
location: ~/projects/r-packages/active/mediationverse
```

**Fields:**

- `project`: Project name
- `type`: Detected type (r-package, quarto, teaching, research, dev-tools)
- `status`: Current status (active/ready/paused/blocked)
- `priority`: Priority level (P0/P1/P2)
- `progress`: Percentage (0-100)
- `next`: Next action description
- `updated`: Last update date (YYYY-MM-DD)
- `category`: Project category
- `location`: Full path to project

---

## Exit Status

| Code | Meaning              |
| ---- | -------------------- |
| 0    | Success              |
| 1    | Invalid arguments    |
| 2    | Project not found    |
| 3    | Permission denied    |
| 4    | Invalid status value |

---

## Environment

### FLOW_CLI_HOME

Override default config directory:

```bash
export FLOW_CLI_HOME=~/.flow-cli
flow status proj --show
```

---

## Notes

### Best Practices

**Update frequency:**

- Daily: Active P0 projects
- Weekly: Active P1/P2 projects
- Monthly: Paused/blocked projects

**Progress accuracy:**

- Update in 5-10% increments
- Be conservative (better to underestimate)
- Don't wait for "perfect" 100%

**Task descriptions:**

- Specific action verbs
- Clear completion criteria
- Next concrete step

### Integration with Dashboard

Status updates appear in:

```bash
flow dash              # Terminal dashboard
flow dashboard --web   # Web dashboard
```

Both auto-refresh to show latest status.

### Version Control

**Add `.STATUS` to git:**

```bash
git add .STATUS
git commit -m "docs: update project status"
```

**Or gitignore it:**

```bash
echo ".STATUS" >> .gitignore
```

Choose based on whether you want to share status with collaborators.

---

## See Also

- [`flow dashboard`](dashboard.md) - View all project statuses
- [`work`](../help/WORKFLOWS.md) - Start working on a project
- [`dash`](../reference/.archive/DASHBOARD-QUICK-REF.md) - Quick dashboard alias
- [Tutorial 1: First Session](../tutorials/01-first-session.md)
- [Tutorial 3: Status Visualizations](../tutorials/03-status-visualizations.md)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (status v1.2)
**Status:** ✅ Production ready with interactive mode
