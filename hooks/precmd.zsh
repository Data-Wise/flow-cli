# hooks/precmd.zsh - Pre-command hook
# Triggered before each prompt is displayed

# Track last command for session logging
typeset -g _FLOW_LAST_CMD_START

_flow_precmd_hook() {
  # Skip if disabled
  [[ "$FLOW_PRECMD_DISABLED" == "1" ]] && return
  
  # Calculate command duration if we tracked it
  if [[ -n "$_FLOW_LAST_CMD_START" ]]; then
    local duration=$(( SECONDS - _FLOW_LAST_CMD_START ))
    
    # Log long-running commands (>60 seconds) for context
    if (( duration > 60 )) && _flow_in_project; then
      local project=$(_flow_project_name "$(_flow_find_project_root)")
      _flow_atlas_async crumb "Long task: $duration seconds" --project="$project"
    fi
    
    unset _FLOW_LAST_CMD_START
  fi
}

# Preexec hook (called before command execution)
_flow_preexec_hook() {
  _FLOW_LAST_CMD_START=$SECONDS
}

# Register preexec hook if not already done
if [[ -z "$_FLOW_PREEXEC_REGISTERED" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _flow_preexec_hook
  _FLOW_PREEXEC_REGISTERED=1
fi
