# commands/work.zsh - Primary workflow command
# Start working on a project with full context setup

# ============================================================================
# WORK COMMAND
# ============================================================================

# Show first-run welcome message
_flow_first_run_welcome() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/flow-cli"
  local welcomed_marker="$config_dir/.welcomed"

  # Only show once
  [[ -f "$welcomed_marker" ]] && return 0

  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}👋 Welcome to flow-cli!${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}Quick Start:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}work <project>${FLOW_COLORS[reset]}  Start working on a project"
  echo "  ${FLOW_COLORS[cmd]}dash${FLOW_COLORS[reset]}            Project dashboard"
  echo "  ${FLOW_COLORS[cmd]}pick${FLOW_COLORS[reset]}            Pick project with fzf"
  echo "  ${FLOW_COLORS[cmd]}win \"text\"${FLOW_COLORS[reset]}      Log an accomplishment"
  echo "  ${FLOW_COLORS[cmd]}finish${FLOW_COLORS[reset]}          End session"
  echo ""
  echo "${FLOW_COLORS[bold]}Get Help:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow help${FLOW_COLORS[reset]}       Show all commands"
  echo "  ${FLOW_COLORS[cmd]}<cmd> help${FLOW_COLORS[reset]}      Command-specific help (e.g., ${FLOW_COLORS[cmd]}g help${FLOW_COLORS[reset]})"
  echo ""
  echo "${FLOW_COLORS[muted]}Tip: Run ${FLOW_COLORS[cmd]}flow doctor${FLOW_COLORS[reset]}${FLOW_COLORS[muted]} to check your installation${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""

  # Create marker file
  mkdir -p "$config_dir"
  touch "$welcomed_marker"
}

work() {
  # Handle help flags
  case "$1" in
    -h|--help|help)
      _work_help
      return 0
      ;;
  esac

  # Show welcome message on first run
  _flow_first_run_welcome

  local project="$1"
  local editor="${2:-${EDITOR:-nvim}}"

  # Check for existing session (avoid conflicts)
  if _flow_has_atlas; then
    local current_session=$(atlas session status --format=json 2>/dev/null | grep -o '"project":"[^"]*"' | cut -d'"' -f4)
    if [[ -n "$current_session" && "$current_session" != "$project" && -n "$project" ]]; then
      _flow_log_warning "Active session: $current_session"
      if ! _flow_confirm "End current session and switch to $project?"; then
        return 1
      fi
      _flow_session_end "Switched to $project"
    fi
  fi
  
  # If no project specified, use picker or current directory
  if [[ -z "$project" ]]; then
    if _flow_has_fzf; then
      project=$(_flow_pick_project)
      [[ -z "$project" ]] && return 1
    else
      # Try to use current directory
      local root=$(_flow_find_project_root)
      if [[ -n "$root" ]]; then
        project=$(_flow_project_name "$root")
      else
        _flow_log_error "No project specified and not in a project directory"
        echo "Usage: work <project> [editor]"
        return 1
      fi
    fi
  fi
  
  # Get project info
  local project_info=$(_flow_get_project "$project")
  
  if [[ -z "$project_info" ]]; then
    _flow_log_error "Project not found: $project"
    return 1
  fi
  
  # Parse project info (uses project_path to avoid ZSH's path/PATH conflict)
  eval "$project_info"

  # Change to project directory
  if [[ -d "$project_path" ]]; then
    cd "$project_path" || return 1
  else
    _flow_log_error "Project path not found: $project_path"
    return 1
  fi

  # Start session in atlas (non-blocking)
  _flow_session_start "$project"

  # Check if teaching project and handle specially
  local project_type=$(_flow_detect_project_type "$project_path")
  if [[ "$project_type" == "teaching" && -f "$project_path/.flow/teach-config.yml" ]]; then
    _work_teaching_session "$project_path"
  else
    # Show context
    _flow_show_work_context "$project" "$project_path"
  fi

  # Open editor
  _flow_open_editor "$editor" "$project_path"
}

# Help function for work command
_work_help() {
  echo "${FLOW_COLORS[bold]}work${FLOW_COLORS[reset]} - Start working on a project"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  work [project] [editor]"
  echo ""
  echo "${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}"
  echo "  project    Project name or partial match (uses picker if omitted)"
  echo "  editor     Editor to open (default: \$EDITOR or nvim)"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -h, --help    Show this help message"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  work                    # Pick project with fzf"
  echo "  work flow               # Start working on flow-cli"
  echo "  work stat-545           # Start working on STAT 545 course"
  echo "  work flow nvim          # Open in neovim"
  echo ""
  echo "${FLOW_COLORS[bold]}RELATED COMMANDS${FLOW_COLORS[reset]}"
  echo "  finish      End current session"
  echo "  hop         Quick switch projects (tmux)"
  echo "  pick        Interactive project picker"
  echo "  dash        Project dashboard"
}

# Show work context when starting
_flow_show_work_context() {
  local project="$1"
  local path="$2"
  
  local type=$(_flow_detect_project_type "$path")
  local icon=$(_flow_project_icon "$type")
  
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "$icon ${FLOW_COLORS[bold]}$project${FLOW_COLORS[reset]} ($type)"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  
  # Show status file info (simplified - pure ZSH)
  if [[ -f "$path/.STATUS" ]]; then
    local -i count=0
    local line
    while IFS= read -r line && (( count++ < 10 )); do
      case "$line" in
        "## Status:"*) echo "🟢 Status:${line#*:}" ;;
        "## Phase:"*)  echo "📍 Phase:${line#*:}" ;;
        "## Focus:"*)  echo "🎯 Focus:${line#*:}" ;;
      esac
    done < "$path/.STATUS"
  fi
  
  echo ""
}

# Open editor with project
_flow_open_editor() {
  local editor="$1"
  local path="$2"
  local editor_cmd="${editor%% *}"  # Get first word if editor has args

  # Check if editor exists
  if [[ -z "$editor" ]]; then
    _flow_log_warning "No editor configured. Set EDITOR or pass editor as argument."
    return 1
  fi

  # Handle common editors
  case "$editor_cmd" in
    code|vscode)
      if command -v code &>/dev/null; then
        { command code "$path" &>/dev/null & } 2>/dev/null
        disown 2>/dev/null
      else
        _flow_log_warning "VS Code not found in PATH"
      fi
      ;;
    cursor)
      if command -v cursor &>/dev/null; then
        { command cursor "$path" &>/dev/null & } 2>/dev/null
        disown 2>/dev/null
      else
        _flow_log_warning "Cursor not found in PATH"
      fi
      ;;
    vim|nvim)
      if command -v "$editor_cmd" &>/dev/null; then
        command $editor "$path"
      else
        _flow_log_warning "$editor_cmd not found in PATH"
      fi
      ;;
    emacs|spacemacs|emacsclient)
      if command -v emacsclient &>/dev/null; then
        command emacsclient -n "$path" 2>/dev/null
      elif command -v emacs &>/dev/null; then
        { command emacs "$path" & } 2>/dev/null
        disown 2>/dev/null
      fi
      # Silently skip if not available (user likely has GUI emacs)
      ;;
    positron)
      # Positron uses AppleScript on macOS
      if [[ "$OSTYPE" == darwin* ]]; then
        osascript -e "tell application \"Positron\" to activate" \
                  -e "tell application \"Positron\" to open POSIX file \"$path\"" 2>/dev/null &
        disown 2>/dev/null
      else
        _flow_log_warning "Positron only supported on macOS"
      fi
      ;;
    *)
      # For other editors, check if command exists first
      if command -v "$editor_cmd" &>/dev/null; then
        { eval "$editor \"$path\"" &>/dev/null & } 2>/dev/null
        disown 2>/dev/null
      else
        _flow_log_muted "Editor '$editor_cmd' not found - skipping"
      fi
      ;;
  esac
}

# ============================================================================
# TEACHING WORKFLOW SUPPORT
# ============================================================================

# Teaching-specific work session (Increment 1: Branch Safety)
_work_teaching_session() {
  local project_dir="$1"
  local config_file="$project_dir/.flow/teach-config.yml"

  # 1. Validate config exists
  if [[ ! -f "$config_file" ]]; then
    _flow_log_error "Teaching config not found: $config_file"
    _flow_log_info "Run 'teach-init' to create configuration"
    return 1
  fi

  # 2. Validate yq available
  if ! command -v yq &>/dev/null; then
    _flow_log_warning "yq not found - teaching features limited"
    # Fall back to regular context display
    _flow_show_work_context "$(basename "$project_dir")" "$project_dir"
    return 0
  fi

  # 3. Branch safety check
  local current_branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)
  local production_branch=$(yq -r '.branches.production' "$config_file" 2>/dev/null)
  local draft_branch=$(yq -r '.branches.draft' "$config_file" 2>/dev/null)

  if [[ "$current_branch" == "$production_branch" ]]; then
    echo ""
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[error]}⚠️  WARNING: You are on PRODUCTION branch${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[bold]}Branch:${FLOW_COLORS[reset]} $production_branch"
    echo "  ${FLOW_COLORS[error]}Students see this branch!${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[info]}Recommended: Switch to draft branch for edits${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[info]}Draft branch: $draft_branch${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""

    # Prompt to switch (with timeout for non-interactive contexts)
    if [[ -z "$FLOW_TEACHING_ALLOW_PRODUCTION" ]]; then
      read -t 30 "?Continue on production anyway? [y/N] " continue_anyway
      echo ""

      if [[ "$continue_anyway" != "y" ]]; then
        _flow_log_info "Switching to draft branch: $draft_branch"
        git -C "$project_dir" checkout "$draft_branch"
        current_branch="$draft_branch"
      fi
    fi
  fi

  # 4. Load shortcuts for current session
  _load_teaching_shortcuts "$config_file"

  # 5. Show enhanced context (Increment 2)
  _display_teaching_context "$project_dir" "$config_file" "$current_branch"
}

# Load teaching shortcuts into current session
_load_teaching_shortcuts() {
  local config_file="$1"

  # Create aliases for current session
  eval "$(yq -r '.shortcuts | to_entries[] | "alias \(.key)=\"\(.value)\""' "$config_file" 2>/dev/null)"

  # Show loaded shortcuts
  echo "${FLOW_COLORS[bold]}Shortcuts loaded:${FLOW_COLORS[reset]}"
  yq -r '.shortcuts | to_entries[] | "  \(.key) → \(.value)"' "$config_file" 2>/dev/null
  echo ""
}

# Display enhanced teaching context (Increment 2: Course Context)
_display_teaching_context() {
  local project_dir="$1"
  local config_file="$2"
  local current_branch="$3"

  # Get basic course info
  local course_name=$(yq -r '.course.name' "$config_file" 2>/dev/null)
  local semester=$(yq -r '.course.semester // empty' "$config_file" 2>/dev/null)
  local year=$(yq -r '.course.year // empty' "$config_file" 2>/dev/null)

  # Display course header
  echo ""
  echo "${FLOW_COLORS[bold]}📚 $course_name${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[info]}Branch:${FLOW_COLORS[reset]} $current_branch"

  # Display semester info if available
  if [[ -n "$semester" && "$semester" != "null" ]]; then
    echo "  ${FLOW_COLORS[info]}Semester:${FLOW_COLORS[reset]} $semester $year"
  fi

  # Calculate and display current week
  local current_week=$(_calculate_current_week "$config_file")
  if [[ -n "$current_week" && "$current_week" != "0" ]]; then
    # Check if it's a break week
    local break_name=$(_is_break_week "$config_file" "$current_week")
    if [[ $? -eq 0 && -n "$break_name" ]]; then
      echo "  ${FLOW_COLORS[warning]}Current Week:${FLOW_COLORS[reset]} Week $current_week ($break_name)"
    else
      echo "  ${FLOW_COLORS[info]}Current Week:${FLOW_COLORS[reset]} Week $current_week"
    fi
  fi

  # Show recent git activity (last 3 commits)
  local recent_commits=$(git -C "$project_dir" log --oneline -3 --format="%s" 2>/dev/null)
  if [[ -n "$recent_commits" ]]; then
    echo ""
    echo "  ${FLOW_COLORS[bold]}Recent Changes:${FLOW_COLORS[reset]}"
    echo "$recent_commits" | sed 's/^/    /' | head -3
  fi

  echo ""
}

# ============================================================================
# FINISH COMMAND
# ============================================================================

finish() {
  local note="$1"
  
  # Check if in a project
  local root=$(_flow_find_project_root)
  if [[ -z "$root" ]]; then
    _flow_log_warning "Not in a project directory"
  fi
  
  # End session
  _flow_session_end "$note"
  
  # Optional: Stage and commit changes
  if [[ -d ".git" ]]; then
    local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if (( changes > 0 )); then
      if _flow_confirm "Commit $changes change(s)?"; then
        git add -A
        local commit_msg="${note:-Work session completed}"
        git commit -m "$commit_msg"
        _flow_log_success "Changes committed: $commit_msg"
      fi
    fi
  fi
}

# ============================================================================
# HOP COMMAND - Quick project switch with tmux
# ============================================================================

hop() {
  # Handle help flags
  case "$1" in
    -h|--help|help)
      _hop_help
      return 0
      ;;
  esac

  local project="$1"

  # If no project, show picker
  if [[ -z "$project" ]]; then
    if _flow_has_fzf; then
      project=$(_flow_pick_project)
      [[ -z "$project" ]] && return 1
    else
      echo "Usage: hop <project>"
      return 1
    fi
  fi
  
  # Get project path
  local project_info=$(_flow_get_project "$project")
  if [[ -z "$project_info" ]]; then
    _flow_log_error "Project not found: $project"
    return 1
  fi
  
  eval "$project_info"

  # If in tmux, create/switch to project session
  if [[ -n "$TMUX" ]]; then
    local session_name="${project//[^a-zA-Z0-9]/_}"

    # Check if session exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux switch-client -t "$session_name"
    else
      # Create new session
      tmux new-session -d -s "$session_name" -c "$project_path"
      tmux switch-client -t "$session_name"
    fi

    _flow_log_success "Hopped to: $project"
  else
    # Not in tmux, just cd
    cd "$project_path" || return 1
    _flow_log_info "Changed to: $project (start tmux for session management)"
  fi
}

# Help function for hop command
_hop_help() {
  echo "${FLOW_COLORS[bold]}hop${FLOW_COLORS[reset]} - Quick project switch with tmux"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  hop [project]"
  echo ""
  echo "${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}"
  echo "  project    Project name or partial match (uses picker if omitted)"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -h, --help    Show this help message"
  echo ""
  echo "${FLOW_COLORS[bold]}BEHAVIOR${FLOW_COLORS[reset]}"
  echo "  In tmux:     Creates/switches to project session"
  echo "  Not in tmux: Changes to project directory"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  hop                     # Pick project with fzf"
  echo "  hop flow                # Switch to flow-cli project"
  echo "  hop aiterm              # Switch to aiterm project"
  echo ""
  echo "${FLOW_COLORS[bold]}RELATED COMMANDS${FLOW_COLORS[reset]}"
  echo "  work        Start working (full context setup)"
  echo "  pick        Interactive project picker"
}

# ============================================================================
# WHY COMMAND - Show current context
# ============================================================================

why() {
  _flow_where "$@"
}
