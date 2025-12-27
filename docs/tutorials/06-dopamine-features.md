# Tutorial: Dopamine Features for Motivation

> **What you'll learn:** How to use win tracking, streaks, and goals to stay motivated
>
> **Time:** ~20 minutes | **Level:** Beginner

---

## Prerequisites

Before starting, you should:

- [ ] Have completed [Tutorial 1: Your First Session](01-first-session.md)
- [ ] Know how to use `work` and `finish` commands
- [ ] Have at least one project to work on

---

## What You'll Learn

By the end of this tutorial, you will:

1. Log wins and celebrate accomplishments
2. Understand win categories and auto-detection
3. Track your streak and daily progress
4. Set and monitor daily goals
5. Use the dashboard to visualize your progress

---

## Why Dopamine Features?

For ADHD minds, small visible rewards are essential for sustained focus:

```
┌─────────────────────────────────────────────────────────┐
│  Do Something  →  Log Win  →  See Progress  →  Repeat  │
│      🎯              🎉            📊           🔄      │
└─────────────────────────────────────────────────────────┘
```

Each win gives you a dopamine boost, making it easier to keep going.

---

## Part 1: Logging Your First Win

### Step 1.1: Complete Something (Anything!)

First, do some work. It could be small:

- Fixed a typo
- Wrote one function
- Read some documentation
- Replied to an email

### Step 1.2: Log the Win

```bash
win "Fixed the typo in README"
```

**What happened:** You logged your first win! The output shows:

```
🎉 WIN LOGGED! #docs
Fixed the typo in README

Keep it up! 🚀
```

Notice how it detected the category `#docs` from the word "README".

### Step 1.3: Try Different Categories

Log a few more wins with different keywords:

```bash
win "Deployed the new homepage"
# → 🚀 ship (detected "deployed")

win "Fixed login bug"
# → 🔧 fix (detected "fixed")

win "Added unit tests for auth module"
# → 🧪 test (detected "tests")
```

---

## Part 2: Understanding Win Categories

### Category Auto-Detection

Flow CLI automatically categorizes wins based on keywords:

| Category | Icon | Trigger Words                           |
| -------- | ---- | --------------------------------------- |
| `code`   | 💻   | implement, add, create, build, refactor |
| `docs`   | 📝   | doc, readme, guide, tutorial, comment   |
| `review` | 👀   | review, pr, feedback, approve           |
| `ship`   | 🚀   | deploy, release, ship, publish, merge   |
| `fix`    | 🔧   | fix, bug, issue, resolve, patch         |
| `test`   | 🧪   | test, spec, coverage, passing           |
| `other`  | ✨   | (default if no keywords match)          |

### Manual Category Override

Sometimes auto-detection doesn't match your intent:

```bash
# Force a specific category
win --code "Wrote utility function"
win -f "Resolved edge case"    # -f = fix
win --ship "Merged feature branch"
```

!!! tip "When to Override"
Use manual categories when: - Keywords are ambiguous ("added docs" → is it code or docs?) - You want a specific categorization for tracking - Auto-detection missed the context

---

## Part 3: Viewing Your Wins

### Recent Wins

```bash
yay
```

Output:

```
🎉 Recent Wins
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💻 Implemented user authentication       2h ago
🔧 Fixed the login bug                   4h ago
📝 Updated README with new features      yesterday

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 3 wins | Streak: 🔥 5 days
```

### Weekly Summary

```bash
yay --week
```

Output:

```
📊 This Week's Wins

🚀 Deployed v2.0 to production
💻 Implemented OAuth login
🧪 Added integration tests
🔧 Fixed race condition
📝 Updated installation docs

─────────────────────────────────────
🚀2 💻3 🔧1 📝1 = 7 wins this week

Mon Tue Wed Thu Fri Sat Sun
 ▁   ▃   ██  ▅   ▂
     Activity Graph
```

!!! success "Celebrate Your Progress"
The weekly summary shows your work patterns. Seeing your wins visualized helps reinforce the habit.

---

## Part 4: Tracking Your Streak

### What's a Streak?

A streak counts consecutive days with at least one work session.

| Streak | Visual | Meaning            |
| ------ | ------ | ------------------ |
| 0-2    | 🌱     | Building momentum  |
| 3-6    | 🔥     | On a roll          |
| 7-13   | 🔥🔥   | Strong week        |
| 14+    | 🔥🔥🔥 | Exceptional streak |

### Viewing Your Streak

Your streak appears in several places:

```bash
# In the dashboard
dash

# In the win display
yay

# In extended status
status --extended
```

### Building a Streak

```
Day 1: work project → 🌱 1 day streak
Day 2: work project → 🌱 2 days
Day 3: work project → 🔥 3 days - On a roll!
Day 4: (no work)    → 😢 Streak reset
Day 5: work project → 🌱 1 day (starting over)
```

!!! tip "Maintain Your Streak"
Even a 5-minute session counts! On busy days, do a quick `work` → `win "Quick check-in"` → `finish` to keep your streak alive.

---

## Part 5: Setting Daily Goals

### Set Your First Goal

```bash
# Set a goal of 3 wins per day
flow goal set 3
```

Output:

```
🎯 Daily goal set: 3 wins
```

### Check Your Progress

```bash
flow goal
```

Output:

```
🎯 Today's Progress
━━━━━━━━━━━━━━━━━━━
██████░░░░ 2/3 wins

Log 1 more win to reach your goal!
```

### Goal Shown in Dashboard

The dashboard now shows your goal progress:

```bash
dash
```

```
┌─ 🎉 Recent Wins ─────────────────────────────────────────────┐
│ 🎯 Daily Goal: ██████░░░░ 2/3                                │
│                                                              │
│ 💻 Implemented auth service              14:20               │
│ 🔧 Fixed login redirect bug              11:45               │
└──────────────────────────────────────────────────────────────┘
```

### Adjusting Your Goal

Start small and increase as you build the habit:

```bash
# Start conservatively
flow goal set 2

# After a week of hitting goals
flow goal set 3

# If you're crushing it
flow goal set 5
```

---

## Part 6: Per-Project Goals

You can set different goals for different projects.

### Add to .STATUS File

Open your project's `.STATUS` file:

```markdown
## Project: my-project

## Status: active

## daily_goal: 5
```

### How Priority Works

1. **Project `.STATUS`** → `daily_goal` field (highest priority)
2. **Global goal** → `flow goal set N`
3. **Default** → 3 wins

---

## Part 7: Dashboard Integration

### Full Dashboard View

```bash
dash
```

```
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD ✓                     Dec 27, 2025  14:30 │
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

### Interactive Dashboard

```bash
dash -i
```

**Keyboard shortcuts:**

| Key      | Action            |
| -------- | ----------------- |
| `Enter`  | Open project      |
| `Ctrl-W` | Log a win         |
| `Ctrl-E` | Edit .STATUS file |
| `?`      | Show help         |
| `Esc`    | Exit              |

---

## Part 8: Complete Workflow

Here's how dopamine features fit into your daily routine:

```bash
# Morning: Check your state
morning
# or
dash

# Start working
work my-project

# Log wins as you go (don't wait!)
win "Fixed authentication bug"
win "Added input validation"

# Check progress mid-day
flow goal

# More work...
win "Completed user profile feature"

# End of session
finish "Good progress today"

# Check your streak
yay
```

---

## Best Practices

### 1. Log Wins Immediately

Don't wait until the end of the day:

```bash
# Right after finishing something
win "Just fixed that annoying bug"
```

The immediate feedback reinforces the behavior.

### 2. Keep Goals Achievable

Start small. A goal you hit daily is better than an ambitious goal you miss:

```bash
# Week 1
flow goal set 2

# Week 2 (if consistently hitting)
flow goal set 3
```

### 3. Use Categories

Categories help you see patterns:

- Lots of 🔧 fix? Maybe time for some proactive work.
- All 💻 code and no 📝 docs? Documentation week!
- Heavy 👀 review? Balance with creation time.

### 4. Check Dashboard Daily

Make `dash` part of your morning:

```bash
morning    # Morning routine with suggestions
dash       # Quick dashboard check
```

---

## Troubleshooting

### Wins Not Showing

```bash
# Check wins file exists
ls -la ~/.local/share/flow/wins.md

# View raw file
cat ~/.local/share/flow/wins.md
```

### Streak Reset Unexpectedly

Streaks require at least one work session per day:

```bash
# Check worklog for gaps
tail -20 ~/.local/share/flow/worklog
```

### Goal Not Updating

```bash
# Check global goal
cat ~/.local/share/flow/goal.json

# Check project-specific goal
grep daily_goal .STATUS
```

---

## What's Next?

Now that you're tracking wins and building streaks:

1. **[Tutorial 7: Sync Command](07-sync-command.md)** - Keep everything in sync
2. **[Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)** - Full command reference
3. **[Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md)** - Deep dive reference

---

## Summary

| Concept     | Command                | Purpose               |
| ----------- | ---------------------- | --------------------- |
| Log win     | `win "text"`           | Record accomplishment |
| View wins   | `yay`, `yay --week`    | See recent wins       |
| Set goal    | `flow goal set N`      | Daily win target      |
| Check goal  | `flow goal`            | See progress          |
| View streak | `dash`, `yay`          | Consecutive days      |
| Categories  | Auto or `--code`, etc. | Organize wins         |

**Remember:** The goal isn't to optimize productivity metrics - it's to make work feel more rewarding so you can sustain focus and momentum.
