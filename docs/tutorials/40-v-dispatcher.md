---
tags:
  - tutorial
  - dispatchers
  - vibe
  - workflow
---

# Tutorial: Workflow Automation with v (vibe)

Bundle testing, coordination, planning, and session management into a single dispatcher. `v` (or `vibe`) is your workflow hub.

**Time:** 15 minutes | **Level:** Intermediate | **Requires:** flow-cli

## What You'll Learn

1. Context-aware testing with `v test`
2. Ecosystem coordination
3. Sprint planning
4. Session management shortcuts
5. Activity logging and progress tracking
6. Health checks

---

## Step 1: Quick Overview

Run `v` with no arguments for a help hint:

```zsh
v
```

For full documentation:

```zsh
v help
```

`v` and `vibe` are identical — use whichever feels natural.

---

## Step 2: Context-Aware Testing

Run tests with automatic project type detection:

```zsh
v test
```

flow-cli detects your project type (ZSH, R, Node, Quarto, etc.) and runs the appropriate test suite.

**Watch mode:**

```zsh
v test watch
```

Keeps tests running as you edit for instant feedback.

---

## Step 3: Ecosystem Coordination

View and manage your development ecosystem:

```zsh
v coord           # Show ecosystems
v coord sync eco  # Sync ecosystem
```

Useful for multi-package setups where projects share dependencies.

---

## Step 4: Sprint Planning

View and manage your current sprint:

```zsh
v plan            # Show current sprint
v plan sprint     # Sprint management
```

---

## Step 5: Session Management

Daily workflow shortcuts:

```zsh
v start           # Start session (alias: v begin)
v end             # End session (alias: v stop)
v morning         # Morning routine (alias: v gm)
v night           # Night routine (alias: v gn)
```

---

## Step 6: Activity & Progress

```zsh
v log             # Activity logging
v dash            # Project dashboard
v status          # Status overview
v progress        # Progress check (alias: v prog)
```

---

## Step 7: Health Check

Verify your environment:

```zsh
v health
```

Checks dependencies, configuration, and system state.

---

## Quick Reference

| Command | Alias | Purpose |
|---------|-------|---------|
| `v test` | `v t` | Context-aware tests |
| `v test watch` | — | Watch mode testing |
| `v coord` | `v c` | Show ecosystems |
| `v plan` | `v p` | Show current sprint |
| `v log` | `v l` | Activity logging |
| `v dash` | `v d` | Project dashboard |
| `v status` | `v s` | Status overview |
| `v start` | `v begin` | Start session |
| `v end` | `v stop` | End session |
| `v morning` | `v gm` | Morning routine |
| `v night` | `v gn` | Night routine |
| `v progress` | `v prog` | Progress check |
| `v health` | — | Health check |

---

## FAQ

### What's the difference between `v` and `vibe`?

They're identical. `vibe` is a full-name alias for `v`.

### Does `v test` work for all project types?

Yes. The dispatcher auto-detects your project type and runs the appropriate test suite. If detection fails, it provides guidance.

### How does `v` relate to other dispatchers?

`v` bundles workflow operations and delegates to other commands behind the scenes. For example, `v dash` calls the existing `dash` command, and `v log` uses the workflow system. It gives you one unified entry point for daily work.

---

## Next Steps

- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
- **[Tutorial 43: ADHD Daily Routine](43-adhd-daily-routine.md)** — Morning briefing, just start, focus timers
