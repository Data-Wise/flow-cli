# Dopamine Features Guide

**Motivation-boosting features for sustained productivity**

**Last Updated:** 2025-12-26
**Version:** v3.5.0
**Target Audience:** All users wanting to stay motivated

---

## Overview

Flow CLI v3.5.0 introduces **dopamine features** - small, visible rewards that reinforce good work habits. These features are designed with ADHD users in mind but benefit everyone.

**Key Concepts:**

| Feature            | Purpose                   | Command       |
| ------------------ | ------------------------- | ------------- |
| **Win Tracking**   | Celebrate accomplishments | `win`, `yay`  |
| **Streak Counter** | Build momentum            | `dash`        |
| **Daily Goals**    | Progress visibility       | `flow goal`   |
| **Categories**     | Organized wins            | Auto-detected |

---

## Quick Start

```bash
# Log a win
win "Fixed the login bug"

# See your wins
yay

# Check your streak
dash

# Set a daily goal
flow goal set 3
```

---

## Win Tracking

### Logging Wins

The `win` command logs accomplishments with automatic categorization:

```bash
# Basic usage
win "Implemented user authentication"

# With explicit category
win --category ship "Deployed v3.5.0 to production"

# Short form
win "Fixed bug #123"
```

### Win Categories

Wins are automatically categorized based on keywords:

| Category | Icon | Trigger Words                           |
| -------- | ---- | --------------------------------------- |
| `code`   | 💻   | implement, add, create, build, refactor |
| `docs`   | 📝   | doc, readme, guide, tutorial, comment   |
| `review` | 👀   | review, pr, feedback, approve           |
| `ship`   | 🚀   | deploy, release, ship, publish, merge   |
| `fix`    | 🔧   | fix, bug, issue, resolve, patch         |
| `test`   | 🧪   | test, spec, coverage, passing           |
| `other`  | ✨   | (default)                               |

### Viewing Wins

```bash
# Recent wins (default: last 5)
yay

# Weekly summary with activity graph
yay --week

# All wins from today
yay --today

# Wins by category
yay --category code
```

**Example Output:**

```
🎉 Recent Wins
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💻 Implemented user authentication       2h ago
🔧 Fixed the login bug                   4h ago
📝 Updated README with new features      yesterday

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 3 wins | Streak: 🔥 5 days
```

---

## Streak Counter

Streaks track consecutive days with at least one work session.

### How It Works

1. **Start a session** → Counts toward today's streak
2. **Work consecutive days** → Streak increases
3. **Miss a day** → Streak resets to 0

### Viewing Your Streak

The streak appears in:

- **Dashboard header:** `🔥 5 day streak`
- **Win display:** Shows at bottom of `yay`
- **Status output:** Part of extended status

```bash
# Quick streak check
dash

# Detailed view
status --extended
```

### Streak Benefits

| Streak | Visual | Meaning            |
| ------ | ------ | ------------------ |
| 0-2    | 🌱     | Building momentum  |
| 3-6    | 🔥     | On a roll          |
| 7-13   | 🔥🔥   | Strong week        |
| 14+    | 🔥🔥🔥 | Exceptional streak |

---

## Daily Goals

Set a target number of wins per day to stay motivated.

### Setting Goals

```bash
# Set global daily goal (applies to all projects)
flow goal set 3

# Set per-project goal (overrides global)
flow goal set 5 --project flow-cli

# View current goal and progress
flow goal
```

### Goal Progress

The goal appears in the dashboard wins section:

```
🎯 Daily Goal: ██████░░░░ 2/3 wins
```

### Per-Project Goals

Add to your project's `.STATUS` file:

```markdown
## daily_goal: 5
```

This overrides the global goal when working in that project.

**Priority Order:**

1. Project `.STATUS` → `daily_goal` field
2. Global `~/.local/share/flow/goal.json`
3. Default: 3 wins

---

## Extended .STATUS Format

v3.5.0 adds new fields to the `.STATUS` file format:

```markdown
## Project: my-project

## Type: node

## Status: active

## Phase: Development

## Priority: 1

## Progress: 45

## daily_goal: 3

## wins: Deployed v1.0 (2025-12-26)

## streak: 5

## last_active: 2025-12-26 14:30

## tags: typescript, api, backend
```

### New Fields

| Field         | Type      | Description                |
| ------------- | --------- | -------------------------- |
| `daily_goal`  | number    | Per-project win goal       |
| `wins`        | text      | Last win recorded          |
| `streak`      | number    | Current streak             |
| `last_active` | datetime  | Last activity              |
| `tags`        | comma-sep | Project tags for filtering |

### Viewing Extended Status

```bash
# Show all extended fields
status --extended

# Or short form
status -e
```

---

## Dashboard Integration

All dopamine features appear in the dashboard:

```bash
dash
```

**Dashboard Sections:**

```
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD ✓                     Dec 26, 2025  14:30 │
╰──────────────────────────────────────────────────────────────╯

  📊 Today: 2 sessions, ⏱ 3h 45m        🔥 5 day streak

  💡 Keep it up! You're 2/3 of the way to your daily goal.

┌─ 🎉 Recent Wins ─────────────────────────────────────────────┐
│ 🎯 Daily Goal: ██████░░░░ 2/3                                │
│                                                              │
│ 💻 Implemented auth service              14:20               │
│ 🔧 Fixed login redirect bug              11:45               │
│ 📝 Updated API documentation             09:30               │
└──────────────────────────────────────────────────────────────┘
```

---

## Interactive TUI

The dashboard TUI (Terminal UI) now has keyboard shortcuts:

```bash
# Launch interactive dashboard
dash -i
# or
dash --interactive
```

### Keyboard Shortcuts

| Key      | Action            |
| -------- | ----------------- |
| `Enter`  | Open project      |
| `Ctrl-E` | Edit .STATUS file |
| `Ctrl-S` | Show status       |
| `Ctrl-W` | Log a win         |
| `?`      | Show help         |
| `Esc`    | Exit              |

### Watch Mode

Auto-refresh the dashboard:

```bash
# Refresh every 5 seconds (default)
dash --watch

# Custom interval
dash --watch 10
```

---

## Best Practices

### 1. Log Wins Immediately

Don't wait - log wins as soon as you complete something:

```bash
# After fixing a bug
win "Fixed the API timeout issue"

# After a code review
win "Reviewed PR #42"
```

### 2. Keep Goals Achievable

Start with a modest goal and increase:

```bash
# Start small
flow goal set 2

# Increase as you build the habit
flow goal set 3
```

### 3. Check Dashboard Daily

Make `dash` part of your morning routine:

```bash
# Morning check
dash

# Or use the morning command
morning
```

### 4. Use Categories

Let the system categorize, but override when needed:

```bash
# Auto-detection usually works
win "Deployed the new feature"  # → 🚀 ship

# Force category when unclear
win --category test "Wrote integration tests"
```

---

## Troubleshooting

### Wins Not Showing

```bash
# Check wins file location
echo $FLOW_DATA_DIR/wins.log

# View raw wins file
cat ~/.local/share/flow/wins.log
```

### Streak Reset Unexpectedly

Streaks require at least one work session per day:

```bash
# Check worklog for gaps
cat ~/.local/share/flow/worklog | tail -20
```

### Goal Not Updating

```bash
# Check goal.json
cat ~/.local/share/flow/goal.json

# Check project .STATUS
cat .STATUS | grep daily_goal
```

---

## Related Commands

| Command     | Purpose                              |
| ----------- | ------------------------------------ |
| `win`       | Log accomplishment                   |
| `yay`       | View recent wins                     |
| `flow goal` | Manage daily goals                   |
| `dash`      | Dashboard with wins section          |
| `status -e` | Extended status with dopamine fields |

---

## See Also

- [Dashboard Quick Reference](../reference/.archive/DASHBOARD-QUICK-REF.md)
- [Command Quick Reference](../help/QUICK-REFERENCE.md)
- [Workflow Quick Reference](../help/WORKFLOWS.md)

---

**Last Updated:** 2025-12-26
**Version:** v3.5.0
