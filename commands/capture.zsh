# commands/capture.zsh - Quick capture commands
# Frictionless idea and task capture for ADHD workflows

# ============================================================================
# CATCH - Quick idea capture
# ============================================================================

catch() {
  local text="$*"
  
  if [[ -z "$text" ]]; then
    # Interactive mode
    if _flow_has_gum; then
      text=$(gum input --placeholder="Quick idea or task..." --width=60)
    else
      read "text?💡 Quick capture: "
    fi
    
    [[ -z "$text" ]] && return 1
  fi
  
  # Detect if in a project
  local project=""
  if _flow_in_project; then
    project=$(_flow_project_name "$(_flow_find_project_root)")
  fi
  
  # Capture to atlas or fallback
  _flow_catch "$text" "$project"
}

# ============================================================================
# INBOX - View captured items
# ============================================================================

inbox() {
  _flow_inbox "$@"
}

# ============================================================================
# CRUMB - Leave breadcrumb
# ============================================================================

crumb() {
  local text="$*"
  
  if [[ -z "$text" ]]; then
    read "text?🍞 Breadcrumb: "
    [[ -z "$text" ]] && return 1
  fi
  
  local project=""
  if _flow_in_project; then
    project=$(_flow_project_name "$(_flow_find_project_root)")
  fi
  
  _flow_crumb "$text" "$project"
}

# ============================================================================
# QUICK CAPTURE ALIASES
# ============================================================================

# Very short aliases for minimal friction
c() { catch "$@" }
i() { inbox "$@" }
b() { crumb "$@" }

# ============================================================================
# WIN - Dopamine logging (celebrate small wins!)
# ============================================================================

win() {
  local text="$*"
  
  if [[ -z "$text" ]]; then
    if _flow_has_gum; then
      text=$(gum input --placeholder="What did you accomplish?" --width=60)
    else
      read "text?🎉 What's your win? "
    fi
    [[ -z "$text" ]] && return 1
  fi
  
  local project=""
  if _flow_in_project; then
    project=$(_flow_project_name "$(_flow_find_project_root)")
  fi
  
  # Log the win
  if _flow_has_atlas; then
    _flow_atlas catch "$text" --type=win ${project:+--project="$project"}
  else
    local wins="${FLOW_DATA_DIR}/wins.md"
    echo "- 🎉 $text${project:+ (@$project)} [$(date '+%Y-%m-%d %H:%M')]" >> "$wins"
  fi
  
  # Celebrate!
  echo ""
  echo "  🎉 ${FLOW_COLORS[success]}WIN LOGGED!${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}$text${FLOW_COLORS[reset]}"
  echo ""
  
  # Extra dopamine with confetti if gum available
  if _flow_has_gum; then
    gum style --foreground 212 "Keep it up! 🚀"
  fi
}

# ============================================================================
# YAY - Quick celebration (even shorter than win)
# ============================================================================

yay() {
  if [[ -n "$*" ]]; then
    win "$@"
  else
    # Just show recent wins
    echo ""
    echo "  ${FLOW_COLORS[header]}Recent Wins:${FLOW_COLORS[reset]}"
    echo ""
    
    if _flow_has_atlas; then
      _flow_atlas inbox --type=win --limit=5 2>/dev/null || {
        local wins="${FLOW_DATA_DIR}/wins.md"
        [[ -f "$wins" ]] && tail -5 "$wins" || echo "  No wins yet. Use 'win' to log your first!"
      }
    else
      local wins="${FLOW_DATA_DIR}/wins.md"
      [[ -f "$wins" ]] && tail -5 "$wins" || echo "  No wins yet. Use 'win' to log your first!"
    fi
    echo ""
  fi
}
