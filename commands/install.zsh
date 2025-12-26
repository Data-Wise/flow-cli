# commands/install.zsh - Tool installation with profiles
# Wrapper around brew/npm/pip with smart defaults

# ============================================================================
# INSTALL COMMAND
# ============================================================================

flow_install() {
  local dry_run=false
  local profile=""
  local category=""
  local force=false
  local verbose=false
  local tools=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n)     dry_run=true; shift ;;
      --profile|-p)     profile="$2"; shift 2 ;;
      --category|-c)    category="$2"; shift 2 ;;
      --force|-f)       force=true; shift ;;
      --verbose|-v)     verbose=true; shift ;;
      --list|-l)        _install_list_profiles; return 0 ;;
      --help|-h)        _install_help; return 0 ;;
      -*)               echo "Unknown option: $1"; return 1 ;;
      *)                tools+=("$1"); shift ;;
    esac
  done

  # Header
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📦 flow install${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  # Check for Homebrew
  if ! command -v brew >/dev/null 2>&1; then
    echo "${FLOW_COLORS[error]}Homebrew not found${FLOW_COLORS[reset]}"
    echo ""
    echo "Install Homebrew first:"
    echo "  ${FLOW_COLORS[accent]}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # Determine what to install
  local -a to_install=()

  if [[ -n "$profile" ]]; then
    # Install from profile
    to_install=($(_install_get_profile_tools "$profile"))
    if [[ ${#to_install[@]} -eq 0 ]]; then
      echo "${FLOW_COLORS[error]}Unknown profile: $profile${FLOW_COLORS[reset]}"
      echo "Available: minimal, developer, researcher, writer, full"
      return 1
    fi
    echo "${FLOW_COLORS[info]}Profile: $profile${FLOW_COLORS[reset]}"
  elif [[ -n "$category" ]]; then
    # Install from category
    to_install=($(_install_get_category_tools "$category"))
    if [[ ${#to_install[@]} -eq 0 ]]; then
      echo "${FLOW_COLORS[error]}Unknown category: $category${FLOW_COLORS[reset]}"
      echo "Available: core, git, dev, r, quarto, python, rust"
      return 1
    fi
    echo "${FLOW_COLORS[info]}Category: $category${FLOW_COLORS[reset]}"
  elif [[ ${#tools[@]} -gt 0 ]]; then
    # Install specific tools
    to_install=("${tools[@]}")
  else
    # No tools specified - show interactive menu
    _install_interactive
    return $?
  fi

  echo ""

  # Filter already installed (unless --force)
  local -a need_install=()
  local -a already_installed=()

  for tool in "${to_install[@]}"; do
    local cmd="${tool%%:*}"  # Handle tool:package format
    if ! $force && command -v "$cmd" >/dev/null 2>&1; then
      already_installed+=("$tool")
    else
      need_install+=("$tool")
    fi
  done

  # Show status
  if [[ ${#already_installed[@]} -gt 0 ]]; then
    echo "${FLOW_COLORS[success]}Already installed:${FLOW_COLORS[reset]}"
    for tool in "${already_installed[@]}"; do
      local cmd="${tool%%:*}"
      local ver=$($cmd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}$ver${FLOW_COLORS[reset]}"
    done
    echo ""
  fi

  if [[ ${#need_install[@]} -eq 0 ]]; then
    echo "${FLOW_COLORS[success]}All tools already installed!${FLOW_COLORS[reset]}"
    echo ""
    return 0
  fi

  # Show what will be installed
  echo "${FLOW_COLORS[info]}To install:${FLOW_COLORS[reset]}"
  for tool in "${need_install[@]}"; do
    local cmd="${tool%%:*}"
    local pkg="${tool#*:}"
    [[ "$pkg" == "$cmd" ]] && pkg=""
    if [[ -n "$pkg" ]]; then
      echo "  ${FLOW_COLORS[accent]}•${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}(brew install $pkg)${FLOW_COLORS[reset]}"
    else
      echo "  ${FLOW_COLORS[accent]}•${FLOW_COLORS[reset]} $cmd"
    fi
  done
  echo ""

  # Dry run mode
  if $dry_run; then
    echo "${FLOW_COLORS[warning]}Dry run - no changes made${FLOW_COLORS[reset]}"
    echo ""
    echo "Would run:"
    for tool in "${need_install[@]}"; do
      local pkg="${tool#*:}"
      [[ "$pkg" == "${tool%%:*}" ]] && pkg="${tool%%:*}"
      echo "  brew install $pkg"
    done
    echo ""
    return 0
  fi

  # Confirm
  echo -n "${FLOW_COLORS[info]}Install ${#need_install[@]} tool(s)?${FLOW_COLORS[reset]} [Y/n] "
  read -r response
  case "$response" in
    [nN]|[nN][oO])
      echo "Cancelled."
      return 0
      ;;
  esac

  echo ""

  # Install each tool
  local success=0
  local failed=0

  for tool in "${need_install[@]}"; do
    local cmd="${tool%%:*}"
    local pkg="${tool#*:}"
    [[ "$pkg" == "$cmd" ]] && pkg="$cmd"

    echo "${FLOW_COLORS[info]}Installing $cmd...${FLOW_COLORS[reset]}"

    if brew install "$pkg" 2>&1; then
      echo "${FLOW_COLORS[success]}✓ $cmd installed${FLOW_COLORS[reset]}"
      ((success++))
    else
      echo "${FLOW_COLORS[error]}✗ Failed to install $cmd${FLOW_COLORS[reset]}"
      ((failed++))
    fi
    echo ""
  done

  # Summary
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""
  if [[ $failed -eq 0 ]]; then
    echo "${FLOW_COLORS[success]}✓ Installed $success tool(s) successfully${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[warning]}Installed $success, failed $failed${FLOW_COLORS[reset]}"
  fi
  echo ""

  return $failed
}

# ============================================================================
# PROFILES
# ============================================================================

_install_get_profile_tools() {
  local profile="$1"

  case "$profile" in
    minimal)
      echo "fzf zoxide bat"
      ;;
    developer|dev)
      echo "fzf zoxide bat eza fd rg:ripgrep gh delta:git-delta jq"
      ;;
    researcher|research)
      echo "fzf zoxide bat eza fd rg:ripgrep gh quarto"
      ;;
    writer)
      echo "fzf bat pandoc quarto"
      ;;
    full|all)
      echo "fzf zoxide bat eza fd rg:ripgrep gh delta:git-delta jq dust duf btop pandoc quarto"
      ;;
    *)
      echo ""
      ;;
  esac
}

# ============================================================================
# CATEGORIES
# ============================================================================

_install_get_category_tools() {
  local category="$1"

  case "$category" in
    core|essential)
      echo "fzf zoxide bat eza"
      ;;
    git)
      echo "gh delta:git-delta git-lfs"
      ;;
    dev|development)
      echo "fd rg:ripgrep jq yq"
      ;;
    r)
      echo "r radian"
      ;;
    quarto|publishing)
      echo "quarto pandoc"
      ;;
    python|py)
      echo "python pyenv"
      ;;
    rust)
      echo "rust rustup"
      ;;
    node|js)
      echo "node nvm"
      ;;
    *)
      echo ""
      ;;
  esac
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

_install_interactive() {
  echo "${FLOW_COLORS[bold]}What would you like to install?${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[accent]}1)${FLOW_COLORS[reset]} Minimal      ${FLOW_COLORS[muted]}(fzf, zoxide, bat)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}2)${FLOW_COLORS[reset]} Developer    ${FLOW_COLORS[muted]}(+ eza, fd, rg, gh, delta, jq)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}3)${FLOW_COLORS[reset]} Researcher   ${FLOW_COLORS[muted]}(+ quarto)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}4)${FLOW_COLORS[reset]} Writer       ${FLOW_COLORS[muted]}(fzf, bat, pandoc, quarto)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}5)${FLOW_COLORS[reset]} Full         ${FLOW_COLORS[muted]}(everything)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}6)${FLOW_COLORS[reset]} Custom       ${FLOW_COLORS[muted]}(choose individual tools)${FLOW_COLORS[reset]}"
  echo ""
  echo -n "${FLOW_COLORS[info]}Choose [1-6]:${FLOW_COLORS[reset]} "
  read -r choice

  case "$choice" in
    1) flow_install --profile minimal ;;
    2) flow_install --profile developer ;;
    3) flow_install --profile researcher ;;
    4) flow_install --profile writer ;;
    5) flow_install --profile full ;;
    6) _install_custom ;;
    *) echo "Invalid choice"; return 1 ;;
  esac
}

_install_custom() {
  echo ""
  echo "${FLOW_COLORS[bold]}Select tools to install:${FLOW_COLORS[reset]}"
  echo ""

  local -a all_tools=(
    "fzf:Fuzzy finder"
    "zoxide:Smart cd"
    "bat:Better cat"
    "eza:Better ls"
    "fd:Better find"
    "rg:ripgrep:Better grep"
    "gh:GitHub CLI"
    "delta:git-delta:Better git diff"
    "jq:JSON processor"
    "dust:Better du"
    "duf:Better df"
    "btop:Better top"
    "quarto:Publishing"
    "pandoc:Document converter"
  )

  local -a selected=()
  local i=1

  for entry in "${all_tools[@]}"; do
    local tool="${entry%%:*}"
    local rest="${entry#*:}"
    local pkg="${rest%%:*}"
    local desc="${rest#*:}"
    [[ "$desc" == "$pkg" ]] && desc=""

    local status=""
    if command -v "$tool" >/dev/null 2>&1; then
      status="${FLOW_COLORS[success]}[installed]${FLOW_COLORS[reset]}"
    fi

    printf "  ${FLOW_COLORS[accent]}%2d)${FLOW_COLORS[reset]} %-10s %s %s\n" "$i" "$tool" "${FLOW_COLORS[muted]}$desc${FLOW_COLORS[reset]}" "$status"
    ((i++))
  done

  echo ""
  echo -n "${FLOW_COLORS[info]}Enter numbers (space-separated) or 'all':${FLOW_COLORS[reset]} "
  read -r selection

  if [[ "$selection" == "all" ]]; then
    for entry in "${all_tools[@]}"; do
      local tool="${entry%%:*}"
      selected+=("$tool")
    done
  else
    for num in $selection; do
      if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#all_tools[@]} )); then
        local entry="${all_tools[$num]}"
        local tool="${entry%%:*}"
        local rest="${entry#*:}"
        local pkg="${rest%%:*}"
        if [[ "$pkg" != "$tool" ]]; then
          selected+=("$tool:$pkg")
        else
          selected+=("$tool")
        fi
      fi
    done
  fi

  if [[ ${#selected[@]} -gt 0 ]]; then
    echo ""
    flow_install "${selected[@]}"
  else
    echo "No tools selected."
  fi
}

# ============================================================================
# LIST PROFILES
# ============================================================================

_install_list_profiles() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📦 Install Profiles${FLOW_COLORS[reset]}                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  echo "${FLOW_COLORS[bold]}PROFILES${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[accent]}minimal${FLOW_COLORS[reset]}      Essential tools only"
  echo "                 ${FLOW_COLORS[muted]}fzf, zoxide, bat${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[accent]}developer${FLOW_COLORS[reset]}    Full development setup"
  echo "                 ${FLOW_COLORS[muted]}fzf, zoxide, bat, eza, fd, rg, gh, delta, jq${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[accent]}researcher${FLOW_COLORS[reset]}   Academic/research tools"
  echo "                 ${FLOW_COLORS[muted]}fzf, zoxide, bat, eza, fd, rg, gh, quarto${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[accent]}writer${FLOW_COLORS[reset]}       Writing and publishing"
  echo "                 ${FLOW_COLORS[muted]}fzf, bat, pandoc, quarto${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[accent]}full${FLOW_COLORS[reset]}         Everything"
  echo "                 ${FLOW_COLORS[muted]}All available tools${FLOW_COLORS[reset]}"
  echo ""

  echo "${FLOW_COLORS[bold]}CATEGORIES${FLOW_COLORS[reset]}"
  echo ""
  echo "  ${FLOW_COLORS[accent]}core${FLOW_COLORS[reset]}         fzf, zoxide, bat, eza"
  echo "  ${FLOW_COLORS[accent]}git${FLOW_COLORS[reset]}          gh, delta, git-lfs"
  echo "  ${FLOW_COLORS[accent]}dev${FLOW_COLORS[reset]}          fd, rg, jq, yq"
  echo "  ${FLOW_COLORS[accent]}r${FLOW_COLORS[reset]}            r, radian"
  echo "  ${FLOW_COLORS[accent]}quarto${FLOW_COLORS[reset]}       quarto, pandoc"
  echo "  ${FLOW_COLORS[accent]}python${FLOW_COLORS[reset]}       python, pyenv"
  echo "  ${FLOW_COLORS[accent]}rust${FLOW_COLORS[reset]}         rust, rustup"
  echo ""

  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow install --profile developer"
  echo "  flow install --category git"
  echo "  flow install fzf bat eza"
  echo ""
}

# ============================================================================
# HELP
# ============================================================================

_install_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📦 flow install${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow install [options] [tools...]"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -p, --profile <name>   Install from profile"
  echo "  -c, --category <name>  Install from category"
  echo "  -n, --dry-run          Show what would be installed"
  echo "  -f, --force            Reinstall even if present"
  echo "  -l, --list             List available profiles"
  echo "  -v, --verbose          Verbose output"
  echo "  -h, --help             Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}PROFILES${FLOW_COLORS[reset]}"
  echo "  minimal      Essential tools (fzf, zoxide, bat)"
  echo "  developer    Full dev setup (+ eza, fd, rg, gh, delta)"
  echo "  researcher   Academic tools (+ quarto)"
  echo "  writer       Publishing (fzf, bat, pandoc, quarto)"
  echo "  full         Everything"
  echo ""
  echo "${FLOW_COLORS[bold]}CATEGORIES${FLOW_COLORS[reset]}"
  echo "  core, git, dev, r, quarto, python, rust, node"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow install                    # Interactive mode"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow install fzf bat eza        # Specific tools"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow install --profile developer # Install profile"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow install --category git     # Install category"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow install --dry-run --profile full"
  echo ""
}

# ============================================================================
# ALIASES
# ============================================================================

alias install='flow_install'
