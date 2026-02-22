# Atlas Integration Guide

> **How flow-cli integrates with Atlas CLI for project intelligence**

This guide covers the architecture, setup, and workflows for flow-cli's Atlas integration. Whether you use Atlas or not, flow-cli works — Atlas just makes it smarter.

---

## Overview

flow-cli and Atlas CLI are separate tools that work together:

| Layer | Tool | Purpose | Speed |
|-------|------|---------|-------|
| **Layer 1** | flow-cli | Instant workflow commands (ZSH) | < 10ms |
| **Layer 2** | Atlas CLI | Project intelligence (Node.js) | < 500ms |

flow-cli handles the hot path (session start, capture, breadcrumbs) with ZSH-native code. Atlas handles the warm path (stats, planning, parking) with its richer data model.

```
┌──────────────────────────────────────────────────────────────┐
│                        User Shell                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐     ┌─────────────────────────────────────┐ │
│  │  flow-cli   │     │  at() bridge                        │ │
│  │             │     │                                     │ │
│  │  work       │────►│  Hot path (ZSH-native fallbacks):   │ │
│  │  finish     │     │    catch, inbox, where, crumb       │ │
│  │  catch      │     │                                     │ │
│  │  crumb      │     │  Warm path (Atlas CLI required):    │ │
│  │  flow doctor│     │    stats, plan, park, dash, etc.    │ │
│  └─────────────┘     └──────────┬──────────────────────────┘ │
│                                 │                            │
│                     ┌───────────▼───────────┐                │
│                     │     Atlas CLI         │                │
│                     │   @data-wise/atlas    │                │
│                     │                       │                │
│                     │  Project database     │                │
│                     │  Session tracking     │                │
│                     │  Analytics            │                │
│                     └───────────────────────┘                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Setup

### 1. Install Atlas (Optional)

```bash
# Homebrew (recommended)
brew install data-wise/tap/atlas

# npm
npm install -g @data-wise/atlas

# Verify
atlas -v
```

### 2. Verify Integration

```bash
flow doctor
```

Look for the **Atlas Integration** section:

```text
  ATLAS INTEGRATION
    ✓ atlas installed (v0.9.0)
    ✓ atlas connected (filesystem backend)
    ✓ project list works (12 projects)
    ○ atlas MCP server (optional, not running)
```

### 3. Configure (Optional)

In your ZSH config (`~/.config/zsh/`):

```bash
# Auto-detect (default) — uses Atlas if on PATH
export FLOW_ATLAS_ENABLED="auto"

# Force on (error if not installed)
export FLOW_ATLAS_ENABLED="yes"

# Force off (ignore even if installed)
export FLOW_ATLAS_ENABLED="no"
```

---

## The Bridge Pattern

The `at()` function is an **enhanced bridge**, not a dispatcher. This distinction matters:

| Aspect | Dispatcher (e.g., `g`) | Bridge (`at`) |
|--------|----------------------|---------------|
| Owns domain logic | Yes (in ZSH) | No (Atlas owns it) |
| Subcommands in ZSH | All defined locally | Pass through to Atlas |
| Help page | ZSH function | ZSH function (styled wrapper) |
| Without dependency | Fully functional | Degraded (4 fallback commands) |
| File location | `lib/dispatchers/*.zsh` | `lib/atlas-bridge.zsh` |

### Command Routing

```
at <command>
    │
    ├── help/--help/-h ──► _at_help()         [Always local]
    ├── (no args) ──► _at_help()              [Always local]
    │
    ├── Atlas installed? ──► atlas "$@"       [Full passthrough]
    │
    └── No Atlas:
        ├── catch/c ──► _flow_catch()         [ZSH fallback]
        ├── inbox/i ──► _flow_inbox()         [ZSH fallback]
        ├── where/w ──► _flow_where()         [ZSH fallback]
        ├── crumb/b ──► _flow_crumb()         [ZSH fallback]
        ├── stats/plan/park/... ──► Install message
        └── * ──► Error + available commands
```

---

## Integration with Existing Commands

Atlas integration isn't just the `at` command. Several core flow-cli commands use Atlas behind the scenes when it's available.

### work (Session Start)

When you run `work myproject`:

1. flow-cli sets up the environment (cd, exports)
2. Calls `_flow_session_start("myproject")`
3. **With Atlas:** `atlas session start myproject`
4. **Without Atlas:** Writes to `~/.local/share/flow/.current-session` + worklog

### finish (Session End)

When you run `finish "Done with auth"`:

1. Calculates session duration
2. Calls `_flow_session_end("Done with auth")`
3. **With Atlas:** `atlas session end "Done with auth"`
4. **Without Atlas:** Writes to worklog with duration

### catch / crumb (Capture)

These core commands use the same bridge functions as `at catch` / `at crumb`:

```bash
# These are equivalent:
catch "Fix bug"       # Direct command
at catch "Fix bug"    # Via at bridge
at c "Fix bug"        # Via at bridge (alias)
```

### flow doctor (Health Check)

`flow doctor` provides a dedicated Atlas section showing:

- Atlas installation status and version
- Storage backend (filesystem, etc.)
- Project count via `atlas project list`
- MCP server status (optional)

### Help Browser

The interactive help browser (`flow help --browse`) includes `at` in the command list. The fzf preview window shows `at help` output.

### Project Listing

`_flow_list_projects()` tries Atlas first:

```
atlas project list --format=names
    │
    ├── Returns plain text ──► Use it
    ├── Returns JSON ──► Fall back to filesystem
    └── Fails ──► Fall back to filesystem
```

This is validated: if the output starts with `{` or `[`, flow-cli rejects it and scans the filesystem instead.

---

## Workflows

### Daily ADHD Workflow with Atlas

```bash
# Morning: Start your day
work myproject           # Session starts (Atlas tracks)
at stats                 # See where you left off

# During work: Capture ideas as they come
at catch "Refactor the auth module"
at catch "Add rate limiting to API"

# Context switch
at crumb "Was debugging login flow"
at park                  # Save context
work other-project       # Switch

# Come back later
at unpark myproject      # Restore context
at trail                 # See your breadcrumbs

# End of day
finish "Completed auth refactor"
at dash                  # Overview of all projects
```

### Capture-and-Triage Workflow

```bash
# Throughout the day: capture everything
at catch "Dark mode for settings"
at catch "Fix Safari redirect"
at catch "Update API docs"

# When you have time: triage
at triage                # Interactive sorting

# Check what's left
at inbox
```

### Project Parking

```bash
# Working on feature A, urgent bug comes in
at park                  # Save feature A context
work bugfix-project      # Switch to bug

# ... fix the bug ...

finish "Fixed critical bug"
at unpark feature-a      # Resume feature A
at trail                 # See where you left off
```

---

## API Contract

The integration is governed by a formal contract (`docs/ATLAS-CONTRACT.md`) that specifies:

- **Version compatibility:** flow-cli v7.4.x works with Atlas v0.9.x
- **Output formats:** `names`, `json`, `table`, `shell`
- **Exit codes:** 0 (success), 1 (error), 2 (not found)
- **Breaking change policy:** Patch = no breaks, Minor = deprecation warnings

See the full contract: [Atlas API Contract](../ATLAS-CONTRACT.md)

---

## Testing

Contract compliance is verified by `tests/test-atlas-contract.zsh`:

```bash
# Run just Atlas tests
zsh tests/test-atlas-contract.zsh

# Run full suite (includes Atlas tests)
./tests/run-all.sh
```

Tests cover:
- Bridge function existence
- Help page content and aliases
- Fallback behavior without Atlas
- Atlas CLI contract compliance (skipped when Atlas not installed)
- Help browser integration

---

## Files

| File | Purpose |
|------|---------|
| `lib/atlas-bridge.zsh` | Bridge functions, `at()`, `_at_help()`, detection, wrappers |
| `lib/help-browser.zsh` | Help browser (includes `at` in dispatcher list) |
| `commands/doctor.zsh` | Health check (Atlas section) |
| `docs/ATLAS-CONTRACT.md` | Formal API contract |
| `tests/test-atlas-contract.zsh` | Contract compliance tests |

---

## Troubleshooting

### Atlas not detected after install

```bash
# Force re-check (clears session cache)
_flow_refresh_atlas

# Or start a new shell
exec zsh
```

### Atlas installed but commands fail

```bash
# Check Atlas directly
atlas -v
atlas project list

# Check flow-cli detection
flow doctor
```

### Want to disable Atlas temporarily

```bash
export FLOW_ATLAS_ENABLED=no
# Atlas is now ignored even if installed
```

---

## See Also

- **Command:** [`at` Command Reference](../commands/at.md) — Full command docs
- **Contract:** [Atlas API Contract](../ATLAS-CONTRACT.md) — Interface specification
- **Architecture:** [Master Architecture](../reference/MASTER-ARCHITECTURE.md) — System design
- **Reference:** [Quick Reference](../help/QUICK-REFERENCE.md) — All commands at a glance

---

**Last Updated:** 2026-02-22
**Version:** v7.4.1
