# lib/dotfile-helpers.zsh - Dotfile management helper functions
# Provides: tool detection, status helpers, path resolution
# Used by: dots, sec, tok dispatchers

# ============================================================================
# TOOL DETECTION (with caching)
# ============================================================================

# Cache tool availability (checked once per session)
typeset -g _FLOW_DOTF_CHEZMOI_AVAILABLE
typeset -g _FLOW_DOTF_BW_AVAILABLE
typeset -g _FLOW_DOTF_MISE_AVAILABLE

# =============================================================================
# Function: _dotf_has_chezmoi
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
#   if _dotf_has_chezmoi; then
#       chezmoi apply
#   else
#       echo "Install chezmoi first"
#   fi
#
# Notes:
#   - Result cached in $_FLOW_DOTF_CHEZMOI_AVAILABLE for session duration
#   - First call performs actual command check, subsequent calls use cache
# =============================================================================
_dotf_has_chezmoi() {
  # Return cached result if available
  if [[ -n "$_FLOW_DOTF_CHEZMOI_AVAILABLE" ]]; then
    [[ "$_FLOW_DOTF_CHEZMOI_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if chezmoi command exists
  if command -v chezmoi &>/dev/null; then
    _FLOW_DOTF_CHEZMOI_AVAILABLE="yes"
    return 0
  else
    _FLOW_DOTF_CHEZMOI_AVAILABLE="no"
    return 1
  fi
}

# =============================================================================
# Function: _dotf_has_bw
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
#   if _dotf_has_bw; then
#       bw status
#   fi
#
# Notes:
#   - Result cached in $_FLOW_DOTF_BW_AVAILABLE for session duration
#   - Used by secret management commands (sec)
# =============================================================================
_dotf_has_bw() {
  # Return cached result if available
  if [[ -n "$_FLOW_DOTF_BW_AVAILABLE" ]]; then
    [[ "$_FLOW_DOTF_BW_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if bw command exists
  if command -v bw &>/dev/null; then
    _FLOW_DOTF_BW_AVAILABLE="yes"
    return 0
  else
    _FLOW_DOTF_BW_AVAILABLE="no"
    return 1
  fi
}

# =============================================================================
# Function: _dotf_has_mise
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
#   if _dotf_has_mise; then
#       mise install
#   fi
#
# Notes:
#   - Result cached in $_FLOW_DOTF_MISE_AVAILABLE for session duration
#   - mise manages runtime versions (Node, Python, Ruby, etc.)
# =============================================================================
_dotf_has_mise() {
  # Return cached result if available
  if [[ -n "$_FLOW_DOTF_MISE_AVAILABLE" ]]; then
    [[ "$_FLOW_DOTF_MISE_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if mise command exists
  if command -v mise &>/dev/null; then
    _FLOW_DOTF_MISE_AVAILABLE="yes"
    return 0
  else
    _FLOW_DOTF_MISE_AVAILABLE="no"
    return 1
  fi
}

# =============================================================================
# Function: _dotf_require_tool
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
#   _dotf_require_tool "chezmoi" "brew install chezmoi"
#   _dotf_require_tool "yq"  # Uses default brew install
#
# Notes:
#   - Displays formatted error message with install instructions
#   - Used at start of commands that depend on external tools
# =============================================================================
_dotf_require_tool() {
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
# Function: _dotf_get_sync_status
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
#   status=$(_dotf_get_sync_status)
#   if [[ "$status" == "modified" ]]; then
#       echo "You have uncommitted changes"
#   fi
#
# Notes:
#   - Checks chezmoi status and git remote state
#   - "modified" means local changes not yet committed
#   - "ahead/behind" refers to git commits vs remote
# =============================================================================
_dotf_get_sync_status() {
  if ! _dotf_has_chezmoi; then
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
    if _dotf_is_ahead_of_remote; then
      echo "ahead"
    elif _dotf_is_behind_remote; then
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
# Function: _dotf_is_ahead_of_remote
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
#   if _dotf_is_ahead_of_remote; then
#       echo "Run 'dots push' to sync changes"
#   fi
#
# Notes:
#   - Checks ~/.local/share/chezmoi/.git status
#   - Uses git rev-list to compare HEAD with upstream
# =============================================================================
_dotf_is_ahead_of_remote() {
  if ! _dotf_has_chezmoi; then
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
# Function: _dotf_is_behind_remote
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
#   if _dotf_is_behind_remote; then
#       echo "Run 'dots pull' to get latest changes"
#   fi
#
# Notes:
#   - Performs git fetch before comparing
#   - Checks ~/.local/share/chezmoi/.git status
# =============================================================================
_dotf_is_behind_remote() {
  if ! _dotf_has_chezmoi; then
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
# Function: _dotf_get_modified_files
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
#   files=$(_dotf_get_modified_files)
#   echo "Modified: $files"
#
# Notes:
#   - Returns relative paths from chezmoi status
#   - Empty output means no modifications
# =============================================================================
_dotf_get_modified_files() {
  if ! _dotf_has_chezmoi; then
    return 1
  fi

  chezmoi status 2>/dev/null | awk '{print $2}'
}

# =============================================================================
# Function: _dotf_get_modified_count
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
#   count=$(_dotf_get_modified_count)
#   [[ $count -gt 0 ]] && echo "$count files need syncing"
#
# Notes:
#   - Returns "0" if chezmoi not available (graceful degradation)
#   - Sanitizes output to ensure valid numeric format
# =============================================================================
_dotf_get_modified_count() {
  if ! _dotf_has_chezmoi; then
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
# Function: _dotf_get_last_sync_time
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
#   last_sync=$(_dotf_get_last_sync_time)
#   echo "Last synced: $last_sync"
#
# Notes:
#   - Uses git log --format=%ar for relative time
#   - Reads from ~/.local/share/chezmoi/.git
# =============================================================================
_dotf_get_last_sync_time() {
  if ! _dotf_has_chezmoi; then
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
# Function: _dotf_get_tracked_count
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
#   tracked=$(_dotf_get_tracked_count)
#   echo "Managing $tracked dotfiles"
#
# Notes:
#   - Returns "0" if chezmoi not available
#   - Uses chezmoi managed command
# =============================================================================
_dotf_get_tracked_count() {
  if ! _dotf_has_chezmoi; then
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
# Function: _dotf_format_status
# Purpose: Format sync status with colored icon for terminal display
# =============================================================================
# Arguments:
#   $1 - (required) Status string from _dotf_get_sync_status
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Formatted status with emoji and ANSI colors
#
# Example:
#   status=$(_dotf_get_sync_status)
#   echo $(_dotf_format_status "$status")
#   # Output: 🟢 Synced (in green)
#
# Notes:
#   - Uses FLOW_COLORS associative array for theming
#   - Status values: synced, modified, behind, ahead, conflict,
#     not-installed, not-initialized, error
# =============================================================================
_dotf_format_status() {
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
# Function: _dotf_get_status_line
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
#   if line=$(_dotf_get_status_line); then
#       echo "$line"
#   fi
#
# Notes:
#   - Returns 1 for error states (no output shown in dashboard)
#   - Includes commit count for ahead/behind states
#   - Uses FLOW_COLORS for consistent theming
# =============================================================================
_dotf_get_status_line() {
  if ! _dotf_has_chezmoi; then
    return 1
  fi

  # Get status components (with timeout to keep it fast)
  local sync_status=$(_dotf_get_sync_status)
  local tracked_count=$(_dotf_get_tracked_count)
  local last_sync=$(_dotf_get_last_sync_time)
  local modified_count=$(_dotf_get_modified_count)

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
# Function: _dotf_resolve_file_path
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
#   path=$(_dotf_resolve_file_path "zshrc")
#   # Returns: /Users/user/.config/zsh/.zshrc
#
#   _dotf_resolve_file_path "vim"  # Multiple matches
#   # Returns all vim-related files, exit code 2
#
# Notes:
#   - Full paths (starting with / or ~) returned as-is
#   - Searches chezmoi managed files with grep -i
#   - Returns absolute paths (prepends $HOME)
# =============================================================================
_dotf_resolve_file_path() {
  local search_term=$1

  if ! _dotf_has_chezmoi; then
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

# ============================================================================
# CHEZMOI SAFETY CACHE (Phase 1)
# ============================================================================

# Cache variables for Chezmoi size and ignore patterns
typeset -g _DOT_SIZE_CACHE
typeset -g _DOT_SIZE_CACHE_TIME
typeset -g _DOT_IGNORE_CACHE
typeset -g _DOT_IGNORE_CACHE_TIME

# Cache TTL (5 minutes = 300 seconds)
typeset -g _DOT_CACHE_TTL=300

# =============================================================================
# Function: _dotf_session_cache_init
# Purpose: Initialize session cache directory with secure permissions
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   _dotf_session_cache_init
#
# Notes:
#   - Creates ~/.cache/dot with mode 700 (user-only access)
#   - Called automatically by other session functions
# =============================================================================
_dotf_session_cache_init() {
  if [[ ! -d "$DOT_SESSION_CACHE_DIR" ]]; then
    mkdir -p "$DOT_SESSION_CACHE_DIR" 2>/dev/null
    chmod 700 "$DOT_SESSION_CACHE_DIR"  # Secure permissions
  fi
}

# =============================================================================
# Function: _dotf_session_cache_save
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
#   _dotf_session_cache_save
#
# Notes:
#   - Creates cache file with mode 600 (user read/write only)
#   - Stores UNLOCK_TIME, LAST_ACTIVITY, IDLE_TIMEOUT
#   - Call after every successful bw unlock
# =============================================================================
_dotf_session_cache_save() {
  _dotf_session_cache_init
  local now=$(date +%s)
  cat > "$DOT_SESSION_CACHE_FILE" << EOF
UNLOCK_TIME=$now
LAST_ACTIVITY=$now
IDLE_TIMEOUT=$DOT_SESSION_IDLE_TIMEOUT
EOF
  chmod 600 "$DOT_SESSION_CACHE_FILE"  # Secure permissions
}

# =============================================================================
# Function: _dotf_session_cache_touch
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
#   _dotf_session_cache_touch
#   bw get item "secret-name"
#
# Notes:
#   - Updates LAST_ACTIVITY in cache file
#   - macOS and Linux compatible (different sed syntax)
#   - Extends session timeout on activity
# =============================================================================
_dotf_session_cache_touch() {
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
# Function: _dotf_session_cache_expired
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
#   if _dotf_session_cache_expired; then
#       echo "Please unlock Bitwarden again"
#   fi
#
# Notes:
#   - Default timeout: 15 minutes (DOT_SESSION_IDLE_TIMEOUT)
#   - Configurable via environment variable
#   - No cache file = expired
# =============================================================================
_dotf_session_cache_expired() {
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
# Function: _dotf_session_cache_clear
# Purpose: Clear Bitwarden session cache and unset BW_SESSION
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   _dotf_session_cache_clear
#   # Session is now locked
#
# Notes:
#   - Removes cache file
#   - Unsets BW_SESSION environment variable
#   - Call on explicit lock or detected session expiry
# =============================================================================
_dotf_session_cache_clear() {
  if [[ -f "$DOT_SESSION_CACHE_FILE" ]]; then
    rm -f "$DOT_SESSION_CACHE_FILE"
  fi
  unset BW_SESSION
}

# =============================================================================
# Function: _dotf_session_time_remaining
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
#   remaining=$(_dotf_session_time_remaining)
#   echo "$remaining seconds left"
#
# Notes:
#   - Returns 0 for expired/missing sessions
#   - Used by status displays
# =============================================================================
_dotf_session_time_remaining() {
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
# Function: _dotf_session_time_remaining_fmt
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
#   echo "Session expires in: $(_dotf_session_time_remaining_fmt)"
#
# Notes:
#   - Shows minutes if > 60 seconds
#   - Shows seconds if < 60 seconds
#   - Returns "expired" if no time remaining
# =============================================================================
_dotf_session_time_remaining_fmt() {
  local remaining=$(_dotf_session_time_remaining)
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
# Function: _dotf_bw_session_valid
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
#   if _dotf_bw_session_valid; then
#       bw get item "my-secret"
#   else
#       echo "Please unlock: sec unlock"
#   fi
#
# Notes:
#   - Checks BW_SESSION environment variable
#   - Verifies cache timeout (15 min idle)
#   - Validates with bw unlock --check
#   - Updates activity time on successful check
# =============================================================================
_dotf_bw_session_valid() {
  if ! _dotf_has_bw; then
    return 1
  fi

  if [[ -z "$BW_SESSION" ]]; then
    return 1
  fi

  # Check cache timeout (15 min idle)
  if _dotf_session_cache_expired; then
    _dotf_session_cache_clear
    return 1
  fi

  # Validate session with Bitwarden
  if ! bw unlock --check &>/dev/null; then
    _dotf_session_cache_clear
    return 1
  fi

  # Update activity time on successful check
  _dotf_session_cache_touch
  return 0
}

# =============================================================================
# Function: _dotf_bw_get_status
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
#   status=$(_dotf_bw_get_status)
#   case "$status" in
#       unlocked) echo "Ready to use" ;;
#       locked) echo "Needs unlock" ;;
#   esac
#
# Notes:
#   - Uses bw status JSON output
#   - "unauthenticated" means not logged in
# =============================================================================
_dotf_bw_get_status() {
  if ! _dotf_has_bw; then
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
# CHEZMOI SAFETY CACHE HELPERS (Phase 1)
# ============================================================================

# =============================================================================
# Function: _dotf_is_cache_valid
# Purpose: Check if a cache is still valid based on TTL
# =============================================================================
# Arguments:
#   $1 - (required) Cache timestamp (Unix epoch seconds)
#   $2 - (optional) Custom TTL in seconds [default: $_DOT_CACHE_TTL]
#
# Returns:
#   0 - Cache is valid (age < TTL)
#   1 - Cache is expired or invalid (no timestamp)
#
# Example:
#   if _dotf_is_cache_valid "$_DOT_SIZE_CACHE_TIME"; then
#       echo "Cache still valid"
#   fi
#
#   # Custom TTL (10 minutes)
#   if _dotf_is_cache_valid "$cache_time" 600; then
#       echo "Cache valid for 10 minutes"
#   fi
#
# Notes:
#   - Returns 1 if cache_time is empty (no cache)
#   - Uses $_DOT_CACHE_TTL (300s / 5min) by default
#   - Calculates age as (now - cache_time) in seconds
# =============================================================================
_dotf_is_cache_valid() {
    local cache_time="$1"
    local ttl="${2:-$_DOT_CACHE_TTL}"

    if [[ -z "$cache_time" ]]; then
        return 1
    fi

    local now=$(date +%s)
    local age=$((now - cache_time))

    (( age < ttl ))
}

# =============================================================================
# Function: _dotf_get_cached_size
# Purpose: Retrieve cached Chezmoi size if still valid
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Cache is valid, size returned via stdout
#   1 - Cache expired or empty (no size returned)
#
# Output:
#   stdout - Cached size value if valid
#
# Example:
#   if size=$(_dotf_get_cached_size); then
#       echo "Cached size: $size"
#   else
#       size=$(du -sh ~/.local/share/chezmoi)
#       _dotf_cache_size "$size"
#   fi
#
# Notes:
#   - Checks $_DOT_SIZE_CACHE_TIME validity
#   - Returns cached value from $_DOT_SIZE_CACHE
#   - Returns 1 if cache expired or not set
# =============================================================================
_dotf_get_cached_size() {
    if _dotf_is_cache_valid "$_DOT_SIZE_CACHE_TIME"; then
        echo "$_DOT_SIZE_CACHE"
        return 0
    fi
    return 1
}

# =============================================================================
# Function: _dotf_cache_size
# Purpose: Store Chezmoi size in cache with current timestamp
# =============================================================================
# Arguments:
#   $1 - (required) Size value to cache
#
# Returns:
#   0 - Always
#
# Example:
#   size=$(du -sh ~/.local/share/chezmoi | awk '{print $1}')
#   _dotf_cache_size "$size"
#
# Notes:
#   - Sets $_DOT_SIZE_CACHE to provided value
#   - Sets $_DOT_SIZE_CACHE_TIME to current Unix timestamp
#   - Call after computing expensive size calculation
# =============================================================================
_dotf_cache_size() {
    _DOT_SIZE_CACHE="$1"
    _DOT_SIZE_CACHE_TIME=$(date +%s)
}

# =============================================================================
# Function: _dotf_get_cached_ignore
# Purpose: Retrieve cached Chezmoi ignore patterns if still valid
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Cache is valid, patterns returned via stdout
#   1 - Cache expired or empty (no patterns returned)
#
# Output:
#   stdout - Cached ignore patterns if valid
#
# Example:
#   if patterns=$(_dotf_get_cached_ignore); then
#       echo "$patterns"
#   else
#       patterns=$(chezmoi ignored)
#       _dotf_cache_ignore "$patterns"
#   fi
#
# Notes:
#   - Checks $_DOT_IGNORE_CACHE_TIME validity
#   - Returns cached value from $_DOT_IGNORE_CACHE
#   - Returns 1 if cache expired or not set
# =============================================================================
_dotf_get_cached_ignore() {
    if _dotf_is_cache_valid "$_DOT_IGNORE_CACHE_TIME"; then
        echo "$_DOT_IGNORE_CACHE"
        return 0
    fi
    return 1
}

# =============================================================================
# Function: _dotf_cache_ignore
# Purpose: Store Chezmoi ignore patterns in cache with current timestamp
# =============================================================================
# Arguments:
#   $1 - (required) Ignore patterns to cache
#
# Returns:
#   0 - Always
#
# Example:
#   patterns=$(chezmoi ignored)
#   _dotf_cache_ignore "$patterns"
#
# Notes:
#   - Sets $_DOT_IGNORE_CACHE to provided value
#   - Sets $_DOT_IGNORE_CACHE_TIME to current Unix timestamp
#   - Call after computing expensive ignore pattern check
# =============================================================================
_dotf_cache_ignore() {
    _DOT_IGNORE_CACHE="$1"
    _DOT_IGNORE_CACHE_TIME=$(date +%s)
}

# ============================================================================
# SECURITY HELPERS (Phase 3)
# ============================================================================

# =============================================================================
# Function: _dotf_security_init
# Purpose: Initialize security settings to prevent secret leakage in history
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Example:
#   _dotf_security_init  # Called automatically on load
#
# Notes:
#   - Adds patterns to HISTIGNORE to prevent storing secrets
#   - Excludes: bw unlock, bw get, BW_SESSION, sec
#   - Called automatically when helpers are loaded
# =============================================================================
_dotf_security_init() {
  # Add Bitwarden commands to history exclusion
  # This prevents BW_SESSION tokens from being stored in history
  if [[ -z "$HISTIGNORE" ]]; then
    export HISTIGNORE="*bw unlock*:*bw get*:*BW_SESSION*:*sec *"
  else
    # Append if not already present
    if [[ ! "$HISTIGNORE" =~ "bw unlock" ]]; then
      export HISTIGNORE="${HISTIGNORE}:*bw unlock*:*bw get*:*BW_SESSION*:*sec *"
    fi
  fi
}

# =============================================================================
# Function: _dotf_security_check_bw_session
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
#   if ! _dotf_security_check_bw_session; then
#       echo "Security issue detected!"
#   fi
#
# Notes:
#   - Checks .zshrc, .zshenv, .zprofile
#   - BW_SESSION should NOT be exported globally
#   - Shows warning with remediation steps
# =============================================================================
_dotf_security_check_bw_session() {
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
_dotf_security_init

# ============================================================================
# GIT SAFETY HELPERS (Phase 2)
# ============================================================================

# =============================================================================
# Function: _dotf_check_git_in_path
# Purpose: Detect .git directories in target path before chezmoi tracking
# =============================================================================
# Arguments:
#   $1 - (required) Target path to scan for .git directories
#
# Returns:
#   0 - .git directories found (paths returned via stdout)
#   1 - No .git directories found
#
# Output:
#   stdout - Space-separated list of .git directory paths
#
# Example:
#   if git_dirs=$(_dotf_check_git_in_path "$target"); then
#       _flow_log_warning "Found .git directories: $git_dirs"
#   fi
#
# Notes:
#   - Performance optimized:
#     1. Checks target/.git first (fast)
#     2. For git repos, uses 'git submodule status' (faster than find)
#     3. For non-git dirs, uses find with 2s timeout
#   - Handles symlinks with user confirmation
#   - Warns on large directories (1000+ files)
#   - Uses _flow_timeout for cross-platform timeout support
#   - Maxdepth 5 to prevent deep recursion
# =============================================================================
_dotf_check_git_in_path() {
    local target="$1"
    local git_dirs=()

    # Handle symlinks
    if [[ -L "$target" ]]; then
        _flow_log_warning "Target is a symlink: $target"
        read -q "REPLY?Follow symlink and scan target? (Y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            # Resolve symlink (try readlink -f first, fallback to realpath)
            local resolved
            resolved=$(readlink -f "$target" 2>/dev/null || realpath "$target" 2>/dev/null)
            if [[ -n "$resolved" ]]; then
                target="$resolved"
                _flow_log_info "Following to: $target"
            else
                _flow_log_error "Failed to resolve symlink"
                return 1
            fi
        else
            # User declined to follow - check only symlink target
            local real_target=$(readlink "$target" 2>/dev/null)
            if [[ -n "$real_target" ]] && [[ -d "${real_target}/.git" ]]; then
                git_dirs+=("${real_target}/.git")
            fi
            if (( ${#git_dirs[@]} > 0 )); then
                echo "${git_dirs[@]}"
                return 0
            fi
            return 1
        fi
    fi

    # Check if target itself has .git (fast check)
    if [[ -d "$target/.git" ]]; then
        git_dirs+=("$target/.git")
    fi

    # Performance optimization: use git commands if it's a git repo
    if [[ -d "$target/.git" ]] && command -v git &>/dev/null; then
        # Fast path: check for git submodules
        local submodule_count
        submodule_count=$(git -C "$target" submodule status 2>/dev/null | wc -l | tr -d ' ')

        # Sanitize count
        submodule_count="${submodule_count##*( )}"
        submodule_count="${submodule_count%%*( )}"
        [[ "$submodule_count" =~ ^[0-9]+$ ]] || submodule_count=0

        if (( submodule_count > 0 )); then
            _flow_log_info "Found $submodule_count git submodule(s) in $target"
            # Add submodule .git directories
            while IFS= read -r submodule_path; do
                local sub_git_dir="${target}/${submodule_path}/.git"
                [[ -d "$sub_git_dir" ]] && git_dirs+=("$sub_git_dir")
            done < <(git -C "$target" submodule foreach --quiet 'echo $sm_path' 2>/dev/null)
        fi
    else
        # Slow path: use find with timeout for non-git directories
        # Check directory size first
        local file_count
        file_count=$(find "$target" -type f 2>/dev/null | head -1000 | wc -l | tr -d ' ')

        # Sanitize count
        file_count="${file_count##*( )}"
        file_count="${file_count%%*( )}"
        [[ "$file_count" =~ ^[0-9]+$ ]] || file_count=0

        if (( file_count >= 1000 )); then
            _flow_log_info "Large directory detected. Git scan may take a few seconds..."
        fi

        # Use timeout wrapper (2 second limit)
        local find_result
        while IFS= read -r gitdir; do
            git_dirs+=("$gitdir")
        done < <(_flow_timeout 2 find "$target" -name ".git" -type d -maxdepth 5 2>/dev/null)

        # Check if find timed out (exit code 124)
        local find_exit=$?
        if (( find_exit == 124 )); then
            _flow_log_warning "Git directory scan timed out after 2 seconds"
            _flow_log_info "Large directories may have .git subdirectories not detected"
        fi
    fi

    # Return results
    if (( ${#git_dirs[@]} > 0 )); then
        echo "${git_dirs[@]}"
        return 0
    fi
    return 1
}

# ============================================================================
# FORMATTING HELPERS
# ============================================================================

# =============================================================================
# Function: _dotf_format_time_ago
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
#   echo $(_dotf_format_time_ago "2 hours ago")
#
# Notes:
#   - Currently passthrough function for future formatting
#   - Handles "unknown" and "not-initialized" states
# =============================================================================
_dotf_format_time_ago() {
  local time_str=$1

  if [[ "$time_str" == "unknown" ]] || [[ "$time_str" == "not-initialized" ]]; then
    echo "$time_str"
  else
    echo "$time_str"
  fi
}

# =============================================================================
# Function: _dotf_format_file_count
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
#   echo $(_dotf_format_file_count 1)   # "1 file"
#   echo $(_dotf_format_file_count 5)   # "5 files"
#
# Notes:
#   - Handles singular/plural correctly
#   - Used in status displays
# =============================================================================
_dotf_format_file_count() {
  local count=$1

  if [[ $count -eq 1 ]]; then
    echo "1 file"
  else
    echo "$count files"
  fi
}

# ============================================================================
# OUTPUT HELPERS (for dot commands)
# ============================================================================

# =============================================================================
# Function: _dotf_warn
# Purpose: Display warning message with dot context
# =============================================================================
# Arguments:
#   $1 - (required) Warning message
#
# Returns:
#   0 - Always
#
# Example:
#   _dotf_warn "Large file detected: config.db"
#
# Notes:
#   - Wrapper around _flow_log_warning for consistency
# =============================================================================
_dotf_warn() {
  _flow_log_warning "$@"
}

# =============================================================================
# Function: _dotf_info
# Purpose: Display info message with dot context
# =============================================================================
# Arguments:
#   $1 - (required) Info message
#
# Returns:
#   0 - Always
#
# Example:
#   _dotf_info "Scanning directory..."
#
# Notes:
#   - Wrapper around _flow_log_info for consistency
# =============================================================================
_dotf_info() {
  _flow_log_info "$@"
}

# =============================================================================
# Function: _dotf_success
# Purpose: Display success message with dot context
# =============================================================================
# Arguments:
#   $1 - (required) Success message
#
# Returns:
#   0 - Always
#
# Example:
#   _dotf_success "Added 3 files to chezmoi"
#
# Notes:
#   - Wrapper around _flow_log_success for consistency
# =============================================================================
_dotf_success() {
  _flow_log_success "$@"
}

# =============================================================================
# Function: _dotf_header
# Purpose: Display section header with dot context
# =============================================================================
# Arguments:
#   $1 - (required) Header text
#
# Returns:
#   0 - Always
#
# Example:
#   _dotf_header "Preview: dots add ~/.config"
#
# Notes:
#   - Uses heavy box drawing for visual separation
#   - FLOW_COLORS[bold] for emphasis
# =============================================================================
_dotf_header() {
  local text="$1"
  echo ""
  echo "${FLOW_COLORS[bold]}${text}${FLOW_COLORS[reset]}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================================
# CHEZMOI SAFETY - PREVIEW & AUTO-SUGGESTION (Phase 1)
# ============================================================================

# =============================================================================
# Function: _dotf_preview_add
# Purpose: Preview files before adding to chezmoi with safety warnings
# =============================================================================
# Arguments:
#   $1 - (required) Target path to add (file or directory)
#
# Returns:
#   0 - User confirmed, proceed with add
#   1 - User cancelled or error
#
# Example:
#   if _dotf_preview_add "$target"; then
#       chezmoi add "$target"
#   fi
#
# Notes:
#   - Shows file count, total size
#   - Warns about large files (>50KB = 51200 bytes)
#   - Warns about generated files (.log, .sqlite, .db, .cache)
#   - Warns about git metadata (/.git/ in path)
#   - Offers auto-ignore suggestions
#   - Uses _flow_get_file_size() and _flow_human_size() from Wave 1
# =============================================================================
_dotf_preview_add() {
  local target="$1"

  # Validate target exists
  if [[ ! -e "$target" ]]; then
    _flow_log_error "Target not found: $target"
    return 1
  fi

  # Display header
  _dotf_header "Preview: dots add $target"

  # Collect file information
  local file_count=0
  local total_bytes=0
  local large_files=()
  local generated_files=()
  local git_files=0
  local all_files=()

  # Handle single file vs directory
  if [[ -f "$target" ]]; then
    # Single file
    file_count=1
    all_files+=("$target")
    local size=$(_flow_get_file_size "$target")
    total_bytes=$size

    # Check if large
    if (( size > 51200 )); then
      large_files+=("$target:$size")
    fi

    # Check if generated
    if [[ "$target" =~ \.(log|sqlite|db|cache)$ ]]; then
      generated_files+=("$target:$size")
    fi

    # Check if git metadata
    if [[ "$target" =~ /\.git/ ]]; then
      git_files=1
    fi
  else
    # Directory - scan all files
    while IFS= read -r file; do
      all_files+=("$file")
      file_count=$((file_count + 1))

      local size=$(_flow_get_file_size "$file")
      total_bytes=$((total_bytes + size))

      # Check if large
      if (( size > 51200 )); then
        large_files+=("$file:$size")
      fi

      # Check if generated
      if [[ "$file" =~ \.(log|sqlite|db|cache)$ ]]; then
        generated_files+=("$file:$size")
      fi

      # Check if git metadata
      if [[ "$file" =~ /\.git/ ]]; then
        git_files=$((git_files + 1))
      fi
    done < <(find "$target" -type f 2>/dev/null)
  fi

  # Display summary
  echo "Files to add: ${FLOW_COLORS[bold]}$file_count${FLOW_COLORS[reset]}"
  echo "Total size: ${FLOW_COLORS[bold]}$(_flow_human_size $total_bytes)${FLOW_COLORS[reset]}"
  echo ""

  # Display warnings
  local has_warnings=false

  # Git metadata warning
  if (( git_files > 0 )); then
    has_warnings=true
    _dotf_warn "⚠️  $git_files git metadata files detected"
    _dotf_info "These will be skipped (covered by .chezmoiignore)"
    echo ""
  fi

  # Large files warning
  if (( ${#large_files[@]} > 0 )); then
    has_warnings=true
    _dotf_warn "⚠️  Large files detected:"
    for entry in "${large_files[@]}"; do
      local filepath="${entry%%:*}"
      local filesize="${entry##*:}"
      local filename=$(basename "$filepath")
      local human_size=$(_flow_human_size $filesize)
      echo "  - ${filename} (${human_size})"
    done
    echo ""
  fi

  # Generated files warning
  if (( ${#generated_files[@]} > 0 )); then
    has_warnings=true
    _dotf_warn "⚠️  Generated files detected:"
    for entry in "${generated_files[@]}"; do
      local filepath="${entry%%:*}"
      local filesize="${entry##*:}"
      local filename=$(basename "$filepath")
      local human_size=$(_flow_human_size $filesize)
      echo "  - ${filename} (${human_size})"
    done
    echo ""
    _dotf_info "💡 Consider excluding: *.log, *.sqlite, *.db, *.cache"
    echo ""

    # Offer auto-ignore
    read -q "REPLY?Auto-add ignore patterns? (Y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
      # Extract patterns from generated files
      local patterns=()
      for entry in "${generated_files[@]}"; do
        local filepath="${entry%%:*}"
        if [[ "$filepath" =~ \.([^.]+)$ ]]; then
          local ext="${match[1]}"
          patterns+=("*.$ext")
        fi
      done

      # Call auto-suggest function
      if (( ${#patterns[@]} > 0 )); then
        _dotf_suggest_ignore_patterns "${patterns[@]}"
      fi
      echo ""
    fi
  fi

  # Final confirmation
  if $has_warnings; then
    read -q "REPLY?Proceed with adding to chezmoi? (Y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
      return 0
    else
      _dotf_info "Add cancelled"
      return 1
    fi
  fi

  return 0
}

# =============================================================================
# Function: _dotf_suggest_ignore_patterns
# Purpose: Auto-suggest and add ignore patterns to .chezmoiignore
# =============================================================================
# Arguments:
#   $@ - Array of file patterns to add (e.g., "*.log" "*.sqlite")
#
# Returns:
#   0 - Patterns added successfully
#   1 - Error or user cancelled
#
# Example:
#   _dotf_suggest_ignore_patterns "*.log" "*.db" "*.cache"
#
# Notes:
#   - Creates .chezmoiignore if missing
#   - Skips duplicate patterns
#   - Adds patterns one per line
#   - Preserves existing content
# =============================================================================
_dotf_suggest_ignore_patterns() {
  local patterns=("$@")

  if (( ${#patterns[@]} == 0 )); then
    return 1
  fi

  local ignore_file="${HOME}/.local/share/chezmoi/.chezmoiignore"
  local added_count=0

  # Create .chezmoiignore if missing
  if [[ ! -f "$ignore_file" ]]; then
    mkdir -p "$(dirname "$ignore_file")"
    touch "$ignore_file"
    _dotf_info "Created .chezmoiignore"
  fi

  # Read existing patterns
  local existing_patterns=()
  if [[ -f "$ignore_file" ]]; then
    while IFS= read -r line; do
      # Skip empty lines and comments
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      existing_patterns+=("$line")
    done < "$ignore_file"
  fi

  # Add unique patterns
  for pattern in "${patterns[@]}"; do
    # Check if pattern already exists
    local exists=false
    for existing in "${existing_patterns[@]}"; do
      if [[ "$existing" == "$pattern" ]]; then
        exists=true
        break
      fi
    done

    # Add if new
    if ! $exists; then
      echo "$pattern" >> "$ignore_file"
      added_count=$((added_count + 1))
      _dotf_success "Added $pattern to .chezmoiignore"
    fi
  done

  if (( added_count > 0 )); then
    return 0
  else
    _dotf_info "All patterns already in .chezmoiignore"
    return 0
  fi
}
