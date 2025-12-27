# commands/status.zsh - Project status management
# View and update .STATUS files with atlas integration

# ============================================================================
# STATUS COMMAND
# ============================================================================

status() {
  local project=""
  local show_extended=0
  local subcmd=""
  local subcmd_args=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|help)
        _flow_status_help
        return 0
        ;;
      -e|--extended)
        show_extended=1
        shift
        ;;
      --create|create|--edit|edit|--set|set|--tag|tag)
        subcmd="$1"
        shift
        subcmd_args=("$@")
        break
        ;;
      -*)
        _flow_log_error "Unknown option: $1"
        return 1
        ;;
      *)
        # First non-option is project name
        if [[ -z "$project" ]]; then
          project="$1"
        fi
        shift
        ;;
    esac
  done

  # No project specified: use current project
  if [[ -z "$project" ]]; then
    if _flow_in_project; then
      local root=$(_flow_find_project_root)
      project=$(_flow_project_name "$root")
    else
      _flow_status_help
      return 0
    fi
  fi

  # Find project
  local path=$(_flow_find_project_path "$project")
  if [[ -z "$path" ]]; then
    _flow_log_error "Project not found: $project"
    return 1
  fi

  local status_file="$path/.STATUS"

  # Handle subcommands
  case "$subcmd" in
    --create|create)
      _flow_status_create "$path"
      return $?
      ;;
    --edit|edit)
      ${EDITOR:-vim} "$status_file"
      return $?
      ;;
    --set|set)
      _flow_status_set "$path" "${subcmd_args[@]}"
      return $?
      ;;
    --tag|tag)
      _flow_status_tags "${subcmd_args[1]}" "$path" "${subcmd_args[2]}"
      return $?
      ;;
    *)
      # Default: Show status
      _flow_status_show "$path"
      if [[ $show_extended -eq 1 ]]; then
        _flow_status_extended "$path"
      fi
      ;;
  esac
}

# ============================================================================
# STATUS DISPLAY
# ============================================================================

_flow_status_show() {
  local path="$1"
  local name=$(_flow_project_name "$path")
  local status_file="$path/.STATUS"
  
  if [[ ! -f "$status_file" ]]; then
    _flow_log_warning "No .STATUS file in $name"
    echo "Create one with: status $name --create"
    return 1
  fi
  
  # Use atlas if available for rich display
  if _flow_has_atlas; then
    _flow_atlas status "$name"
  else
    # Pure shell display
    local type=$(_flow_detect_project_type "$path")
    local icon=$(_flow_project_icon "$type")
    
    echo ""
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo "$icon ${FLOW_COLORS[bold]}$name${FLOW_COLORS[reset]} ($type)"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""
    
    # Parse and display key fields
    local line
    while IFS= read -r line; do
      case "$line" in
        "## Status:"*)  echo "🟢 Status: ${line#*:}" ;;
        "## Phase:"*)   echo "📍 Phase: ${line#*:}" ;;
        "## Focus:"*)   echo "🎯 Focus: ${line#*:}" ;;
        "## Progress:"*) 
          local pct="${line#*:}"
          pct="${pct// /}"
          _flow_progress_bar "$pct" 30
          ;;
        "## Next:"*|"## Next Task:"*|"## Current Task:"*)
          echo "▶️  Next: ${line#*:}"
          ;;
      esac
    done < "$status_file"
    
    echo ""
  fi
}

# ============================================================================
# STATUS CREATION
# ============================================================================

_flow_status_create() {
  local path="$1"
  local name=$(_flow_project_name "$path")
  local status_file="$path/.STATUS"
  
  if [[ -f "$status_file" ]]; then
    if ! _flow_confirm ".STATUS exists. Overwrite?"; then
      return 1
    fi
  fi
  
  # Detect project type
  local proj_type="project"
  if [[ -f "$path/DESCRIPTION" ]]; then
    proj_type="r-package"
  elif [[ -f "$path/_quarto.yml" ]]; then
    proj_type="quarto"
  elif [[ -f "$path/package.json" ]]; then
    proj_type="node-package"
  elif [[ -d "$path/.obsidian" ]]; then
    proj_type="obsidian-vault"
  fi
  
  # Create status file with v3.5.0 extended fields
  cat > "$status_file" << EOF
## Project: $name
## Type: $proj_type
## Status: active
## Phase: Initial
## Priority: 2
## Progress: 0
## daily_goal: 3

## Focus: Getting started

## Quick Context
$name is a $proj_type project.

## Current Tasks
- [ ] Define project goals
- [ ] Set up development environment

## Next Tasks
- [ ] TBD

## Blockers
None

## Links
- Path: $path

## Session Log
- $(date '+%Y-%m-%d'): Project initialized
EOF

  _flow_log_success "Created .STATUS for $name"
  
  # Register with atlas if available
  if _flow_has_atlas; then
    _flow_atlas_async project add "$path"
  fi
}

# ============================================================================
# STATUS UPDATE
# ============================================================================

_flow_status_set() {
  local path="$1"
  shift
  local name=$(_flow_project_name "$path")
  
  # Use atlas if available
  if _flow_has_atlas; then
    _flow_atlas status "$name" "$@"
  else
    # Parse arguments and update file
    local status_file="$path/.STATUS"
    [[ ! -f "$status_file" ]] && { _flow_log_error "No .STATUS file"; return 1; }
    
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --status)
          sed -i '' "s/^## Status:.*$/## Status: $2/" "$status_file"
          shift 2
          ;;
        --focus)
          sed -i '' "s/^## Focus:.*$/## Focus: $2/" "$status_file"
          shift 2
          ;;
        --progress)
          sed -i '' "s/^## Progress:.*$/## Progress: $2/" "$status_file"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    
    _flow_log_success "Updated $name status"
  fi
}

# ============================================================================
# HELPERS
# ============================================================================

_flow_status_help() {
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
${_C_BOLD}│ 📊 STATUS - Project Status Management       │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} status [project] [options]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}status${_C_NC}              Show current project status
  ${_C_CYAN}status <name>${_C_NC}       Show specific project status
  ${_C_CYAN}status <name> --edit${_C_NC} Edit .STATUS file

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} status                   ${_C_DIM}# Current project${_C_NC}
  ${_C_DIM}\$${_C_NC} status medrobust         ${_C_DIM}# Show medrobust${_C_NC}
  ${_C_DIM}\$${_C_NC} status myproj --create   ${_C_DIM}# Create .STATUS${_C_NC}
  ${_C_DIM}\$${_C_NC} status myproj --set --progress 50 --focus \"Testing\"

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--create${_C_NC}            Create new .STATUS file
  ${_C_CYAN}--edit${_C_NC}              Open .STATUS in editor
  ${_C_CYAN}--set${_C_NC}               Update status fields
  ${_C_CYAN}--extended${_C_NC}, ${_C_CYAN}-e${_C_NC}     Show extended fields (wins, streak, tags)
  ${_C_CYAN}--tag${_C_NC} <action>      Manage tags (get, set <tags>, add <tag>)

${_C_BLUE}⚙️  SET OPTIONS${_C_NC}:
  ${_C_CYAN}--status${_C_NC} <value>    Set status (active|paused|blocked|archived)
  ${_C_CYAN}--focus${_C_NC} <text>      Set current focus
  ${_C_CYAN}--progress${_C_NC} <0-100>  Set progress percentage

${_C_BLUE}📄 .STATUS FILE FORMAT${_C_NC}:
  ${_C_DIM}status: active${_C_NC}
  ${_C_DIM}priority: P0${_C_NC}
  ${_C_DIM}progress: 45${_C_NC}
  ${_C_DIM}next: Implement feature${_C_NC}

${_C_BLUE}🆕 EXTENDED FIELDS (v3.5.0)${_C_NC}:
  ${_C_DIM}wins: Fixed bug (2025-12-26), Added feature (2025-12-25)${_C_NC}
  ${_C_DIM}streak: 5${_C_NC}
  ${_C_DIM}last_active: 2025-12-26 14:30${_C_NC}
  ${_C_DIM}tags: r-package, cran-ready, priority${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: With atlas installed, provides richer display

${_C_DIM}See also:${_C_NC} dash help, work help
"
}

# Find project path by name
# NOTE: Always use filesystem search - atlas --format=shell has embedded JSON that breaks eval
_flow_find_project_path() {
  local name="$1"

  # Search filesystem (always - atlas shell format is unreliable)
  local search_dirs=(
    "$FLOW_PROJECTS_ROOT"
    "$FLOW_PROJECTS_ROOT/dev-tools"
    "$FLOW_PROJECTS_ROOT/r-packages/active"
    "$FLOW_PROJECTS_ROOT/r-packages/stable"
    "$FLOW_PROJECTS_ROOT/research"
    "$FLOW_PROJECTS_ROOT/teaching"
    "$FLOW_PROJECTS_ROOT/quarto"
  )

  for dir in "${search_dirs[@]}"; do
    if [[ -d "$dir/$name" ]]; then
      echo "$dir/$name"
      return 0
    fi
  done

  return 1
}

# ============================================================================
# QUICK STATUS ALIASES
# ============================================================================

# st - shorthand for status
st() { status "$@" }

# setprogress - quick progress update
setprogress() {
  local progress="${1:-}"
  if [[ -z "$progress" ]]; then
    echo "Usage: setprogress <0-100>"
    return 1
  fi

  if _flow_in_project; then
    local name=$(_flow_project_name "$(_flow_find_project_root)")
    status "$name" --set --progress "$progress"
  else
    _flow_log_error "Not in a project directory"
  fi
}

# ============================================================================
# EXTENDED .STATUS FIELDS (v3.5.0)
# ============================================================================

# Read a field from .STATUS file (pure ZSH - no external commands)
_flow_status_get_field() {
  local status_file="$1"
  local field="$2"
  local value="" line

  [[ ! -f "$status_file" ]] && return 1

  # Read file and find matching line (case-insensitive)
  while IFS= read -r line; do
    # Match ## Field: value format
    if [[ "${line:l}" == "## ${field:l}:"* ]]; then
      value="${line#*: }"  # Remove everything up to ": "
      value="${value#"${value%%[![:space:]]*}"}"  # Trim leading whitespace
      echo "$value"
      return 0
    fi
  done < "$status_file"

  return 1
}

# Set a field in .STATUS file (pure ZSH - no external commands)
_flow_status_set_field() {
  local status_file="$1"
  local field="$2"
  local value="$3"
  local found=0
  local -a new_lines=()
  local line

  [[ ! -f "$status_file" ]] && return 1

  # Read all lines and update matching field
  while IFS= read -r line; do
    if [[ "${line:l}" == "## ${field:l}:"* ]]; then
      new_lines+=("## ${field}: ${value}")
      found=1
    else
      new_lines+=("$line")
    fi
  done < "$status_file"

  # If field not found, append it
  if (( ! found )); then
    new_lines+=("## ${field}: ${value}")
  fi

  # Write back to file (printf ensures POSIX-compliant trailing newline)
  printf '%s\n' "${new_lines[@]}" > "$status_file"
}

# Update last_active timestamp
_flow_status_touch() {
  local path="${1:-}"

  # Use current project if not specified
  if [[ -z "$path" ]] && _flow_in_project; then
    path=$(_flow_find_project_root)
  fi

  [[ -z "$path" ]] && return 1

  local status_file="$path/.STATUS"
  [[ ! -f "$status_file" ]] && return 1

  zmodload -F zsh/datetime b:strftime
  local timestamp=$(strftime "%Y-%m-%d %H:%M" $EPOCHSECONDS)

  _flow_status_set_field "$status_file" "last_active" "$timestamp"
}

# Get/set tags
_flow_status_tags() {
  local action="${1:-get}"
  local path="${2:-}"

  if [[ -z "$path" ]] && _flow_in_project; then
    path=$(_flow_find_project_root)
  fi

  [[ -z "$path" ]] && return 1

  local status_file="$path/.STATUS"

  case "$action" in
    get)
      _flow_status_get_field "$status_file" "tags"
      ;;
    set)
      shift 2
      local tags="$*"
      _flow_status_set_field "$status_file" "tags" "$tags"
      ;;
    add)
      local current=$(_flow_status_get_field "$status_file" "tags")
      local new_tag="$3"
      if [[ -z "$current" ]]; then
        _flow_status_set_field "$status_file" "tags" "$new_tag"
      elif [[ "$current" != *"$new_tag"* ]]; then
        _flow_status_set_field "$status_file" "tags" "$current, $new_tag"
      fi
      ;;
  esac
}

# Record a win to .STATUS file
_flow_status_add_win() {
  local path="${1:-}"
  local win_text="$2"
  local category="${3:-other}"

  if [[ -z "$path" ]] && _flow_in_project; then
    path=$(_flow_find_project_root)
  fi

  [[ -z "$path" ]] && return 1

  local status_file="$path/.STATUS"
  [[ ! -f "$status_file" ]] && return 1

  zmodload -F zsh/datetime b:strftime
  local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)

  # Get current wins (comma-separated recent wins)
  local current_wins=$(_flow_status_get_field "$status_file" "wins")

  # Truncate win text if too long
  (( ${#win_text} > 40 )) && win_text="${win_text:0:37}..."

  # Prepend new win (keep last 5)
  local new_win="${win_text} ($today)"
  if [[ -z "$current_wins" ]]; then
    _flow_status_set_field "$status_file" "wins" "$new_win"
  else
    # Split and keep last 4 + new one
    local -a wins_arr
    wins_arr=("${(@s:, :)current_wins}")
    wins_arr=("$new_win" "${wins_arr[@]:0:4}")
    _flow_status_set_field "$status_file" "wins" "${(j:, :)wins_arr}"
  fi

  # Update streak
  _flow_status_update_streak "$path"

  # Update last_active
  _flow_status_touch "$path"
}

# Update streak count
_flow_status_update_streak() {
  local path="$1"
  local status_file="$path/.STATUS"

  [[ ! -f "$status_file" ]] && return 1

  zmodload -F zsh/datetime b:strftime
  local today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)

  # Read global wins file to calculate streak
  local wins_file="${FLOW_DATA_DIR}/wins.md"
  [[ ! -f "$wins_file" ]] && return 0

  local streak=0
  local check_date="$today"

  for (( i = 0; i < 30; i++ )); do
    if grep -q "\[$check_date" "$wins_file" 2>/dev/null; then
      ((streak++))
      check_date=$(strftime "%Y-%m-%d" $((EPOCHSECONDS - (i + 1) * 86400)))
    else
      break
    fi
  done

  _flow_status_set_field "$status_file" "streak" "$streak"
}

# Show extended status info
_flow_status_extended() {
  local path="${1:-}"

  if [[ -z "$path" ]] && _flow_in_project; then
    path=$(_flow_find_project_root)
  fi

  [[ -z "$path" ]] && return 1

  local status_file="$path/.STATUS"
  [[ ! -f "$status_file" ]] && return 1

  local name=$(_flow_project_name "$path")

  echo ""
  echo "  ${FLOW_COLORS[header]}Extended Status: $name${FLOW_COLORS[reset]}"
  echo ""

  # Last active
  local last_active=$(_flow_status_get_field "$status_file" "last_active")
  if [[ -n "$last_active" ]]; then
    echo "  ⏱️  Last active: ${FLOW_COLORS[accent]}$last_active${FLOW_COLORS[reset]}"
  fi

  # Streak
  local streak=$(_flow_status_get_field "$status_file" "streak")
  if [[ -n "$streak" ]] && (( streak > 0 )); then
    echo "  🔥 Streak: ${FLOW_COLORS[success]}$streak days${FLOW_COLORS[reset]}"
  fi

  # Tags
  local tags=$(_flow_status_get_field "$status_file" "tags")
  if [[ -n "$tags" ]]; then
    echo "  🏷️  Tags: ${FLOW_COLORS[muted]}$tags${FLOW_COLORS[reset]}"
  fi

  # Recent wins
  local wins=$(_flow_status_get_field "$status_file" "wins")
  if [[ -n "$wins" ]]; then
    echo "  🎉 Recent wins:"
    local -a wins_arr
    wins_arr=("${(@s:, :)wins}")
    for win in "${wins_arr[@]:0:3}"; do
      echo "     ✓ ${FLOW_COLORS[accent]}$win${FLOW_COLORS[reset]}"
    done
  fi

  echo ""
}
