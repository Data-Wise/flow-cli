# V / Vibe Dispatcher Reference

**Version:** 1.0
**Status:** Experimental (Many features are placeholders)
**Part of:** flow-cli v5.15.0+

---

## Overview

The `v` (or `vibe`) dispatcher provides workflow automation shortcuts, consolidating testing, coordination, planning, and session management into a single command interface.

> **Note:** This dispatcher is experimental. Many subcommands show "(Implementation coming soon)" as they are planned for future phases.

---

## Quick Reference

| Command | Action | Status |
|---------|--------|--------|
| `v test` | Run tests (context-aware) | ⚠️ Delegates to `pt` |
| `v test watch` | Watch mode | 🚧 Placeholder |
| `v test cov` | Coverage report | 🚧 Placeholder |
| `v coord` | Show ecosystems | 🚧 Placeholder |
| `v plan` | Current sprint | 🚧 Placeholder |
| `v log` | Activity log | ✅ Delegates to `workflow` |
| `v dash` | Dashboard | ✅ Delegates to `dash` |
| `v status` | Project status | ✅ Delegates to `status` |
| `v health` | Health check | 🚧 Placeholder |
| `v start` | Start session | ✅ Delegates to `startsession` |
| `v end` | End session | ✅ Delegates to `endsession` |
| `v morning` | Morning routine | ✅ Delegates to `pmorning` |
| `v night` | Night routine | ✅ Delegates to `pnight` |
| `v progress` | Check progress | ✅ Delegates to `progress_check` |
| `v help` | Show help | ✅ Working |

---

## Command Categories

### Testing (`v test`)

Run tests with context-aware framework detection.

```bash
v test              # Run tests (auto-detect)
v test watch        # Watch mode (placeholder)
v test cov          # Coverage report (placeholder)
v test scaffold     # Generate test template (placeholder)
v test file <path>  # Run specific test file (placeholder)
v test docs         # Generate test documentation (placeholder)
v test help         # Show test help
```

**Shortcuts:** `v t` = `v test`

### Coordination (`v coord`)

Ecosystem coordination workflows.

```bash
v coord             # Show ecosystems (placeholder)
v coord sync        # Sync ecosystem (placeholder)
v coord status      # Ecosystem dashboard (placeholder)
v coord deps        # Dependency graph (placeholder)
v coord release     # Coordinate release (placeholder)
```

**Shortcuts:** `v c` = `v coord`

**Status:** 🚧 Planned for Phase 3

### Planning (`v plan`)

Sprint and roadmap management.

```bash
v plan              # Current sprint (placeholder)
v plan sprint       # Sprint management (placeholder)
v plan roadmap      # View roadmap (placeholder)
v plan add          # Add task (placeholder)
v plan backlog      # View backlog (placeholder)
```

**Shortcuts:** `v p` = `v plan`

**Status:** 🚧 Planned for Phase 4

### Activity Logging (`v log`)

Delegates to the `workflow` command.

```bash
v log               # Recent activity → workflow
v log today         # Today's log → workflow today
v log started       # Log session start → workflow started
```

**Shortcuts:** `v l` = `v log`

### Direct Commands

Shortcuts to existing flow-cli commands.

```bash
v dash              # → dash (project dashboard)
v status [args]     # → status [args]
v health            # Combined health check (placeholder)
```

**Shortcuts:** `v d` = `v dash`, `v s` = `v status`

### Session Management

Shortcuts to session commands.

```bash
v start [args]      # → startsession [args]
v end               # → endsession
v begin [args]      # Alias for v start
v stop              # Alias for v end
```

### Routines

Morning and night workflow routines.

```bash
v morning           # → pmorning (morning routine)
v night             # → pnight (night routine)
v gm                # Alias for v morning
v gn                # Alias for v night
```

### Progress

Progress tracking.

```bash
v progress          # → progress_check
v prog              # Alias for v progress
```

---

## Full Name: `vibe`

The `vibe` command is an alias for `v`:

```bash
vibe test           # Same as: v test
vibe coord sync     # Same as: v coord sync
vibe help           # Same as: v help
```

---

## Dependencies

The dispatcher delegates to these existing commands:

| Delegation | Required Command | Used By |
|------------|------------------|---------|
| Testing | `pt` | `v test` |
| Logging | `workflow` | `v log` |
| Dashboard | `dash` | `v dash` |
| Status | `status` | `v status` |
| Session Start | `startsession` | `v start` |
| Session End | `endsession` | `v end` |
| Morning | `pmorning` | `v morning` |
| Night | `pnight` | `v night` |
| Progress | `progress_check` | `v progress` |

---

## Implementation Status

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Basic dispatcher structure | ✅ Complete |
| 1 | Help system | ✅ Complete |
| 1 | Session shortcuts | ✅ Complete |
| 2 | Test workflows | ⚠️ Partial (delegates to `pt`) |
| 3 | Coordination workflows | 🚧 Placeholder |
| 4 | Planning workflows | 🚧 Placeholder |
| 5 | Health check | 🚧 Placeholder |

---

## Examples

### Basic Usage

```bash
# Run tests
v test

# Check dashboard
v dash

# Start a work session
v start myproject

# End session
v end
```

### Using Full Name

```bash
# These are equivalent
v test
vibe test

v coord sync
vibe coord sync
```

### Getting Help

```bash
v help              # Full help
v test help         # Test-specific help
```

---

## Configuration

The dispatcher uses colors from `lib/core.zsh` if available, with fallback definitions.

**Environment:** No special environment variables required.

---

## Related Commands

| Command | Relationship |
|---------|--------------|
| `pt` | Test runner (delegated) |
| `workflow` | Activity logging (delegated) |
| `dash` | Dashboard (delegated) |
| `status` | Status display (delegated) |

---

## Troubleshooting

### "Command not found" Errors

If you see errors like "pt command not found", the delegated command isn't available:

1. Check if the command exists: `which pt`
2. Ensure flow-cli is fully loaded: `source flow.plugin.zsh`
3. Some commands may be from external plugins

### Placeholder Messages

Many commands show "(Implementation coming soon)" - these are planned for future releases.

---

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-15 | Initial implementation |

---

## Source

**File:** `lib/dispatchers/v-dispatcher.zsh`
**Functions:** 12 total (v, vibe, _v_help, _v_test, *v_test**, _v_coord, _v_plan, _v_health)
