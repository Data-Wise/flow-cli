---
tags:
  - tutorial
  - capture
  - inbox
  - breadcrumbs
  - adhd
---

# Tutorial: Quick Capture — catch, inbox, crumb, trail

Capture fleeting ideas, leave breadcrumbs for context switching, and never lose track of where you left off.

**Time:** 10 minutes | **Level:** Beginner | **Requires:** flow-cli

## What You'll Learn

1. Capturing ideas instantly with `catch`
2. Reviewing your inbox
3. Leaving breadcrumbs to track context
4. Following your trail to resume after interruptions

---

## Step 1: Quick Capture

Your brain moves fast. Capture ideas before they disappear:

```zsh
catch "refactor the login flow"
```

Instant capture — no confirmation, no friction. Auto-detects your current project.

**Interactive mode** (for longer notes):

```zsh
catch
```

If `gum` is installed, you get a formatted input box. Otherwise, a simple prompt.

---

## Step 2: View Your Inbox

Process captures when you have time:

```zsh
inbox
```

Shows all captured items. Some become tasks. Others were fleeting — that's fine.

**Tip:** Review your inbox during morning briefing or before switching projects.

---

## Step 3: Leave Breadcrumbs

Interruptions are inevitable. Breadcrumbs help you remember what you were doing:

```zsh
crumb "investigating auth bug in user.zsh"
```

Interactive mode:

```zsh
crumb
```

**When to use breadcrumbs:**

- Before an interruption: `crumb "got to line 42, testing API response"`
- When switching projects: `crumb "paused testing, moving to docs"`
- During debugging: `crumb "found mismatch in root detection"`

---

## Step 4: Follow the Trail

When you resume work, read your breadcrumbs:

```zsh
trail                    # Trail for current project
trail flow-cli           # Trail for a specific project
trail flow-cli 10        # Last 10 breadcrumbs only
```

Default shows the last 20 breadcrumbs. Instantly orients you.

---

## Step 5: The ADHD Workflow

How these commands work together:

```zsh
# Start work
work flow-cli

# Idea hits during debugging
catch "think about dispatcher caching strategy"

# Get interrupted
crumb "debugging git integration, got to rebase logic"

# Switch projects
hop teaching

# Come back later
work flow-cli
trail          # "debugging git integration, got to rebase logic"
# Ah yes. Back to it.

# End of day
inbox          # 3 items captured today — process tomorrow
```

**The pattern:** Catch ideas instantly. Leave breadcrumbs at transitions. Follow the trail to resume. Process inbox when ready.

---

## FAQ

### Where are captures stored?

Atlas database (if enabled) or `$FLOW_DATA_DIR` as file fallback. Check with `flow doctor`.

### Does catch work outside projects?

Yes. Captures store without project context when you're not in a project directory.

### What is gum?

An optional TUI tool for prettier prompts. If installed, `catch` and `crumb` use it for formatted input. Without it, you get a simple prompt. Both work fine. Install with `brew install gum`.

### How many breadcrumbs should I leave?

One per context switch or every ~30 minutes of deep work. Don't over-document — just enough to resume.

---

## Next Steps

- **[Tutorial 6: Dopamine Features](06-dopamine-features.md)** — Log accomplishments with `win` and `yay`
- **[Tutorial 43: ADHD Daily Routine](43-adhd-daily-routine.md)** — Morning briefing, just start, focus timers
- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
