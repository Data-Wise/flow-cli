# commands/sync.zsh - Unified sync orchestration for flow-cli v4.0.0
# Cross-tool sync with modular targets and ADHD-friendly feedback

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Load datetime module for timestamps
zmodload -F zsh/datetime b:strftime

# ============================================================================
# SYNC COMMAND - Main dispatcher
# ============================================================================

flow_sync() {
  local target="${1:-}"
  shift 2>/dev/null || true

  local dry_run=0
  local verbose=0
  local quiet=0
  local skip_git=0

  # Parse global options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n)   dry_run=1; shift ;;
      --verbose|-v)   verbose=1; shift ;;
      --quiet|-q)     quiet=1; shift ;;
      --skip-git)     skip_git=1; shift ;;
      --help|-h)      _flow_sync_help; return 0 ;;
      *)              break ;;
    esac
  done

  # Export options for sub-functions
  export _FLOW_SYNC_DRY_RUN=$dry_run
  export _FLOW_SYNC_VERBOSE=$verbose
  export _FLOW_SYNC_QUIET=$quiet
  export _FLOW_SYNC_SKIP_GIT=$skip_git

  case "$target" in
    all)        _flow_sync_all "$@" ;;
    git)        _flow_sync_git "$@" ;;
    status)     _flow_sync_status "$@" ;;
    wins)       _flow_sync_wins "$@" ;;
    goals)      _flow_sync_goals "$@" ;;
    session)    _flow_sync_session "$@" ;;
    remote)     _flow_sync_remote "$@" ;;
    schedule)   _flow_sync_schedule "$@" ;;
    --status)   _flow_sync_dashboard ;;
    help|--help|-h) _flow_sync_help ;;
    "")         _flow_sync_smart ;;
    *)
      _flow_log_error "Unknown sync target: $target"
      echo "Run 'flow sync help' for usage"
      return 1
      ;;
  esac
}

# ============================================================================
# SYNC TARGETS
# ============================================================================

# Session sync - persist current session data
_flow_sync_session() {
  local session_file="${FLOW_DATA_DIR}/.current-session"
  local worklog="${FLOW_DATA_DIR}/worklog"

  if [[ ! -f "$session_file" ]]; then
    (( _FLOW_SYNC_VERBOSE )) && _flow_log_info "No active session"
    return 0
  fi

  # Read current session
  local project="" start="" date=""
  while IFS='=' read -r key value; do
    case "$key" in
      project) project="$value" ;;
      start)   start="$value" ;;
      date)    date="$value" ;;
    esac
  done < "$session_file"

  if [[ -z "$project" || -z "$start" ]]; then
    return 0
  fi

  # Calculate duration
  local now=$EPOCHSECONDS
  local duration=$(( (now - start) / 60 ))

  if (( _FLOW_SYNC_DRY_RUN )); then
    echo "  Would log: ${duration}m on $project"
    return 0
  fi

  # Ensure worklog exists
  [[ ! -f "$worklog" ]] && touch "$worklog"

  # Update worklog with heartbeat
  local timestamp=$(strftime "%Y-%m-%d %H:%M:%S" $now)
  echo "$timestamp HEARTBEAT $project ${duration}m" >> "$worklog"

  echo "${duration}m on $project"
}

# Status sync - update .STATUS timestamps and streaks
_flow_sync_status() {
  local projects_root="${FLOW_PROJECTS_ROOT:-$HOME/projects}"
  local updated=0
  local skipped=0
  local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)

  # Find all .STATUS files
  local -a status_files
  status_files=("${projects_root}"/**/.STATUS(N))

  if (( ${#status_files[@]} == 0 )); then
    (( _FLOW_SYNC_VERBOSE )) && _flow_log_info "No .STATUS files found"
    return 0
  fi

  for status_file in "${status_files[@]}"; do
    local project_dir="${status_file:h}"
    local project_name="${project_dir:t}"

    # Check if recently modified (within last hour)
    local mtime=$(stat -f %m "$status_file" 2>/dev/null || echo 0)
    local age=$(( EPOCHSECONDS - mtime ))

    if (( age < 3600 )); then
      # Recently active - update last_active
      if (( _FLOW_SYNC_DRY_RUN )); then
        echo "  Would update: $project_name"
        ((updated++))
      else
        local timestamp=$(strftime "%Y-%m-%d %H:%M" $EPOCHSECONDS)
        _flow_status_set_field "$status_file" "last_active" "$timestamp"

        # Also update streak if needed
        if typeset -f _flow_status_update_streak >/dev/null 2>&1; then
          _flow_status_update_streak "$project_dir"
        fi
        ((updated++))
      fi
    else
      ((skipped++))
    fi
  done

  if (( _FLOW_SYNC_DRY_RUN )); then
    echo "  Would skip: $skipped (up to date)"
  else
    echo "$updated projects updated"
  fi
}

# Wins sync - aggregate project wins to global wins.md
_flow_sync_wins() {
  local global_wins="${FLOW_DATA_DIR}/wins.md"
  local projects_root="${FLOW_PROJECTS_ROOT:-$HOME/projects}"
  local new_wins=0
  local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)

  # Ensure global wins file exists
  if [[ ! -f "$global_wins" ]]; then
    mkdir -p "${global_wins:h}"
    echo "# Wins Log" > "$global_wins"
    echo "# Format: - ICON text (@project) #category [YYYY-MM-DD HH:MM]" >> "$global_wins"
    echo "" >> "$global_wins"
  fi

  # Read existing wins to detect duplicates
  local -A existing_wins
  while IFS= read -r line; do
    [[ "$line" == "- "* ]] && existing_wins["$line"]=1
  done < "$global_wins"

  # Scan .STATUS files for wins
  local -a status_files
  status_files=("${projects_root}"/**/.STATUS(N))

  for status_file in "${status_files[@]}"; do
    local project_name="${${status_file:h}:t}"
    local wins_field=$(_flow_status_get_field "$status_file" "wins" 2>/dev/null)

    [[ -z "$wins_field" ]] && continue

    # Parse comma-separated wins
    local -a wins_arr
    wins_arr=("${(@s:, :)wins_field}")

    for win in "${wins_arr[@]}"; do
      # Extract date from win format: "text (YYYY-MM-DD)"
      if [[ "$win" =~ '\(([0-9]{4}-[0-9]{2}-[0-9]{2})\)' ]]; then
        local win_date="${match[1]}"
        local win_text="${win% \(*}"

        # Only sync recent wins (today or yesterday)
        if [[ "$win_date" == "$today" || "$win_date" == "$(strftime "%Y-%m-%d" $((EPOCHSECONDS - 86400)))" ]]; then
          # Create formatted win entry
          local formatted="- ✨ ${win_text} (@${project_name}) #other [${win_date}]"

          # Check if already exists
          if [[ -z "${existing_wins[$formatted]}" ]]; then
            if (( _FLOW_SYNC_DRY_RUN )); then
              echo "  Would add: $win_text"
            else
              echo "$formatted" >> "$global_wins"
            fi
            ((new_wins++))
          fi
        fi
      fi
    done
  done

  if (( new_wins > 0 )); then
    echo "$new_wins new wins aggregated"
  else
    echo "all wins synced"
  fi
}

# Goals sync - recalculate goal progress
_flow_sync_goals() {
  local goal_file="${FLOW_DATA_DIR}/goal.json"
  local wins_file="${FLOW_DATA_DIR}/wins.md"
  local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)

  # Count today's wins
  local today_wins=0
  if [[ -f "$wins_file" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ "\[$today" ]] && ((today_wins++))
    done < "$wins_file"
  fi

  # Read target goal
  local target=3  # Default
  if [[ -f "$goal_file" ]]; then
    local file_target=$(grep -o '"target":[0-9]*' "$goal_file" 2>/dev/null | cut -d: -f2)
    [[ -n "$file_target" ]] && target=$file_target
  fi

  # Calculate percentage
  local percent=0
  (( target > 0 )) && percent=$((today_wins * 100 / target))
  (( percent > 100 )) && percent=100

  if (( _FLOW_SYNC_DRY_RUN )); then
    echo "  Current: $today_wins/$target (${percent}%)"
  else
    # Update goal file with current progress
    mkdir -p "${goal_file:h}"
    cat > "$goal_file" << EOF
{
  "date": "$today",
  "target": $target,
  "current": $today_wins,
  "updated": "$(strftime "%H:%M" $EPOCHSECONDS)"
}
EOF
    echo "$today_wins/$target (${percent}%)"
  fi
}

# Git sync - smart git push/pull
_flow_sync_git() {
  # Check if in a git repo
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    (( _FLOW_SYNC_VERBOSE )) && _flow_log_info "Not in a git repository"
    return 0
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  local remote=$(git config --get "branch.${branch}.remote" 2>/dev/null || echo "origin")

  # Check for uncommitted changes
  local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  local stashed=0

  if (( _FLOW_SYNC_DRY_RUN )); then
    echo "  Branch: $branch"
    (( changes > 0 )) && echo "  Would stash: $changes changes"
    echo "  Would: fetch, rebase, push"
    return 0
  fi

  # Stash changes if any
  if (( changes > 0 )); then
    git stash push -m "flow-sync-$(strftime "%Y%m%d-%H%M%S" $EPOCHSECONDS)" >/dev/null 2>&1
    stashed=1
  fi

  # Fetch from remote
  if ! git fetch "$remote" "$branch" >/dev/null 2>&1; then
    _flow_log_warning "Failed to fetch from $remote"
    (( stashed )) && git stash pop >/dev/null 2>&1
    return 1
  fi

  # Check if we're behind
  local behind=$(git rev-list --count HEAD.."${remote}/${branch}" 2>/dev/null || echo 0)
  local ahead=$(git rev-list --count "${remote}/${branch}"..HEAD 2>/dev/null || echo 0)

  # Rebase if behind
  if (( behind > 0 )); then
    if ! git rebase "${remote}/${branch}" >/dev/null 2>&1; then
      _flow_log_error "Rebase conflict - run 'git rebase --abort' to recover"
      git rebase --abort >/dev/null 2>&1
      (( stashed )) && git stash pop >/dev/null 2>&1
      return 1
    fi
  fi

  # Push if ahead
  if (( ahead > 0 )); then
    if ! git push "$remote" "$branch" >/dev/null 2>&1; then
      _flow_log_warning "Failed to push to $remote"
      (( stashed )) && git stash pop >/dev/null 2>&1
      return 1
    fi
    echo "pushed $ahead commits"
  else
    echo "up to date"
  fi

  # Pop stash
  (( stashed )) && git stash pop >/dev/null 2>&1

  return 0
}

# ============================================================================
# ORCHESTRATOR
# ============================================================================

_flow_sync_all() {
  local start_time=$EPOCHSECONDS
  local project_name=""

  # Detect project name if in a project
  if _flow_in_project 2>/dev/null; then
    project_name=$(_flow_project_name "$(_flow_find_project_root)" 2>/dev/null)
  fi

  # Header
  if (( ! _FLOW_SYNC_QUIET )); then
    echo ""
    if [[ -n "$project_name" ]]; then
      echo "  ${FLOW_COLORS[header]}🔄 Syncing ${project_name}${FLOW_COLORS[reset]}"
    else
      echo "  ${FLOW_COLORS[header]}🔄 Syncing all${FLOW_COLORS[reset]}"
    fi
    echo "  ${FLOW_COLORS[muted]}━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  fi

  if (( _FLOW_SYNC_DRY_RUN )); then
    echo ""
    echo "  ${FLOW_COLORS[warning]}🔍 Dry run - no changes will be made${FLOW_COLORS[reset]}"
    echo ""
  fi

  # Define sync order (dependencies respected)
  local -a targets=("session" "status" "wins" "goals")
  (( ! _FLOW_SYNC_SKIP_GIT )) && targets+=("git")

  local total=${#targets[@]}
  local current=0
  local -A results

  local output=""
  local exit_code=0

  for target in "${targets[@]}"; do
    ((current++))

    if (( ! _FLOW_SYNC_QUIET )); then
      echo -n "  [${current}/${total}] ${FLOW_COLORS[accent]}${target}${FLOW_COLORS[reset]}... "
    fi

    # Run sync target and capture output
    output=$(_flow_sync_${target} 2>&1)
    exit_code=$?

    # Get last line of output for summary
    local summary="${output##*$'\n'}"
    [[ -z "$summary" ]] && summary="$output"

    if (( exit_code == 0 )); then
      results[$target]="success"
      if (( ! _FLOW_SYNC_QUIET )); then
        echo "${FLOW_COLORS[success]}done${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}($summary)${FLOW_COLORS[reset]}"
      fi
    else
      results[$target]="failed"
      if (( ! _FLOW_SYNC_QUIET )); then
        echo "${FLOW_COLORS[error]}failed${FLOW_COLORS[reset]}"
      fi
    fi
  done

  # Summary
  local duration=$((EPOCHSECONDS - start_time))

  if (( ! _FLOW_SYNC_QUIET )); then
    echo ""
    if (( _FLOW_SYNC_DRY_RUN )); then
      echo "  ${FLOW_COLORS[muted]}Run without --dry-run to execute${FLOW_COLORS[reset]}"
    else
      echo "  ${FLOW_COLORS[success]}✓ Sync complete${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(${duration}s)${FLOW_COLORS[reset]}"
    fi
    echo ""
  fi

  # Save sync state
  if (( ! _FLOW_SYNC_DRY_RUN )); then
    _flow_sync_state_write \
      "${results[session]:-unknown}" \
      "${results[status]:-unknown}" \
      "${results[wins]:-unknown}" \
      "${results[goals]:-unknown}" \
      "${results[git]:-skipped}"
  fi
}

# ============================================================================
# SMART SYNC & DASHBOARD
# ============================================================================

_flow_sync_smart() {
  local -a suggestions=()

  echo ""
  echo "  ${FLOW_COLORS[header]}🔄 Sync Status${FLOW_COLORS[reset]}"
  echo ""

  # Check git status
  if git rev-parse --git-dir >/dev/null 2>&1; then
    local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)

    if (( changes > 0 )); then
      suggestions+=("git: $changes uncommitted changes")
    elif (( ahead > 0 )); then
      suggestions+=("git: $ahead commits to push")
    fi
  fi

  # Check stale .STATUS files
  local stale=0
  local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)
  local projects_root="${FLOW_PROJECTS_ROOT:-$HOME/projects}"

  for status_file in "${projects_root}"/**/.STATUS(N); do
    local last_active=$(_flow_status_get_field "$status_file" "last_active" 2>/dev/null)
    if [[ -n "$last_active" && "${last_active%% *}" != "$today" ]]; then
      ((stale++))
    fi
  done

  (( stale > 0 )) && suggestions+=("status: $stale projects not updated today")

  # Check wins
  local wins_file="${FLOW_DATA_DIR}/wins.md"
  local today_wins=0
  if [[ -f "$wins_file" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ "\[$today" ]] && ((today_wins++))
    done < "$wins_file"
  fi

  # Read goal
  local goal_file="${FLOW_DATA_DIR}/goal.json"
  local target=3
  if [[ -f "$goal_file" ]]; then
    local file_target=$(grep -o '"target":[0-9]*' "$goal_file" 2>/dev/null | cut -d: -f2)
    [[ -n "$file_target" ]] && target=$file_target
  fi

  echo "  ${FLOW_COLORS[accent]}Today's progress:${FLOW_COLORS[reset]} $today_wins/$target wins"
  echo ""

  if (( ${#suggestions[@]} > 0 )); then
    echo "  ${FLOW_COLORS[warning]}Suggested sync targets:${FLOW_COLORS[reset]}"
    for s in "${suggestions[@]}"; do
      echo "  • $s"
    done
    echo ""
    echo "  Run: ${FLOW_COLORS[accent]}flow sync all${FLOW_COLORS[reset]}"
  else
    echo "  ${FLOW_COLORS[success]}✓ Everything is in sync!${FLOW_COLORS[reset]}"
  fi
  echo ""
}

_flow_sync_dashboard() {
  local state_file="${FLOW_DATA_DIR}/sync-state.json"

  echo ""
  echo "  ${FLOW_COLORS[header]}📊 Sync Dashboard${FLOW_COLORS[reset]}"
  echo ""

  if [[ -f "$state_file" ]]; then
    local last_sync=$(grep -o '"all":"[^"]*"' "$state_file" 2>/dev/null | cut -d'"' -f4)
    if [[ -n "$last_sync" ]]; then
      echo "  Last full sync: ${FLOW_COLORS[accent]}$last_sync${FLOW_COLORS[reset]}"
    fi
  else
    echo "  ${FLOW_COLORS[muted]}No sync history yet${FLOW_COLORS[reset]}"
  fi

  echo ""
  echo "  ${FLOW_COLORS[muted]}Run 'flow sync all' to sync everything${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

_flow_sync_state_write() {
  local session_result="${1:-unknown}"
  local status_result="${2:-unknown}"
  local wins_result="${3:-unknown}"
  local goals_result="${4:-unknown}"
  local git_result="${5:-skipped}"

  local state_file="${FLOW_DATA_DIR}/sync-state.json"
  local timestamp=$(strftime "%Y-%m-%dT%H:%M:%SZ" $EPOCHSECONDS)

  mkdir -p "${state_file:h}"

  cat > "$state_file" << EOF
{
  "last_sync": {
    "all": "$timestamp"
  },
  "results": {
    "session": "$session_result",
    "status": "$status_result",
    "wins": "$wins_result",
    "goals": "$goals_result",
    "git": "$git_result"
  }
}
EOF
}

# ============================================================================
# SCHEDULE - Automated sync
# ============================================================================

_flow_sync_schedule() {
  local action="${1:-status}"
  local plist_name="com.flow-cli.sync"
  local plist_path="$HOME/Library/LaunchAgents/${plist_name}.plist"
  local flow_bin="${FLOW_PLUGIN_DIR:-$HOME/.local/share/flow-cli}/flow.plugin.zsh"
  local log_file="${FLOW_DATA_DIR}/sync-schedule.log"

  case "$action" in
    status|show)
      _flow_sync_schedule_status "$plist_path" "$plist_name"
      ;;
    enable|start)
      local interval="${2:-30}"  # Default 30 minutes
      _flow_sync_schedule_enable "$plist_path" "$plist_name" "$interval" "$flow_bin" "$log_file"
      ;;
    disable|stop)
      _flow_sync_schedule_disable "$plist_path" "$plist_name"
      ;;
    logs)
      _flow_sync_schedule_logs "$log_file"
      ;;
    help|--help|-h)
      _flow_sync_schedule_help
      ;;
    *)
      _flow_log_error "Unknown schedule action: $action"
      echo "Run 'flow sync schedule help' for usage"
      return 1
      ;;
  esac
}

_flow_sync_schedule_status() {
  local plist_path="$1"
  local plist_name="$2"

  echo ""
  echo "  ${FLOW_COLORS[header]}⏰ Sync Schedule Status${FLOW_COLORS[reset]}"
  echo ""

  if [[ -f "$plist_path" ]]; then
    # Check if loaded
    if launchctl list 2>/dev/null | grep -q "$plist_name"; then
      echo "  Status: ${FLOW_COLORS[success]}Active${FLOW_COLORS[reset]}"

      # Parse interval from plist
      local interval=$(grep -A1 'StartInterval' "$plist_path" 2>/dev/null | tail -1 | sed 's/[^0-9]//g')
      if [[ -n "$interval" ]]; then
        local minutes=$((interval / 60))
        echo "  Interval: ${FLOW_COLORS[accent]}Every ${minutes} minutes${FLOW_COLORS[reset]}"
      fi

      # Last run from log
      local log_file="${FLOW_DATA_DIR}/sync-schedule.log"
      if [[ -f "$log_file" ]]; then
        local last_run=$(tail -1 "$log_file" 2>/dev/null | cut -d' ' -f1-2)
        [[ -n "$last_run" ]] && echo "  Last run: ${FLOW_COLORS[muted]}$last_run${FLOW_COLORS[reset]}"
      fi
    else
      echo "  Status: ${FLOW_COLORS[warning]}Disabled${FLOW_COLORS[reset]} (plist exists but not loaded)"
      echo ""
      echo "  ${FLOW_COLORS[muted]}Run 'flow sync schedule enable' to start${FLOW_COLORS[reset]}"
    fi
  else
    echo "  Status: ${FLOW_COLORS[muted]}Not configured${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[muted]}Run 'flow sync schedule enable [minutes]' to start${FLOW_COLORS[reset]}"
  fi
  echo ""
}

_flow_sync_schedule_enable() {
  local plist_path="$1"
  local plist_name="$2"
  local interval_min="$3"
  local flow_bin="$4"
  local log_file="$5"

  local interval_sec=$((interval_min * 60))

  echo ""
  echo "  ${FLOW_COLORS[header]}⏰ Enabling Sync Schedule${FLOW_COLORS[reset]}"
  echo ""

  # Ensure directories exist
  mkdir -p "$(dirname "$plist_path")"
  mkdir -p "$(dirname "$log_file")"

  # Create wrapper script
  local wrapper_script="${FLOW_DATA_DIR}/sync-scheduled.sh"
  cat > "$wrapper_script" << 'WRAPPER'
#!/bin/zsh
# Flow CLI scheduled sync wrapper
source ~/.zshrc 2>/dev/null
FLOW_SYNC_QUIET=1 flow sync all --skip-git >> "${FLOW_DATA_DIR}/sync-schedule.log" 2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S') Sync completed" >> "${FLOW_DATA_DIR}/sync-schedule.log"
WRAPPER
  chmod +x "$wrapper_script"

  # Unload existing if present
  if launchctl list 2>/dev/null | grep -q "$plist_name"; then
    launchctl unload "$plist_path" 2>/dev/null
  fi

  # Create plist
  cat > "$plist_path" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plist_name}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>${wrapper_script}</string>
    </array>
    <key>StartInterval</key>
    <integer>${interval_sec}</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${log_file}</string>
    <key>StandardErrorPath</key>
    <string>${log_file}</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>FLOW_DATA_DIR</key>
        <string>${FLOW_DATA_DIR}</string>
        <key>FLOW_PROJECTS_ROOT</key>
        <string>${FLOW_PROJECTS_ROOT:-$HOME/projects}</string>
    </dict>
</dict>
</plist>
PLIST

  # Load the plist
  if launchctl load "$plist_path" 2>/dev/null; then
    echo "  ${FLOW_COLORS[success]}✓ Schedule enabled${FLOW_COLORS[reset]}"
    echo "  Interval: ${FLOW_COLORS[accent]}Every ${interval_min} minutes${FLOW_COLORS[reset]}"
    echo "  Targets: session, status, wins, goals (git skipped)"
    echo ""
    echo "  ${FLOW_COLORS[muted]}View logs: flow sync schedule logs${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[muted]}Disable: flow sync schedule disable${FLOW_COLORS[reset]}"
  else
    _flow_log_error "Failed to load schedule"
    return 1
  fi
  echo ""
}

_flow_sync_schedule_disable() {
  local plist_path="$1"
  local plist_name="$2"

  echo ""
  echo "  ${FLOW_COLORS[header]}⏰ Disabling Sync Schedule${FLOW_COLORS[reset]}"
  echo ""

  if launchctl list 2>/dev/null | grep -q "$plist_name"; then
    if launchctl unload "$plist_path" 2>/dev/null; then
      echo "  ${FLOW_COLORS[success]}✓ Schedule disabled${FLOW_COLORS[reset]}"
    else
      _flow_log_error "Failed to unload schedule"
      return 1
    fi
  else
    echo "  ${FLOW_COLORS[muted]}Schedule was not active${FLOW_COLORS[reset]}"
  fi

  # Optionally remove the plist
  if [[ -f "$plist_path" ]]; then
    rm -f "$plist_path"
    echo "  ${FLOW_COLORS[muted]}Plist removed${FLOW_COLORS[reset]}"
  fi
  echo ""
}

_flow_sync_schedule_logs() {
  local log_file="$1"

  echo ""
  echo "  ${FLOW_COLORS[header]}📋 Sync Schedule Logs${FLOW_COLORS[reset]}"
  echo ""

  if [[ -f "$log_file" ]]; then
    echo "  ${FLOW_COLORS[muted]}Last 20 entries:${FLOW_COLORS[reset]}"
    echo ""
    tail -20 "$log_file" | while IFS= read -r line; do
      echo "  $line"
    done
  else
    echo "  ${FLOW_COLORS[muted]}No logs yet${FLOW_COLORS[reset]}"
  fi
  echo ""
}

_flow_sync_schedule_help() {
  echo ""
  echo "  ${FLOW_COLORS[header]}⏰ FLOW SYNC SCHEDULE - Automated Sync${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "    flow sync schedule                 Show schedule status"
  echo "    flow sync schedule enable [min]    Enable (default: 30 min)"
  echo "    flow sync schedule disable         Disable scheduled sync"
  echo "    flow sync schedule logs            View recent sync logs"
  echo ""
  echo "  ${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "    flow sync schedule enable          # Every 30 minutes"
  echo "    flow sync schedule enable 15       # Every 15 minutes"
  echo "    flow sync schedule enable 60       # Every hour"
  echo "    flow sync schedule disable         # Stop scheduled sync"
  echo ""
  echo "  ${FLOW_COLORS[bold]}WHAT RUNS${FLOW_COLORS[reset]}"
  echo "    Scheduled sync runs: session, status, wins, goals"
  echo "    Git sync is skipped (requires user interaction)"
  echo ""
  echo "  ${FLOW_COLORS[muted]}Uses macOS launchd for reliable background execution${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# REMOTE SYNC - iCloud Integration
# ============================================================================

# Remote sync dispatcher
_flow_sync_remote() {
    local action="${1:-status}"
    case "$action" in
        init)           _flow_sync_remote_init ;;
        disable)        _flow_sync_remote_disable ;;
        help|--help|-h) _flow_sync_remote_help ;;
        status|*)       _flow_sync_remote_status ;;
    esac
}

# Get iCloud path (returns empty if not available)
_flow_sync_remote_icloud_path() {
    local icloud_base="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    [[ -d "$icloud_base" ]] || return 1
    echo "$icloud_base/flow-cli"
}

# Show remote sync status
_flow_sync_remote_status() {
    local icloud_path
    icloud_path=$(_flow_sync_remote_icloud_path)

    echo ""
    echo "  ${FLOW_COLORS[header]}☁️  Remote Sync Status${FLOW_COLORS[reset]}"
    echo ""

    if [[ -z "$icloud_path" ]]; then
        echo "  iCloud: ${FLOW_COLORS[error]}Not available${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[muted]}iCloud Drive not detected on this system${FLOW_COLORS[reset]}"
        echo ""
        return 1
    fi

    # Check if currently syncing to iCloud
    if [[ "$FLOW_DATA_DIR" == "$icloud_path" ]]; then
        echo "  Status: ${FLOW_COLORS[success]}Syncing to iCloud${FLOW_COLORS[reset]}"
        echo "  Path: $icloud_path"
        echo ""

        # Show synced files with sizes
        echo "  ${FLOW_COLORS[accent]}Synced files:${FLOW_COLORS[reset]}"
        for f in wins.md goal.json sync-state.json; do
            if [[ -f "$icloud_path/$f" ]]; then
                local size=$(wc -c < "$icloud_path/$f" 2>/dev/null | tr -d ' ')
                echo "    ✓ $f (${size}B)"
            fi
        done
    elif [[ -d "$icloud_path" ]]; then
        echo "  Status: ${FLOW_COLORS[warning]}Configured but not active${FLOW_COLORS[reset]}"
        echo "  Path: $icloud_path"
        echo ""
        echo "  ${FLOW_COLORS[muted]}Set FLOW_DATA_DIR to activate:${FLOW_COLORS[reset]}"
        echo "    export FLOW_DATA_DIR=\"$icloud_path\""
    else
        echo "  Status: ${FLOW_COLORS[muted]}Local only${FLOW_COLORS[reset]}"
        echo "  iCloud: ${FLOW_COLORS[success]}Available${FLOW_COLORS[reset]}"
        echo ""
        echo "  Run: ${FLOW_COLORS[accent]}flow sync remote init${FLOW_COLORS[reset]} to enable"
    fi
    echo ""
}

# Initialize iCloud sync
_flow_sync_remote_init() {
    local icloud_path
    icloud_path=$(_flow_sync_remote_icloud_path)

    if [[ -z "$icloud_path" ]]; then
        _flow_log_error "iCloud Drive not available on this system"
        return 1
    fi

    echo ""
    echo "  ${FLOW_COLORS[header]}☁️  Setting up iCloud Sync${FLOW_COLORS[reset]}"
    echo ""

    # Create iCloud directory
    if [[ ! -d "$icloud_path" ]]; then
        mkdir -p "$icloud_path"
        echo "  Created: $icloud_path"
    fi

    # Migrate existing files (core only)
    local local_dir="${FLOW_DATA_DIR:-$HOME/.local/share/flow}"
    local migrated=0

    for f in wins.md goal.json sync-state.json; do
        if [[ -f "$local_dir/$f" && ! -f "$icloud_path/$f" ]]; then
            cp "$local_dir/$f" "$icloud_path/"
            echo "  Migrated: $f"
            ((migrated++))
        elif [[ -f "$icloud_path/$f" ]]; then
            echo "  Exists: $f (skipped)"
        fi
    done

    # Create config file
    local config_dir="$HOME/.config/flow"
    local config_file="$config_dir/remote.conf"
    mkdir -p "$config_dir"
    echo "export FLOW_DATA_DIR=\"$icloud_path\"" > "$config_file"

    echo ""
    echo "  ${FLOW_COLORS[success]}✓ iCloud sync configured${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[bold]}To activate, add to ~/.zshrc:${FLOW_COLORS[reset]}"
    echo ""
    echo "    ${FLOW_COLORS[accent]}source ~/.config/flow/remote.conf${FLOW_COLORS[reset]}"
    echo ""
    echo "  Then restart your shell or run: source ~/.zshrc"
    echo ""
}

# Disable iCloud sync
_flow_sync_remote_disable() {
    local config_file="$HOME/.config/flow/remote.conf"

    echo ""
    echo "  ${FLOW_COLORS[header]}☁️  Disabling iCloud Sync${FLOW_COLORS[reset]}"
    echo ""

    if [[ -f "$config_file" ]]; then
        rm "$config_file"
        echo "  ${FLOW_COLORS[success]}✓ Config file removed${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[muted]}Also remove from ~/.zshrc:${FLOW_COLORS[reset]}"
        echo "    source ~/.config/flow/remote.conf"
        echo ""
        echo "  ${FLOW_COLORS[muted]}Your data remains in iCloud at:${FLOW_COLORS[reset]}"
        echo "    ~/Library/Mobile Documents/com~apple~CloudDocs/flow-cli/"
    else
        echo "  ${FLOW_COLORS[muted]}Remote sync not configured${FLOW_COLORS[reset]}"
    fi
    echo ""
}

# Remote sync help
_flow_sync_remote_help() {
    echo ""
    echo "  ${FLOW_COLORS[header]}☁️  FLOW SYNC REMOTE - iCloud Sync${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
    echo "    flow sync remote            Show sync status"
    echo "    flow sync remote init       Set up iCloud sync"
    echo "    flow sync remote disable    Revert to local storage"
    echo ""
    echo "  ${FLOW_COLORS[bold]}SYNCED DATA${FLOW_COLORS[reset]}"
    echo "    wins.md         Daily accomplishments"
    echo "    goal.json       Daily goal progress"
    echo "    sync-state.json Last sync metadata"
    echo ""
    echo "  ${FLOW_COLORS[bold]}HOW IT WORKS${FLOW_COLORS[reset]}"
    echo "    1. Run 'flow sync remote init' to migrate data"
    echo "    2. Add 'source ~/.config/flow/remote.conf' to ~/.zshrc"
    echo "    3. Apple handles sync automatically"
    echo ""
    echo "  ${FLOW_COLORS[bold]}MULTI-DEVICE${FLOW_COLORS[reset]}"
    echo "    Same iCloud account = automatic sync"
    echo "    Works offline (syncs when connected)"
    echo "    No conflicts with local-only data"
    echo ""
}

# ============================================================================
# HELP
# ============================================================================

_flow_sync_help() {
  echo ""
  echo "  ${FLOW_COLORS[header]}🔄 FLOW SYNC - Unified Sync Command${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "    flow sync              Smart sync (auto-detect what needs syncing)"
  echo "    flow sync all          Sync everything"
  echo "    flow sync <target>     Sync specific target"
  echo ""
  echo "  ${FLOW_COLORS[bold]}TARGETS${FLOW_COLORS[reset]}"
  echo "    session    Persist current session data to worklog"
  echo "    status     Update .STATUS timestamps and streaks"
  echo "    wins       Aggregate project wins to global wins.md"
  echo "    goals      Recalculate daily goal progress"
  echo "    git        Smart git push/pull with stash handling"
  echo "    remote     iCloud sync for multi-device access"
  echo "    schedule   Manage automated background sync"
  echo ""
  echo "  ${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "    --dry-run, -n    Preview changes without executing"
  echo "    --verbose, -v    Show detailed output"
  echo "    --quiet, -q      Minimal output (for scripts)"
  echo "    --skip-git       Skip git sync (for quick local sync)"
  echo "    --status         Show sync dashboard"
  echo ""
  echo "  ${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "    flow sync                   # See what needs syncing"
  echo "    flow sync all               # Sync everything"
  echo "    flow sync all --dry-run     # Preview sync"
  echo "    flow sync status            # Update .STATUS files only"
  echo "    flow sync all --skip-git    # Quick local sync"
  echo ""
  echo "  ${FLOW_COLORS[muted]}Sync order: session → status → wins → goals → git${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# ALIAS
# ============================================================================

# Short alias for sync
sync() { flow_sync "$@" }
