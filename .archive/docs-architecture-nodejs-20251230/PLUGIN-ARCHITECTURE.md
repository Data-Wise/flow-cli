# Plugin Architecture Design (v3.3.0)

> Extensible plugin system for flow-cli

## Overview

The plugin system allows users to extend flow-cli with custom commands, integrations, and workflows without modifying core code.

## Design Goals

1. **Simple to Create** - Single file plugins for simple cases
2. **Discoverable** - `flow plugin list` shows available plugins
3. **Safe** - Plugins are sandboxed, can't break core functionality
4. **ADHD-Friendly** - Minimal boilerplate, clear patterns

## Plugin Types

### Type 1: Single File Plugin

For simple extensions (new command, alias set, etc.):

```
~/.config/flow/plugins/my-plugin.zsh
```

### Type 2: Directory Plugin

For complex plugins with multiple components:

```
~/.config/flow/plugins/my-plugin/
├── plugin.json          # Metadata
├── main.zsh             # Entry point
├── commands/            # Additional commands
└── completions/         # ZSH completions
```

### Type 3: Git Plugin

Plugins hosted in git repositories:

```bash
flow plugin install gh:username/flow-plugin-name
```

## Plugin Structure

### plugin.json (Required for directory plugins)

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": "Your Name",
  "commands": ["mycommand", "another"],
  "dependencies": {
    "tools": ["jq", "curl"],
    "flow": ">=3.3.0"
  },
  "hooks": {
    "post-work": "scripts/on-work.zsh",
    "pre-finish": "scripts/on-finish.zsh"
  }
}
```

### main.zsh (Entry Point)

```zsh
# my-plugin/main.zsh
# Plugin entry point - loaded when flow starts

# Define plugin commands
mycommand() {
  echo "Hello from my plugin!"
}

# Register with flow (optional)
_flow_plugin_register "my-plugin" "1.0.0"
```

## Plugin Discovery

### Search Locations (Priority Order)

1. `$FLOW_PLUGIN_PATH` (custom paths)
2. `~/.config/flow/plugins/` (user plugins)
3. `$FLOW_PLUGIN_DIR/plugins/` (bundled plugins)

### Auto-Discovery

```bash
# List discovered plugins
flow plugin list

# Output:
# INSTALLED PLUGINS
#   my-plugin      v1.0.0  ~/.config/flow/plugins/my-plugin/
#   git-extras     v2.1.0  (bundled)
#
# AVAILABLE (not installed)
#   gh:data-wise/flow-plugin-docker
#   gh:data-wise/flow-plugin-kubernetes
```

## Plugin Commands

### flow plugin list

```bash
flow plugin list           # Show all plugins
flow plugin list --installed  # Only installed
flow plugin list --available  # Only available to install
```

### flow plugin install

```bash
flow plugin install <name>           # From registry
flow plugin install gh:user/repo     # From GitHub
flow plugin install /path/to/plugin  # Local path
flow plugin install --dev .          # Current dir (dev mode)
```

### flow plugin enable/disable

```bash
flow plugin enable my-plugin
flow plugin disable my-plugin
```

### flow plugin update

```bash
flow plugin update            # Update all
flow plugin update my-plugin  # Update specific
```

### flow plugin remove

```bash
flow plugin remove my-plugin
```

## Hook System

Plugins can hook into flow events:

| Hook             | When                   | Use Case             |
| ---------------- | ---------------------- | -------------------- |
| `post-work`      | After `work <project>` | Custom project setup |
| `pre-finish`     | Before `finish`        | Validation, cleanup  |
| `post-finish`    | After `finish`         | Notifications        |
| `session-start`  | Shell starts           | Load plugin state    |
| `session-end`    | Shell exits            | Save plugin state    |
| `project-change` | Directory change       | Context switching    |

### Hook Registration

```zsh
# In plugin main.zsh
_flow_hook_register "post-work" "_my_plugin_on_work"

_my_plugin_on_work() {
  local project="$1"
  echo "Started working on: $project"
}
```

## Configuration

### Plugin Settings

Plugins can have user-configurable settings:

```zsh
# ~/.config/flow/plugins/my-plugin/config.zsh
MY_PLUGIN_API_KEY="..."
MY_PLUGIN_DEFAULT_TIMEOUT=30
```

### Reading Config in Plugin

```zsh
# In main.zsh
local config_file="${FLOW_PLUGIN_DIR}/config.zsh"
[[ -f "$config_file" ]] && source "$config_file"

# Use with defaults
local timeout="${MY_PLUGIN_DEFAULT_TIMEOUT:-60}"
```

## Plugin API

### Core Functions Available to Plugins

```zsh
# Logging
_flow_log_info "message"
_flow_log_success "message"
_flow_log_warning "message"
_flow_log_error "message"

# Project detection
_flow_detect_project_type "$PWD"
_flow_find_project_root
_flow_in_project

# Session info
_flow_current_session
_flow_session_duration

# UI helpers
_flow_confirm "Are you sure?"
_flow_select_from "opt1" "opt2" "opt3"
_flow_progress_bar 50 100

# Plugin utilities
_flow_plugin_register "name" "version"
_flow_hook_register "event" "callback"
_flow_plugin_config_get "key" "default"
```

## Example Plugins

### Simple: Docker Integration

```zsh
# ~/.config/flow/plugins/docker.zsh

# Add docker commands to flow
flow_docker() {
  case "$1" in
    up)    docker-compose up -d ;;
    down)  docker-compose down ;;
    logs)  docker-compose logs -f "${2:-}" ;;
    ps)    docker-compose ps ;;
    *)     echo "Usage: flow docker [up|down|logs|ps]" ;;
  esac
}

# Register command
_flow_plugin_register "docker" "1.0.0"
```

### Complex: Slack Notifications

```
~/.config/flow/plugins/slack-notify/
├── plugin.json
├── main.zsh
└── config.example.zsh
```

```json
// plugin.json
{
  "name": "slack-notify",
  "version": "1.0.0",
  "description": "Send Slack notifications on session events",
  "dependencies": {
    "tools": ["curl", "jq"]
  },
  "hooks": {
    "post-work": "main.zsh:_slack_on_work",
    "post-finish": "main.zsh:_slack_on_finish"
  }
}
```

```zsh
# main.zsh
_slack_on_work() {
  local project="$1"
  _slack_send "Started working on: $project"
}

_slack_on_finish() {
  local project="$1"
  local duration=$(_flow_session_duration)
  _slack_send "Finished $project after ${duration}m"
}

_slack_send() {
  local msg="$1"
  local webhook="${SLACK_WEBHOOK_URL:-}"
  [[ -z "$webhook" ]] && return 1

  curl -s -X POST "$webhook" \
    -H 'Content-type: application/json' \
    -d "{\"text\": \"$msg\"}" >/dev/null
}
```

## Implementation Plan

### Phase 1: Foundation

1. Create plugin loader in `lib/plugin-loader.zsh`
2. Implement `_flow_plugin_register` and `_flow_hook_register`
3. Add plugin discovery logic
4. Create `flow plugin list`

### Phase 2: Installation

1. Implement `flow plugin install` (local paths)
2. Add GitHub repository support
3. Create `flow plugin enable/disable`
4. Add dependency checking

### Phase 3: Hooks

1. Implement hook system
2. Add hooks to existing commands (work, finish)
3. Create hook debugging tools
4. Document hook API

### Phase 4: Polish

1. Create plugin template generator
2. Add `flow plugin create` wizard
3. Build example plugins
4. Write comprehensive documentation

## Security Considerations

1. **No Auto-Execute** - Plugins must be explicitly enabled
2. **Source Review** - Show plugin source before install
3. **Dependency Audit** - Warn about external tool requirements
4. **No Network by Default** - Plugins can't make network calls without declaration

## File Locations

```
flow-cli/
├── lib/
│   └── plugin-loader.zsh    # Core plugin system
├── plugins/                  # Bundled plugins
│   ├── git-extras/
│   └── docker/
└── docs/
    └── plugins/
        ├── CREATING-PLUGINS.md
        └── PLUGIN-API.md

~/.config/flow/
├── plugins/                  # User plugins
│   └── my-plugin/
└── plugin-registry.json      # Installed plugins cache
```

---

_Design document for v3.3.0_
_Created: 2025-12-26_
