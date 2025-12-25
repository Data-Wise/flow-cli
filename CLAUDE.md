# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **flow-cli** - a pure ZSH plugin for ADHD-optimized workflow management. The repo contains:

- ZSH plugin with instant workflow commands (`work`, `dash`, `finish`, etc.)
- Optional Atlas integration for enhanced state management
- ADHD-optimized workflow guides and documentation
- Legacy functions retained for backward compatibility

**Architecture:** Pure ZSH plugin (no Node.js runtime required)

## Project Structure

```
flow-cli/
├── flow.plugin.zsh      # Plugin entry point
├── lib/                 # Core libraries
│   ├── core.zsh         # Colors, logging, utilities
│   ├── atlas-bridge.zsh # Atlas state engine integration
│   ├── project-detector.zsh
│   └── tui.zsh          # Terminal UI components
├── commands/            # Command implementations
│   ├── work.zsh         # work, finish, hop, why
│   ├── dash.zsh         # Dashboard display
│   ├── capture.zsh      # catch, inbox, crumb, win
│   └── adhd.zsh         # js, next, stuck, focus, brk
├── completions/         # ZSH completions (_work, _dash, etc.)
├── hooks/               # ZSH hooks
│   ├── chpwd.zsh        # Directory change hook
│   └── precmd.zsh       # Pre-command hook
├── zsh/functions/       # Legacy functions (backward compat)
├── docs/                # Documentation
├── .archive/            # Archived Node.js CLI (2025-12-25)
└── .STATUS              # Current progress tracking
```

## Key Files

| File                   | Purpose                          |
| ---------------------- | -------------------------------- |
| `flow.plugin.zsh`      | Plugin entry point (source this) |
| `.STATUS`              | Current sprint progress          |
| `README.md`            | User-facing installation guide   |
| `lib/core.zsh`         | Core utilities (logging, colors) |
| `lib/atlas-bridge.zsh` | Atlas integration layer          |

## Commands

| Command           | Description                    | File                 |
| ----------------- | ------------------------------ | -------------------- |
| `work <project>`  | Start working on a project     | commands/work.zsh    |
| `finish [note]`   | End session, optionally commit | commands/work.zsh    |
| `hop <project>`   | Quick switch (tmux)            | commands/work.zsh    |
| `dash [category]` | Show project dashboard         | commands/dash.zsh    |
| `catch <text>`    | Quick capture idea/task        | commands/capture.zsh |
| `js`              | Just start (ADHD helper)       | commands/adhd.zsh    |

## Development

### Testing the plugin

```bash
# Load plugin in current shell
source flow.plugin.zsh

# Test commands work
work <Tab>    # Should show completions
dash          # Should show dashboard
```

### Adding new commands

1. Create function in appropriate `commands/*.zsh` file
2. Use `_flow_*` helpers from `lib/core.zsh`
3. Add completion in `completions/_commandname`

### Legacy functions

The `zsh/functions/` directory contains legacy implementations. When both exist:

- New `commands/*.zsh` load first
- Legacy `zsh/functions/*.zsh` overwrite (safe fallback)

To activate new implementations, remove the legacy duplicate.

## Current Phase

- **P7 - Architecture Refactor** (Active)
  - [x] Pure ZSH plugin structure
  - [x] Atlas integration bridge
  - [x] Completions for main commands
  - [ ] Documentation updates
  - [ ] Remove legacy duplicates after testing

## Integration Points

| Project               | Integration                                |
| --------------------- | ------------------------------------------ |
| `atlas`               | Optional state engine (`@data-wise/atlas`) |
| `zsh-claude-workflow` | Shared project detection patterns          |

## Configuration

Set before sourcing the plugin:

```zsh
export FLOW_PROJECTS_ROOT="$HOME/projects"  # Project root
export FLOW_ATLAS_ENABLED="auto"            # auto|yes|no
export FLOW_QUIET=1                         # Suppress welcome
```
