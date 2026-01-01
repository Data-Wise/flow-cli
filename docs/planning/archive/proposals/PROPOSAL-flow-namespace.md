# PROPOSAL: Unified `flow` Command Namespace

**Date:** 2025-12-25
**Status:** Draft for Review
**Goal:** Retire `v`/`vibe` dispatcher, unify under `flow` namespace

---

## Executive Summary

Replace the fragmented command landscape (`v`, `vibe`, plus individual commands) with a unified `flow` namespace that's discoverable, consistent, and ADHD-friendly.

---

## Current State Analysis

### Existing Command Landscape

| Type            | Commands                                                                            | Notes                           |
| --------------- | ----------------------------------------------------------------------------------- | ------------------------------- |
| **Direct**      | `pick`, `work`, `dash`, `finish`, `catch`, `status`, `timer`, `tutorial`, `morning` | Work well, but not discoverable |
| **ADHD**        | `js`, `next`, `stuck`, `focus`, `brk`, `why`, `hop`                                 | Scattered across files          |
| **Dispatchers** | `g`, `v`/`vibe`, `mcp`, `obs`                                                       | Different paradigms             |

### Problems with Current Approach

1. **Discoverability** - New users don't know what commands exist
2. **Namespace collision** - `v` conflicts with common aliases (vim, etc.)
3. **Inconsistent mental model** - Some commands direct, some dispatched
4. **No single entry point** - Can't type `flow` + Tab to see everything

---

## Proposed: `flow` Command

### Design Principles

1. **Single entry point** - `flow` is the main command
2. **Direct commands still work** - Power users keep shortcuts
3. **Subcommand grouping** - Related commands grouped logically
4. **Tutorial integration** - `flow learn` for guided experience
5. **ADHD-first** - Quick access to common actions

---

## Command Structure Comparison

### Before (Current)

```bash
# Direct commands (no namespace)
pick dev                    # Project picker
work flow-cli               # Start session
dash                        # Dashboard
finish "done for now"       # End session

# v/vibe dispatcher
v test                      # Run tests
v coord sync                # Ecosystem sync
vibe plan sprint            # Sprint planning

# ADHD helpers (direct)
js                          # Just start
stuck                       # Get unstuck
```

### After (Proposed)

```bash
# Namespaced (discoverable)
flow pick dev               # Project picker
flow work flow-cli          # Start session
flow dash                   # Dashboard
flow finish "done"          # End session

# Grouped subcommands
flow test                   # Run tests (context-aware)
flow sync                   # Git sync
flow plan                   # Sprint planning

# ADHD helpers (namespaced)
flow start                  # Just start (was: js)
flow stuck                  # Get unstuck
flow focus "writing tests"  # Set focus

# Learning
flow learn                  # Start tutorial
flow learn beginner         # Specific level
flow help                   # Full help

# Direct shortcuts still work!
pick dev                    # Alias → flow pick dev
work flow-cli               # Alias → flow work flow-cli
js                          # Alias → flow start
```

---

## Subcommand Groups

### ⭐ Core Workflow

| Command                | Action             | Alias           |
| ---------------------- | ------------------ | --------------- |
| `flow work <project>`  | Start work session | `work`          |
| `flow pick [category]` | Project picker     | `pick`, `pp`    |
| `flow dash [scope]`    | Dashboard          | `dash`          |
| `flow finish [note]`   | End session        | `finish`, `fin` |
| `flow hop <project>`   | Quick switch       | `hop`           |
| `flow why`             | Show context       | `why`           |

### ⭐ ADHD Helpers

| Command             | Action                   | Alias   |
| ------------------- | ------------------------ | ------- |
| `flow start`        | Just start (pick random) | `js`    |
| `flow stuck`        | Unblock helper           | `stuck` |
| `flow focus <text>` | Set focus                | `focus` |
| `flow next`         | What to work on          | `next`  |
| `flow break [mins]` | Take a break             | `brk`   |

### Capture & Track

| Command             | Action           | Alias    |
| ------------------- | ---------------- | -------- |
| `flow catch <idea>` | Quick capture    | `catch`  |
| `flow crumb <note>` | Leave breadcrumb | `crumb`  |
| `flow inbox`        | View inbox       | `inbox`  |
| `flow win <text>`   | Log a win        | `win`    |
| `flow status`       | Project status   | `status` |

### ⭐ Actions (Context-Aware)

| Command        | Action         | Notes                        |
| -------------- | -------------- | ---------------------------- |
| `flow test`    | Run tests      | Detects R/Node/Python        |
| `flow build`   | Build project  | Quarto/npm/R CMD             |
| `flow preview` | Preview output | Opens in browser             |
| `flow sync`    | Git sync       | Pull, push, handle conflicts |
| `flow check`   | Health check   | Linting, types, etc.         |

### Learning

| Command               | Action                    |
| --------------------- | ------------------------- |
| `flow learn`          | Start/resume tutorial     |
| `flow learn beginner` | Beginner lessons          |
| `flow learn medium`   | Medium lessons            |
| `flow learn advanced` | Advanced lessons          |
| `flow help`           | Full command reference    |
| `flow help <cmd>`     | Help for specific command |

### ⭐ Timer & Focus

| Command             | Action            | Alias     |
| ------------------- | ----------------- | --------- |
| `flow timer [mins]` | Start focus timer | `timer`   |
| `flow timer status` | Check timer       |           |
| `flow timer stop`   | Stop timer        |           |
| `flow morning`      | Morning routine   | `morning` |

---

## Retiring `v`/`vibe`

### Commands to Migrate

| Old             | New                 | Notes                 |
| --------------- | ------------------- | --------------------- |
| `v test`        | `flow test`         | Context-aware testing |
| `v test watch`  | `flow test --watch` | Watch mode            |
| `v coord sync`  | `flow sync`         | Simplified            |
| `v plan sprint` | `flow plan`         | Sprint planning       |
| `v log`         | `flow log`          | Activity log          |
| `vibe`          | `flow`              | Full namespace        |

### Deprecation Strategy

```bash
# v-dispatcher.zsh becomes thin wrapper
v() {
  echo "⚠️  'v' is deprecated. Use 'flow' instead."
  echo "   v $* → flow $*"
  flow "$@"
}
```

---

## Implementation Plan

### Phase 1: Core `flow` Command

- [ ] Create `commands/flow.zsh` - main dispatcher
- [ ] Implement subcommand routing
- [ ] Add `flow help` with full listing
- [ ] Keep all direct aliases working

### Phase 2: Migrate `v` Features

- [ ] Move `v test` → `flow test`
- [ ] Move `v sync` → `flow sync`
- [ ] Move `v plan` → `flow plan`
- [ ] Deprecation warnings in old `v`

### Phase 3: Tutorial Integration

- [ ] Rename `tutorial` → `flow learn`
- [ ] Add `flow learn run <name>` for named tutorials
- [ ] Add interactive `flow setup` for first-time users

### Phase 4: Completions & Polish

- [ ] ZSH completions for all subcommands
- [ ] Man page or `flow help --full`
- [ ] Update README and docs

---

## Quick Wins vs Long-term

### ⚡ Quick Wins (< 1 hour each)

1. Create basic `flow` dispatcher that routes to existing commands
2. Add `flow help` listing all commands
3. Deprecation wrapper for `v`

### 🔧 Medium Effort (1-2 hours)

4. `flow test` with context detection
5. `flow sync` smart git operations
6. Rename `tutorial` → `flow learn`

### 🏗️ Long-term (Future sessions)

7. Full ZSH completions
8. `flow setup` first-time wizard
9. Remove `v` dispatcher entirely

---

## Trade-offs

| Approach                      | Pros                 | Cons                    |
| ----------------------------- | -------------------- | ----------------------- |
| **Namespace only** (`flow x`) | Clean, discoverable  | More typing             |
| **Direct only** (current)     | Fast for power users | Not discoverable        |
| **Hybrid** (both work) ⭐     | Best of both worlds  | Maintain two interfaces |

**Recommendation:** Hybrid approach - `flow` for discovery, direct aliases for speed.

---

## Example Session with New `flow`

```bash
# Morning startup
$ flow morning
☀️ Good morning! Here's your context...

# Pick a project
$ flow pick dev
🔍 [fzf picker opens]

# Or just start something
$ flow start
🚀 Starting: flow-cli (most recent)

# Set focus
$ flow focus "implementing tutorial command"
🎯 Focus set

# Run tests
$ flow test
✅ Running: npm test (detected Node.js project)

# End session
$ flow finish "tutorial command done"
📝 Committed and session logged
```

---

## Decision Needed

1. **Naming:** `flow` vs `f` vs something else?
2. **Direct aliases:** Keep all, keep some, or retire?
3. **Timeline:** Implement now or plan for later?

---

## Recommended Next Step

→ **Implement Phase 1** - Create `commands/flow.zsh` dispatcher that:

- Routes `flow <cmd>` to existing commands
- Provides `flow help`
- Keeps all direct aliases working

This is low-risk and immediately useful for discoverability.
