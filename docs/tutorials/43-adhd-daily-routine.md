---
tags:
  - tutorial
  - adhd
  - daily-workflow
  - timer
  - anti-paralysis
---

# Tutorial: ADHD Daily Routine — morning, js, timer

Start your day without decision fatigue. Auto-pick projects, run focus timers, and build momentum with three ADHD-optimized commands.

**Time:** 20 minutes | **Level:** Beginner | **Requires:** flow-cli

## What You'll Learn

1. Morning briefing with inbox, projects, and wins
2. Defeating analysis paralysis with `js` (just start)
3. Focus timers with countdown and notifications
4. Break timers and Pomodoro cycles
5. Building a complete daily routine

---

## Step 1: Morning Briefing

Start your day with a full situational overview:

```zsh
morning
```

**What you see:**

- **Inbox count** — how many captured items need attention
- **Active projects** — your current work (up to 5)
- **Yesterday's wins** — recent accomplishments to build momentum
- **Work suggestion** — recommends `js` or `work <project>`

For a faster version:

```zsh
morning -q
```

Quick mode shows essentials only.

---

## Step 2: Just Start

ADHD brains freeze when faced with too many choices. `js` removes the decision entirely:

```zsh
js
```

flow-cli auto-picks from your active projects and starts a work session. **Zero decisions. Just work.**

If you know which project:

```zsh
js myproject
```

---

## Step 3: Focus Timer

Start a focus session with a countdown and progress bar:

```zsh
timer start 25        # 25-minute focus session
timer 25              # Shorthand: bare number starts focus timer
```

**What happens:**

- Countdown display with mini progress bar in your terminal
- macOS notification when the timer completes (with sound)
- Breadcrumb logged automatically if you're in a project
- Timer state saved to `$FLOW_DATA_DIR/timer.state`

Default focus time is 25 minutes. Use any duration:

```zsh
timer 50              # 50-minute deep work session
```

---

## Step 4: Break Timer

After a focus session, take a break:

```zsh
timer break 5         # 5-minute break
timer break           # Default: 5 minutes
```

The notification reminds you when the break is over.

---

## Step 5: Pomodoro Mode

Run structured Pomodoro cycles (25 min focus + 5 min break):

```zsh
timer pomodoro        # One full cycle
timer pom 4           # Four cycles
```

---

## Step 6: Timer Status & Stop

Check if a timer is running:

```zsh
timer                 # or: timer status
```

Cancel a running timer:

```zsh
timer stop
```

---

## Step 7: The Complete Daily Flow

A sample anti-paralysis routine:

```zsh
# 1. Morning briefing (2 min)
morning

# 2. Pick a project (instant)
js

# 3. Focus session
timer 25

# ... work until the notification ...

# 4. Break
timer break 5

# 5. Another cycle
timer 25

# 6. Log a win, wrap up
win "Finished feature X"
finish "Ready for review"
```

This removes decision fatigue, keeps you time-aware (a common ADHD challenge), and builds momentum through wins.

---

## FAQ

### Does `morning` work without Atlas?

Yes. It uses file-based fallbacks if Atlas isn't available. You'll still see inbox count, projects, and wins.

### Does the timer run in the background?

No. It's a foreground countdown with a progress bar. It runs in your current terminal session so it stays visible.

### What if I get interrupted?

Run `timer stop` to cancel. The state file is deleted. Start a fresh timer when you're ready — no penalty, no guilt.

### Can I customize durations?

Yes. `timer 50` for a 50-minute focus, `timer break 10` for a 10-minute break. Use whatever works for your brain.

---

## Next Steps

- **[Tutorial 6: Dopamine Features](06-dopamine-features.md)** — Log wins, build streaks with `win` and `yay`
- **[Tutorial 44: Quick Capture](44-quick-capture.md)** — Capture fleeting ideas with `catch`
- **[Tutorial 1: First Session](01-first-session.md)** — Start here if you haven't used flow-cli yet
- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
