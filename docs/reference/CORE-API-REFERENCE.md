# Core API Reference

> Complete reference for flow-cli's core helper libraries: logging, TUI components, and git integration.

**Version:** 5.15.1
**Last Updated:** 2026-01-22
**Libraries Covered:** `lib/core.zsh`, `lib/tui.zsh`, `lib/git-helpers.zsh`

---

## Table of Contents

1. [Core Library (lib/core.zsh)](#core-library)
   - [Logging Functions](#logging-functions)
   - [Status Icons](#status-icons)
   - [Path Utilities](#path-utilities)
   - [Time Utilities](#time-utilities)
   - [Input Helpers](#input-helpers)
   - [Array Utilities](#array-utilities)
   - [File Utilities](#file-utilities)
2. [TUI Library (lib/tui.zsh)](#tui-library)
   - [Progress Indicators](#progress-indicators)
   - [Tables](#tables)
   - [Boxes & Panels](#boxes-panels)
   - [FZF Integration](#fzf-integration)
   - [Gum Integration](#gum-integration)
   - [Dashboard Widgets](#dashboard-widgets)
   - [Spinner / Loading](#spinner-loading)
3. [Git Helpers (lib/git-helpers.zsh)](#git-helpers)
   - [Repository Status](#repository-status)
   - [Branch Information](#branch-information)
   - [Teaching Content](#teaching-content)
   - [Deployment Workflow](#deployment-workflow)
4. [Color Palette](#color-palette)
5. [Best Practices](#best-practices)

---

## Core Library

**File:** `lib/core.zsh`
**Purpose:** Colors, logging, common utilities
**Functions:** 14

### Logging Functions

#### _flow_log

Base logging function with color support.

```zsh
_flow_log <level> <message...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Log level: `success`, `warning`, `error`, `info`, `debug` |
| `$@` | string | Yes | Message to display |

**Returns:** `0` (always succeeds)

**Example:**
```zsh
_flow_log success "Operation completed"
_flow_log error "Something went wrong"
_flow_log info "Processing 5 files..."
```

**Notes:**
- Uses `FLOW_COLORS` associative array for level-to-color mapping
- Falls back to `info` color if level not recognized

---

#### _flow_log_success

Log success message with green checkmark.

```zsh
_flow_log_success <message...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$@` | string | Yes | Message to display |

**Output:** `✓ message` (in green)

**Example:**
```zsh
_flow_log_success "Build completed"
# Output: ✓ Build completed
```

---

#### _flow_log_warning

Log warning message with yellow warning symbol.

```zsh
_flow_log_warning <message...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$@` | string | Yes | Message to display |

**Output:** `⚠ message` (in yellow)

**Example:**
```zsh
_flow_log_warning "Config file not found, using defaults"
# Output: ⚠ Config file not found, using defaults
```

---

#### _flow_log_error

Log error message with red X symbol.

```zsh
_flow_log_error <message...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$@` | string | Yes | Message to display |

**Output:** `✗ message` (in red)

**Example:**
```zsh
_flow_log_error "Connection failed"
# Output: ✗ Connection failed
```

---

#### _flow_log_info

Log informational message with blue info symbol.

```zsh
_flow_log_info <message...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$@` | string | Yes | Message to display |

**Output:** `ℹ message` (in blue)

**Example:**
```zsh
_flow_log_info "Processing 5 files..."
# Output: ℹ Processing 5 files...
```

---

#### _flow_log_muted

Log muted/gray text without prefix symbol.

```zsh
_flow_log_muted <message...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$@` | string | Yes | Message to display |

**Output:** `message` (in gray)

**Example:**
```zsh
_flow_log_muted "Last updated: 2 hours ago"
# Output: Last updated: 2 hours ago (gray text)
```

---

#### _flow_log_debug

Log debug message (only when `FLOW_DEBUG` is set).

```zsh
_flow_log_debug <message...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$@` | string | Yes | Message to display |

**Returns:** `0` (always succeeds)

**Output:** `[debug] message` (in gray, only if `FLOW_DEBUG` is set)

**Example:**
```zsh
export FLOW_DEBUG=1
_flow_log_debug "Variable value: $var"
# Output: [debug] Variable value: foo

unset FLOW_DEBUG
_flow_log_debug "This won't show"
# (no output)
```

**Notes:**
- Silent when `FLOW_DEBUG` is unset or empty
- Useful for troubleshooting without cluttering normal output

---

### Status Icons

#### _flow_status_icon

Convert project status string to emoji indicator.

```zsh
_flow_status_icon <status>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Status string (case-insensitive) |

**Returns:** `0` (always succeeds)

**Output:** Single emoji character

| Input | Output | Meaning |
|-------|--------|---------|
| `active` or `ACTIVE` | 🟢 | Active/working |
| `paused` or `PAUSED` | 🟡 | Temporarily paused |
| `blocked` or `BLOCKED` | 🔴 | Blocked by issue |
| `archived` or `ARCHIVED` | ⚫ | Archived/completed |
| `stalled` | 🟠 | Stalled (needs attention) |
| (other) | ⚪ | Unknown status |

**Example:**
```zsh
icon=$(_flow_status_icon "active")   # 🟢
icon=$(_flow_status_icon "PAUSED")   # 🟡
icon=$(_flow_status_icon "unknown")  # ⚪
```

---

### Path Utilities

#### _flow_project_name

Extract project name (directory name) from a path.

```zsh
_flow_project_name [path]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | No | `$PWD` | Path to extract name from |

**Returns:** `0` (always succeeds)

**Output:** Project name (last component of path)

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

#### _flow_find_project_root

Find project root by searching upward for `.STATUS` or `.git`.

```zsh
_flow_find_project_root [start_path]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | No | `$PWD` | Starting directory |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Project root found |
| `1` | No project root found (reached filesystem root) |

**Output:** Absolute path to project root

**Example:**
```zsh
root=$(_flow_find_project_root)
if [[ $? -eq 0 ]]; then
    echo "Project root: $root"
else
    echo "Not in a project"
fi

# Start from specific directory
root=$(_flow_find_project_root "/Users/dt/projects/flow-cli/lib")
```

**Notes:**
- Searches for `.STATUS` file (flow-cli project marker)
- Falls back to `.git/config` (standard git repo)
- Uses ZSH `:h` modifier (head/dirname equivalent)

---

#### _flow_in_project

Check if current directory is inside a flow-cli project.

```zsh
_flow_in_project
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Currently in a project directory |
| `1` | Not in a project directory |

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

### Time Utilities

#### _flow_format_duration

Convert seconds to human-readable duration string.

```zsh
_flow_format_duration <seconds>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | integer | Yes | Duration in seconds |

**Returns:** `0` (always succeeds)

**Output:** Formatted duration string

| Input | Output |
|-------|--------|
| `45` | `45s` |
| `125` | `2m` |
| `3725` | `1h 2m` |
| `7200` | `2h 0m` |

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

#### _flow_time_ago

Convert Unix timestamp to relative time string.

```zsh
_flow_time_ago <timestamp>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | integer | Yes | Unix timestamp (seconds since epoch) |

**Returns:** `0` (always succeeds)

**Output:** Relative time string

| Time Difference | Output |
|-----------------|--------|
| < 60 seconds | `just now` |
| 5 minutes | `5m ago` |
| 2 hours | `2h ago` |
| 2 days | `2d ago` |

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

#### _flow_confirm

Display yes/no confirmation prompt with sensible defaults.

```zsh
_flow_confirm [prompt] [default]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | No | `Continue?` | Prompt message |
| `$2` | string | No | `n` | Default answer (`y` or `n`) |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | User answered yes |
| `1` | User answered no |

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

#### _flow_array_contains

Check if a value exists in an array.

```zsh
_flow_array_contains <needle> <haystack...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Value to search for |
| `$@` | strings | Yes | Array elements to search |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Value found in array |
| `1` | Value not found |

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

#### _flow_read_file

Safely read file contents (no error if file doesn't exist).

```zsh
_flow_read_file <file_path>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Path to file |

**Returns:** `0` (always succeeds)

**Output:** File contents, or empty if file doesn't exist

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

#### _flow_get_config

Read a value from a key=value format config file.

```zsh
_flow_get_config <file> <key> [default]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | Yes | - | Path to config file |
| `$2` | string | Yes | - | Key to look up |
| `$3` | string | No | empty | Default value if not found |

**Returns:** `0` (always succeeds)

**Output:** Value for key, or default if not found

**Example:**
```zsh
# Simple lookup with default
local theme=$(_flow_get_config ~/.myconfig "theme" "dark")

# Check if key exists
local value=$(_flow_get_config "$file" "api_key")
[[ -z "$value" ]] && echo "API key not configured"
```

**File Format:**
```ini
theme=dark
timeout=30
# Comments are ignored via grep pattern
```

**Notes:**
- Expects `key=value` format (no spaces around `=`)
- Returns default if file doesn't exist or key not found
- Uses `command grep/cut` to avoid alias interference

---

## TUI Library

**File:** `lib/tui.zsh`
**Purpose:** Terminal UI components (progress, tables, pickers)
**Functions:** 16

### Progress Indicators

#### _flow_progress_bar

Draw an ASCII progress bar with percentage.

```zsh
_flow_progress_bar <current> <total> [width] [filled_char] [empty_char]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | integer | Yes | - | Current value |
| `$2` | integer | Yes | - | Total/maximum value |
| `$3` | integer | No | `20` | Bar width in characters |
| `$4` | string | No | `█` | Filled character |
| `$5` | string | No | `░` | Empty character |

**Returns:** `0` (always succeeds)

**Output:** Progress bar with percentage (e.g., `████████░░░░ 67%`)

**Example:**
```zsh
# Basic usage
echo "Progress: $(_flow_progress_bar 7 10)"
# Output: Progress: ██████████████░░░░░░ 70%

# Custom width and characters
_flow_progress_bar 50 100 30 "=" "-"
# Output: ===============--------------- 50%
```

---

#### _flow_sparkline

Generate a sparkline graph from numeric values.

```zsh
_flow_sparkline <values...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$@` | integers | Yes | Numeric values |

**Returns:** `0` (always succeeds)

**Output:** Sparkline string using Unicode block characters

**Character Set:** `▁▂▃▄▅▆▇█` (8 levels from lowest to highest)

**Example:**
```zsh
_flow_sparkline 1 3 5 7 5 3 1
# Output: ▁▃▅▇▅▃▁

# From array
local -a commits=(2 4 8 12 6 3 1)
_flow_sparkline "${commits[@]}"
# Output: ▁▂▄█▃▂▁
```

**Notes:**
- Auto-scales to min/max of input values
- Handles flat data (all same values) gracefully
- Useful for visualizing trends in dashboards

---

### Tables

#### _flow_table

Display formatted table with headers and rows.

```zsh
_flow_table <headers> <rows...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Comma-separated header columns |
| `$@` | strings | Yes | Comma-separated row data |

**Returns:** `0` (always succeeds)

**Output:** Formatted table with colored headers

**Example:**
```zsh
_flow_table "Name,Status,Time" \
    "flow-cli,active,2h" \
    "project-b,paused,1d" \
    "project-c,archived,5d"

# Output:
# Name                 Status               Time
# ────────────────────────────────────────────────────────────
# flow-cli             active               2h
# project-b            paused               1d
# project-c            archived             5d
```

**Notes:**
- Uses `FLOW_COLORS[header]` for header row
- Fixed 20-character column width
- Uses ZSH `${(s:,:)}` parameter expansion for splitting

---

### Boxes & Panels

#### _flow_box

Draw a Unicode box around text content.

```zsh
_flow_box [title] <content> [width]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | No | empty | Box title (in top border) |
| `$2` | string | Yes | - | Content text (can be multiline) |
| `$3` | integer | No | `50` | Box width |

**Returns:** `0` (always succeeds)

**Output:** Box with rounded corners containing content

**Example:**
```zsh
_flow_box "Project Info" "Name: flow-cli
Status: active
Time: 2h 30m"

# Output:
# ╭─ Project Info ────────────────────────────────╮
# │ Name: flow-cli                                │
# │ Status: active                                │
# │ Time: 2h 30m                                  │
# ╰──────────────────────────────────────────────╯
```

**Notes:**
- Uses Unicode box-drawing characters (`╭╮╰╯│─`)
- Content lines are padded to fit width
- Empty title shows plain top border

---

### FZF Integration

#### _flow_has_fzf

Check if fzf (fuzzy finder) is installed and available.

```zsh
_flow_has_fzf
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | fzf is available |
| `1` | fzf is not installed |

**Example:**
```zsh
if _flow_has_fzf; then
    local choice=$(echo "$options" | fzf)
else
    _flow_log_error "fzf required. Install: brew install fzf"
fi
```

---

#### _flow_pick_project

Interactive project picker using fzf with preview.

```zsh
_flow_pick_project
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | User selected a project |
| `1` | fzf not installed or user cancelled |

**Output:** Selected project name

**Example:**
```zsh
local project=$(_flow_pick_project)
if [[ -n "$project" ]]; then
    cd "$(_flow_project_path "$project")"
fi
```

**Dependencies:**
- `fzf` (required)
- `_flow_list_projects` (for project list)
- `_flow_show_project_preview` (for preview panel)

**Notes:**
- Shows interactive picker with 40% height
- Preview panel shows project details and `.STATUS`
- User can cancel with Esc/Ctrl-C (returns empty)

---

#### _flow_show_project_preview

Generate preview content for fzf project picker.

```zsh
_flow_show_project_preview <project>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Project name to preview |

**Returns:** `0` (always succeeds)

**Output:** Formatted project info with optional `.STATUS` content

**Notes:**
- Used as fzf preview command
- Shows first 20 lines of `.STATUS` file
- Gracefully handles missing projects

---

### Gum Integration

#### _flow_has_gum

Check if gum (glamorous shell tool) is installed.

```zsh
_flow_has_gum
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | gum is available |
| `1` | gum is not installed |

**Notes:**
- gum provides styled prompts, spinners, and inputs
- Install: `brew install gum`
- Functions fall back to basic ZSH when unavailable

---

#### _flow_input

Styled text input prompt (uses gum if available).

```zsh
_flow_input [prompt] [placeholder]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | No | `Enter value` | Prompt text |
| `$2` | string | No | empty | Placeholder text |

**Returns:** `0` (always succeeds)

**Output:** User input text

**Example:**
```zsh
local name=$(_flow_input "Project name" "my-project")
echo "Creating project: $name"
```

---

#### _flow_confirm_styled

Styled yes/no confirmation (uses gum if available).

```zsh
_flow_confirm_styled [prompt]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | No | `Continue?` | Prompt message |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | User confirmed (yes) |
| `1` | User declined (no) |

**Example:**
```zsh
if _flow_confirm_styled "Delete these files?"; then
    rm -rf ./cache
fi
```

---

#### _flow_choose

Multi-option selector (uses gum/fzf if available).

```zsh
_flow_choose <header> <options...>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Header/prompt text |
| `$@` | strings | Yes | Options to choose from |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | User made selection |
| `1` | No selection (cancelled) |

**Output:** Selected option text

**Example:**
```zsh
local status=$(_flow_choose "Set project status:" \
    "active" "paused" "blocked" "archived")
echo "Status set to: $status"
```

**Notes:**
- Tries gum first (prettiest)
- Falls back to fzf (still interactive)
- Final fallback to numbered list with read

---

### Dashboard Widgets

#### _flow_widget_status

Render a project status line for dashboards.

```zsh
_flow_widget_status <project> <status> [focus]
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Project name |
| `$2` | string | Yes | Status string |
| `$3` | string | No | Focus/description text |

**Returns:** `0` (always succeeds)

**Output:** Formatted status line with icon and colors

**Example:**
```zsh
_flow_widget_status "flow-cli" "active" "Adding documentation"
# Output: 🟢 flow-cli        │ Adding documentation

_flow_widget_status "project-b" "paused"
# Output: 🟡 project-b
```

---

#### _flow_widget_timer

Render elapsed session time widget.

```zsh
_flow_widget_timer <start_time>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | integer | Yes | Session start time (Unix timestamp) |

**Returns:** `0` (always succeeds)

**Output:** Timer display with emoji (e.g., `⏱️  2h 15m`)

**Example:**
```zsh
local session_start=1706789400
_flow_widget_timer "$session_start"
# Output: ⏱️  2h 15m
```

---

### Spinner / Loading

#### _flow_spinner_start

Start an animated spinner with message.

```zsh
_flow_spinner_start [message] [estimate]
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `$1` | string | No | `Working...` | Message to display |
| `$2` | string | No | empty | Time estimate (e.g., `~30-60s`) |

**Returns:** `0` (spinner started or already running)

**Global State:** Sets `FLOW_SPINNER_PID` to background process ID

**Animation Frames:** `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (Braille dots, cycles at ~100ms)

**Example:**
```zsh
_flow_spinner_start "Building project..." "~10s"
# ... long operation ...
_flow_spinner_stop "Build complete"
```

**Notes:**
- Only one spinner can run at a time
- Runs in background process
- Call `_flow_spinner_stop` to clean up

---

#### _flow_spinner_stop

Stop the running spinner and optionally show completion message.

```zsh
_flow_spinner_stop [message]
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | No | Success message to display |

**Returns:** `0` (always succeeds)

**Global State:** Clears `FLOW_SPINNER_PID`

**Example:**
```zsh
_flow_spinner_stop "Build complete"
# Output: ✓ Build complete (in green)

_flow_spinner_stop  # Just stop, no message
```

**Notes:**
- Safe to call even if no spinner running
- Clears the spinner line before showing message
- Success message shown with green checkmark

---

#### _flow_with_spinner

Execute a command while showing a spinner.

```zsh
_flow_with_spinner <message> <estimate> <command> [args...]
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Message to display |
| `$2` | string | Yes | Time estimate (use `""` for none) |
| `$@` | command | Yes | Command and arguments to execute |

**Returns:** Exit code of the executed command

**Output:** Command output (after spinner stops)

**Example:**
```zsh
_flow_with_spinner "Building..." "~10s" make build

_flow_with_spinner "Installing deps..." "" npm install

# Check result
if _flow_with_spinner "Testing..." "~30s" npm test; then
    echo "Tests passed!"
fi
```

**Notes:**
- Captures both stdout and stderr from command
- Spinner runs during command execution
- Command output displayed after completion
- Preserves original exit code

---

## Git Helpers

**File:** `lib/git-helpers.zsh`
**Purpose:** Git integration for teaching workflow
**Functions:** 17

### Repository Status

#### _git_in_repo

Check if current directory is inside a git repository.

```zsh
_git_in_repo
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | In a git repository |
| `1` | Not in a git repository |

**Example:**
```zsh
if _git_in_repo; then
    echo "Branch: $(_git_current_branch)"
else
    echo "Not a git repository"
fi
```

---

#### _git_is_clean

Check if working directory has no uncommitted changes.

```zsh
_git_is_clean
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Working directory is clean |
| `1` | Working directory is dirty |

**Example:**
```zsh
if _git_is_clean; then
    echo "Ready to switch branches"
else
    echo "Commit or stash changes first"
fi
```

**Notes:**
- Includes untracked files in "dirty" check
- Returns 1 if not in a git repository

---

#### _git_is_synced

Check if local branch is synchronized with remote.

```zsh
_git_is_synced
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Branch is synced |
| `1` | Branch is out of sync |

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

---

#### _git_has_unpushed_commits

Check if current branch has local commits not pushed to remote.

```zsh
_git_has_unpushed_commits
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Has unpushed commits |
| `1` | All commits pushed |

**Example:**
```zsh
if _git_has_unpushed_commits; then
    echo "You have local commits to push"
fi
```

---

### Branch Information

#### _git_current_branch

Get the name of the current git branch.

```zsh
_git_current_branch
```

**Returns:** `0` (always succeeds)

**Output:** Branch name, or empty if not in git repo

**Example:**
```zsh
local branch=$(_git_current_branch)
echo "Currently on: $branch"
```

**Special Cases:**
- Detached HEAD returns `HEAD`
- Not in repo returns empty string

---

#### _git_remote_branch

Get the upstream tracking branch name.

```zsh
_git_remote_branch
```

**Returns:** `0` (always succeeds)

**Output:** Remote branch name (e.g., `origin/main`), or empty

**Example:**
```zsh
local upstream=$(_git_remote_branch)
if [[ -n "$upstream" ]]; then
    echo "Tracking: $upstream"
else
    echo "No upstream configured"
fi
```

---

### Teaching Content

#### _git_teaching_commit_message

Generate standardized commit message for teaching content.

```zsh
_git_teaching_commit_message <type> <topic> <command> <course> <semester> <year>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Content type (exam, quiz, slides, etc.) |
| `$2` | string | Yes | Topic or title |
| `$3` | string | Yes | Command that generated content |
| `$4` | string | Yes | Course name (e.g., "STAT 545") |
| `$5` | string | Yes | Semester |
| `$6` | string | Yes | Year |

**Returns:** `0` (always succeeds)

**Output:** Formatted commit message

**Example:**
```zsh
msg=$(_git_teaching_commit_message "exam" "Hypothesis Testing" \
    "teach exam \"Hypothesis Testing\" --questions 20" \
    "STAT 545" "Fall" "2024")

# Output:
# teach: add exam for Hypothesis Testing
#
# Generated via: teach exam "Hypothesis Testing" --questions 20
# Course: STAT 545 (Fall 2024)
#
# Co-Authored-By: Scholar <scholar@example.com>
```

---

#### _git_teaching_files

Get list of uncommitted teaching-related files.

```zsh
_git_teaching_files
```

**Returns:** `0` (always succeeds)

**Output:** File paths (one per line), sorted and deduplicated

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

---

#### _git_commit_teaching_content

Commit staged files with a teaching-formatted message.

```zsh
_git_commit_teaching_content <message>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Commit message |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Commit successful |
| `1` | Error (no staged changes or commit failed) |

**Example:**
```zsh
git add exams/midterm.qmd
local msg=$(_git_teaching_commit_message "exam" "Midterm" ...)
_git_commit_teaching_content "$msg"
```

---

### Deployment Workflow

#### _git_create_deploy_pr

Create a pull request for teaching content deployment.

```zsh
_git_create_deploy_pr <draft_branch> <prod_branch> <title> <body>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Source branch (draft) |
| `$2` | string | Yes | Target branch (production) |
| `$3` | string | Yes | PR title |
| `$4` | string | Yes | PR body (markdown) |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | PR created successfully |
| `1` | Error (gh not installed or creation failed) |

**Dependencies:**
- `gh` CLI (GitHub CLI)
- `gh auth login` (authenticated)

**Example:**
```zsh
_git_create_deploy_pr "draft" "main" \
    "Deploy: Week 5 materials" \
    "$(cat pr-body.md)"
```

---

#### _git_detect_production_conflicts

Check if production branch has commits that could cause conflicts.

```zsh
_git_detect_production_conflicts <draft_branch> <prod_branch>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Draft branch name |
| `$2` | string | Yes | Production branch name |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | No conflicts |
| `1` | Potential conflicts (production has new commits) |

**Example:**
```zsh
if ! _git_detect_production_conflicts "draft" "main"; then
    echo "Warning: Production has new commits"
    echo "Consider rebasing before PR"
fi
```

---

#### _git_get_commit_count

Count commits in draft branch not yet in production.

```zsh
_git_get_commit_count <draft_branch> <prod_branch>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Draft branch name |
| `$2` | string | Yes | Production branch name |

**Returns:** `0` (always succeeds)

**Output:** Number of commits (integer)

**Example:**
```zsh
local count=$(_git_get_commit_count "draft" "main")
echo "Ready to deploy $count commits"
```

---

#### _git_get_commit_list

Get markdown-formatted list of commits for PR body.

```zsh
_git_get_commit_list <draft_branch> <prod_branch>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Draft branch name |
| `$2` | string | Yes | Production branch name |

**Returns:** `0` (always succeeds)

**Output:** Commit subjects as markdown list

**Example:**
```zsh
local commits=$(_git_get_commit_list "draft" "main")
# Output:
# - teach: add exam for Hypothesis Testing
# - teach: add lecture slides for Week 5
```

---

#### _git_generate_pr_body

Generate complete markdown PR body for deployment.

```zsh
_git_generate_pr_body <draft_branch> <prod_branch>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Draft branch name |
| `$2` | string | Yes | Production branch name |

**Returns:** `0` (always succeeds)

**Output:** Complete markdown PR body with commits, metadata, and checklist

**Example:**
```zsh
local body=$(_git_generate_pr_body "draft" "main")
gh pr create --body "$body" ...
```

---

#### _git_rebase_onto_production

Rebase draft branch onto latest production.

```zsh
_git_rebase_onto_production <draft_branch> <prod_branch>
```

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `$1` | string | Yes | Draft branch name |
| `$2` | string | Yes | Production branch name |

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Rebase successful |
| `1` | Error (conflicts) |

**Example:**
```zsh
if _git_rebase_onto_production "draft" "main"; then
    echo "Ready for clean merge"
else
    echo "Resolve conflicts manually"
fi
```

---

#### _git_push_current_branch

Push current branch to origin remote.

```zsh
_git_push_current_branch
```

**Returns:**
| Code | Meaning |
|------|---------|
| `0` | Push successful |
| `1` | Error |

**Example:**
```zsh
if _git_push_current_branch; then
    echo "Changes pushed"
fi
```

---

## Color Palette

flow-cli uses an ADHD-friendly color palette defined in `FLOW_COLORS`:

### Status Colors

| Key | Color | Hex | Usage |
|-----|-------|-----|-------|
| `success` | Soft green | `#87d787` | Success messages |
| `warning` | Warm yellow | `#ffd75f` | Warnings |
| `error` | Soft red | `#ff8787` | Errors |
| `info` | Calm blue | `#87d7ff` | Information |

### Project Status Colors

| Key | Color | Usage |
|-----|-------|-------|
| `active` | Green | Active projects |
| `paused` | Yellow | Paused projects |
| `blocked` | Red | Blocked projects |
| `archived` | Gray | Archived projects |

### UI Elements

| Key | Color | Usage |
|-----|-------|-------|
| `header` | Soft purple | Table headers |
| `accent` | Soft orange | Highlights |
| `muted` | Gray | Secondary text |
| `cmd` | Calm blue | Command names |

---

## Best Practices

### Using Logging Functions

```zsh
# Good: Use appropriate log levels
_flow_log_success "Build completed"
_flow_log_error "File not found: $path"
_flow_log_debug "Processing file: $file"

# Bad: Using echo directly
echo "Build completed"  # No color, no consistency
```

### Checking Dependencies

```zsh
# Good: Check before using optional tools
if _flow_has_fzf; then
    local project=$(_flow_pick_project)
else
    _flow_log_warning "fzf not installed, using basic selection"
    # fallback to numbered list
fi
```

### Using Spinners

```zsh
# Good: Use _flow_with_spinner for commands
_flow_with_spinner "Building..." "~10s" make build

# Or manual control for complex operations
_flow_spinner_start "Processing..."
# ... multiple operations ...
_flow_spinner_stop "Done"

# Bad: Forgetting to stop spinner
_flow_spinner_start "Working..."
# ... (exits early on error, spinner keeps running)
```

### Git Operations

```zsh
# Good: Check state before operations
if ! _git_in_repo; then
    _flow_log_error "Not in a git repository"
    return 1
fi

if ! _git_is_clean; then
    _flow_log_warning "Uncommitted changes detected"
fi
```

---

## See Also

- [Dispatcher Reference](DISPATCHER-REFERENCE.md) - Smart command dispatchers
- [Command Quick Reference](COMMAND-QUICK-REFERENCE.md) - User-facing commands
- [Architecture Overview](ARCHITECTURE-OVERVIEW.md) - System architecture
- [Testing Guide](../guides/TESTING.md) - Testing these functions

---

**Last Updated:** 2026-01-22
**Author:** Claude Opus 4.5
