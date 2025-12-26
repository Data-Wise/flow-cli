# commands/setup.zsh - Interactive first-time setup wizard
# ADHD-friendly guided setup experience

# ============================================================================
# SETUP COMMAND
# ============================================================================

setup() {
  local mode="${1:-}"

  case "$mode" in
    --quick|-q)      _setup_quick ;;
    --full|-f)       _setup_full ;;
    --help|-h|help)  _setup_help ;;
    *)               _setup_interactive ;;
  esac
}

# ============================================================================
# INTERACTIVE WIZARD
# ============================================================================

_setup_interactive() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🚀 flow-cli Setup Wizard${FLOW_COLORS[reset]}                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "  Welcome! Let's get you set up with flow-cli."
  echo ""
  echo "  ${FLOW_COLORS[muted]}This wizard will:${FLOW_COLORS[reset]}"
  echo "  • Check your current setup"
  echo "  • Install recommended tools"
  echo "  • Configure your environment"
  echo ""

  # Step 1: Health check
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[bold]}Step 1: Health Check${FLOW_COLORS[reset]}"
  echo ""

  # Run doctor in quiet mode to count issues
  local issues=0
  command -v fzf >/dev/null 2>&1 || ((issues++))
  command -v eza >/dev/null 2>&1 || ((issues++))
  command -v bat >/dev/null 2>&1 || ((issues++))
  command -v fd >/dev/null 2>&1 || ((issues++))
  command -v rg >/dev/null 2>&1 || ((issues++))
  command -v zoxide >/dev/null 2>&1 || ((issues++))

  if [[ $issues -eq 0 ]]; then
    echo "  ${FLOW_COLORS[success]}✓ All recommended tools installed!${FLOW_COLORS[reset]}"
    echo ""
    echo "  You're all set! Run ${FLOW_COLORS[accent]}dash${FLOW_COLORS[reset]} to see your dashboard."
    echo ""
    return 0
  fi

  echo "  ${FLOW_COLORS[warning]}Found $issues missing tool(s)${FLOW_COLORS[reset]}"
  echo ""

  # Step 2: Offer to install
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[bold]}Step 2: Install Tools${FLOW_COLORS[reset]}"
  echo ""

  local choices=(
    "1) Install all recommended tools (Homebrew)"
    "2) Choose which tools to install"
    "3) Skip for now"
  )

  for choice in "${choices[@]}"; do
    echo "  $choice"
  done
  echo ""

  echo -n "  ${FLOW_COLORS[info]}?${FLOW_COLORS[reset]} Your choice [1-3]: "
  read -r response

  case "$response" in
    1)
      _setup_install_all
      ;;
    2)
      _setup_choose_tools
      ;;
    3)
      echo ""
      echo "  ${FLOW_COLORS[muted]}Skipped. Run 'setup' anytime to continue.${FLOW_COLORS[reset]}"
      echo ""
      ;;
    *)
      echo ""
      echo "  ${FLOW_COLORS[muted]}Invalid choice. Run 'setup' to try again.${FLOW_COLORS[reset]}"
      echo ""
      ;;
  esac

  # Step 3: Configuration
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[bold]}Step 3: Configuration${FLOW_COLORS[reset]}"
  echo ""

  # Check if FLOW_PROJECTS_ROOT is set
  if [[ -z "$FLOW_PROJECTS_ROOT" ]]; then
    echo "  ${FLOW_COLORS[warning]}⚠ FLOW_PROJECTS_ROOT not set${FLOW_COLORS[reset]}"
    echo ""
    echo "  Add to your .zshrc:"
    echo "  ${FLOW_COLORS[accent]}export FLOW_PROJECTS_ROOT=\"\$HOME/projects\"${FLOW_COLORS[reset]}"
    echo ""
  else
    echo "  ${FLOW_COLORS[success]}✓ FLOW_PROJECTS_ROOT:${FLOW_COLORS[reset]} $FLOW_PROJECTS_ROOT"
  fi

  # Check plugin loaded
  if [[ -n "$FLOW_PLUGIN_LOADED" ]]; then
    echo "  ${FLOW_COLORS[success]}✓ flow-cli loaded:${FLOW_COLORS[reset]} v${FLOW_VERSION:-unknown}"
  else
    echo "  ${FLOW_COLORS[error]}✗ flow-cli not loaded${FLOW_COLORS[reset]}"
  fi

  echo ""

  # Step 4: Next steps
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[bold]}🎉 Setup Complete!${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[muted]}Try these commands:${FLOW_COLORS[reset]}"
  echo "  • ${FLOW_COLORS[accent]}dash${FLOW_COLORS[reset]}        - See your project dashboard"
  echo "  • ${FLOW_COLORS[accent]}work <name>${FLOW_COLORS[reset]} - Start working on a project"
  echo "  • ${FLOW_COLORS[accent]}doctor${FLOW_COLORS[reset]}      - Check system health"
  echo "  • ${FLOW_COLORS[accent]}flow help${FLOW_COLORS[reset]}   - Get help with commands"
  echo ""
}

# ============================================================================
# INSTALL HELPERS
# ============================================================================

_setup_install_all() {
  echo ""
  echo "  ${FLOW_COLORS[info]}Installing all recommended tools...${FLOW_COLORS[reset]}"
  echo ""

  # Check for Homebrew
  if ! command -v brew >/dev/null 2>&1; then
    echo "  ${FLOW_COLORS[error]}✗ Homebrew not found${FLOW_COLORS[reset]}"
    echo ""
    echo "  Install Homebrew first:"
    echo "  ${FLOW_COLORS[accent]}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # Install via Brewfile if it exists
  local brewfile="$FLOW_PLUGIN_DIR/setup/Brewfile"
  if [[ -f "$brewfile" ]]; then
    echo "  ${FLOW_COLORS[muted]}Using $brewfile${FLOW_COLORS[reset]}"
    brew bundle --file="$brewfile"
  else
    # Fallback: install individually
    local tools=(fzf eza bat fd ripgrep zoxide)
    for tool in "${tools[@]}"; do
      if ! command -v "$tool" >/dev/null 2>&1; then
        echo "  Installing $tool..."
        brew install "$tool"
      fi
    done
  fi

  echo ""
  echo "  ${FLOW_COLORS[success]}✓ Installation complete!${FLOW_COLORS[reset]}"
  echo ""
}

_setup_choose_tools() {
  echo ""

  local -A tools=(
    [fzf]="Fuzzy finder (REQUIRED for project picker)"
    [eza]="Modern ls replacement (prettier file listings)"
    [bat]="Cat with syntax highlighting"
    [fd]="Fast find replacement"
    [rg]="Fast grep replacement (ripgrep)"
    [zoxide]="Smart cd with history"
  )

  for tool desc in "${(@kv)tools}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "  ${FLOW_COLORS[success]}✓ $tool${FLOW_COLORS[reset]} - $desc"
    else
      echo -n "  ${FLOW_COLORS[warning]}○ $tool${FLOW_COLORS[reset]} - $desc [install? y/N] "
      read -r response
      if [[ "$response" == "y" || "$response" == "Y" ]]; then
        local pkg="$tool"
        [[ "$tool" == "rg" ]] && pkg="ripgrep"
        brew install "$pkg"
        echo "    ${FLOW_COLORS[success]}✓ Installed${FLOW_COLORS[reset]}"
      fi
    fi
  done

  echo ""
}

# ============================================================================
# QUICK SETUP (Non-interactive)
# ============================================================================

_setup_quick() {
  echo ""
  echo "  ${FLOW_COLORS[bold]}Quick Setup${FLOW_COLORS[reset]}"
  echo ""

  # Just run doctor --fix -y
  doctor --fix -y
}

# ============================================================================
# FULL SETUP (Everything)
# ============================================================================

_setup_full() {
  echo ""
  echo "  ${FLOW_COLORS[bold]}Full Setup${FLOW_COLORS[reset]}"
  echo ""

  # Run interactive setup
  _setup_interactive

  # Then show extra options
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[bold]}Additional Configuration${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[muted]}Optional integrations:${FLOW_COLORS[reset]}"
  echo "  • ${FLOW_COLORS[accent]}npm install -g @data-wise/atlas${FLOW_COLORS[reset]} - Enhanced state management"
  echo "  • ${FLOW_COLORS[accent]}pip install radian${FLOW_COLORS[reset]} - Better R console"
  echo ""
}

# ============================================================================
# HELP
# ============================================================================

_setup_help() {
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
${_C_BOLD}│ 🚀 SETUP - First-Time Setup Wizard          │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} setup [option]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of usage)${_C_NC}:
  ${_C_CYAN}setup${_C_NC}              Interactive setup wizard
  ${_C_CYAN}setup --quick${_C_NC}      Auto-install all missing tools

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} setup                   ${_C_DIM}# Interactive wizard${_C_NC}
  ${_C_DIM}\$${_C_NC} setup --quick           ${_C_DIM}# Auto-install${_C_NC}
  ${_C_DIM}\$${_C_NC} setup --full            ${_C_DIM}# Full setup + extras${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}(none)${_C_NC}            Interactive wizard (default)
  ${_C_CYAN}-q, --quick${_C_NC}       Quick non-interactive install
  ${_C_CYAN}-f, --full${_C_NC}        Full setup with all options
  ${_C_CYAN}-h, --help${_C_NC}        Show this help

${_C_BLUE}📦 WHAT GETS INSTALLED${_C_NC}:
  ${_C_CYAN}fzf${_C_NC}               Fuzzy finder (required)
  ${_C_CYAN}eza${_C_NC}               Modern ls replacement
  ${_C_CYAN}bat${_C_NC}               Cat with syntax highlighting
  ${_C_CYAN}fd${_C_NC}                Fast find replacement
  ${_C_CYAN}ripgrep${_C_NC}           Fast grep replacement
  ${_C_CYAN}zoxide${_C_NC}            Smart cd with history

${_C_MAGENTA}💡 TIP${_C_NC}: Run 'doctor' to check health anytime

${_C_DIM}See also:${_C_NC} doctor help, dash help
"
}

# Alias
alias flow-setup='setup'
