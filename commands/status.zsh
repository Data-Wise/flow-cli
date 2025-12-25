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
  cat << 'EOF'
Usage: status [project] [options]

View and update project status files.

OPTIONS:
  --create    Create new .STATUS file
  --edit      Open .STATUS in editor
  --set       Update status fields

SET OPTIONS:
  --status <value>    Set status (active|paused|blocked|archived)
  --focus <text>      Set current focus
  --progress <0-100>  Set progress percentage

EXAMPLES:
  status               # Show current project status
  status medrobust     # Show medrobust status
  status myproj --create   # Create new .STATUS
  status myproj --set --progress 50 --focus "Testing"

With atlas installed, provides richer display and tracking.
EOF
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
