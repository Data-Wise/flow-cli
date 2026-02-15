# lib/core.zsh - Core utilities for flow-cli
# Provides: colors, logging, common helpers

# ============================================================================
# COLORS (ADHD-friendly palette)
# ============================================================================

# Status colors
typeset -gA FLOW_COLORS
FLOW_COLORS=(
  [reset]='\033[0m'
  [bold]='\033[1m'
  [dim]='\033[2m'
  
  # Status indicators
  [success]='\033[38;5;114m'    # Soft green
  [warning]='\033[38;5;221m'    # Warm yellow  
  [error]='\033[38;5;203m'      # Soft red
  [info]='\033[38;5;117m'       # Calm blue
  
  # Project status
  [active]='\033[38;5;114m'     # Green
  [paused]='\033[38;5;221m'     # Yellow
  [blocked]='\033[38;5;203m'    # Red
  [archived]='\033[38;5;245m'   # Gray
  
  # UI elements
  [header]='\033[38;5;147m'     # Soft purple
  [accent]='\033[38;5;216m'     # Soft orange
  [muted]='\033[38;5;245m'      # Gray
  [cmd]='\033[38;5;117m'        # Calm blue (for command names)
)

# ============================================================================
# LOGGING
# ============================================================================

# =============================================================================
# Function: _flow_log
# Purpose: Base logging function with color support
# =============================================================================
# Arguments:
#   $1 - (required) Log level: success|warning|error|info|debug|muted
#   $@ - (required) Message to display
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Colored message with automatic reset
#
# Example:
#   _flow_log success "Operation completed"
#   _flow_log error "Something went wrong"
#
# Notes:
#   - Uses FLOW_COLORS associative array for level-to-color mapping
#   - Falls back to 'info' color if level not found
# =============================================================================
_flow_log() {
  local level="$1"
  shift
  local color="${FLOW_COLORS[$level]:-${FLOW_COLORS[info]}}"
  echo -e "${color}$*${FLOW_COLORS[reset]}"
}

# =============================================================================
# Function: _flow_log_success
# Purpose: Log success message with green checkmark
# =============================================================================
# Arguments:
#   $@ - (required) Message to display
#
# Example:
#   _flow_log_success "Build completed"
#   # Output: ✓ Build completed (in green)
# =============================================================================
_flow_log_success() { _flow_log success "✓ $*" }

# =============================================================================
# Function: _flow_log_warning
# Purpose: Log warning message with yellow warning symbol
# =============================================================================
# Arguments:
#   $@ - (required) Message to display
#
# Example:
#   _flow_log_warning "Config file not found, using defaults"
#   # Output: ⚠ Config file not found, using defaults (in yellow)
# =============================================================================
_flow_log_warning() { _flow_log warning "⚠ $*" }

# =============================================================================
# Function: _flow_log_error
# Purpose: Log error message with red X symbol
# =============================================================================
# Arguments:
#   $@ - (required) Message to display
#
# Example:
#   _flow_log_error "Connection failed"
#   # Output: ✗ Connection failed (in red)
# =============================================================================
_flow_log_error()   { _flow_log error "✗ $*" }

# =============================================================================
# Function: _flow_log_info
# Purpose: Log informational message with blue info symbol
# =============================================================================
# Arguments:
#   $@ - (required) Message to display
#
# Example:
#   _flow_log_info "Processing 5 files..."
#   # Output: ℹ Processing 5 files... (in blue)
# =============================================================================
_flow_log_info()    { _flow_log info "ℹ $*" }

# =============================================================================
# Function: _flow_log_muted
# Purpose: Log muted/gray text without prefix symbol
# =============================================================================
# Arguments:
#   $@ - (required) Message to display
#
# Example:
#   _flow_log_muted "Last updated: 2 hours ago"
#   # Output: Last updated: 2 hours ago (in gray)
# =============================================================================
_flow_log_muted()   { echo -e "${FLOW_COLORS[muted]}$*${FLOW_COLORS[reset]}" }

# =============================================================================
# Function: _flow_log_debug
# Purpose: Log debug message (only when FLOW_DEBUG is set)
# =============================================================================
# Arguments:
#   $@ - (required) Message to display
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - "[debug] message" in gray (only if FLOW_DEBUG is set)
#
# Example:
#   export FLOW_DEBUG=1
#   _flow_log_debug "Variable value: $var"
#   # Output: [debug] Variable value: foo (in gray)
#
# Notes:
#   - Silent when FLOW_DEBUG is unset or empty
#   - Useful for troubleshooting without cluttering normal output
# =============================================================================
_flow_log_debug() {
  [[ -n "$FLOW_DEBUG" ]] && echo -e "${FLOW_COLORS[muted]}[debug] $*${FLOW_COLORS[reset]}"
}

# ============================================================================
# STATUS ICONS
# ============================================================================

# =============================================================================
# Function: _flow_status_icon
# Purpose: Convert project status string to emoji indicator
# =============================================================================
# Arguments:
#   $1 - (required) Status string (case-insensitive)
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Single emoji character representing status
#
# Status Mapping:
#   active/ACTIVE   → 🟢 (green circle)
#   paused/PAUSED   → 🟡 (yellow circle)
#   blocked/BLOCKED → 🔴 (red circle)
#   archived/ARCHIVED → ⚫ (black circle)
#   stalled         → 🟠 (orange circle)
#   (other)         → ⚪ (white circle)
#
# Example:
#   icon=$(_flow_status_icon "active")  # Returns: 🟢
#   icon=$(_flow_status_icon "PAUSED")  # Returns: 🟡
#
# Notes:
#   - Case-insensitive matching for common statuses
#   - Used in dashboards and project listings
# =============================================================================
_flow_status_icon() {
  case "$1" in
    active|ACTIVE)     echo "🟢" ;;
    paused|PAUSED)     echo "🟡" ;;
    blocked|BLOCKED)   echo "🔴" ;;
    archived|ARCHIVED) echo "⚫" ;;
    stalled)           echo "🟠" ;;
    *)                 echo "⚪" ;;
  esac
}

# ============================================================================
# PATH UTILITIES
# ============================================================================

# =============================================================================
# Function: _flow_project_name
# Purpose: Extract project name (directory name) from a path
# =============================================================================
# Arguments:
#   $1 - (optional) Path to extract name from [default: $PWD]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Project name (last component of path)
#
# Example:
#   _flow_project_name "/Users/dt/projects/flow-cli"
#   # Output: flow-cli
#
#   _flow_project_name  # Uses current directory
#   # Output: (current directory name)
#
# Notes:
#   - Uses ZSH :t modifier (tail/basename equivalent)
#   - Does not validate path exists
# =============================================================================
_flow_project_name() {
  local dir_path="${1:-$PWD}"
  echo "${dir_path:t}"  # ZSH builtin: :t = tail (basename equivalent)
}

# =============================================================================
# Function: _flow_find_project_root
# Purpose: Find project root by searching upward for .STATUS or .git
# =============================================================================
# Arguments:
#   $1 - (optional) Starting directory [default: $PWD]
#
# Returns:
#   0 - Project root found
#   1 - No project root found (reached filesystem root)
#
# Output:
#   stdout - Absolute path to project root
#
# Example:
#   root=$(_flow_find_project_root)
#   if [[ $? -eq 0 ]]; then
#       echo "Project root: $root"
#   else
#       echo "Not in a project"
#   fi
#
#   # Start from specific directory
#   root=$(_flow_find_project_root "/Users/dt/projects/flow-cli/lib")
#
# Notes:
#   - Searches for .STATUS file (flow-cli project marker)
#   - Falls back to .git/config (standard git repo)
#   - Uses ZSH :h modifier (head/dirname equivalent)
# =============================================================================
_flow_find_project_root() {
  local dir="${1:-$PWD}"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.STATUS" ]] || [[ -f "$dir/.git/config" ]]; then
      echo "$dir"
      return 0
    fi
    dir="${dir:h}"
  done
  return 1
}

# =============================================================================
# Function: _flow_in_project
# Purpose: Check if current directory is inside a flow-cli project
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Currently in a project directory
#   1 - Not in a project directory
#
# Example:
#   if _flow_in_project; then
#       echo "You're in a project!"
#   else
#       echo "Navigate to a project first"
#   fi
#
# Notes:
#   - Wrapper around _flow_find_project_root
#   - Suppresses all output (check return code only)
# =============================================================================
_flow_in_project() {
  _flow_find_project_root &>/dev/null
}

# ============================================================================
# TIME UTILITIES
# ============================================================================

# =============================================================================
# Function: _flow_format_duration
# Purpose: Convert seconds to human-readable duration string
# =============================================================================
# Arguments:
#   $1 - (required) Duration in seconds
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted duration string
#
# Format Examples:
#   45      → "45s"
#   125     → "2m"
#   3725    → "1h 2m"
#   7200    → "2h 0m"
#
# Example:
#   elapsed=$(_flow_format_duration 3725)
#   echo "Session: $elapsed"  # Output: Session: 1h 2m
#
# Notes:
#   - Seconds shown only for durations < 1 minute
#   - Minutes always shown for durations >= 1 minute
#   - Hours and minutes shown for durations >= 1 hour
# =============================================================================
_flow_format_duration() {
  local seconds="$1"
  if (( seconds < 60 )); then
    echo "${seconds}s"
  elif (( seconds < 3600 )); then
    echo "$(( seconds / 60 ))m"
  else
    local hours=$(( seconds / 3600 ))
    local mins=$(( (seconds % 3600) / 60 ))
    echo "${hours}h ${mins}m"
  fi
}

# =============================================================================
# Function: _flow_time_ago
# Purpose: Convert Unix timestamp to relative time string
# =============================================================================
# Arguments:
#   $1 - (required) Unix timestamp (seconds since epoch)
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Relative time string
#
# Format Examples:
#   (now - 30)    → "just now"
#   (now - 300)   → "5m ago"
#   (now - 7200)  → "2h ago"
#   (now - 172800) → "2d ago"
#
# Example:
#   last_commit=$(git log -1 --format=%ct)
#   echo "Last commit: $(_flow_time_ago $last_commit)"
#   # Output: Last commit: 2h ago
#
# Notes:
#   - Uses current time for comparison
#   - "just now" for anything < 60 seconds
#   - Does not handle future timestamps
# =============================================================================
_flow_time_ago() {
  local timestamp="$1"
  local now=$(date +%s)
  local diff=$(( now - timestamp ))

  if (( diff < 60 )); then
    echo "just now"
  elif (( diff < 3600 )); then
    echo "$(( diff / 60 ))m ago"
  elif (( diff < 86400 )); then
    echo "$(( diff / 3600 ))h ago"
  else
    echo "$(( diff / 86400 ))d ago"
  fi
}

# ============================================================================
# INPUT HELPERS
# ============================================================================

# =============================================================================
# Function: _flow_confirm
# Purpose: Display yes/no confirmation prompt with sensible defaults
# =============================================================================
# Arguments:
#   $1 - (optional) Prompt message [default: "Continue?"]
#   $2 - (optional) Default answer "y" or "n" [default: "n"]
#
# Returns:
#   0 - User answered yes (or default was "y" in non-interactive mode)
#   1 - User answered no (or default was "n" in non-interactive mode)
#
# Example:
#   # Default "no" behavior
#   if _flow_confirm "Delete all files?"; then
#       rm -rf ./build
#   fi
#
#   # Default "yes" behavior
#   if _flow_confirm "Continue with build?" "y"; then
#       make build
#   fi
#
# Notes:
#   - Non-interactive mode (no TTY) returns the default value
#   - Capitalizes the default option: [Y/n] or [y/N]
#   - Uses ZSH read -q for single-character response
# =============================================================================
_flow_confirm() {
  local prompt="${1:-Continue?}"
  local default="${2:-n}"

  # If no TTY, return default (usually false/no)
  if [[ ! -t 0 ]]; then
    [[ "$default" == "y" ]]
    return
  fi

  if [[ "$default" == "y" ]]; then
    prompt="$prompt [Y/n] "
  else
    prompt="$prompt [y/N] "
  fi

  read -q "?$prompt" response
  echo
  [[ "$response" == "y" ]]
}

# ============================================================================
# ARRAY UTILITIES
# ============================================================================

# =============================================================================
# Function: _flow_array_contains
# Purpose: Check if a value exists in an array
# =============================================================================
# Arguments:
#   $1 - (required) Value to search for (needle)
#   $@ - (required) Array elements to search through (haystack)
#
# Returns:
#   0 - Value found in array
#   1 - Value not found
#
# Example:
#   local -a statuses=(active paused blocked)
#   if _flow_array_contains "active" "${statuses[@]}"; then
#       echo "Found active status"
#   fi
#
#   # Inline usage
#   _flow_array_contains "$status" active paused blocked && echo "Valid"
#
# Notes:
#   - Uses exact string matching
#   - Pass array with ${array[@]} syntax
# =============================================================================
_flow_array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# ============================================================================
# FILE UTILITIES
# ============================================================================

# =============================================================================
# Function: _flow_read_file
# Purpose: Safely read file contents (no error if file doesn't exist)
# =============================================================================
# Arguments:
#   $1 - (required) Path to file
#
# Returns:
#   0 - Always succeeds (even if file doesn't exist)
#
# Output:
#   stdout - File contents, or empty if file doesn't exist
#
# Example:
#   # Read a config file, empty string if missing
#   local config=$(_flow_read_file "$HOME/.myconfig")
#
#   # Use in conditionals
#   if [[ -n "$(_flow_read_file "$path/.STATUS")" ]]; then
#       echo "Project has status file"
#   fi
#
# Notes:
#   - Silently handles missing files (no stderr output)
#   - Useful for optional configuration files
# =============================================================================
_flow_read_file() {
  local file="$1"
  [[ -f "$file" ]] && cat "$file"
}

# =============================================================================
# Function: _flow_get_config
# Purpose: Read a value from a key=value format config file
# =============================================================================
# Arguments:
#   $1 - (required) Path to config file
#   $2 - (required) Key to look up
#   $3 - (optional) Default value if key not found
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Value for key, or default if not found
#
# Example:
#   # Simple lookup with default
#   local theme=$(_flow_get_config ~/.myconfig "theme" "dark")
#
#   # Check if key exists
#   local value=$(_flow_get_config "$file" "api_key")
#   [[ -z "$value" ]] && echo "API key not configured"
#
# File Format:
#   theme=dark
#   timeout=30
#   # Comments are ignored via grep pattern
#
# Notes:
#   - Expects "key=value" format (no spaces around =)
#   - Returns default if file doesn't exist or key not found
#   - Uses command grep/cut to avoid alias interference
# =============================================================================
_flow_get_config() {
  local file="$1"
  local key="$2"
  local default="$3"

  if [[ -f "$file" ]]; then
    local value=$(command grep "^${key}=" "$file" 2>/dev/null | command cut -d'=' -f2-)
    echo "${value:-$default}"
  else
    echo "$default"
  fi
}

# ============================================================================
# SECRET BACKEND CONFIGURATION
# ============================================================================

# =============================================================================
# Function: _dotf_secret_backend
# Purpose: Get the configured secret storage backend
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Backend name: "keychain" (default), "bitwarden", or "both"
#
# Example:
#   local backend=$(_dotf_secret_backend)
#   case "$backend" in
#     keychain)  echo "Using macOS Keychain only" ;;
#     bitwarden) echo "Using Bitwarden only" ;;
#     both)      echo "Using both backends" ;;
#   esac
#
# Environment:
#   FLOW_SECRET_BACKEND - Override default backend
#     "keychain"  - macOS Keychain only (default, no unlock needed)
#     "bitwarden" - Bitwarden only (requires dot unlock)
#     "both"      - Both backends (Keychain primary, Bitwarden sync)
#
# Notes:
#   - Default is "keychain" for instant access without unlock
#   - "bitwarden" mode preserves legacy behavior
#   - "both" mode enables cloud backup with local performance
# =============================================================================
_dotf_secret_backend() {
  local backend="${FLOW_SECRET_BACKEND:-keychain}"

  # Validate backend value
  case "$backend" in
    keychain|bitwarden|both)
      echo "$backend"
      ;;
    *)
      # Invalid value, fall back to default
      _flow_log_warning "Invalid FLOW_SECRET_BACKEND='$backend', using 'keychain'"
      echo "keychain"
      ;;
  esac
}

# =============================================================================
# Function: _dotf_secret_needs_bitwarden
# Purpose: Check if current backend requires Bitwarden
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Bitwarden is needed (backend is "bitwarden" or "both")
#   1 - Bitwarden not needed (backend is "keychain")
#
# Example:
#   if _dotf_secret_needs_bitwarden; then
#     # Ensure Bitwarden is available and unlocked
#     _dotf_require_tool "bw" "brew install bitwarden-cli"
#   fi
#
# Notes:
#   - Use this to conditionally skip Bitwarden checks
#   - Returns success (0) for "bitwarden" and "both" modes
# =============================================================================
_dotf_secret_needs_bitwarden() {
  local backend=$(_dotf_secret_backend)
  [[ "$backend" == "bitwarden" ]] || [[ "$backend" == "both" ]]
}

# =============================================================================
# Function: _dotf_secret_uses_keychain
# Purpose: Check if current backend uses Keychain
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Keychain is used (backend is "keychain" or "both")
#   1 - Keychain not used (backend is "bitwarden")
#
# Example:
#   if _dotf_secret_uses_keychain; then
#     _dotf_kc_add "$name"
#   fi
#
# Notes:
#   - Use this to conditionally use Keychain storage
#   - Returns success (0) for "keychain" and "both" modes
# =============================================================================
_dotf_secret_uses_keychain() {
  local backend=$(_dotf_secret_backend)
  [[ "$backend" == "keychain" ]] || [[ "$backend" == "both" ]]
}

# ============================================================================
# CROSS-PLATFORM UTILITIES (BSD vs GNU)
# ============================================================================

# =============================================================================
# Function: _flow_get_file_size
# Purpose: Get file size in bytes (cross-platform: BSD macOS vs GNU Linux)
# =============================================================================
# Arguments:
#   $1 - (required) Path to file
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - File size in bytes, or 0 on error
#
# Example:
#   local size=$(_flow_get_file_size "/path/to/file.txt")
#   echo "File is $size bytes"
#
# Notes:
#   - Detects GNU vs BSD stat automatically
#   - GNU stat (Linux): stat -c%s
#   - BSD stat (macOS): stat -f%z
#   - Returns 0 if file doesn't exist or on error
# =============================================================================
_flow_get_file_size() {
  local file="$1"

  # Detect stat flavor
  if stat --version 2>/dev/null | grep -q GNU; then
    # GNU stat (Linux)
    stat -c%s "$file" 2>/dev/null || echo 0
  else
    # BSD stat (macOS)
    stat -f%z "$file" 2>/dev/null || echo 0
  fi
}

# =============================================================================
# Function: _flow_human_size
# Purpose: Convert bytes to human-readable size (cross-platform)
# =============================================================================
# Arguments:
#   $1 - (required) Size in bytes
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Human-readable size (e.g., "2.5G", "150M", "4.2K", "512 bytes")
#
# Example:
#   local bytes=1572864
#   echo "Size: $(_flow_human_size $bytes)"
#   # Output: Size: 1M
#
# Notes:
#   - Prefers numfmt (GNU coreutils) if available
#   - Fallback: manual conversion (GB/MB/KB/bytes)
#   - Handles edge cases: 0 bytes, negative values
#   - On macOS with Homebrew: brew install coreutils (provides gnumfmt)
# =============================================================================
_flow_human_size() {
  local bytes="$1"

  # Handle edge cases
  if [[ -z "$bytes" ]] || (( bytes < 0 )); then
    echo "0 bytes"
    return
  fi

  if (( bytes == 0 )); then
    echo "0 bytes"
    return
  fi

  # For very small files (< 1KB), always show "X bytes" format
  if (( bytes < 1024 )); then
    echo "${bytes} bytes"
    return
  fi

  # Prefer numfmt if available (GNU coreutils)
  if command -v numfmt &>/dev/null; then
    numfmt --to=iec "$bytes" 2>/dev/null
    return
  fi

  # Fallback: manual conversion with integer arithmetic
  if (( bytes >= 1073741824 )); then
    # GB (1024^3)
    local gb=$((bytes / 1073741824))
    echo "${gb}G"
  elif (( bytes >= 1048576 )); then
    # MB (1024^2)
    local mb=$((bytes / 1048576))
    echo "${mb}M"
  else
    # KB (1024)
    local kb=$((bytes / 1024))
    echo "${kb}K"
  fi
}

# =============================================================================
# Function: _flow_timeout
# Purpose: Run command with timeout (cross-platform: GNU vs macOS)
# =============================================================================
# Arguments:
#   $1 - (required) Timeout in seconds
#   $@ - (required) Command to run with arguments
#
# Returns:
#   Exit code of command, or 124 on timeout (GNU timeout convention)
#
# Example:
#   # Limit find to 2 seconds
#   _flow_timeout 2 find /large/directory -name "*.txt"
#
#   # Check return code
#   _flow_timeout 5 slow_command
#   [[ $? -eq 124 ]] && echo "Command timed out"
#
# Notes:
#   - Uses GNU timeout if available (Linux, Homebrew coreutils)
#   - Fallback: gtimeout (macOS with brew install coreutils)
#   - Last resort: runs command without timeout (no error)
#   - Returns 124 on timeout (matches GNU timeout convention)
#   - To install on macOS: brew install coreutils
# =============================================================================
_flow_timeout() {
  local timeout_seconds="$1"
  shift

  # Try GNU timeout first (standard on Linux, brew coreutils on macOS)
  if command -v timeout &>/dev/null; then
    timeout "$timeout_seconds" "$@"
    return
  fi

  # Try gtimeout (macOS with Homebrew coreutils)
  if command -v gtimeout &>/dev/null; then
    gtimeout "$timeout_seconds" "$@"
    return
  fi

  # Fallback: run without timeout
  # NOTE: This is safe - better to complete slowly than fail
  "$@"
}
