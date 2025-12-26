# commands/doctor.zsh - Health check for flow-cli
# Checks installed dependencies and offers to fix issues

# ============================================================================
# DOCTOR COMMAND
# ============================================================================

doctor() {
  local mode="check"    # check, fix, ai
  local verbose=false
  local auto_yes=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fix|-f)       mode="fix"; shift ;;
      --ai|-a)        mode="ai"; shift ;;
      --yes|-y)       auto_yes=true; shift ;;
      --verbose|-v)   verbose=true; shift ;;
      --help|-h)      _doctor_help; return 0 ;;
      *)              shift ;;
    esac
  done

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🩺 flow-cli Health Check${FLOW_COLORS[reset]}                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  # Track issues for fixing
  typeset -ga _doctor_missing_brew=()
  typeset -ga _doctor_missing_npm=()
  typeset -ga _doctor_missing_pip=()

  # ──────────────────────────────────────────────────────────────
  # SHELL & CORE
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}🐚 SHELL${FLOW_COLORS[reset]}"
  _doctor_check_cmd "zsh" "" "shell"
  _doctor_check_cmd "git" "" "shell"
  echo ""

  # ──────────────────────────────────────────────────────────────
  # REQUIRED
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}⚡ REQUIRED${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(core functionality)${FLOW_COLORS[reset]}"
  _doctor_check_cmd "fzf" "brew" "required"
  echo ""

  # ──────────────────────────────────────────────────────────────
  # RECOMMENDED
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}✨ RECOMMENDED${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(enhanced experience)${FLOW_COLORS[reset]}"
  _doctor_check_cmd "eza" "brew" "recommended"
  _doctor_check_cmd "bat" "brew" "recommended"
  _doctor_check_cmd "zoxide" "brew" "recommended"
  _doctor_check_cmd "fd" "brew" "recommended"
  _doctor_check_cmd "rg" "brew:ripgrep" "recommended"
  echo ""

  # ──────────────────────────────────────────────────────────────
  # OPTIONAL
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}📦 OPTIONAL${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(nice to have)${FLOW_COLORS[reset]}"
  _doctor_check_cmd "dust" "brew" "optional"
  _doctor_check_cmd "duf" "brew" "optional"
  _doctor_check_cmd "btop" "brew" "optional"
  _doctor_check_cmd "delta" "brew:git-delta" "optional"
  _doctor_check_cmd "gh" "brew" "optional"
  _doctor_check_cmd "jq" "brew" "optional"
  echo ""

  # ──────────────────────────────────────────────────────────────
  # INTEGRATIONS
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}🔌 INTEGRATIONS${FLOW_COLORS[reset]}"
  _doctor_check_cmd "atlas" "npm:@data-wise/atlas" "optional"

  # Check for radian (R console) only if R exists
  if command -v R >/dev/null 2>&1; then
    _doctor_check_cmd "radian" "pip" "optional"
  fi
  echo ""

  # ──────────────────────────────────────────────────────────────
  # ZSH PLUGINS
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}🔧 ZSH PLUGINS${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(via antidote)${FLOW_COLORS[reset]}"
  _doctor_check_zsh_plugin "powerlevel10k" "romkatv/powerlevel10k"
  _doctor_check_zsh_plugin "autosuggestions" "zsh-users/zsh-autosuggestions"
  _doctor_check_zsh_plugin "syntax-highlighting" "zsh-users/zsh-syntax-highlighting"
  _doctor_check_zsh_plugin "completions" "zsh-users/zsh-completions"
  echo ""

  # ──────────────────────────────────────────────────────────────
  # FLOW-CLI STATUS
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}🌊 FLOW-CLI${FLOW_COLORS[reset]}"
  if [[ -n "$FLOW_PLUGIN_LOADED" ]]; then
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} flow-cli v${FLOW_VERSION:-unknown} loaded"
  else
    echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} flow-cli not loaded"
  fi

  if _flow_has_atlas 2>/dev/null; then
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} atlas connected"
  else
    echo "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} atlas not connected ${FLOW_COLORS[muted]}(standalone mode)${FLOW_COLORS[reset]}"
  fi
  echo ""

  # ──────────────────────────────────────────────────────────────
  # SUMMARY & ACTIONS
  # ──────────────────────────────────────────────────────────────
  local total_missing=$((${#_doctor_missing_brew[@]} + ${#_doctor_missing_npm[@]} + ${#_doctor_missing_pip[@]}))

  if [[ $total_missing -eq 0 ]]; then
    echo "${FLOW_COLORS[success]}✓ All essential tools installed!${FLOW_COLORS[reset]}"
    echo ""
    return 0
  fi

  # Show summary
  echo "${FLOW_COLORS[warning]}△ Missing ${total_missing} tool(s)${FLOW_COLORS[reset]}"
  echo ""

  # Handle different modes
  case "$mode" in
    fix)
      _doctor_interactive_fix "$auto_yes"
      ;;
    ai)
      _doctor_ai_assist
      ;;
    *)
      # Default: show suggestions
      echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
      echo ""
      echo "${FLOW_COLORS[bold]}Quick actions:${FLOW_COLORS[reset]}"
      echo "  ${FLOW_COLORS[accent]}doctor --fix${FLOW_COLORS[reset]}     Interactive install missing tools"
      echo "  ${FLOW_COLORS[accent]}doctor --fix -y${FLOW_COLORS[reset]}  Install all without prompts"
      echo "  ${FLOW_COLORS[accent]}doctor --ai${FLOW_COLORS[reset]}      AI-assisted troubleshooting"
      echo ""
      echo "${FLOW_COLORS[muted]}Or install all via Brewfile:${FLOW_COLORS[reset]}"
      echo "  brew bundle --file=$FLOW_PLUGIN_DIR/setup/Brewfile"
      echo ""
      ;;
  esac
}

# ============================================================================
# INTERACTIVE FIX MODE
# ============================================================================

_doctor_interactive_fix() {
  local auto_yes="${1:-false}"

  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}🔧 Interactive Fix Mode${FLOW_COLORS[reset]}"
  echo ""

  # Homebrew packages
  if [[ ${#_doctor_missing_brew[@]} -gt 0 ]]; then
    echo "${FLOW_COLORS[info]}Homebrew packages to install:${FLOW_COLORS[reset]}"
    for pkg in "${_doctor_missing_brew[@]}"; do
      echo "  • $pkg"
    done
    echo ""

    if [[ "$auto_yes" == true ]] || _doctor_confirm "Install ${#_doctor_missing_brew[@]} Homebrew package(s)?"; then
      echo ""
      for pkg in "${_doctor_missing_brew[@]}"; do
        echo "${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if brew install "$pkg" 2>&1; then
          echo "${FLOW_COLORS[success]}✓ $pkg installed${FLOW_COLORS[reset]}"
        else
          echo "${FLOW_COLORS[error]}✗ Failed to install $pkg${FLOW_COLORS[reset]}"
        fi
      done
      echo ""
    else
      echo "${FLOW_COLORS[muted]}Skipped Homebrew packages${FLOW_COLORS[reset]}"
      echo ""
    fi
  fi

  # NPM packages
  if [[ ${#_doctor_missing_npm[@]} -gt 0 ]]; then
    echo "${FLOW_COLORS[info]}NPM packages to install:${FLOW_COLORS[reset]}"
    for pkg in "${_doctor_missing_npm[@]}"; do
      echo "  • $pkg"
    done
    echo ""

    if [[ "$auto_yes" == true ]] || _doctor_confirm "Install ${#_doctor_missing_npm[@]} NPM package(s) globally?"; then
      echo ""
      for pkg in "${_doctor_missing_npm[@]}"; do
        echo "${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if npm install -g "$pkg" 2>&1; then
          echo "${FLOW_COLORS[success]}✓ $pkg installed${FLOW_COLORS[reset]}"
        else
          echo "${FLOW_COLORS[error]}✗ Failed to install $pkg${FLOW_COLORS[reset]}"
        fi
      done
      echo ""
    else
      echo "${FLOW_COLORS[muted]}Skipped NPM packages${FLOW_COLORS[reset]}"
      echo ""
    fi
  fi

  # Pip packages
  if [[ ${#_doctor_missing_pip[@]} -gt 0 ]]; then
    echo "${FLOW_COLORS[info]}Pip packages to install:${FLOW_COLORS[reset]}"
    for pkg in "${_doctor_missing_pip[@]}"; do
      echo "  • $pkg"
    done
    echo ""

    if [[ "$auto_yes" == true ]] || _doctor_confirm "Install ${#_doctor_missing_pip[@]} pip package(s)?"; then
      echo ""
      for pkg in "${_doctor_missing_pip[@]}"; do
        echo "${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if pip install "$pkg" 2>&1; then
          echo "${FLOW_COLORS[success]}✓ $pkg installed${FLOW_COLORS[reset]}"
        else
          echo "${FLOW_COLORS[error]}✗ Failed to install $pkg${FLOW_COLORS[reset]}"
        fi
      done
      echo ""
    else
      echo "${FLOW_COLORS[muted]}Skipped pip packages${FLOW_COLORS[reset]}"
      echo ""
    fi
  fi

  echo "${FLOW_COLORS[success]}Done!${FLOW_COLORS[reset]} Run ${FLOW_COLORS[accent]}doctor${FLOW_COLORS[reset]} again to verify."
  echo ""
}

# ============================================================================
# AI-ASSISTED MODE (Claude CLI)
# ============================================================================

_doctor_ai_assist() {
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}🤖 AI-Assisted Troubleshooting${FLOW_COLORS[reset]}"
  echo ""

  # Check if claude is available
  if ! command -v claude >/dev/null 2>&1; then
    echo "${FLOW_COLORS[error]}✗ Claude CLI not found${FLOW_COLORS[reset]}"
    echo ""
    echo "Install Claude CLI first:"
    echo "  ${FLOW_COLORS[accent]}npm install -g @anthropic-ai/claude-cli${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # Build context for Claude
  local context="flow-cli doctor found these missing tools:\n"

  if [[ ${#_doctor_missing_brew[@]} -gt 0 ]]; then
    context+="Homebrew: ${_doctor_missing_brew[*]}\n"
  fi
  if [[ ${#_doctor_missing_npm[@]} -gt 0 ]]; then
    context+="NPM: ${_doctor_missing_npm[*]}\n"
  fi
  if [[ ${#_doctor_missing_pip[@]} -gt 0 ]]; then
    context+="Pip: ${_doctor_missing_pip[*]}\n"
  fi

  context+="\nCurrent directory: $PWD\n"
  context+="Shell: $SHELL\n"
  context+="OS: $(uname -s)\n"

  echo "${FLOW_COLORS[muted]}Launching Claude CLI for assistance...${FLOW_COLORS[reset]}"
  echo ""

  # Launch Claude with context
  local prompt="I'm setting up flow-cli and the doctor command found missing tools. Help me:
1. Understand what each missing tool does
2. Decide which ones I actually need
3. Install them safely

Missing tools:
$(echo -e "$context")

Please explain each tool briefly and ask which ones I want to install."

  # Use claude CLI with the prompt
  if _doctor_confirm "Launch Claude CLI for AI-assisted setup?"; then
    echo ""
    claude --print "$prompt"
  else
    echo ""
    echo "${FLOW_COLORS[muted]}You can manually run:${FLOW_COLORS[reset]}"
    echo "  claude \"Help me install: ${_doctor_missing_brew[*]} ${_doctor_missing_npm[*]}\""
    echo ""
  fi
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

_doctor_check_cmd() {
  local cmd="$1"
  local install_spec="$2"  # Format: "brew" or "brew:package" or "npm:package" or "pip"
  local category="$3"      # required, recommended, optional

  if command -v "$cmd" >/dev/null 2>&1; then
    local version=""
    version=$($cmd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}${version}${FLOW_COLORS[reset]}"
    return 0
  else
    # Parse install spec
    local manager="${install_spec%%:*}"
    local package="${install_spec#*:}"
    [[ "$package" == "$install_spec" ]] && package="$cmd"

    # Show status
    local icon="○"
    [[ "$category" == "required" ]] && icon="✗"
    local color="${FLOW_COLORS[warning]}"
    [[ "$category" == "required" ]] && color="${FLOW_COLORS[error]}"

    local hint=""
    case "$manager" in
      brew) hint="brew install $package" ;;
      npm)  hint="npm install -g $package" ;;
      pip)  hint="pip install $package" ;;
    esac

    echo "  ${color}${icon}${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}← $hint${FLOW_COLORS[reset]}"

    # Track for fixing
    case "$manager" in
      brew) _doctor_missing_brew+=("$package") ;;
      npm)  _doctor_missing_npm+=("$package") ;;
      pip)  _doctor_missing_pip+=("$package") ;;
    esac

    return 1
  fi
}

_doctor_check_zsh_plugin() {
  local name="$1"
  local repo="$2"
  local plugins_file="${ZDOTDIR:-$HOME/.config/zsh}/.zsh_plugins.txt"

  if [[ -f "$plugins_file" ]] && grep -q "$repo" "$plugins_file" 2>/dev/null; then
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $name"
    return 0
  else
    echo "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} $name ${FLOW_COLORS[muted]}(not in plugins.txt)${FLOW_COLORS[reset]}"
    return 1
  fi
}

_doctor_confirm() {
  local prompt="$1"
  local response

  echo -n "${FLOW_COLORS[info]}? ${prompt}${FLOW_COLORS[reset]} [Y/n] "
  read -r response

  case "$response" in
    [nN]|[nN][oO]) return 1 ;;
    *) return 0 ;;
  esac
}

_doctor_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}flow doctor${FLOW_COLORS[reset]} - Health Check                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  doctor [options]"
  echo ""
  echo "${FLOW_COLORS[bold]}MODES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}(default)${FLOW_COLORS[reset]}      Check and show status"
  echo "  ${FLOW_COLORS[accent]}-f, --fix${FLOW_COLORS[reset]}      Interactive install missing tools"
  echo "  ${FLOW_COLORS[accent]}-a, --ai${FLOW_COLORS[reset]}       AI-assisted troubleshooting (Claude CLI)"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -y, --yes      Skip confirmations (use with --fix)"
  echo "  -v, --verbose  Show detailed version info"
  echo "  -h, --help     Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor              # Quick health check"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --fix        # Interactively fix issues"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --fix -y     # Auto-install all missing"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --ai         # Get AI help deciding what to install"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow doctor         # Also works via flow command"
  echo ""
  echo "${FLOW_COLORS[bold]}INSTALL ALL AT ONCE${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}brew bundle --file=\$FLOW_PLUGIN_DIR/setup/Brewfile${FLOW_COLORS[reset]}"
  echo ""
}

# Alias for discoverability
alias flow-doctor='doctor'
