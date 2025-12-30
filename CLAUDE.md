# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**flow-cli** - Pure ZSH plugin for ADHD-optimized workflow management.

- **Architecture:** Pure ZSH plugin (no Node.js runtime required)
- **Status:** Production ready (v4.4.3)
- **Install:** Via plugin manager (antidote, zinit, oh-my-zsh)
- **Optional:** Atlas integration for enhanced state management
- **Health Check:** `flow doctor` for dependency verification

### What It Does

- Instant workflow commands: `work`, `dash`, `finish`, `hop`
- 8 smart dispatchers: `g`, `mcp`, `obs`, `qu`, `r`, `cc`, `tm`, `wt`
- ADHD-friendly design (sub-10ms response, smart defaults)
- Session tracking, project switching, quick capture

---

## Layered Architecture (flow-cli + aiterm + craft)

flow-cli is part of a 3-layer developer tooling stack:

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 3: craft plugin (Claude Code)                            │
│  /craft:git:feature - AI-assisted, tests, changelog             │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: aiterm (Python CLI)                                   │
│  ait feature - rich visualization, complex automation           │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: flow-cli (Pure ZSH) ← YOU ARE HERE                    │
│  g, wt, cc - instant (<10ms), zero overhead, ADHD-friendly      │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use flow-cli vs aiterm

| Need                      | Use      | Command                  |
| ------------------------- | -------- | ------------------------ |
| **Quick branch creation** | flow-cli | `g feature start <name>` |
| **Quick worktree**        | flow-cli | `wt create <branch>`     |
| **Quick cleanup**         | flow-cli | `g feature prune`        |
| Full feature setup (deps) | aiterm   | `ait feature start -w`   |
| Pipeline visualization    | aiterm   | `ait feature status`     |
| Interactive cleanup       | aiterm   | `ait feature cleanup`    |
| **Quick MCP check**       | flow-cli | `mcp test <name>`        |
| Full MCP validation       | aiterm   | `ait mcp validate`       |
| **Launch Claude**         | flow-cli | `cc`, `cc yolo`          |
| Configure Claude settings | aiterm   | `ait claude settings`    |

### Delegation to aiterm

The `tm` dispatcher delegates to aiterm for rich operations:

- `tm ghost` → `ait ghost` (Ghostty terminal status)
- `tm detect` → `ait detect` (project context detection)
- `tm switch` → `ait switch` (apply context to terminal)

### flow-cli Owns:

1. **Instant operations** (<10ms response, pure ZSH)
2. **Session management** (work/finish/hop)
3. **ADHD motivation** (win/yay/streaks/goals)
4. **Quick navigation** (pick/dash)
5. **Simple dispatchers** (g/cc/mcp/r/qu/obs/wt/tm)

### aiterm Owns:

1. **Rich visualization** (tables, panels, trees via Rich)
2. **Complex automation** (deps install, multi-step workflows)
3. **Claude Code integration** (settings, hooks, approvals, MCP)
4. **Terminal configuration** (profiles, themes, fonts)
5. **Session tracking** (live sessions, conflicts, history)
6. **Workflow templates** (full workflow management)

**Repo:** https://github.com/Data-Wise/aiterm

---

## Quick Reference

### Core Commands

```bash
work <project>    # Start session
finish [note]     # End session (optional commit)
hop <project>     # Quick switch (tmux)
dash [category]   # Project dashboard
dash -i           # Interactive TUI (fzf)
dash --watch      # Live refresh mode
catch <text>      # Quick capture
js                # Just start (auto-picks project)
flow doctor       # Health check (verify dependencies)
flow doctor --fix # Interactive install missing tools
```

### Dopamine Features (v4.4.3)

```bash
win <text>        # Log accomplishment (auto-categorized)
yay               # Show recent wins
yay --week        # Weekly summary + graph
flow goal         # Show daily goal progress
flow goal set 3   # Set daily win target
```

**Categories:** 💻 code, 📝 docs, 👀 review, 🚀 ship, 🔧 fix, 🧪 test, ✨ other

### Active Dispatchers (8)

```bash
g <cmd>       # Git workflows (g status, g push, g commit)
mcp <cmd>     # MCP server management (mcp status, mcp logs)
obs <cmd>     # Obsidian notes (obs vaults, obs stats)
qu <cmd>      # Quarto publishing (qu preview, qu render)
r <cmd>       # R package dev (r test, r doc, r check)
cc [cmd]      # Claude Code launcher (cc, cc pick, cc yolo)
tm <cmd>      # Terminal manager (tm title, tm profile, tm ghost)
wt <cmd>      # Worktree management (wt create, wt status, wt prune)
```

**Get help:** `<dispatcher> help` (e.g., `r help`, `cc help`, `wt help`)

### CC Dispatcher Quick Reference

```bash
cc                # Launch Claude HERE (current dir, acceptEdits)
cc pick           # Pick project → Claude
cc <project>      # Direct jump → Claude (e.g., cc flow)
cc yolo           # Launch HERE in YOLO mode (skip permissions)
cc yolo pick      # Pick project → YOLO mode
cc plan           # Launch HERE in Plan mode
cc opus           # Launch HERE with Opus model
cc resume         # Resume Claude session picker
cc continue       # Continue most recent conversation
```

**Alias:** `ccy` = `cc yolo`

### TM Dispatcher Quick Reference

```bash
# Shell-native (instant, no Python)
tm title <text>       # Set tab/window title
tm profile <name>     # Switch iTerm2 profile
tm which              # Show detected terminal

# Aiterm delegation
tm ghost              # Ghostty status
tm ghost theme        # List/set Ghostty themes
tm switch             # Apply terminal context
tm detect             # Detect project context
```

**Aliases:** `tmt` = title, `tmp` = profile, `tmg` = ghost, `tms` = switch

### Deprecated (Removed 2025-12-25)

```bash
v / vibe      → Use 'flow' command instead
d             → Use 'dash' command
f             → Use 'flow' command
pp            → Use 'pick' command
ah            → Use 'aliashelp' command
```

**Note:** The `r` dispatcher no longer conflicts with `alias r=` - the alias was removed from ~/.config/zsh/.zshrc

---

## Project Structure

```
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/
│   ├── core.zsh              # Colors, logging, utilities
│   ├── atlas-bridge.zsh      # Atlas integration
│   ├── project-detector.zsh  # Project type detection
│   ├── tui.zsh               # Terminal UI components
│   └── dispatchers/          # Smart command dispatchers
│       ├── g-dispatcher.zsh      # Git workflows
│       ├── mcp-dispatcher.zsh    # MCP servers
│       ├── obs.zsh               # Obsidian
│       ├── qu-dispatcher.zsh     # Quarto
│       └── r-dispatcher.zsh      # R packages
├── commands/                 # Command implementations
│   ├── work.zsh             # work, finish, hop, why
│   ├── dash.zsh             # Dashboard
│   ├── capture.zsh          # catch, crumb, trail
│   ├── adhd.zsh             # js, next, stuck, focus
│   ├── flow.zsh             # flow command
│   ├── doctor.zsh           # Health check & dependency management
│   └── pick.zsh             # Project picker
├── setup/                    # Installation & setup
│   ├── Brewfile             # Recommended Homebrew packages
│   └── README.md            # Setup instructions
├── completions/             # ZSH completions
│   ├── _work, _dash, _flow, _hop, _pick
├── hooks/                   # ZSH hooks
│   ├── chpwd.zsh           # Directory change
│   └── precmd.zsh          # Pre-command
├── docs/                    # Documentation (MkDocs)
│   ├── reference/          # Reference cards
│   ├── tutorials/          # Step-by-step guides
│   ├── guides/             # How-to guides
│   └── commands/           # Command docs
├── tests/                   # Test suite
├── zsh/functions/          # Legacy (backward compat)
└── .archive/               # Archived Node.js CLI
```

---

## Key Files

| File                                     | Purpose                  | Notes                    |
| ---------------------------------------- | ------------------------ | ------------------------ |
| `flow.plugin.zsh`                        | Plugin entry point       | Source this to load      |
| `lib/core.zsh`                           | Core utilities           | Logging, colors, helpers |
| `lib/atlas-bridge.zsh`                   | Atlas integration        | Optional state engine    |
| `lib/dispatchers/*.zsh`                  | Smart dispatchers        | 6 active dispatchers     |
| `commands/*.zsh`                         | Core commands            | work, dash, finish, etc. |
| `docs/reference/DISPATCHER-REFERENCE.md` | Complete dispatcher docs | 442 lines                |
| `.STATUS`                                | Current progress         | Sprint tracking          |

---

## Development

### Testing the Plugin

```bash
# Load in current shell
source flow.plugin.zsh

# Test commands
work <Tab>           # Completions work
dash                 # Dashboard displays
r help               # Dispatcher help
qu help              # Dispatcher help
```

### Adding New Commands

1. **Choose location:**
   - Core command → `commands/<name>.zsh`
   - Dispatcher subcommand → `lib/dispatchers/<name>-dispatcher.zsh`

2. **Use helpers from `lib/core.zsh`:**

   ```bash
   _flow_log_success "Message"
   _flow_log_error "Error"
   _flow_find_project_root
   _flow_detect_project_type "$PWD"
   ```

3. **Add completion:**
   - Create `completions/_<commandname>`
   - Follow existing patterns

4. **Add help:**
   - Every dispatcher MUST have `_<cmd>_help()` function
   - Use color scheme from `lib/core.zsh`

### Adding New Dispatcher

1. **Create file:** `lib/dispatchers/<name>-dispatcher.zsh`

2. **Pattern:**

   ```bash
   # Single-letter or 2-letter function name
   x() {
       case "$1" in
           action1) shift; _x_action1 "$@" ;;
           action2) shift; _x_action2 "$@" ;;
           help|--help|-h) _x_help ;;
           *) _x_help ;;
       esac
   }

   _x_help() {
       # Formatted help with examples
   }
   ```

3. **Update docs:**
   - Add to `docs/reference/DISPATCHER-REFERENCE.md`
   - Update `docs/reference/COMMAND-QUICK-REFERENCE.md`
   - Update `mkdocs.yml` if needed

---

## Architecture Principles

### 1. Pure ZSH (No Node.js)

- All core commands in ZSH
- Sub-10ms response time
- No build step, no dependencies

### 2. ADHD-Friendly Design

| Principle        | Implementation              |
| ---------------- | --------------------------- |
| **Discoverable** | Built-in help: `<cmd> help` |
| **Consistent**   | Same pattern everywhere     |
| **Forgiving**    | Smart defaults, no errors   |
| **Fast**         | Cached project scanning     |

### 3. Dispatcher Pattern

```bash
# Pattern: command + keyword + options
r test              # R package: run tests
g push              # Git: push to remote
qu preview          # Quarto: preview document
```

**Benefits:**

- One command per domain
- Self-documenting
- Passthrough for advanced usage

### 4. Optional Enhancement

- Atlas integration is **optional**
- Graceful degradation without Atlas
- ZSH-only mode is fully functional

---

## Testing

### Test Suite Locations

```bash
# Integration tests (Atlas + flow-cli)
tests/integration/atlas-flow-integration.zsh

# Unit tests (ZSH only)
tests/unit/**/*.test.zsh

# E2E tests (require Atlas)
tests/test-atlas-e2e.zsh

# Interactive tests
tests/interactive-dog-feeding.zsh      # Gamified testing
tests/interactive-test.zsh
```

### Running Tests

```bash
# Quick test: Load plugin
source flow.plugin.zsh

# Unit tests
zsh tests/unit/test-project-detector.zsh

# Interactive (recommended for ADHD)
./tests/interactive-dog-feeding.zsh
```

---

## Documentation

### Website

**URL:** https://Data-Wise.github.io/flow-cli/  
**Build:** `mkdocs build`  
**Deploy:** `mkdocs gh-deploy --force`

### Key Docs

| Document                                     | Purpose                   |
| -------------------------------------------- | ------------------------- |
| `docs/guides/DOPAMINE-FEATURES-GUIDE.md`     | Win/streak/goal features  |
| `docs/reference/DISPATCHER-REFERENCE.md`     | Complete dispatcher guide |
| `docs/reference/ALIAS-REFERENCE-CARD.md`     | All 28 aliases            |
| `docs/reference/COMMAND-QUICK-REFERENCE.md`  | Quick command lookup      |
| `docs/reference/WORKFLOW-QUICK-REFERENCE.md` | Common workflows          |
| `docs/getting-started/quick-start.md`        | 5-minute tutorial         |
| `docs/CONVENTIONS.md`                        | Code standards            |
| `docs/PHILOSOPHY.md`                         | Design principles         |

### Updating Docs

1. **Edit markdown files in `docs/`**
2. **Test locally:** `mkdocs serve` (http://127.0.0.1:8000)
3. **Build:** `mkdocs build`
4. **Deploy:** `mkdocs gh-deploy --force`

**Navigation:** Update `mkdocs.yml` when adding new pages

---

## Configuration

### Environment Variables

Set in `.zshrc` **before** sourcing the plugin:

```zsh
# Project root directory
export FLOW_PROJECTS_ROOT="$HOME/projects"

# Atlas integration (auto|yes|no)
export FLOW_ATLAS_ENABLED="auto"

# Quiet mode (suppress welcome)
export FLOW_QUIET=1

# Debug mode
export FLOW_DEBUG=1
```

### User Preferences (2025-12-25)

- **Explicit commands** over shortcuts
- **No single-letter aliases** (too ambiguous)
- **Full command names** (dash, flow, pick, not d, f, pp)
- **Dispatchers** for domain-specific workflows

---

## Integration Points

| Project                  | Integration                              | Status             |
| ------------------------ | ---------------------------------------- | ------------------ |
| **atlas**                | Optional state engine (@data-wise/atlas) | Optional           |
| **zsh-claude-workflow**  | Shared project patterns                  | Active             |
| **claude-mcp**           | Browser extension MCP                    | Complementary      |
| **statistical-research** | MCP server (R, Zotero)                   | Via mcp dispatcher |

---

## Current Status (2025-12-30)

### ✅ v4.4.3 Released (Documentation)

- [x] 9 dedicated dispatcher reference pages:
  - CC, G, MCP, OBS, QU, R, TM, WT dispatchers
  - Plus main DISPATCHER-REFERENCE.md overview
- [x] All reference pages cross-linked with "See also"
- [x] Tutorial 11: TM Dispatcher

### ✅ v4.4.3 Released

- [x] `tm` dispatcher - Terminal manager (aiterm integration)
  - Shell-native: `tm title`, `tm profile`, `tm which`
  - Aiterm delegation: `tm ghost`, `tm switch`, `tm detect`
  - Aliases: `tmt`, `tmp`, `tmg`, `tms`, `tmd`

### ✅ v4.4.3 Released

- [x] `g feature status` - Show merged vs active branches
- [x] `g feature prune --older-than` - Filter by branch age
- [x] `g feature prune --force` - Skip confirmation
- [x] `wt status` - Show worktree health and disk usage
- [x] `wt prune` - Comprehensive cleanup with branch deletion
- [x] `cc wt status` - Show worktrees with Claude session info

### ✅ v4.4.3 Released

- [x] Worktree + Claude Integration (`cc wt`)
- [x] Branch cleanup (`g feature prune`)
- [x] 57 new tests

### 🎯 Production Ready

- **Version:** 4.4.0
- **Released:** 2025-12-30
- **Status:** Production use phase
- **Performance:** Sub-10ms for core commands
- **Documentation:** https://Data-Wise.github.io/flow-cli/
- **Tests:** 100+ tests across all features

### 📋 Future Roadmap

**Remote & Team Features**

- [ ] Remote state sync (optional cloud backup)
- [ ] Multi-device support
- [ ] Shared templates

---

## Common Tasks

### Update Dispatcher

1. Edit `lib/dispatchers/<name>-dispatcher.zsh`
2. Update help function `_<name>_help()`
3. Test: `source flow.plugin.zsh && <name> help`
4. Update docs: `docs/reference/DISPATCHER-REFERENCE.md`

### Add Alias

1. Check frequency: Only if used 10+ times/day
2. Add to appropriate section in .zshrc (NOT in flow-cli)
3. Update `docs/reference/ALIAS-REFERENCE-CARD.md`
4. Avoid conflicts with system commands

### Fix Startup Error

Common issues:

```bash
# Alias/function conflict
# Fix: Remove alias, keep function
unalias <name>

# Missing dependency
# Fix: Add conditional check
command -v <tool> >/dev/null || return

# Syntax error
# Fix: Check ZSH syntax (not bash)
```

### Deploy Documentation

```bash
# Build and test locally
mkdocs serve

# Deploy to GitHub Pages
mkdocs gh-deploy --force

# Verify
open https://Data-Wise.github.io/flow-cli/
```

### Create Release

```bash
# Use the release script to bump all version files
./scripts/release.sh 3.7.0

# Review changes
git diff

# Commit and tag
git add -A && git commit -m "chore: bump version to 3.7.0"
git tag -a v4.4.3 -m "v4.4.3"

# Push (requires PR for protected branch)
git push origin main && git push origin v4.4.3
```

**Files updated by release script:**

- `package.json` - version field
- `README.md` - badge version
- `CLAUDE.md` - version references
- `docs/reference/CC-DISPATCHER-REFERENCE.md` - version

---

## Support

- **Documentation:** https://Data-Wise.github.io/flow-cli/
- **Issues:** https://github.com/Data-Wise/flow-cli/issues
- **Tests:** `./tests/interactive-dog-feeding.zsh`

---

**Last Updated:** 2025-12-30
**Status:** Production Ready
