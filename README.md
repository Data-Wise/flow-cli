# flow-cli

[![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)](https://github.com/Data-Wise/flow-cli/releases/tag/v4.0.0)
[![CI Tests](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml/badge.svg)](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-online-brightgreen.svg)](https://data-wise.github.io/flow-cli/)

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

# Interactive dashboard (TUI via atlas)
dash --full
```

## Testing Your Installation

After installing, validate everything works with our interactive dog feeding test:

```bash
./tests/interactive-dog-feeding.zsh
```

This gamified test walks you through validating all core commands in a fun, ADHD-friendly way. Feed a virtual dog by confirming commands work correctly! 🐕

**Features:**

- 👀 Shows expected output before running commands
- ✅ Interactive validation (just confirm y/n)
- ⭐ Star rating system (aim for 5 stars!)
- 🎮 Gamification makes testing engaging

See [tests/DOG-FEEDING-TEST-README.md](tests/DOG-FEEDING-TEST-README.md) for details.

## Commands

| Command          | Description                      |
| ---------------- | -------------------------------- |
| `work <project>` | Start working on a project       |
| `finish [note]`  | End session, optionally commit   |
| `hop <project>`  | Quick switch (tmux sessions)     |
| `dash`           | Show project dashboard           |
| `dash --full`    | Interactive TUI (requires atlas) |
| `why`            | Show current context             |
| `catch <text>`   | Quick capture idea/task          |
| `crumb <text>`   | Leave breadcrumb                 |
| `trail [proj]`   | Show breadcrumb trail            |
| `at <cmd>`       | Direct atlas access              |
| `win <text>`     | Log accomplishment (v3.5.0)      |
| `yay`            | Show recent wins (v3.5.0)        |
| `flow goal`      | Daily goal tracking (v3.5.0)     |

### Dispatchers (Smart Context-Aware Functions)

The plugin includes 6 active dispatchers for common workflows:

```zsh
g <cmd>       # Git workflows (status, commit, push, etc.)
mcp <cmd>     # MCP server management (status, logs, restart)
obs <cmd>     # Obsidian notes (search, daily, capture)
qu <cmd>      # Quarto publishing (preview, render, pdf)
r <cmd>       # R package development (test, doc, check, cycle)
cc [cmd]      # Claude Code launcher (cc, cc pick, cc yolo)
```

See [DISPATCHER-REFERENCE.md](docs/reference/DISPATCHER-REFERENCE.md) for complete documentation.

### Command Shortcuts

```zsh
c "idea"      # catch
i             # inbox
b "note"      # crumb (breadcrumb)
t             # trail
```

### Dash Options

```zsh
dash                # Quick ZSH dashboard
dash --full         # Atlas TUI dashboard
dash -i             # Interactive fzf picker
dash --watch        # Live refresh mode (v3.5.0)
dash --active       # Show only active projects
```

### Dopamine Features (v3.5.0)

```zsh
# Log wins with auto-categorization
win "Fixed the login bug"        # 🔧 fix
win "Deployed to production"     # 🚀 ship
win "Added unit tests"           # 🧪 test

# View wins
yay                              # Recent wins
yay --week                       # Weekly summary + graph

# Daily goal tracking
flow goal set 3                  # Set daily target
flow goal                        # Check progress
```

**Dashboard shows:** streak counter, recent wins, goal progress.

See [Dopamine Features Guide](docs/guides/DOPAMINE-FEATURES-GUIDE.md) for details.

## Session Conflict Handling

When you `work` on a new project while another session is active:

```zsh
$ work medrobust
⚠️ Active session: atlas
End current session and switch to medrobust? (y/n)
```

This prevents accidentally leaving orphan sessions.

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
│   ├── capture.zsh      # catch, crumb, trail
│   └── adhd.zsh         # ADHD helpers
├── lib/                 # Core libraries
│   ├── core.zsh         # Colors, logging, utils
│   ├── atlas-bridge.zsh # Atlas integration
│   ├── project-detector.zsh
│   └── tui.zsh          # Terminal UI
├── completions/         # ZSH completions
├── hooks/               # ZSH hooks (chpwd, precmd)
├── tests/               # Test suites
│   └── integration/     # Atlas integration tests
└── zsh/                 # Legacy functions (being migrated)
```

## Programmatic API

flow-cli exposes internal functions for shell scripting:

### Project Functions

```zsh
# Get project info (returns shell-eval format)
info=$(_flow_get_project "myproject")
eval "$info"  # Sets: name, path, proj_status

# List all projects
projects=("${(@f)$(_flow_list_projects)}")

# List by status filter
active=("${(@f)$(_flow_list_projects "active")}")
```

### Session Functions

```zsh
# Start session
_flow_session_start "myproject"

# End session with optional note
_flow_session_end "completed feature"
```

### Capture Functions

```zsh
# Quick capture
_flow_catch "idea text"
_flow_catch "project-specific task" "myproject"

# Leave breadcrumb
_flow_crumb "working on auth module"

# Show inbox
_flow_inbox
```

### Context Functions

```zsh
# Get context ("where was I?")
_flow_where
_flow_where "myproject"  # Specific project

# Timestamp (zsh/datetime)
ts=$(_flow_timestamp)       # 2025-12-25 10:30:00
ts=$(_flow_timestamp_short) # 2025-12-25 10:30
```

### Atlas Functions

```zsh
# Check if atlas is available
if _flow_has_atlas; then
  echo "Atlas connected"
fi

# Direct atlas call
_flow_atlas project list --format=json

# Silent (no output)
_flow_atlas_silent sync

# JSON output
json=$(_flow_atlas_json where)

# Async (fire-and-forget)
_flow_atlas_async crumb "background note"
```

### Helper Functions

```zsh
# Logging (colored output)
_flow_log_success "Done!"
_flow_log_warning "Careful..."
_flow_log_error "Failed!"
_flow_log_debug "Debug info"  # Only when FLOW_DEBUG=1

# Project detection
root=$(_flow_find_project_root)
type=$(_flow_detect_project_type "$PWD")
name=$(_flow_project_name "$PWD")
```

## Atlas Integration

When atlas is installed, flow-cli automatically uses it for:

- Project registry (faster lookups)
- Session tracking (work/finish)
- Context reconstruction (why)
- Quick capture (catch, crumb, trail)
- Interactive dashboard (dash --full)

Without atlas, flow-cli falls back to:

- Filesystem-based project discovery
- Local worklog file
- Basic context from .STATUS files

### Output Format Expectations

flow-cli expects these atlas output formats:

| Command          | Format Flag      | Expected Output                   |
| ---------------- | ---------------- | --------------------------------- |
| `project list`   | `--format=names` | One name per line                 |
| `project show`   | `--format=shell` | `name="x"` `path="y"` (eval-able) |
| `session status` | `--format=json`  | JSON with `project` field         |

### Version Compatibility

| flow-cli | atlas | Status        |
| -------- | ----- | ------------- |
| 2.x      | 0.1.x | ✅ Compatible |
| 3.x      | 0.1.x | 🔮 Planned    |

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

## Testing

```bash
# Unit tests (always run)
zsh tests/test-atlas-integration.zsh

# E2E tests (require atlas)
zsh tests/test-atlas-e2e.zsh

# Full integration test (atlas + flow-cli coordination)
zsh tests/integration/atlas-flow-integration.zsh
```

Test results:

- **Integration tests**: 26 tests (fallback mode)
- **E2E tests**: 20+ tests (when atlas installed)

## License

MIT

## Related

- [atlas](../atlas) - Project state engine
- [zsh-claude-workflow](../zsh-claude-workflow) - Claude integration
