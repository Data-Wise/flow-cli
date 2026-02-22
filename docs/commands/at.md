# at (Atlas Bridge)

> **Project intelligence, context tracking, and quick capture via the Atlas CLI bridge**

The `at` command bridges flow-cli to the [Atlas CLI](https://github.com/Data-Wise/atlas) for project intelligence features. It works in two modes: **with Atlas** (full feature set via passthrough) and **without Atlas** (essential commands via ZSH-native fallbacks).

---

## Synopsis

```bash
at <subcommand> [args]    # Atlas bridge command
at help                   # Show styled help page
at                        # Show help (no args)
```

**Quick examples:**

```bash
# Quick capture (works with or without Atlas)
at catch "Fix login redirect bug"
at inbox

# Context tracking (works with or without Atlas)
at where
at crumb "Debugging the cache layer"

# Project intelligence (requires Atlas)
at stats
at plan
at park
at dash
```

---

## Commands Overview

### Always Available (ZSH-native fallbacks)

| Command | Alias | Description | Fallback Storage |
|---------|-------|-------------|-----------------|
| `at catch <text>` | `at c` | Quick capture to inbox | `~/.local/share/flow/inbox.md` |
| `at inbox` | `at i` | Show captured items | Reads inbox.md |
| `at where [project]` | `at w` | Current project context | Filesystem detection |
| `at crumb <text>` | `at b` | Leave a breadcrumb | `~/.local/share/flow/trail.log` |
| `at help` | `at -h` | Show help page | Built-in |

### Requires Atlas CLI

| Command | Description | Output |
|---------|-------------|--------|
| `at stats` | Project statistics overview | Table |
| `at plan` | Planning view (priorities, deadlines) | Table |
| `at park [project]` | Park current project (save context) | Text |
| `at unpark [project]` | Resume a parked project | Text |
| `at parked` | List all parked projects | Names |
| `at dash` | Project dashboard | Table |
| `at dashboard` | Full dashboard (alias for dash) | Table |
| `at focus [project]` | Set/show focus project | Text |
| `at triage` | Process inbox items interactively | Interactive |
| `at trail` | Show breadcrumb trail | Text |
| `at session start <project>` | Start work session | Text |
| `at session end [note]` | End work session | Text |

---

## Quick Capture

> Capture ideas before they disappear. Works with or without Atlas.

```bash
# Basic capture
at catch "Add dark mode to settings page"

# With project association (Atlas only)
at catch "Fix pagination" --project=flow-cli

# View inbox
at inbox
```

**Output (without Atlas):**

```text
  [success] Captured: Add dark mode to settings page
```

**Storage:** Without Atlas, captures are stored as markdown checkboxes in `~/.local/share/flow/inbox.md`:

```markdown
- [ ] Add dark mode to settings page [2026-02-22 14:30]
```

---

## Context Tracking

> Know where you are and leave breadcrumbs for future you.

### where

```bash
# Auto-detect from current directory
at where

# Check specific project
at where flow-cli
```

**Output:**

```text
  Project: flow-cli
   Status: Active
   Focus: Atlas integration update
```

### crumb

```bash
# Leave a breadcrumb
at crumb "Left off debugging auth middleware"
at crumb "About to refactor — save point"

# View trail (Atlas only)
at trail
```

**Output:**

```text
  [success] Breadcrumb: Left off debugging auth middleware
```

---

## Project Intelligence (Atlas Required)

### stats

```bash
at stats
```

Shows project statistics including active time, captures, sessions, and activity trends.

### plan

```bash
at plan
```

Shows the planning view with priorities, deadlines, and task status.

### park / unpark

```bash
# Park current project (saves all context)
at park

# Park a specific project
at park flow-cli

# See what's parked
at parked

# Resume a parked project
at unpark flow-cli
```

Parking saves your project context so you can switch to something else and come back later without losing your place.

### dash

```bash
at dash
```

Full project dashboard showing all projects at a glance with status, recent activity, and focus indicators.

### focus

```bash
# Set focus project
at focus flow-cli

# Show current focus
at focus
```

### triage

```bash
at triage
```

Interactive inbox processing — review captured items and sort them into projects, archive, or trash.

---

## How It Works

### Architecture: Enhanced Bridge Pattern

```
User types: at stats
       │
       ▼
  ┌─────────┐
  │  at()    │  Flow-cli bridge function
  │          │  (lib/atlas-bridge.zsh)
  └────┬─────┘
       │
       ├── "help" ──► _at_help()        [Always: flow-cli styled help]
       │
       ├── Atlas installed? ──► Yes ──► atlas "$@"   [Passthrough to Atlas CLI]
       │
       └── No Atlas:
           ├── catch/inbox/where/crumb ──► ZSH fallbacks
           ├── stats/plan/park/... ──► Install message
           └── unknown ──► Error + available commands
```

**Key design decisions:**

- `at help` **always** shows flow-cli's styled help page (never Atlas's native help)
- With Atlas: all commands pass through directly to the `atlas` CLI
- Without Atlas: 4 essential commands have ZSH-native fallbacks
- Warm-path commands (stats, plan, park, etc.) show install instructions when Atlas is missing

### Performance Model

| Path | Commands | Latency | Implementation |
|------|----------|---------|---------------|
| **Hot** | catch, inbox, where, crumb | < 10ms | ZSH-native (fallback) |
| **Warm** | stats, plan, park, dash, etc. | < 500ms | Atlas CLI subprocess |

### Integration with Existing Commands

The `at` bridge integrates with flow-cli's core commands:

| Core Command | Atlas Integration |
|-------------|-------------------|
| `work <project>` | Calls `_flow_session_start` which uses `atlas session start` |
| `finish [note]` | Calls `_flow_session_end` which uses `atlas session end` |
| `catch <text>` | Calls `_flow_catch` which uses `atlas catch` |
| `crumb <text>` | Calls `_flow_crumb` which uses `atlas crumb` |
| `flow doctor` | Shows Atlas version, backend, project count, MCP status |
| Help browser | Lists `at` with all 15 dispatchers, shows preview via `at help` |

---

## Installation

Atlas is **optional**. flow-cli works standalone without it.

```bash
# Install Atlas (npm)
npm install -g @data-wise/atlas

# Install Atlas (Homebrew)
brew install data-wise/tap/atlas

# Verify
atlas -v

# Check integration
flow doctor    # Shows Atlas section
```

### Configuration

```bash
# Auto-detect (default) — uses Atlas if installed
export FLOW_ATLAS_ENABLED="auto"

# Always use Atlas (error if not installed)
export FLOW_ATLAS_ENABLED="yes"

# Disable Atlas (even if installed)
export FLOW_ATLAS_ENABLED="no"
```

---

## Without Atlas

When Atlas is not installed, `at` provides helpful feedback:

```bash
# Essential commands work via fallbacks
$ at catch "Quick idea"
  [success] Captured: Quick idea

# Warm-path commands show install instructions
$ at stats
  [error] 'at stats' requires Atlas CLI
    Install: npm i -g @data-wise/atlas
    Or:      brew install data-wise/tap/atlas

# Unknown commands list what's available
$ at something
  [error] Atlas not installed
    Available without Atlas: catch, inbox, where, crumb
    Install: npm i -g @data-wise/atlas

    Run at help for all commands
```

---

## Health Check

`flow doctor` shows Atlas integration status:

```text
  ATLAS INTEGRATION
    ✓ atlas installed (v0.9.0)
    ✓ atlas connected (filesystem backend)
    ✓ project list works (12 projects)
    ○ atlas MCP server (optional, not running)
```

Or when not installed:

```text
  ATLAS INTEGRATION
    ○ atlas (optional, not installed)
```

---

## Tips

!!! tip "Capture Everything"
    Use `at catch` liberally — it's designed to be friction-free. Triage later with `at triage`.

!!! tip "Park Before Switching"
    When switching projects, `at park` saves your full context. `at unpark` restores it when you come back.

!!! tip "Breadcrumbs for ADHD"
    Before any interruption, drop a quick `at crumb "what I was doing"`. Your future self will thank you.

!!! tip "Works Without Atlas"
    You don't need Atlas installed for basic capture and context tracking. The 4 fallback commands (catch, inbox, where, crumb) work with pure ZSH.

---

## Related Commands

| Command | Description |
|---------|-------------|
| [`work`](work.md) | Start session (uses Atlas session tracking) |
| [`finish`](finish.md) | End session (uses Atlas session end) |
| [`catch`](capture.md#catch) | Direct capture command (same as `at catch`) |
| [`crumb`](capture.md#crumb) | Direct breadcrumb (same as `at crumb`) |
| [`dash`](dash.md) | Project dashboard |
| [`doctor`](doctor.md) | Health check (shows Atlas status) |

---

## See Also

- **Contract:** [Atlas API Contract](../ATLAS-CONTRACT.md) — Formal interface specification
- **Architecture:** [Master Architecture](../reference/MASTER-ARCHITECTURE.md) — System design
- **Reference:** [Master Dispatcher Guide](../reference/MASTER-DISPATCHER-GUIDE.md) — All dispatchers
- **Guide:** [Atlas Integration Guide](../guides/ATLAS-INTEGRATION-GUIDE.md) — Setup and workflows

---

**Last Updated:** 2026-02-22
**Command Version:** v7.4.1
**Status:** Production ready (Atlas optional)
