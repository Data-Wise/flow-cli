# commands/morning.zsh - Daily startup routine
# ADHD-friendly morning workflow to reduce decision fatigue

# ============================================================================
# MORNING COMMAND
# ============================================================================

morning() {
  local quick="${1:-}"
  
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "  ☀️  ${FLOW_COLORS[bold]}GOOD MORNING${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  
  # Quick mode just shows essentials
  if [[ "$quick" == "-q" || "$quick" == "--quick" ]]; then
    _flow_morning_quick
    return
  fi
  
  # 1. Show inbox count
  _flow_morning_inbox
  
  # 2. Show active projects summary
  _flow_morning_projects

  # 3. Show upcoming dated items (7-day window + overdue)
  _flow_morning_agenda

  # 4. Show today's wins (if any from yesterday)
  _flow_morning_wins
  
  # 5. Suggest what to work on
  _flow_morning_suggest
  
  echo ""
  echo "${FLOW_COLORS[muted]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}Ready to start? Try: js (just-start) or work <project>${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# MORNING SECTIONS
# ============================================================================

_flow_morning_inbox() {
  local count=0
  
  if _flow_has_atlas; then
    count=$(_flow_atlas inbox --stats 2>/dev/null | grep -oE "Inbox: [0-9]+" | grep -oE "[0-9]+" || echo "0")
  else
    local inbox="${FLOW_DATA_DIR}/inbox.md"
    [[ -f "$inbox" ]] && count=$(wc -l < "$inbox" | tr -d ' ')
  fi
  
  if (( count > 0 )); then
    echo "  📥 ${FLOW_COLORS[warning]}$count items${FLOW_COLORS[reset]} in inbox"
  else
    echo "  📥 Inbox clear ✨"
  fi
}

_flow_morning_projects() {
  echo ""
  echo "  ${FLOW_COLORS[muted]}Active Projects:${FLOW_COLORS[reset]}"
  
  local projects=$(_flow_list_projects "active" 2>/dev/null)
  local count=0
  
  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    (( count >= 5 )) && break
    
    local info=$(_flow_get_project "$project" 2>/dev/null)
    local focus=""
    local progress=""
    
    if [[ -n "$info" ]]; then
      eval "$info"
      if [[ -n "$path" ]] && [[ -f "$path/.STATUS" ]]; then
        focus=$(grep -m1 "^## Focus:" "$path/.STATUS" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
        progress=$(grep -m1 "^## Progress:" "$path/.STATUS" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | tr -d '%')
      fi
    fi
    
    local icon=$(_flow_project_icon "$(_flow_detect_project_type "$path" 2>/dev/null)")
    
    printf "     %s %-15s" "$icon" "$project"
    [[ -n "$progress" ]] && printf " [%3d%%]" "$progress"
    [[ -n "$focus" ]] && printf " → %.30s" "$focus"
    echo ""
    
    ((count++))
  done <<< "$projects"
  
  if (( count == 0 )); then
    echo "     ${FLOW_COLORS[muted]}No active projects${FLOW_COLORS[reset]}"
  fi
}

# Upcoming dated items for the morning routine (top 5, 7-day window + overdue).
# Self-suppresses when nothing is due. Driven by the shared schedule engine.
_flow_morning_agenda() {
  typeset -f _schedule_collect >/dev/null 2>&1 || return 0

  local records
  records=$(_schedule_collect 7 | _schedule_filter_window 7 | _schedule_sort)
  [[ -n "$records" ]] && records=$(print -r -- "$records" | _schedule_drop_holidays)
  [[ -z "$records" ]] && return 0

  echo ""
  echo "  ${FLOW_COLORS[muted]}Upcoming (next 7 days):${FLOW_COLORS[reset]}"

  local count=0 rec
  while IFS= read -r rec; do
    [[ -z "$rec" ]] && continue
    (( count >= 5 )) && break
    _schedule_render_line "$rec"
    ((count++))
  done <<< "$records"

  local total=$(print -r -- "$records" | grep -c .)
  if (( total > 5 )); then
    echo "  ${FLOW_COLORS[muted]}  +$((total - 5)) more — run 'agenda'${FLOW_COLORS[reset]}"
  fi
}

# Count of in-window (7d + overdue) dated items, for the quick one-liner.
_flow_agenda_count() {
  typeset -f _schedule_collect >/dev/null 2>&1 || { echo 0; return 0; }
  local records
  records=$(_schedule_collect 7 | _schedule_filter_window 7)
  [[ -n "$records" ]] && records=$(print -r -- "$records" | _schedule_drop_holidays)
  [[ -z "$records" ]] && { echo 0; return 0; }
  print -r -- "$records" | grep -c .
}

_flow_morning_wins() {
  local wins_file="${FLOW_DATA_DIR}/wins.md"
  
  if [[ -f "$wins_file" ]]; then
    local yesterday=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null)
    local recent=$(grep "$yesterday" "$wins_file" 2>/dev/null | tail -3)
    
    if [[ -n "$recent" ]]; then
      echo ""
      echo "  ${FLOW_COLORS[muted]}Yesterday's wins:${FLOW_COLORS[reset]}"
      echo "$recent" | while read -r line; do
        echo "     $line"
      done
    fi
  fi
}

_flow_morning_suggest() {
  echo ""
  echo "  ${FLOW_COLORS[accent]}💡 Suggestion:${FLOW_COLORS[reset]}"
  
  # Try to find P0/P1 priority project
  local suggestion=""
  
  if _flow_has_atlas; then
    suggestion=$(_flow_atlas project list --status=active --format=names 2>/dev/null | head -1)
  else
    # Find priority project from filesystem
    for status_file in "$FLOW_PROJECTS_ROOT"/**/.STATUS(N); do
      local status=$(grep -m1 "^## Status:" "$status_file" | cut -d: -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')
      local priority=$(grep -m1 "^## Priority:" "$status_file" | cut -d: -f2 | tr -d ' ')
      
      if [[ "$status" == "active" ]] && [[ "$priority" == "1" || "$priority" == "P1" ]]; then
        local dir="${status_file:h}"
        suggestion="${dir:t}"
        break
      fi
    done
  fi
  
  if [[ -n "$suggestion" ]]; then
    echo "     Work on ${FLOW_COLORS[bold]}$suggestion${FLOW_COLORS[reset]}"
    echo "     Run: ${FLOW_COLORS[success]}work $suggestion${FLOW_COLORS[reset]}"
  else
    echo "     Run ${FLOW_COLORS[success]}js${FLOW_COLORS[reset]} to let the system pick for you"
  fi
}

_flow_morning_quick() {
  # Just show count and suggestion
  local inbox=0
  local active=0
  
  if _flow_has_atlas; then
    inbox=$(_flow_atlas inbox --count 2>/dev/null || echo "0")
    active=$(_flow_atlas project list --status=active --count 2>/dev/null || echo "?")
  else
    local inbox_file="${FLOW_DATA_DIR}/inbox.md"
    [[ -f "$inbox_file" ]] && inbox=$(wc -l < "$inbox_file" | tr -d ' ')
    active=$(_flow_list_projects "active" 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  local due=$(_flow_agenda_count)
  if (( due > 0 )); then
    echo "  📥 $inbox inbox  │  📂 $active active projects  │  📅 $due due soon"
  else
    echo "  📥 $inbox inbox  │  📂 $active active projects"
  fi
  echo ""
  echo "  ${FLOW_COLORS[accent]}→ js${FLOW_COLORS[reset]} to start working"
}

# ============================================================================
# TODAY COMMAND - Quick daily status
# ============================================================================

today() {
  echo ""
  echo "${FLOW_COLORS[header]}📅 TODAY${FLOW_COLORS[reset]} $(date '+%A, %B %d')"
  echo ""
  
  # Show current session if any
  if _flow_has_atlas; then
    local session=$(_flow_atlas session status 2>/dev/null)
    if [[ -n "$session" ]] && [[ "$session" != "No active session" ]]; then
      echo "  🎯 $session"
      echo ""
    fi
  fi
  
  # Show today's wins
  local wins_file="${FLOW_DATA_DIR}/wins.md"
  local today_date=$(date '+%Y-%m-%d')
  
  if [[ -f "$wins_file" ]]; then
    local today_wins=$(grep "$today_date" "$wins_file" 2>/dev/null)
    if [[ -n "$today_wins" ]]; then
      echo "  ${FLOW_COLORS[success]}Today's wins:${FLOW_COLORS[reset]}"
      echo "$today_wins" | while read -r line; do
        echo "     $line"
      done
      echo ""
    fi
  fi
  
  # Show what's due today (+ overdue)
  _flow_today_agenda

  # Show active work
  _flow_morning_projects
  echo ""
}

# Dated items due today plus anything overdue (window 0). Self-suppresses.
_flow_today_agenda() {
  typeset -f _schedule_collect >/dev/null 2>&1 || return 0

  local records
  records=$(_schedule_collect 0 | _schedule_filter_window 0 | _schedule_sort)
  [[ -n "$records" ]] && records=$(print -r -- "$records" | _schedule_drop_holidays)
  [[ -z "$records" ]] && return 0

  echo "  ${FLOW_COLORS[warning]}📅 Due today${FLOW_COLORS[reset]}"
  local rec
  while IFS= read -r rec; do
    [[ -z "$rec" ]] && continue
    _schedule_render_line "$rec"
  done <<< "$records"
  echo ""
}

# ============================================================================
# WEEK COMMAND - Weekly review helper
# ============================================================================

week() {
  echo ""
  echo "${FLOW_COLORS[header]}📊 WEEKLY REVIEW${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}Week of $(date '+%B %d, %Y')${FLOW_COLORS[reset]}"
  echo ""
  
  # This week's deadlines (7-day window, grouped by weekday)
  _flow_week_agenda

  # Session stats
  if _flow_has_atlas; then
    echo "  ${FLOW_COLORS[accent]}Sessions this week:${FLOW_COLORS[reset]}"
    _flow_atlas trail --days=7 2>/dev/null | head -10
    echo ""
  fi

  # Wins this week
  local wins_file="${FLOW_DATA_DIR}/wins.md"
  if [[ -f "$wins_file" ]]; then
    local week_ago=$(date -v-7d '+%Y-%m-%d' 2>/dev/null || date -d '7 days ago' '+%Y-%m-%d' 2>/dev/null)
    echo "  ${FLOW_COLORS[success]}Wins this week:${FLOW_COLORS[reset]}"
    awk -v d="$week_ago" '$0 ~ d || $0 > d' "$wins_file" 2>/dev/null | tail -10 | while read -r line; do
      echo "     $line"
    done
  fi
  
  echo ""
  echo "  ${FLOW_COLORS[muted]}Take a moment to celebrate progress! 🎉${FLOW_COLORS[reset]}"
  echo ""
}

# This week's dated items (7-day window + overdue), grouped by weekday.
# Self-suppresses when nothing is due.
_flow_week_agenda() {
  typeset -f _schedule_collect >/dev/null 2>&1 || return 0

  local records
  records=$(_schedule_collect 7 | _schedule_filter_window 7 | _schedule_sort)
  [[ -n "$records" ]] && records=$(print -r -- "$records" | _schedule_drop_holidays)
  [[ -z "$records" ]] && return 0

  echo "  ${FLOW_COLORS[accent]}📅 This week's deadlines:${FLOW_COLORS[reset]}"

  zmodload zsh/datetime 2>/dev/null
  local rec date last_day day_label
  while IFS= read -r rec; do
    [[ -z "$rec" ]] && continue
    date="${rec%%|*}"
    # Weekday header (printed once per day); overdue items grouped under "Overdue"
    if [[ "$date" < "$(strftime '%Y-%m-%d' $EPOCHSECONDS)" ]]; then
      day_label="Overdue"
    else
      local e=$(strftime -r '%Y-%m-%d %H:%M:%S' "$date 12:00:00" 2>/dev/null)
      day_label=$(strftime '%A' "$e" 2>/dev/null)
    fi
    if [[ "$day_label" != "$last_day" ]]; then
      echo "     ${FLOW_COLORS[muted]}${day_label}:${FLOW_COLORS[reset]}"
      last_day="$day_label"
    fi
    _schedule_render_line "$rec"
  done <<< "$records"
  echo ""
}

# ============================================================================
# ALIASES
# ============================================================================

# Quick morning check
am() { morning -q }
