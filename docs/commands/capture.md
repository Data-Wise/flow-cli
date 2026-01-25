# capture

> **Frictionless idea and accomplishment capture for ADHD workflows with dopamine tracking**

The capture commands provide instant, low-friction ways to log ideas, breadcrumbs, and accomplishments. They're designed for ADHD minds that need to capture thoughts before they disappear.

---

## Synopsis

```bash
win <text>              # Log an accomplishment
catch <idea>            # Quick capture to inbox
crumb <note>            # Leave a breadcrumb
yay                     # Show recent wins
```

**Quick examples:**

```bash
# Log wins
win "Fixed authentication bug"
win --ship "Deployed v2.0"

# Capture ideas
catch "Add dark mode feature"
catch "Research better error handling"

# Leave breadcrumbs
crumb "Working on user auth"
crumb "About to refactor database layer"

# Review
yay                     # Recent wins
yay --week              # Weekly summary
inbox                   # View captured ideas
```

---

## Commands Overview

| Command | Purpose                 | Shortcut |
| ------- | ----------------------- | -------- |
| `catch` | Quick idea/task capture | `c`      |
| `win`   | Log an accomplishment   | -        |
| `yay`   | Show recent wins        | -        |
| `crumb` | Leave a breadcrumb      | `b`      |
| `trail` | Show breadcrumb trail   | `t`      |
| `inbox` | View captured items     | `i`      |

---

## win

> Log an accomplishment and get a dopamine boost! 🎉

### Usage

```bash
win [options] <text>
```

### Options

| Flag       | Short | Category            |
| ---------- | ----- | ------------------- |
| `--code`   | `-c`  | 💻 Code work        |
| `--docs`   | `-d`  | 📝 Documentation    |
| `--review` | `-r`  | 👀 Code review      |
| `--ship`   | `-s`  | 🚀 Shipped/deployed |
| `--fix`    | `-f`  | 🔧 Bug fix          |
| `--test`   | `-t`  | 🧪 Testing          |

### Examples

```bash
# Basic win (auto-detects category)
win "Implemented user authentication"

# With explicit category
win --ship "Deployed v2.0 to production"
win -f "Fixed login bug"

# Interactive mode
win
# 🎉 What's your win? _
```

### Auto-Detection

If you don't specify a category, `win` automatically detects it from keywords:

| Keywords                              | Category  |
| ------------------------------------- | --------- |
| deploy, release, ship, publish, merge | 🚀 ship   |
| review, pr, feedback, approve         | 👀 review |
| test, spec, coverage, passing         | 🧪 test   |
| fix, bug, issue, resolve, patch       | 🔧 fix    |
| doc, readme, guide, tutorial          | 📝 docs   |
| implement, add, create, build         | 💻 code   |

### Output

```
  🎉 WIN LOGGED! #code
  Implemented user authentication

  Keep it up! 🚀
```

---

## yay

> Celebrate your wins and view your streak

### Usage

```bash
yay [--week|-w]
```

### Show Recent Wins

```bash
# Show last 5 wins
yay
```

Output:

```
  🎉 Recent Wins

  💻 Implemented dark mode
  🔧 Fixed memory leak in worker
  📝 Updated API documentation
  🚀 Deployed to staging

  Total: 4 wins today | 🔥 3-day streak
```

### Weekly Summary

```bash
# Show this week's wins with stats
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

---

## catch

> Capture an idea or task instantly before it escapes

### Usage

```bash
catch <text>
# or
c <text>
```

### Examples

```bash
# Quick capture
catch "Add dark mode toggle to settings"
c "Research better caching strategy"

# Interactive mode
catch
# 💡 Quick capture: _
```

### Where It Goes

- **With atlas:** Saved to atlas inbox
- **Without atlas:** Saved to `~/.local/share/flow/inbox.md`

---

## crumb

> Leave a breadcrumb to trace your thinking

Breadcrumbs help you remember what you were doing and why. Perfect for ADHD when you get interrupted.

### Usage

```bash
crumb <text>
# or
b <text>
```

### Examples

```bash
# Leave a breadcrumb
crumb "Started refactoring auth module"
b "Switching to fix urgent bug, will return"

# Interactive mode
crumb
# 🍞 Breadcrumb: _
```

---

## trail

> View your breadcrumb trail

### Usage

```bash
trail [project] [limit]
# or
t [project] [limit]
```

### Examples

```bash
# Show last 20 breadcrumbs
trail

# Show breadcrumbs for a specific project
trail flow-cli

# Limit results
trail flow-cli 10
```

---

## inbox

> View your captured ideas and tasks

### Usage

```bash
inbox
# or
i
```

---

## Daily Goals

Combine wins with daily goals for maximum motivation:

```bash
# Set a daily win goal
flow goal set 3

# Check progress
flow goal
# Today: ██░░░░░░░░ 2/3 wins

# Log a win
win "Completed API endpoint"
# 🎉 WIN LOGGED! #code
# 🎯 Goal: 3/3 - You did it! 🏆
```

---

## Tips

!!! tip "Log Wins Immediately"
Don't wait until the end of the day. Log wins as they happen for maximum dopamine and accurate tracking.

!!! tip "Use Categories"
Categories help you see patterns in your work. Are you shipping a lot but not writing docs? The weekly summary reveals it.

!!! tip "Breadcrumbs for Interruptions"
When you get interrupted, drop a quick `crumb` so you can pick up where you left off.

---

## Related Commands

| Command                                             | Description             |
| --------------------------------------------------- | ----------------------- |
| [`work`](work.md)                                   | Start a session         |
| [`finish`](finish.md)                               | End session with commit |
| [`dash`](dash.md)                                   | View wins in dashboard  |
| [`flow goal`](../guides/DOPAMINE-FEATURES-GUIDE.md) | Daily goal tracking     |

---

## See Also

- **Guide:** [Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md) - Win streaks and goals
- **Reference:** [Workflow Quick Reference](../help/WORKFLOWS.md) - Common workflows
- **Command:** [work](work.md) - Start sessions
- **Command:** [finish](finish.md) - End sessions

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0
**Status:** ✅ Production ready with dopamine tracking
