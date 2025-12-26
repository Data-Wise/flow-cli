# commands/upgrade.zsh - Update flow-cli and dependencies
# Self-update, tool updates, and plugin updates

# ============================================================================
# UPGRADE COMMAND
# ============================================================================

flow_upgrade() {
  local target="self"    # self, tools, plugins, all
  local check_only=false
  local verbose=false
  local force=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      self|flow)       target="self"; shift ;;
      tools)           target="tools"; shift ;;
      plugins)         target="plugins"; shift ;;
      all)             target="all"; shift ;;
      --check|-c)      check_only=true; shift ;;
      --changelog)     _upgrade_show_changelog; return 0 ;;
      --force|-f)      force=true; shift ;;
      --verbose|-v)    verbose=true; shift ;;
      --help|-h)       _upgrade_help; return 0 ;;
      *)               shift ;;
    esac
  done

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}⬆️  flow upgrade${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  case "$target" in
    self)
      _upgrade_flow_cli "$check_only" "$verbose" "$force"
      ;;
    tools)
      _upgrade_tools "$check_only" "$verbose"
      ;;
    plugins)
      _upgrade_plugins "$check_only" "$verbose"
      ;;
    all)
      _upgrade_flow_cli "$check_only" "$verbose" "$force"
      echo ""
      _upgrade_tools "$check_only" "$verbose"
      echo ""
      _upgrade_plugins "$check_only" "$verbose"
      ;;
  esac
}

# ============================================================================
# SELF UPDATE
# ============================================================================

_upgrade_flow_cli() {
  local check_only="${1:-false}"
  local verbose="${2:-false}"
  local force="${3:-false}"

  local plugin_dir="${FLOW_PLUGIN_DIR:-$(cd "${0:h}/.." && pwd)}"
  local current_version="${FLOW_VERSION:-unknown}"

  echo "${FLOW_COLORS[bold]}🌊 flow-cli${FLOW_COLORS[reset]}"
  echo ""
  echo "  Current: v$current_version"
  echo "  Location: $plugin_dir"
  echo ""

  # Check if it's a git repo
  if [[ ! -d "$plugin_dir/.git" ]]; then
    echo "  ${FLOW_COLORS[warning]}△ Not a git repository - manual update required${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # Check for updates
  echo "  ${FLOW_COLORS[muted]}Checking for updates...${FLOW_COLORS[reset]}"

  (
    cd "$plugin_dir"
    git fetch origin main --quiet 2>/dev/null
  )

  local local_hash=$(cd "$plugin_dir" && git rev-parse HEAD 2>/dev/null)
  local remote_hash=$(cd "$plugin_dir" && git rev-parse origin/main 2>/dev/null)

  if [[ "$local_hash" == "$remote_hash" ]]; then
    echo "  ${FLOW_COLORS[success]}✓ Already up to date${FLOW_COLORS[reset]}"
    echo ""
    return 0
  fi

  # Show what's new
  local commits_behind=$(cd "$plugin_dir" && git rev-list --count HEAD..origin/main 2>/dev/null)
  echo "  ${FLOW_COLORS[info]}⬆ $commits_behind commit(s) available${FLOW_COLORS[reset]}"

  if $verbose; then
    echo ""
    echo "  ${FLOW_COLORS[muted]}Recent changes:${FLOW_COLORS[reset]}"
    (
      cd "$plugin_dir"
      git log --oneline HEAD..origin/main 2>/dev/null | head -5 | while read line; do
        echo "    ${FLOW_COLORS[muted]}$line${FLOW_COLORS[reset]}"
      done
    )
  fi

  echo ""

  # Check only mode
  if $check_only; then
    echo "  ${FLOW_COLORS[muted]}Run 'flow upgrade' to update${FLOW_COLORS[reset]}"
    return 0
  fi

  # Confirm update
  if ! $force; then
    echo -n "  ${FLOW_COLORS[info]}Update now?${FLOW_COLORS[reset]} [Y/n] "
    read -r response
    case "$response" in
      [nN]|[nN][oO])
        echo "  Cancelled."
        return 0
        ;;
    esac
  fi

  # Perform update
  echo ""
  echo "  ${FLOW_COLORS[info]}Updating...${FLOW_COLORS[reset]}"

  (
    cd "$plugin_dir"

    # Stash local changes
    local has_changes=false
    if ! git diff --quiet || ! git diff --cached --quiet; then
      has_changes=true
      git stash push -m "flow upgrade auto-stash" --quiet 2>/dev/null
    fi

    # Pull updates
    if git pull --rebase origin main --quiet 2>/dev/null; then
      echo "  ${FLOW_COLORS[success]}✓ Updated to latest${FLOW_COLORS[reset]}"
    else
      echo "  ${FLOW_COLORS[error]}✗ Update failed${FLOW_COLORS[reset]}"
      return 1
    fi

    # Restore stash
    if $has_changes; then
      git stash pop --quiet 2>/dev/null
    fi
  )

  # Get new version
  local new_version=$(cd "$plugin_dir" && grep -m1 'FLOW_VERSION=' flow.plugin.zsh 2>/dev/null | cut -d'"' -f2)
  echo "  New version: v${new_version:-$current_version}"
  echo ""

  echo "  ${FLOW_COLORS[muted]}Reload shell to apply: exec zsh${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# TOOL UPDATES
# ============================================================================

_upgrade_tools() {
  local check_only="${1:-false}"
  local verbose="${2:-false}"

  echo "${FLOW_COLORS[bold]}📦 Homebrew Tools${FLOW_COLORS[reset]}"
  echo ""

  if ! command -v brew >/dev/null 2>&1; then
    echo "  ${FLOW_COLORS[error]}Homebrew not found${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check for outdated packages
  echo "  ${FLOW_COLORS[muted]}Checking for updates...${FLOW_COLORS[reset]}"

  local outdated=$(brew outdated --quiet 2>/dev/null)
  local count=$(echo "$outdated" | grep -c . 2>/dev/null || echo 0)

  if [[ -z "$outdated" ]] || [[ $count -eq 0 ]]; then
    echo "  ${FLOW_COLORS[success]}✓ All tools up to date${FLOW_COLORS[reset]}"
    echo ""
    return 0
  fi

  echo "  ${FLOW_COLORS[info]}$count package(s) have updates:${FLOW_COLORS[reset]}"
  echo ""

  # Show outdated packages
  for pkg in $outdated; do
    local current=$(brew list --versions "$pkg" 2>/dev/null | awk '{print $2}')
    local latest=$(brew info "$pkg" --json 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null)
    echo "    ${FLOW_COLORS[accent]}$pkg${FLOW_COLORS[reset]} $current → $latest"
  done

  echo ""

  if $check_only; then
    echo "  ${FLOW_COLORS[muted]}Run 'flow upgrade tools' to update${FLOW_COLORS[reset]}"
    return 0
  fi

  # Confirm
  echo -n "  ${FLOW_COLORS[info]}Upgrade all?${FLOW_COLORS[reset]} [Y/n] "
  read -r response
  case "$response" in
    [nN]|[nN][oO])
      echo "  Cancelled."
      return 0
      ;;
  esac

  echo ""
  echo "  ${FLOW_COLORS[info]}Upgrading...${FLOW_COLORS[reset]}"
  echo ""

  if brew upgrade 2>&1; then
    echo ""
    echo "  ${FLOW_COLORS[success]}✓ Tools upgraded${FLOW_COLORS[reset]}"
  else
    echo ""
    echo "  ${FLOW_COLORS[error]}✗ Some upgrades failed${FLOW_COLORS[reset]}"
  fi
  echo ""
}

# ============================================================================
# PLUGIN UPDATES
# ============================================================================

_upgrade_plugins() {
  local check_only="${1:-false}"
  local verbose="${2:-false}"

  echo "${FLOW_COLORS[bold]}🔌 ZSH Plugins${FLOW_COLORS[reset]}"
  echo ""

  # Check for antidote
  if command -v antidote >/dev/null 2>&1; then
    echo "  Using: antidote"
    echo ""

    if $check_only; then
      echo "  ${FLOW_COLORS[muted]}Run 'flow upgrade plugins' to update${FLOW_COLORS[reset]}"
      return 0
    fi

    echo "  ${FLOW_COLORS[info]}Updating plugins...${FLOW_COLORS[reset]}"
    echo ""

    if antidote update 2>&1; then
      echo ""
      echo "  ${FLOW_COLORS[success]}✓ Plugins updated${FLOW_COLORS[reset]}"
    else
      echo ""
      echo "  ${FLOW_COLORS[error]}✗ Update failed${FLOW_COLORS[reset]}"
    fi

  elif command -v zinit >/dev/null 2>&1; then
    echo "  Using: zinit"
    echo ""

    if $check_only; then
      echo "  ${FLOW_COLORS[muted]}Run 'zinit update' to update${FLOW_COLORS[reset]}"
      return 0
    fi

    echo "  ${FLOW_COLORS[info]}Updating plugins...${FLOW_COLORS[reset]}"
    zinit update --all 2>&1

  elif [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "  Using: oh-my-zsh"
    echo ""

    if $check_only; then
      echo "  ${FLOW_COLORS[muted]}Run 'omz update' to update${FLOW_COLORS[reset]}"
      return 0
    fi

    echo "  ${FLOW_COLORS[info]}Updating oh-my-zsh...${FLOW_COLORS[reset]}"
    (
      cd "$HOME/.oh-my-zsh"
      git pull --rebase origin master 2>&1
    )

  else
    echo "  ${FLOW_COLORS[muted]}No plugin manager detected${FLOW_COLORS[reset]}"
  fi

  echo ""
}

# ============================================================================
# CHANGELOG
# ============================================================================

_upgrade_show_changelog() {
  local plugin_dir="${FLOW_PLUGIN_DIR:-$(cd "${0:h}/.." && pwd)}"

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📜 Changelog${FLOW_COLORS[reset]}                                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  # Show CHANGELOG.md if exists
  if [[ -f "$plugin_dir/CHANGELOG.md" ]]; then
    head -50 "$plugin_dir/CHANGELOG.md"
  elif [[ -f "$plugin_dir/docs/CHANGELOG.md" ]]; then
    head -50 "$plugin_dir/docs/CHANGELOG.md"
  else
    # Fall back to git log
    echo "${FLOW_COLORS[bold]}Recent commits:${FLOW_COLORS[reset]}"
    echo ""
    (
      cd "$plugin_dir"
      git log --oneline -20 2>/dev/null | while read line; do
        echo "  $line"
      done
    )
  fi

  echo ""
}

# ============================================================================
# HELP
# ============================================================================

_upgrade_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}⬆️  flow upgrade${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow upgrade [target] [options]"
  echo ""
  echo "${FLOW_COLORS[bold]}TARGETS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}self${FLOW_COLORS[reset]}        Update flow-cli itself (default)"
  echo "  ${FLOW_COLORS[accent]}tools${FLOW_COLORS[reset]}       Update Homebrew packages"
  echo "  ${FLOW_COLORS[accent]}plugins${FLOW_COLORS[reset]}     Update ZSH plugins"
  echo "  ${FLOW_COLORS[accent]}all${FLOW_COLORS[reset]}         Update everything"
  echo ""
  echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
  echo "  -c, --check      Check for updates without installing"
  echo "  --changelog      Show what's new"
  echo "  -f, --force      Skip confirmation prompts"
  echo "  -v, --verbose    Show detailed output"
  echo "  -h, --help       Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow upgrade              # Update flow-cli"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow upgrade --check      # Check for updates"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow upgrade tools        # Update brew packages"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow upgrade all          # Update everything"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow upgrade --changelog  # See what's new"
  echo ""
}

# ============================================================================
# ALIASES
# ============================================================================

alias upgrade='flow_upgrade'
