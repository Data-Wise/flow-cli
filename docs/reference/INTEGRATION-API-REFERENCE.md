# Integration Libraries API Reference

**Version:** flow-cli v5.15.1
**Generated:** 2026-01-22
**Coverage:** 80 functions across 6 libraries

---

## Overview

This document provides comprehensive API documentation for flow-cli's integration libraries. These libraries handle external service integration, plugin management, configuration, and system utilities.

### Libraries Covered

| Library | Functions | Purpose |
|---------|-----------|---------|
| [atlas-bridge.zsh](#atlas-bridgezsh) | 21 | Atlas CLI integration with fallback |
| [plugin-loader.zsh](#plugin-loaderzsh) | 23 | Plugin system management |
| [config.zsh](#configzsh) | 16 | Configuration management |
| [keychain-helpers.zsh](#keychain-helperszsh) | 7 | macOS Keychain secret management |
| [project-detector.zsh](#project-detectorzsh) | 4 | Project type detection |
| [project-cache.zsh](#project-cachezsh) | 9 | Project list caching |

---

## atlas-bridge.zsh

Atlas CLI integration with graceful fallback to local operations when Atlas is not installed.

### Timestamp Utilities

#### `_flow_timestamp`

Get current timestamp in YYYY-MM-DD HH:MM:SS format.

```zsh
_flow_timestamp
```

**Returns:** `0` - Always

**Output:** Timestamp string (e.g., "2026-01-22 14:30:45")

**Example:**
```zsh
ts=$(_flow_timestamp)
echo "Current time: $ts"
```

---

#### `_flow_timestamp_short`

Get current timestamp in short YYYY-MM-DD HH:MM format.

```zsh
_flow_timestamp_short
```

**Returns:** `0` - Always

**Output:** Short timestamp string (e.g., "2026-01-22 14:30")

**Example:**
```zsh
ts=$(_flow_timestamp_short)
echo "[$ts] Event logged"
```

---

### Atlas Detection

#### `_flow_has_atlas`

Check if Atlas CLI is available (with session-level caching).

```zsh
_flow_has_atlas
```

**Returns:**
- `0` - Atlas is available
- `1` - Atlas is not installed

**Example:**
```zsh
if _flow_has_atlas; then
    _flow_atlas session start "$project"
else
    echo "Atlas not installed, using fallback"
fi
```

**Notes:**
- Result is cached in `$_FLOW_ATLAS_AVAILABLE` for session duration
- Use `_flow_refresh_atlas` to force re-check

---

#### `_flow_refresh_atlas`

Force re-check of Atlas CLI availability (clears cache).

```zsh
_flow_refresh_atlas
```

**Returns:**
- `0` - Atlas is now available
- `1` - Atlas is still not installed

**Example:**
```zsh
# After installing atlas
_flow_refresh_atlas
if _flow_has_atlas; then
    echo "Atlas now available!"
fi
```

---

#### `_flow_init_atlas`

Initialize Atlas connection (respects FLOW_ATLAS_ENABLED setting).

```zsh
_flow_init_atlas
```

**Environment:**
- `FLOW_ATLAS_ENABLED` - "auto", "yes", or "no" (default: "auto")

**Example:**
```zsh
# Called during plugin initialization
_flow_init_atlas
```

---

### Atlas CLI Wrappers

#### `_flow_atlas`

Main Atlas CLI wrapper (use for all atlas calls).

```zsh
_flow_atlas <command> [args...]
```

**Arguments:**
- `$@` - Arguments to pass to atlas command

**Returns:**
- `0` - Atlas command succeeded
- `1` - Atlas not available or command failed

**Example:**
```zsh
_flow_atlas session start "my-project"
_flow_atlas project list --status=active
```

---

#### `_flow_atlas_silent`

Execute Atlas command silently (no output, return code only).

```zsh
_flow_atlas_silent <command> [args...]
```

**Returns:**
- `0` - Atlas available and command succeeded (or Atlas not available)

**Example:**
```zsh
_flow_atlas_silent session ping  # Just check if session is alive
```

---

#### `_flow_atlas_json`

Execute Atlas command with JSON output format.

```zsh
_flow_atlas_json <command> [args...]
```

**Output:** JSON output from Atlas command

**Example:**
```zsh
project_data=$(_flow_atlas_json project get "my-project")
echo "$project_data" | jq '.status'
```

---

#### `_flow_atlas_async`

Execute Atlas command asynchronously (fire-and-forget).

```zsh
_flow_atlas_async <command> [args...]
```

**Returns:** `0` - Always (command launched in background)

**Example:**
```zsh
# Log analytics event without blocking
_flow_atlas_async analytics log "session-started"
```

---

### Project Operations

#### `_flow_get_project`

Get project information by name.

```zsh
_flow_get_project <name>
```

**Arguments:**
- `$1` - (required) Project name to look up

**Returns:**
- `0` - Project found
- `1` - Project not found

**Output:** Shell-evaluable variables: `name`, `project_path`, `proj_status`

**Example:**
```zsh
if info=$(_flow_get_project "my-project"); then
    eval "$info"
    cd "$project_path"
fi
```

---

#### `_flow_get_project_fallback`

Find project by name in filesystem (fallback when Atlas unavailable).

```zsh
_flow_get_project_fallback <name>
```

**Arguments:**
- `$1` - (required) Project name to look up

**Output:**
```zsh
name="project-name"
project_path="/path/to/project"
proj_status="active"
```

**Notes:**
- Searches FLOW_PROJECTS_ROOT and common subdirectories
- Search order: root, dev-tools, r-packages/*, research, teaching, quarto

---

#### `_flow_list_projects`

List all projects (uses Atlas if available, otherwise fallback).

```zsh
_flow_list_projects [status_filter]
```

**Arguments:**
- `$1` - (optional) Status filter (e.g., "active", "archived")

**Output:** Project names, one per line

**Example:**
```zsh
# List all projects
_flow_list_projects

# List only active projects
_flow_list_projects "active"
```

---

#### `_flow_list_projects_fallback`

List projects by scanning filesystem for .STATUS files.

```zsh
_flow_list_projects_fallback [status_filter]
```

**Notes:**
- Scans recursively for .STATUS files in FLOW_PROJECTS_ROOT
- Uses ZSH glob qualifiers: (N) for nullglob

---

### Session Operations

#### `_flow_session_start`

Start a work session for a project.

```zsh
_flow_session_start <project>
```

**Arguments:**
- `$1` - (required) Project name to start session for

**Side Effects:**
- Creates session state file
- Exports `FLOW_CURRENT_PROJECT` and `FLOW_SESSION_START`
- Appends to worklog file (fallback mode)

**Example:**
```zsh
_flow_session_start "my-project"
echo "Working on: $FLOW_CURRENT_PROJECT"
```

---

#### `_flow_session_end`

End the current work session.

```zsh
_flow_session_end [note]
```

**Arguments:**
- `$1` - (optional) Note to record with session end

**Side Effects:**
- Removes session state file
- Unsets `FLOW_CURRENT_PROJECT` and `FLOW_SESSION_START`

**Example:**
```zsh
_flow_session_end "Completed feature X"
```

---

#### `_flow_session_current`

Get information about the current active session.

```zsh
_flow_session_current
```

**Returns:**
- `0` - Active session found
- `1` - No active session

**Output:**
```zsh
project=<name>
elapsed_mins=<minutes>
```

**Example:**
```zsh
if info=$(_flow_session_current); then
    eval "$info"
    echo "Working on $project for $elapsed_mins minutes"
fi
```

---

#### `_flow_today_session_time`

Calculate total session time for today.

```zsh
_flow_today_session_time
```

**Output:** Total minutes worked today (integer)

**Example:**
```zsh
total=$(_flow_today_session_time)
echo "Worked $((total / 60))h $((total % 60))m today"
```

---

### Capture Operations

#### `_flow_catch`

Quick capture of a thought/task to inbox.

```zsh
_flow_catch <text> [project]
```

**Arguments:**
- `$1` - (required) Text to capture
- `$2` - (optional) Project to associate with capture

**Example:**
```zsh
_flow_catch "Fix the login bug"
_flow_catch "Update docs" "my-project"
```

---

#### `_flow_inbox`

Display the capture inbox contents.

```zsh
_flow_inbox
```

**Output:** Inbox contents or "Inbox empty" message

---

### Context Operations

#### `_flow_where`

Get current project context ("where was I?").

```zsh
_flow_where [project]
```

**Arguments:**
- `$1` - (optional) Project name to get context for

**Example:**
```zsh
_flow_where             # Context for current directory
_flow_where "my-proj"   # Context for specific project
```

---

#### `_flow_where_fallback`

Get project context from filesystem (fallback).

```zsh
_flow_where_fallback [project]
```

**Notes:**
- Parses .STATUS file for Status: and Focus: lines
- Detects project from current directory if not specified

---

#### `_flow_crumb`

Leave a breadcrumb (context marker for future reference).

```zsh
_flow_crumb <text> [project]
```

**Arguments:**
- `$1` - (required) Breadcrumb text (what you were working on)
- `$2` - (optional) Project to associate with breadcrumb

**Example:**
```zsh
_flow_crumb "Debugging auth flow"
```

---

### Direct Atlas Access

#### `at`

Shortcut alias for Atlas CLI (or fallback commands).

```zsh
at <command> [args...]
```

**Subcommands (fallback mode):**
- `catch|c <text>` - Quick capture
- `inbox|i` - Show inbox
- `where|w [project]` - Show context
- `crumb|b <text>` - Leave breadcrumb

**Example:**
```zsh
at session start my-project    # Atlas mode
at catch "Fix bug"             # Works with or without Atlas
```

---

## plugin-loader.zsh

Plugin system for flow-cli providing plugin discovery, loading, and hook management.

### Plugin Registration

#### `_flow_plugin_register`

Register a plugin with the flow-cli plugin system.

```zsh
_flow_plugin_register <name> [version] [description]
```

**Arguments:**
- `$1` - (required) Plugin name (unique identifier)
- `$2` - (optional) Version string [default: "1.0.0"]
- `$3` - (optional) Plugin description

**Returns:**
- `0` - Registration successful
- `1` - Name not provided

**Example:**
```zsh
# In plugin's main.zsh
_flow_plugin_register "my-plugin" "2.0.0" "My awesome plugin"
```

---

#### `_flow_plugin_exists`

Check if a plugin is registered.

```zsh
_flow_plugin_exists <name>
```

**Returns:**
- `0` - Plugin is registered
- `1` - Plugin is not registered

**Example:**
```zsh
if _flow_plugin_exists "my-plugin"; then
    echo "Plugin is loaded"
fi
```

---

#### `_flow_plugin_enabled`

Check if a plugin is currently enabled.

```zsh
_flow_plugin_enabled <name>
```

**Returns:**
- `0` - Plugin is enabled
- `1` - Plugin is disabled or not registered

---

#### `_flow_plugin_version`

Get the version string of a registered plugin.

```zsh
_flow_plugin_version <name>
```

**Output:** Version string (e.g., "2.0.0") or "unknown"

---

#### `_flow_plugin_path`

Get the filesystem path of a registered plugin.

```zsh
_flow_plugin_path <name>
```

**Output:** Plugin path or empty string if not found

---

### Plugin Discovery

#### `_flow_plugin_discover`

Discover all available plugins in configured plugin paths.

```zsh
_flow_plugin_discover
```

**Output:** Plugin paths, one per line (sorted, unique)

**Notes:**
- Searches FLOW_PLUGIN_PATHS array
- Finds single-file plugins (*.zsh)
- Finds directory plugins (with main.zsh or plugin.json)

---

#### `_flow_plugin_metadata`

Extract metadata from a plugin.

```zsh
_flow_plugin_metadata <plugin_path>
```

**Output:** Pipe-delimited metadata: `name|version|description|type`

**Example:**
```zsh
metadata=$(_flow_plugin_metadata "/path/to/plugin")
echo "$metadata"  # my-plugin|1.0.0|Description|directory
```

---

### Plugin Loading

#### `_flow_plugin_load`

Load and initialize a single plugin from path.

```zsh
_flow_plugin_load <plugin_path>
```

**Arguments:**
- `$1` - (required) Path to plugin file or directory

**Returns:**
- `0` - Plugin loaded successfully
- `1` - Plugin not found, no entry point, or load failed

**Example:**
```zsh
_flow_plugin_load "$HOME/.config/flow/plugins/my-plugin"
```

---

#### `_flow_plugin_load_all`

Discover and load all enabled plugins.

```zsh
_flow_plugin_load_all
```

**Notes:**
- Skips disabled plugins from registry
- Called automatically by `_flow_plugin_init`

---

#### `_flow_plugin_check_deps`

Verify a plugin's dependencies are satisfied.

```zsh
_flow_plugin_check_deps <plugin_json_path>
```

**Returns:**
- `0` - All dependencies met (or no jq to check)
- `1` - Missing tool dependency

---

### Plugin Enable/Disable

#### `_flow_plugin_enable`

Enable a plugin and persist the setting.

```zsh
_flow_plugin_enable <name>
```

**Example:**
```zsh
_flow_plugin_enable "my-plugin"
```

---

#### `_flow_plugin_disable`

Disable a plugin and persist the setting.

```zsh
_flow_plugin_disable <name>
```

**Notes:** Requires shell reload to take effect

---

#### `_flow_plugin_is_disabled`

Check if a plugin is disabled in the persistent registry.

```zsh
_flow_plugin_is_disabled <name>
```

**Returns:**
- `0` - Plugin is disabled
- `1` - Plugin is not disabled (or no registry)

---

#### `_flow_plugin_registry_save`

Persist plugin enable/disable state to registry file.

```zsh
_flow_plugin_registry_save
```

**Notes:** Writes to `$FLOW_PLUGIN_REGISTRY` (JSON format)

---

#### `_flow_plugin_registry_load`

Load plugin enable/disable state from registry file.

```zsh
_flow_plugin_registry_load
```

---

### Hook System

#### `_flow_hook_register`

Register a callback function for a hook event.

```zsh
_flow_hook_register <event> <callback>
```

**Arguments:**
- `$1` - (required) Hook event name
- `$2` - (required) Callback function name

**Valid Events:**
- `post-work` - After work <project>
- `pre-finish` - Before finish
- `post-finish` - After finish
- `session-start` - Shell starts
- `session-end` - Shell exits
- `project-change` - Directory change to project
- `pre-command` - Before any flow command
- `post-command` - After any flow command

**Example:**
```zsh
_my_on_work() {
    echo "Started working on: $1"
}
_flow_hook_register "post-work" "_my_on_work"
```

---

#### `_flow_hook_run`

Execute all registered callbacks for a hook event.

```zsh
_flow_hook_run <event> [args...]
```

**Arguments:**
- `$1` - (required) Hook event name
- `$@` - Additional arguments passed to callbacks

**Example:**
```zsh
_flow_hook_run "post-work" "$project_name"
```

---

#### `_flow_hook_list`

Display all registered hooks and their callbacks.

```zsh
_flow_hook_list
```

---

### Plugin Listing

#### `_flow_plugin_list`

Display all installed plugins with their status.

```zsh
_flow_plugin_list [show_available]
```

**Arguments:**
- `$1` - (optional) "true" to show discovered but not loaded plugins

---

### Initialization

#### `_flow_plugin_init`

Initialize the plugin system and load all enabled plugins.

```zsh
_flow_plugin_init
```

**Notes:**
- Loads registry
- Creates user plugin directory
- Loads all enabled plugins
- Runs session-start hooks

---

#### `_flow_plugin_cleanup`

Clean up plugin system on shell exit.

```zsh
_flow_plugin_cleanup
```

**Notes:** Runs session-end hooks

---

### Utility Functions

#### `_flow_plugin_config_get`

Retrieve a configuration value for the current plugin.

```zsh
_flow_plugin_config_get <key> [default]
```

**Arguments:**
- `$1` - (required) Configuration key
- `$2` - (optional) Default value if key not found

---

#### `_flow_plugin_create`

Create a new plugin from template with boilerplate structure.

```zsh
_flow_plugin_create <name> [directory]
```

**Arguments:**
- `$1` - (required) Plugin name
- `$2` - (optional) Base directory [default: user plugins dir]

**Creates:**
- `plugin.json` - Plugin manifest
- `main.zsh` - Plugin entry point with examples

**Example:**
```zsh
_flow_plugin_create "my-plugin"
# Creates ~/.config/flow/plugins/my-plugin/
```

---

## config.zsh

Configuration management for flow-cli with profiles and persistence.

### Configuration File Management

#### `_flow_config_init`

Initialize the configuration system and load existing config.

```zsh
_flow_config_init
```

**Notes:**
- Creates config and profile directories if needed
- Loads config from file or uses defaults
- Called automatically on source

---

#### `_flow_config_load`

Load configuration values from the config file.

```zsh
_flow_config_load
```

**Returns:**
- `0` - Config loaded successfully
- `1` - Config file doesn't exist

---

#### `_flow_config_save`

Save current configuration values to the config file.

```zsh
_flow_config_save
```

**Notes:** Writes to `$FLOW_CONFIG_FILE` with header and timestamp

---

### Configuration Value Accessors

#### `_flow_config_get`

Retrieve a configuration value by key.

```zsh
_flow_config_get <key> [default]
```

**Arguments:**
- `$1` - (required) Configuration key
- `$2` - (optional) Default value if key not found

**Example:**
```zsh
projects_root=$(_flow_config_get "projects_root" "$HOME/projects")
```

---

#### `_flow_config_set`

Set a configuration value in memory.

```zsh
_flow_config_set <key> <value>
```

**Arguments:**
- `$1` - (required) Configuration key
- `$2` - (required) Value to set

**Notes:** Call `_flow_config_save` to persist

---

#### `_flow_config_reset`

Reset a single configuration value to its default.

```zsh
_flow_config_reset <key>
```

**Returns:**
- `0` - Key reset successfully
- `1` - Key not found in defaults

---

#### `_flow_config_reset_all`

Reset all configuration values to their defaults.

```zsh
_flow_config_reset_all
```

---

#### `_flow_config_is_set`

Check if a configuration value differs from its default.

```zsh
_flow_config_is_set <key>
```

**Returns:**
- `0` - Value is different from default
- `1` - Value equals default

---

### Configuration Display

#### `_flow_config_show`

Display all configuration values in a formatted, categorized view.

```zsh
_flow_config_show [filter] [show_all]
```

**Arguments:**
- `$1` - (optional) Filter string to match keys/categories
- `$2` - (optional) "true" to show all values

**Categories:** core, ui, timer, adhd, git, ai

---

#### `_flow_config_export`

Output configuration in a sourceable/exportable format.

```zsh
_flow_config_export
```

**Output:** `FLOW_CONFIG[key]="value"` lines

---

### Configuration Profiles

#### `_flow_config_profile_list`

Display all available configuration profiles.

```zsh
_flow_config_profile_list
```

**Built-in Profiles:**
- `minimal` - Minimal settings, quiet mode
- `developer` - Full developer settings
- `adhd` - Maximum ADHD support features
- `researcher` - Academic workflow optimized

---

#### `_flow_config_profile_save`

Save the current configuration as a named profile.

```zsh
_flow_config_profile_save <name>
```

**Arguments:**
- `$1` - (required) Profile name (alphanumeric, hyphens, underscores)

**Notes:** Cannot overwrite built-in profile names

---

#### `_flow_config_profile_load`

Load a configuration profile.

```zsh
_flow_config_profile_load <name>
```

**Arguments:**
- `$1` - (required) Profile name (built-in or user-defined)

**Example:**
```zsh
_flow_config_profile_load "adhd"
_flow_config_save  # Persist the loaded profile
```

---

#### `_flow_config_profile_delete`

Delete a user-defined configuration profile.

```zsh
_flow_config_profile_delete <name>
```

**Notes:** Cannot delete built-in profiles

---

### Interactive Configuration

#### `_flow_config_wizard`

Run an interactive configuration wizard.

```zsh
_flow_config_wizard
```

**Notes:**
- Prompts for common settings (core, timer, adhd, git)
- Press Enter to keep current value
- Offers to save at the end

---

### Apply Configuration

#### `_flow_config_apply`

Apply configuration values to environment variables.

```zsh
_flow_config_apply
```

**Environment Variables Set:**
- `FLOW_PROJECTS_ROOT`
- `FLOW_ATLAS_ENABLED`
- `FLOW_LOAD_DISPATCHERS`
- `FLOW_QUIET` (if quiet=1)
- `FLOW_DEBUG` (if debug=1)

---

## keychain-helpers.zsh

macOS Keychain secret management with Touch ID support.

### Secret Management

#### `_dot_kc_add`

Add or update a secret in macOS Keychain.

```zsh
_dot_kc_add <name>
```

**Arguments:**
- `$1` - (required) Secret name (identifier)

**Notes:**
- Prompts for secret value with hidden input
- Uses `-U` flag to update if exists

**Example:**
```zsh
_dot_kc_add "github-token"
# Enter secret value: ****
```

---

#### `_dot_kc_get`

Retrieve a secret value from macOS Keychain.

```zsh
_dot_kc_get <name>
```

**Arguments:**
- `$1` - (required) Secret name to retrieve

**Returns:**
- `0` - Secret found
- `1` - Secret not found

**Output:** Secret value (raw, no decorations)

**Example:**
```zsh
export GITHUB_TOKEN=$(_dot_kc_get "github-token")
```

---

#### `_dot_kc_list`

List all flow-cli secrets stored in macOS Keychain.

```zsh
_dot_kc_list
```

**Output:** List of secret names with bullet points

---

#### `_dot_kc_delete`

Remove a secret from macOS Keychain.

```zsh
_dot_kc_delete <name>
```

**Arguments:**
- `$1` - (required) Secret name to delete

**Returns:**
- `0` - Secret deleted
- `1` - Secret not found

---

#### `_dot_kc_import`

Bulk import secrets from Bitwarden folder into macOS Keychain.

```zsh
_dot_kc_import
```

**Prerequisites:**
- Bitwarden CLI (`bw`) installed
- Active Bitwarden session (`$BW_SESSION`)
- Folder named "flow-cli-secrets" in Bitwarden

---

#### `_dot_kc_help`

Display help documentation for keychain secret commands.

```zsh
_dot_kc_help
```

---

#### `_dot_secret_kc`

Main router/dispatcher for all dot secret subcommands.

```zsh
_dot_secret_kc <subcommand> [args...]
```

**Subcommands:**
- `add|new` - Store a secret
- `get` - Retrieve a secret
- `list|ls` - List all secrets
- `delete|rm|remove` - Remove a secret
- `import` - Import from Bitwarden
- `help` - Show help

**Notes:** Default action (no subcommand) treats arg as secret name for get

---

## project-detector.zsh

Project type detection based on marker files and directories.

### Detection Functions

#### `_flow_detect_project_type`

Detect project type based on marker files present.

```zsh
_flow_detect_project_type [directory]
```

**Arguments:**
- `$1` - (optional) Directory to check [default: $PWD]

**Returns:** `0` - Always

**Output:** Project type string

**Project Types:**
| Type | Markers |
|------|---------|
| `r-package` | DESCRIPTION + NAMESPACE |
| `teaching` | syllabus.qmd, lectures/, .flow/teach-config.yml |
| `research` | manuscript.qmd, paper.qmd |
| `quarto` | _quarto.yml |
| `obsidian` | .obsidian/ |
| `python` | pyproject.toml, setup.py |
| `node` | package.json |
| `rust` | Cargo.toml |
| `go` | go.mod |
| `generic` | (default) |

**Example:**
```zsh
type=$(_flow_detect_project_type)
echo "This is a $type project"
```

---

#### `_flow_project_commands`

Get suggested commands relevant to a project type.

```zsh
_flow_project_commands [type]
```

**Arguments:**
- `$1` - (optional) Project type [default: auto-detected]

**Output:** Space-separated list of relevant commands

**Example:**
```zsh
_flow_project_commands "r-package"
# Output: devtools::check() devtools::test() devtools::document() devtools::build()
```

---

#### `_flow_project_icon`

Get emoji icon representing a project type.

```zsh
_flow_project_icon [type]
```

**Arguments:**
- `$1` - (optional) Project type [default: auto-detected]

**Output:** Emoji icon

**Icons:**
| Type | Icon |
|------|------|
| r-package | 📦 |
| python | 🐍 |
| node | 📗 |
| rust | 🦀 |
| go | 🐹 |
| quarto | 📝 |
| teaching | 🎓 |
| research | 🔬 |
| obsidian | 💎 |
| generic | 📁 |

---

#### `_flow_validate_teaching_config`

Validate a teaching workflow configuration file.

```zsh
_flow_validate_teaching_config <config_path>
```

**Arguments:**
- `$1` - (required) Path to teach-config.yml

**Returns:**
- `0` - Configuration is valid
- `1` - Missing required fields

**Required Fields:**
- `course.name`
- `branches.draft`
- `branches.production`

---

## project-cache.zsh

Project list caching layer for sub-10ms pick response times.

### Cache Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJ_CACHE_FILE` | `~/.cache/flow-cli/projects.cache` | Cache file location |
| `PROJ_CACHE_TTL` | `300` | Cache TTL in seconds (5 minutes) |
| `FLOW_CACHE_ENABLED` | `1` | Enable/disable caching |

### Cache Generation

#### `_proj_cache_generate`

Generate project cache from filesystem scan.

```zsh
_proj_cache_generate
```

**Returns:**
- `0` - Cache generated successfully
- `1` - Failed to create directory or write file

**Notes:**
- Always generates complete unfiltered list
- Filters applied at read time for flexibility

---

### Cache Validation

#### `_proj_cache_is_valid`

Check if project cache exists and is within TTL.

```zsh
_proj_cache_is_valid
```

**Returns:**
- `0` - Cache is valid (exists and not stale)
- `1` - Cache is invalid, missing, or stale

---

### Cache Access

#### `_proj_list_all_cached`

Get project list from cache with optional filtering.

```zsh
_proj_list_all_cached [category] [recent_only]
```

**Arguments:**
- `$1` - (optional) Category filter (e.g., "dev", "r")
- `$2` - (optional) "recent" to filter for recent sessions only

**Notes:**
- Main public API replacing `_proj_list_all`
- Regenerates cache automatically if stale
- Falls back to uncached if cache disabled

**Example:**
```zsh
# Get all projects
_proj_list_all_cached

# Get dev-tools projects
_proj_list_all_cached "dev"

# Get recently used projects
_proj_list_all_cached "" "recent"
```

---

### Cache Invalidation

#### `_proj_cache_invalidate`

Delete cache file to force regeneration on next access.

```zsh
_proj_cache_invalidate
```

**Returns:**
- `0` - Cache invalidated (or didn't exist)

---

### Cache Statistics

#### `_proj_cache_stats`

Display detailed cache statistics and health status.

```zsh
_proj_cache_stats
```

**Output:**
- Cache status (valid/stale)
- Cache age vs TTL
- Number of cached projects
- Cache file location

---

#### `_proj_format_duration`

Convert seconds to human-readable duration string.

```zsh
_proj_format_duration <seconds>
```

**Arguments:**
- `$1` - (required) Number of seconds

**Output:** Formatted string (e.g., "2m 30s" or "45s")

---

### Public Commands

#### `flow-cache-refresh`

Manually invalidate and regenerate the project cache.

```zsh
flow-cache-refresh
```

---

#### `flow-cache-clear`

Delete the project cache file without regenerating.

```zsh
flow-cache-clear
```

---

#### `flow-cache-status`

Display current cache status and statistics.

```zsh
flow-cache-status
```

---

## Common Usage Patterns

### Atlas with Fallback

```zsh
# Start session with automatic fallback
_flow_session_start "my-project"

# Quick capture works with or without Atlas
_flow_catch "Remember to update docs"

# End session with note
_flow_session_end "Completed feature X"
```

### Plugin Development

```zsh
# Create new plugin
_flow_plugin_create "my-awesome-plugin"

# In main.zsh
_flow_plugin_register "my-awesome-plugin" "1.0.0" "Does awesome things"

# Register hooks
_flow_hook_register "post-work" "_my_on_work"
_flow_hook_register "session-end" "_my_cleanup"
```

### Configuration Profiles

```zsh
# Load ADHD-optimized profile
_flow_config_profile_load "adhd"
_flow_config_save

# Create custom profile
_flow_config_set "timer_default" "30"
_flow_config_set "dopamine_mode" "yes"
_flow_config_profile_save "my-profile"
```

### Keychain Secrets

```zsh
# Store a secret
_dot_kc_add "github-token"

# Use in scripts
export GITHUB_TOKEN=$(_dot_kc_get "github-token")
gh auth login --with-token <<< $(_dot_kc_get "github-token")
```

### Project Detection

```zsh
# Get project info
type=$(_flow_detect_project_type)
icon=$(_flow_project_icon "$type")
commands=$(_flow_project_commands "$type")

echo "$icon This is a $type project"
echo "Suggested commands: $commands"
```

---

## See Also

- [Core API Reference](CORE-API-REFERENCE.md) - Core utilities (logging, TUI, git helpers)
- [Teaching API Reference](TEACHING-API-REFERENCE.md) - Teaching workflow libraries
- [Dispatcher Reference](DISPATCHER-REFERENCE.md) - Command dispatchers
- [Architecture Overview](ARCHITECTURE-OVERVIEW.md) - System architecture

---

**Last Updated:** 2026-01-22
**Author:** Claude Opus 4.5
