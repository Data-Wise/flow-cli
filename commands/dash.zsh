# commands/dash.zsh - Dashboard command
# Quick overview of all projects and their status

# ============================================================================
# DASH COMMAND
# ============================================================================

dash() {
  local mode=""
  local filter=""
  local format="compact"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full|-f)
        mode="full"
        shift
        ;;
      --tui|-t)
        mode="tui"
        shift
        ;;
      --active|-a)
        filter="active"
        shift
        ;;
      --detailed|-d)
        format="detailed"
        shift
        ;;
      --minimal|-m)
        format="minimal"
        shift
        ;;
      *)
        filter="$1"
        shift
        ;;
    esac
  done
  
  # Full mode: use atlas dashboard (TUI)
  if [[ "$mode" == "full" ]]; then
    if _flow_has_atlas; then
      _flow_atlas dashboard
      return $?
    else
      _flow_log_warning "Atlas not available. Using local dashboard."
    fi
  fi
  
  # TUI mode: interactive fzf dashboard
  if [[ "$mode" == "tui" ]]; then
    dash-tui
    return $?
  fi
  
  # Default: quick ZSH dashboard
  _flow_dash_quick "$filter" "$format"
}

# Quick ZSH-native dashboard (fast, no dependencies)
_flow_dash_quick() {
  local filter="$1"
  local format="$2"
  
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[bold]}PROJECT DASHBOARD${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  
  # Show current session if active
  if _flow_has_atlas; then
    local current=$(atlas session status --format=json 2>/dev/null | grep -o '"project":"[^"]*"' | cut -d'"' -f4)
    if [[ -n "$current" ]]; then
      echo "  ${FLOW_COLORS[success]}▶ Active session:${FLOW_COLORS[reset]} $current"
      echo ""
    fi
  fi
  
  # Get projects (using atlas if available)
  local projects
  if [[ -n "$filter" ]]; then
    projects=$(_flow_list_projects "$filter")
  else
    projects=$(_flow_list_projects)
  fi
  
  if [[ -z "$projects" ]]; then
    echo "  No projects found"
    return
  fi
  
  # Display projects
  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    _flow_dash_project_row "$project" "$format"
  done <<< "$projects"
  
  echo ""
  
  # Show legend
  echo "${FLOW_COLORS[muted]}  🟢 Active  🟡 Paused  🔴 Blocked  🟠 Stalled  ⚫ Archived${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[muted]}  Tip: 'dash --full' for interactive TUI (requires atlas)${FLOW_COLORS[reset]}"
  echo ""
}

# Render a single project row
_flow_dash_project_row() {
  local project="$1"
  local format="$2"

  # Get project info
  local info=$(_flow_get_project "$project" 2>/dev/null)

  local proj_status="unknown"
  local focus=""
  local path=""

  if [[ -n "$info" ]]; then
    eval "$info"
  fi

  # Try to read from .STATUS file if we have path (pure ZSH)
  if [[ -n "$path" ]] && [[ -f "$path/.STATUS" ]]; then
    local line
    while IFS= read -r line; do
      case "$line" in
        "## Status:"*) proj_status="${${line#*:}// /}" ; proj_status="${proj_status:l}" ;;
        "## Focus:"*)  focus="${line#*:}" ; focus="${focus## }" ;;
      esac
    done < "$path/.STATUS"
  fi

  local icon=$(_flow_status_icon "${proj_status:-unknown}")
  local color="${FLOW_COLORS[$proj_status]:-${FLOW_COLORS[muted]}}"
  local type_icon=$(_flow_project_icon "$(_flow_detect_project_type "$path" 2>/dev/null)")
  
  case "$format" in
    compact)
      printf "  %s %s ${color}%-18s${FLOW_COLORS[reset]}" "$icon" "$type_icon" "$project"
      [[ -n "$focus" ]] && printf " │ %.40s" "$focus"
      echo ""
      ;;
    detailed)
      printf "  %s ${color}%-20s${FLOW_COLORS[reset]}\n" "$icon" "$project"
      [[ -n "$path" ]] && printf "     📁 %s\n" "$path"
      [[ -n "$focus" ]] && printf "     🎯 %s\n" "$focus"
      echo ""
      ;;
    minimal)
      printf "%s %s\n" "$icon" "$project"
      ;;
  esac
}

# ============================================================================
# DASH VARIANTS
# ============================================================================

# Show only active projects
dash-active() {
  dash --active
}

# Show all projects with details
dash-all() {
  dash --detailed
}

# Show stalled projects (no activity)
dash-stalled() {
  echo ""
  echo "${FLOW_COLORS[warning]}⚠️  STALLED PROJECTS (no recent activity)${FLOW_COLORS[reset]}"
  echo ""
  
  local projects=$(_flow_list_projects)
  local found=0
  
  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    
    local info=$(_flow_get_project "$project" 2>/dev/null)
    [[ -z "$info" ]] && continue
    eval "$info"
    
    # Check for staleness (no .STATUS update in 14 days)
    if [[ -n "$path" ]] && [[ -f "$path/.STATUS" ]]; then
      local mtime=$(stat -f %m "$path/.STATUS" 2>/dev/null || stat -c %Y "$path/.STATUS" 2>/dev/null)
      local now=$(date +%s)
      local age_days=$(( (now - mtime) / 86400 ))
      
      if (( age_days > 14 )); then
        printf "  🟠 %-20s │ %d days stale\n" "$project" "$age_days"
        found=1
      fi
    fi
  done <<< "$projects"
  
  if (( found == 0 )); then
    echo "  ✨ No stalled projects!"
  fi
  echo ""
}

# ============================================================================
# INTERACTIVE DASHBOARD (TUI)
# ============================================================================

dash-tui() {
  if ! _flow_has_fzf; then
    _flow_log_error "fzf required for TUI mode. Install: brew install fzf"
    dash
    return
  fi
  
  local projects=$(_flow_list_projects)
  
  # Build preview data
  local selected
  selected=$(echo "$projects" | fzf \
    --header="🎯 PROJECT DASHBOARD │ Enter: work │ Ctrl-D: delete │ Ctrl-E: edit status" \
    --preview="_flow_show_project_preview {}" \
    --preview-window=right:50%:wrap \
    --height=80% \
    --layout=reverse \
    --border=rounded \
    --bind="enter:accept" \
    --bind="ctrl-d:execute(echo 'delete:{}' > /tmp/flow-dash-action)+abort" \
    --bind="ctrl-e:execute(echo 'edit:{}' > /tmp/flow-dash-action)+abort" \
  )
  
  # Handle selection
  if [[ -n "$selected" ]]; then
    work "$selected"
  fi
  
  # Handle special actions
  if [[ -f /tmp/flow-dash-action ]]; then
    local action=$(cat /tmp/flow-dash-action)
    rm /tmp/flow-dash-action
    
    case "$action" in
      delete:*)
        local proj="${action#delete:}"
        if _flow_confirm "Remove $proj from registry?"; then
          _flow_atlas project remove "$proj"
        fi
        ;;
      edit:*)
        local proj="${action#edit:}"
        local info=$(_flow_get_project "$proj")
        eval "$info"
        ${EDITOR:-vim} "$path/.STATUS"
        ;;
    esac
  fi
}
