# commands/adhd.zsh - ADHD-friendly helper commands
# Reduce friction, provide dopamine, manage cognitive load

# ============================================================================
# JS - Just Start (anti-paralysis command)
# ============================================================================

js() {
  local project="${1:-}"
  
  echo ""
  echo "${FLOW_COLORS[accent]}🚀 JUST START${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}(Picking something for you...)${FLOW_COLORS[reset]}"
  echo ""
  
  if [[ -z "$project" ]]; then
    # Get active projects
    local projects=$(_flow_list_projects "active" 2>/dev/null)
    
    if [[ -z "$projects" ]]; then
      projects=$(_flow_list_projects 2>/dev/null | head -5)
    fi
    
    if [[ -z "$projects" ]]; then
      _flow_log_error "No projects found"
      return 1
    fi
    
    # Pick a random project (or the most recently used)
    if _flow_has_atlas; then
      # Atlas can suggest based on recency and patterns
      project=$(_flow_atlas project list --suggest --format=names 2>/dev/null | head -1)
    fi
    
    if [[ -z "$project" ]]; then
      # Fallback: pick randomly from active projects
      project=$(echo "$projects" | sort -R | head -1)
    fi
  fi
  
  if [[ -z "$project" ]]; then
    _flow_log_error "Couldn't pick a project. Try: js <project-name>"
    return 1
  fi
  
  echo "  ${FLOW_COLORS[success]}→ $project${FLOW_COLORS[reset]}"
  echo ""
  
  # Start working
  work "$project"
}

# ============================================================================
# NEXT - What should I work on next?
# ============================================================================

next() {
  echo ""
  echo "${FLOW_COLORS[header]}🎯 NEXT TASK SUGGESTIONS${FLOW_COLORS[reset]}"
  echo ""
  
  # Check inbox first
  local inbox_count=0
  if _flow_has_atlas; then
    inbox_count=$(_flow_atlas inbox --count 2>/dev/null || echo "0")
  else
    local inbox="${FLOW_DATA_DIR}/inbox.md"
    [[ -f "$inbox" ]] && inbox_count=$(wc -l < "$inbox" | tr -d ' ')
  fi
  
  if (( inbox_count > 0 )); then
    echo "  📥 You have $inbox_count items in your inbox"
  fi
  
  # Show active projects with focus
  echo ""
  echo "  ${FLOW_COLORS[muted]}Active projects:${FLOW_COLORS[reset]}"
  
  local projects=$(_flow_list_projects "active" 2>/dev/null)
  local count=0
  
  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    (( count >= 3 )) && break
    
    local info=$(_flow_get_project "$project" 2>/dev/null)
    local focus=""
    
    if [[ -n "$info" ]]; then
      eval "$info"
      if [[ -n "$path" ]] && [[ -f "$path/.STATUS" ]]; then
        focus=$(grep -m1 "^## Focus:" "$path/.STATUS" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
      fi
    fi
    
    local icon=$(_flow_project_icon "$(_flow_detect_project_type "$path" 2>/dev/null)")
    printf "  %s %-15s" "$icon" "$project"
    [[ -n "$focus" ]] && printf " → %s" "$focus"
    echo ""
    
    ((count++))
  done <<< "$projects"
  
  echo ""
  echo "  ${FLOW_COLORS[muted]}Tip: Run 'js' to just start, or 'work <project>' to pick${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# STUCK - When you're feeling stuck
# ============================================================================

stuck() {
  echo ""
  echo "${FLOW_COLORS[warning]}😵 FEELING STUCK?${FLOW_COLORS[reset]}"
  echo ""
  echo "  Try one of these:"
  echo ""
  echo "  ${FLOW_COLORS[success]}1.${FLOW_COLORS[reset]} Take a 5-minute break (walk, stretch, water)"
  echo "  ${FLOW_COLORS[success]}2.${FLOW_COLORS[reset]} Write down exactly what's blocking you"
  echo "  ${FLOW_COLORS[success]}3.${FLOW_COLORS[reset]} Break the task into tiny pieces"
  echo "  ${FLOW_COLORS[success]}4.${FLOW_COLORS[reset]} Switch to a different project"
  echo "  ${FLOW_COLORS[success]}5.${FLOW_COLORS[reset]} Ask for help (rubber duck it)"
  echo ""
  
  if _flow_confirm "Would you like to capture what you're stuck on?"; then
    catch
  fi
}

# ============================================================================
# FOCUS - Set or show current focus
# ============================================================================

focus() {
  local text="$*"
  
  # Get current project
  local project=""
  if _flow_in_project; then
    project=$(_flow_project_name "$(_flow_find_project_root)")
  fi
  
  if [[ -z "$text" ]]; then
    # Show current focus
    if _flow_has_atlas && [[ -n "$project" ]]; then
      _flow_atlas focus "$project"
    else
      local root=$(_flow_find_project_root)
      if [[ -n "$root" ]] && [[ -f "$root/.STATUS" ]]; then
        local focus=$(grep -m1 "^## Focus:" "$root/.STATUS" | cut -d: -f2-)
        if [[ -n "$focus" ]]; then
          echo "🎯 Focus:$focus"
        else
          echo "No focus set. Usage: focus <what you're working on>"
        fi
      else
        echo "Not in a project. Usage: focus <what you're working on>"
      fi
    fi
  else
    # Set focus
    if _flow_has_atlas && [[ -n "$project" ]]; then
      _flow_atlas focus "$project" "$text"
    else
      # Update .STATUS file directly
      local root=$(_flow_find_project_root)
      if [[ -n "$root" ]] && [[ -f "$root/.STATUS" ]]; then
        # Check if Focus line exists
        if grep -q "^## Focus:" "$root/.STATUS"; then
          sed -i '' "s/^## Focus:.*$/## Focus: $text/" "$root/.STATUS"
        else
          # Add Focus line after Status line
          sed -i '' "/^## Status:/a\\
## Focus: $text" "$root/.STATUS"
        fi
        _flow_log_success "Focus set: $text"
      else
        _flow_log_error "Not in a project with .STATUS file"
      fi
    fi
  fi
}

# ============================================================================
# BREAK - Take a proper break
# ============================================================================

brk() {
  local duration="${1:-5}"
  
  echo ""
  echo "${FLOW_COLORS[info]}☕ BREAK TIME${FLOW_COLORS[reset]}"
  echo ""
  echo "  Taking a $duration minute break..."
  echo "  ${FLOW_COLORS[muted]}(Saving your context)${FLOW_COLORS[reset]}"
  
  # Save breadcrumb
  if _flow_in_project; then
    crumb "Taking a $duration min break"
  fi
  
  # Simple countdown (can be interrupted with Ctrl+C)
  local seconds=$((duration * 60))
  
  echo ""
  while (( seconds > 0 )); do
    printf "\r  ⏱️  %d:%02d remaining  " $((seconds / 60)) $((seconds % 60))
    sleep 1
    ((seconds--))
  done
  
  echo ""
  echo ""
  echo "  ${FLOW_COLORS[success]}Break over! Ready to get back to it?${FLOW_COLORS[reset]}"
  
  # Show context to help resume
  if _flow_in_project; then
    echo ""
    why
  fi
}
