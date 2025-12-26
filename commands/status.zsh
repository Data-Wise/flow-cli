# commands/status.zsh - Project status management
# View and update .STATUS files with atlas integration

# ============================================================================
# STATUS COMMAND
# ============================================================================

status() {
  local project="$1"
  shift
  
  # No args: show current project status
  if [[ -z "$project" ]]; then
    if _flow_in_project; then
      local root=$(_flow_find_project_root)
      project=$(_flow_project_name "$root")
    else
      _flow_status_help
      return 0
    fi
  fi
  
  # Help
  if [[ "$project" == "-h" || "$project" == "--help" || "$project" == "help" ]]; then
    _flow_status_help
    return 0
  fi
  
  # Find project
  local path=$(_flow_find_project_path "$project")
  if [[ -z "$path" ]]; then
    _flow_log_error "Project not found: $project"
    return 1
  fi
  
  local status_file="$path/.STATUS"
  
  # Handle subcommands
  case "$1" in
    --create|create)
      _flow_status_create "$path"
      return $?
      ;;
    --edit|edit)
      ${EDITOR:-vim} "$status_file"
      return $?
      ;;
    --set|set)
      shift
      _flow_status_set "$path" "$@"
      return $?
      ;;
    *)
      # Default: Show status
      _flow_status_show "$path"
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
  
  # Create status file
  cat > "$status_file" << EOF
## Project: $name
## Type: $proj_type
## Status: active
## Phase: Initial
## Priority: 2
## Progress: 0

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

${_C_BLUE}⚙️  SET OPTIONS${_C_NC}:
  ${_C_CYAN}--status${_C_NC} <value>    Set status (active|paused|blocked|archived)
  ${_C_CYAN}--focus${_C_NC} <text>      Set current focus
  ${_C_CYAN}--progress${_C_NC} <0-100>  Set progress percentage

${_C_BLUE}📄 .STATUS FILE FORMAT${_C_NC}:
  ${_C_DIM}status: active${_C_NC}
  ${_C_DIM}priority: P0${_C_NC}
  ${_C_DIM}progress: 45${_C_NC}
  ${_C_DIM}next: Implement feature${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: With atlas installed, provides richer display

${_C_DIM}See also:${_C_NC} dash help, work help
"
}

# Find project path by name
_flow_find_project_path() {
  local name="$1"
  
  # Use atlas if available
  if _flow_has_atlas; then
    local info=$(_flow_atlas project show "$name" --format=shell 2>/dev/null)
    if [[ -n "$info" ]]; then
      eval "$info"
      echo "$path"
      return 0
    fi
  fi
  
  # Fallback: Search filesystem
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
