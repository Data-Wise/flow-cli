# Tutorial: The Sync Command

> **What you'll learn:** How to use `flow sync` to keep your data synchronized
>
> **Time:** ~15 minutes | **Level:** Intermediate

---

## Prerequisites

Before starting, you should:

- [ ] Have completed [Tutorial 1: Your First Session](01-first-session.md)
- [ ] Have worked on at least one project with `work`/`finish`
- [ ] Have logged some wins with `win`

---

## What You'll Learn

By the end of this tutorial, you will:

1. Understand what sync does and why it matters
2. Use smart sync to detect what needs syncing
3. Sync specific targets (session, status, wins, goals, git)
4. Preview changes with dry-run mode
5. Set up scheduled automatic sync

---

## Why Sync?

Flow CLI tracks data in multiple places:

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Session     │   │  .STATUS     │   │  Wins        │
│  (worklog)   │   │  (per-proj)  │   │  (global)    │
└──────────────┘   └──────────────┘   └──────────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                    ┌──────┴──────┐
                    │ flow sync   │
                    │ all         │
                    └─────────────┘
```

The `sync` command orchestrates keeping all this data consistent.

---

## Part 1: Smart Sync

### Check What Needs Syncing

Run sync without arguments to see the current state:

```bash
flow sync
```

Output:

```
🔄 Sync Status

Today's progress: 2/3 wins

Suggested sync targets:
• git: 3 uncommitted changes
• status: 2 projects not updated today

Run: flow sync all
```

### Sync Everything

```bash
flow sync all
```

Output:

```
🔄 Syncing all
━━━━━━━━━━━━━━━━━━━━

[1/5] session... done (45m on flow-cli)
[2/5] status... done (2 projects updated)
[3/5] wins... done (all wins synced)
[4/5] goals... done (2/3 (67%))
[5/5] git... done (pushed 3 commits)

✓ Sync complete (2s)
```

---

## Part 2: Sync Targets

You can sync specific targets individually:

### Session Sync

Persists your current session data to the worklog:

```bash
flow sync session
```

Output:

```
45m on flow-cli
```

### Status Sync

Updates `.STATUS` timestamps and streaks for active projects:

```bash
flow sync status
```

Output:

```
2 projects updated
```

### Wins Sync

Aggregates project wins to the global wins file:

```bash
flow sync wins
```

Output:

```
3 new wins aggregated
```

### Goals Sync

Recalculates daily goal progress:

```bash
flow sync goals
```

Output:

```
2/3 (67%)
```

### Git Sync

Smart git sync with stash handling:

```bash
flow sync git
```

Output:

```
pushed 3 commits
```

**What git sync does:**

1. Stashes uncommitted changes (if any)
2. Fetches from remote
3. Rebases onto remote branch
4. Pushes local commits
5. Pops stash to restore changes

---

## Part 3: Preview with Dry Run

Before syncing, preview what will happen:

```bash
flow sync all --dry-run
```

Output:

```
🔄 Syncing all
━━━━━━━━━━━━━━━━━━━━

🔍 Dry run - no changes will be made

[1/5] session... Would log: 45m on flow-cli
[2/5] status... Would update: flow-cli
                Would skip: 12 (up to date)
[3/5] wins... Would add: Implemented auth
              Would add: Fixed login bug
[4/5] goals... Current: 2/3 (67%)
[5/5] git... Branch: main
             Would stash: 3 changes
             Would: fetch, rebase, push

Run without --dry-run to execute
```

!!! tip "Use Dry Run First"
Always run `--dry-run` before syncing if you're unsure what will happen.

---

## Part 4: Sync Options

### Skip Git (Quick Local Sync)

When you just want to sync local data quickly:

```bash
flow sync all --skip-git
```

This skips the git sync target, which can be slow if you have network issues.

### Verbose Mode

See detailed output:

```bash
flow sync all --verbose
```

### Quiet Mode

Minimal output for scripts:

```bash
flow sync all --quiet
```

---

## Part 5: Scheduled Sync

Set up automatic background sync using macOS launchd.

### Check Schedule Status

```bash
flow sync schedule
```

Output:

```
⏰ Sync Schedule Status

Status: Not configured

Run 'flow sync schedule enable [minutes]' to start
```

### Enable Scheduled Sync

```bash
# Every 30 minutes (default)
flow sync schedule enable

# Every 15 minutes
flow sync schedule enable 15

# Every hour
flow sync schedule enable 60
```

Output:

```
⏰ Enabling Sync Schedule

✓ Schedule enabled
Interval: Every 30 minutes
Targets: session, status, wins, goals (git skipped)

View logs: flow sync schedule logs
Disable: flow sync schedule disable
```

!!! note "Git Skipped"
Scheduled sync skips git because it may require user interaction (merge conflicts, auth).

### View Schedule Logs

```bash
flow sync schedule logs
```

Output:

```
📋 Sync Schedule Logs

Last 20 entries:

2025-12-27 14:30:00 Sync completed
2025-12-27 14:00:00 Sync completed
2025-12-27 13:30:00 Sync completed
```

### Disable Scheduled Sync

```bash
flow sync schedule disable
```

Output:

```
⏰ Disabling Sync Schedule

✓ Schedule disabled
Plist removed
```

---

## Part 6: Sync Dashboard

View your sync history:

```bash
flow sync --status
```

Output:

```
📊 Sync Dashboard

Last full sync: 2025-12-27T14:30:00Z

Run 'flow sync all' to sync everything
```

---

## Part 7: Common Workflows

### Daily Workflow

```bash
# Morning: Quick sync check
flow sync

# If things need syncing
flow sync all

# End of day: Full sync including git
flow sync all
```

### Before Switching Computers

Make sure everything is synced:

```bash
flow sync all
```

### After Extended Break

Check what's stale and sync:

```bash
# See what needs syncing
flow sync

# Sync everything
flow sync all

# Check your dashboard
dash
```

### CI/Automation

For scripts, use quiet mode:

```bash
flow sync all --quiet --skip-git
```

---

## Sync Order

The sync runs in dependency order:

```
session → status → wins → goals → git
   1        2        3       4      5
```

1. **Session** - Capture current session first
2. **Status** - Update project statuses
3. **Wins** - Aggregate wins (needs status data)
4. **Goals** - Calculate progress (needs wins data)
5. **Git** - Push everything (last, may fail)

---

## Troubleshooting

### Git Sync Failed

```bash
# Check git status manually
git status

# If conflicts, resolve them
git rebase --continue
# or
git rebase --abort

# Then retry
flow sync git
```

### Sync Takes Too Long

Skip git for quick local sync:

```bash
flow sync all --skip-git
```

### Scheduled Sync Not Running

Check if the launch agent is loaded:

```bash
launchctl list | grep flow
```

If not listed, re-enable:

```bash
flow sync schedule enable
```

---

## Summary

| Command                      | Purpose                |
| ---------------------------- | ---------------------- |
| `flow sync`                  | Smart status check     |
| `flow sync all`              | Sync everything        |
| `flow sync <target>`         | Sync specific target   |
| `flow sync all --dry-run`    | Preview changes        |
| `flow sync all --skip-git`   | Quick local sync       |
| `flow sync schedule enable`  | Enable automated sync  |
| `flow sync schedule disable` | Disable automated sync |
| `flow sync schedule logs`    | View sync history      |

---

## What's Next?

Now that you understand sync:

1. **[FAQ](../getting-started/faq.md)** - Common questions and troubleshooting
2. **[Command Quick Reference](../help/QUICK-REFERENCE.md)** - All commands
3. **[Workflow Quick Reference](../help/WORKFLOWS.md)** - Common workflows

---

## Related

- [Dopamine Features Tutorial](06-dopamine-features.md)
- [sync command reference](../commands/sync.md)
