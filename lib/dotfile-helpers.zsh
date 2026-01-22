# lib/dotfile-helpers.zsh - Dotfile management helper functions
# Provides: tool detection, status helpers, path resolution
# Used by: dot dispatcher

# ============================================================================
# TOOL DETECTION (with caching)
# ============================================================================

# Cache tool availability (checked once per session)
typeset -g _FLOW_DOT_CHEZMOI_AVAILABLE
typeset -g _FLOW_DOT_BW_AVAILABLE
typeset -g _FLOW_DOT_MISE_AVAILABLE

# =============================================================================
# Function: _dot_has_chezmoi
# Purpose: Check if chezmoi dotfile manager is available (with session caching)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Chezmoi is installed and available
#   1 - Chezmoi is not installed
#
# Example:
#   if _dot_has_chezmoi; then
#       chezmoi apply
#   else
#       echo "Install chezmoi first"
#   fi
#
# Notes:
#   - Result cached in $_FLOW_DOT_CHEZMOI_AVAILABLE for session duration
#   - First call performs actual command check, subsequent calls use cache
# =============================================================================
_dot_has_chezmoi() {
  # Return cached result if available
  if [[ -n "$_FLOW_DOT_CHEZMOI_AVAILABLE" ]]; then
    [[ "$_FLOW_DOT_CHEZMOI_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if chezmoi command exists
  if command -v chezmoi &>/dev/null; then
    _FLOW_DOT_CHEZMOI_AVAILABLE="yes"
    return 0
  else
    _FLOW_DOT_CHEZMOI_AVAILABLE="no"
    return 1
  fi
}

# =============================================================================
# Function: _dot_has_bw
# Purpose: Check if Bitwarden CLI is available (with session caching)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Bitwarden CLI (bw) is installed
#   1 - Bitwarden CLI is not installed
#
# Example:
#   if _dot_has_bw; then
#       bw status
#   fi
#
# Notes:
#   - Result cached in $_FLOW_DOT_BW_AVAILABLE for session duration
#   - Used by secret management commands (dot secret)
# =============================================================================
_dot_has_bw() {
  # Return cached result if available
  if [[ -n "$_FLOW_DOT_BW_AVAILABLE" ]]; then
    [[ "$_FLOW_DOT_BW_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if bw command exists
  if command -v bw &>/dev/null; then
    _FLOW_DOT_BW_AVAILABLE="yes"
    return 0
  else
    _FLOW_DOT_BW_AVAILABLE="no"
    return 1
  fi
}

# =============================================================================
# Function: _dot_has_mise
# Purpose: Check if mise (formerly rtx) version manager is available
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - mise is installed
#   1 - mise is not installed
#
# Example:
#   if _dot_has_mise; then
#       mise install
#   fi
#
# Notes:
#   - Result cached in $_FLOW_DOT_MISE_AVAILABLE for session duration
#   - mise manages runtime versions (Node, Python, Ruby, etc.)
# =============================================================================
_dot_has_mise() {
  # Return cached result if available
  if [[ -n "$_FLOW_DOT_MISE_AVAILABLE" ]]; then
    [[ "$_FLOW_DOT_MISE_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if mise command exists
  if command -v mise &>/dev/null; then
    _FLOW_DOT_MISE_AVAILABLE="yes"
    return 0
  else
    _FLOW_DOT_MISE_AVAILABLE="no"
    return 1
  fi
}

# =============================================================================
# Function: _dot_require_tool
# Purpose: Verify a tool is installed, show error with install command if not
# =============================================================================
# Arguments:
#   $1 - (required) Tool/command name to check
#   $2 - (optional) Install command [default: "brew install $tool"]
#
# Returns:
#   0 - Tool is available
#   1 - Tool not found (error message displayed)
#
# Example:
#   _dot_require_tool "chezmoi" "brew install chezmoi"
#   _dot_require_tool "yq"  # Uses default brew install
#
# Notes:
#   - Displays formatted error message with install instructions
#   - Used at start of commands that depend on external tools
# =============================================================================
_dot_require_tool() {
  local tool=$1
  local install_cmd=${2:-brew install $tool}

  if ! command -v "$tool" &>/dev/null; then
    _flow_log_error "$tool not found. Install: $install_cmd"
    return 1
  fi
  return 0
}

# ============================================================================
# STATUS HELPERS
# ============================================================================

# =============================================================================
# Function: _dot_get_sync_status
# Purpose: Get current dotfile sync status relative to remote repository
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Status retrieved successfully
#   1 - Error (chezmoi not installed or not initialized)
#
# Output:
#   stdout - Status string: "synced"|"modified"|"behind"|"ahead"|
#            "not-installed"|"not-initialized"|"error"
#
# Example:
#   status=$(_dot_get_sync_status)
#   if [[ "$status" == "modified" ]]; then
#       echo "You have uncommitted changes"
#   fi
#
# Notes:
#   - Checks chezmoi status and git remote state
#   - "modified" means local changes not yet committed
#   - "ahead/behind" refers to git commits vs remote
# =============================================================================
_dot_get_sync_status() {
  if ! _dot_has_chezmoi; then
    echo "not-installed"
    return 1
  fi

  # Check if chezmoi is initialized
  if [[ ! -d "${HOME}/.local/share/chezmoi" ]]; then
    echo "not-initialized"
    return 1
  fi

  # Get status from chezmoi
  local status_output
  status_output=$(chezmoi status 2>/dev/null)
  local status_code=$?

  if [[ $status_code -ne 0 ]]; then
    echo "error"
    return 1
  fi

  # Parse status
  if [[ -z "$status_output" ]]; then
    # Check if repo is ahead/behind
    if _dot_is_ahead_of_remote; then
      echo "ahead"
    elif _dot_is_behind_remote; then
      echo "behind"
    else
      echo "synced"
    fi
  else
    # Has local modifications
    echo "modified"
  fi
}

# =============================================================================
# Function: _dot_is_ahead_of_remote
# Purpose: Check if local chezmoi repo has unpushed commits
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Local repo is ahead (has unpushed commits)
#   1 - Not ahead, or chezmoi not available
#
# Example:
#   if _dot_is_ahead_of_remote; then
#       echo "Run 'dot push' to sync changes"
#   fi
#
# Notes:
#   - Checks ~/.local/share/chezmoi/.git status
#   - Uses git rev-list to compare HEAD with upstream
# =============================================================================
_dot_is_ahead_of_remote() {
  if ! _dot_has_chezmoi; then
    return 1
  fi

  local chezmoi_dir="${HOME}/.local/share/chezmoi"
  if [[ ! -d "$chezmoi_dir/.git" ]]; then
    return 1
  fi

  # Check git status in chezmoi directory
  (
    cd "$chezmoi_dir" || return 1
    git rev-list @{u}..HEAD 2>/dev/null | grep -q .
  )
}

# =============================================================================
# Function: _dot_is_behind_remote
# Purpose: Check if local chezmoi repo is behind remote (needs pull)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Local repo is behind (remote has new commits)
#   1 - Not behind, or chezmoi not available
#
# Example:
#   if _dot_is_behind_remote; then
#       echo "Run 'dot pull' to get latest changes"
#   fi
#
# Notes:
#   - Performs git fetch before comparing
#   - Checks ~/.local/share/chezmoi/.git status
# =============================================================================
_dot_is_behind_remote() {
  if ! _dot_has_chezmoi; then
    return 1
  fi

  local chezmoi_dir="${HOME}/.local/share/chezmoi"
  if [[ ! -d "$chezmoi_dir/.git" ]]; then
    return 1
  fi

  # Fetch remote (silent)
  (
    cd "$chezmoi_dir" || return 1
    git fetch --quiet 2>/dev/null
    git rev-list HEAD..@{u} 2>/dev/null | grep -q .
  )
}

# =============================================================================
# Function: _dot_get_modified_files
# Purpose: Get list of files with local modifications pending sync
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success (even if no modified files)
#   1 - Chezmoi not available
#
# Output:
#   stdout - Newline-separated list of modified file paths
#
# Example:
#   files=$(_dot_get_modified_files)
#   echo "Modified: $files"
#
# Notes:
#   - Returns relative paths from chezmoi status
#   - Empty output means no modifications
# =============================================================================
_dot_get_modified_files() {
  if ! _dot_has_chezmoi; then
    return 1
  fi

  chezmoi status 2>/dev/null | awk '{print $2}'
}

# =============================================================================
# Function: _dot_get_modified_count
# Purpose: Get count of files with local modifications
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always (count returned via stdout)
#
# Output:
#   stdout - Number of modified files (0 if none or chezmoi unavailable)
#
# Example:
#   count=$(_dot_get_modified_count)
#   [[ $count -gt 0 ]] && echo "$count files need syncing"
#
# Notes:
#   - Returns "0" if chezmoi not available (graceful degradation)
#   - Sanitizes output to ensure valid numeric format
# =============================================================================
_dot_get_modified_count() {
  if ! _dot_has_chezmoi; then
    echo "0"
    return
  fi

  local count=$(chezmoi status 2>/dev/null | wc -l | tr -d ' ')

  # Sanitize: strip whitespace and validate numeric format
  count="${count##*( )}"    # Remove leading spaces
  count="${count%%*( )}"    # Remove trailing spaces
  [[ "$count" =~ ^[0-9]+$ ]] || count=0

  echo "$count"
}

# =============================================================================
# Function: _dot_get_last_sync_time
# Purpose: Get relative time since last dotfile commit
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success
#   1 - Chezmoi not available or not initialized
#
# Output:
#   stdout - Relative time string (e.g., "2 hours ago", "3 days ago")
#            or "unknown"/"not-initialized" on error
#
# Example:
#   last_sync=$(_dot_get_last_sync_time)
#   echo "Last synced: $last_sync"
#
# Notes:
#   - Uses git log --format=%ar for relative time
#   - Reads from ~/.local/share/chezmoi/.git
# =============================================================================
_dot_get_last_sync_time() {
  if ! _dot_has_chezmoi; then
    echo "unknown"
    return 1
  fi

  local chezmoi_dir="${HOME}/.local/share/chezmoi"
  if [[ ! -d "$chezmoi_dir/.git" ]]; then
    echo "not-initialized"
    return 1
  fi

  # Get last commit time
  local commit_time
  commit_time=$(cd "$chezmoi_dir" && git log -1 --format=%ar 2>/dev/null)

  if [[ -n "$commit_time" ]]; then
    echo "$commit_time"
  else
    echo "unknown"
  fi
}

# =============================================================================
# Function: _dot_get_tracked_count
# Purpose: Get total number of files managed by chezmoi
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always (count returned via stdout)
#
# Output:
#   stdout - Number of tracked/managed files
#
# Example:
#   tracked=$(_dot_get_tracked_count)
#   echo "Managing $tracked dotfiles"
#
# Notes:
#   - Returns "0" if chezmoi not available
#   - Uses chezmoi managed command
# =============================================================================
_dot_get_tracked_count() {
  if ! _dot_has_chezmoi; then
    echo "0"
    return
  fi

  local count=$(chezmoi managed 2>/dev/null | wc -l | tr -d ' ')

  # Sanitize: strip whitespace and validate numeric format
  count="${count##*( )}"    # Remove leading spaces
  count="${count%%*( )}"    # Remove trailing spaces
  [[ "$count" =~ ^[0-9]+$ ]] || count=0

  echo "$count"
}

# =============================================================================
# Function: _dot_format_status
# Purpose: Format sync status with colored icon for terminal display
# =============================================================================
# Arguments:
#   $1 - (required) Status string from _dot_get_sync_status
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Formatted status with emoji and ANSI colors
#
# Example:
#   status=$(_dot_get_sync_status)
#   echo $(_dot_format_status "$status")
#   # Output: 🟢 Synced (in green)
#
# Notes:
#   - Uses FLOW_COLORS associative array for theming
#   - Status values: synced, modified, behind, ahead, conflict,
#     not-installed, not-initialized, error
# =============================================================================
_dot_format_status() {
  local sync_status=$1

  case "$sync_status" in
    synced)
      echo "${FLOW_COLORS[success]}🟢 Synced${FLOW_COLORS[reset]}"
      ;;
    modified)
      echo "${FLOW_COLORS[warning]}🟡 Modified${FLOW_COLORS[reset]}"
      ;;
    behind)
      echo "${FLOW_COLORS[error]}🔴 Behind${FLOW_COLORS[reset]}"
      ;;
    ahead)
      echo "${FLOW_COLORS[info]}🔵 Ahead${FLOW_COLORS[reset]}"
      ;;
    conflict)
      echo "${FLOW_COLORS[error]}⚠️  Conflict${FLOW_COLORS[reset]}"
      ;;
    not-installed)
      echo "${FLOW_COLORS[muted]}❌ Not installed${FLOW_COLORS[reset]}"
      ;;
    not-initialized)
      echo "${FLOW_COLORS[muted]}⚪ Not initialized${FLOW_COLORS[reset]}"
      ;;
    error)
      echo "${FLOW_COLORS[error]}❌ Error${FLOW_COLORS[reset]}"
      ;;
    *)
      echo "${FLOW_COLORS[muted]}❓ Unknown${FLOW_COLORS[reset]}"
      ;;
  esac
}

# ============================================================================
# DASHBOARD INTEGRATION
# ============================================================================

# =============================================================================
# Function: _dot_get_status_line
# Purpose: Generate one-line dotfile status for dashboard display
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success (status line generated)
#   1 - Chezmoi not available or error state
#
# Output:
#   stdout - Formatted status line with icon, state, details, file count
#            Example: "  📝 Dotfiles: 🟢 Synced (2 hours ago) · 45 files tracked"
#
# Example:
#   if line=$(_dot_get_status_line); then
#       echo "$line"
#   fi
#
# Notes:
#   - Returns 1 for error states (no output shown in dashboard)
#   - Includes commit count for ahead/behind states
#   - Uses FLOW_COLORS for consistent theming
# =============================================================================
_dot_get_status_line() {
  if ! _dot_has_chezmoi; then
    return 1
  fi

  # Get status components (with timeout to keep it fast)
  local sync_status=$(_dot_get_sync_status)
  local tracked_count=$(_dot_get_tracked_count)
  local last_sync=$(_dot_get_last_sync_time)
  local modified_count=$(_dot_get_modified_count)

  # Format based on status
  local status_icon=""
  local status_text=""
  local detail_text=""

  case "$sync_status" in
    synced)
      status_icon="🟢"
      status_text="${FLOW_COLORS[success]}Synced${FLOW_COLORS[reset]}"
      detail_text="($last_sync)"
      ;;
    modified)
      status_icon="🟡"
      status_text="${FLOW_COLORS[warning]}Modified${FLOW_COLORS[reset]}"
      if [[ $modified_count -gt 0 ]]; then
        detail_text="($modified_count file$([ $modified_count -gt 1 ] && echo 's') pending)"
      else
        detail_text="(pending)"
      fi
      ;;
    behind)
      status_icon="🔴"
      status_text="${FLOW_COLORS[error]}Behind${FLOW_COLORS[reset]}"
      # Get commit count if possible
      local behind_count=""
      local chezmoi_dir="${HOME}/.local/share/chezmoi"
      if [[ -d "$chezmoi_dir/.git" ]]; then
        behind_count=$(cd "$chezmoi_dir" && git rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ')
        # Sanitize: strip whitespace and validate numeric format
        behind_count="${behind_count##*( )}"
        behind_count="${behind_count%%*( )}"
        [[ "$behind_count" =~ ^[0-9]+$ ]] || behind_count=0
        if [[ $behind_count -gt 0 ]]; then
          detail_text="($behind_count commit$([ $behind_count -gt 1 ] && echo 's'))"
        else
          detail_text="(needs pull)"
        fi
      else
        detail_text="(needs pull)"
      fi
      ;;
    ahead)
      status_icon="🔵"
      status_text="${FLOW_COLORS[info]}Ahead${FLOW_COLORS[reset]}"
      # Get commit count if possible
      local ahead_count=""
      local chezmoi_dir="${HOME}/.local/share/chezmoi"
      if [[ -d "$chezmoi_dir/.git" ]]; then
        ahead_count=$(cd "$chezmoi_dir" && git rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
        # Sanitize: strip whitespace and validate numeric format
        ahead_count="${ahead_count##*( )}"
        ahead_count="${ahead_count%%*( )}"
        [[ "$ahead_count" =~ ^[0-9]+$ ]] || ahead_count=0
        if [[ $ahead_count -gt 0 ]]; then
          detail_text="($ahead_count commit$([ $ahead_count -gt 1 ] && echo 's'))"
        else
          detail_text="(needs push)"
        fi
      else
        detail_text="(needs push)"
      fi
      ;;
    not-initialized)
      status_icon="⚪"
      status_text="${FLOW_COLORS[muted]}Not initialized${FLOW_COLORS[reset]}"
      detail_text=""
      ;;
    *)
      # Don't show line for error states
      return 1
      ;;
  esac

  # Format tracked count
  local tracked_text="${FLOW_COLORS[muted]}$tracked_count file$([ $tracked_count -gt 1 ] && echo 's') tracked${FLOW_COLORS[reset]}"

  # Build final line
  echo "  📝 ${FLOW_COLORS[bold]}Dotfiles:${FLOW_COLORS[reset]} $status_icon $status_text $detail_text · $tracked_text"
}

# ============================================================================
# PATH RESOLUTION (fuzzy matching for file names)
# ============================================================================

# =============================================================================
# Function: _dot_resolve_file_path
# Purpose: Resolve partial file name to full path using fuzzy matching
# =============================================================================
# Arguments:
#   $1 - (required) Search term (partial filename or full path)
#
# Returns:
#   0 - Single match found
#   1 - No matches found
#   2 - Multiple matches found (all returned via stdout)
#
# Output:
#   stdout - Absolute path(s) to matching file(s)
#
# Example:
#   path=$(_dot_resolve_file_path "zshrc")
#   # Returns: /Users/user/.config/zsh/.zshrc
#
#   _dot_resolve_file_path "vim"  # Multiple matches
#   # Returns all vim-related files, exit code 2
#
# Notes:
#   - Full paths (starting with / or ~) returned as-is
#   - Searches chezmoi managed files with grep -i
#   - Returns absolute paths (prepends $HOME)
# =============================================================================
_dot_resolve_file_path() {
  local search_term=$1

  if ! _dot_has_chezmoi; then
    return 1
  fi

  # If it's already a full path, return it
  if [[ "$search_term" =~ ^[/~] ]]; then
    echo "$search_term"
    return 0
  fi

  # Search in managed files
  local matched_files
  matched_files=$(chezmoi managed 2>/dev/null | grep -i "$search_term")

  if [[ -z "$matched_files" ]]; then
    # No match found
    return 1
  fi

  # Count matches
  local match_count
  match_count=$(echo "$matched_files" | wc -l | tr -d ' ')

  # Sanitize: strip whitespace and validate numeric format
  match_count="${match_count##*( )}"
  match_count="${match_count%%*( )}"
  [[ "$match_count" =~ ^[0-9]+$ ]] || match_count=0

  if [[ $match_count -eq 1 ]]; then
    # Single match - return absolute path (chezmoi managed returns relative paths)
    echo "$HOME/$matched_files"
    return 0
  else
    # Multiple matches - return all as absolute paths for selection
    echo "$matched_files" | while read -r file; do
      echo "$HOME/$file"
    done
    return 2  # Signal multiple matches
  fi
}

# ============================================================================
# BITWARDEN HELPERS
# ============================================================================

# Session cache configuration
typeset -g DOT_SESSION_CACHE_DIR="${HOME}/.cache/dot"
typeset -g DOT_SESSION_CACHE_FILE="${DOT_SESSION_CACHE_DIR}/session"
typeset -g DOT_SESSION_IDLE_TIMEOUT=${DOT_SESSION_IDLE_TIMEOUT:-900}  # 15 min default

# =============================================================================
# Function: _dot_session_cache_init
# Purpose: Initialize session cache directory with secure permissions
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   _dot_session_cache_init
#
# Notes:
#   - Creates ~/.cache/dot with mode 700 (user-only access)
#   - Called automatically by other session functions
# =============================================================================
_dot_session_cache_init() {
  if [[ ! -d "$DOT_SESSION_CACHE_DIR" ]]; then
    mkdir -p "$DOT_SESSION_CACHE_DIR" 2>/dev/null
    chmod 700 "$DOT_SESSION_CACHE_DIR"  # Secure permissions
  fi
}

# =============================================================================
# Function: _dot_session_cache_save
# Purpose: Save Bitwarden session metadata to cache after unlock
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   # After successful bw unlock
#   _dot_session_cache_save
#
# Notes:
#   - Creates cache file with mode 600 (user read/write only)
#   - Stores UNLOCK_TIME, LAST_ACTIVITY, IDLE_TIMEOUT
#   - Call after every successful bw unlock
# =============================================================================
_dot_session_cache_save() {
  _dot_session_cache_init
  local now=$(date +%s)
  cat > "$DOT_SESSION_CACHE_FILE" << EOF
UNLOCK_TIME=$now
LAST_ACTIVITY=$now
IDLE_TIMEOUT=$DOT_SESSION_IDLE_TIMEOUT
EOF
  chmod 600 "$DOT_SESSION_CACHE_FILE"  # Secure permissions
}

# =============================================================================
# Function: _dot_session_cache_touch
# Purpose: Update last activity timestamp to prevent idle timeout
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   # Before each Bitwarden operation
#   _dot_session_cache_touch
#   bw get item "secret-name"
#
# Notes:
#   - Updates LAST_ACTIVITY in cache file
#   - macOS and Linux compatible (different sed syntax)
#   - Extends session timeout on activity
# =============================================================================
_dot_session_cache_touch() {
  if [[ -f "$DOT_SESSION_CACHE_FILE" ]]; then
    local now=$(date +%s)
    # Update LAST_ACTIVITY line
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/^LAST_ACTIVITY=.*/LAST_ACTIVITY=$now/" "$DOT_SESSION_CACHE_FILE" 2>/dev/null
    else
      sed -i "s/^LAST_ACTIVITY=.*/LAST_ACTIVITY=$now/" "$DOT_SESSION_CACHE_FILE" 2>/dev/null
    fi
  fi
}

# =============================================================================
# Function: _dot_session_cache_expired
# Purpose: Check if Bitwarden session has exceeded idle timeout
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Session is expired or cache doesn't exist
#   1 - Session is still valid
#
# Example:
#   if _dot_session_cache_expired; then
#       echo "Please unlock Bitwarden again"
#   fi
#
# Notes:
#   - Default timeout: 15 minutes (DOT_SESSION_IDLE_TIMEOUT)
#   - Configurable via environment variable
#   - No cache file = expired
# =============================================================================
_dot_session_cache_expired() {
  if [[ ! -f "$DOT_SESSION_CACHE_FILE" ]]; then
    return 0  # No cache = expired
  fi

  # Read cache values
  local unlock_time=0
  local last_activity=0
  local idle_timeout=$DOT_SESSION_IDLE_TIMEOUT

  source "$DOT_SESSION_CACHE_FILE" 2>/dev/null

  # Check if variables were read
  if [[ -z "$LAST_ACTIVITY" || "$LAST_ACTIVITY" == "0" ]]; then
    return 0  # Invalid cache = expired
  fi

  local now=$(date +%s)
  local idle_seconds=$((now - LAST_ACTIVITY))

  if [[ $idle_seconds -ge $idle_timeout ]]; then
    return 0  # Expired
  fi

  return 1  # Not expired
}

# =============================================================================
# Function: _dot_session_cache_clear
# Purpose: Clear Bitwarden session cache and unset BW_SESSION
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   _dot_session_cache_clear
#   # Session is now locked
#
# Notes:
#   - Removes cache file
#   - Unsets BW_SESSION environment variable
#   - Call on explicit lock or detected session expiry
# =============================================================================
_dot_session_cache_clear() {
  if [[ -f "$DOT_SESSION_CACHE_FILE" ]]; then
    rm -f "$DOT_SESSION_CACHE_FILE"
  fi
  unset BW_SESSION
}

# =============================================================================
# Function: _dot_session_time_remaining
# Purpose: Get seconds remaining before session idle timeout
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Seconds remaining (0 if expired or no cache)
#
# Example:
#   remaining=$(_dot_session_time_remaining)
#   echo "$remaining seconds left"
#
# Notes:
#   - Returns 0 for expired/missing sessions
#   - Used by status displays
# =============================================================================
_dot_session_time_remaining() {
  if [[ ! -f "$DOT_SESSION_CACHE_FILE" ]]; then
    echo "0"
    return
  fi

  source "$DOT_SESSION_CACHE_FILE" 2>/dev/null

  local now=$(date +%s)
  local idle_seconds=$((now - LAST_ACTIVITY))
  local remaining=$((DOT_SESSION_IDLE_TIMEOUT - idle_seconds))

  if [[ $remaining -lt 0 ]]; then
    echo "0"
  else
    echo "$remaining"
  fi
}

# =============================================================================
# Function: _dot_session_time_remaining_fmt
# Purpose: Get human-readable time remaining until session expires
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Formatted time (e.g., "5 min", "30 sec", "expired")
#
# Example:
#   echo "Session expires in: $(_dot_session_time_remaining_fmt)"
#
# Notes:
#   - Shows minutes if > 60 seconds
#   - Shows seconds if < 60 seconds
#   - Returns "expired" if no time remaining
# =============================================================================
_dot_session_time_remaining_fmt() {
  local remaining=$(_dot_session_time_remaining)
  if [[ $remaining -le 0 ]]; then
    echo "expired"
  else
    local minutes=$((remaining / 60))
    local seconds=$((remaining % 60))
    if [[ $minutes -gt 0 ]]; then
      echo "${minutes} min"
    else
      echo "${seconds} sec"
    fi
  fi
}

# =============================================================================
# Function: _dot_bw_session_valid
# Purpose: Check if Bitwarden session is valid and not timed out
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Session is valid and active
#   1 - Session invalid, expired, or bw not installed
#
# Example:
#   if _dot_bw_session_valid; then
#       bw get item "my-secret"
#   else
#       echo "Please unlock: dot secret unlock"
#   fi
#
# Notes:
#   - Checks BW_SESSION environment variable
#   - Verifies cache timeout (15 min idle)
#   - Validates with bw unlock --check
#   - Updates activity time on successful check
# =============================================================================
_dot_bw_session_valid() {
  if ! _dot_has_bw; then
    return 1
  fi

  if [[ -z "$BW_SESSION" ]]; then
    return 1
  fi

  # Check cache timeout (15 min idle)
  if _dot_session_cache_expired; then
    _dot_session_cache_clear
    return 1
  fi

  # Validate session with Bitwarden
  if ! bw unlock --check &>/dev/null; then
    _dot_session_cache_clear
    return 1
  fi

  # Update activity time on successful check
  _dot_session_cache_touch
  return 0
}

# =============================================================================
# Function: _dot_bw_get_status
# Purpose: Get current Bitwarden vault status
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Status retrieved successfully
#   1 - Bitwarden not installed
#
# Output:
#   stdout - Status string: "locked"|"unlocked"|"unauthenticated"|
#            "not-installed"|"error"
#
# Example:
#   status=$(_dot_bw_get_status)
#   case "$status" in
#       unlocked) echo "Ready to use" ;;
#       locked) echo "Needs unlock" ;;
#   esac
#
# Notes:
#   - Uses bw status JSON output
#   - "unauthenticated" means not logged in
# =============================================================================
_dot_bw_get_status() {
  if ! _dot_has_bw; then
    echo "not-installed"
    return 1
  fi

  local bw_status
  bw_status=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

  if [[ -z "$bw_status" ]]; then
    echo "error"
  else
    echo "$bw_status"
  fi
}

# ============================================================================
# SECURITY HELPERS (Phase 3)
# ============================================================================

# =============================================================================
# Function: _dot_security_init
# Purpose: Initialize security settings to prevent secret leakage in history
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   _dot_security_init  # Called automatically on load
#
# Notes:
#   - Adds patterns to HISTIGNORE to prevent storing secrets
#   - Excludes: bw unlock, bw get, BW_SESSION, dot secret
#   - Called automatically when helpers are loaded
# =============================================================================
_dot_security_init() {
  # Add Bitwarden commands to history exclusion
  # This prevents BW_SESSION tokens from being stored in history
  if [[ -z "$HISTIGNORE" ]]; then
    export HISTIGNORE="*bw unlock*:*bw get*:*BW_SESSION*:*dot secret*"
  else
    # Append if not already present
    if [[ ! "$HISTIGNORE" =~ "bw unlock" ]]; then
      export HISTIGNORE="${HISTIGNORE}:*bw unlock*:*bw get*:*BW_SESSION*:*dot secret*"
    fi
  fi
}

# =============================================================================
# Function: _dot_security_check_bw_session
# Purpose: Check for insecure BW_SESSION exports in shell startup files
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - No security issues found
#   1 - BW_SESSION found in startup files (security risk)
#
# Example:
#   if ! _dot_security_check_bw_session; then
#       echo "Security issue detected!"
#   fi
#
# Notes:
#   - Checks .zshrc, .zshenv, .zprofile
#   - BW_SESSION should NOT be exported globally
#   - Shows warning with remediation steps
# =============================================================================
_dot_security_check_bw_session() {
  # Check if BW_SESSION is in shell startup files
  # Use ZDOTDIR if set, otherwise fall back to HOME
  local config_files=(
    "${ZDOTDIR:-$HOME}/.zshrc"
    "${ZDOTDIR:-$HOME}/.zshenv"
    "${ZDOTDIR:-$HOME}/.zprofile"
  )

  local found_global=false
  for file in "${config_files[@]}"; do
    if [[ -f "$file" ]] && grep -q "export BW_SESSION" "$file" 2>/dev/null; then
      found_global=true
      _flow_log_error "Security issue: BW_SESSION exported in $file"
    fi
  done

  if $found_global; then
    _flow_log_warning "BW_SESSION should NOT be exported globally"
    _flow_log_info "Remove 'export BW_SESSION' from startup files"
    return 1
  fi

  return 0
}

# Initialize security settings when helpers are loaded
_dot_security_init

# ============================================================================
# FORMATTING HELPERS
# ============================================================================

# =============================================================================
# Function: _dot_format_time_ago
# Purpose: Format relative time string for display (passthrough)
# =============================================================================
# Arguments:
#   $1 - (required) Time string to format
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Formatted time string (currently passthrough)
#
# Example:
#   echo $(_dot_format_time_ago "2 hours ago")
#
# Notes:
#   - Currently passthrough function for future formatting
#   - Handles "unknown" and "not-initialized" states
# =============================================================================
_dot_format_time_ago() {
  local time_str=$1

  if [[ "$time_str" == "unknown" ]] || [[ "$time_str" == "not-initialized" ]]; then
    echo "$time_str"
  else
    echo "$time_str"
  fi
}

# =============================================================================
# Function: _dot_format_file_count
# Purpose: Format file count with proper singular/plural grammar
# =============================================================================
# Arguments:
#   $1 - (required) Count number
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Formatted string (e.g., "1 file" or "5 files")
#
# Example:
#   echo $(_dot_format_file_count 1)   # "1 file"
#   echo $(_dot_format_file_count 5)   # "5 files"
#
# Notes:
#   - Handles singular/plural correctly
#   - Used in status displays
# =============================================================================
_dot_format_file_count() {
  local count=$1

  if [[ $count -eq 1 ]]; then
    echo "1 file"
  else
    echo "$count files"
  fi
}
