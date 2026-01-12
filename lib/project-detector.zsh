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

# Get project-specific commands
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

# Get project icon based on type
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

# Validate teaching configuration file
# Returns 0 if valid, 1 if invalid
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
