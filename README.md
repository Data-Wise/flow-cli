# flow-cli

**Pure ZSH Workflow Plugin** - ADHD-optimized productivity for developers.

## Overview

flow-cli is a ZSH plugin that provides instant workflow commands. It optionally integrates with [atlas](../atlas) for enhanced state management.

```
┌─────────────────────────────────────────────────────────────────┐
│  flow-cli                       atlas (optional)                │
│  ─────────                      ────────────────                │
│  Pure ZSH plugin                Node.js state engine            │
│  • Sub-10ms response            • Project registry              │
│  • work/finish/dash             • Session tracking              │
│  • hop/why/catch                • Context reconstruction        │
│  • TUI dashboard                                                 │
│  Consumes ──────────────────────▶ Enhanced features             │
└─────────────────────────────────────────────────────────────────┘
```

**Works standalone** - atlas is optional for enhanced features.

## Installation

### Using a plugin manager (recommended)

```zsh
# antidote
antidote install data-wise/flow-cli

# zinit
zinit light data-wise/flow-cli

# oh-my-zsh
git clone https://github.com/data-wise/flow-cli.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/flow-cli
# Then add flow-cli to plugins array in .zshrc
```

### Manual installation

```bash
git clone https://github.com/data-wise/flow-cli.git ~/.flow-cli
echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc
```

### Optional: Install atlas for enhanced features

```bash
npm install -g @data-wise/atlas
```

## Quick Start

```zsh
# Start working on a project
work myproject

# Finish session (with optional commit)
finish "completed feature X"

# Quick project switch (tmux)
hop otherproject

# Show context ("where was I?")
why

# Quick capture an idea
catch "check that paper about mediation"

# Show dashboard
dash
```

## Commands

| Command          | Description                    |
| ---------------- | ------------------------------ |
| `work <project>` | Start working on a project     |
| `finish [note]`  | End session, optionally commit |
| `hop <project>`  | Quick switch (tmux sessions)   |
| `dash`           | Show project dashboard         |
| `why`            | Show current context           |
| `catch <text>`   | Quick capture idea/task        |
| `crumb <text>`   | Leave breadcrumb               |
| `at <cmd>`       | Direct atlas access            |

## Configuration

Set in `.zshrc` before sourcing the plugin:

```zsh
# Project root directory
export FLOW_PROJECTS_ROOT="$HOME/projects"

# Atlas integration (auto|yes|no)
export FLOW_ATLAS_ENABLED="auto"

# Quiet mode (no welcome message)
export FLOW_QUIET=1
```

## Directory Structure

```
flow-cli/
├── flow.plugin.zsh      # Plugin entry point
├── commands/            # Command implementations
│   ├── work.zsh         # work, finish, hop, why
│   ├── dash.zsh         # Dashboard
│   ├── capture.zsh      # catch, crumb
│   └── adhd.zsh         # ADHD helpers
├── lib/                 # Core libraries
│   ├── core.zsh         # Colors, logging, utils
│   ├── atlas-bridge.zsh # Atlas integration
│   ├── project-detector.zsh
│   └── tui.zsh          # Terminal UI
├── completions/         # ZSH completions
├── hooks/               # ZSH hooks (chpwd, precmd)
└── zsh/                 # Legacy functions (being migrated)
```

## Atlas Integration

When atlas is installed, flow-cli automatically uses it for:

- Project registry (faster lookups)
- Session tracking (work/finish)
- Context reconstruction (why)
- Quick capture (catch, crumb)

Without atlas, flow-cli falls back to:

- Filesystem-based project discovery
- Local worklog file
- Basic context from .STATUS files

## Project Types

flow-cli auto-detects project types:

| Type      | Detection                      | Icon |
| --------- | ------------------------------ | ---- |
| R Package | `DESCRIPTION` file             | 📦   |
| Quarto    | `_quarto.yml`                  | 📘   |
| Node.js   | `package.json`                 | 🟢   |
| Python    | `pyproject.toml` or `setup.py` | 🐍   |
| Git repo  | `.git` directory               | 📁   |

## Dependencies

**Required:** ZSH 5.0+

**Optional (enhanced features):**

- [fzf](https://github.com/junegunn/fzf) - Fuzzy project picker
- [gum](https://github.com/charmbracelet/gum) - Beautiful prompts
- [atlas](../atlas) - State management engine
- tmux - Session management for `hop`

## License

MIT

## Related

- [atlas](../atlas) - Project state engine
- [zsh-claude-workflow](../zsh-claude-workflow) - Claude integration
