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
