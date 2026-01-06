# lib/atlas-bridge.zsh - Atlas CLI integration
# Provides seamless integration with @data-wise/atlas when available
# Falls back to local operations when atlas is not installed

# Load zsh datetime module for strftime
zmodload zsh/datetime 2>/dev/null

# ============================================================================
# ZSH-NATIVE UTILITIES (avoid external commands)
# ============================================================================

# Get timestamp (YYYY-MM-DD HH:MM:SS)
_flow_timestamp() {
  strftime '%Y-%m-%d %H:%M:%S' $EPOCHSECONDS
}

# Get short timestamp (YYYY-MM-DD HH:MM)
_flow_timestamp_short() {
  strftime '%Y-%m-%d %H:%M' $EPOCHSECONDS
}

# ============================================================================
# ATLAS DETECTION
# ============================================================================

# Cache atlas availability (checked once per session)
typeset -g _FLOW_ATLAS_AVAILABLE

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

# Force re-check atlas availability
_flow_refresh_atlas() {
  unset _FLOW_ATLAS_AVAILABLE
  _flow_has_atlas
}

# Initialize atlas connection
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

# Main atlas command wrapper (use this for all atlas calls)
_flow_atlas() {
  # Double-check atlas exists (cache might be stale)
  if ! command -v atlas &>/dev/null; then
    _FLOW_ATLAS_AVAILABLE="no"
    return 1
  fi

  atlas "$@" 2>/dev/null
}

# Silent atlas call (no output, just return code)
_flow_atlas_silent() {
  if _flow_has_atlas; then
    atlas "$@" &>/dev/null
  fi
}

# Atlas call with JSON output
_flow_atlas_json() {
  if _flow_has_atlas; then
    atlas "$@" --format=json 2>/dev/null
  fi
}

# Fire-and-forget atlas call (async, non-blocking)
_flow_atlas_async() {
  if _flow_has_atlas; then
    { atlas "$@" &>/dev/null & } 2>/dev/null
    disown 2>/dev/null
  fi
}

# ============================================================================
# PROJECT OPERATIONS
# ============================================================================

# Get project info (atlas or fallback)
# NOTE: We always use fallback now because atlas --format=shell embeds JSON
# in values which causes eval errors. The fallback is fast and reliable.
_flow_get_project() {
  local name="$1"

  # Always use fallback - it's reliable and fast
  # Atlas shell format has embedded JSON that breaks eval
  _flow_get_project_fallback "$name"
}

# Fallback: Find project by name in FLOW_PROJECTS_ROOT
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
    echo "path=\"$path\""
    echo "proj_status=\"active\""  # Avoid 'status' - conflicts with ZSH builtin
    return 0
  fi
  return 1
}

# List projects (atlas or fallback)
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

# Fallback: List projects from filesystem
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

# Start session
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

# End session
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

# Get current session info
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

# Get today's total session time (from worklog)
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

# Quick capture
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

# Show inbox
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

# Get current context ("where was I?")
_flow_where() {
  local project="${1:-}"
  
  if _flow_has_atlas; then
    _flow_atlas where ${project:+"$project"}
  else
    _flow_where_fallback "$project"
  fi
}

# Fallback: Basic context from filesystem
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

# Leave breadcrumb
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

# `at` is a shortcut to atlas (easier to type)
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
