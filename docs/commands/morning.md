# morning

> ADHD-friendly daily startup routine

The `morning` command provides a structured startup routine to reduce decision fatigue and get you working faster. It shows your inbox, active projects, yesterday's wins, and suggests what to work on.

---

## Usage

```bash
morning [options]
```

## Options

| Flag      | Short | Description        |
| --------- | ----- | ------------------ |
| `--quick` | `-q`  | Quick summary only |

---

## What It Shows

The full `morning` command displays:

1. **Inbox count** - Captured ideas awaiting review
2. **Active projects** - Top 5 with progress and focus
3. **Yesterday's wins** - Recent accomplishments
4. **Suggestion** - What to work on next

---

## Examples

### Full Morning Routine

```bash
morning
```

Output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ☀️  GOOD MORNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📥 3 items in inbox

  Active Projects:
     🔧 flow-cli        [ 85%] → Documentation enhancement
     📦 rmediation      [ 60%] → CRAN submission prep
     🎓 stat-440        [ 40%] → Week 12 materials

  Yesterday's wins:
     💻 Implemented dark mode toggle
     🔧 Fixed session tracking bug

  💡 Suggestion:
     Work on flow-cli
     Run: work flow-cli

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ready to start? Try: js (just-start) or work <project>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Quick Mode

```bash
morning -q
# or
am
```

Output:

```
  📥 3 inbox  │  📂 5 active projects

  → js to start working
```

---

## Related Commands

### today

Quick daily status showing current session and today's wins:

```bash
today
```

Output:

```
📅 TODAY Friday, December 27

  🎯 Working on: flow-cli (2h 15m)

  Today's wins:
     💻 Added hop command documentation
     📝 Updated Quick Start guide

  Active Projects:
     🔧 flow-cli        [ 85%] → Documentation enhancement
```

### week

Weekly review helper showing session stats and wins:

```bash
week
```

Output:

```
📊 WEEKLY REVIEW
Week of December 27, 2025

  Sessions this week:
    Mon: flow-cli (3h), rmediation (1h)
    Tue: stat-440 (2h)
    Wed: flow-cli (4h)
    ...

  Wins this week:
     🚀 Deployed v4.0.1
     💻 Added win categories
     📝 Updated documentation
     ...

  Take a moment to celebrate progress! 🎉
```

---

## Aliases

| Alias | Command      |
| ----- | ------------ |
| `am`  | `morning -q` |

---

## How Suggestions Work

The `morning` command suggests projects based on:

1. **Priority** - P1/P0 projects are suggested first
2. **Status** - Active projects only
3. **Recency** - Recently worked projects get priority

---

## Tips

!!! tip "Make It a Habit"
Run `morning` as the first command when you open your terminal. It sets the context for your day.

!!! tip "Quick Mode for Busy Days"
Use `morning -q` (or just `am`) when you're in a rush but still want to see the essentials.

!!! tip "Follow the Suggestion"
If you're not sure what to work on, just follow the suggestion. Reducing decision fatigue is the goal.

!!! tip "Use with js"
After `morning`, run `js` (just-start) to let the system pick and open a project for you automatically.

---

## Workflow Example

```bash
# Start your day
morning

# Follow the suggestion or pick your own
work flow-cli     # Explicit choice
# or
js                # Let system decide

# ... do your work ...

# Check progress later
today

# End of week
week              # Review accomplishments
```

---

## Related Commands

| Command                 | Description                     |
| ----------------------- | ------------------------------- |
| [`work`](work.md)       | Start focused work session      |
| [`dash`](dash.md)       | Project dashboard               |
| `js`                    | Just start (auto-picks project) |
| [`timer`](timer.md)     | Focus timer                     |
| [`capture`](capture.md) | View inbox with `inbox`         |

---

## See Also

- [First Session Tutorial](../tutorials/01-first-session.md)
- [Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md)
- [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (morning v1.0)
**Status:** ✅ Production ready with ADHD-friendly startup routine
