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

# Require a tool (show error if not found)
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

# Get sync status (synced|modified|behind|ahead|conflict)
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

# Check if local repo is ahead of remote
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

# Check if local repo is behind remote
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

# Get list of modified files
_dot_get_modified_files() {
  if ! _dot_has_chezmoi; then
    return 1
  fi

  chezmoi status 2>/dev/null | awk '{print $2}'
}

# Get count of modified files
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

# Get last sync time (from git commit in chezmoi dir)
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

# Get count of tracked files
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

# Format status for display (with icon and color)
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

# Get one-line status for dashboard display
# Returns formatted string with status icon, state, time/details, and file count
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

# Resolve file path with fuzzy matching
# Usage: _dot_resolve_file_path "zshrc" -> "$HOME/.config/zsh/.zshrc"
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
    # Single match - return it
    echo "$matched_files"
    return 0
  else
    # Multiple matches - return all for selection
    echo "$matched_files"
    return 2  # Signal multiple matches
  fi
}

# ============================================================================
# BITWARDEN HELPERS
# ============================================================================

# Check if Bitwarden session is valid
_dot_bw_session_valid() {
  if ! _dot_has_bw; then
    return 1
  fi

  if [[ -z "$BW_SESSION" ]]; then
    return 1
  fi

  # Validate session
  bw unlock --check &>/dev/null
}

# Get Bitwarden status
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

# Ensure sensitive commands are not stored in history
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

# Check if BW_SESSION is exported globally (security risk)
_dot_security_check_bw_session() {
  # Check if BW_SESSION is in shell startup files
  local config_files=(
    "$HOME/.zshrc"
    "$HOME/.zshenv"
    "$HOME/.zprofile"
    "$HOME/.config/zsh/.zshrc"
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

# Format time ago (relative time)
_dot_format_time_ago() {
  local time_str=$1

  if [[ "$time_str" == "unknown" ]] || [[ "$time_str" == "not-initialized" ]]; then
    echo "$time_str"
  else
    echo "$time_str"
  fi
}

# Format file count (with proper singular/plural)
_dot_format_file_count() {
  local count=$1

  if [[ $count -eq 1 ]]; then
    echo "1 file"
  else
    echo "$count files"
  fi
}
