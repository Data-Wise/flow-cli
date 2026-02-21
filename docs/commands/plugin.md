# flow plugin

> Plugin management for flow-cli extensions

## Synopsis

```bash
flow plugin [command] [options]
flow plugin list
flow plugin install <path|gh:user/repo>
flow plugin create <name>
```text

## Description

`flow plugin` manages the flow-cli plugin system. Plugins extend flow-cli with new commands, hooks, and functionality without modifying the core codebase.

## Commands

| Command                | Description                                 |
| ---------------------- | ------------------------------------------- |
| `list`                 | List all installed plugins                  |
| `enable <name>`        | Enable a disabled plugin                    |
| `disable <name>`       | Disable a plugin (persists across sessions) |
| `create <name>`        | Create a new plugin from template           |
| `install <path>`       | Install plugin from local path              |
| `install gh:user/repo` | Install plugin from GitHub                  |
| `remove <name>`        | Remove a user-installed plugin              |
| `info <name>`          | Show plugin details                         |
| `hooks`                | Show all registered hooks                   |
| `path`                 | Show plugin search paths                    |

## Plugin Search Paths

Plugins are discovered in these locations:

1. `~/.config/flow/plugins/` - User plugins
2. `~/.local/share/flow/plugins/` - Installed plugins
3. `<flow-cli>/plugins/` - Bundled plugins

## Hook System

Plugins can register callbacks for these events:

| Hook             | Trigger                 | Use Case                     |
| ---------------- | ----------------------- | ---------------------------- |
| `post-work`      | After `work` command    | Project setup, notifications |
| `pre-finish`     | Before `finish` command | Validation, cleanup          |
| `post-finish`    | After `finish` command  | Notifications, stats         |
| `session-start`  | When session begins     | Logging, timers              |
| `session-end`    | When session ends       | Cleanup, reporting           |
| `project-change` | On chpwd in project     | Context switching            |
| `pre-command`    | Before any command      | Logging, validation          |
| `post-command`   | After any command       | Stats, notifications         |

## Examples

### List Plugins

```bash
flow plugin list
```text

Output:

```text
INSTALLED PLUGINS

  example  v1.0.0  [enabled]
    Example plugin demonstrating capabilities
    Path: ~/.config/flow/plugins/example

  TOTALS
    Installed: 1
    Enabled: 1
```text

### Create a Plugin

```bash
flow plugin create my-plugin
```text

Creates:

```text
~/.config/flow/plugins/my-plugin/
├── main.zsh          # Plugin entry point
├── plugin.json       # Metadata (optional)
└── README.md         # Documentation
```bash

### Install from GitHub

```bash
# Install from GitHub
flow plugin install gh:username/flow-plugin-name

# Install as dev (symlink)
flow plugin install --dev ~/code/my-plugin
```bash

### Enable/Disable

```bash
# Disable a plugin
flow plugin disable example

# Re-enable it
flow plugin enable example
```text

### View Hook Registrations

```bash
flow plugin hooks
```text

Output:

```text
REGISTERED HOOKS

  post-work:
    _example_on_work (example)

  session-start:
    _example_on_session (example)

  TOTALS
    Events with hooks: 2
    Total callbacks: 2
```zsh

## Creating Plugins

### Minimal Plugin (Single File)

`~/.config/flow/plugins/hello/main.zsh`:

```zsh
# Register the plugin
_flow_plugin_register "hello" "1.0.0" "Says hello"

# Define commands
hello() {
    echo "Hello from my plugin!"
}
```zsh

### Plugin with Hooks

```zsh
_flow_plugin_register "notify" "1.0.0" "Desktop notifications"

# Register hook callback
_notify_on_finish() {
    local project="$1"
    osascript -e "display notification \"Finished $project\" with title \"flow-cli\""
}
_flow_hook_register "post-finish" "_notify_on_finish"
```zsh

### Plugin with Dependencies

```zsh
_flow_plugin_register "git-stats" "1.0.0" "Git statistics"

# Check dependencies
_flow_plugin_require_tool "git" || return 1
_flow_plugin_require_tool "gh" || return 1

# Plugin code here...
```text

### Plugin Metadata (plugin.json)

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "My awesome plugin",
  "author": "Your Name",
  "requires": {
    "flow": ">=3.3.0",
    "tools": ["git", "fzf"]
  },
  "hooks": ["post-work", "post-finish"]
}
```zsh

## Plugin API

### Registration

```zsh
# Register plugin
_flow_plugin_register "name" "version" "description"

# Check if plugin exists
_flow_plugin_exists "name"

# Get plugin info
_flow_plugin_info "name"
```zsh

### Hooks

```zsh
# Register hook callback
_flow_hook_register "event-name" "callback_function"

# Run hooks for an event
_flow_hook_run "event-name" "$arg1" "$arg2"
```zsh

### Dependencies

```zsh
# Require a CLI tool
_flow_plugin_require_tool "tool-name"

# Require flow version
_flow_plugin_require_version "3.3.0"
```zsh

### Logging

```zsh
# Use flow-cli logging
_flow_log_success "Operation complete"
_flow_log_error "Something went wrong"
_flow_log_warning "Watch out"
_flow_log_debug "Debug info"
```text

## Plugin Registry

Disabled plugins are tracked in:

```text
~/.config/flow/plugin-registry.json
```text

Format:

```json
{
  "disabled": ["plugin-a", "plugin-b"],
  "settings": {}
}
```

## Best Practices

1. **Use unique prefixes** - Prefix functions with plugin name (e.g., `_myplugin_func`)
2. **Check dependencies** - Use `_flow_plugin_require_tool` for external tools
3. **Handle errors gracefully** - Don't break flow-cli if plugin fails
4. **Document hooks** - Specify which hooks your plugin uses
5. **Keep it focused** - One plugin, one purpose

## Related Commands

- [`flow config`](config.md) - Configuration management
- [`flow doctor`](doctor.md) - Check system health

## See Also

- [Contributing Guide](../contributing/CONTRIBUTING.md)
- [Example Plugin](https://github.com/data-wise/flow-cli/tree/main/plugins/example)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (plugin v3.3.0)
**Status:** ✅ Production ready with hook system
