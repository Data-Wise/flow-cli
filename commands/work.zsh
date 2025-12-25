# commands/work.zsh - Primary workflow command
# Start working on a project with full context setup

# ============================================================================
# WORK COMMAND
# ============================================================================

work() {
  local project="$1"
  local editor="${2:-${EDITOR:-code}}"
  
  # If no project specified, use picker or current directory
  if [[ -z "$project" ]]; then
    if _flow_has_fzf; then
      project=$(_flow_pick_project)
      [[ -z "$project" ]] && return 1
    else
      # Try to use current directory
      local root=$(_flow_find_project_root)
      if [[ -n "$root" ]]; then
        project=$(_flow_project_name "$root")
      else
        _flow_log_error "No project specified and not in a project directory"
        echo "Usage: work <project> [editor]"
        return 1
      fi
    fi
  fi
  
  # Get project info
  local project_info=$(_flow_get_project "$project")
  
  if [[ -z "$project_info" ]]; then
    _flow_log_error "Project not found: $project"
    return 1
  fi
  
  # Parse project info
  eval "$project_info"
  
  # Change to project directory
  if [[ -d "$path" ]]; then
    cd "$path" || return 1
  else
    _flow_log_error "Project path not found: $path"
    return 1
  fi
  
  # Start session in atlas (non-blocking)
  _flow_session_start "$project"
  
  # Show context
  _flow_show_work_context "$project" "$path"
  
  # Open editor
  _flow_open_editor "$editor" "$path"
}

# Show work context when starting
_flow_show_work_context() {
  local project="$1"
  local path="$2"
  
  local type=$(_flow_detect_project_type "$path")
  local icon=$(_flow_project_icon "$type")
  
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "$icon ${FLOW_COLORS[bold]}$project${FLOW_COLORS[reset]} ($type)"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  
  # Show status file info (simplified - pure ZSH)
  if [[ -f "$path/.STATUS" ]]; then
    local -i count=0
    local line
    while IFS= read -r line && (( count++ < 10 )); do
      case "$line" in
        "## Status:"*) echo "🟢 Status:${line#*:}" ;;
        "## Phase:"*)  echo "📍 Phase:${line#*:}" ;;
        "## Focus:"*)  echo "🎯 Focus:${line#*:}" ;;
      esac
    done < "$path/.STATUS"
  fi
  
  echo ""
}

# Open editor with project
_flow_open_editor() {
  local editor="$1"
  local path="$2"

  # Handle common editors
  case "${editor%% *}" in  # Get first word if editor has args
    code|vscode)
      command code "$path" &>/dev/null &
      ;;
    cursor)
      command cursor "$path" &>/dev/null &
      ;;
    vim|nvim)
      command $editor "$path"
      ;;
    emacs|spacemacs|emacsclient)
      if command -v emacsclient &>/dev/null; then
        command emacsclient -n "$path" 2>/dev/null
      elif command -v emacs &>/dev/null; then
        command emacs "$path" &
      fi
      ;;
    *)
      # For complex $EDITOR values, use eval
      eval "$editor \"$path\"" &>/dev/null &
      ;;
  esac
}

# ============================================================================
# FINISH COMMAND
# ============================================================================

finish() {
  local note="$1"
  
  # Check if in a project
  local root=$(_flow_find_project_root)
  if [[ -z "$root" ]]; then
    _flow_log_warning "Not in a project directory"
  fi
  
  # End session
  _flow_session_end "$note"
  
  # Optional: Stage and commit changes
  if [[ -d ".git" ]]; then
    local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if (( changes > 0 )); then
      if _flow_confirm "Commit $changes change(s)?"; then
        git add -A
        local commit_msg="${note:-Work session completed}"
        git commit -m "$commit_msg"
        _flow_log_success "Changes committed: $commit_msg"
      fi
    fi
  fi
}

# ============================================================================
# HOP COMMAND - Quick project switch with tmux
# ============================================================================

hop() {
  local project="$1"
  
  # If no project, show picker
  if [[ -z "$project" ]]; then
    if _flow_has_fzf; then
      project=$(_flow_pick_project)
      [[ -z "$project" ]] && return 1
    else
      echo "Usage: hop <project>"
      return 1
    fi
  fi
  
  # Get project path
  local project_info=$(_flow_get_project "$project")
  if [[ -z "$project_info" ]]; then
    _flow_log_error "Project not found: $project"
    return 1
  fi
  
  eval "$project_info"
  
  # If in tmux, create/switch to project session
  if [[ -n "$TMUX" ]]; then
    local session_name="${project//[^a-zA-Z0-9]/_}"
    
    # Check if session exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux switch-client -t "$session_name"
    else
      # Create new session
      tmux new-session -d -s "$session_name" -c "$path"
      tmux switch-client -t "$session_name"
    fi
    
    _flow_log_success "Hopped to: $project"
  else
    # Not in tmux, just cd
    cd "$path" || return 1
    _flow_log_info "Changed to: $project (start tmux for session management)"
  fi
}

# ============================================================================
# WHY COMMAND - Show current context
# ============================================================================

why() {
  _flow_where "$@"
}
