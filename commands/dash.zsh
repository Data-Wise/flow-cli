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
  _dash_current
  _dash_quick_access

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
  local date_str=$(date "+%b %d, %Y")
  local time_str=$(date "+%H:%M")
  local streak=0
  local today_sessions=0
  local today_mins=0
  local today_time="--"

  # Get stats from atlas if available
  if _flow_has_atlas; then
    local stats=$(atlas status --format=json 2>/dev/null)
    if [[ -n "$stats" ]]; then
      streak=$(echo "$stats" | grep -o '"streak":[0-9]*' | cut -d: -f2 || echo "0")
      today_sessions=$(echo "$stats" | grep -o '"todaySessions":[0-9]*' | cut -d: -f2 || echo "0")
      today_mins=$(echo "$stats" | grep -o '"todayMinutes":[0-9]*' | cut -d: -f2 || echo "0")
    fi
  else
    # Fallback: Count today's sessions and time from worklog
    local worklog="${FLOW_DATA_DIR}/worklog"
    local today=$(date "+%Y-%m-%d")
    if [[ -f "$worklog" ]]; then
      today_sessions=$(grep -c "^$today.*START" "$worklog" 2>/dev/null || echo "0")
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

  # Header box with time
  echo "╭──────────────────────────────────────────────────────────────╮"
  printf "│  🌊 ${FLOW_COLORS[bold]}FLOW DASHBOARD${FLOW_COLORS[reset]}%$((62 - 18 - ${#date_str} - 8))s%s  🕐 %s │\n" "" "$date_str" "$time_str"
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
      current_project=$(echo "$session" | grep -o '"project":"[^"]*"' | cut -d'"' -f4)
      local mins=$(echo "$session" | grep -o '"elapsed":[0-9]*' | cut -d: -f2)
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
      current_focus=$(grep -m1 "^## Focus:" "$proj_path/.STATUS" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
    fi
  fi

  if [[ -n "$current_project" ]]; then
    local type_icon=$(_flow_project_icon "$(_flow_detect_project_type "$proj_path" 2>/dev/null)")

    echo "  🎯 ${FLOW_COLORS[bold]}ACTIVE NOW${FLOW_COLORS[reset]}"
    echo "  ╭────────────────────────────────────────────────────────────╮"
    printf "  │  %s ${FLOW_COLORS[success]}%-52s${FLOW_COLORS[reset]} │\n" "$type_icon" "$current_project"
    if [[ -n "$current_focus" ]]; then
      # Truncate focus to fit
      local focus_display="${current_focus:0:54}"
      printf "  │  ${FLOW_COLORS[muted]}Focus: %-51s${FLOW_COLORS[reset]} │\n" "$focus_display"
    fi
    if [[ -n "$elapsed" ]]; then
      printf "  │  ${FLOW_COLORS[muted]}⏱  %-55s${FLOW_COLORS[reset]} │\n" "$elapsed elapsed"
    fi
    echo "  ╰────────────────────────────────────────────────────────────╯"
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

    if [[ -n "$proj_path" ]] && [[ -f "$proj_path/.STATUS" ]]; then
      local proj_status=$(_dash_get_project_status "$proj_path/.STATUS")
      status_icon=$(_flow_status_icon "$proj_status")
      focus=$(_dash_get_project_focus "$proj_path/.STATUS")
    fi

    local prefix="├─"
    (( count == max - 1 )) && prefix="└─"

    if [[ -n "$focus" ]]; then
      local focus_short="${focus:0:30}"
      printf "  %s %s ${FLOW_COLORS[info]}%-16s${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" "$prefix" "$status_icon" "$project" "$focus_short"
    else
      printf "  %s %s ${FLOW_COLORS[info]}%-16s${FLOW_COLORS[reset]}\n" "$prefix" "$status_icon" "$project"
    fi

    ((count++))
  done

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

    # Build progress bar (5 chars for compact display)
    local bar=""
    if (( cat_progress_count[$cat] > 0 )); then
      local filled=$((avg_progress / 20))  # 5 segments = 20% each
      local empty=$((5 - filled))
      local bar_filled="" bar_empty=""
      (( filled > 0 )) && bar_filled=$(printf '█%.0s' {1..$filled})
      (( empty > 0 )) && bar_empty=$(printf '░%.0s' {1..$empty})
      bar="${bar_filled}${bar_empty}"
    else
      bar="░░░░░"
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

    # Progress bar
    local bar=""
    if [[ -n "$progress" ]] && [[ "$progress" =~ ^[0-9]+$ ]]; then
      local filled=$((progress / 10))
      local empty=$((10 - filled))
      local bar_filled="" bar_empty=""
      (( filled > 0 )) && bar_filled=$(printf '█%.0s' {1..$filled})
      (( empty > 0 )) && bar_empty=$(printf '░%.0s' {1..$empty})
      bar=" ${bar_filled}${bar_empty} ${progress}%"
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

_dash_footer() {
  local inbox_count=0

  # Get inbox count
  if _flow_has_atlas; then
    inbox_count=$(atlas inbox --count 2>/dev/null || echo "0")
  else
    local inbox="${FLOW_DATA_DIR}/inbox.md"
    [[ -f "$inbox" ]] && inbox_count=$(wc -l < "$inbox" | tr -d ' ')
  fi

  echo "  ─────────────────────────────────────────────────────────────"

  if (( inbox_count > 0 )); then
    echo "  📥 ${FLOW_COLORS[warning]}Inbox: $inbox_count items${FLOW_COLORS[reset]}"
  fi

  echo ""
  echo "  ${FLOW_COLORS[muted]}💡 'dash dev' to expand category │ 'dash -a' for all │ 'flow pick' to switch${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# HELP
# ============================================================================

_dash_help() {
  cat << 'EOF'
╭──────────────────────────────────────────────────────────────╮
│  🌊 DASH - Project Dashboard                                 │
╰──────────────────────────────────────────────────────────────╯

USAGE: dash [option|category]

OPTIONS:
  (none)        Summary view (default)
  -a, --all     Show all projects (flat list)
  -i            Interactive mode with fzf picker
  -f, --full    Interactive TUI (requires atlas)
  -h, --help    Show this help

CATEGORIES:
  dev           Expand dev-tools projects
  r             Expand R packages
  research      Expand research projects
  teach         Expand teaching projects

EXAMPLES:
  dash              # Summary dashboard
  dash dev          # Show all dev-tools projects
  dash -a           # Flat list of all projects
  flow dash r       # R packages via flow command

LEGEND:
  🟢 Active    🟡 Paused    🔴 Blocked
  🟠 Stalled   ⚫ Archived  ⚪ Unknown
EOF
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
_dash_get_status_field() {
  local file="$1"
  local field="$2"
  local value=""

  [[ ! -f "$file" ]] && return 1

  # Try markdown format first (## Field:)
  value=$(grep -m1 "^## ${field}:" "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')

  # Fall back to YAML-like format (field:)
  if [[ -z "$value" ]]; then
    value=$(grep -m1 "^${field}:" "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
  fi

  # Normalize status values
  if [[ "$field" == "Status" || "$field" == "status" ]]; then
    value=$(echo "$value" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
    # Map variations
    case "$value" in
      underreview|"under review") value="active" ;;
      inprogress|"in progress") value="active" ;;
      wip) value="active" ;;
      onhold|"on hold") value="paused" ;;
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

  # Create preview script
  local preview_cmd='
    project=$(echo {} | sed "s/.*[🔧📦🔬🎓📝📱] [🟢🟡🔴🟠⚫⚪] //" | cut -d: -f1 | xargs)
    path=$(find ~/projects -maxdepth 4 -type d -name "$project" 2>/dev/null | head -1)
    if [[ -f "$path/.STATUS" ]]; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      cat "$path/.STATUS" | head -20
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "Path: $path"
    else
      echo "No .STATUS file"
      echo "Path: $path"
    fi
  '

  # Run fzf
  local selected=$(echo "$sorted_lines" | fzf \
    --ansi \
    --header="🌊 FLOW DASHBOARD - Select project (Enter: work, Ctrl-D: dash)" \
    --preview="$preview_cmd" \
    --preview-window=right:50%:wrap \
    --bind="ctrl-d:execute(echo DASH {})+abort" \
    --bind="enter:accept" \
    --height=80% \
    --border=rounded \
    --prompt="🔍 " \
    --pointer="▶" \
    --marker="✓")

  [[ -z "$selected" ]] && return 0

  # Extract project name
  local project_name=$(echo "$selected" | sed 's/.*[🔧📦🔬🎓📝📱] [🟢🟡🔴🟠⚫⚪] //' | cut -d: -f1 | xargs)

  # Check if it was a DASH command (Ctrl-D)
  if [[ "$selected" == "DASH "* ]]; then
    local cat=$(_dash_detect_category "$(_dash_find_project_path "$project_name")")
    dash "$cat"
  else
    # Start work session
    work "$project_name"
  fi
}

# ============================================================================
# ALIASES
# ============================================================================

alias d='dash'
alias di='dash -i'
