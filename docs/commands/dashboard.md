# Dashboard Command

Interactive Terminal UI (TUI) dashboard for real-time workflow monitoring.

## Usage

```bash
flow dashboard [options]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--interval <ms>` | Auto-refresh interval in milliseconds | 5000 (5 seconds) |
| `--help`, `-h` | Show help message | - |

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `q`, `ESC`, `Ctrl-C` | Quit dashboard |
| `r` | Refresh data manually |
| `/` | Filter/search projects |
| `↑`/`↓` | Navigate sessions list |
| `?`, `h` | Show help overlay |

## Dashboard Layout

The dashboard is divided into four main sections:

### 1. Active Session (Top)

Shows the currently active session with:
- Project name
- Task description
- Git branch
- Duration (updates in real-time)
- Session state
- Flow state indicator (🔥 for flow state, ⏱️ otherwise)

Border color indicates flow state:
- **Green**: In flow state (15+ minutes)
- **Cyan**: Active but not in flow state
- **Gray**: No active session

### 2. Metrics Visualization (Middle Left)

Bar chart showing today's metrics:
- **Sessions**: Total sessions today
- **Flow**: Sessions that reached flow state
- **Completed**: Successfully completed sessions
- **Minutes**: Total time spent today

### 3. Statistics Summary (Middle Right)

Displays key statistics:

**Today**
- Sessions count
- Total time
- Flow sessions

**Recent (7 days)**
- Total sessions
- Total time
- Average duration

**Metrics**
- Daily average
- Flow percentage
- Completion rate
- Current streak (consecutive days)
- Trend indicator (📈/📉)

**Projects**
- Total projects tracked

### 4. Recent Sessions (Bottom)

Interactive table showing recent sessions:
- Project name
- Task description
- Duration
- Outcome (completed/ongoing/interrupted)
- Start time

Use `↑`/`↓` arrow keys to navigate. Press `/` to filter by project name.

## Examples

### Basic Usage

```bash
# Start dashboard with default settings
flow dashboard
```

### Custom Refresh Interval

```bash
# Refresh every 10 seconds
flow dashboard --interval 10000

# Refresh every 2 seconds (for active monitoring)
flow dashboard --interval 2000
```

### Filtering Sessions

1. Press `/` to open the filter prompt
2. Type part of a project name (case-insensitive)
3. Press `Enter` to apply filter
4. Press `ESC` to cancel

Example: Type "flow-cli" to show only sessions for the flow-cli project.

## Visual Example

```
╭─ Active Session ─────────────────────────────────────────────────────────╮
│ 🔥 flow-cli                                                               │
│ Task: Implement TUI dashboard                                            │
│ Branch: dev | Duration: 1h 23m | State: active                           │
╰───────────────────────────────────────────────────────────────────────────╯

╭─ Today's Metrics ──────╮  ╭─ Statistics ─────────────────────────────────╮
│                        │  │ Today                                        │
│   ▄▄▄▄                 │  │   Sessions: 3                                │
│   ████  ▄▄▄▄           │  │   Total Time: 147m                           │
│   ████  ████  ▄▄▄▄     │  │   Flow Sessions: 2                           │
│   ████  ████  ████ ▄▄▄ │  │                                              │
│ Sess Flow Comp Mins    │  │ Recent (7 days)                              │
╰────────────────────────╯  │   Total Sessions: 15                         │
                            │   Total Time: 720m                           │
                            │   Avg Duration: 48m                          │
                            │                                              │
                            │ Metrics                                      │
                            │   Daily Average: 103m                        │
                            │   Flow %: 67%                                │
                            │   Completion Rate: 80%                       │
                            │   Streak: 5 days                             │
                            │   Trend: 📈                                   │
                            ╰──────────────────────────────────────────────╯

╭─ Recent Sessions (↑/↓ to navigate) ──────────────────────────────────────╮
│ Project       Task                  Duration  Outcome     Start Time     │
│ flow-cli      TUI dashboard         23m       ongoing     Dec 24 10:45am │
│ flow-cli      Documentation         45m       completed   Dec 24 09:15am │
│ mediationv... Planning meeting      30m       completed   Dec 23 02:30pm │
│ examify       Bug fixes             18m       interrupted Dec 23 11:20am │
╰───────────────────────────────────────────────────────────────────────────╯

Press ? for help | q to quit | r to refresh | / to filter
```

## Features

### Real-time Updates

The dashboard automatically refreshes every 5 seconds (configurable). The active session duration updates in real-time.

### ADHD-Friendly Design

- **Visual hierarchy**: Important information (active session) is at the top
- **Color coding**: Green for success/flow, cyan for active, yellow for warnings
- **Minimal cognitive load**: Key metrics at a glance
- **Interactive navigation**: Keyboard-driven, no mouse required

### Data Source

The dashboard uses the `GetStatusUseCase` which provides:
- Active session information from `SessionRepository`
- Historical sessions from the past 7 days
- Project statistics from `ProjectRepository`
- Calculated productivity metrics

All business logic is handled by the use case - the dashboard is pure presentation.

## Architecture

```
dashboard.js (command)
    ↓
Dashboard.js (UI component)
    ↓
GetStatusUseCase (business logic)
    ↓
SessionRepository + ProjectRepository (data)
```

The dashboard follows Clean Architecture principles:
- **Presentation Layer**: `Dashboard.js` (blessed widgets)
- **Application Layer**: `GetStatusUseCase` (business logic)
- **Data Layer**: Repositories (file system access)

## Troubleshooting

### Dashboard doesn't update

- Check that sessions are being created properly
- Verify data directory exists: `~/.flow-cli/`
- Try manual refresh with `r` key

### Garbled display

- Ensure terminal supports UTF-8
- Try resizing terminal window
- Restart dashboard

### Performance issues

- Increase refresh interval: `--interval 10000`
- Check system resources
- Reduce number of tracked sessions

## Related Commands

- `flow status` - Show static status output
- `flow status --web` - Launch web-based dashboard

## See Also

- [Status Command](./status.md)
- [Getting Started](../getting-started/quick-start.md)
- [ADHD Workflow Guide](../user/WORKFLOWS-QUICK-WINS.md)
