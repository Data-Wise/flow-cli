# lib/atlas-bridge.zsh - Atlas CLI integration
# Provides seamless integration with @data-wise/atlas when available
# Falls back to local operations when atlas is not installed

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
  if _flow_has_atlas; then
    atlas "$@"
  else
    _flow_log_warning "Atlas not available. Install with: npm install -g @data-wise/atlas"
    return 1
  fi
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
_flow_get_project() {
  local name="$1"
  
  if _flow_has_atlas; then
    _flow_atlas project show "$name" --format=shell 2>/dev/null
  else
    _flow_get_project_fallback "$name"
  fi
}

# Fallback: Find project by name in FLOW_PROJECTS_ROOT
_flow_get_project_fallback() {
  local name="$1"
  local path
  
  # Try exact match first
  if [[ -d "$FLOW_PROJECTS_ROOT/$name" ]]; then
    path="$FLOW_PROJECTS_ROOT/$name"
  else
    # Search for project
    path=$(find "$FLOW_PROJECTS_ROOT" -maxdepth 3 -type d -name "$name" 2>/dev/null | head -1)
  fi
  
  if [[ -n "$path" ]]; then
    echo "name=\"$name\""
    echo "path=\"$path\""
    if [[ -f "$path/.STATUS" ]]; then
      local status=$(grep -m1 "^## Status:" "$path/.STATUS" 2>/dev/null | cut -d: -f2 | tr -d ' ')
      echo "status=\"${status:-unknown}\""
    fi
    return 0
  fi
  return 1
}

# List projects (atlas or fallback)
_flow_list_projects() {
  local filter="${1:-}"
  
  if _flow_has_atlas; then
    if [[ -n "$filter" ]]; then
      _flow_atlas project list --status="$filter" --format=names 2>/dev/null
    else
      _flow_atlas project list --format=names 2>/dev/null
    fi
  else
    _flow_list_projects_fallback "$filter"
  fi
}

# Fallback: List projects from filesystem
_flow_list_projects_fallback() {
  local filter="${1:-}"
  find "$FLOW_PROJECTS_ROOT" -maxdepth 3 -name ".STATUS" 2>/dev/null | while read status_file; do
    local dir=$(dirname "$status_file")
    local name=$(basename "$dir")
    
    if [[ -n "$filter" ]]; then
      local status=$(grep -m1 "^## Status:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')
      [[ "$status" == "$filter" ]] && echo "$name"
    else
      echo "$name"
    fi
  done
}

# ============================================================================
# SESSION OPERATIONS
# ============================================================================

# Start session
_flow_session_start() {
  local project="$1"
  
  if _flow_has_atlas; then
    _flow_atlas session start "$project"
  else
    # Fallback: Log to worklog
    local worklog="${FLOW_DATA_DIR}/worklog"
    echo "$(date '+%Y-%m-%d %H:%M:%S') START $project" >> "$worklog"
    _flow_log_success "Session started: $project"
  fi
}

# End session
_flow_session_end() {
  local note="${1:-}"
  
  if _flow_has_atlas; then
    _flow_atlas session end "$note"
  else
    # Fallback: Log to worklog
    local worklog="${FLOW_DATA_DIR}/worklog"
    echo "$(date '+%Y-%m-%d %H:%M:%S') END ${note:+($note)}" >> "$worklog"
    _flow_log_success "Session ended"
  fi
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
    echo "- [ ] $text${project:+ (@$project)} [$(date '+%Y-%m-%d %H:%M')]" >> "$inbox"
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
    local status=$(grep -m1 "^## Status:" "$status_file" | cut -d: -f2 | tr -d ' ')
    local focus=$(grep -m1 "^## Focus:" "$status_file" | cut -d: -f2-)
    
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
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${project:+[$project] }$text" >> "$trail"
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
