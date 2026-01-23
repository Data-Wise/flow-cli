# lib/atlas-bridge.zsh - Atlas CLI integration
# Provides seamless integration with @data-wise/atlas when available
# Falls back to local operations when atlas is not installed

# Load zsh datetime module for strftime
zmodload zsh/datetime 2>/dev/null

# ============================================================================
# ZSH-NATIVE UTILITIES (avoid external commands)
# ============================================================================

# =============================================================================
# Function: _flow_timestamp
# Purpose: Get current timestamp in YYYY-MM-DD HH:MM:SS format
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Timestamp string (e.g., "2026-01-22 14:30:45")
#
# Example:
#   ts=$(_flow_timestamp)
#   echo "Current time: $ts"
#
# Dependencies:
#   - zsh/datetime module (zmodload zsh/datetime)
#
# Notes:
#   - Uses ZSH-native strftime for performance
#   - Relies on $EPOCHSECONDS for current Unix time
# =============================================================================
_flow_timestamp() {
  strftime '%Y-%m-%d %H:%M:%S' $EPOCHSECONDS
}

# =============================================================================
# Function: _flow_timestamp_short
# Purpose: Get current timestamp in short YYYY-MM-DD HH:MM format
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Short timestamp string (e.g., "2026-01-22 14:30")
#
# Example:
#   ts=$(_flow_timestamp_short)
#   echo "[$ts] Event logged"
#
# Dependencies:
#   - zsh/datetime module (zmodload zsh/datetime)
#
# Notes:
#   - Omits seconds for more compact display
#   - Useful for log entries and capture timestamps
# =============================================================================
_flow_timestamp_short() {
  strftime '%Y-%m-%d %H:%M' $EPOCHSECONDS
}

# ============================================================================
# ATLAS DETECTION
# ============================================================================

# Cache atlas availability (checked once per session)
typeset -g _FLOW_ATLAS_AVAILABLE

# =============================================================================
# Function: _flow_has_atlas
# Purpose: Check if Atlas CLI is available (with session-level caching)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Atlas is available
#   1 - Atlas is not installed
#
# Example:
#   if _flow_has_atlas; then
#       _flow_atlas session start "$project"
#   else
#       echo "Atlas not installed, using fallback"
#   fi
#
# Notes:
#   - Result is cached in $_FLOW_ATLAS_AVAILABLE for session duration
#   - Use _flow_refresh_atlas to force re-check
#   - Enables graceful degradation when Atlas is not installed
# =============================================================================
_flow_has_atlas() {
  # Return cached result if available
  if [[ -n "$_FLOW_ATLAS_AVAILABLE" ]]; then
    [[ "$_FLOW_ATLAS_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if atlas command exists
  if command -v atlas &>/dev/null; then
    _FLOW_ATLAS_AVAILABLE="yes"
    return 0
  else
    _FLOW_ATLAS_AVAILABLE="no"
    return 1
  fi
}

# =============================================================================
# Function: _flow_refresh_atlas
# Purpose: Force re-check of Atlas CLI availability (clears cache)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Atlas is now available
#   1 - Atlas is still not installed
#
# Example:
#   # After installing atlas
#   _flow_refresh_atlas
#   if _flow_has_atlas; then
#       echo "Atlas now available!"
#   fi
#
# Notes:
#   - Clears $_FLOW_ATLAS_AVAILABLE cache
#   - Useful after installing/uninstalling Atlas mid-session
# =============================================================================
_flow_refresh_atlas() {
  unset _FLOW_ATLAS_AVAILABLE
  _flow_has_atlas
}

# =============================================================================
# Function: _flow_init_atlas
# Purpose: Initialize Atlas connection (respects FLOW_ATLAS_ENABLED setting)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always (initialization is best-effort)
#
# Environment:
#   FLOW_ATLAS_ENABLED - "auto", "yes", or "no" (default: "auto")
#
# Example:
#   # Called during plugin initialization
#   _flow_init_atlas
#
# Notes:
#   - If FLOW_ATLAS_ENABLED="no", Atlas is disabled even if installed
#   - Logs debug message on successful connection
#   - Safe to call multiple times
# =============================================================================
_flow_init_atlas() {
  if [[ "$FLOW_ATLAS_ENABLED" == "no" ]]; then
    _FLOW_ATLAS_AVAILABLE="no"
    return
  fi

  if _flow_has_atlas; then
    _flow_log_debug "Atlas connected"
  fi
}

# ============================================================================
# ATLAS CLI WRAPPER
# ============================================================================

# =============================================================================
# Function: _flow_atlas
# Purpose: Main Atlas CLI wrapper (use for all atlas calls)
# =============================================================================
# Arguments:
#   $@ - Arguments to pass to atlas command
#
# Returns:
#   0 - Atlas command succeeded
#   1 - Atlas not available or command failed
#
# Output:
#   stdout - Atlas command output (stderr suppressed)
#
# Example:
#   _flow_atlas session start "my-project"
#   _flow_atlas project list --status=active
#
# Notes:
#   - Double-checks atlas availability (cache might be stale)
#   - Suppresses stderr for cleaner output
#   - Updates cache if atlas becomes unavailable
# =============================================================================
_flow_atlas() {
  # Double-check atlas exists (cache might be stale)
  if ! command -v atlas &>/dev/null; then
    _FLOW_ATLAS_AVAILABLE="no"
    return 1
  fi

  atlas "$@" 2>/dev/null
}

# =============================================================================
# Function: _flow_atlas_silent
# Purpose: Execute Atlas command silently (no output, return code only)
# =============================================================================
# Arguments:
#   $@ - Arguments to pass to atlas command
#
# Returns:
#   0 - Atlas available and command succeeded (or Atlas not available)
#   Non-zero - Atlas command failed
#
# Example:
#   _flow_atlas_silent session ping  # Just check if session is alive
#   if _flow_atlas_silent project exists "my-project"; then
#       echo "Project exists"
#   fi
#
# Notes:
#   - Suppresses both stdout and stderr
#   - Returns success (0) if Atlas not available (graceful degradation)
#   - Use for side-effect operations where output doesn't matter
# =============================================================================
_flow_atlas_silent() {
  if _flow_has_atlas; then
    atlas "$@" &>/dev/null
  fi
}

# =============================================================================
# Function: _flow_atlas_json
# Purpose: Execute Atlas command with JSON output format
# =============================================================================
# Arguments:
#   $@ - Arguments to pass to atlas command (--format=json auto-added)
#
# Returns:
#   0 - Command succeeded
#   1 - Atlas not available or command failed
#
# Output:
#   stdout - JSON output from Atlas command
#
# Example:
#   project_data=$(_flow_atlas_json project get "my-project")
#   echo "$project_data" | jq '.status'
#
# Dependencies:
#   - jq (recommended for parsing output)
#
# Notes:
#   - Automatically appends --format=json flag
#   - Returns nothing if Atlas not available
#   - Useful for programmatic access to Atlas data
# =============================================================================
_flow_atlas_json() {
  if _flow_has_atlas; then
    atlas "$@" --format=json 2>/dev/null
  fi
}

# =============================================================================
# Function: _flow_atlas_async
# Purpose: Execute Atlas command asynchronously (fire-and-forget)
# =============================================================================
# Arguments:
#   $@ - Arguments to pass to atlas command
#
# Returns:
#   0 - Always (command launched in background)
#
# Example:
#   # Log analytics event without blocking
#   _flow_atlas_async analytics log "session-started"
#
#   # Sync data in background
#   _flow_atlas_async sync --quiet
#
# Notes:
#   - Runs command in background subshell
#   - Disowns process to prevent shell wait
#   - No way to check command result
#   - Use for non-critical operations (analytics, sync)
# =============================================================================
_flow_atlas_async() {
  if _flow_has_atlas; then
    { atlas "$@" &>/dev/null & } 2>/dev/null
    disown 2>/dev/null
  fi
}

# ============================================================================
# PROJECT OPERATIONS
# ============================================================================

# =============================================================================
# Function: _flow_get_project
# Purpose: Get project information by name (uses fallback for reliability)
# =============================================================================
# Arguments:
#   $1 - (required) Project name to look up
#
# Returns:
#   0 - Project found
#   1 - Project not found
#
# Output:
#   stdout - Shell-evaluable variables: name, project_path, proj_status
#
# Example:
#   if info=$(_flow_get_project "my-project"); then
#       eval "$info"
#       cd "$project_path"
#   fi
#
# Notes:
#   - Always uses filesystem fallback (Atlas shell format has JSON issues)
#   - Searches FLOW_PROJECTS_ROOT and common subdirectories
#   - Output avoids reserved variable names (path, status)
# =============================================================================
_flow_get_project() {
  local name="$1"

  # Always use fallback - it's reliable and fast
  # Atlas shell format has embedded JSON that breaks eval
  _flow_get_project_fallback "$name"
}

# =============================================================================
# Function: _flow_get_project_fallback
# Purpose: Find project by name in filesystem (fallback when Atlas unavailable)
# =============================================================================
# Arguments:
#   $1 - (required) Project name to look up
#
# Returns:
#   0 - Project found
#   1 - Project not found
#
# Output:
#   stdout - Shell-evaluable variables:
#            name="project-name"
#            project_path="/path/to/project"
#            proj_status="active"
#
# Example:
#   if info=$(_flow_get_project_fallback "flow-cli"); then
#       eval "$info"
#       echo "Found at: $project_path"
#   fi
#
# Environment:
#   FLOW_PROJECTS_ROOT - Base directory for projects
#
# Notes:
#   - Searches exact match first, then common subdirectories
#   - Search order: root, dev-tools, r-packages/*, research, teaching, quarto
#   - Uses project_path/proj_status to avoid ZSH reserved names
# =============================================================================
_flow_get_project_fallback() {
  local name="$1"
  local path

  # Try exact match first
  if [[ -d "$FLOW_PROJECTS_ROOT/$name" ]]; then
    path="$FLOW_PROJECTS_ROOT/$name"
  else
    # Search in common subdirectories
    local search_dirs=(
      "$FLOW_PROJECTS_ROOT/dev-tools"
      "$FLOW_PROJECTS_ROOT/r-packages/active"
      "$FLOW_PROJECTS_ROOT/r-packages/stable"
      "$FLOW_PROJECTS_ROOT/research"
      "$FLOW_PROJECTS_ROOT/teaching"
      "$FLOW_PROJECTS_ROOT/quarto"
    )
    for dir in "${search_dirs[@]}"; do
      if [[ -d "$dir/$name" ]]; then
        path="$dir/$name"
        break
      fi
    done
  fi

  if [[ -n "$path" ]]; then
    echo "name=\"$name\""
    echo "project_path=\"$path\""  # Avoid 'path' - conflicts with ZSH's PATH-tied variable
    echo "proj_status=\"active\""  # Avoid 'status' - conflicts with ZSH builtin
    return 0
  fi
  return 1
}

# =============================================================================
# Function: _flow_list_projects
# Purpose: List all projects (uses Atlas if available, otherwise fallback)
# =============================================================================
# Arguments:
#   $1 - (optional) Status filter (e.g., "active", "archived")
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Project names, one per line
#
# Example:
#   # List all projects
#   _flow_list_projects
#
#   # List only active projects
#   _flow_list_projects "active"
#
# Notes:
#   - Tries Atlas first with --format=names
#   - Falls back to filesystem scan if Atlas returns JSON or fails
#   - Validates Atlas output format before using
# =============================================================================
_flow_list_projects() {
  local filter="${1:-}"

  if _flow_has_atlas; then
    local output
    if [[ -n "$filter" ]]; then
      output=$(_flow_atlas project list --status="$filter" --format=names 2>/dev/null)
    else
      output=$(_flow_atlas project list --format=names 2>/dev/null)
    fi

    # Validate: names format should be plain text, one per line
    # If it looks like JSON (starts with { or [), fall back
    if [[ "$output" == "{"* ]] || [[ "$output" == "["* ]] || [[ -z "$output" ]]; then
      _flow_list_projects_fallback "$filter"
    else
      echo "$output"
    fi
  else
    _flow_list_projects_fallback "$filter"
  fi
}

# =============================================================================
# Function: _flow_list_projects_fallback
# Purpose: List projects by scanning filesystem for .STATUS files
# =============================================================================
# Arguments:
#   $1 - (optional) Status filter (currently ignored in fallback)
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Project names, one per line
#
# Example:
#   projects=$(_flow_list_projects_fallback)
#   echo "Found $(echo "$projects" | wc -l) projects"
#
# Environment:
#   FLOW_PROJECTS_ROOT - Base directory to scan
#
# Notes:
#   - Scans recursively for .STATUS files
#   - Uses ZSH glob qualifiers: (N) for nullglob
#   - :h = dirname, :t = basename (ZSH modifiers)
#   - Filter parameter ignored (would require parsing .STATUS content)
# =============================================================================
_flow_list_projects_fallback() {
  local filter="${1:-}"
  local status_file dir name

  for status_file in "$FLOW_PROJECTS_ROOT"/**/.STATUS(N); do
    dir="${status_file:h}"   # ZSH: :h = head (dirname equivalent)
    name="${dir:t}"          # ZSH: :t = tail (basename equivalent)
    echo "$name"
  done
}

# ============================================================================
# SESSION OPERATIONS
# ============================================================================

# Session state file
_FLOW_SESSION_FILE="${FLOW_DATA_DIR}/.current-session"

# =============================================================================
# Function: _flow_session_start
# Purpose: Start a work session for a project (with Atlas or fallback)
# =============================================================================
# Arguments:
#   $1 - (required) Project name to start session for
#
# Returns:
#   0 - Session started successfully
#
# Side Effects:
#   - Creates $_FLOW_SESSION_FILE with session state
#   - Exports FLOW_CURRENT_PROJECT and FLOW_SESSION_START
#   - Appends to worklog file (fallback mode)
#
# Example:
#   _flow_session_start "my-project"
#   echo "Working on: $FLOW_CURRENT_PROJECT"
#
# Environment:
#   FLOW_DATA_DIR - Directory for session state files
#
# Notes:
#   - Creates FLOW_DATA_DIR if it doesn't exist
#   - Session state stored for time tracking
#   - Uses Atlas if available, otherwise logs to worklog
# =============================================================================
_flow_session_start() {
  local project="$1"

  # Save session state (for time tracking)
  [[ ! -d "${FLOW_DATA_DIR}" ]] && /bin/mkdir -p "${FLOW_DATA_DIR}"
  echo "project=$project" > "$_FLOW_SESSION_FILE"
  echo "start=$EPOCHSECONDS" >> "$_FLOW_SESSION_FILE"
  echo "date=$(strftime '%Y-%m-%d' $EPOCHSECONDS)" >> "$_FLOW_SESSION_FILE"

  # Export for current shell
  export FLOW_CURRENT_PROJECT="$project"
  export FLOW_SESSION_START="$EPOCHSECONDS"

  if _flow_has_atlas; then
    _flow_atlas session start "$project"
  else
    # Fallback: Log to worklog
    local worklog="${FLOW_DATA_DIR}/worklog"
    echo "$(_flow_timestamp) START $project" >> "$worklog"
    _flow_log_success "Session started: $project"
  fi
}

# =============================================================================
# Function: _flow_session_end
# Purpose: End the current work session (with Atlas or fallback)
# =============================================================================
# Arguments:
#   $1 - (optional) Note to record with session end
#
# Returns:
#   0 - Session ended successfully
#
# Side Effects:
#   - Removes $_FLOW_SESSION_FILE
#   - Unsets FLOW_CURRENT_PROJECT and FLOW_SESSION_START
#   - Appends to worklog file (fallback mode)
#
# Example:
#   _flow_session_end "Completed feature X"
#   _flow_session_end  # No note
#
# Notes:
#   - Calculates duration from FLOW_SESSION_START or session file
#   - Displays human-readable duration (Xh Ym or Xm)
#   - Safe to call even if no session active
# =============================================================================
_flow_session_end() {
  local note="${1:-}"
  local duration_mins=0

  # Calculate duration
  if [[ -n "$FLOW_SESSION_START" ]]; then
    local elapsed=$((EPOCHSECONDS - FLOW_SESSION_START))
    duration_mins=$((elapsed / 60))
  elif [[ -f "$_FLOW_SESSION_FILE" ]]; then
    local start_time=$(command grep "^start=" "$_FLOW_SESSION_FILE" | command cut -d= -f2)
    if [[ -n "$start_time" ]]; then
      local elapsed=$((EPOCHSECONDS - start_time))
      duration_mins=$((elapsed / 60))
    fi
  fi

  if _flow_has_atlas; then
    _flow_atlas session end "$note"
  else
    # Fallback: Log to worklog with duration
    local worklog="${FLOW_DATA_DIR}/worklog"
    echo "$(_flow_timestamp) END ${duration_mins}m ${note:+($note)}" >> "$worklog"
    if (( duration_mins >= 60 )); then
      _flow_log_success "Session ended: $((duration_mins / 60))h $((duration_mins % 60))m"
    else
      _flow_log_success "Session ended: ${duration_mins}m"
    fi
  fi

  # Clean up session state
  rm -f "$_FLOW_SESSION_FILE"
  unset FLOW_CURRENT_PROJECT FLOW_SESSION_START
}

# =============================================================================
# Function: _flow_session_current
# Purpose: Get information about the current active session
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Active session found
#   1 - No active session
#
# Output:
#   stdout - Shell-evaluable variables:
#            project=<name>
#            elapsed_mins=<minutes>
#
# Example:
#   if info=$(_flow_session_current); then
#       eval "$info"
#       echo "Working on $project for $elapsed_mins minutes"
#   else
#       echo "No active session"
#   fi
#
# Notes:
#   - Reads from $_FLOW_SESSION_FILE
#   - Calculates elapsed time from session start
#   - Returns 1 if session file missing or incomplete
# =============================================================================
_flow_session_current() {
  if [[ -f "$_FLOW_SESSION_FILE" ]]; then
    local project=$(command grep "^project=" "$_FLOW_SESSION_FILE" | command cut -d= -f2)
    local start_time=$(command grep "^start=" "$_FLOW_SESSION_FILE" | command cut -d= -f2)

    if [[ -n "$project" && -n "$start_time" ]]; then
      local elapsed=$((EPOCHSECONDS - start_time))
      local mins=$((elapsed / 60))
      echo "project=$project"
      echo "elapsed_mins=$mins"
      return 0
    fi
  fi
  return 1
}

# =============================================================================
# Function: _flow_today_session_time
# Purpose: Calculate total session time for today (from worklog + active)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Total minutes worked today (integer)
#
# Example:
#   total=$(_flow_today_session_time)
#   echo "Worked $((total / 60))h $((total % 60))m today"
#
# Notes:
#   - Sums completed sessions from worklog
#   - Includes current active session if started today
#   - Parses "END Xm" format from worklog entries
#   - Used for productivity tracking and dashboard
# =============================================================================
_flow_today_session_time() {
  local worklog="${FLOW_DATA_DIR}/worklog"
  local today=$(strftime '%Y-%m-%d' $EPOCHSECONDS)
  local total_mins=0

  if [[ -f "$worklog" ]]; then
    # Sum up all session durations from today
    while IFS= read -r line; do
      if [[ "$line" == "$today"*" END "* ]]; then
        # Extract minutes from "END Xm" format
        local mins=$(echo "$line" | grep -o 'END [0-9]*m' | grep -o '[0-9]*')
        [[ -n "$mins" ]] && ((total_mins += mins))
      fi
    done < "$worklog"
  fi

  # Add current session if active
  if [[ -f "$_FLOW_SESSION_FILE" ]]; then
    local start_time=$(command grep "^start=" "$_FLOW_SESSION_FILE" | command cut -d= -f2)
    local session_date=$(command grep "^date=" "$_FLOW_SESSION_FILE" | command cut -d= -f2)
    if [[ "$session_date" == "$today" && -n "$start_time" ]]; then
      local elapsed=$((EPOCHSECONDS - start_time))
      ((total_mins += elapsed / 60))
    fi
  fi

  echo "$total_mins"
}

# ============================================================================
# CAPTURE OPERATIONS
# ============================================================================

# =============================================================================
# Function: _flow_catch
# Purpose: Quick capture of a thought/task to inbox
# =============================================================================
# Arguments:
#   $1 - (required) Text to capture
#   $2 - (optional) Project to associate with capture
#
# Returns:
#   0 - Capture succeeded
#
# Example:
#   _flow_catch "Fix the login bug"
#   _flow_catch "Update docs" "my-project"
#
# Notes:
#   - Uses Atlas if available, otherwise appends to inbox.md
#   - Fallback format: "- [ ] text (@project) [timestamp]"
#   - Designed for ADHD-friendly quick capture workflow
# =============================================================================
_flow_catch() {
  local text="$1"
  local project="${2:-}"

  if _flow_has_atlas; then
    if [[ -n "$project" ]]; then
      _flow_atlas catch "$text" --project="$project"
    else
      _flow_atlas catch "$text"
    fi
  else
    # Fallback: Append to inbox file
    local inbox="${FLOW_DATA_DIR}/inbox.md"
    echo "- [ ] $text${project:+ (@$project)} [$(_flow_timestamp_short)]" >> "$inbox"
    _flow_log_success "Captured: $text"
  fi
}

# =============================================================================
# Function: _flow_inbox
# Purpose: Display the capture inbox contents
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Inbox contents (captured items) or "Inbox empty" message
#
# Example:
#   _flow_inbox  # Display all captured items
#
# Notes:
#   - Uses Atlas if available, otherwise reads inbox.md
#   - Shows 📭 emoji if inbox is empty (ADHD-friendly visual)
# =============================================================================
_flow_inbox() {
  if _flow_has_atlas; then
    _flow_atlas inbox
  else
    local inbox="${FLOW_DATA_DIR}/inbox.md"
    if [[ -f "$inbox" ]]; then
      cat "$inbox"
    else
      echo "📭 Inbox empty"
    fi
  fi
}

# ============================================================================
# CONTEXT OPERATIONS
# ============================================================================

# =============================================================================
# Function: _flow_where
# Purpose: Get current project context ("where was I?")
# =============================================================================
# Arguments:
#   $1 - (optional) Project name to get context for
#
# Returns:
#   0 - Context found
#   1 - No context available
#
# Output:
#   stdout - Project context information (name, status, focus)
#
# Example:
#   _flow_where             # Context for current directory
#   _flow_where "my-proj"   # Context for specific project
#
# Notes:
#   - Uses Atlas if available, otherwise uses fallback
#   - Fallback detects project from current directory
#   - Shows status and focus from .STATUS file if available
# =============================================================================
_flow_where() {
  local project="${1:-}"

  if _flow_has_atlas; then
    _flow_atlas where ${project:+"$project"}
  else
    _flow_where_fallback "$project"
  fi
}

# =============================================================================
# Function: _flow_where_fallback
# Purpose: Get project context from filesystem (fallback for _flow_where)
# =============================================================================
# Arguments:
#   $1 - (optional) Project name to get context for
#
# Returns:
#   0 - Context found
#   1 - No project context available
#
# Output:
#   stdout - Project info with status and focus from .STATUS file
#
# Example:
#   _flow_where_fallback                # Auto-detect from PWD
#   _flow_where_fallback "flow-cli"     # Specific project
#
# Notes:
#   - Detects project from current directory if not specified
#   - Parses .STATUS file for Status: and Focus: lines
#   - Shows 📁 emoji for visual project identification
# =============================================================================
_flow_where_fallback() {
  local project="${1:-}"

  # If no project specified, try to detect from current directory
  if [[ -z "$project" ]]; then
    local root=$(_flow_find_project_root)
    [[ -n "$root" ]] && project=$(_flow_project_name "$root")
  fi

  if [[ -z "$project" ]]; then
    echo "No project context"
    return 1
  fi

  echo "📁 Project: $project"

  # Show status if available
  local status_file
  for search_dir in "$PWD" "$FLOW_PROJECTS_ROOT/$project"; do
    if [[ -f "$search_dir/.STATUS" ]]; then
      status_file="$search_dir/.STATUS"
      break
    fi
  done

  if [[ -f "$status_file" ]]; then
    local status=$(command grep -m1 "^## Status:" "$status_file" | command cut -d: -f2 | tr -d ' ')
    local focus=$(command grep -m1 "^## Focus:" "$status_file" | command cut -d: -f2-)

    [[ -n "$status" ]] && echo "   Status: $status"
    [[ -n "$focus" ]] && echo "   Focus: $focus"
  fi
}

# =============================================================================
# Function: _flow_crumb
# Purpose: Leave a breadcrumb (context marker for future reference)
# =============================================================================
# Arguments:
#   $1 - (required) Breadcrumb text (what you were working on)
#   $2 - (optional) Project to associate with breadcrumb
#
# Returns:
#   0 - Breadcrumb recorded
#
# Example:
#   _flow_crumb "Debugging auth flow"
#   _flow_crumb "Refactoring API" "my-project"
#
# Notes:
#   - Uses Atlas if available, otherwise logs to trail.log
#   - Helps resume work after interruptions (ADHD-friendly)
#   - 🍞 emoji provides visual feedback in fallback mode
# =============================================================================
_flow_crumb() {
  local text="$1"
  local project="${2:-}"

  if _flow_has_atlas; then
    _flow_atlas crumb "$text" ${project:+--project="$project"}
  else
    # Fallback: Log to trail file
    local trail="${FLOW_DATA_DIR}/trail.log"
    echo "$(_flow_timestamp) ${project:+[$project] }$text" >> "$trail"
    _flow_log_success "🍞 Breadcrumb: $text"
  fi
}

# ============================================================================
# ALIAS FOR DIRECT ATLAS ACCESS
# ============================================================================

# =============================================================================
# Function: at
# Purpose: Shortcut alias for Atlas CLI (or fallback commands)
# =============================================================================
# Arguments:
#   $@ - Command and arguments to pass to Atlas
#
# Returns:
#   0 - Command succeeded
#   1 - Atlas not available and command not supported
#
# Subcommands (fallback mode):
#   catch|c  <text>     - Quick capture
#   inbox|i             - Show inbox
#   where|w  [project]  - Show context
#   crumb|b  <text>     - Leave breadcrumb
#
# Example:
#   at session start my-project    # Atlas mode
#   at catch "Fix bug"             # Works with or without Atlas
#   at inbox                       # Show captured items
#
# Notes:
#   - Passes through to atlas CLI if available
#   - Provides essential fallback commands without Atlas
#   - 'at' chosen for easy typing (2 chars)
# =============================================================================
at() {
  if _flow_has_atlas; then
    atlas "$@"
  else
    case "$1" in
      catch|c)  shift; _flow_catch "$@" ;;
      inbox|i)  _flow_inbox ;;
      where|w)  shift; _flow_where "$@" ;;
      crumb|b)  shift; _flow_crumb "$@" ;;
      *)
        _flow_log_error "Atlas not installed. Install: npm install -g @data-wise/atlas"
        echo "Available fallback commands: catch, inbox, where, crumb"
        ;;
    esac
  fi
}
