# commands/capture.zsh - Quick capture commands
# Frictionless idea and task capture for ADHD workflows

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Load datetime module once at startup (used by win, yay, flow goal)
zmodload -F zsh/datetime b:strftime

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
# TRAIL - Show breadcrumb trail
# ============================================================================

trail() {
  local project="${1:-}"
  local limit="${2:-20}"
  
  # If no project specified, try to detect from current directory
  if [[ -z "$project" ]] && _flow_in_project; then
    project=$(_flow_project_name "$(_flow_find_project_root)")
  fi
  
  if _flow_has_atlas; then
    if [[ -n "$project" ]]; then
      _flow_atlas trail "$project" --limit="$limit"
    else
      _flow_atlas trail --limit="$limit"
    fi
  else
    # Fallback: Show from local trail file
    local trail_file="${FLOW_DATA_DIR}/trail.log"
    if [[ -f "$trail_file" ]]; then
      echo ""
      echo "  ${FLOW_COLORS[header]}🍞 Breadcrumb Trail${FLOW_COLORS[reset]}"
      echo ""
      if [[ -n "$project" ]]; then
        grep "\[$project\]" "$trail_file" | tail -"$limit"
      else
        tail -"$limit" "$trail_file"
      fi
      echo ""
    else
      _flow_log_info "No breadcrumbs yet. Use 'crumb' to leave one."
    fi
  fi
}

# ============================================================================
# QUICK CAPTURE ALIASES
# ============================================================================

# Very short aliases for minimal friction
c() { catch "$@" }
i() { inbox "$@" }
b() { crumb "$@" }
t() { trail "$@" }

# ============================================================================
# WIN CATEGORIES
# ============================================================================

# Category icons for visual identification
typeset -gA FLOW_WIN_CATEGORIES=(
  [code]="💻"
  [docs]="📝"
  [review]="👀"
  [ship]="🚀"
  [fix]="🔧"
  [test]="🧪"
  [other]="✨"
)

# Auto-detect win category from text
_flow_detect_win_category() {
  local text="${1:l}"  # lowercase for matching

  # Ship indicators (highest priority)
  if [[ "$text" =~ (deploy|release|ship|publish|merge|launch|live) ]]; then
    echo "ship"
  # Review indicators
  elif [[ "$text" =~ (review|pr|feedback|approve|comment) ]]; then
    echo "review"
  # Test indicators
  elif [[ "$text" =~ (test|spec|coverage|passing|green) ]]; then
    echo "test"
  # Fix indicators
  elif [[ "$text" =~ (fix|bug|issue|resolve|patch|debug) ]]; then
    echo "fix"
  # Docs indicators
  elif [[ "$text" =~ (doc|readme|guide|tutorial|comment|explain) ]]; then
    echo "docs"
  # Code indicators (default for dev work)
  elif [[ "$text" =~ (implement|add|create|build|refactor|code|function|feature) ]]; then
    echo "code"
  else
    echo "other"
  fi
}

# ============================================================================
# WIN - Dopamine logging (celebrate small wins!)
# ============================================================================

win() {
  local category=""
  local text=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --code|-c)     category="code"; shift ;;
      --docs|-d)     category="docs"; shift ;;
      --review|-r)   category="review"; shift ;;
      --ship|-s)     category="ship"; shift ;;
      --fix|-f)      category="fix"; shift ;;
      --test|-t)     category="test"; shift ;;
      --category=*)  category="${1#--category=}"; shift ;;
      *)             text="$text $1"; shift ;;
    esac
  done
  text="${text# }"  # trim leading space

  if [[ -z "$text" ]]; then
    if _flow_has_gum; then
      text=$(gum input --placeholder="What did you accomplish?" --width=60)
    else
      read "text?🎉 What's your win? "
    fi
    [[ -z "$text" ]] && return 1
  fi

  # Auto-detect category if not specified
  [[ -z "$category" ]] && category=$(_flow_detect_win_category "$text")

  local project=""
  if _flow_in_project; then
    project=$(_flow_project_name "$(_flow_find_project_root)")
  fi

  local cat_icon="${FLOW_WIN_CATEGORIES[$category]:-✨}"

  # Log the win to local file
  # TODO: Add atlas --type=win support when available in atlas CLI
  local wins="${FLOW_DATA_DIR}/wins.md"
  local timestamp=$(strftime "%Y-%m-%d %H:%M" $EPOCHSECONDS)
  echo "- $cat_icon $text${project:+ (@$project)} #$category [$timestamp]" >> "$wins"

  # Also update project .STATUS if in a project (v3.5.0)
  if _flow_in_project; then
    local root=$(_flow_find_project_root)
    if [[ -f "$root/.STATUS" ]] && typeset -f _flow_status_add_win >/dev/null 2>&1; then
      _flow_status_add_win "$root" "$text" "$category"
    fi
  fi

  # Celebrate!
  echo ""
  echo "  🎉 ${FLOW_COLORS[success]}WIN LOGGED!${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}#$category${FLOW_COLORS[reset]}"
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
  local wins="${FLOW_DATA_DIR}/wins.md"

  case "$1" in
    --week|-w)
      # Weekly wins summary (v3.5.0)
      echo ""
      echo "  ${FLOW_COLORS[header]}📊 This Week's Wins${FLOW_COLORS[reset]}"
      echo ""

      if [[ ! -f "$wins" ]]; then
        echo "  No wins yet. Use 'win' to log your first!"
        echo ""
        return
      fi

      # Calculate 7 days ago
      local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)
      local week_ago=$(strftime "%Y-%m-%d" $((EPOCHSECONDS - 7 * 86400)))
      local count=0
      local -A day_counts
      local -A cat_counts

      # Initialize counts
      for (( i = 0; i < 7; i++ )); do
        local day=$(strftime "%Y-%m-%d" $((EPOCHSECONDS - i * 86400)))
        day_counts[$day]=0
      done

      # Initialize category counts
      for cat in code docs review ship fix test other; do
        cat_counts[$cat]=0
      done

      # Count wins per day and category
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ '\[([0-9]{4}-[0-9]{2}-[0-9]{2})' ]]; then
          local win_date="${match[1]}"
          if [[ ! "$win_date" < "$week_ago" ]]; then
            ((count++))
            ((day_counts[$win_date]++))

            # Extract category
            local win_cat="other"
            if [[ "$line" =~ '#([a-z]+)' ]]; then
              win_cat="${match[1]}"
            fi
            ((cat_counts[$win_cat]++))

            # Get icon and text
            local win_icon="${FLOW_WIN_CATEGORIES[$win_cat]:-✨}"
            local win_text="${line#*- }"
            win_text="${win_text#* }"  # Remove icon
            win_text="${win_text%% \#*}"  # Remove category tag
            win_text="${win_text%% \[*}"  # Remove timestamp
            (( ${#win_text} > 45 )) && win_text="${win_text:0:42}..."
            echo "  $win_icon ${FLOW_COLORS[accent]}${win_text}${FLOW_COLORS[reset]}"
          fi
        fi
      done < "$wins"

      echo ""
      echo "  ${FLOW_COLORS[muted]}─────────────────────────────────────${FLOW_COLORS[reset]}"

      # Category breakdown (only show non-zero)
      local cat_summary=""
      for cat in ship code fix docs review test; do
        if (( cat_counts[$cat] > 0 )); then
          local icon="${FLOW_WIN_CATEGORIES[$cat]}"
          cat_summary="$cat_summary $icon${cat_counts[$cat]}"
        fi
      done
      if [[ -n "$cat_summary" ]]; then
        echo "  ${FLOW_COLORS[muted]}Breakdown:${FLOW_COLORS[reset]}$cat_summary"
      fi

      echo "  ${FLOW_COLORS[success]}Total: $count wins this week!${FLOW_COLORS[reset]}"

      # Mini graph
      echo -n "  "
      for (( i = 6; i >= 0; i-- )); do
        local day=$(strftime "%Y-%m-%d" $((EPOCHSECONDS - i * 86400)))
        local day_count=${day_counts[$day]:-0}
        if (( day_count == 0 )); then
          echo -n "${FLOW_COLORS[muted]}·${FLOW_COLORS[reset]}"
        elif (( day_count < 3 )); then
          echo -n "${FLOW_COLORS[accent]}▂${FLOW_COLORS[reset]}"
        elif (( day_count < 5 )); then
          echo -n "${FLOW_COLORS[success]}▄${FLOW_COLORS[reset]}"
        else
          echo -n "${FLOW_COLORS[success]}█${FLOW_COLORS[reset]}"
        fi
      done
      echo " ${FLOW_COLORS[muted]}(last 7 days)${FLOW_COLORS[reset]}"
      echo ""
      ;;

    --help|-h)
      echo ""
      echo "  ${FLOW_COLORS[header]}yay / win - Celebrate wins!${FLOW_COLORS[reset]}"
      echo ""
      echo "  ${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
      echo "    win [text]       Log a win (auto-detects category)"
      echo "    yay [text]       Alias for win"
      echo "    yay              Show recent wins"
      echo "    yay --week       Weekly wins summary with breakdown"
      echo ""
      echo "  ${FLOW_COLORS[bold]}CATEGORY FLAGS${FLOW_COLORS[reset]}"
      echo "    -c, --code       💻 Code implementation"
      echo "    -d, --docs       📝 Documentation"
      echo "    -r, --review     👀 Code review"
      echo "    -s, --ship       🚀 Deploy/release"
      echo "    -f, --fix        🔧 Bug fix"
      echo "    -t, --test       🧪 Testing"
      echo ""
      echo "  ${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
      echo "    win Fixed memory leak in parser"
      echo "    win -s Deployed v2.0 to production"
      echo "    win --docs Updated API reference"
      echo ""
      echo "  ${FLOW_COLORS[muted]}Categories are auto-detected from keywords${FLOW_COLORS[reset]}"
      echo ""
      ;;

    "")
      # Show recent wins
      echo ""
      echo "  ${FLOW_COLORS[header]}🎉 Recent Wins${FLOW_COLORS[reset]}"
      echo ""

      if _flow_has_atlas; then
        _flow_atlas inbox --type=win --limit=5 2>/dev/null || {
          [[ -f "$wins" ]] && tail -5 "$wins" || echo "  No wins yet. Use 'win' to log your first!"
        }
      else
        [[ -f "$wins" ]] && tail -5 "$wins" || echo "  No wins yet. Use 'win' to log your first!"
      fi
      echo ""
      echo "  ${FLOW_COLORS[muted]}Tip: 'yay --week' for weekly summary${FLOW_COLORS[reset]}"
      echo ""
      ;;

    *)
      # Log a win
      win "$@"
      ;;
  esac
}

# ============================================================================
# FLOW GOAL - Daily task/win goal tracking
# ============================================================================

# Default goal: 3 wins per day (achievable, not overwhelming)
FLOW_DEFAULT_DAILY_GOAL=3

# Get today's date in consistent format
_flow_today() {
  strftime "%Y-%m-%d" $EPOCHSECONDS
}

# Get goal file path
_flow_goal_file() {
  echo "${FLOW_DATA_DIR}/goal.json"
}

# Read current goal (check project .STATUS first, then global, then default)
_flow_read_goal() {
  local goal_file=$(_flow_goal_file)
  local today=$(_flow_today)

  # First: Check project .STATUS for daily_goal (v3.5.0)
  if _flow_in_project; then
    local root=$(_flow_find_project_root)
    local status_file="$root/.STATUS"
    if [[ -f "$status_file" ]]; then
      local project_goal=$(grep -i "^## daily_goal:" "$status_file" 2>/dev/null | head -1 | sed 's/^## [^:]*: *//')
      if [[ -n "$project_goal" ]] && [[ "$project_goal" =~ ^[0-9]+$ ]]; then
        echo "$project_goal"
        return
      fi
    fi
  fi

  # Second: Check global goal.json
  if [[ -f "$goal_file" ]]; then
    local file_date=$(grep -o '"date":"[^"]*"' "$goal_file" 2>/dev/null | cut -d'"' -f4)
    local target=$(grep -o '"target":[0-9]*' "$goal_file" 2>/dev/null | cut -d: -f2)

    # Check if goal is from today
    if [[ "$file_date" == "$today" ]]; then
      echo "${target:-$FLOW_DEFAULT_DAILY_GOAL}"
      return
    fi
  fi

  # Default goal
  echo "$FLOW_DEFAULT_DAILY_GOAL"
}

# Count today's wins
_flow_count_today_wins() {
  local wins_file="${FLOW_DATA_DIR}/wins.md"
  local today=$(_flow_today)
  local count=0

  if [[ -f "$wins_file" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ "\[$today" ]]; then
        ((count++))
      fi
    done < "$wins_file"
  fi

  echo "$count"
}

# Save goal to file
_flow_save_goal() {
  local target="$1"
  local goal_file=$(_flow_goal_file)
  local today=$(_flow_today)

  # Ensure directory exists
  mkdir -p "$(dirname "$goal_file")"

  # Save as simple JSON
  cat > "$goal_file" << EOF
{
  "date": "$today",
  "target": $target,
  "updated": "$(date '+%H:%M')"
}
EOF
}

# Main goal command
flow_goal() {
  local cmd="${1:-}"

  case "$cmd" in
    set)
      # flow goal set <n> [--project]
      local new_goal=""
      local save_to_project=0
      shift  # Remove 'set'

      # Parse arguments
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --project|-p) save_to_project=1; shift ;;
          [0-9]*) new_goal="$1"; shift ;;
          *) shift ;;
        esac
      done

      if [[ -z "$new_goal" ]] || ! [[ "$new_goal" =~ ^[0-9]+$ ]]; then
        if _flow_has_gum; then
          new_goal=$(gum input --placeholder="Daily win goal (e.g., 3)" --width=30)
        else
          read "new_goal?🎯 Daily win goal: "
        fi
      fi

      if [[ -z "$new_goal" ]] || ! [[ "$new_goal" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid goal. Please enter a number."
        return 1
      fi

      # Save to project .STATUS or global
      if [[ $save_to_project -eq 1 ]] && _flow_in_project; then
        local root=$(_flow_find_project_root)
        local status_file="$root/.STATUS"
        if [[ -f "$status_file" ]]; then
          _flow_status_set_field "$status_file" "daily_goal" "$new_goal"
          local proj_name=$(_flow_project_name "$root")
          echo ""
          echo "  🎯 ${FLOW_COLORS[success]}Project goal set: $new_goal wins/day${FLOW_COLORS[reset]} (${FLOW_COLORS[muted]}$proj_name${FLOW_COLORS[reset]})"
          echo ""
        else
          echo "❌ No .STATUS file in project. Create with: status --create"
          return 1
        fi
      else
        _flow_save_goal "$new_goal"
        echo ""
        echo "  🎯 ${FLOW_COLORS[success]}Daily goal set: $new_goal wins${FLOW_COLORS[reset]}"
        echo ""
      fi
      ;;

    reset)
      # Reset to default
      _flow_save_goal "$FLOW_DEFAULT_DAILY_GOAL"
      echo ""
      echo "  🔄 ${FLOW_COLORS[success]}Goal reset to $FLOW_DEFAULT_DAILY_GOAL wins${FLOW_COLORS[reset]}"
      echo ""
      ;;

    --help|-h|help)
      echo ""
      echo "  ${FLOW_COLORS[header]}flow goal - Daily win goal tracking${FLOW_COLORS[reset]}"
      echo ""
      echo "  ${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
      echo "    flow goal                    Show today's progress"
      echo "    flow goal set <n>            Set global daily goal"
      echo "    flow goal set <n> --project  Set project-specific goal (in .STATUS)"
      echo "    flow goal reset              Reset to default ($FLOW_DEFAULT_DAILY_GOAL wins)"
      echo ""
      echo "  ${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
      echo "    -p, --project    Save goal to current project's .STATUS file"
      echo ""
      echo "  ${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
      echo "    flow goal set 5              Set global goal to 5 wins"
      echo "    flow goal set 3 -p           Set project goal to 3 wins"
      echo "    flow goal                    See progress bar"
      echo ""
      echo "  ${FLOW_COLORS[muted]}Project goals override global goals${FLOW_COLORS[reset]}"
      echo "  ${FLOW_COLORS[muted]}Log wins with 'win' command${FLOW_COLORS[reset]}"
      echo ""
      ;;

    ""|status)
      # Show goal status
      local target=$(_flow_read_goal)
      local current=$(_flow_count_today_wins)
      local remaining=$((target - current))
      local percent=0
      (( target > 0 )) && percent=$((current * 100 / target))
      (( percent > 100 )) && percent=100

      echo ""
      echo "  ${FLOW_COLORS[header]}🎯 Daily Goal${FLOW_COLORS[reset]}"
      echo ""

      # Progress bar
      local bar_width=20
      local filled=$((percent * bar_width / 100))
      local empty=$((bar_width - filled))
      local bar=""
      for (( i = 0; i < filled; i++ )); do bar+="█"; done
      for (( i = 0; i < empty; i++ )); do bar+="░"; done

      if (( current >= target )); then
        echo "  ${FLOW_COLORS[success]}[$bar] $current/$target wins - GOAL REACHED! 🎉${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[accent]}Amazing work today! You crushed it!${FLOW_COLORS[reset]}"
      elif (( current > 0 )); then
        echo "  ${FLOW_COLORS[accent]}[$bar] $current/$target wins (${percent}%)${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[muted]}$remaining more to go - you've got this!${FLOW_COLORS[reset]}"
      else
        echo "  ${FLOW_COLORS[muted]}[$bar] 0/$target wins${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[muted]}Log your first win: win \"Completed X\"${FLOW_COLORS[reset]}"
      fi

      echo ""
      echo "  ${FLOW_COLORS[muted]}Change goal: flow goal set <n>${FLOW_COLORS[reset]}"
      echo ""
      ;;

    *)
      echo "Unknown goal command: $cmd"
      echo "Try: flow goal help"
      return 1
      ;;
  esac
}
