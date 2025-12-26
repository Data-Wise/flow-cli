# commands/doctor.zsh - Health check for flow-cli
# Checks installed dependencies and shows setup status

# ============================================================================
# DOCTOR COMMAND
# ============================================================================

doctor() {
  local show_fix=false
  local verbose=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fix|-f)     show_fix=true; shift ;;
      --verbose|-v) verbose=true; shift ;;
      --help|-h)    _doctor_help; return 0 ;;
      *)            shift ;;
    esac
  done

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🩺 flow-cli Health Check${FLOW_COLORS[reset]}                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  local missing_required=()
  local missing_recommended=()
  local missing_optional=()

  # ──────────────────────────────────────────────────────────────
  # SHELL & CORE
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}🐚 SHELL${FLOW_COLORS[reset]}"
  _doctor_check_cmd "zsh" "" true
  _doctor_check_cmd "git" "" true
  echo ""

  # ──────────────────────────────────────────────────────────────
  # REQUIRED
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}⚡ REQUIRED${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(core functionality)${FLOW_COLORS[reset]}"
  _doctor_check_cmd "fzf" "brew install fzf" true || missing_required+=("fzf")
  echo ""

  # ──────────────────────────────────────────────────────────────
  # RECOMMENDED
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}✨ RECOMMENDED${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(enhanced experience)${FLOW_COLORS[reset]}"
  _doctor_check_cmd "eza" "brew install eza" false || missing_recommended+=("eza")
  _doctor_check_cmd "bat" "brew install bat" false || missing_recommended+=("bat")
  _doctor_check_cmd "zoxide" "brew install zoxide" false || missing_recommended+=("zoxide")
  _doctor_check_cmd "fd" "brew install fd" false || missing_recommended+=("fd")
  _doctor_check_cmd "rg" "brew install ripgrep" false || missing_recommended+=("ripgrep")
  echo ""

  # ──────────────────────────────────────────────────────────────
  # OPTIONAL
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}📦 OPTIONAL${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(nice to have)${FLOW_COLORS[reset]}"
  _doctor_check_cmd "dust" "brew install dust" false || missing_optional+=("dust")
  _doctor_check_cmd "duf" "brew install duf" false || missing_optional+=("duf")
  _doctor_check_cmd "btop" "brew install btop" false || missing_optional+=("btop")
  _doctor_check_cmd "delta" "brew install delta" false || missing_optional+=("delta")
  _doctor_check_cmd "gh" "brew install gh" false || missing_optional+=("gh")
  _doctor_check_cmd "jq" "brew install jq" false || missing_optional+=("jq")
  echo ""

  # ──────────────────────────────────────────────────────────────
  # INTEGRATIONS
  # ──────────────────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}🔌 INTEGRATIONS${FLOW_COLORS[reset]}"
  _doctor_check_cmd "atlas" "npm install -g @data-wise/atlas" false || missing_optional+=("atlas")

  # Check for radian (R console)
  if command -v R >/dev/null 2>&1; then
    _doctor_check_cmd "radian" "pip install radian" false || missing_optional+=("radian")
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
  # SUMMARY
  # ──────────────────────────────────────────────────────────────
  local total_missing=$((${#missing_required[@]} + ${#missing_recommended[@]}))

  if [[ $total_missing -eq 0 ]]; then
    echo "${FLOW_COLORS[success]}✓ All essential tools installed!${FLOW_COLORS[reset]}"
  else
    if [[ ${#missing_required[@]} -gt 0 ]]; then
      echo "${FLOW_COLORS[error]}⚠ Missing required: ${missing_required[*]}${FLOW_COLORS[reset]}"
    fi
    if [[ ${#missing_recommended[@]} -gt 0 ]]; then
      echo "${FLOW_COLORS[warning]}△ Missing recommended: ${missing_recommended[*]}${FLOW_COLORS[reset]}"
    fi
  fi
  echo ""

  # ──────────────────────────────────────────────────────────────
  # FIX SUGGESTIONS
  # ──────────────────────────────────────────────────────────────
  if [[ "$show_fix" == true ]] || [[ $total_missing -gt 0 ]]; then
    echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    if [[ ${#missing_required[@]} -gt 0 ]] || [[ ${#missing_recommended[@]} -gt 0 ]]; then
      echo "${FLOW_COLORS[bold]}Quick fix:${FLOW_COLORS[reset]}"
      echo "  ${FLOW_COLORS[accent]}brew bundle --file=$FLOW_PLUGIN_DIR/setup/Brewfile${FLOW_COLORS[reset]}"
      echo ""
      echo "${FLOW_COLORS[muted]}Or install individually:${FLOW_COLORS[reset]}"

      for tool in "${missing_required[@]}" "${missing_recommended[@]}"; do
        case "$tool" in
          ripgrep) echo "  brew install ripgrep" ;;
          atlas)   echo "  npm install -g @data-wise/atlas" ;;
          radian)  echo "  pip install radian" ;;
          *)       echo "  brew install $tool" ;;
        esac
      done
      echo ""
    fi
  fi
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

_doctor_check_cmd() {
  local cmd="$1"
  local install_hint="$2"
  local required="${3:-false}"

  if command -v "$cmd" >/dev/null 2>&1; then
    local version=""
    # Try to get version (suppress errors)
    version=$($cmd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}${version}${FLOW_COLORS[reset]}"
    return 0
  else
    if [[ "$required" == true ]]; then
      echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}← $install_hint${FLOW_COLORS[reset]}"
    else
      echo "  ${FLOW_COLORS[warning]}○${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}← $install_hint${FLOW_COLORS[reset]}"
    fi
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

_doctor_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}flow doctor${FLOW_COLORS[reset]} - Health Check                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  doctor [options]"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -f, --fix      Show install commands for missing tools"
  echo "  -v, --verbose  Show detailed version info"
  echo "  -h, --help     Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor           # Quick health check"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --fix     # Show how to fix issues"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow doctor      # Also works via flow command"
  echo ""
  echo "${FLOW_COLORS[bold]}INSTALL ALL TOOLS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}brew bundle --file=\$FLOW_PLUGIN_DIR/setup/Brewfile${FLOW_COLORS[reset]}"
  echo ""
}

# Alias for discoverability
alias flow-doctor='doctor'
