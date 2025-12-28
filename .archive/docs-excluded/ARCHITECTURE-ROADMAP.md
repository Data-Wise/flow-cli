# Architecture Roadmap - Pure ZSH Plugin

**Status:** v3.6.2 Released
**Date:** 2025-12-27
**Architecture:** Pure ZSH plugin (no Node.js runtime)
**Philosophy:** Sub-10ms response, ADHD-friendly design

---

## Current Architecture (v3.x)

flow-cli achieved Clean Architecture by **removing** complexity, not adding it.

```
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/
│   ├── core.zsh              # Colors, logging, utilities
│   ├── atlas-bridge.zsh      # Optional atlas integration
│   ├── project-detector.zsh  # Project type detection
│   ├── tui.zsh               # Terminal UI components
│   └── dispatchers/          # Smart command routing
│       ├── g-dispatcher.zsh  # Git workflows
│       ├── cc-dispatcher.zsh # Claude Code
│       ├── r-dispatcher.zsh  # R packages
│       ├── qu-dispatcher.zsh # Quarto
│       ├── obs.zsh           # Obsidian
│       └── mcp-dispatcher.zsh # MCP servers
├── commands/                 # Command implementations
│   ├── work.zsh             # Session management
│   ├── dash.zsh             # Dashboard
│   ├── capture.zsh          # Quick capture, wins
│   ├── adhd.zsh             # ADHD helpers
│   ├── flow.zsh             # Main dispatcher
│   └── pick.zsh             # Project picker
├── completions/             # ZSH completions
├── hooks/                   # ZSH hooks
└── docs/                    # MkDocs documentation
```

### Key Decisions

| Decision           | Rationale                                 |
| ------------------ | ----------------------------------------- |
| Pure ZSH           | Sub-10ms response, no Node.js overhead    |
| Optional atlas     | Graceful degradation without dependencies |
| Dispatcher pattern | Domain-specific commands (g, r, cc, qu)   |
| .STATUS files      | Simple text-based project state           |

---

## Version History

### v3.6.x (Current)

- CC dispatcher with pick variants
- Release automation (scripts/release.sh)
- Full documentation site

### v3.5.0

- Dopamine features (win, yay, streak)
- Daily goal tracking
- Extended .STATUS format

### v3.4.0

- AI recipes and templates
- Multi-model support
- Conversation mode

### v3.3.0

- Plugin system
- Hook system (8 events)
- Configuration profiles

### v3.2.0

- AI-powered commands (flow ai, flow do)
- Install/upgrade system
- Context-aware prompts

### v3.1.0

- flow doctor with --fix
- Brewfile for dependencies

### v3.0.0

- Pure ZSH architecture
- Archived 140KB legacy code
- Clean plugin structure

---

## v4.0.0 Roadmap

### Goals

- Cross-tool orchestration
- Remote state sync (optional)
- Team features (optional)

### Planned Features

#### Cross-Tool Orchestration

```bash
flow sync all          # Sync everything (atlas + git + obsidian)
flow status all        # Unified status across tools
flow export            # Export state for backup/migration
```

**Components:**

- Unified sync command
- Status aggregation
- Import/export formats

#### Remote State Sync

```bash
flow cloud init        # Initialize cloud backup
flow cloud push        # Push state to cloud
flow cloud pull        # Pull state from cloud
flow cloud status      # Show sync status
```

**Requirements:**

- Optional (local-first always)
- End-to-end encryption
- Multiple backend support (S3, GitHub, custom)
- Conflict resolution

#### Team Features

```bash
flow team init         # Initialize team space
flow team template     # Shared project templates
flow team dash         # Team dashboard
```

**Scope:**

- Shared templates only (no real-time sync)
- Optional opt-in
- Privacy-respecting

---

## Architecture Principles

### 1. ADHD-Friendly

- Sub-10ms response for all commands
- Smart defaults (no config required)
- Built-in help (`<cmd> help`)

### 2. Graceful Degradation

- Works without atlas
- Works without fzf, gum
- Core functionality never breaks

### 3. Domain Dispatchers

- One command per domain (g, r, cc, qu)
- Consistent pattern: `cmd action [args]`
- Self-documenting with help

### 4. Optional Enhancement

- Atlas provides state engine
- AI features require API key
- Cloud features require config

---

## Migration from Node.js CLI

The original flow-cli had a Node.js CLI component (`cli/`) with:

- TypeScript definitions
- ES modules
- Clean Architecture layers

This was **archived to .archive/** in v3.0.0 because:

1. ZSH-only is faster (no Node.js startup)
2. Simpler to maintain
3. Atlas handles state management
4. No build step required

**Legacy docs are preserved in `.archive/docs/` for reference.**

---

## Implementation Status

| Feature               | Status   | Version |
| --------------------- | -------- | ------- |
| Pure ZSH architecture | Complete | v3.0.0  |
| 6 dispatchers         | Complete | v3.6.0  |
| Dopamine features     | Complete | v3.5.0  |
| Plugin system         | Complete | v3.3.0  |
| AI features           | Complete | v3.4.0  |
| Cross-tool sync       | Planned  | v4.0.0  |
| Remote state          | Planned  | v4.0.0  |
| Team features         | Planned  | v4.0.0  |

---

## Related Documents

- [Quick Reference](QUICK-REFERENCE.md)
- [Plugin Architecture](PLUGIN-ARCHITECTURE.md)
- [v4.0.0 Planning](../planning/V4-PLANNING.md)
- [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md)

---

**Last Updated:** 2025-12-27
**Status:** v3.6.2 Released, v4.0.0 Planning
