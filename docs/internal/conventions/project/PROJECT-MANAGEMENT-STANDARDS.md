# Project Management Standards

> **TL;DR:** Two-tier project management system (.STATUS + PROJECT-HUB.md) with ADHD-friendly workflows and clear update cadence.

**Last Updated:** 2025-12-19
**Based on:** Data-Wise ecosystem project management system
**Location:** `~/projects/dev-tools/zsh-configuration/standards/project/`

---

## 📋 Table of Contents

- [Overview](#overview)
- [Two-Tier System](#two-tier-system)
- [.STATUS File](#status-file)
- [PROJECT-HUB.md](#project-hubmd)
- [Update Cadence](#update-cadence)
- [Shell Commands](#shell-commands)
- [Project Management Commands](#project-management-commands)
- [Integration with Workflow](#integration-with-workflow)
- [Templates](#templates)

---

## Overview

### Core Principle

> **Two tiers:** .STATUS for daily tracking, PROJECT-HUB.md for weekly strategic planning.

**Why Two Tiers:**
- Prevents cognitive overload (don't think strategy when doing task)
- Enables quick context recovery (< 5 seconds)
- Separates tactical (today) from strategic (this week/month)
- ADHD-friendly: Right level of detail for right purpose

### System Components

| Component | Purpose | Update Frequency |
|-----------|---------|------------------|
| `.STATUS` | Daily task tracking | After each work session |
| `PROJECT-HUB.md` | Strategic roadmap | Weekly review |
| ADHD Helpers | Task initiation & dopamine | As needed during work |
| `work` command | Multi-editor project launcher | Start of work session |

---

## Two-Tier System

### Tier 1: .STATUS File

**Purpose:** Machine-readable daily progress tracking

**Location:** Project root (`.STATUS`)

**Format:** Structured text (YAML-ish header + free-form sections)

**Update Trigger:**
- After completing a work session
- Before switching to different project
- End of day wrap-up

**Read By:**
- `dash` command (project dashboard)
- `just-start` command (auto-pick next task)
- `status` command (view/edit)
- `next` command (show next action)

### Tier 2: PROJECT-HUB.md

**Purpose:** Strategic roadmap and phase tracking

**Location:** Project root (`PROJECT-HUB.md`)

**Format:** Markdown with progress bars, sections

**Update Trigger:**
- Weekly review (Friday afternoons)
- Major milestone completion
- Phase transitions

**Read By:**
- Manual review during planning
- Weekly retrospectives
- When planning next phases

---

## .STATUS File

### Standard Format

```diff
🚀 [PROJECT NAME] Status
────────────────────────────────────────────────

📍 LOCATION
~/projects/[category]/[project-name]/

⏰ LAST UPDATED
2025-12-19 Afternoon

────────────────────────────────────────────────

🎯 CURRENT STATUS
[One-line summary of what was just completed or what's in progress]

────────────────────────────────────────────────

📊 PROGRESS

Phase P0: [Name] ████████████████████ 100% ✅
Phase P1: [Name] ██████████████░░░░░░  70% 🔄
Phase P2: [Name] ░░░░░░░░░░░░░░░░░░░░   0% 📋

────────────────────────────────────────────────

✅ JUST COMPLETED (Session: [Date] - [Description])

[Detailed list of what was accomplished this session]

────────────────────────────────────────────────

📋 NEXT ACTIONS

**Immediate (Choose One):**

A) [Task description] 🟢 [est. time] ⭐ RECOMMENDED
   - Sub-step 1
   - Sub-step 2
   - Expected outcome

B) [Alternative task] 🟡 [est. time]
   - Sub-step 1
   - Sub-step 2

**Medium-Term (This Week):**
- [ ] Task 1
- [ ] Task 2

**Long-Term (Future):**
- [ ] Strategic initiative
- [ ] Future enhancement

────────────────────────────────────────────────

📁 KEY FILES

[List of important files with descriptions]

────────────────────────────────────────────────

🎉 WINS

[Recent accomplishments - celebrate progress!]
```text

### Visual Elements

**Progress Bars:**

```text
Full:     ████████████████████ 100%
Partial:  ██████████░░░░░░░░░░  50%
Empty:    ░░░░░░░░░░░░░░░░░░░░   0%
```diff

**Status Indicators:**
- ✅ Complete
- 🔄 In Progress
- 📋 Planned
- ⏳ Waiting/Blocked
- ⭐ Recommended Next Action

**Priority Colors (for terminal output):**
- 🟢 Green: Easy, quick wins
- 🟡 Yellow: Medium effort
- 🔴 Red: High effort or blocked

### Key Sections Explained

**1. CURRENT STATUS:**
- One-line summary
- What's happening RIGHT NOW
- Easy to scan in 2 seconds

**2. PROGRESS:**
- Visual progress bars
- Phase-based tracking
- Percentage completion

**3. JUST COMPLETED:**
- Document wins immediately
- Dopamine boost
- Context for future you

**4. NEXT ACTIONS:**
- Multiple options (ADHD-friendly)
- Estimated times
- Recommended action marked with ⭐
- Categorized: Immediate / Medium / Long-term

**5. KEY FILES:**
- Quick reference to important paths
- Saves time searching

**6. WINS:**
- Celebrate progress
- Combat time blindness
- Motivation boost

---

## PROJECT-HUB.md

### Standard Format

```markdown
# ⚡ [Project Name] - Project Control Hub

> **Quick Status:** [High-level status summary]

**Last Updated:** 2025-12-19
**Current Phase:** P[N] - [Phase Name]
**Next Action:** [Top priority task]

---

## 🎯 Quick Reference

| What | Status | Link |
|------|--------|------|
| **[Key Metric 1]** | ✅/⚠️/❌ Status | Description or path |
| **[Key Metric 2]** | ✅/⚠️/❌ Status | Description or path |
| **[Key Metric 3]** | ✅/⚠️/❌ Status | Description or path |

---

## 📊 Overall Progress

```text

P0: [Phase Name]         ████████████████████ 100% ✅ (date)
P1: [Phase Name]         ████████████████████ 100% ✅ (date)
P2: [Phase Name]         ██████████████░░░░░░  70% 🔄 (date)
  ├─ Subphase A          ████████████████████ 100% ✅
  ├─ Subphase B          ██████████░░░░░░░░░░  50% 🔄
  └─ Subphase C          ░░░░░░░░░░░░░░░░░░░░   0% ⏳

```diff

**Status:** [Overall project health indicator]

---

## 🚀 P[N]: [Current Phase Name] (Date)

### [Subsection Name]

**Achievement:** [What was accomplished]

**Key Deliverables:**
- ✅ Item 1
- ✅ Item 2
- ⚠️ Item 3 (in progress)

**Next Actions:**
- [ ] Action 1
- [ ] Action 2

---

## ✅ Recent Completions

### [Phase/Feature Name] (Date)

- [x] ✅ Task 1
- [x] ✅ Task 2
- [x] ✅ Task 3

**Impact:** [Description of what this accomplished]

---

## 📋 Historical Phases (Collapsed)

Brief summary of completed phases for reference.

---

**Created:** [Date]
**Maintainer:** [Name/Team]
```diff

### Sections Explained

**1. Header Summary:**
- Quick Status: One-line project health
- Current Phase: What's active now
- Next Action: Top priority (from .STATUS)

**2. Quick Reference Table:**
- Key metrics at a glance
- Status indicators (✅ good, ⚠️ attention needed, ❌ problem)
- Links to important resources

**3. Overall Progress:**
- All phases in one view
- Visual progress bars
- Subphase breakdown for active work
- Status indicators and dates

**4. Current Phase Deep Dive:**
- Detailed breakdown of active work
- Accomplishments
- Next actions
- Documentation

**5. Recent Completions:**
- Last 2-3 major milestones
- Keeps wins visible
- Provides context

---

## Update Cadence

### Daily Updates (.STATUS)

**When:**
- End of work session
- Before context switching
- End of day wrap-up

**What to Update:**
- "CURRENT STATUS" - one-line summary
- "JUST COMPLETED" - add session accomplishments
- "NEXT ACTIONS" - update based on progress
- "LAST UPDATED" - current date/time

**Time:** < 30 seconds (just facts, no overthinking)

### Weekly Updates (PROJECT-HUB.md)

**When:**
- Friday afternoon
- After completing major milestone
- Phase transitions

**What to Update:**
- "Quick Status" - overall health check
- "Overall Progress" - update percentages
- "Current Phase" - update subphase progress
- Move completed items to "Recent Completions"

**Time:** 5-10 minutes (strategic thinking)

### What NOT to Update

- Don't update PROJECT-HUB.md during daily work
- Don't add strategic planning to .STATUS
- Don't update both files every session

---

## Shell Commands

### Status Management

```bash
# View current project status
status

# Edit .STATUS file
editstatus

# Create new .STATUS from template
newstatus

# Show next action item
next
```bash

### Project Hub Management

```bash
# View PROJECT-HUB.md
hub

# Edit PROJECT-HUB.md
edithub

# Create new PROJECT-HUB.md from template
newhub
```bash

### ADHD Helpers

```bash
# Auto-pick next task when stuck
just-start           # aliases: js, idk, stuck

# Show current context
why

# Log a win
win "Completed feature X"      # alias: w!

# Show today's wins
wins

# Quick celebration
yay                  # alias: nice

# View wins history (7 days)
wins-history         # alias: wh

# Leave breadcrumb for future
breadcrumb "Working on X, blocked by Y"   # alias: bc

# View breadcrumbs
crumbs               # alias: bcs

# Get AI task suggestion
what-next            # alias: wn
```bash

### Focus Timers

```bash
# Start focus timer
focus 25             # 25 minutes
focus 50             # 50 minutes

# Pre-configured timers
f15                  # 15-minute timer
f25                  # 25-minute (Pomodoro)
f50                  # 50-minute deep work
f90                  # 90-minute extended session

# Check elapsed time
time-check           # alias: tc

# Stop timer early
focus-stop           # alias: fs
```bash

---

## Project Management Commands

### Dashboard View

```bash
# Show all projects with status
dash

# Filter by category
dash teaching
dash research
dash packages
dash dev
```text

**Output:**

```text
╭─────────────────────────────────────────────╮
│ 🎯 YOUR WORK DASHBOARD                      │
╰─────────────────────────────────────────────╯

🔥 ACTIVE NOW (3):
  📦 mediationverse [P0] 85% - Run final simulations
  📚 stat-440 [P1] 30% - Grade assignment 3
  🔧 zsh-configuration [P2] 100% - Phase 1 complete

📋 READY TO START (2):
  📦 medfit [P1] 0% - Add vignette
  📊 product-of-three [P1] 60% - Review simulations
```bash

### Work Session Management

```bash
# Start working on project
work <project>       # Auto-detects editor
work <project> --editor=emacs

# Editor shortcuts
we <project>         # Open in Emacs
wc <project>         # Open in VS Code
wp <project>         # Open in Positron
wa <project>         # Open in Claude Code (Aider)
wt <project>         # Terminal only

# Morning routine
morning              # alias: gm
# Shows: dashboard → picks project → starts work
```bash

### Status Updates

```bash
# Update project status interactively
status <project>

# Quick status update
status <project> active P0 "Task description" 95

# Create new .STATUS file
status <project> --create

# Show status
status <project> --show
```bash

---

## Integration with Workflow

### Typical Day Flow

**Morning (< 2 minutes):**

```bash
# 1. See what's active
dash

# 2. Auto-pick based on priority
just-start           # or: js

# 3. Start working
work .               # Opens current project
```bash

**During Work:**

```bash
# Start focus timer
f25

# Leave context note
bc "Debugging auth flow, suspect issue in line 42"

# Log quick wins
win "Fixed authentication bug"
```bash

**End of Session (< 30 seconds):**

```bash
# Update status
editstatus           # Add to "JUST COMPLETED"
                    # Update "CURRENT STATUS"
                    # Update "NEXT ACTIONS"

# View wins
wins                 # Celebrate progress!
```bash

**Weekly Review (5-10 minutes):**

```bash
# Review all progress
dash

# Update strategic plan
edithub              # Update progress bars
                    # Move items to "Recent Completions"
                    # Plan next week
```yaml

---

## Templates

### .STATUS Template

Location: `~/.STATUS-template-enhanced`

**Create from template:**

```bash
newstatus
```bash

**Or manually:**

```bash
cp ~/.STATUS-template-enhanced ~/projects/my-project/.STATUS
```yaml

### PROJECT-HUB Template

Location: `~/.PROJECT-HUB-template`

**Create from template:**

```bash
newhub
```bash

**Or manually:**

```bash
cp ~/.PROJECT-HUB-template ~/projects/my-project/PROJECT-HUB.md
```diff

---

## Best Practices

### DO

- ✅ Update .STATUS after EVERY work session
- ✅ Keep "NEXT ACTIONS" updated with options
- ✅ Mark recommended action with ⭐
- ✅ Log wins immediately (dopamine boost)
- ✅ Leave breadcrumbs when switching contexts
- ✅ Update PROJECT-HUB.md weekly
- ✅ Keep progress bars accurate
- ✅ Celebrate small wins

### DON'T

- ❌ Skip .STATUS updates (loses context)
- ❌ Update PROJECT-HUB.md daily (wrong granularity)
- ❌ Make next actions too vague ("work on it")
- ❌ Forget to update "LAST UPDATED" timestamp
- ❌ Let breadcrumbs pile up (review weekly)
- ❌ Overthink updates (< 30 seconds for .STATUS)
- ❌ Update both files every time (use right tool)

---

## Troubleshooting

### "I forgot what I was working on"

```bash
# Quick context recovery
why                  # Shows current location, git status, .STATUS excerpt

# Or
status .             # View .STATUS for current project
next                 # Show next action
```bash

### "I don't know what to work on"

```bash
# Let system decide
just-start           # Auto-picks based on priority

# Or see all options
dash                 # View all projects
```bash

### "I'm stuck on current task"

```bash
# Leave note and switch
bc "Blocked waiting for X, need to research Y"
just-start           # Pick different task
```bash

### "Lost track of progress"

```bash
# View all wins
wins                 # Today
wins-history         # Last 7 days

# Check status
dash                 # All projects
```

---

## Integration with Other Standards

**See also:**
- [PROJECT-STRUCTURE.md](./PROJECT-STRUCTURE.md) - File organization
- [COMMIT-MESSAGES.md](../code/COMMIT-MESSAGES.md) - Git commit standards
- [WEBSITE-DESIGN-GUIDE.md](../documentation/WEBSITE-DESIGN-GUIDE.md) - Documentation sites

---

## References

**Implemented in:**
- `~/.config/zsh/functions/adhd-helpers.zsh` - ADHD workflow commands
- `~/.config/zsh/functions/work.zsh` - Multi-editor work command
- `~/.config/zsh/functions/dash.zsh` - Project dashboard
- `~/.config/zsh/functions/status.zsh` - Status management

**Documentation:**
- `/Users/dt/projects/.planning/PM-FILE-MANAGEMENT-COMPLETE.md`
- `/Users/dt/projects/.planning/README.md`
- `/Users/dt/projects/.planning/archive/PROJECT_MANAGEMENT_OVERVIEW.md`

---

**Created:** 2025-12-19
**Based on:** Data-Wise ecosystem PM system (Dec 2025)
**Maintainer:** DT
