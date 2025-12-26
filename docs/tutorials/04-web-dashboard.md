# Tutorial: Web Dashboard Deep Dive

> **What you'll build:** Using the browser-based dashboard for rich visualizations
>
> **Time:** ~20 minutes | **Level:** Advanced

---

## Prerequisites

Before starting, you should:

- [ ] Completed: [Tutorial 3: Using Status Visualizations](03-status-visualizations.md)
- [ ] Have Node.js installed (for web dashboard)
- [ ] Have multiple projects tracked with progress
- [ ] Comfortable with terminal commands

**Verify your setup:**

```bash
# Check Node.js is installed
node --version

# Should see v18+ or v20+

# Check Flow CLI is installed
which flow
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Launch and navigate the web dashboard
2. Use interactive visualizations
3. Filter and search projects
4. Monitor real-time session data
5. Export and share dashboard views

---

## Overview

The web dashboard provides rich browser-based visualizations:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Launch        │ --> │  Interactive   │ --> │  Take Actions  │
│  (flow dash)   │     │  Explore       │     │  (terminal)    │
└────────────────┘     └────────────────┘     └────────────────┘
```

Benefits over terminal dashboard:

- Charts and graphs (bar, line, pie)
- Mouse/touch interaction
- Larger screen real estate
- Persistent view while you work
- Shareable URLs

---

## Part 1: Launching the Dashboard

### Step 1.1: Start the Web Server

Launch the dashboard:

```bash
flow dashboard --web
```

**What happened:** A web server starts and opens your browser:

```
🌐 Starting Flow CLI Web Dashboard...

Server: http://localhost:3000
Dashboard: http://localhost:3000/dashboard

✨ Dashboard ready!
Press Ctrl+C to stop server
```

**Your browser opens automatically** showing the dashboard.

> **Tip:** Keep the terminal open - closing it stops the server

### Step 1.2: Dashboard Layout

The dashboard has 4 main sections:

```
┌─────────────────────────────────────────────┐
│ 📊 Flow CLI Dashboard          [Filters]    │
├─────────────────────────────────────────────┤
│ 🔥 ACTIVE SESSION (if running)              │
│   Project: mediationverse                   │
│   Duration: 45 minutes                      │
│   Progress: ████████░░ 85%                  │
├─────────────────────────────────────────────┤
│ 📈 TODAY'S METRICS                          │
│   [Bar Chart: Sessions, Time, Progress]     │
├─────────────────────────────────────────────┤
│ 📋 ALL PROJECTS                             │
│   [Table: Name, Status, Priority, Progress] │
├─────────────────────────────────────────────┤
│ 📊 STATISTICS                               │
│   Total Projects: 15                        │
│   Active: 4 | Paused: 6 | Blocked: 1        │
│   Average Progress: 62%                     │
└─────────────────────────────────────────────┘
```

### Step 1.3: Navigation Basics

Navigate using:

**Mouse:**

- Scroll up/down to see all sections
- Click table headers to sort
- Click project names for details
- Hover for tooltips

**Keyboard:**

- `↑/↓` - Navigate projects list
- `/` - Focus search box
- `ESC` - Clear search
- `r` - Refresh data
- `q` - Quit (returns to terminal)

### Checkpoint

At this point, you should have:

- [x] Launched the web dashboard
- [x] Seen the 4 main sections
- [x] Tried basic navigation

**Verify:**

Open browser to `http://localhost:3000/dashboard` - you should see your projects.

---

## Part 2: Interactive Features

### Step 2.1: Filtering Projects

Use filters to focus:

**By status:**

```
[Filters]
☑ Active
☐ Ready
☑ Paused
☐ Blocked

Apply Filters
```

**By category:**

```
[Category]
▼ All Categories
  Teaching
  Research
  Packages
  Dev Tools

Select: Teaching
```

**By priority:**

```
[Priority]
☑ P0 (Critical)
☑ P1 (Important)
☐ P2 (Normal)

Apply Filters
```

### Step 2.2: Search Projects

Use the search box:

```
[🔍 Search projects...]
```

**Search examples:**

- Type `med` → Shows mediationverse, medfit, rmediation
- Type `stat` → Shows stat-440
- Type `active` → Shows all active projects
- Type `90%` → Shows projects near completion

### Step 2.3: Sorting Projects

Click column headers to sort:

| Column   | Sort Options               |
| -------- | -------------------------- |
| Name     | A-Z, Z-A                   |
| Status   | Active first, Paused first |
| Priority | P0 first, P2 first         |
| Progress | High to low, Low to high   |
| Updated  | Newest first, Oldest first |

**Example:** Click "Progress ↓" to see most complete projects first.

### Step 2.4: Project Details

Click a project name to see details:

```
┌─────────────────────────────────────────────┐
│ 📦 mediationverse                           │
├─────────────────────────────────────────────┤
│ Status:    🔥 ACTIVE                        │
│ Priority:  [P0] Critical                    │
│ Category:  r-packages                       │
│ Progress:  ████████░░ 85%                   │
│ Task:      Final simulations                │
│ Updated:   2025-12-24 10:30 AM              │
│                                             │
│ Recent Activity:                            │
│   Dec 20: 60% → 70% (+10%)                  │
│   Dec 22: 70% → 80% (+10%)                  │
│   Dec 24: 80% → 85% (+5%)                   │
│                                             │
│ [Open in Terminal] [Update Status]          │
└─────────────────────────────────────────────┘
```

### Checkpoint

At this point, you should:

- [x] Filter projects by status/category/priority
- [x] Search for specific projects
- [x] Sort by different columns
- [x] View project details

**Verify:**

Filter to show only "Teaching" category and "P0" priority. You should see fewer projects.

---

## Part 3: Real-Time Monitoring

### Step 3.1: Active Session Display

When you have an active session, the dashboard shows live updates:

**Terminal:**

```bash
# Start a session (in separate terminal)
work mediationverse
f25
```

**Dashboard displays:**

```
╭───────────────────────────────────────────╮
│ 🔥 ACTIVE SESSION                         │
├───────────────────────────────────────────┤
│ Project:   mediationverse                 │
│ Started:   10:30 AM (45 minutes ago)      │
│ Timer:     🍅 Pomodoro (15:32 remaining)  │
│ Progress:  ████████░░ 85%                 │
│ Task:      Final simulations              │
╰───────────────────────────────────────────╯

[Duration updates every second]
```

### Step 3.2: Today's Metrics Charts

View visual metrics:

**Bar Chart:**

```
Today's Activity
─────────────────
Sessions │████████░░ 4 sessions
Time     │██████████ 3.5 hours
Projects │███░░░░░░░ 3 active
Progress │███████░░░ +15% total
```

**Progress Distribution:**

```
Progress Ranges
───────────────
0-25%   │███░░░░░░░░ 3 projects
26-50%  │█████░░░░░░ 5 projects
51-75%  │████░░░░░░░ 4 projects
76-99%  │██████░░░░░ 6 projects
100%    │██░░░░░░░░░ 2 projects
```

### Step 3.3: Statistics Summary

Key metrics at a glance:

```
╭───────────────────────────────────────────╮
│ 📊 STATISTICS                             │
├───────────────────────────────────────────┤
│ Total Projects:       20                  │
│ Active:               4 (20%)             │
│ Ready:                8 (40%)             │
│ Paused:               6 (30%)             │
│ Blocked:              2 (10%)             │
│                                           │
│ Average Progress:     62%                 │
│ Completed This Week:  3 projects          │
│ Total Time This Week: 18.5 hours          │
╰───────────────────────────────────────────╯
```

### Step 3.4: Auto-Refresh

Dashboard auto-refreshes every 5 seconds to show latest data.

**Customize refresh interval:**

```bash
# Faster updates (every 2 seconds)
flow dashboard --web --interval 2000

# Slower updates (every 10 seconds)
flow dashboard --web --interval 10000
```

### Checkpoint

At this point, you should:

- [x] See active session updates (if you have one)
- [x] View today's metrics charts
- [x] Understand statistics summary
- [x] See auto-refresh in action

**Verify:**

Update a project in terminal (`status . active P0 "Test" 88`), watch dashboard update within 5 seconds.

---

## Part 4: Advanced Features

### Feature 1: Export Views

Save dashboard views:

**Screenshot:**

- Use browser screenshot tool (Cmd+Shift+4 on Mac)
- Captures current dashboard state

**Print to PDF:**

- Browser: File → Print → Save as PDF
- Useful for sharing with team

**Data Export:**

```bash
# Export project data to JSON
flow status --json > projects.json

# Share with team or import elsewhere
```

### Feature 2: Multiple Dashboard Windows

Open multiple views:

**Terminal 1:**

```bash
flow dashboard --web --port 3000
# Main dashboard
```

**Terminal 2:**

```bash
flow dashboard --web --port 3001 --category teaching
# Teaching-only dashboard
```

**Terminal 3:**

```bash
flow dashboard --web --port 3002 --category research
# Research-only dashboard
```

Now you have 3 browser tabs, each showing different views!

### Feature 3: Embed in Other Tools

Use the dashboard URL in other apps:

**Browser bookmark:**

```
http://localhost:3000/dashboard
```

**Obsidian/Notion:**

```markdown
[My Projects Dashboard](http://localhost:3000/dashboard)
```

**Alfred/Raycast workflow:**

```bash
open http://localhost:3000/dashboard
```

### Feature 4: Keyboard Shortcuts

Productivity shortcuts:

| Key   | Action             |
| ----- | ------------------ |
| `/`   | Focus search       |
| `r`   | Refresh now        |
| `1-5` | Filter by status   |
| `a`   | Show all           |
| `h`   | Show help overlay  |
| `?`   | Keyboard shortcuts |
| `ESC` | Clear filters      |
| `q`   | Quit dashboard     |

### Feature 5: Dark/Light Theme

Toggle theme (if implemented):

**Top-right corner:**

```
[🌙] Dark Mode
[☀️] Light Mode
```

Or use browser's dark mode settings.

---

## Exercises

### Exercise 1: Custom View

Create a custom filtered view for your workflow.

<details>
<summary>Hint</summary>

Combine filters (status, category, priority) and bookmark the result.

</details>

<details>
<summary>Solution</summary>

**Morning teaching view:**

```
1. Launch dashboard: flow dashboard --web
2. Filters:
   - Category: Teaching
   - Priority: P0, P1
   - Status: Active
3. Sort: Priority (P0 first)
4. Bookmark: "Morning Teaching Focus"
```

**Research progress view:**

```
1. Launch dashboard
2. Filters:
   - Category: Research
   - Progress: 50%+
3. Sort: Progress (high to low)
4. Bookmark: "Near-Complete Research"
```

</details>

### Exercise 2: Monitor Active Session

Track a complete work session using the dashboard.

<details>
<summary>Solution</summary>

**Setup:**

```bash
# Terminal 1: Launch dashboard
flow dashboard --web

# Terminal 2: Start work session
work mediationverse
f50
```

**Monitor:**

1. Watch active session timer count up
2. See duration update every second
3. Work on project for 50 minutes
4. Update status when done

**Verify:**

```bash
# Terminal 2: Update when timer completes
status . active P0 "Session complete (+10%)" 95

# Dashboard: See progress update within 5 seconds
```

</details>

### Exercise 3: Weekly Review Dashboard

Use dashboard for weekly review process.

<details>
<summary>Solution</summary>

```bash
# Launch dashboard
flow dashboard --web

# Review each category:
1. Teaching:
   - Filter: Category = Teaching
   - Check: Which need updates?
   - Action: Update statuses in terminal

2. Research:
   - Filter: Category = Research
   - Check: Progress on each
   - Action: Update and set priorities

3. Packages:
   - Filter: Category = Packages
   - Check: Near 100%?
   - Action: Ship completed ones

4. Overall:
   - Clear filters (show all)
   - Check: Statistics summary
   - Note: Total progress this week
   - Export: Screenshot for records
```

</details>

---

## Common Issues

### "Dashboard won't open"

**Cause:** Port already in use or browser not opening

**Fix:**

```bash
# Try different port
flow dashboard --web --port 3001

# Or manually open browser
flow dashboard --web
# Then open: http://localhost:3000/dashboard
```

### "Data not updating"

**Cause:** Auto-refresh paused or connection lost

**Fix:**

```bash
# Press 'r' to refresh manually
# Or restart dashboard
# Ctrl+C, then: flow dashboard --web
```

### "Charts look empty"

**Cause:** Not enough data tracked yet

**Fix:**

```bash
# Track more projects
status project1 active P0 "Task 1" 50
status project2 active P1 "Task 2" 75

# Work on them, then refresh dashboard
```

---

## Summary

In this tutorial, you learned:

| Concept   | What You Did                                      |
| --------- | ------------------------------------------------- |
| Launching | Started web dashboard with `flow dashboard --web` |
| Filtering | Filtered by status, category, priority            |
| Searching | Used search box for quick access                  |
| Sorting   | Sorted columns (name, progress, etc)              |
| Real-time | Monitored active session updates                  |
| Charts    | Viewed bar charts and statistics                  |
| Export    | Saved screenshots and data                        |

**Key commands:**

```bash
flow dashboard --web                  # Launch dashboard
flow dashboard --web --port 3001      # Custom port
flow dashboard --web --interval 2000  # Fast refresh
flow status --json > data.json        # Export data
```

**Dashboard sections:**

1. **Active Session** - Live timer and progress
2. **Today's Metrics** - Charts and graphs
3. **All Projects** - Sortable, filterable table
4. **Statistics** - Summary metrics

---

## Next Steps

You've completed all tutorials! Continue learning:

1. **[Command Reference: status](../commands/status.md)** — Complete status command documentation
2. **[Command Reference: dashboard](../commands/dashboard.md)** — Complete dashboard command documentation
3. **[Workflows & Quick Wins](../guides/WORKFLOWS-QUICK-WINS.md)** — Advanced productivity patterns
4. **[Troubleshooting Guide](../getting-started/troubleshooting.md)** — Common issues and fixes

---

## Quick Reference

```
┌─────────────────────────────────────────────────────┐
│  WEB DASHBOARD QUICK REFERENCE                      │
├─────────────────────────────────────────────────────┤
│  Launch:                                            │
│    flow dashboard --web           Default           │
│    flow dashboard --web --port N  Custom port       │
│    flow dashboard --web --interval N  Refresh rate  │
├─────────────────────────────────────────────────────┤
│  Keyboard:                                          │
│    /      Focus search                              │
│    r      Refresh now                               │
│    ESC    Clear filters                             │
│    h/?    Show help                                 │
│    q      Quit                                      │
├─────────────────────────────────────────────────────┤
│  Features:                                          │
│    - Real-time session monitoring                   │
│    - Interactive charts and graphs                  │
│    - Filter/search/sort projects                    │
│    - Export screenshots and data                    │
│    - Auto-refresh every 5 seconds                   │
└─────────────────────────────────────────────────────┘
```
