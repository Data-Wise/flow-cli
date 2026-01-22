# lib/project-detector.zsh - Project type detection
# Detects project type based on files present

# ============================================================================
# PROJECT TYPE DETECTION
# ============================================================================

typeset -gA PROJECT_TYPE_INDICATORS
PROJECT_TYPE_INDICATORS=(
  [r-package]="DESCRIPTION,NAMESPACE"
  [python]="pyproject.toml,setup.py,requirements.txt"
  [node]="package.json"
  [rust]="Cargo.toml"
  [go]="go.mod"
  [quarto]="_quarto.yml,.quarto"
  [obsidian]=".obsidian"
  [teaching]="syllabus.qmd,lectures"
  [research]="manuscript.qmd,paper.qmd"
)

# =============================================================================
# Function: _flow_detect_project_type
# Purpose: Detect project type based on marker files and directories present
# =============================================================================
# Arguments:
#   $1 - (optional) Directory to check [default: $PWD]
#
# Returns:
#   0 - Project type detected (or generic fallback)
#   1 - Error (invalid teaching config found)
#
# Output:
#   stdout - Project type string: r-package|python|node|rust|go|quarto|
#            obsidian|teaching|research|generic
#
# Example:
#   _flow_detect_project_type                     # Check current directory
#   _flow_detect_project_type "/path/to/project"  # Check specific path
#   local type=$(_flow_detect_project_type)       # Capture result
#
# Notes:
#   - Detection order matters: more specific types checked first
#   - R package requires BOTH DESCRIPTION AND NAMESPACE files
#   - Teaching detected via syllabus.qmd, lectures/, or .flow/teach-config.yml
#   - Validates teaching config if present (returns error if invalid)
#   - Falls back to "generic" if no markers found
#   - Used by dashboard, project picker, and context-aware commands
# =============================================================================
_flow_detect_project_type() {
  local dir="${1:-$PWD}"
  
  # Check for R package first (most specific)
  if [[ -f "$dir/DESCRIPTION" ]] && [[ -f "$dir/NAMESPACE" ]]; then
    echo "r-package"
    return 0
  fi
  
  # Check for teaching project (enhanced for teaching workflow v2)
  if [[ -f "$dir/syllabus.qmd" ]] ||
     [[ -d "$dir/lectures" ]] ||
     [[ -f "$dir/.flow/teach-config.yml" ]]; then

    # Validate config if present
    if [[ -f "$dir/.flow/teach-config.yml" ]]; then
      if ! _flow_validate_teaching_config "$dir/.flow/teach-config.yml"; then
        _flow_log_error "Invalid teaching config: $dir/.flow/teach-config.yml"
        return 1
      fi
    fi

    echo "teaching"
    return 0
  fi
  
  # Check for research project
  if [[ -f "$dir/manuscript.qmd" ]] || [[ -f "$dir/paper.qmd" ]]; then
    echo "research"
    return 0
  fi
  
  # Check for Quarto project
  if [[ -f "$dir/_quarto.yml" ]]; then
    echo "quarto"
    return 0
  fi
  
  # Check for Obsidian vault
  if [[ -d "$dir/.obsidian" ]]; then
    echo "obsidian"
    return 0
  fi
  
  # Check for Python project
  if [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]]; then
    echo "python"
    return 0
  fi
  
  # Check for Node project
  if [[ -f "$dir/package.json" ]]; then
    echo "node"
    return 0
  fi
  
  # Check for Rust project
  if [[ -f "$dir/Cargo.toml" ]]; then
    echo "rust"
    return 0
  fi
  
  # Check for Go project
  if [[ -f "$dir/go.mod" ]]; then
    echo "go"
    return 0
  fi
  
  # Default
  echo "generic"
}

# =============================================================================
# Function: _flow_project_commands
# Purpose: Get suggested commands relevant to a project type
# =============================================================================
# Arguments:
#   $1 - (optional) Project type [default: auto-detected from $PWD]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Space-separated list of relevant commands/tools
#            Empty string for unrecognized project types
#
# Example:
#   _flow_project_commands "r-package"
#   # Output: devtools::check() devtools::test() devtools::document() devtools::build()
#
#   _flow_project_commands "python"
#   # Output: pytest uv pip ruff
#
#   _flow_project_commands  # Auto-detects current project
#
# Notes:
#   - Used by dashboard and context help to suggest relevant actions
#   - Returns R function calls for r-package (devtools::*)
#   - Returns CLI commands for other languages
#   - Teaching and research share Quarto commands
# =============================================================================
_flow_project_commands() {
  local type="${1:-$(_flow_detect_project_type)}"
  
  case "$type" in
    r-package)
      echo "devtools::check() devtools::test() devtools::document() devtools::build()"
      ;;
    python)
      echo "pytest uv pip ruff"
      ;;
    node)
      echo "npm test npm run build npm start"
      ;;
    rust)
      echo "cargo test cargo build cargo run"
      ;;
    quarto)
      echo "quarto render quarto preview"
      ;;
    teaching)
      echo "quarto render quarto preview"
      ;;
    research)
      echo "quarto render"
      ;;
    *)
      echo ""
      ;;
  esac
}

# =============================================================================
# Function: _flow_project_icon
# Purpose: Get emoji icon representing a project type
# =============================================================================
# Arguments:
#   $1 - (optional) Project type [default: auto-detected from $PWD]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Single emoji character representing the project type
#
# Example:
#   _flow_project_icon "r-package"    # Output: 📦
#   _flow_project_icon "python"       # Output: 🐍
#   _flow_project_icon "teaching"     # Output: 🎓
#   _flow_project_icon "unknown"      # Output: 📁 (default)
#
# Notes:
#   - Used in dashboard, pick list, and status displays
#   - Icons chosen for quick visual recognition:
#     📦 r-package, 🐍 python, 📗 node, 🦀 rust, 🐹 go
#     📝 quarto, 🎓 teaching, 🔬 research, 💎 obsidian, 📁 generic
# =============================================================================
_flow_project_icon() {
  local type="${1:-$(_flow_detect_project_type)}"
  
  case "$type" in
    r-package)  echo "📦" ;;
    python)     echo "🐍" ;;
    node)       echo "📗" ;;
    rust)       echo "🦀" ;;
    go)         echo "🐹" ;;
    quarto)     echo "📝" ;;
    teaching)   echo "🎓" ;;
    research)   echo "🔬" ;;
    obsidian)   echo "💎" ;;
    *)          echo "📁" ;;
  esac
}

# =============================================================================
# Function: _flow_validate_teaching_config
# Purpose: Validate a teaching workflow configuration file for required fields
# =============================================================================
# Arguments:
#   $1 - (required) Path to teach-config.yml file
#
# Returns:
#   0 - Configuration is valid (or yq not available - degrades gracefully)
#   1 - Configuration is invalid (missing required fields)
#
# Output:
#   stderr - Error messages for missing required fields
#
# Example:
#   _flow_validate_teaching_config ".flow/teach-config.yml"
#   if ! _flow_validate_teaching_config "$config"; then
#       echo "Fix config before continuing"
#   fi
#
# Notes:
#   - Requires yq for YAML parsing (warns and returns 0 if not installed)
#   - Required fields: course.name, branches.draft, branches.production
#   - Called automatically by _flow_detect_project_type for teaching projects
#   - Part of teaching workflow v2 validation layer
# =============================================================================
_flow_validate_teaching_config() {
  local config="$1"

  # Check yq is available
  if ! command -v yq &>/dev/null; then
    _flow_log_warning "yq not found - cannot validate teaching config"
    return 0  # Don't fail, just warn
  fi

  # Check required fields
  yq -e '.course.name' "$config" &>/dev/null || {
    _flow_log_error "Missing required field: course.name"
    return 1
  }

  yq -e '.branches.draft' "$config" &>/dev/null || {
    _flow_log_error "Missing required field: branches.draft"
    return 1
  }

  yq -e '.branches.production' "$config" &>/dev/null || {
    _flow_log_error "Missing required field: branches.production"
    return 1
  }

  return 0
}
