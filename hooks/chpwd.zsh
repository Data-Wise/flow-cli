# hooks/chpwd.zsh - Directory change hook
# Triggered whenever the user changes directory

_flow_chpwd_hook() {
  # Skip if disabled
  [[ "$FLOW_CHPWD_DISABLED" == "1" ]] && return
  
  # Detect if we entered a project directory
  local project_root=$(_flow_find_project_root 2>/dev/null)
  
  if [[ -n "$project_root" ]]; then
    local project_name=$(_flow_project_name "$project_root")
    
    # Only log if this is a different project
    if [[ "$project_name" != "$_FLOW_CURRENT_PROJECT" ]]; then
      _FLOW_CURRENT_PROJECT="$project_name"
      
      # Log to atlas if available (async, non-blocking)
      _flow_atlas_async log "entered $project_name"
      
      # Show brief context (can be disabled with FLOW_QUIET=1)
      if [[ -z "$FLOW_QUIET" ]]; then
        _flow_log_debug "📁 $project_name"
      fi
    fi
  else
    # Left project context
    if [[ -n "$_FLOW_CURRENT_PROJECT" ]]; then
      _flow_atlas_async log "left $_FLOW_CURRENT_PROJECT"
      unset _FLOW_CURRENT_PROJECT
    fi
  fi
}
