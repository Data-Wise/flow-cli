# Command Reference: flow dashboard

Complete reference for the `flow dashboard` command - monitor workflow status in real-time.

---

## Synopsis

```bash
flow dashboard [options]
flow dashboard --web [--port <port>] [--interval <ms>]
flow dashboard --help
```

---

## Description

The `flow dashboard` command launches an interactive dashboard for monitoring projects, sessions, and workflow metrics. It provides both terminal (TUI) and web-based interfaces.

**Features:**

- Real-time session monitoring with live timers
- Project status overview with filtering
- Today's activity metrics and charts
- Statistics summary (projects, time, progress)
- Auto-refresh for up-to-date information

---

## Usage Modes

### Terminal Dashboard (TUI)

Launch interactive terminal interface:

```bash
flow dashboard
```

**Features:**

- ASCII-based visualizations
- Keyboard navigation
- Real-time updates
- Works over SSH
- Minimal resource usage

### Web Dashboard

Launch browser-based dashboard:

```bash
flow dashboard --web
```

**Features:**

- Rich HTML/CSS visualizations
- Mouse and touch interaction
- Charts and graphs
- Larger screen real estate
- Shareable URL (localhost)

---

## Options

### --web

Launch web-based dashboard:

```bash
flow dashboard --web
```

**What happens:**

1. Starts HTTP server on localhost
2. Opens browser automatically
3. Serves dashboard at `http://localhost:3000/dashboard`
4. Auto-refreshes every 5 seconds

**Terminal output:**

```yaml
🌐 Starting Flow CLI Web Dashboard...

Server: http://localhost:3000
Dashboard: http://localhost:3000/dashboard

✨ Dashboard ready!
Press Ctrl+C to stop server
```

**Browser displays:**

- Active session (if running)
- Today's metrics (charts)
- All projects (table)
- Statistics summary

### --port <port>

Specify custom port for web dashboard:

```bash
flow dashboard --web --port 8080
```

**Default:** 3000

**Use cases:**

- Port 3000 already in use
- Run multiple dashboards
- Corporate firewall rules

**Example with multiple dashboards:**

```bash
# Terminal 1: Main dashboard
flow dashboard --web --port 3000

# Terminal 2: Teaching projects only
flow dashboard --web --port 3001 --category teaching

# Terminal 3: Research projects only
flow dashboard --web --port 3002 --category research
```

### --interval <ms>

Set auto-refresh interval (milliseconds):

```bash
flow dashboard --web --interval 2000
```

**Default:** 5000 (5 seconds)

**Range:** 1000-60000 (1-60 seconds)

**Examples:**

```bash
# Fast updates (every 2 seconds)
flow dashboard --web --interval 2000

# Slow updates (every 30 seconds)
flow dashboard --web --interval 30000

# Very fast (every second) - resource intensive
flow dashboard --web --interval 1000
```

**Recommendations:**

| Update Interval | Use Case                                 |
| --------------- | ---------------------------------------- |
| 1-2 seconds     | Active development with frequent changes |
| 5 seconds       | Normal use (default)                     |
| 10-30 seconds   | Background monitoring                    |
| 60 seconds      | Low resource usage                       |

### --category <category>

Filter dashboard to specific category:

```bash
flow dashboard --web --category teaching
```

**Valid categories:**

- `teaching`
- `research`
- `packages`
- `dev` (dev-tools)

**Example:**

```bash
# Teaching-only dashboard
flow dashboard --web --category teaching --port 3001

# Research-only dashboard
flow dashboard --web --category research --port 3002
```

### --help, -h

Show help message:

```bash
flow dashboard --help
```

---

## Keyboard Shortcuts

### Terminal Dashboard (TUI)

| Key                  | Action                 |
| -------------------- | ---------------------- |
| `q`, `ESC`, `Ctrl-C` | Quit dashboard         |
| `r`                  | Refresh data manually  |
| `↑/↓`                | Navigate sessions list |
| `h`, `?`             | Show help overlay      |

### Web Dashboard

| Key      | Action                                    |
| -------- | ----------------------------------------- |
| `/`      | Focus search box                          |
| `r`      | Refresh data manually                     |
| `ESC`    | Clear search/filters                      |
| `h`, `?` | Show keyboard shortcuts                   |
| `q`      | Quit (close browser, stop server)         |
| `1-5`    | Filter by status (1=active, 2=ready, etc) |
| `a`      | Show all (clear filters)                  |

---

## Dashboard Sections

### 1. Active Session

Shows current work session (if active):

**Terminal:**

```text
╭─────────────────────────────────────────╮
│ 🔥 ACTIVE SESSION                       │
├─────────────────────────────────────────┤
│ Project:   mediationverse               │
│ Started:   10:30 AM (45 minutes ago)    │
│ Timer:     🍅 Pomodoro (15:32 left)     │
│ Progress:  ████████░░ 85%               │
│ Task:      Final simulations            │
╰─────────────────────────────────────────╯
```

**Web:**

- Large card at top
- Live timer (updates every second)
- Visual progress bar
- Quick actions (update status, stop timer)

### 2. Today's Metrics

Activity charts for current day:

**Bar Charts:**

```text
Today's Activity
────────────────
Sessions │████████░░ 4 sessions
Time     │██████████ 3.5 hours
Projects │███░░░░░░░ 3 active
Progress │███████░░░ +15% total
```

**Web:**

- Interactive bar/line charts
- Hover for details
- Click to filter

### 3. Projects Table

All projects with status, priority, progress:

**Terminal:**

```text
┌──────────────────┬────────┬────┬────┬─────────────┐
│ Project          │ Status │ Pri│ %  │ Task        │
├──────────────────┼────────┼────┼────┼─────────────┤
│ mediationverse   │ Active │ P0 │ 85%│ Final sims  │
│ stat-440         │ Active │ P1 │ 60%│ Grade exams │
│ flow-cli         │ Ready  │ P2 │100%│ Complete!   │
└──────────────────┴────────┴────┴────┴─────────────┘
```

**Web:**

- Sortable columns (click headers)
- Filterable (search box)
- Click row for details

### 4. Statistics

Summary metrics:

```text
╭─────────────────────────────────────────╮
│ 📊 STATISTICS                           │
├─────────────────────────────────────────┤
│ Total Projects:       20                │
│ Active:               4 (20%)           │
│ Ready:                8 (40%)           │
│ Paused:               6 (30%)           │
│ Blocked:              2 (10%)           │
│                                         │
│ Average Progress:     62%               │
│ Completed This Week:  3 projects        │
│ Total Time This Week: 18.5 hours        │
╰─────────────────────────────────────────╯
```

---

## Examples

### Example 1: Quick Status Check

```bash
# Launch terminal dashboard
flow dashboard

# View, then quit
# Press 'q' to exit
```

### Example 2: Background Web Dashboard

```bash
# Start web dashboard in background
flow dashboard --web &

# Dashboard URL: http://localhost:3000/dashboard
# Keep working in terminal while dashboard runs

# Stop dashboard
fg
Ctrl+C
```

### Example 3: Category-Specific Dashboards

```bash
# Open 3 browser tabs with different views

# Tab 1: Teaching
flow dashboard --web --port 3000 --category teaching

# Tab 2: Research (new terminal)
flow dashboard --web --port 3001 --category research

# Tab 3: Packages (new terminal)
flow dashboard --web --port 3002 --category packages

# Now have dedicated view for each work type
```

### Example 4: Custom Refresh Rate

```bash
# Very active development - fast updates
flow dashboard --web --interval 1000

# Background monitoring - slow updates
flow dashboard --web --interval 30000
```

### Example 5: Integration with Work Session

```bash
# Terminal 1: Start work session
work mediationverse
f25

# Terminal 2: Monitor progress
flow dashboard --web

# Dashboard shows:
# - Active session timer (live countdown)
# - Project progress
# - Session duration (updates every second)
```

### Example 6: Weekly Review

```bash
# Sunday evening: Review all projects

flow dashboard --web

# In browser:
# 1. Review each category
# 2. Check progress %
# 3. Update priorities in terminal
# 4. Screenshot for records
```

---

## Web Dashboard Features

### Interactive Filtering

**By Status:**

- ☑ Active
- ☑ Ready
- ☐ Paused
- ☐ Blocked

**By Category:**

- Teaching
- Research
- Packages
- Dev Tools

**By Priority:**

- ☑ P0 (Critical)
- ☑ P1 (Important)
- ☐ P2 (Normal)

### Search

Search box accepts:

- Project names (partial match)
- Task descriptions
- Status keywords
- Progress values ("90%", ">50%")

**Examples:**

- `med` → mediationverse, medfit
- `active` → all active projects
- `90%` → projects near completion
- `grade` → projects with "grade" in task

### Sorting

Click column headers to sort:

| Column   | Sorts                      |
| -------- | -------------------------- |
| Name     | A-Z, Z-A                   |
| Status   | Active first, etc          |
| Priority | P0 first, P2 first         |
| Progress | High to low, low to high   |
| Updated  | Newest first, oldest first |

### Export

**Screenshot:**

- Use browser tools (Cmd+Shift+4 on Mac)
- Captures dashboard state

**Print to PDF:**

- Browser: File → Print → Save as PDF
- Good for sharing with team

**Data Export:**

```bash
flow status --json > dashboard-data.json
```

---

## Files

### Session Data

Active session stored in: `~/.config/zsh/.worklog`

**Format:**

```json
{
  "project": "mediationverse",
  "start_time": "2025-12-24T15:30:00Z",
  "timer": {
    "duration": 25,
    "remaining": 932
  },
  "task": "Final simulations"
}
```

### Project Data

Each project: `~/projects/category/project/.STATUS`

**Format:**

```text
project: mediationverse
status: active
priority: P0
progress: 85
next: Final simulations
updated: 2025-12-24
```

---

## Exit Status

| Code | Meaning               |
| ---- | --------------------- |
| 0    | Success (clean exit)  |
| 1    | Invalid arguments     |
| 2    | Port already in use   |
| 3    | Permission denied     |
| 4    | Server startup failed |

---

## Environment

### FLOW_CLI_HOME

Override default config directory:

```bash
export FLOW_CLI_HOME=~/.flow-cli
flow dashboard
```

### PORT

Default port for web dashboard:

```bash
export PORT=8080
flow dashboard --web
# Uses port 8080 instead of 3000
```

---

## Notes

### Performance

**Resource usage:**

| Dashboard Type     | CPU | Memory | Network        |
| ------------------ | --- | ------ | -------------- |
| Terminal (TUI)     | ~1% | ~10 MB | None           |
| Web (default)      | ~2% | ~50 MB | Localhost only |
| Web (fast refresh) | ~5% | ~75 MB | Localhost only |

**Tips:**

- Use terminal dashboard for low resource usage
- Use slower refresh (10-30s) for background monitoring
- Close web dashboard when not actively viewing

### Security

**Web dashboard:**

- Binds to localhost only (not accessible from network)
- No authentication (assumes local use)
- No HTTPS (localhost HTTP only)

**Don't expose to network:**

```bash
# This is UNSAFE:
flow dashboard --web --host 0.0.0.0

# Keep it local:
flow dashboard --web
# Binds to 127.0.0.1 only
```

### Accessibility

**Web dashboard:**

- ARIA labels for screen readers
- Keyboard navigation
- High contrast mode support
- Respects prefers-reduced-motion

**Terminal dashboard:**

- Works with screen readers
- Standard terminal navigation
- Color-blind friendly (uses symbols + colors)

---

## Troubleshooting

### "Port already in use"

**Error:**

```text
Error: Port 3000 is already in use
```

**Solution:**

```bash
# Try different port
flow dashboard --web --port 3001

# Or kill process using port 3000
lsof -ti:3000 | xargs kill -9
```

### "Dashboard not opening"

**Cause:** Browser not auto-opening

**Solution:**

```bash
flow dashboard --web
# Manually open: http://localhost:3000/dashboard
```

### "Data not updating"

**Cause:** Auto-refresh paused or failed

**Solution:**

- Press `r` to refresh manually
- Check terminal for errors
- Restart dashboard (Ctrl+C, relaunch)

### "Charts showing no data"

**Cause:** No projects tracked yet

**Solution:**

```bash
# Create some project data
cd ~/projects/your-project
flow status your-project --create
flow status your-project active P1 "First task" 25

# Refresh dashboard
```

---

## See Also

- [`flow status`](status.md) - Update project status
- [`dash`](../reference/MASTER-DISPATCHER-GUIDE.md) - Dashboard quick reference
- [Tutorial 4: Web Dashboard](../tutorials/04-web-dashboard.md) - Complete tutorial
- [Workflows & Tips](../guides/WORKFLOWS-QUICK-WINS.md) - Productivity patterns

---

## History

- **v1.0** (2025-12-14) - Terminal dashboard implemented
- **v1.1** (2025-12-21) - Web dashboard added
- **v1.2** (2025-12-24) - Category filtering and improved charts

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (dashboard v1.2)
**Status:** ✅ Production ready with web interface and live refresh
