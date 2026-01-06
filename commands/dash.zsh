# commands/dash.zsh - Dashboard command (Option A: Summary-First)
# ADHD-friendly project overview with progressive disclosure

# ============================================================================
# CONFIGURATION
# ============================================================================

# Category definitions: path:type:icon:display_name
typeset -gA DASH_CATEGORIES
DASH_CATEGORIES=(
  [dev]="dev-tools:dev:🔧:Dev Tools"
  [r]="r-packages/active:r:📦:R Packages|r-packages/stable:r:📦:R Packages"
  [research]="research:rs:🔬:Research"
  [teach]="teaching:teach:🎓:Teaching"
  [quarto]="quarto:q:📝:Quarto"
  [apps]="apps:app:📱:Apps"
)

# How many projects to show in quick access
DASH_QUICK_COUNT=5

# ============================================================================
# DASH COMMAND
# ============================================================================

dash() {
  local mode="${1:-}"
  local show_all=0

  # Parse arguments
  case "$mode" in
    -h|--help|help)
      _dash_help
      return 0
      ;;
    -a|--all)
      show_all=1
      mode=""
      ;;
    -i|--interactive)
      # Interactive mode with fzf
      _dash_interactive
      return
      ;;
    -w|--watch)
      # Watch mode - auto-refresh (v3.5.0)
      local interval="${2:-5}"
      _dash_watch "$interval"
      return
      ;;
    -f|--full)
      # Full TUI mode
      if _flow_has_atlas; then
        _flow_atlas dashboard
      else
        _flow_log_warning "Atlas not available for TUI mode. Try 'dash -i' for fzf mode."
        mode=""
      fi
      return
      ;;
    dev|r|research|teach|quarto|apps)
      # Category expansion mode
      _dash_category_expanded "$mode"
      return
      ;;
  esac

  # Default: Summary-first dashboard
  echo ""
  _dash_header
  _dash_right_now
  _dash_current
  _dash_quick_wins
  _dash_quick_access
  _dash_recent_wins

  if (( show_all )); then
    _dash_all_projects
  else
    _dash_categories
  fi

  _dash_footer
}

# ============================================================================
# HEADER - Summary stats and streak
# ============================================================================

_dash_header() {
  # Use ZSH strftime instead of date
  zmodload -F zsh/datetime b:strftime
  local date_str=$(strftime "%b %d, %Y" $EPOCHSECONDS)
  local time_str=$(strftime "%H:%M" $EPOCHSECONDS)
  local streak=0
  local today_sessions=0
  local today_mins=0
  local today_time="--"

  # Quick health check (cached for performance)
  local health_indicator=""
  local health_issues=$(_dash_quick_health_check)
  if [[ "$health_issues" == "0" ]]; then
    health_indicator="${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]}"
  else
    health_indicator="${FLOW_COLORS[warning]}⚠${health_issues}${FLOW_COLORS[reset]}"
  fi

  # Get stats from atlas if available
  if _flow_has_atlas; then
    local stats=$(atlas status --format=json 2>/dev/null)
    if [[ -n "$stats" ]]; then
      # ZSH pattern matching for JSON values
      [[ "$stats" =~ '"streak":([0-9]+)' ]] && streak="${match[1]}"
      [[ "$stats" =~ '"todaySessions":([0-9]+)' ]] && today_sessions="${match[1]}"
      [[ "$stats" =~ '"todayMinutes":([0-9]+)' ]] && today_mins="${match[1]}"
    fi
  else
    # Fallback: Count today's sessions and time from worklog
    local worklog="${FLOW_DATA_DIR}/worklog"
    local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)
    if [[ -f "$worklog" ]]; then
      # Count lines matching pattern using ZSH
      today_sessions=0
      local line
      while IFS= read -r line; do
        [[ "$line" == "$today"*"START"* ]] && ((today_sessions++))
      done < "$worklog"
    fi
    # Get total time including current session
    today_mins=$(_flow_today_session_time)
  fi

  # Format time
  if (( today_mins >= 60 )); then
    today_time="$((today_mins / 60))h $((today_mins % 60))m"
  elif (( today_mins > 0 )); then
    today_time="${today_mins}m"
  fi

  # Header box with time and health indicator
  echo "╭──────────────────────────────────────────────────────────────╮"
  printf "│  🌊 ${FLOW_COLORS[bold]}FLOW DASHBOARD${FLOW_COLORS[reset]} %s%$((48 - ${#date_str}))s%s  🕐 %s │\n" "$health_indicator" "" "$date_str" "$time_str"
  echo "╰──────────────────────────────────────────────────────────────╯"
  echo ""

  # Stats row - always show
  printf "  📊 ${FLOW_COLORS[muted]}Today:${FLOW_COLORS[reset]} "

  if (( today_sessions > 0 )); then
    printf "%d session%s" "$today_sessions" "$( (( today_sessions > 1 )) && echo 's' )"
  else
    printf "${FLOW_COLORS[muted]}no sessions${FLOW_COLORS[reset]}"
  fi

  if [[ "$today_time" != "--" ]]; then
    printf ", ⏱ %s" "$today_time"
  fi

  # Streak
  if (( streak > 0 )); then
    printf "        🔥 ${FLOW_COLORS[warning]}%d day streak${FLOW_COLORS[reset]}" "$streak"
  fi

  echo ""
  echo ""
}

# ============================================================================
# RIGHT NOW - Smart suggestion (Phase 1: ADHD-friendly)
# ============================================================================

_dash_right_now() {
  # Get today's stats (reuse from header logic)
  local today_sessions=0
  local today_mins=0
  local streak=0
  local daily_goal=1  # Default: at least 1 session per day
  
  # Get stats
  if _flow_has_atlas; then
    local stats=$(atlas status --format=json 2>/dev/null)
    if [[ -n "$stats" ]]; then
      [[ "$stats" =~ '"streak":([0-9]+)' ]] && streak="${match[1]}"
      [[ "$stats" =~ '"todaySessions":([0-9]+)' ]] && today_sessions="${match[1]}"
      [[ "$stats" =~ '"todayMinutes":([0-9]+)' ]] && today_mins="${match[1]}"
    fi
  else
    local worklog="${FLOW_DATA_DIR}/worklog"
    zmodload -F zsh/datetime b:strftime
    local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)
    if [[ -f "$worklog" ]]; then
      today_sessions=0
      local line
      while IFS= read -r line; do
        [[ "$line" == "$today"*"START"* ]] && ((today_sessions++))
      done < "$worklog"
    fi
    today_mins=$(_flow_today_session_time)
  fi
  
  # Smart suggestion logic
  local suggestion=""
  local suggested_project=""
  local next_action=""
  local estimate=""
  
  # Check if already in a session
  local current_project=""
  local session_info=$(_flow_session_current 2>/dev/null)
  if [[ -n "$session_info" ]]; then
    eval "$session_info"
    current_project="$project"
  elif [[ -n "$FLOW_CURRENT_PROJECT" ]]; then
    current_project="$FLOW_CURRENT_PROJECT"
  fi
  
  if [[ -n "$current_project" ]]; then
    # Already working - suggest continuing
    suggestion="Keep going on"
    suggested_project="$current_project"
  else
    # Not working - suggest starting
    # Find first active project with a focus/next item
    local projects=$(_flow_list_projects)
    local found=0
    
    while IFS= read -r project; do
      [[ -z "$project" ]] && continue
      
      local proj_path=$(_dash_find_project_path "$project")
      if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
        local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
        if [[ "$proj_status" == "active" ]]; then
          local focus=$(_dash_get_project_focus "$proj_path/.STATUS")
          if [[ -n "$focus" ]]; then
            suggested_project="$project"
            next_action="$focus"
            found=1
            break
          fi
        fi
      fi
    done <<< "$projects"
    
    if (( found )); then
      suggestion="Start work on"
    else
      # No active project with focus - suggest first active
      while IFS= read -r project; do
        [[ -z "$project" ]] && continue
        local proj_path=$(_dash_find_project_path "$project")
        if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
          local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
          if [[ "$proj_status" == "active" ]]; then
            suggested_project="$project"
            found=1
            break
          fi
        fi
      done <<< "$projects"
      
      if (( found )); then
        suggestion="Start work on"
      else
        suggestion="No active projects"
      fi
    fi
  fi
  
  # Build goal message
  local goal_msg=""
  if (( today_sessions == 0 )); then
    goal_msg="🎯 Goal: Get 1 session done to start streak"
  elif (( streak == 0 && today_sessions > 0 )); then
    goal_msg="🎯 Goal: Complete session to start streak"
  elif (( today_sessions < daily_goal )); then
    goal_msg="🎯 Goal: ${daily_goal} session$(( daily_goal > 1 ? 's' : '' )) today"
  else
    goal_msg="✅ Daily goal achieved!"
  fi
  
  # Format today stats
  local sessions_text="0 sessions"
  if (( today_sessions > 0 )); then
    sessions_text="$today_sessions session$(( today_sessions > 1 ? 's' : '' ))"
  fi
  
  local time_text="0m"
  if (( today_mins >= 60 )); then
    time_text="$((today_mins / 60))h $((today_mins % 60))m"
  elif (( today_mins > 0 )); then
    time_text="${today_mins}m"
  fi
  
  local streak_text="0 day"
  if (( streak > 0 )); then
    streak_text="$streak day$(( streak > 1 ? 's' : '' ))"
  fi
  
  # Display RIGHT NOW section
  echo "  ⚡ ${FLOW_COLORS[bold]}RIGHT NOW${FLOW_COLORS[reset]}"
  echo "  ╭────────────────────────────────────────────────────────────╮"
  
  if [[ -n "$suggested_project" ]]; then
    printf "  │  💡 ${FLOW_COLORS[bold]}SUGGESTION:${FLOW_COLORS[reset]} %-42s │\n" "$suggestion '$suggested_project'"
    if [[ -n "$next_action" ]]; then
      # Truncate to 54 chars
      local action_display="${next_action:0:54}"
      printf "  │     ${FLOW_COLORS[muted]}→ %-52s${FLOW_COLORS[reset]} │\n" "$action_display"
    fi
  else
    printf "  │  💡 ${FLOW_COLORS[muted]}%-52s${FLOW_COLORS[reset]} │\n" "No active projects - run 'work <project>'"
  fi
  
  echo "  │                                                              │"
  printf "  │  📊 TODAY: %-10s  •  🔥 %-8s  •  %-22s │\n" \
    "$sessions_text, $time_text" "$streak_text" "$goal_msg"
  echo "  ╰────────────────────────────────────────────────────────────╯"
  echo ""
}

# ============================================================================
# QUICK WINS - Tasks under 30 minutes (v3.5.0)
# ============================================================================

_dash_quick_wins() {
  # Collect quick wins from .STATUS files
  local -a quick_wins=()
  local projects=$(_flow_list_projects)

  while IFS= read -r project; do
    [[ -z "$project" ]] && continue

    local proj_path=$(_dash_find_project_path "$project")
    [[ -z "$proj_path" ]] && continue
    [[ ! -f "$proj_path/.STATUS" ]] && continue

    local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
    [[ "$proj_status" != "active" ]] && continue

    # Check for quick win markers
    local quick_win=$(_dash_get_status_field "$proj_path/.STATUS" "quick_win")
    local estimate=$(_dash_get_status_field "$proj_path/.STATUS" "estimate")
    local focus=$(_dash_get_project_focus "$proj_path/.STATUS")

    # Is it a quick win? (marked as quick_win, or estimate < 30m)
    local is_quick=0
    if [[ -n "$quick_win" && "$quick_win" != "no" && "$quick_win" != "false" ]]; then
      is_quick=1
    elif [[ -n "$estimate" ]]; then
      # Parse estimate (e.g., "15m", "20min", "1h")
      local mins=0
      if [[ "$estimate" == *"m"* ]]; then
        mins="${estimate//[^0-9]/}"
        (( mins < 30 )) && is_quick=1
      fi
    fi

    if (( is_quick )) && [[ -n "$focus" ]]; then
      local urgency=$(_dash_get_urgency "$proj_path/.STATUS")
      quick_wins+=("${urgency}|${project}|${focus}|${estimate:-quick}")
    fi
  done <<< "$projects"

  # Only show section if we have quick wins
  (( ${#quick_wins[@]} == 0 )) && return

  echo "  ⚡ ${FLOW_COLORS[bold]}QUICK WINS${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(< 30 min)${FLOW_COLORS[reset]}"

  local count=0
  local max=3  # Show top 3 quick wins

  for item in "${quick_wins[@]}"; do
    (( count >= max )) && break

    local urgency="${item%%|*}"
    local rest="${item#*|}"
    local proj="${rest%%|*}"
    rest="${rest#*|}"
    local focus="${rest%%|*}"
    local est="${rest##*|}"

    local urgency_icon=""
    case "$urgency" in
      high)   urgency_icon="🔥 " ;;
      medium) urgency_icon="⏰ " ;;
      low)    urgency_icon="⚡ " ;;
      *)      urgency_icon="⚡ " ;;
    esac

    local prefix="├─"
    (( count == max - 1 || count == ${#quick_wins[@]} - 1 )) && prefix="└─"

    printf "  %s %s${FLOW_COLORS[success]}%-14s${FLOW_COLORS[reset]} %s" "$prefix" "$urgency_icon" "$proj" "${focus:0:35}"
    if [[ -n "$est" && "$est" != "quick" ]]; then
      printf " ${FLOW_COLORS[muted]}~%s${FLOW_COLORS[reset]}" "$est"
    fi
    echo ""

    ((count++))
  done

  echo ""
}

# Get urgency level from .STATUS
_dash_get_urgency() {
  local status_file="$1"
  local urgency=""

  # Check for urgency field
  urgency=$(_dash_get_status_field "$status_file" "urgency")
  if [[ -n "$urgency" ]]; then
    echo "${urgency:l}"
    return
  fi

  # Check for deadline
  local deadline=$(_dash_get_status_field "$status_file" "deadline")
  if [[ -n "$deadline" ]]; then
    # Parse deadline and check if it's soon
    zmodload -F zsh/datetime b:strftime
    local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)

    # Simple comparison (works for YYYY-MM-DD format)
    if [[ "$deadline" < "$today" ]]; then
      echo "high"  # Overdue
    elif [[ "$deadline" == "$today" ]]; then
      echo "high"  # Due today
    else
      # Check if within 3 days
      local today_epoch=$EPOCHSECONDS
      # Rough calculation: assume deadline is 3+ days if greater than today + 3 days
      echo "medium"
    fi
    return
  fi

  # Check for priority field
  local priority=$(_dash_get_status_field "$status_file" "priority")
  case "${priority:l}" in
    1|high|urgent) echo "high" ;;
    2|medium)      echo "medium" ;;
    *)             echo "low" ;;
  esac
}

# Format urgency icon for display
_dash_urgency_icon() {
  local urgency="$1"
  case "$urgency" in
    high)   echo "🔥" ;;   # Fire - urgent
    medium) echo "⏰" ;;   # Clock - time-sensitive
    low)    echo "⚡" ;;   # Lightning - quick
    *)      echo "" ;;
  esac
}

# ============================================================================
# CURRENT SESSION - Highlight active work
# ============================================================================

_dash_current() {
  local current_project=""
  local current_focus=""
  local elapsed=""

  # Check for active session (local first, then atlas)
  local session_info=$(_flow_session_current 2>/dev/null)
  if [[ -n "$session_info" ]]; then
    eval "$session_info"
    current_project="$project"
    if [[ -n "$elapsed_mins" ]]; then
      if (( elapsed_mins >= 60 )); then
        elapsed="$((elapsed_mins / 60))h $((elapsed_mins % 60))m"
      else
        elapsed="${elapsed_mins}m"
      fi
    fi
  elif _flow_has_atlas; then
    local session=$(atlas session status --format=json 2>/dev/null)
    if [[ "$session" != *'"active":false'* ]] && [[ "$session" == *'"project":'* ]]; then
      # ZSH pattern matching for JSON
      [[ "$session" =~ '"project":"([^"]*)"' ]] && current_project="${match[1]}"
      local mins=""
      [[ "$session" =~ '"elapsed":([0-9]+)' ]] && mins="${match[1]}"
      if [[ -n "$mins" ]]; then
        elapsed="${mins}m"
      fi
    fi
  fi

  # Fallback: check FLOW_CURRENT_PROJECT
  if [[ -z "$current_project" ]] && [[ -n "$FLOW_CURRENT_PROJECT" ]]; then
    current_project="$FLOW_CURRENT_PROJECT"
  fi

  # Get focus from .STATUS if we have a current project
  if [[ -n "$current_project" ]]; then
    local proj_path=$(_dash_find_project_path "$current_project")
    if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
      current_focus=$(_dash_get_project_focus "$proj_path/.STATUS")
    fi
  fi

  if [[ -n "$current_project" ]]; then
    local type_icon=$(_flow_project_icon "$(_flow_detect_project_type "$proj_path" 2>/dev/null)")
    
    # Calculate session progress for timer bar
    local elapsed_mins=0
    local target_mins=90  # Default 90 min sessions
    local timer_percent=0
    
    if [[ -n "$session_info" ]] && [[ -n "$elapsed_mins" ]]; then
      timer_percent=$(( elapsed_mins * 100 / target_mins ))
      (( timer_percent > 100 )) && timer_percent=100
    elif [[ -n "$elapsed" ]]; then
      # Parse elapsed time to get minutes
      if [[ "$elapsed" == *"h"* ]]; then
        local hours="${elapsed%%h*}"
        local mins="${elapsed##*h }"
        mins="${mins%%m*}"
        elapsed_mins=$(( hours * 60 + mins ))
      else
        elapsed_mins="${elapsed%%m*}"
      fi
      timer_percent=$(( elapsed_mins * 100 / target_mins ))
      (( timer_percent > 100 )) && timer_percent=100
    fi
    
    # Build 10-char progress bar for timer
    local timer_bar=""
    if (( elapsed_mins > 0 )); then
      local filled=$(( timer_percent / 10 ))
      local empty=$(( 10 - filled ))
      local bar_filled="" bar_empty=""
      (( filled > 0 )) && bar_filled=$(printf '█%.0s' {1..$filled})
      (( empty > 0 )) && bar_empty=$(printf '░%.0s' {1..$empty})
      timer_bar="[${bar_filled}${bar_empty}] ${timer_percent}% of ${target_mins}m"
    fi

    # Enhanced display with different borders (┏━┓ vs ╭─╮)
    if [[ -n "$elapsed" ]]; then
      echo "  🎯 ${FLOW_COLORS[bold]}ACTIVE SESSION${FLOW_COLORS[reset]} • $elapsed elapsed"
    else
      echo "  🎯 ${FLOW_COLORS[bold]}ACTIVE SESSION${FLOW_COLORS[reset]}"
    fi
    echo "  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    printf "  ┃  %s ${FLOW_COLORS[success]}%-52s${FLOW_COLORS[reset]} ┃\n" "$type_icon" "$current_project"
    
    if [[ -n "$current_focus" ]]; then
      # No truncation - full text
      printf "  ┃  ${FLOW_COLORS[muted]}Focus: %-51s${FLOW_COLORS[reset]} ┃\n" "$current_focus"
    fi
    
    if [[ -n "$timer_bar" ]]; then
      printf "  ┃  ${FLOW_COLORS[muted]}Timer: %-51s${FLOW_COLORS[reset]} ┃\n" "$timer_bar"
    fi
    
    echo "  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo ""
  fi
}

# ============================================================================
# QUICK ACCESS - Recent projects
# ============================================================================

_dash_quick_access() {
  echo "  📁 ${FLOW_COLORS[bold]}QUICK ACCESS${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(Active first)${FLOW_COLORS[reset]}"

  # Collect projects and sort (active first)
  local projects=$(_flow_list_projects)
  local -a active_projects=()
  local -a other_projects=()

  while IFS= read -r project; do
    [[ -z "$project" ]] && continue

    local proj_path=$(_dash_find_project_path "$project")
    local proj_status=""

    if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
      proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
    fi

    if [[ "$proj_status" == "active" ]]; then
      active_projects+=("$project")
    else
      other_projects+=("$project")
    fi
  done <<< "$projects"

  # Combine: active first, then others (keep original order within groups)
  local -a sorted_projects=("${active_projects[@]}" "${other_projects[@]}")

  # Display top DASH_QUICK_COUNT
  local count=0
  local total=${#sorted_projects[@]}
  local max=$((total < DASH_QUICK_COUNT ? total : DASH_QUICK_COUNT))

  for project in "${sorted_projects[@]}"; do
    (( count >= DASH_QUICK_COUNT )) && break

    local proj_path=$(_dash_find_project_path "$project")
    local status_icon="⚪"
    local focus=""
    local urgency_icon=""

    if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
      local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
      status_icon=$(_flow_status_icon "$proj_status")
      focus=$(_dash_get_project_focus "$proj_path/.STATUS")

      # Get urgency indicator for active projects
      if [[ "$proj_status" == "active" ]]; then
        local urgency=$(_dash_get_urgency "$proj_path/.STATUS")
        case "$urgency" in
          high)   urgency_icon="🔥" ;;
          medium) urgency_icon="⏰" ;;
        esac
      fi
    fi

    local prefix="├─"
    (( count == max - 1 )) && prefix="└─"

    if [[ -n "$focus" ]]; then
      local focus_short="${focus:0:30}"
      if [[ -n "$urgency_icon" ]]; then
        printf "  %s %s %s ${FLOW_COLORS[info]}%-14s${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" "$prefix" "$status_icon" "$urgency_icon" "$project" "$focus_short"
      else
        printf "  %s %s ${FLOW_COLORS[info]}%-16s${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" "$prefix" "$status_icon" "$project" "$focus_short"
      fi
    else
      if [[ -n "$urgency_icon" ]]; then
        printf "  %s %s %s ${FLOW_COLORS[info]}%-14s${FLOW_COLORS[reset]}\n" "$prefix" "$status_icon" "$urgency_icon" "$project"
      else
        printf "  %s %s ${FLOW_COLORS[info]}%-16s${FLOW_COLORS[reset]}\n" "$prefix" "$status_icon" "$project"
      fi
    fi

    ((count++))
  done

  echo ""
}

# ============================================================================
# RECENT WINS - Dopamine boost (v3.5.0)
# ============================================================================

_dash_recent_wins() {
  local wins_file="${FLOW_DATA_DIR}/wins.md"

  # Skip if no wins file
  [[ -f "$wins_file" ]] || return 0

  # Get today's wins and recent wins
  zmodload -F zsh/datetime b:strftime
  local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)
  local -a today_wins=()
  local -a recent_wins=()
  local total_wins=0

  # Parse wins file (format: - 🎉 text (@project) [YYYY-MM-DD HH:MM])
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ((total_wins++))

    # Extract date from [YYYY-MM-DD HH:MM]
    if [[ "$line" =~ '\[([0-9]{4}-[0-9]{2}-[0-9]{2})' ]]; then
      local win_date="${match[1]}"

      # Extract text (between 🎉 and (@project) or [date])
      local win_text="${line#*🎉 }"
      win_text="${win_text%% \(@*}"
      win_text="${win_text%% \[*}"

      if [[ "$win_date" == "$today" ]]; then
        today_wins+=("$win_text")
      elif [[ ${#recent_wins[@]} -lt 3 ]]; then
        recent_wins+=("$win_text")
      fi
    fi
  done < "$wins_file"

  # Display section only if there are wins
  (( total_wins == 0 )) && return 0

  echo "  🎉 ${FLOW_COLORS[bold]}RECENT WINS${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(Dopamine boost!)${FLOW_COLORS[reset]}"

  # Show today's wins
  if (( ${#today_wins[@]} > 0 )); then
    echo "     ${FLOW_COLORS[success]}Today:${FLOW_COLORS[reset]}"
    for win in "${today_wins[@]:0:3}"; do
      # Truncate long wins
      (( ${#win} > 45 )) && win="${win:0:42}..."
      echo "     ✓ ${FLOW_COLORS[accent]}${win}${FLOW_COLORS[reset]}"
    done
    if (( ${#today_wins[@]} > 3 )); then
      echo "     ${FLOW_COLORS[muted]}  +$((${#today_wins[@]} - 3)) more today${FLOW_COLORS[reset]}"
    fi
  else
    echo "     ${FLOW_COLORS[muted]}No wins logged today. Use 'win' to celebrate!${FLOW_COLORS[reset]}"
  fi

  # Calculate streak
  local streak=0
  local check_date="$today"
  local prev_day=""

  # Sort wins by date and count streak
  for (( i = 1; i <= 30; i++ )); do
    if grep -q "\[$check_date" "$wins_file" 2>/dev/null; then
      ((streak++))
      # Go back one day
      prev_day=$check_date
      check_date=$(strftime "%Y-%m-%d" $((EPOCHSECONDS - i * 86400)))
    else
      break
    fi
  done

  # Show streak if > 1
  if (( streak > 1 )); then
    echo "     🔥 ${FLOW_COLORS[success]}${streak}-day streak!${FLOW_COLORS[reset]}"
  fi

  # Show daily goal progress (v3.5.0)
  if typeset -f _flow_read_goal >/dev/null 2>&1; then
    local target=$(_flow_read_goal)
    local current=${#today_wins[@]}
    if (( target > 0 )); then
      local percent=$((current * 100 / target))
      (( percent > 100 )) && percent=100

      # Build mini progress bar
      local bar_width=10
      local filled=$((percent * bar_width / 100))
      local empty=$((bar_width - filled))
      local bar=""
      for (( i = 0; i < filled; i++ )); do bar+="█"; done
      for (( i = 0; i < empty; i++ )); do bar+="░"; done

      if (( current >= target )); then
        echo "     🎯 ${FLOW_COLORS[success]}[$bar] Goal reached! ($current/$target)${FLOW_COLORS[reset]}"
      else
        echo "     🎯 ${FLOW_COLORS[muted]}[$bar] $current/$target wins today${FLOW_COLORS[reset]}"
      fi
    fi
  fi

  echo ""
}

# ============================================================================
# CATEGORIES - Grouped summary
# ============================================================================

_dash_categories() {
  # Count projects per category and track progress
  local -A cat_total
  local -A cat_active
  local -A cat_progress_sum
  local -A cat_progress_count

  # Initialize counts
  for key in dev r research teach quarto apps; do
    cat_total[$key]=0
    cat_active[$key]=0
    cat_progress_sum[$key]=0
    cat_progress_count[$key]=0
  done

  # Count projects and collect progress
  local all_projects=$(_flow_list_projects)
  local total=0

  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    ((total++))

    local proj_path=$(_dash_find_project_path "$project")
    [[ -z "$proj_path" ]] && continue

    local cat=$(_dash_detect_category "$proj_path")
    [[ -z "$cat" ]] && cat="dev"

    ((cat_total[$cat]++))

    # Check status and progress
    if [[ -f "$proj_path/.STATUS" ]]; then
      local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
      if [[ "$proj_status" == "active" ]]; then
        ((cat_active[$cat]++))
      fi

      # Collect progress for average
      local progress=$(_dash_get_project_progress "$proj_path/.STATUS")
      if [[ -n "$progress" ]] && [[ "$progress" =~ ^[0-9]+$ ]]; then
        ((cat_progress_sum[$cat] += progress))
        ((cat_progress_count[$cat]++))
      fi
    fi
  done <<< "$all_projects"

  echo "  📋 ${FLOW_COLORS[bold]}BY CATEGORY${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}($total total)${FLOW_COLORS[reset]}"

  # Category metadata
  local -A cat_icons cat_names
  cat_icons=([dev]="🔧" [r]="📦" [research]="🔬" [teach]="🎓" [quarto]="📝" [apps]="📱")
  cat_names=([dev]="dev-tools" [r]="r-packages" [research]="research" [teach]="teaching" [quarto]="quarto" [apps]="apps")

  # Sort categories: active count (desc), then total count (desc)
  local sorted_cats=()
  local cat_key

  for cat_key in dev r research teach quarto apps; do
    local t="${cat_total[$cat_key]:-0}"
    (( t == 0 )) && continue
    local a="${cat_active[$cat_key]:-0}"
    # Create sortable key: active*1000 + total (for stable sort)
    sorted_cats+=("$(printf '%04d:%04d:%s' $((1000-a)) $((1000-t)) "$cat_key")")
  done

  # Sort and extract category names
  local sorted=(${(o)sorted_cats})
  local display_cats=()
  for item in "${sorted[@]}"; do
    display_cats+=("${item##*:}")
  done

  local num_cats=${#display_cats[@]}
  local idx=0

  for cat in "${display_cats[@]}"; do
    ((idx++))
    local icon="${cat_icons[$cat]}"
    local name="${cat_names[$cat]}"
    local t="${cat_total[$cat]:-0}"
    local a="${cat_active[$cat]:-0}"

    local prefix="├─"
    (( idx == num_cats )) && prefix="└─"

    # Calculate average progress
    local avg_progress=0
    if (( cat_progress_count[$cat] > 0 )); then
      avg_progress=$((cat_progress_sum[$cat] / cat_progress_count[$cat]))
    fi

    # Build progress bar (10 chars for better visibility)
    local bar=""
    if (( cat_progress_count[$cat] > 0 )); then
      local filled=$((avg_progress / 10))  # 10 segments = 10% each
      local empty=$((10 - filled))
      local bar_filled="" bar_empty=""
      (( filled > 0 )) && bar_filled=$(printf '█%.0s' {1..$filled})
      (( empty > 0 )) && bar_empty=$(printf '░%.0s' {1..$empty})
      bar="[${bar_filled}${bar_empty}]"
    else
      bar="[░░░░░░░░░░]"
    fi

    printf "  %s %s ${FLOW_COLORS[info]}%-12s${FLOW_COLORS[reset]} %s %3d%%  │  " "$prefix" "$icon" "$name" "$bar" "$avg_progress"

    if (( a > 0 )); then
      printf "${FLOW_COLORS[success]}%d active${FLOW_COLORS[reset]} / %d\n" "$a" "$t"
    else
      printf "${FLOW_COLORS[muted]}0 active${FLOW_COLORS[reset]} / %d\n" "$t"
    fi
  done

  echo ""
}

# ============================================================================
# CATEGORY EXPANDED - Show all projects in a category
# ============================================================================

_dash_category_expanded() {
  local cat="$1"
  local cat_icon=""
  local cat_name=""

  case "$cat" in
    dev)      cat_icon="🔧"; cat_name="DEV-TOOLS" ;;
    r)        cat_icon="📦"; cat_name="R-PACKAGES" ;;
    research) cat_icon="🔬"; cat_name="RESEARCH" ;;
    teach)    cat_icon="🎓"; cat_name="TEACHING" ;;
    quarto)   cat_icon="📝"; cat_name="QUARTO" ;;
    apps)     cat_icon="📱"; cat_name="APPS" ;;
  esac

  echo ""
  echo "  $cat_icon ${FLOW_COLORS[bold]}$cat_name${FLOW_COLORS[reset]}"
  echo "  ─────────────────────────────────────────────────────────────"
  echo ""

  # Collect and sort projects (active first, then alphabetically)
  local projects=$(_flow_list_projects)
  local -a active_projects=()
  local -a other_projects=()

  while IFS= read -r project; do
    [[ -z "$project" ]] && continue

    local proj_path=$(_dash_find_project_path "$project")
    [[ -z "$proj_path" ]] && continue

    local proj_cat=$(_dash_detect_category "$proj_path")
    [[ "$proj_cat" != "$cat" ]] && continue

    # Check if active
    local proj_status=""
    if [[ -f "$proj_path/.STATUS" ]]; then
      proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
    fi

    if [[ "$proj_status" == "active" ]]; then
      active_projects+=("$project")
    else
      other_projects+=("$project")
    fi
  done <<< "$projects"

  # Sort each group alphabetically
  active_projects=(${(o)active_projects})
  other_projects=(${(o)other_projects})

  # Combined sorted list
  local -a sorted_projects=("${active_projects[@]}" "${other_projects[@]}")
  local count=${#sorted_projects[@]}

  # Display projects
  for project in "${sorted_projects[@]}"; do
    local proj_path=$(_dash_find_project_path "$project")
    local status_icon="⚪"
    local focus=""
    local progress=""

    if [[ -f "$proj_path/.STATUS" ]]; then
      local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
      status_icon=$(_flow_status_icon "$proj_status")
      focus=$(_dash_get_project_focus "$proj_path/.STATUS")
      progress=$(_dash_get_project_progress "$proj_path/.STATUS")
    fi

    local type_icon=$(_flow_project_icon "$(_flow_detect_project_type "$proj_path" 2>/dev/null)")

    # Progress bar (10-char for consistency)
    local bar=""
    if [[ -n "$progress" ]] && [[ "$progress" =~ ^[0-9]+$ ]]; then
      local filled=$((progress / 10))
      local empty=$((10 - filled))
      local bar_filled="" bar_empty=""
      (( filled > 0 )) && bar_filled=$(printf '█%.0s' {1..$filled})
      (( empty > 0 )) && bar_empty=$(printf '░%.0s' {1..$empty})
      bar=" [${bar_filled}${bar_empty}] ${progress}%"
    fi

    printf "  %s %s %-20s" "$status_icon" "$type_icon" "$project"
    [[ -n "$bar" ]] && printf "%s" "$bar"
    echo ""

    if [[ -n "$focus" ]]; then
      printf "       ${FLOW_COLORS[muted]}→ %.50s${FLOW_COLORS[reset]}\n" "$focus"
    fi
  done

  if (( count == 0 )); then
    echo "  ${FLOW_COLORS[muted]}No projects in this category${FLOW_COLORS[reset]}"
  fi

  echo ""
  echo "  ${FLOW_COLORS[muted]}← 'dash' to return to summary${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# ALL PROJECTS - Flat list (when using -a flag)
# ============================================================================

_dash_all_projects() {
  echo "  📋 ${FLOW_COLORS[bold]}ALL PROJECTS${FLOW_COLORS[reset]}"
  echo ""

  local projects=$(_flow_list_projects)

  while IFS= read -r project; do
    [[ -z "$project" ]] && continue

    local proj_path=$(_dash_find_project_path "$project")
    local status_icon="⚪"
    local focus=""

    if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
      local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
      status_icon=$(_flow_status_icon "$proj_status")
      focus=$(_dash_get_project_focus "$proj_path/.STATUS")
      focus="${focus:0:40}"  # Truncate
    fi

    local type_icon=$(_flow_project_icon "$(_flow_detect_project_type "$proj_path" 2>/dev/null)")

    printf "  %s %s %-20s" "$status_icon" "$type_icon" "$project"
    [[ -n "$focus" ]] && printf " ${FLOW_COLORS[muted]}│ %s${FLOW_COLORS[reset]}" "$focus"
    echo ""
  done <<< "$projects"

  echo ""
}

# ============================================================================
# FOOTER
# ============================================================================

# ============================================================================
# RANDOM TIPS
# ============================================================================

_dash_random_tip() {
  # Show tips ~20% of the time
  (( RANDOM % 5 != 0 )) && return

  local -a tips
  tips=(
    "Use ${FLOW_COLORS[cmd]}pick --recent${FLOW_COLORS[reset]} to see projects with Claude sessions"
    "Try ${FLOW_COLORS[cmd]}cc yolo pick${FLOW_COLORS[reset]} for quick Claude launch without prompts"
    "Run ${FLOW_COLORS[cmd]}flow doctor --fix${FLOW_COLORS[reset]} to install missing tools interactively"
    "Use ${FLOW_COLORS[cmd]}wt create <branch>${FLOW_COLORS[reset]} for clean git worktrees"
    "Log wins with ${FLOW_COLORS[cmd]}win \"text\"${FLOW_COLORS[reset]} - they auto-categorize!"
    "Set daily goals: ${FLOW_COLORS[cmd]}flow goal set 3${FLOW_COLORS[reset]} for motivation"
    "Try ${FLOW_COLORS[cmd]}dash -i${FLOW_COLORS[reset]} for interactive project picker"
    "Use ${FLOW_COLORS[cmd]}g feature start <name>${FLOW_COLORS[reset]} for clean feature branches"
    "Run ${FLOW_COLORS[cmd]}yay --week${FLOW_COLORS[reset]} to see your weekly accomplishments graph"
    "Quick commit: ${FLOW_COLORS[cmd]}g commit \"msg\"${FLOW_COLORS[reset]} combines add & commit"
    "Check streaks with ${FLOW_COLORS[cmd]}flow goal${FLOW_COLORS[reset]} - consistency builds momentum!"
    "Use ${FLOW_COLORS[cmd]}hop <project>${FLOW_COLORS[reset]} for instant tmux session switching"
  )

  local tip_index=$(( RANDOM % ${#tips[@]} + 1 ))
  echo "  💡 ${FLOW_COLORS[muted]}Tip: ${tips[$tip_index]}${FLOW_COLORS[reset]}"
  echo ""
}

_dash_footer() {
  local inbox_count=0

  # Get inbox count
  if _flow_has_atlas; then
    inbox_count=$(atlas inbox --count 2>/dev/null || echo "0")
  else
    local inbox="${FLOW_DATA_DIR}/inbox.md"
    if [[ -f "$inbox" ]]; then
      # Count lines using ZSH array (no external commands)
      local -a lines
      lines=("${(@f)$(< "$inbox")}")
      inbox_count=${#lines[@]}
    fi
  fi

  echo "  ─────────────────────────────────────────────────────────────"

  # Context-aware single suggestion
  local suggestion=""
  
  # Check if in active session
  local current_project=""
  local session_info=$(_flow_session_current 2>/dev/null)
  if [[ -n "$session_info" ]]; then
    eval "$session_info"
    current_project="$project"
  elif [[ -n "$FLOW_CURRENT_PROJECT" ]]; then
    current_project="$FLOW_CURRENT_PROJECT"
  fi
  
  if [[ -n "$current_project" ]]; then
    suggestion="💡 Type 'finish' when done  •  'dash -i' to switch  •  'h' for help"
  else
    # Find first active project to suggest
    local projects=$(_flow_list_projects)
    local suggested=""
    while IFS= read -r project; do
      [[ -z "$project" ]] && continue
      local proj_path=$(_dash_find_project_path "$project")
      if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
        local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
        if [[ "$proj_status" == "active" ]]; then
          suggested="$project"
          break
        fi
      fi
    done <<< "$projects"
    
    if [[ -n "$suggested" ]]; then
      suggestion="💡 Try: 'work $suggested' to start  •  'dash -i' for picker  •  'h' for help"
    else
      suggestion="💡 Run 'work <project>' to start  •  'dash -i' for picker  •  'h' for help"
    fi
  fi
  
  if (( inbox_count > 0 )); then
    echo "  📥 ${FLOW_COLORS[warning]}Inbox: $inbox_count items${FLOW_COLORS[reset]}"
  fi

  # Show random tip (~20% of the time)
  _dash_random_tip

  echo ""
  echo "  ${FLOW_COLORS[muted]}$suggestion${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# HELP
# ============================================================================

_dash_help() {
  # Colors
  local _C_BOLD="${_C_BOLD:-\033[1m}"
  local _C_NC="${_C_NC:-\033[0m}"
  local _C_GREEN="${_C_GREEN:-\033[0;32m}"
  local _C_CYAN="${_C_CYAN:-\033[0;36m}"
  local _C_BLUE="${_C_BLUE:-\033[0;34m}"
  local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
  local _C_MAGENTA="${_C_MAGENTA:-\033[0;35m}"
  local _C_DIM="${_C_DIM:-\033[2m}"

  echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ 🌊 DASH - Project Dashboard                 │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} dash [option|category]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}dash${_C_NC}              Summary dashboard (default)
  ${_C_CYAN}dash dev${_C_NC}          Expand dev-tools projects
  ${_C_CYAN}dash -i${_C_NC}           Interactive fzf picker

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} dash                   ${_C_DIM}# Summary view${_C_NC}
  ${_C_DIM}\$${_C_NC} dash dev               ${_C_DIM}# Dev-tools projects${_C_NC}
  ${_C_DIM}\$${_C_NC} dash r                 ${_C_DIM}# R packages${_C_NC}
  ${_C_DIM}\$${_C_NC} dash -i                ${_C_DIM}# Interactive picker${_C_NC}
  ${_C_DIM}\$${_C_NC} dash -w                ${_C_DIM}# Auto-refresh every 5s${_C_NC}
  ${_C_DIM}\$${_C_NC} dash -w 10             ${_C_DIM}# Auto-refresh every 10s${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}(none)${_C_NC}            Summary view (default)
  ${_C_CYAN}-a, --all${_C_NC}         Show all projects (flat list)
  ${_C_CYAN}-i${_C_NC}                Interactive mode with fzf picker
  ${_C_CYAN}-w [sec]${_C_NC}          Watch mode - auto-refresh (default: 5s)
  ${_C_CYAN}-f, --full${_C_NC}        Interactive TUI (requires atlas)
  ${_C_CYAN}-h, --help${_C_NC}        Show this help

${_C_BLUE}⌨️  INTERACTIVE KEYS${_C_NC} (with -i):
  ${_C_CYAN}Enter${_C_NC}             Start work on project
  ${_C_CYAN}Ctrl-D${_C_NC}            Open project dashboard
  ${_C_CYAN}Ctrl-E${_C_NC}            Edit .STATUS file
  ${_C_CYAN}Ctrl-S${_C_NC}            Show status with extended info
  ${_C_CYAN}Ctrl-W${_C_NC}            Show project wins
  ${_C_CYAN}?${_C_NC}                 Toggle preview panel

${_C_BLUE}📂 CATEGORIES${_C_NC}:
  ${_C_CYAN}dev${_C_NC}               Dev-tools projects
  ${_C_CYAN}r${_C_NC}                 R packages
  ${_C_CYAN}research${_C_NC}          Research projects
  ${_C_CYAN}teach${_C_NC}             Teaching projects
  ${_C_CYAN}quarto${_C_NC}            Quarto projects
  ${_C_CYAN}apps${_C_NC}              Applications

${_C_BLUE}🎨 LEGEND${_C_NC}:
  🟢 Active    🟡 Paused    🔴 Blocked
  🟠 Stalled   ⚫ Archived  ⚪ Unknown

${_C_BLUE}⚡ URGENCY INDICATORS${_C_NC}:
  🔥 High (deadline/urgent)
  ⏰ Medium (time-sensitive)
  ⚡ Quick win (< 30 min)

${_C_DIM}See also:${_C_NC} work help, status help, pick help
"
}

# ============================================================================
# HELPERS
# ============================================================================

# Find project path by name
_dash_find_project_path() {
  local name="$1"
  local search_dirs=(
    "$FLOW_PROJECTS_ROOT/dev-tools"
    "$FLOW_PROJECTS_ROOT/apps"
    "$FLOW_PROJECTS_ROOT/r-packages/active"
    "$FLOW_PROJECTS_ROOT/r-packages/stable"
    "$FLOW_PROJECTS_ROOT/research"
    "$FLOW_PROJECTS_ROOT/teaching"
    "$FLOW_PROJECTS_ROOT/quarto/manuscripts"
    "$FLOW_PROJECTS_ROOT/quarto/presentations"
    "$FLOW_PROJECTS_ROOT"
  )

  for dir in "${search_dirs[@]}"; do
    if [[ -d "$dir/$name" ]]; then
      echo "$dir/$name"
      return 0
    fi
  done

  return 1
}

# Detect category from path
_dash_detect_category() {
  local path="$1"

  case "$path" in
    */dev-tools/*) echo "dev" ;;
    */r-packages/*) echo "r" ;;
    */research/*) echo "research" ;;
    */teaching/*) echo "teach" ;;
    */quarto/*) echo "quarto" ;;
    */apps/*) echo "apps" ;;
    *) echo "dev" ;;
  esac
}

# Parse .STATUS field (supports both "## Field:" and "field:" formats)
# Uses ZSH builtins only - no external commands
_dash_get_status_field() {
  local file="$1"
  local field="$2"
  local value="" line

  [[ ! -f "$file" ]] && return 1

  # Read file and find matching line
  while IFS= read -r line; do
    # Try markdown format (## Field:)
    if [[ "$line" == "## ${field}:"* ]]; then
      value="${line#*: }"  # Remove everything up to ": "
      value="${value#"${value%%[![:space:]]*}"}"  # Trim leading whitespace
      break
    fi
    # Try YAML format (field:)
    if [[ "$line" == "${field}:"* ]]; then
      value="${line#*: }"
      value="${value#"${value%%[![:space:]]*}"}"
      break
    fi
  done < "$file"

  # Normalize status values
  if [[ "$field" == "Status" || "$field" == "status" ]]; then
    value="${value:l}"      # ZSH: lowercase
    value="${value// /}"    # ZSH: remove spaces
    # Map variations
    case "$value" in
      underreview) value="active" ;;
      inprogress) value="active" ;;
      wip) value="active" ;;
      onhold) value="paused" ;;
    esac
  fi

  echo "$value"
}

# Get project status
_dash_get_project_status() {
  local status_file="$1"
  _dash_get_status_field "$status_file" "Status"
}

# Get project focus
_dash_get_project_focus() {
  local status_file="$1"
  local focus=""
  focus=$(_dash_get_status_field "$status_file" "Focus")
  [[ -z "$focus" ]] && focus=$(_dash_get_status_field "$status_file" "next")
  echo "$focus"
}

# Get project progress
_dash_get_project_progress() {
  local status_file="$1"
  local progress=""
  progress=$(_dash_get_status_field "$status_file" "Progress")
  [[ -z "$progress" ]] && progress=$(_dash_get_status_field "$status_file" "progress")
  echo "${progress//%/}"  # Remove % if present
}

# Quick health check (fast, cached, for header display)
# Returns number of issues (0 = all good)
_dash_quick_health_check() {
  local cache_file="${FLOW_DATA_DIR:-/tmp}/.health_cache"
  local cache_ttl=3600  # 1 hour cache

  # Check cache
  if [[ -f "$cache_file" ]]; then
    local cache_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    local now=$EPOCHSECONDS
    if (( now - cache_time < cache_ttl )); then
      cat "$cache_file"
      return
    fi
  fi

  # Quick checks (no external commands for speed)
  local issues=0

  # Required: fzf
  command -v fzf >/dev/null 2>&1 || ((issues++))

  # Recommended core tools (only count critical ones)
  command -v eza >/dev/null 2>&1 || ((issues++))
  command -v bat >/dev/null 2>&1 || ((issues++))
  command -v fd >/dev/null 2>&1 || ((issues++))
  command -v rg >/dev/null 2>&1 || ((issues++))

  # Cache result
  echo "$issues" > "$cache_file" 2>/dev/null
  echo "$issues"
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

_dash_interactive() {
  # Check for fzf
  if ! command -v fzf &>/dev/null; then
    _flow_log_error "fzf not installed. Install with: brew install fzf"
    return 1
  fi

  # Build project list with status info
  local projects=$(_flow_list_projects)
  local -a project_lines=()

  while IFS= read -r project; do
    [[ -z "$project" ]] && continue

    local proj_path=$(_dash_find_project_path "$project")
    local status_icon="⚪"
    local focus=""
    local cat_icon=""

    if [[ -n "$proj_path" ]]; then
      local cat=$(_dash_detect_category "$proj_path")
      case "$cat" in
        dev) cat_icon="🔧" ;;
        r) cat_icon="📦" ;;
        research) cat_icon="🔬" ;;
        teach) cat_icon="🎓" ;;
        quarto) cat_icon="📝" ;;
        apps) cat_icon="📱" ;;
      esac

      if [[ -f "$proj_path/.STATUS" ]]; then
        local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
        status_icon=$(_flow_status_icon "$proj_status")
        focus=$(_dash_get_project_focus "$proj_path/.STATUS")
        focus="${focus:0:40}"
      fi
    fi

    # Format: icon status name :: focus (the :: is a separator for fzf)
    if [[ -n "$focus" ]]; then
      project_lines+=("$cat_icon $status_icon $project :: $focus")
    else
      project_lines+=("$cat_icon $status_icon $project")
    fi
  done <<< "$projects"

  # Sort: active projects first (🟢 comes before other icons alphabetically)
  local sorted_lines=$(printf '%s\n' "${project_lines[@]}" | sort -t' ' -k2,2 -k3,3)

  # Create enhanced preview script (v3.5.0)
  local preview_cmd='
    project=$(echo {} | sed "s/.*[🔧📦🔬🎓📝📱] [🟢🟡🔴🟠⚫⚪] //" | command cut -d: -f1 | xargs)
    path=$(find ~/projects -maxdepth 4 -type d -name "$project" 2>/dev/null | head -1)
    if [[ -f "$path/.STATUS" ]]; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "📁 $project"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      # Show key fields
      grep -E "^## (Status|Phase|Progress|Focus|Next|wins|streak|tags|last_active):" "$path/.STATUS" 2>/dev/null | head -10
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      # Git status if available
      if [[ -d "$path/.git" ]]; then
        cd "$path" && git log --oneline -3 2>/dev/null | while read line; do echo "  $line"; done
      fi
      echo ""
      echo "📂 $path"
    else
      echo "No .STATUS file"
      echo "Path: $path"
    fi
  '

  # Run fzf with enhanced keybindings (v3.5.0)
  local selected=$(echo "$sorted_lines" | fzf \
    --ansi \
    --header="🌊 FLOW DASHBOARD │ ↵:work  ^D:dash  ^E:edit  ^S:status  ^W:wins  ?:help" \
    --preview="$preview_cmd" \
    --preview-window=right:50%:wrap \
    --bind="ctrl-d:execute(echo DASH {})+abort" \
    --bind="ctrl-e:execute(echo EDIT {})+abort" \
    --bind="ctrl-s:execute(echo STATUS {})+abort" \
    --bind="ctrl-w:execute(echo WINS {})+abort" \
    --bind="enter:accept" \
    --bind="?:toggle-preview" \
    --height=80% \
    --border=rounded \
    --prompt="🔍 " \
    --pointer="▶" \
    --marker="✓" \
    --color="header:italic")

  [[ -z "$selected" ]] && return 0

  # Extract project name using ZSH (no sed/cut/xargs)
  # Format is: "cat_icon status_icon project_name :: focus"
  local project_name="$selected"
  # Remove leading "DASH " if present
  project_name="${project_name#DASH }"
  # Remove category icon and space (first 2 chars + space)
  project_name="${project_name#?? }"
  # Remove status icon and space (next 2 chars + space)
  project_name="${project_name#?? }"
  # Remove everything after " ::" if present
  project_name="${project_name%% ::*}"
  # Trim whitespace
  project_name="${project_name#"${project_name%%[![:space:]]*}"}"
  project_name="${project_name%"${project_name##*[![:space:]]}"}"

  # Handle action based on keybinding (v3.5.0)
  local proj_path=$(_dash_find_project_path "$project_name")

  if [[ "$selected" == "DASH "* ]]; then
    # Ctrl-D: Show category dashboard
    local cat=$(_dash_detect_category "$proj_path")
    dash "$cat"
  elif [[ "$selected" == "EDIT "* ]]; then
    # Ctrl-E: Edit .STATUS file
    if [[ -f "$proj_path/.STATUS" ]]; then
      ${EDITOR:-vim} "$proj_path/.STATUS"
    else
      _flow_log_warning "No .STATUS file for $project_name"
    fi
  elif [[ "$selected" == "STATUS "* ]]; then
    # Ctrl-S: Show detailed status
    status "$project_name" --extended
  elif [[ "$selected" == "WINS "* ]]; then
    # Ctrl-W: Show project wins
    if [[ -f "$proj_path/.STATUS" ]]; then
      local wins=$(command grep -i "^## wins:" "$proj_path/.STATUS" 2>/dev/null | sed 's/^## wins: *//')
      if [[ -n "$wins" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[header]}🎉 Wins for $project_name${FLOW_COLORS[reset]}"
        echo ""
        local -a wins_arr
        wins_arr=("${(@s:, :)wins}")
        for win in "${wins_arr[@]}"; do
          echo "  ✓ ${FLOW_COLORS[accent]}$win${FLOW_COLORS[reset]}"
        done
        echo ""
      else
        _flow_log_info "No wins logged for $project_name yet"
      fi
    else
      _flow_log_warning "No .STATUS file for $project_name"
    fi
  else
    # Enter: Start work session
    work "$project_name"
  fi
}

# ============================================================================
# WATCH MODE (v3.5.0)
# ============================================================================

_dash_watch() {
  local interval="${1:-5}"

  echo ""
  echo "  ${FLOW_COLORS[header]}🔄 Watch Mode${FLOW_COLORS[reset]} (refreshing every ${interval}s, Ctrl-C to exit)"
  echo ""

  while true; do
    clear
    dash
    echo ""
    echo "  ${FLOW_COLORS[muted]}Last updated: $(date '+%H:%M:%S') │ Ctrl-C to exit${FLOW_COLORS[reset]}"
    sleep "$interval"
  done
}

# ============================================================================
# ALIASES
# ============================================================================

alias di='dash -i'
