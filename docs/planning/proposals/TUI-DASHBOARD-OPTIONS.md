# TUI Dashboard Options - Interactive Terminal UI

**Context:** Day 8-9 implementation for Interactive TUI Dashboard
**Created:** 2025-12-23
**Estimated Effort:** 2-3 hours

## Overview

Create a beautiful, interactive Terminal User Interface (TUI) dashboard for the flow-cli status command. This dashboard will provide real-time session monitoring, project selection, and quick actions through an intuitive terminal interface.

---

## Option 1: Blessed (Most Popular) ⭐ RECOMMENDED

**Library:** [blessed](https://github.com/chjj/blessed) (11.9k stars)
**Philosophy:** Full-featured terminal interface library (like ncurses for Node.js)

### Pros

- ✅ Most mature and widely used TUI library
- ✅ Rich widget set (boxes, lists, tables, progress bars, forms)
- ✅ Built-in keyboard and mouse support
- ✅ Easy styling with CSS-like syntax
- ✅ Excellent documentation and examples
- ✅ Works in any terminal (no external dependencies)
- ✅ Active community and plugins (blessed-contrib for charts)

### Cons

- ⚠️ Larger bundle size (~100KB)
- ⚠️ Steeper learning curve for complex layouts
- ⚠️ Some quirks with terminal compatibility

### Code Example

```javascript
import blessed from 'blessed'

// Create screen
const screen = blessed.screen({
  smartCSR: true,
  title: 'Flow CLI Dashboard'
})

// Active session box
const sessionBox = blessed.box({
  top: 0,
  left: 0,
  width: '100%',
  height: 8,
  border: { type: 'line' },
  style: {
    border: { fg: 'green' },
    focus: { border: { fg: 'cyan' } }
  },
  label: ' 🔥 Active Session ',
  content: 'Project: rmediation\nTask: Fix tests\nDuration: 45 min'
})

// Project list
const projectList = blessed.list({
  top: 8,
  left: 0,
  width: '50%',
  height: '100%-8',
  border: { type: 'line' },
  style: {
    selected: { bg: 'blue' }
  },
  keys: true,
  vi: true,
  items: ['rmediation', 'quarto-doc', 'flow-cli']
})

// Render
screen.append(sessionBox)
screen.append(projectList)
screen.render()

// Quit on Escape, q, or Control-C
screen.key(['escape', 'q', 'C-c'], () => process.exit(0))
```

### Use Cases

- Complex dashboards with multiple widgets
- Interactive forms and menus
- Real-time data updates
- Custom key bindings

### Effort: ~2-3 hours

- Layout: 30 min
- Widgets: 1 hour
- Interactivity: 30 min
- Styling: 30 min
- Testing: 30 min

---

## Option 2: Ink (React for CLI) 🎨

**Library:** [ink](https://github.com/vadimdemedes/ink) (26.8k stars)
**Philosophy:** Build TUIs with React components

### Pros

- ✅ Use React components and hooks (familiar for React devs)
- ✅ Declarative UI (easier to reason about)
- ✅ Hot reload during development
- ✅ Built-in components (Box, Text, Newline)
- ✅ Smaller learning curve if you know React
- ✅ Great for simple, focused UIs
- ✅ Auto-testing with ink-testing-library

### Cons

- ⚠️ Requires React knowledge
- ⚠️ Heavier (React runtime overhead)
- ⚠️ Less control over low-level terminal features
- ⚠️ Overkill for simple dashboards

### Code Example

```javascript
import React, { useState, useEffect } from 'react'
import { render, Box, Text } from 'ink'

const Dashboard = () => {
  const [session, setSession] = useState(null)

  useEffect(() => {
    // Fetch session data
    const interval = setInterval(() => {
      // Update session
    }, 1000)
    return () => clearInterval(interval)
  }, [])

  return (
    <Box flexDirection="column">
      <Box borderStyle="round" borderColor="green" padding={1}>
        <Box flexDirection="column">
          <Text bold color="green">
            🔥 Active Session
          </Text>
          <Text>Project: {session?.project}</Text>
          <Text>Duration: {session?.duration} min</Text>
        </Box>
      </Box>

      <Box borderStyle="round" marginTop={1} padding={1}>
        <Box flexDirection="column">
          <Text bold color="cyan">
            📊 Today
          </Text>
          <Text>Sessions: 5</Text>
          <Text>Duration: 3h 45m</Text>
        </Box>
      </Box>
    </Box>
  )
}

render(<Dashboard />)
```

### Use Cases

- React developers
- Simple, focused dashboards
- Rapid prototyping
- Component reusability

### Effort: ~2 hours

- Components: 1 hour
- State management: 30 min
- Styling: 30 min

---

## Option 3: Terminal-Kit (Feature Rich) 🛠️

**Library:** [terminal-kit](https://github.com/cronvel/terminal-kit) (3.1k stars)
**Philosophy:** Full terminal manipulation library

### Pros

- ✅ Extremely feature-rich (animations, images, menus)
- ✅ Better graphics support (can display images in terminal)
- ✅ Progress bars, spinners, tables out of the box
- ✅ Document-based API (easier than blessed)
- ✅ Built-in input handling (text fields, yes/no, menus)

### Cons

- ⚠️ Less popular (smaller community)
- ⚠️ Heavy (larger API surface)
- ⚠️ Some features require specific terminals

### Code Example

```javascript
import terminalKit from 'terminal-kit'
const term = terminalKit.terminal

// Clear and position
term.clear()

// Session box
term.cyan('╭─ 🔥 Active Session ─────────────╮\n')
term.cyan('│ ').green('Project: rmediation          ').cyan('│\n')
term.cyan('│ ').yellow('Duration: 45 min              ').cyan('│\n')
term.cyan('╰──────────────────────────────────╯\n\n')

// Interactive menu
term.green('Select project:\n')
const items = ['rmediation', 'quarto-doc', 'flow-cli']

term.singleColumnMenu(items, (error, response) => {
  term('\n').green(`Selected: ${items[response.selectedIndex]}`)
})
```

### Use Cases

- Rich graphics in terminal
- Interactive menus and forms
- Progress tracking with spinners
- Image display in supported terminals

### Effort: ~2 hours

- Setup: 15 min
- UI elements: 1 hour
- Interactivity: 45 min

---

## Option 4: Charm Bubbletea (Go-inspired) 🫧

**Library:** [bubbletea](https://github.com/charmbracelet/bubbletea) (JavaScript port: not official)
**Note:** Primarily a Go library, but Elm Architecture concepts apply

### Pros

- ✅ Elm Architecture pattern (Model-View-Update)
- ✅ Predictable state management
- ✅ Great for complex interactive apps
- ✅ Composable and testable

### Cons

- ⚠️ No official JavaScript port
- ⚠️ Would need to build from scratch using the pattern
- ⚠️ Steeper learning curve

**Recommendation:** Use blessed or ink instead for JavaScript projects.

---

## Graphics & Charts Libraries

### blessed-contrib (Charts for Blessed) 📊

**Library:** [blessed-contrib](https://github.com/yaronn/blessed-contrib)
**Use with:** blessed

**Features:**

- Line charts
- Bar charts
- Donut charts
- Sparklines
- Tables
- Maps
- Logs

**Code Example:**

```javascript
import blessed from 'blessed'
import contrib from 'blessed-contrib'

const screen = blessed.screen()

const grid = new contrib.grid({ rows: 12, cols: 12, screen })

// Line chart
const line = grid.set(0, 0, 6, 12, contrib.line, {
  label: 'Session Duration Trend',
  showLegend: true,
  style: {
    line: 'yellow',
    baseline: 'white'
  }
})

// Bar chart
const bar = grid.set(6, 0, 6, 6, contrib.bar, {
  label: 'Projects by Sessions',
  barWidth: 4,
  barSpacing: 6,
  maxHeight: 9
})

// Donut chart
const donut = grid.set(6, 6, 6, 6, contrib.donut, {
  label: 'Completion Rate',
  radius: 8,
  arcWidth: 3
})

// Update data
line.setData([
  { title: 'This Week', x: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], y: [30, 45, 60, 40, 50] }
])

screen.render()
```

**Effort:** +1 hour to add charts to blessed dashboard

---

### ink-ui (UI Components for Ink) 🎨

**Library:** [ink-ui](https://github.com/vadimdemedes/ink-ui)
**Use with:** ink

**Features:**

- Select menu
- Multi-select
- Progress bar
- Spinner
- Text input

**Code Example:**

```javascript
import React from 'react'
import { render } from 'ink'
import { Select } from 'ink-ui'

const Demo = () => (
  <Select
    items={[
      { label: 'rmediation', value: 'rm' },
      { label: 'quarto-doc', value: 'qd' },
      { label: 'flow-cli', value: 'fc' }
    ]}
    onSelect={item => {
      console.log(`Selected: ${item.label}`)
    }}
  />
)

render(<Demo />)
```

---

## Recommended Approach: Blessed + blessed-contrib ⭐

### Why This Combination?

1. **Mature ecosystem** - Battle-tested in production
2. **Rich widgets** - Everything we need out of the box
3. **Charts support** - blessed-contrib for visualizations
4. **No React overhead** - Pure terminal manipulation
5. **Excellent examples** - Many open-source dashboards to reference

### Dashboard Layout (Proposed)

```
╭─ 🔥 ACTIVE SESSION ──────────────────────────────────────╮
│ Project: rmediation                                      │
│ Task: Fix failing tests                                  │
│ Duration: 45 min 🔥 IN FLOW                              │
│ Branch: fix/test-bug │ Uncommitted: 3 files             │
╰──────────────────────────────────────────────────────────╯

╭─ 📊 TODAY ─────────╮  ╭─ 📈 TREND (7 days) ────────────╮
│ Sessions:     5    │  │     60 ┤                        │
│ Duration:  3h 45m  │  │     50 ┤      ●                 │
│ Completed:    4/5  │  │     40 ┤   ●     ●              │
│ Flow %:      80%   │  │     30 ┤●           ●        ●  │
╰────────────────────╯  ╰────────────────────────────────╯

╭─ 📁 RECENT PROJECTS ────────────────────────────────────╮
│ ▸ rmediation              45m │ 5 sessions │ 80% flow  │
│   quarto-doc              30m │ 3 sessions │ 100% comp │
│   flow-cli             1h 15m │ 2 sessions │ Active    │
╰──────────────────────────────────────────────────────────╯

╭─ ⚡ QUICK ACTIONS ──────────────────────────────────────╮
│ [f] Finish  [p] Pause  [s] Switch  [r] Refresh  [q] Quit │
╰──────────────────────────────────────────────────────────╯
```

### Implementation Plan (2-3 hours)

**Phase 1: Basic Layout (1 hour)**

- Setup blessed screen
- Create session box
- Create today stats box
- Create project list
- Basic keyboard navigation

**Phase 2: Charts (30 min)**

- Add blessed-contrib
- Line chart for trend
- Donut chart for completion rate
- Real-time updates

**Phase 3: Interactivity (45 min)**

- Keyboard shortcuts (f, p, s, r, q)
- Project selection with Enter
- Auto-refresh every 5 seconds
- Status updates on actions

**Phase 4: Polish (30 min)**

- Color scheme (match current CLI colors)
- Border styles
- Loading states
- Error handling

---

## Alternative: Hybrid Approach 🎯

**Use both blessed AND current CLI:**

1. **Default:** Enhanced status command (what we built today)
2. **Optional flag:** `flow status --tui` launches blessed dashboard
3. **Best of both worlds:** Fast CLI + rich TUI when needed

### Benefits

- Users choose their preference
- CLI remains fast and scriptable
- TUI available for deep dives
- No breaking changes

### Implementation

```javascript
// cli/commands/status.js
if (options.tui) {
  const { TUIController } = await import('../adapters/controllers/TUIController.js')
  const controller = new TUIController(getStatusUseCase)
  await controller.launch()
} else {
  // Current StatusController
}
```

---

## Decision Matrix

| Criterion       | blessed    | ink      | terminal-kit | Hybrid     |
| --------------- | ---------- | -------- | ------------ | ---------- |
| **Ease of use** | ⭐⭐⭐     | ⭐⭐⭐⭐ | ⭐⭐⭐       | ⭐⭐⭐⭐   |
| **Features**    | ⭐⭐⭐⭐⭐ | ⭐⭐⭐   | ⭐⭐⭐⭐⭐   | ⭐⭐⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐   | ⭐⭐⭐   | ⭐⭐⭐⭐     | ⭐⭐⭐⭐   |
| **Community**   | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐       | ⭐⭐⭐⭐⭐ |
| **Charts**      | ⭐⭐⭐⭐⭐ | ⭐⭐     | ⭐⭐⭐⭐     | ⭐⭐⭐⭐⭐ |
| **Effort**      | 2-3h       | 2h       | 2h           | 3h         |
| **Maintenance** | ⭐⭐⭐⭐   | ⭐⭐⭐⭐ | ⭐⭐⭐       | ⭐⭐⭐⭐⭐ |

---

## Recommendation: Hybrid with Blessed 🎯

**Primary:** Keep enhanced CLI (current work)
**Optional:** Add `--tui` flag for blessed dashboard
**Charts:** Use blessed-contrib for visualizations

### Why?

1. ✅ No breaking changes to CLI
2. ✅ Users choose their interface
3. ✅ Best tool for each use case
4. ✅ Rich charts and widgets available
5. ✅ Mature, well-tested libraries
6. ✅ ADHD-friendly: choice reduces friction

### Next Steps

If implementing TUI:

1. **Install dependencies**

   ```bash
   npm install blessed blessed-contrib
   ```

2. **Create TUIController** (adapters layer)
   - Similar to StatusController
   - Launches blessed screen
   - Handles keyboard events

3. **Add `--tui` flag** to status command

4. **Test in various terminals**
   - iTerm2, Terminal.app, VS Code terminal
   - tmux/screen compatibility

5. **Documentation**
   - Add TUI screenshots
   - Keyboard shortcut reference
   - Troubleshooting guide

---

## Visual Mockup (ASCII)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Flow CLI Dashboard                           [q] Quit    ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                            ┃
┃  🔥 ACTIVE SESSION                                         ┃
┃  ╭────────────────────────────────────────────────────╮  ┃
┃  │ rmediation                            Fix tests    │  ┃
┃  │ Duration: 45 min 🔥                   3 files ⚡    │  ┃
┃  ╰────────────────────────────────────────────────────╯  ┃
┃                                                            ┃
┃  ╭─ 📊 TODAY ───╮  ╭─ 📈 TREND ───────────────────────╮  ┃
┃  │ 5 sessions   │  │    50│         ●                 │  ┃
┃  │ 3h 45m       │  │    40│      ●     ●              │  ┃
┃  │ 4/5 complete │  │    30│   ●           ●        ●  │  ┃
┃  ╰──────────────╯  ╰───────────────────────────────────╯  ┃
┃                                                            ┃
┃  📁 PROJECTS          Duration  Sessions  Status          ┃
┃  ╭────────────────────────────────────────────────────╮  ┃
┃  │ ▸ rmediation          45m      5      🔥 Flow      │  ┃
┃  │   quarto-doc          30m      3      ✅ Complete  │  ┃
┃  │   flow-cli         1h 15m      2      🚧 Active    │  ┃
┃  ╰────────────────────────────────────────────────────╯  ┃
┃                                                            ┃
┃  ⚡ [f]inish [p]ause [s]witch [r]efresh [↑↓] navigate    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## Conclusion

**Recommended path:** Implement hybrid approach with blessed + blessed-contrib

**Estimated effort:** 3 hours total

- blessed setup: 1 hour
- Charts: 30 min
- Interactivity: 1 hour
- Testing & polish: 30 min

**Benefits:**

- Choice for users (CLI vs TUI)
- Rich visualizations
- ADHD-friendly interface
- Professional dashboard
- Production-ready library

**When to skip TUI:**

- Time constraints (CLI alone is excellent)
- Prefer web dashboard instead
- Focus on other features first

The enhanced CLI status command we built today is already **production-ready** and provides great value. The TUI is an **optional enhancement** for users who want a richer terminal experience.
