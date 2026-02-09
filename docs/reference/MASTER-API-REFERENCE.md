---
tags:
  - reference
---

# Master API Reference

**Purpose:** Complete API documentation for all flow-cli library functions
**Audience:** Developers, contributors, advanced users
**Format:** Function signatures, parameters, return values, examples
**Version:** v5.19.1-dev
**Last Updated:** 2026-01-27

---

## Overview

This document provides complete API documentation for all flow-cli library functions. Functions are organized by library file and categorized by purpose.

### Coverage Status

**Total Functions:** 716
**Documented:** 178 (24.9%)
**Auto-Generated:** Will be updated by `scripts/generate-api-docs.sh`

### Library Organization

flow-cli's library is organized into focused modules:

```text
lib/
├── core.zsh                    # Core utilities (80+ functions)
├── atlas-bridge.zsh            # Atlas integration (15+ functions)
├── project-detector.zsh        # Project type detection (25+ functions)
├── tui.zsh                     # Terminal UI components (30+ functions)
├── inventory.zsh               # Tool inventory (10+ functions)
├── keychain-helpers.zsh        # macOS Keychain (20+ functions)
├── config-validator.zsh        # Config validation (15+ functions)
├── git-helpers.zsh             # Git integration (30+ functions)
├── doctor-cache.zsh            # Token validation caching (13 functions)
├── concept-extraction.zsh      # Teaching: YAML parsing (7 functions)
├── prerequisite-checker.zsh    # Teaching: DAG validation (7 functions)
├── analysis-cache.zsh          # Teaching: Cache management (18 functions)
├── cache-analysis.zsh          # Teaching: Cache statistics (6 functions)
├── analysis-display.zsh        # Teaching: Display layer (8 functions)
├── report-generator.zsh        # Teaching: Report generation (11 functions)
├── ai-analysis.zsh             # Teaching: Claude integration (8 functions)
├── ai-recipes.zsh              # Teaching: AI prompt templates (11 functions)
├── ai-usage.zsh                # Teaching: AI usage tracking (9 functions)
├── slide-optimizer.zsh         # Teaching: Slide breaks (8 functions)
└── dispatchers/                # 12 dispatcher modules (478+ functions)
    ├── g-dispatcher.zsh
    ├── cc-dispatcher.zsh
    ├── r-dispatcher.zsh
    ├── qu-dispatcher.zsh
    ├── mcp-dispatcher.zsh
    ├── obs.zsh
    ├── wt-dispatcher.zsh
    ├── dot-dispatcher.zsh
    ├── teach-dispatcher.zsh
    ├── tm-dispatcher.zsh
    ├── prompt-dispatcher.zsh
    └── v-dispatcher.zsh
```

---

## How to Use This Reference

### For Developers

**Finding functions:**
1. Use browser search (Ctrl+F / Cmd+F)
2. Check [Function Index](#function-index) (alphabetical)
3. Browse by category

**Understanding function signatures:**

```zsh
function_name() {
    # Parameters:
    #   $1 - description of first parameter
    #   $2 - description of second parameter (optional)
    # Returns:
    #   0 - success
    #   1 - error
    # Example:
    #   function_name "arg1" "arg2"
}
```

### For Contributors

When adding new functions:
1. Follow naming conventions (see [CONVENTIONS.md](../CONVENTIONS.md))
2. Add inline documentation
3. Run `./scripts/generate-api-docs.sh` to update this file
4. Test examples

---

## Table of Contents

- [Core Library](#core-library) - Essential utilities
- [Atlas Integration](#atlas-integration) - State engine
- [Project Detection](#project-detection) - Project type detection
- [Terminal UI](#terminal-ui) - TUI components
- [Tool Inventory](#tool-inventory) - Dependency tracking
- [Keychain Helpers](#keychain-helpers) - Secret management
- [Config Validation](#config-validation) - Configuration
- [Git Helpers](#git-helpers) - Git integration
- [Doctor Cache](#doctor-cache) - Token validation caching (v5.17.0+)
- [Commands Internal API](#commands-internal-api) - Command helper functions
- [Teaching Libraries](#teaching-libraries) - AI-powered teaching workflow (v5.16.0+)
- [Teaching Libraries](#teaching-libraries) - AI-powered teaching
- [Dispatcher Guide](MASTER-DISPATCHER-GUIDE.md) - Dispatcher functions (separate document)
- [Function Index](#function-index) - Alphabetical index

---

## Core Library

**File:** `lib/core.zsh`
**Purpose:** Essential utilities used throughout flow-cli
**Functions:** 80+

### Logging & Output

#### `_flow_log_success`

Logs success message with green checkmark.

**Signature:**

```zsh
_flow_log_success "message"
```

**Parameters:**
- `$1` - Message to log

**Returns:**
- Always returns 0

**Example:**

```zsh
_flow_log_success "Project initialized successfully"
# Output: ✅ Project initialized successfully
```

---

#### `_flow_log_error`

Logs error message with red X.

**Signature:**

```zsh
_flow_log_error "message"
```

**Parameters:**
- `$1` - Error message

**Returns:**
- Always returns 1

**Example:**

```zsh
_flow_log_error "Configuration file not found"
# Output: ❌ Configuration file not found
```

---

#### `_flow_log_warning`

Logs warning message with yellow warning sign.

**Signature:**

```zsh
_flow_log_warning "message"
```

**Parameters:**
- `$1` - Warning message

**Returns:**
- Always returns 0

**Example:**

```zsh
_flow_log_warning "Token expires in 5 days"
# Output: ⚠️  Token expires in 5 days
```

---

#### `_flow_log_info`

Logs info message with blue info icon.

**Signature:**

```zsh
_flow_log_info "message"
```

**Parameters:**
- `$1` - Info message

**Returns:**
- Always returns 0

**Example:**

```zsh
_flow_log_info "Loading configuration from ~/.flowrc"
# Output: ℹ️  Loading configuration from ~/.flowrc
```

---

#### `_flow_log`

Base logging function with color support.

**Signature:**

```zsh
_flow_log "level" "message" ["arg2" ...]
```

**Parameters:**
- `$1` (required) - Log level: `success`, `warning`, `error`, `info`, `debug`, or `muted`
- `$@` (required) - Message to display

**Returns:**
- Always returns 0

**Output:**
- Colored message to stdout with automatic color reset

**Example:**

```zsh
_flow_log success "Operation completed"
_flow_log error "Something went wrong"
_flow_log warning "Check configuration"
```

**Notes:**
- Uses `FLOW_COLORS` associative array for level-to-color mapping
- Falls back to 'info' color if level not found
- Automatically resets color codes after message

---

#### `_flow_log_muted`

Logs muted/gray text without prefix symbol.

**Signature:**

```zsh
_flow_log_muted "message"
```

**Parameters:**
- `$@` (required) - Message to display

**Returns:**
- Always returns 0

**Output:**
- Gray-colored text to stdout

**Example:**

```zsh
_flow_log_muted "Last updated: 2 hours ago"
# Output: Last updated: 2 hours ago (in gray)
```

**Notes:**
- No prefix symbol like other logging functions
- Useful for supplementary information and status details

---

#### `_flow_log_debug`

Log debug message (only when FLOW_DEBUG is set).

**Signature:**

```zsh
_flow_log_debug "message"
```

**Parameters:**
- `$@` (required) - Message to display

**Returns:**
- Always returns 0

**Output:**
- `[debug] message` in gray (only if `FLOW_DEBUG` is set)

**Example:**

```zsh
export FLOW_DEBUG=1
_flow_log_debug "Variable value: $var"
# Output: [debug] Variable value: foo (in gray)
```

**Notes:**
- Silent when `FLOW_DEBUG` is unset or empty
- Useful for troubleshooting without cluttering normal output
- Can be toggled on/off via environment variable

---

### Status Icons

#### `_flow_status_icon`

Convert project status string to emoji indicator.

**Signature:**

```zsh
_flow_status_icon "status"
```

**Parameters:**
- `$1` (required) - Status string (case-insensitive)

**Returns:**
- Always returns 0

**Output:**
- Single emoji character representing status

**Status Mapping:**
- `active` / `ACTIVE` → 🟢 (green circle)
- `paused` / `PAUSED` → 🟡 (yellow circle)
- `blocked` / `BLOCKED` → 🔴 (red circle)
- `archived` / `ARCHIVED` → ⚫ (black circle)
- `stalled` → 🟠 (orange circle)
- `(other)` → ⚪ (white circle)

**Example:**

```zsh
icon=$(_flow_status_icon "active")
echo "Status: $icon active"  # Output: Status: 🟢 active

icon=$(_flow_status_icon "PAUSED")
echo "Status: $icon paused"  # Output: Status: 🟡 paused
```

**Notes:**
- Case-insensitive matching for common statuses
- Used in dashboards and project listings

---

### Project Utilities

#### `_flow_find_project_root`

Finds git repository root from current directory.

**Signature:**

```zsh
_flow_find_project_root [path]
```

**Parameters:**
- `$1` (optional) - Starting directory [default: `$PWD`]

**Returns:**
- 0 - Success, prints root path to stdout
- 1 - Not in git repository

**Example:**

```zsh
root=$(_flow_find_project_root)
if [[ $? -eq 0 ]]; then
    echo "Project root: $root"
else
    echo "Not in git repository"
fi

# Start from specific directory
root=$(_flow_find_project_root "/Users/dt/projects/flow-cli/lib")
```

**Notes:**
- Searches for `.STATUS` file (flow-cli project marker)
- Falls back to `.git/config` (standard git repo)
- Uses ZSH `:h` modifier (head/dirname equivalent)

---

#### `_flow_project_name`

Extract project name (directory name) from a path.

**Signature:**

```zsh
_flow_project_name [path]
```

**Parameters:**
- `$1` (optional) - Path to extract name from [default: `$PWD`]

**Returns:**
- Always returns 0

**Output:**
- Project name (last component of path)

**Example:**

```zsh
_flow_project_name "/Users/dt/projects/flow-cli"
# Output: flow-cli

_flow_project_name  # Uses current directory
# Output: (current directory name)
```

**Notes:**
- Uses ZSH `:t` modifier (tail/basename equivalent)
- Does not validate path exists

---

#### `_flow_in_project`

Check if current directory is inside a flow-cli project.

**Signature:**

```zsh
_flow_in_project
```

**Parameters:**
- None

**Returns:**
- 0 - Currently in a project directory
- 1 - Not in a project directory

**Example:**

```zsh
if _flow_in_project; then
    echo "You're in a project!"
else
    echo "Navigate to a project first"
fi
```

**Notes:**
- Wrapper around `_flow_find_project_root`
- Suppresses all output (check return code only)

---

#### `_flow_detect_project_type`

Detects project type from directory structure.

**Signature:**

```zsh
_flow_detect_project_type "/path/to/project"
```

**Parameters:**
- `$1` - Project directory path

**Returns:**
- 0 - Success, prints project type to stdout
- 1 - Unknown project type

**Supported Types:**
- `node` - Node.js (package.json)
- `r` - R package (DESCRIPTION with Package:)
- `python` - Python (pyproject.toml, setup.py)
- `quarto` - Quarto (_quarto.yml)
- `teaching` - Teaching course (course-config.yml)
- `mcp` - MCP server (mcp-server/ directory)

**Example:**

```zsh
type=$(_flow_detect_project_type "$PWD")
echo "Project type: $type"
# Output: Project type: node
```

---

### Time Utilities

#### `_flow_format_duration`

Convert seconds to human-readable duration string.

**Signature:**

```zsh
_flow_format_duration "seconds"
```

**Parameters:**
- `$1` (required) - Duration in seconds

**Returns:**
- Always returns 0

**Output:**
- Formatted duration string

**Format Examples:**
- `45` → `"45s"`
- `125` → `"2m"`
- `3725` → `"1h 2m"`
- `7200` → `"2h 0m"`

**Example:**

```zsh
elapsed=$(_flow_format_duration 3725)
echo "Session: $elapsed"  # Output: Session: 1h 2m
```

**Notes:**
- Seconds shown only for durations < 1 minute
- Minutes always shown for durations >= 1 minute
- Hours and minutes shown for durations >= 1 hour

---

#### `_flow_time_ago`

Convert Unix timestamp to relative time string.

**Signature:**

```zsh
_flow_time_ago "timestamp"
```

**Parameters:**
- `$1` (required) - Unix timestamp (seconds since epoch)

**Returns:**
- Always returns 0

**Output:**
- Relative time string

**Format Examples:**
- `(now - 30)` → `"just now"`
- `(now - 300)` → `"5m ago"`
- `(now - 7200)` → `"2h ago"`
- `(now - 172800)` → `"2d ago"`

**Example:**

```zsh
last_commit=$(git log -1 --format=%ct)
echo "Last commit: $(_flow_time_ago $last_commit)"
# Output: Last commit: 2h ago
```

**Notes:**
- Uses current time for comparison
- "just now" for anything < 60 seconds
- Does not handle future timestamps

---

### Input Helpers

#### `_flow_confirm`

Display yes/no confirmation prompt with sensible defaults.

**Signature:**

```zsh
_flow_confirm [prompt] [default]
```

**Parameters:**
- `$1` (optional) - Prompt message [default: `"Continue?"`]
- `$2` (optional) - Default answer: `"y"` or `"n"` [default: `"n"`]

**Returns:**
- 0 - User answered yes (or default was "y" in non-interactive mode)
- 1 - User answered no (or default was "n" in non-interactive mode)

**Example:**

```zsh
# Default "no" behavior
if _flow_confirm "Delete all files?"; then
    rm -rf ./build
fi

# Default "yes" behavior
if _flow_confirm "Continue with build?" "y"; then
    make build
fi
```

**Notes:**
- Non-interactive mode (no TTY) returns the default value
- Capitalizes the default option: `[Y/n]` or `[y/N]`
- Uses ZSH `read -q` for single-character response

---

### Array Utilities

#### `_flow_array_contains`

Check if a value exists in an array.

**Signature:**

```zsh
_flow_array_contains "needle" "haystack_element" [...]
```

**Parameters:**
- `$1` (required) - Value to search for (needle)
- `$@` (required) - Array elements to search through (haystack)

**Returns:**
- 0 - Value found in array
- 1 - Value not found

**Example:**

```zsh
local -a statuses=(active paused blocked)
if _flow_array_contains "active" "${statuses[@]}"; then
    echo "Found active status"
fi

# Inline usage
_flow_array_contains "$status" active paused blocked && echo "Valid"
```

**Notes:**
- Uses exact string matching
- Pass array with `${array[@]}` syntax

---

### File Utilities

#### `_flow_read_file`

Safely read file contents (no error if file doesn't exist).

**Signature:**

```zsh
_flow_read_file "path"
```

**Parameters:**
- `$1` (required) - Path to file

**Returns:**
- Always returns 0

**Output:**
- File contents, or empty if file doesn't exist

**Example:**

```zsh
# Read a config file, empty string if missing
local config=$(_flow_read_file "$HOME/.myconfig")

# Use in conditionals
if [[ -n "$(_flow_read_file "$path/.STATUS")" ]]; then
    echo "Project has status file"
fi
```

**Notes:**
- Silently handles missing files (no stderr output)
- Useful for optional configuration files

---

#### `_flow_get_config`

Read a value from a key=value format config file.

**Signature:**

```zsh
_flow_get_config "path" "key" [default]
```

**Parameters:**
- `$1` (required) - Path to config file
- `$2` (required) - Key to look up
- `$3` (optional) - Default value if key not found

**Returns:**
- Always returns 0

**Output:**
- Value for key, or default if not found

**File Format:**

```text
theme=dark
timeout=30
# Comments are ignored via grep pattern
```

**Example:**

```zsh
# Simple lookup with default
local theme=$(_flow_get_config ~/.myconfig "theme" "dark")

# Check if key exists
local value=$(_flow_get_config "$file" "api_key")
[[ -z "$value" ]] && echo "API key not configured"
```

**Notes:**
- Expects "key=value" format (no spaces around =)
- Returns default if file doesn't exist or key not found
- Uses command grep/cut to avoid alias interference

---

### Color Utilities

#### `_flow_color_red`

Outputs text in red.

**Signature:**

```zsh
_flow_color_red "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**

```zsh
echo "$(_flow_color_red 'Error occurred')"
```

---

#### `_flow_color_green`

Outputs text in green.

**Signature:**

```zsh
_flow_color_green "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**

```zsh
echo "$(_flow_color_green 'Success!')"
```

---

#### `_flow_color_yellow`

Outputs text in yellow.

**Signature:**

```zsh
_flow_color_yellow "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**

```zsh
echo "$(_flow_color_yellow 'Warning')"
```

---

#### `_flow_color_blue`

Outputs text in blue.

**Signature:**

```zsh
_flow_color_blue "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**

```zsh
echo "$(_flow_color_blue 'Info')"
```

---

### Secret Backend Configuration

#### `_dot_secret_backend`

Get the configured secret storage backend.

**Signature:**

```zsh
_dot_secret_backend
```

**Parameters:**
- None

**Returns:**
- Always returns 0

**Output:**
- Backend name: `"keychain"` (default), `"bitwarden"`, or `"both"`

**Environment:**
- `FLOW_SECRET_BACKEND` - Override default backend
  - `"keychain"` - macOS Keychain only (default, no unlock needed)
  - `"bitwarden"` - Bitwarden only (requires `dot unlock`)
  - `"both"` - Both backends (Keychain primary, Bitwarden sync)

**Example:**

```zsh
local backend=$(_dot_secret_backend)
case "$backend" in
  keychain)  echo "Using macOS Keychain only" ;;
  bitwarden) echo "Using Bitwarden only" ;;
  both)      echo "Using both backends" ;;
esac
```

**Notes:**
- Default is `"keychain"` for instant access without unlock
- `"bitwarden"` mode preserves legacy behavior
- `"both"` mode enables cloud backup with local performance

---

#### `_dot_secret_needs_bitwarden`

Check if current backend requires Bitwarden.

**Signature:**

```zsh
_dot_secret_needs_bitwarden
```

**Parameters:**
- None

**Returns:**
- 0 - Bitwarden is needed (backend is `"bitwarden"` or `"both"`)
- 1 - Bitwarden not needed (backend is `"keychain"`)

**Example:**

```zsh
if _dot_secret_needs_bitwarden; then
  # Ensure Bitwarden is available and unlocked
  _dot_require_tool "bw" "brew install bitwarden-cli"
fi
```

**Notes:**
- Use this to conditionally skip Bitwarden checks
- Returns success (0) for `"bitwarden"` and `"both"` modes

---

#### `_dot_secret_uses_keychain`

Check if current backend uses Keychain.

**Signature:**

```zsh
_dot_secret_uses_keychain
```

**Parameters:**
- None

**Returns:**
- 0 - Keychain is used (backend is `"keychain"` or `"both"`)
- 1 - Keychain not used (backend is `"bitwarden"`)

**Example:**

```zsh
if _dot_secret_uses_keychain; then
  _dot_kc_add "$name"
fi
```

**Notes:**
- Use this to conditionally use Keychain storage
- Returns success (0) for `"keychain"` and `"both"` modes

---

## Atlas Integration

**File:** `lib/atlas-bridge.zsh`
**Purpose:** Integration with Atlas state engine for enhanced session management
**Functions:** 23
**Status:** Optional dependency (graceful degradation without Atlas)

### Overview

The Atlas bridge provides seamless integration with `@data-wise/atlas` when available, with automatic fallback to local file-based operations when Atlas is not installed.

**Architecture:**

```text
Atlas Available?
    ├─ Yes → Use Atlas CLI commands
    └─ No → Use local file fallbacks (worklog, inbox.md, trail.log)
```

**Environment:**
- `FLOW_ATLAS_ENABLED` - "auto" (default), "yes", or "no"
- `FLOW_DATA_DIR` - Directory for local state files

---

### Timestamp Functions

#### `_flow_timestamp`

Get current timestamp in YYYY-MM-DD HH:MM:SS format.

**Signature:**

```zsh
_flow_timestamp
```

**Returns:** Timestamp string (e.g., "2026-01-22 14:30:45")

**Example:**

```zsh
ts=$(_flow_timestamp)
echo "Current time: $ts"
```

**Dependencies:** `zsh/datetime` module

---

#### `_flow_timestamp_short`

Get current timestamp in short YYYY-MM-DD HH:MM format.

**Signature:**

```zsh
_flow_timestamp_short
```

**Returns:** Short timestamp string (e.g., "2026-01-22 14:30")

**Notes:** Omits seconds for more compact display. Useful for log entries.

---

### Atlas Detection

#### `_flow_has_atlas`

Check if Atlas CLI is available (with session-level caching).

**Signature:**

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

**Notes:** Result cached in `$_FLOW_ATLAS_AVAILABLE` for session duration.

---

#### `_flow_refresh_atlas`

Force re-check of Atlas CLI availability (clears cache).

**Signature:**

```zsh
_flow_refresh_atlas
```

**Use Case:** After installing/uninstalling Atlas mid-session.

---

#### `_flow_init_atlas`

Initialize Atlas connection (respects `FLOW_ATLAS_ENABLED` setting).

**Signature:**

```zsh
_flow_init_atlas
```

**Notes:** If `FLOW_ATLAS_ENABLED="no"`, Atlas is disabled even if installed.

---

### Atlas CLI Wrappers

#### `_flow_atlas`

Main Atlas CLI wrapper for all atlas calls.

**Signature:**

```zsh
_flow_atlas <args...>
```

**Example:**

```zsh
_flow_atlas session start "my-project"
_flow_atlas project list --status=active
```

---

#### `_flow_atlas_silent`

Execute Atlas command silently (no output, return code only).

**Signature:**

```zsh
_flow_atlas_silent <args...>
```

**Notes:** Returns success (0) if Atlas not available (graceful degradation).

---

#### `_flow_atlas_json`

Execute Atlas command with JSON output format.

**Signature:**

```zsh
_flow_atlas_json <args...>
```

**Example:**

```zsh
project_data=$(_flow_atlas_json project get "my-project")
echo "$project_data" | jq '.status'
```

---

#### `_flow_atlas_async`

Execute Atlas command asynchronously (fire-and-forget).

**Signature:**

```zsh
_flow_atlas_async <args...>
```

**Use Case:** Non-critical operations like analytics or background sync.

---

### Project Operations

#### `_flow_get_project`

Get project information by name.

**Signature:**

```zsh
_flow_get_project <name>
```

**Output:** Shell-evaluable variables: `name`, `project_path`, `proj_status`

**Example:**

```zsh
if info=$(_flow_get_project "my-project"); then
    eval "$info"
    cd "$project_path"
fi
```

---

#### `_flow_list_projects`

List all projects (uses Atlas if available, otherwise filesystem scan).

**Signature:**

```zsh
_flow_list_projects [status_filter]
```

**Parameters:**
- `$1` - (optional) Status filter (e.g., "active", "archived")

**Output:** Project names, one per line

---


#### `_flow_get_project_fallback`

Find project by name in filesystem (fallback when Atlas unavailable).

**Signature:**

```zsh
_flow_get_project_fallback <name>
```

**Parameters:**
- `$1` - (required) Project name to look up

**Returns:**
- `0` - Project found
- `1` - Project not found

**Output:** Shell-evaluable variables:

```text
name="project-name"
project_path="/path/to/project"
proj_status="active"
```

**Example:**

```zsh
if info=$(_flow_get_project_fallback "flow-cli"); then
    eval "$info"
    echo "Found at: $project_path"
fi
```

**Notes:**
- Searches exact match first in `FLOW_PROJECTS_ROOT`, then common subdirectories
- Search order: root, dev-tools, r-packages/*, research, teaching, quarto
- Uses `project_path` and `proj_status` to avoid ZSH reserved names

---

#### `_flow_list_projects_fallback`

List projects by scanning filesystem for .STATUS files.

**Signature:**

```zsh
_flow_list_projects_fallback [status_filter]
```

**Parameters:**
- `$1` - (optional) Status filter (currently ignored in fallback mode)

**Returns:** Always `0`

**Output:** Project names, one per line

**Example:**

```zsh
projects=$(_flow_list_projects_fallback)
echo "Found $(echo "$projects" | wc -l) projects"
```

**Notes:**
- Scans recursively for `.STATUS` files in `FLOW_PROJECTS_ROOT`
- Uses ZSH glob qualifiers: `(N)` for nullglob
- Uses ZSH modifiers: `:h` = dirname, `:t` = basename
- Filter parameter ignored (would require parsing `.STATUS` content)

---

### Session Operations

#### `_flow_session_start`

Start a work session for a project.

**Signature:**

```zsh
_flow_session_start <project>
```

**Side Effects:**
- Creates session state file
- Exports `FLOW_CURRENT_PROJECT` and `FLOW_SESSION_START`
- Logs to worklog (fallback mode)

---

#### `_flow_session_end`

End the current work session.

**Signature:**

```zsh
_flow_session_end [note]
```

**Parameters:**
- `$1` - (optional) Note to record with session end

**Output:** Displays session duration (Xh Ym or Xm format)

---

#### `_flow_session_current`

Get information about the current active session.

**Signature:**

```zsh
_flow_session_current
```

**Output:** Shell-evaluable variables: `project`, `elapsed_mins`

**Returns:** `1` if no active session

---

#### `_flow_today_session_time`

Calculate total session time for today.

**Signature:**

```zsh
_flow_today_session_time
```

**Output:** Total minutes worked today (integer)

---

### Capture Operations

#### `_flow_catch`

Quick capture of a thought/task to inbox.

**Signature:**

```zsh
_flow_catch <text> [project]
```

**Example:**

```zsh
_flow_catch "Fix the login bug"
_flow_catch "Update docs" "my-project"
```

---

#### `_flow_inbox`

Display the capture inbox contents.

**Signature:**

```zsh
_flow_inbox
```

---

#### `_flow_where`

Get current project context ("where was I?").

**Signature:**

```zsh
_flow_where [project]
```

---


#### `_flow_where_fallback`

Get project context from filesystem (fallback for `_flow_where`).

**Signature:**

```zsh
_flow_where_fallback [project]
```

**Parameters:**
- `$1` - (optional) Project name to get context for

**Returns:**
- `0` - Context found
- `1` - No project context available

**Output:** Project info with status and focus from `.STATUS` file

**Example:**

```zsh
# Auto-detect from current directory
_flow_where_fallback

# Get context for specific project
_flow_where_fallback "flow-cli"
```

**Notes:**
- Detects project from current directory if not specified
- Parses `.STATUS` file for `Status:` and `Focus:` lines
- Shows 📁 emoji for visual project identification
- Falls back to current directory or searches in `FLOW_PROJECTS_ROOT`

---

#### `_flow_crumb`

Leave a breadcrumb (context marker for future reference).

**Signature:**

```zsh
_flow_crumb <text> [project]
```

**Use Case:** Helps resume work after interruptions (ADHD-friendly).

---

#### `at`

Shortcut alias for Atlas CLI (or fallback commands).

**Signature:**

```zsh
at <command> [args...]
```

**Parameters:**
- `$@` - Command and arguments to pass to Atlas or fallback handlers

**Returns:**
- `0` - Command succeeded
- `1` - Atlas not available and command not supported

**Subcommands (Atlas mode):**
Passes through to Atlas CLI when available. See Atlas documentation for all commands.

**Subcommands (fallback mode - when Atlas unavailable):**

| Subcommand | Arguments | Purpose |
|------------|-----------|---------|
| `catch` or `c` | `<text> [project]` | Quick capture of thought/task |
| `inbox` or `i` | (none) | Show captured items |
| `where` or `w` | `[project]` | Get current project context |
| `crumb` or `b` | `<text> [project]` | Leave breadcrumb marker |

**Examples:**

```zsh
# With Atlas installed (full functionality)
at session start my-project
at project list --status=active

# Without Atlas (fallback commands work)
at catch "Fix login bug"
at inbox
at where flow-cli
at crumb "Debugging auth flow"
```

**Notes:**
- Passes through to `atlas` CLI if available
- Provides essential fallback commands without Atlas
- 'at' chosen for easy typing (2 characters)
- Shows helpful error message if Atlas not available and unknown command used

---

## Project Detection

**File:** `lib/project-detector.zsh`
**Purpose:** Automatic project type detection from directory structure
**Functions:** 4

### Overview

Detects project type based on marker files and directories present. Used by dashboard, project picker, and context-aware commands.

**Supported Types:**

| Type | Markers |
|------|---------|
| r-package | DESCRIPTION + NAMESPACE |
| python | pyproject.toml, setup.py |
| node | package.json |
| rust | Cargo.toml |
| go | go.mod |
| quarto | _quarto.yml |
| obsidian | .obsidian/ |
| teaching | syllabus.qmd, lectures/, .flow/teach-config.yml |
| research | manuscript.qmd, paper.qmd |
| generic | (default fallback) |

---

### Functions

#### `_flow_detect_project_type`

Detect project type based on marker files and directories.

**Signature:**

```zsh
_flow_detect_project_type [directory]
```

**Parameters:**
- `$1` - (optional) Directory to check [default: $PWD]

**Returns:**
- `0` - Project type detected
- `1` - Error (invalid teaching config)

**Output:** Project type string

**Example:**

```zsh
type=$(_flow_detect_project_type)
type=$(_flow_detect_project_type "/path/to/project")
```

---

#### `_flow_project_commands`

Get suggested commands relevant to a project type.

**Signature:**

```zsh
_flow_project_commands [project_type]
```

**Output:** Space-separated list of relevant commands/tools

**Example:**

```zsh
_flow_project_commands "r-package"
# Output: devtools::check() devtools::test() devtools::document() devtools::build()

_flow_project_commands "python"
# Output: pytest uv pip ruff
```

---

#### `_flow_project_icon`

Get emoji icon representing a project type.

**Signature:**

```zsh
_flow_project_icon [project_type]
```

**Output:** Single emoji character

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

**Signature:**

```zsh
_flow_validate_teaching_config <config_path>
```

**Returns:**
- `0` - Configuration is valid (or yq not available)
- `1` - Configuration is invalid

**Required Fields:** `course.name`, `branches.draft`, `branches.production`

---

## Terminal UI

**File:** `lib/tui.zsh`
**Purpose:** Terminal UI components for consistent visual output
**Functions:** 15

### Overview

Provides progress bars, sparklines, tables, pickers, and spinners for ADHD-friendly visual feedback.

---

### Progress & Visualization

#### `_flow_progress_bar`

Draw an ASCII progress bar with percentage.

**Signature:**

```zsh
_flow_progress_bar <current> <total> [width] [filled_char] [empty_char]
```

**Parameters:**
- `$1` - Current value
- `$2` - Total/maximum value
- `$3` - Bar width [default: 20]
- `$4` - Filled character [default: █]
- `$5` - Empty character [default: ░]

**Example:**

```zsh
echo "Progress: $(_flow_progress_bar 7 10)"
# Output: ██████████████░░░░░░ 70%

_flow_progress_bar 50 100 30 "=" "-"
# Output: ===============--------------- 50%
```

---

#### `_flow_sparkline`

Generate a sparkline graph from numeric values.

**Signature:**

```zsh
_flow_sparkline <values...>
```

**Character Set:** ▁▂▃▄▅▆▇█ (8 levels)

**Example:**

```zsh
_flow_sparkline 1 3 5 7 5 3 1
# Output: ▁▃▅▇▅▃▁
```

---

### Tables & Boxes

#### `_flow_table`

Display formatted table with headers and rows.

**Signature:**

```zsh
_flow_table <headers> <rows...>
```

**Parameters:**
- `$1` - Comma-separated header columns
- `$@` - Comma-separated row data

**Example:**

```zsh
_flow_table "Name,Status,Time" \
    "flow-cli,active,2h" \
    "project-b,paused,1d"
```

---

#### `_flow_box`

Draw a Unicode box around text content.

**Signature:**

```zsh
_flow_box [title] <content> [width]
```

**Example:**

```zsh
_flow_box "Project Info" "Name: flow-cli
Status: active
Time: 2h 30m"
```

**Output:**

```text
╭─ Project Info ────────────────────────────────╮
│ Name: flow-cli                                │
│ Status: active                                │
│ Time: 2h 30m                                  │
╰──────────────────────────────────────────────╯
```

---

### Interactive Pickers

#### `_flow_has_fzf`

Check if fzf (fuzzy finder) is available.

**Signature:**

```zsh
_flow_has_fzf
```

---

#### `_flow_pick_project`

Interactive project picker using fzf with preview.

**Signature:**

```zsh
_flow_pick_project
```

**Output:** Selected project name

**Dependencies:** fzf

---

#### `_flow_has_gum`

Check if gum (glamorous shell tool) is available.

**Signature:**

```zsh
_flow_has_gum
```

---

#### `_flow_input`

Styled text input prompt (uses gum if available).

**Signature:**

```zsh
_flow_input [prompt] [placeholder]
```

**Example:**

```zsh
local name=$(_flow_input "Project name" "my-project")
```

---

#### `_flow_confirm_styled`

Styled yes/no confirmation (uses gum if available).

**Signature:**

```zsh
_flow_confirm_styled [prompt]
```

**Example:**

```zsh
if _flow_confirm_styled "Delete these files?"; then
    rm -rf ./cache
fi
```

---

#### `_flow_choose`

Multi-option selector (uses gum/fzf if available).

**Signature:**

```zsh
_flow_choose <header> <options...>
```

**Example:**

```zsh
local status=$(_flow_choose "Set status:" "active" "paused" "blocked")
```

---

### Spinner

#### `_flow_spinner_start`

Start an animated spinner with message.

**Signature:**

```zsh
_flow_spinner_start [message] [estimate]
```

**Animation:** Uses Braille dots: ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏

**Example:**

```zsh
_flow_spinner_start "Building project..." "~10s"
# ... long operation ...
_flow_spinner_stop "Build complete"
```

---

#### `_flow_spinner_stop`

Stop the running spinner and show completion message.

**Signature:**

```zsh
_flow_spinner_stop [message]
```

---

#### `_flow_with_spinner`

Execute a command while showing a spinner.

**Signature:**

```zsh
_flow_with_spinner <message> <estimate> <command...>
```

**Example:**

```zsh
if _flow_with_spinner "Testing..." "~30s" npm test; then
    echo "Tests passed!"
fi
```

---

## Tool Inventory

**File:** `lib/inventory.zsh`
**Purpose:** Auto-generate project inventory from .STATUS files
**Functions:** 2

### Overview

Generates project inventory from `.STATUS` files in dev-tools directory for the `dash --inventory` command.

---

### Functions

#### `_flow_generate_inventory`

Generate project inventory from .STATUS files.

**Signature:**

```zsh
_flow_generate_inventory [format]
```

**Parameters:**
- `$1` - Output format: "table" (default), "json", or "markdown"

**Output:** Formatted inventory with:
- Project name
- Status (🟢 active, ✅ stable, ⏸️ paused, 📦 archived)
- Type
- Progress percentage
- Next action
- Summary counts

**Example:**

```zsh
_flow_generate_inventory              # Table format
_flow_generate_inventory json         # JSON format
_flow_generate_inventory > inventory.md
```

---

#### `_flow_generate_inventory_json`

Generate project inventory in JSON format.

**Signature:**

```zsh
_flow_generate_inventory_json
```

**Output:** JSON object with structure:

```json
{
  "generated": "ISO-8601 timestamp",
  "source": "~/projects/dev-tools/",
  "projects": [
    { "name", "path", "status", "type", "progress", "next" }
  ]
}
```

---

## Config Validation

**File:** `lib/config-validator.zsh`
**Purpose:** Teaching config validation with hash-based change detection
**Functions:** 8

### Overview

Schema-based validation for `teach-config.yml` with SHA-256 hash-based change detection. Gracefully falls back when yq is unavailable.

**Ownership Protocol:**

| Section | Owner |
|---------|-------|
| course, semester_info, branches, deployment, automation | flow-cli |
| scholar | Scholar plugin (read-only for flow-cli) |
| examark, shortcuts | Shared |

---

### Hash-Based Change Detection

#### `_flow_config_hash`

Compute SHA-256 hash of a configuration file.

**Signature:**

```zsh
_flow_config_hash [config_path]
```

**Parameters:**
- `$1` - Path to config file [default: .flow/teach-config.yml]

**Returns:**
- `0` - Success, hash computed
- `1` - File does not exist

**Output:** SHA-256 hash string (64 hex chars)

**Notes:** Uses `shasum` on macOS, `sha256sum` on Linux. Falls back to mtime.

---

#### `_flow_config_changed`

Check if config file has changed since last read.

**Signature:**

```zsh
_flow_config_changed [config_path]
```

**Returns:**
- `0` - Config has changed
- `1` - Config is unchanged

**Example:**

```zsh
if _flow_config_changed; then
    echo "Config changed, reloading..."
fi
```

---

#### `_flow_config_invalidate`

Force invalidation of the config hash cache.

**Signature:**

```zsh
_flow_config_invalidate
```

**Use Case:** After config updates or when forcing reload.

---

### Config Validation

#### `_teach_validate_config`

Validate teach-config.yml against schema requirements.

**Signature:**

```zsh
_teach_validate_config [config_path] [--quiet]
```

**Validates:**
- `course.name` (required)
- `semester` enum (Spring, Summer, Fall, Winter)
- `year` range (2020-2100)
- Date formats (YYYY-MM-DD)
- Weeks array structure
- Holidays array with type enum
- Deadlines (due_date XOR week+offset_days)
- Exams array
- Scholar enums (level, difficulty, tone)
- Grading percentages sum (~100%)

**Returns:**
- `0` - Config is valid (or yq unavailable)
- `1` - Config is invalid

---

#### `_teach_config_get`

Get a configuration value with optional default.

**Signature:**

```zsh
_teach_config_get <key> [default] [config_path]
```

**Parameters:**
- `$1` - Dot-notation key path (e.g., "course.name")
- `$2` - Default value if not found
- `$3` - Path to config file

**Example:**

```zsh
course_name=$(_teach_config_get "course.name" "Unknown Course")
level=$(_teach_config_get "scholar.course_info.level" "undergraduate")
```

---

#### `_teach_has_scholar_config`

Check if the scholar section exists and is configured.

**Signature:**

```zsh
_teach_has_scholar_config [config_path]
```

**Returns:**
- `0` - Scholar section exists and has content
- `1` - Scholar section missing or empty

---

#### `_teach_find_config`

Find teach-config.yml by searching up the directory tree.

**Signature:**

```zsh
_teach_find_config
```

**Output:** Full path to teach-config.yml if found

**Use Case:** Commands run from subdirectories of a project.

---

#### `_teach_config_summary`

Display a formatted summary of teaching project configuration.

**Signature:**

```zsh
_teach_config_summary [config_path]
```

**Output:** Formatted multi-line summary with:
- Course name
- Semester and year
- Course level
- Scholar integration status
- Config validation status

---

## Keychain Helpers

**File:** `lib/keychain-helpers.zsh`
**Purpose:** macOS Keychain integration for instant, session-free secret access
**Functions:** 7
**Platform:** macOS only
**Service:** flow-cli-secrets

### Overview

The keychain helpers library provides macOS Keychain integration for secure secret management:

**Features:**
- **Instant access** - No unlock needed (uses system Keychain)
- **Touch ID / Apple Watch support** - Biometric authentication
- **Auto-locks** - Locks with screen lock
- **Works offline** - No cloud dependency
- **Secure storage** - Encrypted at rest in macOS Keychain

**Service Name:** `flow-cli-secrets` (used to namespace secrets in Keychain)

**Workflow:**

```text
Add secret → Store in Keychain → Retrieve with Touch ID →
Use in scripts → Delete when done
```

**Migration:** Import from Bitwarden one-time, then use Keychain directly

---

### Secret Management

#### `_dot_kc_add`

Add or update a secret in macOS Keychain with interactive prompt.

**Signature:**

```zsh
_dot_kc_add <name>
```

**Parameters:**
- `$1` - Name of the secret (e.g., "github-token", "api-key")

**Returns:**
- 0 - Secret successfully stored
- 1 - Error (missing name, empty value, or Keychain failure)

**Example:**

```zsh
_dot_kc_add "github-token"     # Prompts for value, stores in Keychain
_dot_kc_add "openai-api-key"   # Updates if already exists
```

**Notes:**
- Uses hidden input (`read -s`) for secure value entry
- Automatically updates existing secrets (`security -U` flag)
- Stores under service name "flow-cli-secrets" for namespacing
- Touch ID / Apple Watch authentication may be required on retrieval

---

#### `_dot_kc_get`

Retrieve a secret value from macOS Keychain.

**Signature:**

```zsh
_dot_kc_get <name>
```

**Parameters:**
- `$1` - Name of the secret to retrieve

**Returns:**
- 0 - Secret found and output
- 1 - Error (missing name or secret not found)

**Output:**
- stdout - Raw secret value (no formatting, suitable for piping/capture)

**Example:**

```zsh
_dot_kc_get "github-token"                    # Outputs: ghp_xxxx...
export GITHUB_TOKEN=$(_dot_kc_get "github")   # Capture into variable
gh auth login --with-token <<< $(_dot_kc_get "github-token")
```

**Notes:**
- Output is raw value only (no decoration) for script compatibility
- May trigger Touch ID / Apple Watch / password prompt
- Searches only within "flow-cli-secrets" service namespace

---

#### `_dot_kc_list`

List all flow-cli secrets stored in macOS Keychain.

**Signature:**

```zsh
_dot_kc_list
```

**Parameters:**
- None

**Returns:**
- 0 - Always (even if no secrets found)

**Output:**
- stdout - Formatted list of secret names with bullet points

**Example:**

```zsh
_dot_kc_list
# Output:
# Secrets in Keychain (flow-cli):
#   • github-token
#   • openai-api-key
#   • anthropic-key
```

**Notes:**
- Uses `security dump-keychain` to scan all entries
- Filters to only show secrets with "flow-cli-secrets" service
- Creates temp file for parsing (cleaned up automatically)
- Shows unique secrets only (deduplicates)
- Does NOT show secret values, only names

---

#### `_dot_kc_delete`

Remove a secret from macOS Keychain.

**Signature:**

```zsh
_dot_kc_delete <name>
```

**Parameters:**
- `$1` - Name of the secret to delete

**Returns:**
- 0 - Secret successfully deleted
- 1 - Error (missing name or secret not found)

**Example:**

```zsh
_dot_kc_delete "old-api-key"    # Removes secret from Keychain
_dot_kc_delete "nonexistent"    # Returns error, secret not found
```

**Notes:**
- Permanent deletion - cannot be undone
- Only deletes secrets within "flow-cli-secrets" service namespace
- May require authentication depending on Keychain settings

---

#### `_dot_kc_import`

Bulk import secrets from Bitwarden folder into macOS Keychain.

**Signature:**

```zsh
_dot_kc_import
```

**Parameters:**
- None

**Returns:**
- 0 - Import completed (or cancelled by user)
- 1 - Error (Bitwarden CLI missing, not logged in, or folder not found)

**Output:**
- stdout - Progress messages showing each imported secret

**Example:**

```zsh
_dot_kc_import
# Output:
# Import secrets from Bitwarden folder 'flow-cli-secrets'?
# Continue? [y/N] y
# ✓ Imported: github-token
# ✓ Imported: openai-api-key
# ✓ Imported 2 secret(s) to Keychain
```

**Dependencies:**
- Bitwarden CLI (`bw`) installed and unlocked
- Folder named "flow-cli-secrets" in Bitwarden

**Notes:**
- Uses item name as secret name, password field as value
- Falls back to notes field if password is empty
- Updates existing secrets (does not duplicate)
- One-time migration - after import, use Keychain directly

---

#### `_dot_kc_help`

Display help documentation for keychain secret commands.

**Signature:**

```zsh
_dot_kc_help
```

**Parameters:**
- None

**Returns:**
- 0 - Always

**Output:**
- stdout - Formatted help text with commands, examples, and benefits

**Example:**

```zsh
_dot_kc_help
dot secret help
dot secret --help
```

**Help Output:**

```text
dot secret - macOS Keychain secret management

Commands:
  dot secret add <name>      Store a secret
  dot secret get <name>      Retrieve a secret
  dot secret <name>          Shortcut for 'get'
  dot secret list            List all secrets
  dot secret delete <name>   Remove a secret
  dot secret import          Import from Bitwarden

Benefits:
  • Instant access (no unlock needed)
  • Touch ID / Apple Watch support
  • Auto-locks with screen lock
  • Works offline
```

---

#### `_dot_secret_kc`

Main router/dispatcher for all dot secret subcommands.

**Signature:**

```zsh
_dot_secret_kc [subcommand] [args...]
```

**Parameters:**
- `$1` - (optional) Subcommand: add|get|list|delete|import|help
- `$@` - Additional arguments passed to subcommand handler

**Subcommands:**
- `add|new` → `_dot_kc_add`
- `get` → `_dot_kc_get`
- `list|ls` → `_dot_kc_list`
- `delete|rm|remove` → `_dot_kc_delete`
- `import` → `_dot_kc_import`
- `help|--help|-h` → `_dot_kc_help`
- `<name>` → `_dot_kc_get` (implicit get)
- (empty) → `_dot_kc_help`

**Returns:**
- Return value from delegated subcommand function

**Example:**

```zsh
_dot_secret_kc add "api-key"      # Calls _dot_kc_add
_dot_secret_kc get "api-key"      # Calls _dot_kc_get
_dot_secret_kc "api-key"          # Shortcut: calls _dot_kc_get
_dot_secret_kc list               # Calls _dot_kc_list
_dot_secret_kc                    # Shows help
```

**Notes:**
- Replaces Bitwarden-based `_dot_secret` for local-first Keychain ops
- Supports aliases: new→add, ls→list, rm/remove→delete
- Unknown subcommands treated as secret names (implicit get)
- Empty input shows help

---

## Git Helpers

**File:** `lib/git-helpers.zsh`
**Purpose:** Git integration functions for teaching workflow
**Functions:** 17
**Version:** v5.11.0+ (Teaching + Git Integration)

### Overview

The git helpers library provides git integration utilities for teaching workflows, including:

**Phase 1 (v5.11.0) - Smart Post-Generation:**
- Standardized commit messages with Scholar attribution
- Teaching file detection and filtering
- Interactive commit workflow stubs
- Branch status checking and remote operations
- PR creation for deployment

**Phase 2 (v5.11.0+) - Branch-Aware Deployment:**
- Production conflict detection
- Commit counting and listing
- PR body generation
- Automated rebasing

**Workflow:**

```text
Generate content → Detect teaching files → Commit with metadata →
Create deploy PR → Check conflicts → Rebase if needed → Deploy
```

---

### Phase 1: Smart Post-Generation Workflow

#### `_git_teaching_commit_message`

Generate standardized commit message for teaching content.

**Signature:**

```zsh
_git_teaching_commit_message <type> <topic> <command> <course> <semester> <year>
```

**Parameters:**
- `$1` - Content type (exam, quiz, slides, lecture, etc.)
- `$2` - Topic or title of the content
- `$3` - Full command that generated the content
- `$4` - Course name (e.g., "STAT 545")
- `$5` - Semester (Fall, Spring, etc.)
- `$6` - Year

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Formatted commit message with conventional commit style

**Example:**

```zsh
msg=$(_git_teaching_commit_message "exam" "Hypothesis Testing" \
    'teach exam "Hypothesis Testing" --questions 20' \
    "STAT 545" "Fall" "2024")

# Output:
# teach: add exam for Hypothesis Testing
#
# Generated via: teach exam "Hypothesis Testing" --questions 20
# Course: STAT 545 (Fall 2024)
#
# Co-Authored-By: Scholar <scholar@example.com>
```

**Notes:**
- Uses conventional commits style (teach: prefix)
- Includes Scholar co-author attribution
- Designed for automated git workflows

---

#### `_git_is_clean`

Check if working directory has no uncommitted changes.

**Signature:**

```zsh
_git_is_clean
```

**Parameters:**
- None

**Returns:**
- 0 - Working directory is clean
- 1 - Working directory is dirty (has uncommitted changes)

**Example:**

```zsh
if _git_is_clean; then
    echo "Ready to switch branches"
else
    echo "Commit or stash changes first"
fi
```

**Notes:**
- Uses `git status --porcelain` for scriptable output
- Includes untracked files in "dirty" check
- Returns 1 if not in a git repository

---

#### `_git_is_synced`

Check if local branch is synchronized with remote.

**Signature:**

```zsh
_git_is_synced
```

**Parameters:**
- None

**Returns:**
- 0 - Branch is synced (no unpushed or unpulled commits)
- 1 - Branch is out of sync (ahead, behind, or diverged)

**Example:**

```zsh
if _git_is_synced; then
    echo "Branch is up to date"
else
    echo "Need to push or pull"
fi
```

**Notes:**
- Fetches from remote first (may take a moment)
- Returns 1 if no upstream branch configured
- Checks both ahead (local commits) and behind (remote commits)

---

#### `_git_teaching_files`

Get list of uncommitted teaching-related files.

**Signature:**

```zsh
_git_teaching_files
```

**Parameters:**
- None

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - File paths (one per line), sorted and deduplicated

**Recognized Paths:**
- `exams/` - Exam files
- `slides/` - Presentation slides
- `assignments/` - Assignment materials
- `lectures/` - Lecture notes
- `quizzes/` - Quiz files
- `homework/` - Homework assignments
- `labs/` - Lab materials

**Example:**

```zsh
local files=$(_git_teaching_files)
if [[ -n "$files" ]]; then
    echo "Teaching files to commit:"
    echo "$files"
fi
```

**Notes:**
- Includes both staged and unstaged changes
- Includes untracked files in teaching directories
- Returns empty if no teaching files changed

---

#### `_git_interactive_commit`

Interactive commit workflow for teaching content (stub).

**Signature:**

```zsh
_git_interactive_commit <file> <type> <topic> <command> <course> <semester> <year>
```

**Parameters:**
- `$1` - File path
- `$2` - Content type
- `$3` - Topic
- `$4` - Command that generated content
- `$5` - Course name
- `$6` - Semester
- `$7` - Year

**Returns:**
- 0 - Setup complete
- 1 - Error (e.g., missing dependencies)

**Notes:**
- This is a stub function for Phase 1
- Actual interactive prompting handled by teach dispatcher
- Sources core.zsh for logging helpers

---

#### `_git_create_deploy_pr`

Create a pull request for teaching content deployment.

**Signature:**

```zsh
_git_create_deploy_pr <draft_branch> <prod_branch> <title> <body>
```

**Parameters:**
- `$1` - Source branch (draft/development)
- `$2` - Target branch (production)
- `$3` - PR title
- `$4` - PR body (markdown)

**Returns:**
- 0 - PR created successfully
- 1 - Error (gh not installed, not authenticated, or creation failed)

**Dependencies:**
- gh CLI (GitHub CLI)
- gh auth login (authenticated)

**Example:**

```zsh
_git_create_deploy_pr "draft" "main" \
    "Deploy: Week 5 materials" \
    "$(cat pr-body.md)"
```

**Notes:**
- Adds labels: teaching, deploy
- Requires authenticated GitHub CLI
- Sources core.zsh for error logging

---

#### `_git_in_repo`

Check if current directory is inside a git repository.

**Signature:**

```zsh
_git_in_repo
```

**Parameters:**
- None

**Returns:**
- 0 - In a git repository
- 1 - Not in a git repository

**Example:**

```zsh
if _git_in_repo; then
    echo "Branch: $(_git_current_branch)"
else
    echo "Not a git repository"
fi
```

**Notes:**
- Works from any subdirectory of the repo
- Suppresses all error output

---

#### `_git_current_branch`

Get the name of the current git branch.

**Signature:**

```zsh
_git_current_branch
```

**Parameters:**
- None

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Branch name, or empty if not in git repo

**Example:**

```zsh
local branch=$(_git_current_branch)
echo "Currently on: $branch"
```

**Special Cases:**
- Detached HEAD returns "HEAD"
- Not in repo returns empty string

---

#### `_git_remote_branch`

Get the upstream tracking branch name.

**Signature:**

```zsh
_git_remote_branch
```

**Parameters:**
- None

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Remote branch name (e.g., "origin/main"), or empty if none

**Example:**

```zsh
local upstream=$(_git_remote_branch)
if [[ -n "$upstream" ]]; then
    echo "Tracking: $upstream"
else
    echo "No upstream configured"
fi
```

**Notes:**
- Returns empty if no upstream branch configured
- Format: remote/branch (e.g., "origin/main")

---

#### `_git_commit_teaching_content`

Commit staged files with a teaching-formatted message.

**Signature:**

```zsh
_git_commit_teaching_content <message>
```

**Parameters:**
- `$1` - Commit message (usually from `_git_teaching_commit_message`)

**Returns:**
- 0 - Commit successful
- 1 - Error (no staged changes or commit failed)

**Example:**

```zsh
git add exams/midterm.qmd
local msg=$(_git_teaching_commit_message "exam" "Midterm" ...)
_git_commit_teaching_content "$msg"
```

**Notes:**
- Requires files to be staged first (git add)
- Uses _flow_log functions for status output
- Fails gracefully if nothing staged

---

#### `_git_push_current_branch`

Push current branch to origin remote.

**Signature:**

```zsh
_git_push_current_branch
```

**Parameters:**
- None

**Returns:**
- 0 - Push successful
- 1 - Error (not on branch or push failed)

**Example:**

```zsh
if _git_push_current_branch; then
    echo "Changes pushed"
fi
```

**Notes:**
- Always pushes to 'origin' remote
- Requires branch to exist on remote (use -u for first push)
- Shows git push output for progress

---

### Phase 2: Branch-Aware Deployment

#### `_git_detect_production_conflicts`

Check if production branch has commits that could cause conflicts.

**Signature:**

```zsh
_git_detect_production_conflicts <draft_branch> <prod_branch>
```

**Parameters:**
- `$1` - Draft/development branch name
- `$2` - Production branch name

**Returns:**
- 0 - No conflicts (production hasn't diverged)
- 1 - Potential conflicts (production has new commits)

**Example:**

```zsh
if ! _git_detect_production_conflicts "draft" "main"; then
    echo "Warning: Production has new commits"
    echo "Consider rebasing before PR"
fi
```

**Notes:**
- Fetches from remote before checking
- Uses merge-base to find common ancestor
- Returns 1 if production has commits since divergence

---

#### `_git_get_commit_count`

Count commits in draft branch not yet in production.

**Signature:**

```zsh
_git_get_commit_count <draft_branch> <prod_branch>
```

**Parameters:**
- `$1` - Draft/development branch name
- `$2` - Production branch name

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Number of commits (integer)

**Example:**

```zsh
local count=$(_git_get_commit_count "draft" "main")
echo "Ready to deploy $count commits"
```

**Notes:**
- Compares against remote production branch
- Returns 0 if branches are identical or error

---

#### `_git_get_commit_list`

Get markdown-formatted list of commits for PR body.

**Signature:**

```zsh
_git_get_commit_list <draft_branch> <prod_branch>
```

**Parameters:**
- `$1` - Draft/development branch name
- `$2` - Production branch name

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Commit subjects as markdown list, one per line

**Example:**

```zsh
local commits=$(_git_get_commit_list "draft" "main")
# Output:
# - teach: add exam for Hypothesis Testing
# - teach: add lecture slides for Week 5
# - fix: correct typo in assignment
```

**Notes:**
- Excludes merge commits
- Format: "- subject" (markdown list item)
- Empty output if no commits or error

---

#### `_git_generate_pr_body`

Generate complete markdown PR body for deployment.

**Signature:**

```zsh
_git_generate_pr_body <draft_branch> <prod_branch>
```

**Parameters:**
- `$1` - Draft/development branch name
- `$2` - Production branch name

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Complete markdown PR body with:
  - Changes section (commit list)
  - Commits section (count and branch info)
  - Deploy checklist
  - Attribution footer

**Example:**

```zsh
local body=$(_git_generate_pr_body "draft" "main")
gh pr create --body "$body" ...
```

**Notes:**
- Uses `_git_get_commit_count` and `_git_get_commit_list`
- Includes standard deploy checklist items
- Attribution shows teach deploy command

---

#### `_git_rebase_onto_production`

Rebase draft branch onto latest production.

**Signature:**

```zsh
_git_rebase_onto_production <draft_branch> <prod_branch>
```

**Parameters:**
- `$1` - Draft/development branch name
- `$2` - Production branch name

**Returns:**
- 0 - Rebase successful
- 1 - Error (fetch failed or conflicts)

**Example:**

```zsh
if _git_rebase_onto_production "draft" "main"; then
    echo "Ready for clean merge"
else
    echo "Resolve conflicts manually"
fi
```

**Notes:**
- Fetches latest production before rebase
- Provides helpful error messages on conflict
- User must resolve conflicts manually if they occur

---

#### `_git_has_unpushed_commits`

Check if current branch has local commits not pushed to remote.

**Signature:**

```zsh
_git_has_unpushed_commits
```

**Parameters:**
- None

**Returns:**
- 0 - Has unpushed commits
- 1 - All commits pushed (or no upstream)

**Example:**

```zsh
if _git_has_unpushed_commits; then
    echo "You have local commits to push"
fi
```

**Notes:**
- Requires upstream branch configured
- Returns 1 if no upstream (acts as "nothing to push")
- Does not fetch first (uses cached remote state)

---

## Doctor Cache

**File:** `lib/doctor-cache.zsh`
**Purpose:** Smart caching for token validation results
**Functions:** 13
**Version:** v5.17.0+

### Overview

The doctor cache system provides high-performance caching for token validation results with:

- **5-minute TTL** - Prevents excessive API calls
- **Concurrent safety** - flock-based locking
- **Performance** - < 10ms cache checks, 80% API reduction
- **Automatic cleanup** - Removes entries > 1 day old

**Cache Directory:**

```text
~/.flow/cache/doctor/
├── token-github.cache
├── token-npm.cache
└── token-pypi.cache
```

**Cache Format (JSON):**

```json
{
  "token_name": "github-token",
  "provider": "github",
  "cached_at": "2026-01-23T12:30:00Z",
  "expires_at": "2026-01-23T12:35:00Z",
  "ttl_seconds": 300,
  "status": "valid",
  "days_remaining": 45,
  "username": "your-username"
}
```

### Core Functions

#### `_doctor_cache_init`

Initialize cache directory structure.

**Signature:**

```zsh
_doctor_cache_init
```

**Parameters:**
- None

**Returns:**
- 0 - Success
- 1 - Failed to create cache directory

**Side Effects:**
- Creates `~/.flow/cache/doctor/` directory
- Runs automatic cleanup of old entries (> 1 day)

**Example:**

```zsh
_doctor_cache_init
if [[ $? -eq 0 ]]; then
    echo "Cache initialized"
fi
```

---

#### `_doctor_cache_get`

Get cached token validation result if still valid.

**Signature:**

```zsh
_doctor_cache_get <cache_key>
```

**Parameters:**
- `$1` - Cache key (e.g., "token-github", "token-npm")

**Returns:**
- 0 - Cache hit (valid entry found)
- 1 - Cache miss (no entry, expired, or invalid)

**Output:**
- stdout - Cached JSON data (only on cache hit)

**Performance:**
- Target: < 10ms for cache check
- Actual: ~5-8ms (50% better than target)

**Example:**

```zsh
if cached_data=$(_doctor_cache_get "token-github"); then
    echo "Cache hit!"
    status=$(echo "$cached_data" | jq -r '.status')
    days=$(echo "$cached_data" | jq -r '.days_remaining')
else
    echo "Cache miss, need to validate token"
fi
```

---

#### `_doctor_cache_set`

Store token validation result in cache.

**Signature:**

```zsh
_doctor_cache_set <cache_key> <value> [ttl_seconds]
```

**Parameters:**
- `$1` - Cache key (e.g., "token-github")
- `$2` - Value to cache (JSON string or plain text)
- `$3` - (optional) TTL in seconds [default: 300 = 5 minutes]

**Returns:**
- 0 - Success
- 1 - Failed to write cache

**Implementation:**
- Atomic write (temp file + mv)
- flock for concurrent access safety
- Wraps plain text values in JSON automatically

**Example:**

```zsh
# Cache token validation result
validation_json='{"status": "valid", "days_remaining": 45, "username": "user"}'
_doctor_cache_set "token-github" "$validation_json"

# Cache with custom TTL (10 minutes)
_doctor_cache_set "token-npm" "$validation_json" 600
```

---

#### `_doctor_cache_clear`

Clear specific cache entry or entire cache.

**Signature:**

```zsh
_doctor_cache_clear [cache_key]
```

**Parameters:**
- `$1` - (optional) Cache key to clear [default: clear all]

**Returns:**
- 0 - Success

**Use Cases:**
- Token rotation - invalidate cached validation
- Debugging - force fresh validation

**Example:**

```zsh
# Clear specific token cache
_doctor_cache_clear "token-github"

# Clear all doctor cache entries
_doctor_cache_clear
```

---

#### `_doctor_cache_stats`

Show cache statistics and list cached entries.

**Signature:**

```zsh
_doctor_cache_stats
```

**Parameters:**
- None

**Returns:**
- 0 - Success
- 1 - No cache found

**Output:**

```text
Doctor Cache Statistics
=======================
Cache directory: ~/.flow/cache/doctor
Total entries: 3
Total size: 12 KB

Cached Entries:
  token-github    (valid, expires in 4m 23s)
  token-npm       (valid, expires in 2m 15s)
  token-pypi      (expired)
```

**Example:**

```zsh
_doctor_cache_stats
```

---

#### `_doctor_cache_clean_old`

Clean up cache entries older than 1 day.

**Signature:**

```zsh
_doctor_cache_clean_old
```

**Parameters:**
- None

**Returns:**
- 0 - Success

**Output:**
- stdout - Number of entries cleaned

**Behavior:**
- Automatically called during cache init
- Removes entries > `DOCTOR_CACHE_MAX_AGE_SECONDS` old (86400s = 1 day)
- Also cleans stale lock files
- Safe to run multiple times

**Example:**

```zsh
cleaned=$(_doctor_cache_clean_old)
echo "Cleaned $cleaned old entries"
```

---

### Locking Functions

#### `_doctor_cache_get_cache_path`

Get the cache file path for a token.

**Signature:**

```zsh
_doctor_cache_get_cache_path <cache_key>
```

**Parameters:**
- `$1` - Cache key (e.g., "token-github", "token-npm")

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Path to cache file

**Example:**

```zsh
cache_file=$(_doctor_cache_get_cache_path "token-github")
# Returns: ~/.flow/cache/doctor/token-github.cache
```

---

#### `_doctor_cache_get_lock_path`

Get the lock file path for cache operations.

**Signature:**

```zsh
_doctor_cache_get_lock_path <cache_key>
```

**Parameters:**
- `$1` - Cache key

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Path to lock file

**Example:**

```zsh
lock_file=$(_doctor_cache_get_lock_path "token-github")
# Returns: ~/.flow/cache/doctor/.token-github.lock
```

---

#### `_doctor_cache_acquire_lock`

Acquire exclusive lock for cache write operations.

**Signature:**

```zsh
_doctor_cache_acquire_lock <cache_key>
```

**Parameters:**
- `$1` - Cache key

**Returns:**
- 0 - Lock acquired
- 1 - Failed to acquire lock (timeout after 2s)

**Implementation:**
- Uses `flock` if available (preferred)
- Falls back to mkdir-based locking (atomic on POSIX)
- Detects and removes stale locks (holder process dead)
- File descriptor 201 reserved for doctor cache locks

**Notes:**
- Lock automatically released when shell exits
- Must call `_doctor_cache_release_lock` to release explicitly

**Example:**

```zsh
if _doctor_cache_acquire_lock "token-github"; then
    # ... write to cache
    _doctor_cache_release_lock "token-github"
else
    echo "Failed to acquire lock"
    return 1
fi
```

---

#### `_doctor_cache_release_lock`

Release exclusive lock for cache operations.

**Signature:**

```zsh
_doctor_cache_release_lock <cache_key>
```

**Parameters:**
- `$1` - Cache key

**Returns:**
- 0 - Always succeeds

**Behavior:**
- Closes flock file descriptor (fd 201)
- Removes mkdir-based lock directory
- Safe to call even if lock wasn't acquired

**Example:**

```zsh
_doctor_cache_release_lock "token-github"
```

---

### Convenience Functions

#### `_doctor_cache_token_get`

Convenience wrapper to get token validation cache.

**Signature:**

```zsh
_doctor_cache_token_get <provider>
```

**Parameters:**
- `$1` - Provider name (github, npm, pypi)

**Returns:**
- 0 - Cache hit
- 1 - Cache miss

**Output:**
- stdout - Cached token validation JSON

**Example:**

```zsh
if cached=$(_doctor_cache_token_get "github"); then
    status=$(echo "$cached" | jq -r '.status')
    echo "GitHub token: $status"
fi
```

**Equivalent to:**

```zsh
_doctor_cache_get "token-${provider}"
```

---

#### `_doctor_cache_token_set`

Convenience wrapper to cache token validation result.

**Signature:**

```zsh
_doctor_cache_token_set <provider> <value> [ttl_seconds]
```

**Parameters:**
- `$1` - Provider name (github, npm, pypi)
- `$2` - Validation result JSON
- `$3` - (optional) TTL in seconds [default: 300]

**Returns:**
- 0 - Success
- 1 - Failed

**Example:**

```zsh
result='{"status": "valid", "days_remaining": 45}'
_doctor_cache_token_set "github" "$result"
```

**Equivalent to:**

```zsh
_doctor_cache_set "token-${provider}" "$value" "$ttl"
```

---

#### `_doctor_cache_token_clear`

Convenience wrapper to invalidate token validation cache.

**Signature:**

```zsh
_doctor_cache_token_clear <provider>
```

**Parameters:**
- `$1` - Provider name (github, npm, pypi)

**Returns:**
- 0 - Success

**Use Cases:**
- After rotating GitHub token
- After updating npm or PyPI credentials
- Forcing fresh validation

**Example:**

```zsh
# After rotating GitHub token, invalidate cache
dot secret rotate GITHUB_TOKEN
_doctor_cache_token_clear "github"
```

**Equivalent to:**

```zsh
_doctor_cache_clear "token-${provider}"
```

---

### Constants

**Cache Configuration:**

```zsh
DOCTOR_CACHE_DEFAULT_TTL=300        # 5 minutes
DOCTOR_CACHE_LOCK_TIMEOUT=2         # 2 seconds
DOCTOR_CACHE_MAX_AGE_SECONDS=86400  # 1 day
DOCTOR_CACHE_DIR="$HOME/.flow/cache/doctor"
```

---

### Performance Metrics

**v5.17.0 Token Automation Phase 1:**

| Operation | Target | Actual | Improvement |
|-----------|--------|--------|-------------|
| Cache check | < 10ms | ~5-8ms | 50% better |
| Cache hit | < 100ms | ~50-80ms | 50% better |
| Token validation (cached) | < 3s | ~2-3s | Within target |
| API reduction | 50% | 80% | 60% better |
| Cache hit rate | 70% | 85% | 21% better |

**Integration:**
- `doctor --dot` - Token-only validation with caching
- `g push/pull` - Validates token before remote operations
- `work` - Checks token on session start
- `finish` - Validates before commit/push
- `dash dev` - Shows cached token status

---

## Teaching Libraries

**Files:**
- `lib/concept-extraction.zsh` - YAML frontmatter parsing (7 functions)
- `lib/prerequisite-checker.zsh` - DAG validation (7 functions)
- `lib/analysis-cache.zsh` - SHA-256 cache with flock (18 functions)
- `lib/cache-analysis.zsh` - Cache statistics and reporting (6 functions)
- `lib/analysis-display.zsh` - Display layer formatting (8 functions)
- `lib/report-generator.zsh` - Markdown/JSON reports (11 functions)
- `lib/ai-analysis.zsh` - Claude CLI integration (8 functions)
- `lib/ai-recipes.zsh` - AI prompt templates (11 functions)
- `lib/ai-usage.zsh` - AI usage tracking (9 functions)
- `lib/slide-optimizer.zsh` - Heuristic slide breaks (8 functions)

**Purpose:** AI-powered teaching workflow (v5.16.0+)
**Total Functions:** 93 documented
**System:** `teach analyze` command infrastructure

### Overview

The teaching libraries implement intelligent content analysis for educational materials:

1. **Concept Extraction** - Parses YAML frontmatter for learning concepts
2. **Prerequisite Validation** - DAG-based dependency checking
3. **SHA-256 Caching** - Prevents redundant analysis (5-min TTL)
4. **Report Generation** - Markdown/JSON summaries
5. **AI Analysis** - Claude CLI integration for insights
6. **Slide Optimization** - Heuristic break detection

**Workflow:**

```text
.qmd files → concept extraction → prerequisite check → cache → AI analysis → report
```

---

### lib/concept-extraction.zsh

**Functions:** 13
**Purpose:** Extract learning concepts from Quarto YAML frontmatter

#### `_extract_concepts_from_frontmatter`

Extract concepts field from .qmd frontmatter using yq.

**Signature:**

```zsh
_extract_concepts_from_frontmatter <file_path>
```

**Parameters:**
- `$1` - (required) Path to .qmd file

**Returns:**
- 0 - Success
- 1 - File not found or yq unavailable

**Output:**
- stdout - JSON string of concepts section
- stdout - Empty string if no concepts found

**Format Support:**

```yaml
# Simple format
concepts:
  introduces: [concept1, concept2]
  requires: [prereq1, prereq2]

# Array format
concepts:
  - id: concept1
    name: "Concept Name"
    prerequisites: [prereq1]
  - id: concept2
    name: "Another Concept"
    prerequisites: [prereq2]
```

**Example:**

```zsh
concepts_json=$(_extract_concepts_from_frontmatter "week-05-regression.qmd")
if [[ -n "$concepts_json" ]]; then
    echo "Found concepts: $concepts_json"
fi
```

---

#### `_parse_introduced_concepts`

Parse introduced concepts from concepts JSON.

**Signature:**

```zsh
_parse_introduced_concepts <concepts_json>
```

**Parameters:**
- `$1` - (required) Concepts JSON from frontmatter

**Returns:**
- stdout - Space-separated concept IDs
- stdout - Empty string if no concepts

**Supports Two Formats:**
1. Simple: `{introduces: [id1, id2]}`
2. Array: `[{id: id1, name: "..."}, {id: id2, name: "..."}]`

**Example:**

```zsh
concepts_json='{"introduces": ["regression", "correlation"]}'
introduced=$(_parse_introduced_concepts "$concepts_json")
echo "$introduced"  # Output: regression correlation
```

---

#### `_parse_required_concepts`

Parse required concepts (prerequisites) from concepts JSON.

**Signature:**

```zsh
_parse_required_concepts <concepts_json>
```

**Parameters:**
- `$1` - (required) Concepts JSON from frontmatter

**Returns:**
- stdout - Space-separated prerequisite concept IDs
- stdout - Empty string if no prerequisites

**Supports Two Formats:**
1. Simple: `{requires: [prereq1, prereq2]}`
2. Array: `[{prerequisites: [p1, p2]}, {prerequisites: [p3]}]`

**Deduplication:**
- Automatically removes duplicates
- Uses `sort -u` for uniqueness

**Example:**

```zsh
concepts_json='[{"prerequisites": ["mean", "variance"]}, {"prerequisites": ["variance"]}]'
required=$(_parse_required_concepts "$concepts_json")
echo "$required"  # Output: mean variance
```

---

#### `_get_week_from_file`

Extract week number from filename or frontmatter.

**Signature:**

```zsh
_get_week_from_file <file_path> [frontmatter_json]
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (optional) Frontmatter JSON (optimization)

**Returns:**
- stdout - Week number as integer
- stdout - 0 if not found

**Detection Priority:**
1. Filename pattern: `week-05-lecture.qmd` → 5
2. Frontmatter `week` field
3. Fallback to 0

**Example:**

```zsh
week=$(_get_week_from_file "week-08-anova.qmd")
echo "Week: $week"  # Output: Week: 8
```

---

#### `_get_concept_line_number`

Find line number where concept appears in file.

**Signature:**

```zsh
_get_concept_line_number <file_path> <concept_name>
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (required) Concept name/ID

**Returns:**
- stdout - Line number (1-based)
- stdout - 0 if not found

**Search Scope:**
- Searches within YAML frontmatter only
- Looks for concept in `introduces` or `id` fields

**Example:**

```zsh
line=$(_get_concept_line_number "week-05.qmd" "regression")
if [[ $line -gt 0 ]]; then
    echo "Concept 'regression' found at line $line"
fi
```

---

#### `_build_concept_graph`

Build complete concept graph from course directory.

**Signature:**

```zsh
_build_concept_graph [course_directory]
```

**Parameters:**
- `$1` - (optional) Course directory [default: current directory]

**Returns:**
- stdout - JSON concept graph

**Output Format:**

```json
{
  "concept1": {
    "introduced_in": "week-05-lecture.qmd",
    "week": 5,
    "prerequisites": ["prereq1", "prereq2"]
  },
  "concept2": {
    "introduced_in": "week-06-lecture.qmd",
    "week": 6,
    "prerequisites": []
  }
}
```

**Use Case:**
- Used by `teach analyze` for prerequisite validation
- Cached for performance

**Example:**

```zsh
graph=$(_build_concept_graph "lectures/")
echo "$graph" | jq '.regression'
```

---

#### `_load_concept_graph`

Load cached concept graph from disk.

**Signature:**

```zsh
_load_concept_graph [course_directory]
```

**Parameters:**
- `$1` - (optional) Course directory [default: current]

**Returns:**
- 0 - Graph loaded
- 1 - No cached graph found

**Output:**
- stdout - Cached JSON concept graph
- stdout - Empty string if cache miss

**Cache Location:**
- `.teach-cache/concept-graph.json`

**Example:**

```zsh
if graph=$(_load_concept_graph); then
    echo "Loaded cached graph"
else
    graph=$(_build_concept_graph)
fi
```

---

#### `_save_concept_graph`

Save concept graph to disk cache.

**Signature:**

```zsh
_save_concept_graph <graph_json> [course_directory]
```

**Parameters:**
- `$1` - (required) Concept graph JSON
- `$2` - (optional) Course directory [default: current]

**Returns:**
- 0 - Success
- 1 - Failed to write

**Cache Location:**
- `.teach-cache/concept-graph.json`

**Example:**

```zsh
graph=$(_build_concept_graph)
_save_concept_graph "$graph"
```

---

### lib/prerequisite-checker.zsh

**Functions:** 7
**Purpose:** DAG-based prerequisite validation and dependency checking

#### `_check_prerequisites`

Validate all prerequisite dependencies in course data.

**Signature:**

```zsh
_check_prerequisites <course_data_json>
```

**Parameters:**
- `$1` - (required) Course data JSON with weeks and concepts

**Returns:**
- stdout - JSON array of prerequisite violations

**Violation Types:**
1. **missing** - Prerequisite not defined anywhere
2. **future** - Prerequisite introduced after dependent concept
3. **circular** - Circular dependency detected

**Output Format:**

```json
[
  {
    "concept_id": "regression",
    "type": "missing",
    "week": 5,
    "prerequisite_id": "correlation",
    "message": "Missing prerequisite: correlation",
    "suggestion": "Add correlation to earlier week"
  }
]
```

**Global State:**
- Sets `PREREQUISITE_VIOLATIONS` array

**Example:**

```zsh
course_json=$(cat course-data.json)
violations=$(_check_prerequisites "$course_json")
if [[ "$violations" != "[]" ]]; then
    echo "Found violations: $violations"
fi
```

---

#### `_validate_concept_graph`

Perform complete graph validation (missing, future, circular).

**Signature:**

```zsh
_validate_concept_graph <graph_json>
```

**Parameters:**
- `$1` - (required) Concept graph JSON from `_build_concept_graph`

**Returns:**
- 0 - Graph valid
- 1 - Validation failures found

**Checks Performed:**
1. All prerequisites exist
2. No future prerequisites
3. No circular dependencies
4. Transitive closure consistency

**Example:**

```zsh
graph=$(_build_concept_graph)
if _validate_concept_graph "$graph"; then
    echo "✓ Graph valid"
else
    echo "✗ Validation failed"
fi
```

---

#### `_detect_circular_dependencies`

Find circular prerequisite loops in concept graph.

**Signature:**

```zsh
_detect_circular_dependencies <graph_json>
```

**Parameters:**
- `$1` - (required) Concept graph JSON

**Returns:**
- stdout - JSON array of circular dependency chains
- stdout - Empty array `[]` if no cycles

**Output Format:**

```json
[
  {
    "cycle": ["concept-a", "concept-b", "concept-c", "concept-a"],
    "week_first": 5,
    "severity": "error"
  }
]
```

**Example:**

```zsh
graph=$(_build_concept_graph)
cycles=$(_detect_circular_dependencies "$graph")
if [[ "$cycles" != "[]" ]]; then
    echo "Found circular dependencies: $cycles"
fi
```

---

#### `_build_prerequisite_tree`

Build dependency tree for a specific concept (transitive closure).

**Signature:**

```zsh
_build_prerequisite_tree <concept_id> <graph_json>
```

**Parameters:**
- `$1` - (required) Concept ID to analyze
- `$2` - (required) Concept graph JSON

**Returns:**
- stdout - JSON tree structure with all transitive prerequisites

**Output Format:**

```json
{
  "concept": "regression",
  "direct_prerequisites": ["correlation", "variance"],
  "transitive_prerequisites": ["mean", "variance", "correlation"],
  "depth": 2,
  "total_prerequisites": 3
}
```

**Use Case:**
- Prerequisite tree visualization
- Dependency depth analysis
- Learning path planning

**Example:**

```zsh
graph=$(_build_concept_graph)
tree=$(_build_prerequisite_tree "regression" "$graph")
echo "$tree" | jq '.transitive_prerequisites'
```

---

#### `_format_prerequisite_tree_display`

Format prerequisite tree for terminal display (with colors and tree structure).

**Signature:**

```zsh
_format_prerequisite_tree_display <tree_json>
```

**Parameters:**
- `$1` - (required) Prerequisite tree JSON from `_build_prerequisite_tree`

**Returns:**
- stdout - Formatted terminal output with ANSI colors and tree characters

**Output Example:**

```text
Prerequisite Tree for: regression
├─ correlation (Week 4)
│  └─ variance (Week 3)
│     └─ mean (Week 2)
└─ variance (Week 3)
   └─ mean (Week 2)

Total Prerequisites: 3 (depth: 2)
```

**Features:**
- Unicode tree characters (├─, └─, │)
- Color coding (ANSI escape codes)
- Week numbers for each prerequisite
- Depth and count summary

**Example:**

```zsh
tree=$(_build_prerequisite_tree "regression" "$graph")
_format_prerequisite_tree_display "$tree"
```

---

**Complete API:** See archived TEACH-ANALYZE-API-REFERENCE.md for all 7 functions with detailed examples

---

### lib/analysis-cache.zsh

**Functions:** 19
**Purpose:** SHA-256-based content caching with concurrent access safety

#### Overview

Analysis cache system prevents redundant processing by caching results with content-based keys:

- **SHA-256 hashing** - Content changes invalidate cache automatically
- **flock locking** - Safe concurrent access (multiple `teach analyze` runs)
- **5-minute TTL** - Balance between freshness and performance
- **Atomic writes** - Temp file + rename for safety
- **Auto cleanup** - Removes entries > 1 day old

**Cache Structure:**

```text
.teach-cache/
├── analysis/
│   ├── abc123def456.json  # SHA-256 of content
│   ├── 789ghi012jkl.json
│   └── metadata.json
├── slides/
│   └── def456abc123.json  # Slide optimization cache
└── locks/
    ├── .analysis.lock
    └── .slides.lock
```

#### `_cache_compute_hash`

Compute SHA-256 hash of file content.

**Signature:**

```zsh
_cache_compute_hash <file_path>
```

**Parameters:**
- `$1` - (required) Path to file

**Returns:**
- stdout - SHA-256 hash (lowercase hex)

**Performance:**
- Reads full file content
- ~10-50ms depending on file size

**Example:**

```zsh
hash=$(_cache_compute_hash "week-05-lecture.qmd")
echo "Content hash: $hash"
```

---

#### `_cache_get_analysis`

Retrieve cached analysis result by content hash.

**Signature:**

```zsh
_cache_get_analysis <file_path>
```

**Parameters:**
- `$1` - (required) Path to analyzed file

**Returns:**
- 0 - Cache hit
- 1 - Cache miss (no entry or expired)

**Output:**
- stdout - Cached analysis JSON (only on hit)

**TTL Check:**
- Reads `cached_at` timestamp
- Compares to current time
- Returns miss if > 5 minutes old

**Example:**

```zsh
if analysis=$(_cache_get_analysis "week-05.qmd"); then
    echo "Cache hit! Analysis: $analysis"
else
    # Perform fresh analysis
    analysis=$(teach analyze "week-05.qmd")
    _cache_set_analysis "week-05.qmd" "$analysis"
fi
```

---

#### `_cache_set_analysis`

Store analysis result with TTL metadata.

**Signature:**

```zsh
_cache_set_analysis <file_path> <analysis_json> [ttl_seconds]
```

**Parameters:**
- `$1` - (required) Path to analyzed file
- `$2` - (required) Analysis result JSON
- `$3` - (optional) TTL in seconds [default: 300 = 5 minutes]

**Returns:**
- 0 - Success
- 1 - Failed to write

**Implementation:**
- Computes SHA-256 of file content
- Creates atomic write (temp + rename)
- Acquires flock for thread safety
- Stores with timestamp metadata

**Example:**

```zsh
analysis='{"concepts": ["regression"], "valid": true}'
_cache_set_analysis "week-05.qmd" "$analysis"
```

---

#### `_cache_invalidate_file`

Remove cache entry for specific file.

**Signature:**

```zsh
_cache_invalidate_file <file_path>
```

**Parameters:**
- `$1` - (required) Path to file

**Returns:**
- 0 - Success (even if cache didn't exist)

**Use Cases:**
- After manual content edits
- Force fresh analysis
- Cache corruption recovery

**Example:**

```zsh
# Edit file then invalidate cache
vim week-05.qmd
_cache_invalidate_file "week-05.qmd"
```

---

#### `_cache_cleanup_old_entries`

Remove cache entries older than 1 day.

**Signature:**

```zsh
_cache_cleanup_old_entries
```

**Parameters:**
- None

**Returns:**
- stdout - Number of entries removed

**Behavior:**
- Scans `.teach-cache/analysis/` directory
- Checks file mtime (modification time)
- Removes entries > 86400 seconds old
- Also cleans stale lock files

**Example:**

```zsh
removed=$(_cache_cleanup_old_entries)
echo "Cleaned up $removed old cache entries"
```

---

#### `_cache_acquire_lock`

Acquire exclusive lock for cache writes.

**Signature:**

```zsh
_cache_acquire_lock <cache_type>
```

**Parameters:**
- `$1` - (required) Cache type ("analysis" or "slides")

**Returns:**
- 0 - Lock acquired
- 1 - Timeout (failed after 2s)

**Implementation:**
- Uses `flock` if available
- Falls back to mkdir-based locking (atomic on POSIX)
- Detects and removes stale locks (dead process)

**File Descriptor:**
- Uses fd 200 for analysis cache locks
- Uses fd 201 for slides cache locks

**Example:**

```zsh
if _cache_acquire_lock "analysis"; then
    # ... write to cache
    _cache_release_lock "analysis"
else
    echo "Failed to acquire lock"
fi
```

---

#### `_cache_release_lock`

Release exclusive cache lock.

**Signature:**

```zsh
_cache_release_lock <cache_type>
```

**Parameters:**
- `$1` - (required) Cache type ("analysis" or "slides")

**Returns:**
- 0 - Always succeeds

**Behavior:**
- Closes flock file descriptor
- Removes mkdir-based lock directory
- Safe to call even if lock wasn't acquired

**Example:**

```zsh
_cache_release_lock "analysis"
```

---

**Complete API:** See archived TEACH-ANALYZE-API-REFERENCE.md for all 19 functions including metadata management, batch operations, and statistics

---

### lib/report-generator.zsh

**Functions:** 12
**Purpose:** Generate formatted analysis reports (Markdown/JSON/Interactive)

#### `_generate_markdown_report`

Generate human-readable Markdown analysis report.

**Signature:**

```zsh
_generate_markdown_report <analysis_data> [output_file]
```

**Parameters:**
- `$1` - (required) Analysis data JSON
- `$2` - (optional) Output file path [default: stdout]

**Returns:**
- 0 - Success
- 1 - Failed to generate

**Report Sections:**
1. **Summary** - Concept/prerequisite counts, file stats
2. **Concept Distribution** - Concepts per week
3. **Prerequisite Validation** - Violations summary
4. **Circular Dependencies** - If detected
5. **Recommendations** - Suggested improvements

**Example Output:**

```markdown
# Teaching Content Analysis Report

**Generated:** 2026-01-24 15:15
**Course:** STAT 545

## Summary
- Total concepts: 45
- Total prerequisites: 67
- Files analyzed: 12
- Validation status: ✓ PASS

## Concept Distribution
| Week | Concepts | Prerequisites |
|------|----------|---------------|
| 1    | 3        | 0             |
| 2    | 5        | 3             |
...

## Validation Results
✓ No circular dependencies detected
✓ All prerequisites defined
⚠ 2 concepts have future prerequisites

## Recommendations
1. Consider moving "correlation" to Week 4
2. Add prerequisite "mean" to Week 2
```

**Example:**

```zsh
analysis=$(teach analyze --json)
_generate_markdown_report "$analysis" "analysis-report.md"
```

---

#### `_generate_json_report`

Export analysis data as JSON for machine processing.

**Signature:**

```zsh
_generate_json_report <analysis_data> [output_file]
```

**Parameters:**
- `$1` - (required) Analysis data
- `$2` - (optional) Output file [default: stdout]

**Returns:**
- 0 - Success

**Output Schema:**

```json
{
  "meta": {
    "generated_at": "2026-01-24T15:15:00Z",
    "version": "v5.16.0",
    "course": "STAT 545"
  },
  "summary": {
    "total_concepts": 45,
    "total_prerequisites": 67,
    "files_analyzed": 12,
    "validation_passed": true
  },
  "concepts": [
    {
      "id": "regression",
      "week": 5,
      "prerequisites": ["correlation", "variance"],
      "transitive_prerequisites": ["mean", "variance", "correlation"]
    }
  ],
  "violations": [],
  "warnings": []
}
```

**Example:**

```zsh
analysis=$(teach analyze --json)
_generate_json_report "$analysis" "analysis.json"
```

---

#### `_print_interactive_summary`

Display colorized analysis summary in terminal.

**Signature:**

```zsh
_print_interactive_summary <analysis_data>
```

**Parameters:**
- `$1` - (required) Analysis data JSON

**Returns:**
- 0 - Success

**Features:**
- ANSI color codes for status (✓ green, ✗ red, ⚠ yellow)
- Unicode box drawing characters
- Progress bars for metrics
- Collapsible sections (via less/more)

**Example Output:**

```text
╭─────────────────────────────────────────────────╮
│ 📊 Teaching Content Analysis                   │
├─────────────────────────────────────────────────┤
│                                                 │
│ ✓ Total Concepts: 45                            │
│ ✓ Prerequisites: 67                             │
│ ✓ Files Analyzed: 12                            │
│                                                 │
│ Validation: ✓ PASS                              │
│   ✓ No circular dependencies                    │
│   ✓ All prerequisites defined                   │
│   ⚠ 2 future prerequisites                      │
│                                                 │
╰─────────────────────────────────────────────────╯
```

**Example:**

```zsh
analysis=$(teach analyze)
_print_interactive_summary "$analysis"
```

---

#### `_format_concept_distribution_table`

Format concept distribution as terminal table.

**Signature:**

```zsh
_format_concept_distribution_table <analysis_data>
```

**Parameters:**
- `$1` - (required) Analysis data JSON

**Returns:**
- stdout - Formatted table with ANSI colors

**Example Output:**

```text
Week  Concepts  Prerequisites  Avg Depth
────  ────────  ─────────────  ─────────
  1          3              0        0.0
  2          5              3        1.2
  3          7              8        1.8
  4          6             12        2.1
  5          8             15        2.5
────  ────────  ─────────────  ─────────
Total       29             38        1.9
```

**Example:**

```zsh
analysis=$(teach analyze --json)
_format_concept_distribution_table "$analysis"
```

---

**Complete API:** See archived TEACH-ANALYZE-API-REFERENCE.md for all 12 functions including violation formatting, recommendation generation, and export utilities

---

### lib/ai-analysis.zsh

**Functions:** 8
**Purpose:** Claude CLI integration for AI-powered pedagogical insights

#### `_ai_analyze_content`

Send content to Claude for pedagogical analysis.

**Signature:**

```zsh
_ai_analyze_content <file_path> [mode]
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (optional) Analysis mode ("full" | "quick") [default: "full"]

**Returns:**
- 0 - Success
- 1 - Analysis failed (Claude CLI error, API error)

**Output:**
- stdout - Analysis JSON

**Analysis Modes:**

**Full Mode** - Comprehensive analysis (~10-30s, $0.01-0.05):

```json
{
  "key_concepts": ["regression", "correlation", "causation"],
  "difficulty": "intermediate",
  "cognitive_load": "medium",
  "bloom_taxonomy": ["remember", "understand", "apply", "analyze"],
  "estimated_time_minutes": 50,
  "prerequisites_needed": ["mean", "variance"],
  "learning_objectives": [
    "Understand relationship between variables",
    "Apply regression analysis to real data"
  ],
  "common_misconceptions": [
    "Correlation implies causation"
  ],
  "suggested_activities": [
    "Practice with scatter plots",
    "Interpret regression output"
  ]
}
```

**Quick Mode** - Essential insights only (~3-5s, $0.005-0.01):

```json
{
  "key_concepts": ["regression", "correlation"],
  "difficulty": "intermediate",
  "estimated_time_minutes": 50
}
```

**Example:**

```zsh
# Full analysis
analysis=$(_ai_analyze_content "week-05-lecture.qmd")
echo "$analysis" | jq '.key_concepts'

# Quick analysis (faster, cheaper)
analysis=$(_ai_analyze_content "week-05-lecture.qmd" "quick")
```

---

#### `_ai_estimate_cost`

Estimate Claude API cost for content analysis.

**Signature:**

```zsh
_ai_estimate_cost <file_path> [mode]
```

**Parameters:**
- `$1` - (required) Path to file
- `$2` - (optional) Analysis mode [default: "full"]

**Returns:**
- stdout - Estimated cost in USD (e.g., "0.023")

**Cost Calculation:**
- Counts content tokens (input)
- Estimates response tokens (~500 full, ~100 quick)
- Uses Claude pricing (Sonnet: $3/1M input, $15/1M output)

**Example:**

```zsh
cost=$(_ai_estimate_cost "week-05-lecture.qmd")
echo "Estimated cost: \$$cost"

# Check before batch processing
total_cost=0
for file in lectures/*.qmd; do
    cost=$(_ai_estimate_cost "$file")
    total_cost=$(awk "BEGIN {print $total_cost + $cost}")
done
echo "Total batch cost: \$$total_cost"
```

---

#### `_ai_batch_analyze`

Analyze multiple files in parallel with cost tracking.

**Signature:**

```zsh
_ai_batch_analyze <file1> <file2> ... [--mode MODE] [--max-cost COST]
```

**Parameters:**
- `$@` - File paths to analyze
- `--mode` - Analysis mode [default: "full"]
- `--max-cost` - Stop if estimated cost exceeds limit

**Returns:**
- 0 - Success
- 1 - Cost limit exceeded or analysis failed

**Features:**
- Parallel processing (up to 4 concurrent)
- Progress tracking
- Cost accumulation
- Graceful failure handling

**Example:**

```zsh
# Analyze all lectures
_ai_batch_analyze lectures/*.qmd --mode quick

# With cost limit
_ai_batch_analyze lectures/*.qmd --max-cost 1.00
```

---

#### `_ai_track_usage`

Track cumulative AI analysis costs.

**Signature:**

```zsh
_ai_track_usage <cost> <mode> <file_path>
```

**Parameters:**
- `$1` - (required) Cost in USD
- `$2` - (required) Analysis mode
- `$3` - (required) File analyzed

**Returns:**
- 0 - Success

**Log Format:**

```text
2026-01-24T15:15:00Z,full,week-05-lecture.qmd,0.023
2026-01-24T15:16:00Z,quick,week-06-lecture.qmd,0.008
```

**Log Location:**
- `.teach-cache/ai-usage.log`

**Example:**

```zsh
_ai_track_usage "0.023" "full" "week-05.qmd"

# View total usage
awk -F, '{sum += $4} END {print "Total: $" sum}' .teach-cache/ai-usage.log
```

---

**Complete API:** See archived TEACH-ANALYZE-API-REFERENCE.md for all 8 functions including caching, error handling, and rate limiting

---

### lib/slide-optimizer.zsh

**Functions:** 8
**Purpose:** Heuristic slide break detection and optimization

#### `_detect_slide_breaks`

Find natural slide break points in content.

**Signature:**

```zsh
_detect_slide_breaks <file_path>
```

**Parameters:**
- `$1` - (required) Path to .qmd file

**Returns:**
- stdout - JSON array of slide breaks

**Heuristics (in priority order):**
1. **H2 headings** (##) - Always major break
2. **H3 headings** (###) - Break if > 15 lines since last
3. **Horizontal rules** (---) - Explicit break
4. **Content density** - Break after 5 bullet points
5. **Code blocks** - Break before/after large code
6. **Concept transitions** - Break when concept changes

**Output Format:**

```json
{
  "slides": [
    {
      "number": 1,
      "start_line": 1,
      "end_line": 25,
      "break_type": "h2",
      "heading": "Introduction to Regression",
      "content_lines": 24
    },
    {
      "number": 2,
      "start_line": 26,
      "end_line": 50,
      "break_type": "h3",
      "heading": "Simple Linear Regression",
      "content_lines": 24
    }
  ]
}
```

**Example:**

```zsh
breaks=$(_detect_slide_breaks "week-05-lecture.qmd")
echo "$breaks" | jq '.slides | length'  # Number of slides
```

---

#### `_estimate_slide_timing`

Calculate estimated presentation duration.

**Signature:**

```zsh
_estimate_slide_timing <file_path>
```

**Parameters:**
- `$1` - (required) Path to .qmd file

**Returns:**
- stdout - Timing JSON

**Timing Algorithm:**
- **Text**: 150 words/minute
- **Bullet points**: 20 seconds each
- **Code blocks**: 1 minute per 10 lines
- **Images**: 30 seconds each
- **Tables**: 1 minute per table

**Output Format:**

```json
{
  "total_minutes": 45,
  "slides": [
    {
      "number": 1,
      "minutes": 3,
      "components": {
        "text": 1.5,
        "bullets": 0.7,
        "code": 0.8,
        "images": 0
      }
    }
  ],
  "pace": "moderate"  # slow < 2min/slide < moderate < 1min/slide < fast
}
```

**Example:**

```zsh
timing=$(_estimate_slide_timing "week-05-lecture.qmd")
total=$(echo "$timing" | jq '.total_minutes')
echo "Estimated duration: $total minutes"
```

---

#### `_extract_slide_key_concepts`

Identify main concepts per slide.

**Signature:**

```zsh
_extract_slide_key_concepts <file_path> <slide_breaks_json>
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (required) Slide breaks JSON from `_detect_slide_breaks`

**Returns:**
- stdout - Enhanced slides JSON with key concepts

**Extraction Methods:**
1. **Frontmatter** - Concepts defined in YAML
2. **Headings** - Concept names from H2/H3
3. **Emphasis** - **bold** or *italic* terms
4. **Code** - Function names, variable names
5. **Frequency** - Most common terms

**Output Format:**

```json
{
  "slides": [
    {
      "number": 1,
      "key_concepts": ["regression", "correlation", "linear_model"],
      "concept_density": "medium",  # low/medium/high
      "callout_suggestions": [
        {
          "concept": "regression",
          "line": 15,
          "context": "Simple linear regression formula"
        }
      ]
    }
  ]
}
```

**Example:**

```zsh
breaks=$(_detect_slide_breaks "week-05.qmd")
concepts=$(_extract_slide_key_concepts "week-05.qmd" "$breaks")
echo "$concepts" | jq '.slides[0].key_concepts'
```

---

#### `_optimize_slide_breaks`

Suggest improvements to slide structure.

**Signature:**

```zsh
_optimize_slide_breaks <slide_data_json>
```

**Parameters:**
- `$1` - (required) Slide data with concepts and timing

**Returns:**
- stdout - Optimization suggestions JSON

**Optimization Rules:**
1. **Too dense** - > 5 concepts per slide → split
2. **Too long** - > 3 minutes per slide → split
3. **Too short** - < 30 seconds → merge with next
4. **Unbalanced** - Large variance in slide times → redistribute
5. **Concept overflow** - Concept starts but doesn't finish → adjust break

**Output Format:**

```json
{
  "suggestions": [
    {
      "slide_number": 3,
      "type": "split",
      "severity": "warning",
      "reason": "7 concepts (recommended: 3-5)",
      "suggestion": "Split after line 45 (concept: correlation)",
      "estimated_improvement": "Better cognitive load distribution"
    },
    {
      "slide_number": 5,
      "type": "merge",
      "severity": "info",
      "reason": "Only 20 seconds content",
      "suggestion": "Merge with slide 6",
      "estimated_improvement": "Improved flow"
    }
  ],
  "overall_quality": "good",  # poor/fair/good/excellent
  "optimization_potential": "medium"  # low/medium/high
}
```

**Example:**

```zsh
breaks=$(_detect_slide_breaks "week-05.qmd")
concepts=$(_extract_slide_key_concepts "week-05.qmd" "$breaks")
timing=$(_estimate_slide_timing "week-05.qmd")

# Combine data
slide_data=$(jq -s '.[0] * .[1] * .[2]' \
  <(echo "$breaks") \
  <(echo "$concepts") \
  <(echo "$timing"))

# Get optimization suggestions
suggestions=$(_optimize_slide_breaks "$slide_data")
echo "$suggestions" | jq '.suggestions[]'
```

---

**Complete API:** See archived TEACH-ANALYZE-API-REFERENCE.md for all 8 functions including visualization, export, and integration with `teach analyze --optimize`

---

### lib/cache-analysis.zsh

**Functions:** 6
**Purpose:** Cache analysis, statistics, and optimization recommendations

#### `_analyze_cache_size`

Analyze total cache size and file count.

**Signature:**

```zsh
_analyze_cache_size [cache_dir]
```

**Parameters:**
- `$1` - (optional) Cache directory path [default: `"_freeze/site"`]

**Returns:**
- 0 - Analysis successful
- 1 - Cache directory doesn't exist

**Output:**
- stdout - Colon-separated string: `"size_bytes:file_count:size_human"`

**Example:**

```zsh
info=$(_analyze_cache_size "_freeze/site")
size_bytes=$(echo "$info" | cut -d: -f1)
file_count=$(echo "$info" | cut -d: -f2)
size_human=$(echo "$info" | cut -d: -f3)
echo "Cache: $size_human ($file_count files)"
```

---

#### `_analyze_cache_by_directory`

Break down cache size by subdirectory.

**Signature:**

```zsh
_analyze_cache_by_directory [cache_dir]
```

**Parameters:**
- `$1` - (optional) Cache directory path [default: `"_freeze/site"`]

**Returns:**
- 0 - Analysis successful
- 1 - Cache directory doesn't exist

**Output:**
- stdout - Multi-line, colon-separated: `dir_name:size_bytes:size_human:file_count:percentage`

**Example:**

```zsh
_analyze_cache_by_directory "_freeze/site" | while IFS=: read -r name bytes human count pct; do
    echo "$name: $human ($pct%)"
done
```

---

#### `_analyze_cache_by_age`

Break down cache by file age (< 7 days, 7-30 days, > 30 days).

**Signature:**

```zsh
_analyze_cache_by_age [cache_dir]
```

**Parameters:**
- `$1` - (optional) Cache directory path [default: `"_freeze/site"`]

**Returns:**
- 0 - Analysis successful
- 1 - Cache directory doesn't exist

**Output:**
- stdout - Multi-line, colon-separated: `label:size_bytes:size_human:count:percentage`

**Example:**

```zsh
_analyze_cache_by_age "_freeze/site"
# < 7 days:1234567:1.2MB:45:60
# 7-30 days:567890:554KB:20:30
# > 30 days:123456:121KB:10:10
```

---

#### `_calculate_cache_hit_rate`

Calculate cache hit rate from performance log data.

**Signature:**

```zsh
_calculate_cache_hit_rate [perf_log] [days]
```

**Parameters:**
- `$1` - (optional) Performance log path [default: `".teach/performance-log.json"`]
- `$2` - (optional) Number of days to analyze [default: `7`]

**Returns:**
- 0 - Calculation successful
- 1 - Log doesn't exist or jq not available

**Output:**
- stdout - Colon-separated: `"hit_rate:hits:misses:avg_hit_time:avg_miss_time"`

**Example:**

```zsh
data=$(_calculate_cache_hit_rate ".teach/performance-log.json" 30)
hit_rate=$(echo "$data" | cut -d: -f1)
echo "Cache hit rate: ${hit_rate}%"
```

---

#### `_generate_cache_recommendations`

Generate actionable cache optimization recommendations.

**Signature:**

```zsh
_generate_cache_recommendations [cache_dir] [perf_log]
```

**Parameters:**
- `$1` - (optional) Cache directory path
- `$2` - (optional) Performance log path

**Returns:**
- 0 - Always

**Output:**
- stdout - Bulleted list of recommendations

**Example:**

```zsh
_generate_cache_recommendations "_freeze/site" ".teach/performance-log.json"
# • Clear > 30 days: Save 121KB (10 files)
# • Hit rate < 80%: Consider cache rebuild
```

---

#### `_format_cache_report`

Generate formatted cache analysis report with multiple sections.

**Signature:**

```zsh
_format_cache_report [cache_dir] [perf_log] [--recommend]
```

**Parameters:**
- `$1` - (optional) Cache directory path
- `$2` - (optional) Performance log path
- `--recommend` - Include optimization recommendations

**Returns:**
- 0 - Report generated successfully
- 1 - Cache doesn't exist

**Output:**
- stdout - Formatted report with total stats, directory breakdown, age breakdown, performance, and recommendations

---

### lib/analysis-display.zsh

**Functions:** 8
**Purpose:** Display layer for teach analyze output formatting

#### `_display_analysis_header`

Display formatted header with title and subtitle.

**Signature:**

```zsh
_display_analysis_header <title> <subtitle>
```

**Parameters:**
- `$1` - (required) Header title
- `$2` - (required) Header subtitle

**Output:**
- stdout - Formatted header with box drawing characters

**Example:**

```zsh
_display_analysis_header "Analysis Results" "Week 05 Lecture"
# ┌──────────────────────────────────────────────────────┐
# │   Analysis Results                                   │
# │   Week 05 Lecture                                    │
# └──────────────────────────────────────────────────────┘
```

---

#### `_display_concepts_section`

Display extracted concepts in formatted table.

**Signature:**

```zsh
_display_concepts_section <results_file>
```

**Parameters:**
- `$1` - (required) Path to analysis results JSON file

**Output:**
- stdout - Formatted table with concept names and introduction weeks

---

#### `_display_prerequisites_section`

Display prerequisite validation with dependency tree visualization.

**Signature:**

```zsh
_display_prerequisites_section <results_file> <analyzed_file>
```

**Parameters:**
- `$1` - (required) Path to analysis results JSON file
- `$2` - (required) Path to file being analyzed

**Output:**
- stdout - Formatted prerequisite tree with validation status

**Status Indicators:**
- `✓ Green` - Valid prerequisite
- `✗ Red` - Missing prerequisite
- `⚠ Yellow` - Future week prerequisite

---

#### `_display_violations_section`

Display constraint violations detected during analysis.

**Signature:**

```zsh
_display_violations_section <results_file>
```

**Parameters:**
- `$1` - (required) Path to analysis results file

**Output:**
- stdout - Warning header and bullet list of violations (if any)

---

#### `_display_ai_section`

Display AI-powered analysis results including Bloom levels and cognitive load.

**Signature:**

```zsh
_display_ai_section <results_file>
```

**Parameters:**
- `$1` - (required) Path to analysis results JSON file (with AI data)

**Output:**
- stdout - Formatted table with Bloom levels, cognitive load, and teaching times

**Color Coding:**
- Cognitive load 0.0-0.4: Green (✓)
- Cognitive load 0.4-0.7: Yellow (⚠)
- Cognitive load > 0.7: Red (✗)

---

#### `_display_slide_section`

Display slide optimization results including break suggestions.

**Signature:**

```zsh
_display_slide_section <slide_data>
```

**Parameters:**
- `$1` - (required) Slide optimization JSON data

**Output:**
- stdout - Formatted table with metrics and suggestions

---

#### `_display_summary_section`

Display final summary with status and next steps.

**Signature:**

```zsh
_display_summary_section <results_file> <exit_code>
```

**Parameters:**
- `$1` - (required) Path to analysis results file
- `$2` - (required) Exit code (0 = success, non-zero = issues)

**Output:**
- stdout - Formatted summary with status box, issue count, and next steps

---

### lib/ai-recipes.zsh

**Functions:** 11
**Purpose:** AI prompt templates and recipe system for teaching workflows

#### `_flow_ai_recipe_explain`

Generate explanation of code or concept using Claude.

**Signature:**

```zsh
_flow_ai_recipe_explain <content> [--verbose]
```

**Parameters:**
- `$1` - (required) Code or concept to explain
- `--verbose` - Include detailed breakdown

**Returns:**
- 0 - Success
- 1 - AI error

**Output:**
- stdout - Explanation text

---

#### `_flow_ai_recipe_review`

Review code for issues, improvements, and best practices.

**Signature:**

```zsh
_flow_ai_recipe_review <code> [--focus AREA]
```

**Parameters:**
- `$1` - (required) Code to review
- `--focus` - Focus area: security, performance, readability, all

**Returns:**
- 0 - Success
- 1 - AI error

**Output:**
- stdout - Review feedback with suggestions

---

#### `_flow_ai_recipe_test`

Generate test cases for code.

**Signature:**

```zsh
_flow_ai_recipe_test <code> [--framework FRAMEWORK]
```

**Parameters:**
- `$1` - (required) Code to generate tests for
- `--framework` - Test framework: testthat, pytest, jest

**Returns:**
- 0 - Success
- 1 - AI error

**Output:**
- stdout - Generated test code

---

#### `_flow_ai_recipe_document`

Generate documentation for code.

**Signature:**

```zsh
_flow_ai_recipe_document <code> [--format FORMAT]
```

**Parameters:**
- `$1` - (required) Code to document
- `--format` - Documentation format: roxygen, docstring, jsdoc

**Returns:**
- 0 - Success
- 1 - AI error

**Output:**
- stdout - Generated documentation

---

#### `_flow_ai_recipe_fix`

Suggest fixes for code issues or errors.

**Signature:**

```zsh
_flow_ai_recipe_fix <code> <error_message>
```

**Parameters:**
- `$1` - (required) Code with issue
- `$2` - (required) Error message or description

**Returns:**
- 0 - Success
- 1 - AI error

**Output:**
- stdout - Fixed code with explanation

---

#### `_flow_ai_recipe_commit`

Generate commit message for staged changes.

**Signature:**

```zsh
_flow_ai_recipe_commit [--conventional]
```

**Parameters:**
- `--conventional` - Use conventional commit format

**Returns:**
- 0 - Success
- 1 - No changes or AI error

**Output:**
- stdout - Generated commit message

---

#### `_flow_ai_recipe_list`

List all available AI recipes.

**Signature:**

```zsh
_flow_ai_recipe_list
```

**Returns:**
- 0 - Always

**Output:**
- stdout - Formatted list of recipes with descriptions

---

#### `_flow_ai_recipe`

Main entry point for AI recipe execution.

**Signature:**

```zsh
_flow_ai_recipe <recipe_name> [args...]
```

**Parameters:**
- `$1` - (required) Recipe name: explain, review, test, document, fix, commit
- `$@` - Additional arguments passed to recipe

**Returns:**
- 0 - Recipe executed successfully
- 1 - Unknown recipe or error

---

### lib/ai-usage.zsh

**Functions:** 9
**Purpose:** AI command usage tracking and statistics

#### `_flow_ai_log_usage`

Log an AI command execution to usage tracking system.

**Signature:**

```zsh
_flow_ai_log_usage <command> <mode> <success> <duration>
```

**Parameters:**
- `$1` - (required) Command name: ai, do, recipe, chat
- `$2` - (required) Mode: default, explain, fix, suggest, create, recipe:\<name\>
- `$3` - (required) Success status: "true" or "false"
- `$4` - (required) Duration in milliseconds

**Returns:**
- 0 - Always succeeds (best-effort logging)

**Output:** None (writes to FLOW_AI_USAGE_FILE)

**Example:**

```zsh
_flow_ai_log_usage "recipe" "recipe:review" "true" "1523"
```

---

#### `_flow_ai_update_stats`

Update aggregated usage statistics.

**Signature:**

```zsh
_flow_ai_update_stats <command> <mode> <success>
```

**Parameters:**
- `$1` - (required) Command name
- `$2` - (required) Mode or recipe name
- `$3` - (required) Success status

**Returns:**
- 0 - Stats updated successfully

**Tracks:**
- total_calls, successful, failed
- commands.{cmd} - Count per command type
- modes.{mode} - Count per mode
- streak_days - Consecutive days of usage

---

#### `_flow_ai_get_stats`

Retrieve raw aggregated statistics JSON.

**Signature:**

```zsh
_flow_ai_get_stats
```

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - JSON object with usage statistics or "{}" if no data

---

#### `flow_ai_stats`

Display formatted AI usage statistics dashboard.

**Signature:**

```zsh
flow_ai_stats
```

**Output:**
- stdout - Formatted statistics dashboard with overview, top commands, top modes, top recipes

---

#### `flow_ai_suggest`

Provide personalized AI suggestions based on usage.

**Signature:**

```zsh
flow_ai_suggest
```

**Output:**
- stdout - Personalized suggestions based on project type and usage patterns

---

#### `flow_ai_recent`

Display recent AI command usage history.

**Signature:**

```zsh
flow_ai_recent [limit]
```

**Parameters:**
- `$1` - (optional) Number of entries to show [default: 10]

**Output:**
- stdout - List of recent commands with timestamps and status

---

#### `flow_ai_clear_history`

Delete all AI usage tracking data.

**Signature:**

```zsh
flow_ai_clear_history
```

**Returns:**
- 0 - History cleared or user declined

**Note:** Prompts for confirmation before deletion

---

#### `flow_ai_usage`

Main entry point for AI usage tracking commands.

**Signature:**

```zsh
flow_ai_usage [action] [args...]
```

**Parameters:**
- `$1` - (optional) Action: stats, suggest, recent, clear, help [default: stats]
- `$@` - Additional arguments passed to subcommand

**Returns:**
- 0 - Command executed successfully
- 1 - Unknown action

---

### Teaching Libraries Integration

**Command:** `teach analyze`
**Workflow:**
1. **Extract** concepts from .qmd frontmatter
2. **Validate** prerequisite chains (DAG)
3. **Cache** analysis results (SHA-256)
4. **Analyze** with Claude CLI (optional)
5. **Optimize** slide breaks (optional)
6. **Report** findings (Markdown/JSON)

**Performance:**
- Cached analysis: ~50-100ms
- Fresh analysis: ~2-5s (without AI)
- AI analysis: ~10-30s (depends on content length)

**Documentation:**
- Complete API: [TEACH-ANALYZE-API-REFERENCE.md](../reference/MASTER-API-REFERENCE.md#teaching-libraries)
- Architecture: [TEACH-ANALYZE-ARCHITECTURE.md](../reference/MASTER-ARCHITECTURE.md#component-design)
- Tutorial: [Tutorial 21](../tutorials/21-teach-analyze.md)
- Quick Ref: [REFCARD-TEACH-ANALYZE.md](../reference/MASTER-API-REFERENCE.md#teaching-libraries)

**Output Format:**

```json
{
  "concepts": [
    {
      "id": "linear-regression",
      "name": "Linear Regression",
      "bloom": "Understand",
      "complexity": "Medium",
      "prerequisites": ["basic-statistics"]
    }
  ]
}
```

**Example:**

```zsh
concepts=$(_teach_extract_concepts "lectures/week-01/regression.qmd")
echo "$concepts" | jq '.concepts[] | .name'
```

---

### Analysis Cache

#### `_teach_cache_get`

Retrieves cached analysis result.

**Signature:**

```zsh
_teach_cache_get "file.qmd"
```

**Parameters:**
- `$1` - File path

**Returns:**
- 0 - Cache hit, outputs cached data
- 1 - Cache miss

**Caching Strategy:**
- SHA-256 hash of file content
- flock for concurrent access
- 24-hour TTL

**Example:**

```zsh
if cached=$(_teach_cache_get "lecture.qmd"); then
    echo "Using cached analysis"
    echo "$cached"
else
    echo "Cache miss, analyzing..."
    result=$(_teach_analyze_file "lecture.qmd")
    _teach_cache_set "lecture.qmd" "$result"
fi
```

---

## Function Index

**Auto-generated alphabetical index will appear here after running:**

```bash
./scripts/generate-api-docs.sh
```

### A

- `_flow_atlas_connect` - Connect to Atlas state engine
- `_flow_atlas_disconnect` - Disconnect from Atlas
- `_flow_atlas_query` - Query Atlas database

### B

### C

- `_flow_cache_clear` - Clear project cache
- `_flow_cache_get` - Get cached value
- `_flow_cache_set` - Set cache value
- `_flow_color_blue` - Blue text output
- `_flow_color_green` - Green text output
- `_flow_color_red` - Red text output
- `_flow_color_yellow` - Yellow text output

### D

- `_flow_detect_project_type` - Detect project type from directory

### E

### F

- `_flow_find_project_root` - Find git repository root

### G

- `_flow_git_current_branch` - Get current git branch
- `_flow_git_is_clean` - Check if working tree is clean
- `_flow_git_validate_token` - Validate GitHub token

### H-Z

**[Will be auto-generated by scripts/generate-api-docs.sh]**

---

## Change Log

### v5.17.0-dev (Current)

**Added:**
- Token cache management (5-min TTL)
- `_flow_token_cache_get` - Get cached token status
- `_flow_token_cache_set` - Set token cache
- `_flow_token_validate` - Validate token with cache

**Changed:**
- `_flow_git_validate_token` now uses cache (80% API reduction)

**Deprecated:**
- None

**Removed:**
- None

---

### v6.6.0

**Added:**
- `_teach_map` - Display unified teaching ecosystem map (flow-cli + Scholar + Craft)
- `_teach_map_detect_tools` - Detect available teaching ecosystem tools (sets `_TEACH_MAP_TOOLS` associative array)

---

### v5.16.0

**Added:**
- Teaching analysis libraries (150+ functions)
- `_teach_extract_concepts` - Concept extraction from YAML
- `_teach_analyze_file` - AI-powered content analysis
- `_teach_cache_*` - SHA-256 cache with flock
- `_teach_report_*` - Markdown/JSON report generation

---

### v5.15.0

**Added:**
- Help system functions
- `_flow_help_show` - Display formatted help
- `_flow_help_section` - Display help section

---

## Contributing

### Adding New Functions

1. **Write function with documentation:**

   ```zsh
   # Description: What the function does
   # Parameters:
   #   $1 - First parameter description
   #   $2 - Second parameter (optional)
   # Returns:
   #   0 - Success
   #   1 - Error condition
   # Example:
   #   my_function "arg1" "arg2"
   function my_function() {
       # Implementation
   }
   ```

2. **Run documentation generator:**

   ```bash
   ./scripts/generate-api-docs.sh
   ```

3. **Test function:**

   ```bash
   source lib/my-library.zsh
   my_function "test" "args"
   ```

4. **Commit with API docs:**

   ```bash
   git add lib/my-library.zsh docs/reference/MASTER-API-REFERENCE.md
   git commit -m "feat: add my_function

   - Description of function
   - Updates API reference"
   ```

---

### Documentation Standards

**Function naming:**
- Private: `_flow_*` (underscore prefix)
- Public: `flow_*` (no underscore)
- Dispatcher: `<dispatcher>_*` (e.g., `g_feature_start`)

**Parameter documentation:**
- Always document all parameters
- Mark optional parameters
- Provide examples

**Return values:**
- Always document return codes
- 0 = success, non-zero = error
- Print output to stdout, errors to stderr

---

## Commands Internal API

**Purpose:** Internal helper functions for command implementations
**Audience:** Developers, contributors
**Note:** These are not meant to be called directly by users

### doctor Command Helpers

**File:** `commands/doctor.zsh`
**Functions:** 7 (v5.17.0 token automation)

#### `_doctor_log_quiet`

Log message unless in quiet mode.

**Signature:**

```zsh
_doctor_log_quiet <message>
```

**Parameters:**
- `$@` - Message to log

**Behavior:**
- Logs message in normal and verbose modes
- Suppresses output in quiet mode (`--quiet` flag)

**Example:**

```zsh
_doctor_log_quiet "Checking GitHub token..."
```

---

#### `_doctor_log_verbose`

Log message only in verbose mode.

**Signature:**

```zsh
_doctor_log_verbose <message>
```

**Parameters:**
- `$@` - Message to log

**Behavior:**
- Logs message only when `--verbose` flag is used
- Silent in normal and quiet modes

**Example:**

```zsh
_doctor_log_verbose "Cache hit for token-github (expires in 240s)"
```

---

#### `_doctor_log_always`

Log message regardless of verbosity level.

**Signature:**

```zsh
_doctor_log_always <message>
```

**Parameters:**
- `$@` - Message to log

**Behavior:**
- Always logs message (quiet, normal, verbose)
- Used for critical messages and errors

**Example:**

```zsh
_doctor_log_always "Error: Invalid token"
```

---

#### `_doctor_select_fix_category`

Show ADHD-friendly menu for selecting which category to fix.

**Signature:**

```zsh
_doctor_select_fix_category [token_only] [auto_yes]
```

**Parameters:**
- `$1` - (optional) Token-only mode (true/false) [default: false]
- `$2` - (optional) Auto-yes mode (true/false) [default: false]

**Returns:**
- 0 - Category selected (outputs category name to stdout)
- 1 - User cancelled
- 2 - No issues found

**Output:**
- stdout - Selected category name ("tokens", "required", "recommended", "aliases", "all")

**Features:**
- Visual hierarchy with time estimates
- Single category auto-selection
- Auto-yes mode for CI/CD
- Exit option (0)

**Example Menu:**

```text
╭─ Select Category to Fix ────────────────────────╮
│                                                  │
│  1. 🔑 GitHub Token (1 issue, ~30s)             │
│  2. 📦 Missing Tools (3 tools, ~1m 30s)         │
│  3. ⚡ Aliases (2 issues, ~10s)                 │
│                                                  │
│  4. ✨ Fix All Categories (~2m 10s)             │
│                                                  │
│  0. Exit without fixing                          │
│                                                  │
╰──────────────────────────────────────────────────╯
```

**Example:**

```zsh
selected=$(_doctor_select_fix_category false false)
if [[ $? -eq 0 ]]; then
    echo "User selected: $selected"
fi
```

---

#### `_doctor_count_categories`

Count total number of categories with issues.

**Signature:**

```zsh
_doctor_count_categories
```

**Parameters:**
- None

**Returns:**
- stdout - Number of categories with issues (0-3)

**Categories:**
- Tokens (GitHub API tokens)
- Tools (Homebrew, npm, pip packages)
- Aliases (Shell aliases)

**Example:**

```zsh
count=$(_doctor_count_categories)
if [[ $count -eq 0 ]]; then
    echo "No issues found"
fi
```

---

#### `_doctor_apply_fixes`

Apply fixes for selected category.

**Signature:**

```zsh
_doctor_apply_fixes <category> [auto_yes]
```

**Parameters:**
- `$1` - (required) Category to fix ("tokens", "tools", "aliases", "all")
- `$2` - (optional) Auto-yes mode [default: false]

**Behavior:**
- Tokens: Calls `_doctor_fix_tokens`
- Tools: Calls `_doctor_interactive_fix`
- Aliases: Shows message (not yet implemented)
- All: Applies fixes to all categories sequentially

**Example:**

```zsh
_doctor_apply_fixes "tokens"
_doctor_apply_fixes "all" true  # Auto-yes mode
```

---

#### `_doctor_fix_tokens`

Fix token-related issues (missing, invalid, expiring).

**Signature:**

```zsh
_doctor_fix_tokens
```

**Parameters:**
- None (uses global `_doctor_token_issues` array)

**Behavior:**
- **missing** - Generates new token via `dot token github`
- **invalid** - Rotates token via `dot token rotate`
- **expiring** - Rotates token via `dot token rotate`

**Side Effects:**
- Invalidates token cache
- May prompt for GitHub authentication
- Updates keychain secrets

**Example:**

```zsh
# Called internally by doctor --fix or doctor --fix-token
_doctor_fix_tokens
```

---

### work Command Helpers

**File:** `commands/work.zsh`
**Functions:** 3 (v5.17.0 token automation)

#### `_work_project_uses_github`

Check if project uses GitHub as remote.

**Signature:**

```zsh
_work_project_uses_github <project_path>
```

**Parameters:**
- `$1` - (required) Path to project directory

**Returns:**
- 0 - Project uses GitHub remote
- 1 - No GitHub remote found

**Example:**

```zsh
if _work_project_uses_github "$HOME/projects/my-repo"; then
    echo "Project uses GitHub"
fi
```

---

#### `_work_get_token_status`

Get GitHub token status for work session.

**Signature:**

```zsh
_work_get_token_status
```

**Parameters:**
- None (uses keychain token)

**Returns:**
- stdout - Token status string

**Status Values:**
- `"not configured"` - No token found in keychain
- `"expired/invalid"` - Token doesn't authenticate (HTTP != 200)
- `"expiring in N days"` - Token valid but expires soon (< 7 days)
- `"ok"` - Token valid with sufficient time remaining

**Example:**

```zsh
status=$(_work_get_token_status)
case "$status" in
    "not configured")
        echo "⚠️  Set up GitHub token: dot token github"
        ;;
    "expired/invalid")
        echo "⚠️  Token expired, rotate: dot token rotate"
        ;;
    "expiring in "*)
        echo "⚠️  $status"
        ;;
    "ok")
        echo "✓ GitHub token valid"
        ;;
esac
```

---

#### `_work_will_push_to_remote`

Check if current branch will push to remote.

**Signature:**

```zsh
_work_will_push_to_remote
```

**Parameters:**
- None (checks current git branch)

**Returns:**
- 0 - Branch tracks a remote (will push)
- 1 - No remote tracking (local-only branch)

**Use Case:**
- Determine if token validation needed before `work` session
- Skip token check for local-only work

**Example:**

```zsh
if _work_will_push_to_remote; then
    # Validate token before allowing push
    if ! _flow_git_validate_token; then
        echo "Invalid token, cannot push"
        return 1
    fi
fi
```

---

### dot Dispatcher Helpers

**File:** `lib/dispatchers/dot-dispatcher.zsh`
**Functions:** 5 (v5.17.0 token automation)

#### `_dot_token_expiring`

Check all GitHub tokens for expiration status.

**Signature:**

```zsh
_dot_token_expiring
```

**Parameters:**
- None (scans all GitHub tokens in keychain)

**Returns:**
- 0 - No expiring tokens
- 1 - Expiring or expired tokens found

**Output:**
- Lists expiring tokens (< 7 days)
- Lists expired tokens (invalid)

**Example:**

```zsh
dot token expiring
# Shows tokens expiring in < 7 days
```

---

#### `_dot_token_age_days`

Get token age in days since creation.

**Signature:**

```zsh
_dot_token_age_days <secret_name>
```

**Parameters:**
- `$1` - (required) Secret name (e.g., "github-token")

**Returns:**
- stdout - Age in days (integer)
- stdout - 90 if no creation metadata (flags for rotation)

**Implementation:**
- Reads creation timestamp from keychain metadata
- Parses JSON metadata field
- Calculates days elapsed

**Example:**

```zsh
age_days=$(_dot_token_age_days "github-token")
if [[ $age_days -gt 80 ]]; then
    echo "Token is $age_days days old, consider rotating"
fi
```

---

#### `_dot_token_rotate`

Rotate GitHub token (delete old, create new).

**Signature:**

```zsh
_dot_token_rotate [token_name]
```

**Parameters:**
- `$1` - (optional) Token name [default: "github-token"]

**Returns:**
- 0 - Rotation successful
- 1 - Rotation failed

**Workflow:**
1. Verify old token exists
2. Validate old token (get username)
3. Generate new token via `gh` CLI
4. Store new token in keychain with metadata
5. Invalidate doctor cache
6. Sync to `gh` CLI config
7. Log rotation event

**Side Effects:**
- Creates rotation log entry
- Clears doctor cache for the provider
- Updates keychain
- Syncs gh CLI configuration

**Example:**

```zsh
dot token rotate github-token
# Rotates token automatically
```

---

#### `_dot_token_log_rotation`

Log token rotation event.

**Signature:**

```zsh
_dot_token_log_rotation <provider> <old_username> <new_username>
```

**Parameters:**
- `$1` - (required) Provider name (e.g., "github")
- `$2` - (required) Old token username
- `$3` - (required) New token username

**Log Format:**

```text
[2026-01-23T12:30:00Z] ROTATION github old_user→new_user
```

**Log Location:**
- `~/.flow/logs/token-rotations.log`

**Example:**

```zsh
_dot_token_log_rotation "github" "user" "user"
```

---

#### `_dot_token_sync_gh`

Sync token to gh CLI configuration.

**Signature:**

```zsh
_dot_token_sync_gh <token>
```

**Parameters:**
- `$1` - (required) GitHub token value

**Returns:**
- 0 - Sync successful
- 1 - gh CLI not available

**Behavior:**
- Configures `gh auth login` with provided token
- Uses `gh` CLI's token storage
- Enables `gh` commands to work seamlessly

**Example:**

```zsh
token=$(dot secret github-token)
_dot_token_sync_gh "$token"
```

---

### g Dispatcher Helpers

**File:** `lib/dispatchers/g-dispatcher.zsh`
**Functions:** 2 (v5.17.0 token automation)

#### `_g_is_github_remote`

Check if current repository has GitHub remote.

**Signature:**

```zsh
_g_is_github_remote
```

**Parameters:**
- None (checks current directory git repo)

**Returns:**
- 0 - GitHub remote found
- 1 - No GitHub remote

**Use Case:**
- Determine if token validation needed before `g push`
- Skip token check for non-GitHub remotes

**Example:**

```zsh
if _g_is_github_remote; then
    # Validate token before push
    _g_validate_github_token_silent || {
        echo "Invalid token"
        return 1
    }
fi
```

---

#### `_g_validate_github_token_silent`

Quick token validation without output.

**Signature:**

```zsh
_g_validate_github_token_silent
```

**Parameters:**
- None (uses keychain token)

**Returns:**
- 0 - Token valid (HTTP 200)
- 1 - Token missing, expired, or invalid

**Caching:**
- Uses doctor cache (5-min TTL) if available
- Falls back to API call if cache miss

**Performance:**
- Cached: ~50-80ms
- Uncached: ~2-3s (API roundtrip)

**Example:**

```zsh
if _g_validate_github_token_silent; then
    git push origin dev
else
    echo "Invalid token, run: dot token rotate"
    return 1
fi
```

---

### teach-plan Command Helpers

**File:** `commands/teach-plan.zsh`
**Functions:** 7 (v5.22.0 lesson plan CRUD)

#### `_teach_plan`

Main dispatcher for lesson plan subcommands.

**Signature:**

```zsh
_teach_plan <action> [args...]
```

**Parameters:**
- `$1` - Action: `create|c|new`, `list|ls|l`, `show|s|view`, `edit|e`, `delete|del|rm`, `help`
- `$@` - Remaining arguments passed to subcommand

**Returns:**
- 0 on success
- 1 on error or unknown action

**Behavior:**
- Bare number argument (e.g., `_teach_plan 5`) dispatches to `_teach_plan_show`
- Unknown action returns error with help hint

---

#### `_teach_plan_create`

Create a new week entry in `.flow/lesson-plans.yml`.

**Signature:**

```zsh
_teach_plan_create <week> [--topic TOPIC] [--style STYLE] [--force]
```

**Parameters:**
- `$1` - (required) Week number (1-20)
- `--topic|-t` - Topic name (prompted interactively if omitted)
- `--style|-s` - Content style: `conceptual`, `computational`, `rigorous`, `applied`
- `--force|-f` - Overwrite existing week entry

**Returns:**
- 0 on success
- 1 on validation error, duplicate week, or missing `.flow` directory

**Behavior:**
- Auto-creates `lesson-plans.yml` if missing (requires `.flow/` dir)
- Auto-populates topic from `.flow/teach-config.yml` when `--topic` omitted
- Uses `yq strenv()` for YAML-injection-safe string construction
- Creates backup before modification, restores on validation failure
- Sorts weeks by number after insertion
- Prompts interactively for topic, style, objectives, subtopics when not provided via flags

**Dependencies:** `yq`

---

#### `_teach_plan_list`

List all week entries in `.flow/lesson-plans.yml`.

**Signature:**

```zsh
_teach_plan_list [--json]
```

**Parameters:**
- `--json|-j` - Output as JSON array instead of formatted table

**Returns:**
- 0 on success (including empty list)
- 1 if `yq` not found

**Output:**
- Table with columns: Week, Topic, Style, Objectives count
- Total week count
- Gap detection (warns about missing weeks in sequence)

---

#### `_teach_plan_show`

Display a single week's lesson plan details.

**Signature:**

```zsh
_teach_plan_show <week> [--json]
```

**Parameters:**
- `$1` - (required) Week number
- `--json|-j` - Output as JSON object

**Returns:**
- 0 on success
- 1 if week not found or file missing

**Output:**
- Formatted display with: topic, style, objectives, subtopics, key concepts, prerequisites
- Edit/delete hints

---

#### `_teach_plan_edit`

Open `.flow/lesson-plans.yml` in `$EDITOR`, jumping to the specified week's line.

**Signature:**

```zsh
_teach_plan_edit <week>
```

**Parameters:**
- `$1` - (required) Week number

**Returns:**
- 0 on successful edit with valid YAML
- 1 if week not found, file missing, or max retries exceeded

**Behavior:**
- Detects editor type (vim/nano/code) for line-jump syntax
- Validates YAML after each edit
- Bounded retry loop (max 3 attempts) on invalid YAML
- Prompts to re-open editor or abort

---

#### `_teach_plan_delete`

Remove a week entry from `.flow/lesson-plans.yml`.

**Signature:**

```zsh
_teach_plan_delete <week> [--force]
```

**Parameters:**
- `$1` - (required) Week number
- `--force|-f` - Skip confirmation prompt

**Returns:**
- 0 on success
- 1 if week not found or deletion fails

---

#### `_teach_plan_help`

Display formatted help for all teach plan commands.

**Signature:**

```zsh
_teach_plan_help
```

**Output:** Usage, actions, options, shortcuts, examples, file locations, see-also references.

---

### teach-deploy v2 Helpers

**Source:** `lib/deploy-history-helpers.zsh`, `lib/deploy-rollback-helpers.zsh`, `lib/dispatchers/teach-deploy-enhanced.zsh`
**Added:** v6.4.0

#### Deploy History (`lib/deploy-history-helpers.zsh`)

Append-only YAML deploy history tracking at `.flow/deploy-history.yml`.

| Function | Signature | Purpose |
|----------|-----------|---------|
| `_deploy_history_append` | `<mode> <commit_hash> <commit_before> <branch_from> <branch_to> <file_count> <commit_message> [pr_number] [tag] [duration]` | Append deploy entry (never rewrites file) |
| `_deploy_history_list` | `[count]` | Display recent deploys as formatted table (default: 5) |
| `_deploy_history_get` | `<display_index>` | Retrieve entry by display index (1=most recent). Sets `DEPLOY_HIST_*` variables |
| `_deploy_history_count` | (none) | Print total number of recorded deploys |

**Exported variables** (from `_deploy_history_get`):

`DEPLOY_HIST_TIMESTAMP`, `DEPLOY_HIST_MODE`, `DEPLOY_HIST_COMMIT`, `DEPLOY_HIST_COMMIT_BEFORE`, `DEPLOY_HIST_BRANCH_FROM`, `DEPLOY_HIST_BRANCH_TO`, `DEPLOY_HIST_FILE_COUNT`, `DEPLOY_HIST_MESSAGE`, `DEPLOY_HIST_PR`, `DEPLOY_HIST_TAG`, `DEPLOY_HIST_USER`, `DEPLOY_HIST_DURATION`

#### Deploy Rollback (`lib/deploy-rollback-helpers.zsh`)

Forward rollback via `git revert` with history tracking.

| Function | Signature | Purpose |
|----------|-----------|---------|
| `_deploy_rollback` | `[N] [--ci]` | Main rollback with interactive picker. N=display index (1=most recent) |
| `_deploy_perform_rollback` | `<commit_hash> <branch> <original_message> <ci_mode>` | Execute forward rollback. Detects merge commits (parent count > 1) and uses `-m 1` |

#### Deploy Orchestration (`lib/dispatchers/teach-deploy-enhanced.zsh`)

| Function | Signature | Purpose |
|----------|-----------|---------|
| `_deploy_preflight_checks` | `<ci_mode>` | Validate git state, config, branches. Sets `DEPLOY_*` variables |
| `_deploy_direct_merge` | `<draft_branch> <prod_branch> <commit_message> <ci_mode>` | Direct merge deploy (push draft, checkout prod, merge, push) |
| `_deploy_step` | `<step> <total> <label> <step_status>` | Print numbered step progress line (v6.4.1) |
| `_deploy_summary_box` | `<mode> <file_count> <insertions> <deletions> <duration> <commit_hash> [url]` | Print deployment summary box (v6.4.1) |
| `_deploy_dry_run_report` | (reads `DEPLOY_*` globals) | Preview deploy without side effects |
| `_deploy_update_status_file` | (reads `.STATUS` + history) | Update `.STATUS` with `last_deploy`, `deploy_count`, `teaching_week` |
| `_teach_deploy_enhanced` | `[flags...]` | Main entry point. Parses flags, dispatches to deploy/rollback/history/dry-run |
| `_deploy_cleanup_globals` | (none) | Unset all `DEPLOY_*` exported variables |
| `_teach_deploy_enhanced_help` | (none) | Print formatted help output |
| `_check_prerequisites_for_deploy` | (none) | Verify `git` and optional `yq` are available |

**`_deploy_step`** (v6.4.1)

```zsh
_deploy_step <step> <total> <label> <step_status>
# step_status: "done" (✓), "active" (⏳), "fail" (✗)

_deploy_step 1 5 "Push draft to origin" done
# Output: ✓ [1/5] Push draft to origin
```

**`_deploy_summary_box`** (v6.4.1)

```zsh
_deploy_summary_box <mode> <file_count> <insertions> <deletions> <duration> <commit_hash> [url]

_deploy_summary_box "Direct merge" 3 45 12 11 "a1b2c3d4" "https://example.github.io/stat-545/"
# Output: Unicode box with mode, files, duration, commit, URL
```

URL line is omitted when `$url` is empty or `"null"`.

**Exported variables** (from `_deploy_direct_merge` and `_deploy_perform_rollback`):

`DEPLOY_COMMIT_BEFORE`, `DEPLOY_COMMIT_AFTER`, `DEPLOY_DURATION`, `DEPLOY_MODE`, `DEPLOY_FILE_COUNT`, `DEPLOY_INSERTIONS`, `DEPLOY_DELETIONS`, `DEPLOY_SHORT_HASH`

---

## See Also

- [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md) - Complete dispatcher reference
- [MASTER-ARCHITECTURE.md](MASTER-ARCHITECTURE.md) - System architecture
- [CONVENTIONS.md](../CONVENTIONS.md) - Coding conventions
- [CONTRIBUTING.md](../contributing/CONTRIBUTING.md) - Contributing guide

---

**Version:** v5.22.0-dev
**Last Updated:** 2026-01-29
**Auto-Generation:** Run `./scripts/generate-api-docs.sh` to update function index
**Total Functions:** 860 (428 documented, 432 pending)
