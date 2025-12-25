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
)

# ============================================================================
# LOGGING
# ============================================================================

_flow_log() {
  local level="$1"
  shift
  local color="${FLOW_COLORS[$level]:-${FLOW_COLORS[info]}}"
  echo -e "${color}$*${FLOW_COLORS[reset]}"
}

_flow_log_success() { _flow_log success "✓ $*" }
_flow_log_warning() { _flow_log warning "⚠ $*" }
_flow_log_error()   { _flow_log error "✗ $*" }
_flow_log_info()    { _flow_log info "ℹ $*" }

_flow_log_debug() {
  [[ -n "$FLOW_DEBUG" ]] && echo -e "${FLOW_COLORS[muted]}[debug] $*${FLOW_COLORS[reset]}"
}

# ============================================================================
# STATUS ICONS
# ============================================================================

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

# Get project name from path
_flow_project_name() {
  local path="${1:-$PWD}"
  echo "${path:t}"  # ZSH builtin: :t = tail (basename equivalent)
}

# Find project root (looks for .STATUS, .git, etc.)
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

# Check if in a project directory
_flow_in_project() {
  _flow_find_project_root &>/dev/null
}

# ============================================================================
# TIME UTILITIES
# ============================================================================

# Human-readable duration
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

# Relative time (e.g., "2 hours ago")
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

# Simple yes/no prompt
_flow_confirm() {
  local prompt="${1:-Continue?}"
  local default="${2:-n}"
  
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

# Check if array contains value
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

# Safe file read (returns empty if file doesn't exist)
_flow_read_file() {
  local file="$1"
  [[ -f "$file" ]] && cat "$file"
}

# Get value from key=value file
_flow_get_config() {
  local file="$1"
  local key="$2"
  local default="$3"
  
  if [[ -f "$file" ]]; then
    local value=$(grep "^${key}=" "$file" 2>/dev/null | cut -d'=' -f2-)
    echo "${value:-$default}"
  else
    echo "$default"
  fi
}
