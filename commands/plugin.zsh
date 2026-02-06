# commands/plugin.zsh - Plugin management commands
# Provides list, enable, disable, create, install, remove

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

flow_plugin() {
  local cmd="${1:-list}"
  shift 2>/dev/null

  case "$cmd" in
    list|ls)       _flow_plugin_cmd_list "$@" ;;
    enable)        _flow_plugin_cmd_enable "$@" ;;
    disable)       _flow_plugin_cmd_disable "$@" ;;
    create|new)    _flow_plugin_cmd_create "$@" ;;
    install|add)   _flow_plugin_cmd_install "$@" ;;
    remove|rm)     _flow_plugin_cmd_remove "$@" ;;
    info)          _flow_plugin_cmd_info "$@" ;;
    hooks)         _flow_plugin_cmd_hooks "$@" ;;
    path)          _flow_plugin_cmd_path "$@" ;;
    help|--help|-h) _flow_plugin_help ;;
    *)
      _flow_log_error "Unknown plugin command: $cmd"
      _flow_plugin_help
      return 1
      ;;
  esac
}

# ============================================================================
# COMMAND IMPLEMENTATIONS
# ============================================================================

# List plugins
_flow_plugin_cmd_list() {
  local show_all=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a|--all|--available) show_all=true; shift ;;
      -h|--help) _flow_plugin_list_help; return 0 ;;
      *) shift ;;
    esac
  done

  _flow_plugin_list "$show_all"
}

# Enable a plugin
_flow_plugin_cmd_enable() {
  local name="$1"

  if [[ -z "$name" ]]; then
    _flow_log_error "Usage: flow plugin enable <name>"
    return 1
  fi

  # Check if plugin exists
  local -a discovered
  discovered=("${(@f)$(_flow_plugin_discover)}")

  local found=false
  for plugin_path in "${discovered[@]}"; do
    local metadata=$(_flow_plugin_metadata "$plugin_path")
    local pname="${metadata%%|*}"
    if [[ "$pname" == "$name" ]]; then
      found=true
      break
    fi
  done

  if [[ "$found" == "false" ]]; then
    _flow_log_error "Plugin not found: $name"
    return 1
  fi

  _flow_plugin_enable "$name"
  echo ""
  echo "${FLOW_COLORS[info]}Reload your shell to load the plugin: exec zsh${FLOW_COLORS[reset]}"
}

# Disable a plugin
_flow_plugin_cmd_disable() {
  local name="$1"

  if [[ -z "$name" ]]; then
    _flow_log_error "Usage: flow plugin disable <name>"
    return 1
  fi

  if ! _flow_plugin_exists "$name"; then
    _flow_log_error "Plugin not loaded: $name"
    return 1
  fi

  _flow_plugin_disable "$name"
}

# Create a new plugin
_flow_plugin_cmd_create() {
  local name=""
  local dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--dir) dir="$2"; shift 2 ;;
      -h|--help) _flow_plugin_create_help; return 0 ;;
      -*) _flow_log_error "Unknown option: $1"; return 1 ;;
      *) name="$1"; shift ;;
    esac
  done

  if [[ -z "$name" ]]; then
    echo ""
    echo "${FLOW_COLORS[header]}CREATE NEW PLUGIN${FLOW_COLORS[reset]}"
    echo ""
    echo -n "  Plugin name: "
    read -r name
  fi

  if [[ -z "$name" ]]; then
    _flow_log_error "Plugin name is required"
    return 1
  fi

  # Validate name (alphanumeric and hyphens only)
  if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    _flow_log_error "Invalid plugin name. Use letters, numbers, hyphens, underscores."
    return 1
  fi

  _flow_plugin_create "$name" "$dir"
}

# Install a plugin (from path or git)
_flow_plugin_cmd_install() {
  local source="$1"
  local dev_mode=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dev) dev_mode=true; shift ;;
      -h|--help) _flow_plugin_install_help; return 0 ;;
      -*) _flow_log_error "Unknown option: $1"; return 1 ;;
      *) source="$1"; shift ;;
    esac
  done

  if [[ -z "$source" ]]; then
    _flow_log_error "Usage: flow plugin install <source>"
    echo ""
    echo "Sources:"
    echo "  /path/to/plugin     Local directory"
    echo "  gh:user/repo        GitHub repository"
    echo "  --dev .             Current directory (dev mode)"
    return 1
  fi

  local plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugins"

  # Handle GitHub source
  if [[ "$source" == gh:* ]]; then
    local repo="${source#gh:}"
    local name="${repo##*/}"
    name="${name#flow-plugin-}"  # Remove common prefix

    echo "Installing from GitHub: $repo"

    if ! command -v git >/dev/null 2>&1; then
      _flow_log_error "git is required to install from GitHub"
      return 1
    fi

    local target="$plugin_dir/$name"

    if [[ -d "$target" ]]; then
      _flow_log_error "Plugin already installed: $name"
      echo "To update: cd $target && git pull"
      return 1
    fi

    if git clone "https://github.com/$repo.git" "$target" 2>/dev/null; then
      _flow_log_success "Installed: $name"
      echo ""
      echo "Reload your shell to load the plugin: exec zsh"
    else
      _flow_log_error "Failed to clone repository"
      return 1
    fi
    return 0
  fi

  # Handle dev mode (symlink current directory)
  if [[ "$dev_mode" == "true" ]]; then
    source="${source:-.}"
    source="${source:A}"  # Absolute path

    if [[ ! -f "$source/main.zsh" && ! -f "$source/plugin.json" ]]; then
      _flow_log_error "Not a valid plugin directory (missing main.zsh or plugin.json)"
      return 1
    fi

    local name="${source:t}"
    local target="$plugin_dir/$name"

    if [[ -e "$target" ]]; then
      _flow_log_error "Plugin already exists: $target"
      return 1
    fi

    ln -s "$source" "$target"
    _flow_log_success "Installed (dev mode): $name -> $source"
    echo ""
    echo "Reload your shell to load the plugin: exec zsh"
    return 0
  fi

  # Handle local path
  if [[ -d "$source" ]]; then
    local name="${source:t}"
    local target="$plugin_dir/$name"

    if [[ -e "$target" ]]; then
      _flow_log_error "Plugin already exists: $target"
      return 1
    fi

    cp -r "$source" "$target"
    _flow_log_success "Installed: $name"
    echo ""
    echo "Reload your shell to load the plugin: exec zsh"
    return 0
  fi

  _flow_log_error "Source not found: $source"
  return 1
}

# Remove a plugin
_flow_plugin_cmd_remove() {
  local name="$1"
  local force=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force) force=true; shift ;;
      -h|--help) echo "Usage: flow plugin remove [-f] <name>"; return 0 ;;
      -*) _flow_log_error "Unknown option: $1"; return 1 ;;
      *) name="$1"; shift ;;
    esac
  done

  if [[ -z "$name" ]]; then
    _flow_log_error "Usage: flow plugin remove <name>"
    return 1
  fi

  local plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugins"
  local target="$plugin_dir/$name"

  if [[ ! -e "$target" ]]; then
    # Check if it's a bundled plugin
    if [[ -e "${FLOW_PLUGIN_DIR}/plugins/$name" ]]; then
      _flow_log_error "Cannot remove bundled plugin: $name"
      echo "Use 'flow plugin disable $name' instead"
      return 1
    fi

    _flow_log_error "Plugin not found: $name"
    return 1
  fi

  # Confirm unless forced
  if [[ "$force" != "true" ]]; then
    if ! _flow_confirm "Remove plugin '$name'?"; then
      echo "Cancelled"
      return 0
    fi
  fi

  # Check if it's a symlink (dev mode)
  if [[ -L "$target" ]]; then
    rm "$target"
    _flow_log_success "Removed symlink: $name"
  else
    rm -rf "$target"
    _flow_log_success "Removed: $name"
  fi

  echo ""
  echo "Reload your shell to unload the plugin: exec zsh"
}

# Show plugin info
_flow_plugin_cmd_info() {
  local name="$1"

  if [[ -z "$name" ]]; then
    _flow_log_error "Usage: flow plugin info <name>"
    return 1
  fi

  if ! _flow_plugin_exists "$name"; then
    _flow_log_error "Plugin not loaded: $name"
    return 1
  fi

  local plugin_path="${_FLOW_PLUGINS[$name]}"
  local version="${_FLOW_PLUGIN_VERSIONS[$name]}"
  local enabled="${_FLOW_PLUGIN_ENABLED[$name]:-1}"

  echo ""
  echo "${FLOW_COLORS[header]}PLUGIN: $name${FLOW_COLORS[reset]}"
  echo ""
  echo "  Version:  $version"
  echo "  Path:     $plugin_path"
  echo "  Enabled:  $([[ "$enabled" == "1" ]] && echo "yes" || echo "no")"

  # Show plugin.json info if available
  if [[ -f "$plugin_path/plugin.json" ]] && command -v jq >/dev/null 2>&1; then
    local description=$(jq -r '.description // empty' "$plugin_path/plugin.json")
    local author=$(jq -r '.author // empty' "$plugin_path/plugin.json")
    local -a commands=($(jq -r '.commands[]? // empty' "$plugin_path/plugin.json"))
    local -a tools=($(jq -r '.dependencies.tools[]? // empty' "$plugin_path/plugin.json"))

    [[ -n "$description" ]] && echo "  Desc:     $description"
    [[ -n "$author" ]] && echo "  Author:   $author"

    if (( ${#commands[@]} > 0 )); then
      echo "  Commands: ${commands[*]}"
    fi

    if (( ${#tools[@]} > 0 )); then
      echo "  Requires: ${tools[*]}"
    fi
  fi

  # Show registered hooks
  local has_hooks=false
  for event in "${FLOW_HOOK_EVENTS[@]}"; do
    local callbacks="${_FLOW_HOOKS[$event]:-}"
    if [[ "$callbacks" == *"_${name}_"* ]]; then
      if [[ "$has_hooks" == "false" ]]; then
        echo "  Hooks:"
        has_hooks=true
      fi
      echo "    - $event"
    fi
  done

  echo ""
}

# Show registered hooks
_flow_plugin_cmd_hooks() {
  _flow_hook_list
}

# Show plugin paths
_flow_plugin_cmd_path() {
  echo ""
  echo "${FLOW_COLORS[header]}PLUGIN SEARCH PATHS${FLOW_COLORS[reset]}"
  echo ""

  local idx=1
  for path in "${FLOW_PLUGIN_PATHS[@]}"; do
    [[ -z "$path" ]] && continue

    local status="✓"
    local color="${FLOW_COLORS[success]}"
    if [[ ! -d "$path" ]]; then
      status="○"
      color="${FLOW_COLORS[muted]}"
    fi

    echo "  $idx. $status $color$path${FLOW_COLORS[reset]}"
    ((idx++))
  done

  echo ""
  echo "${FLOW_COLORS[muted]}User plugins: ${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugins/${FLOW_COLORS[reset]}"
  echo ""
}

# ============================================================================
# HELP
# ============================================================================

_flow_plugin_help() {
  echo ""
  echo "${FLOW_COLORS[bold]}flow plugin${FLOW_COLORS[reset]} - Manage flow-cli plugins"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow plugin <command> [options]"
  echo ""
  echo "${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}"
  echo "  list [-a]           List installed plugins (-a: show all discovered)"
  echo "  enable <name>       Enable a disabled plugin"
  echo "  disable <name>      Disable a plugin"
  echo "  create <name>       Create a new plugin from template"
  echo "  install <source>    Install plugin from path or GitHub"
  echo "  remove <name>       Remove a user plugin"
  echo "  info <name>         Show plugin details"
  echo "  hooks               Show registered hooks"
  echo "  path                Show plugin search paths"
  echo ""
  echo "${FLOW_COLORS[bold]}INSTALL SOURCES${FLOW_COLORS[reset]}"
  echo "  /path/to/plugin     Copy from local directory"
  echo "  gh:user/repo        Clone from GitHub"
  echo "  --dev .             Symlink current dir (development)"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  flow plugin list"
  echo "  flow plugin create my-plugin"
  echo "  flow plugin install gh:username/flow-plugin-docker"
  echo "  flow plugin install --dev ."
  echo "  flow plugin disable my-plugin"
  echo "  flow plugin remove my-plugin"
  echo ""
  echo "${FLOW_COLORS[bold]}PLUGIN LOCATIONS${FLOW_COLORS[reset]}"
  echo "  User:    ~/.config/flow/plugins/"
  echo "  Bundled: \$FLOW_PLUGIN_DIR/plugins/"
  echo ""
}

_flow_plugin_list_help() {
  echo "Usage: flow plugin list [-a|--all]"
  echo ""
  echo "Options:"
  echo "  -a, --all    Show all discovered plugins (including unloaded)"
}

_flow_plugin_create_help() {
  echo "Usage: flow plugin create <name> [-d <directory>]"
  echo ""
  echo "Options:"
  echo "  -d, --dir    Create in specified directory (default: ~/.config/flow/plugins)"
}

_flow_plugin_install_help() {
  echo "Usage: flow plugin install <source>"
  echo ""
  echo "Sources:"
  echo "  /path/to/plugin     Local directory"
  echo "  gh:user/repo        GitHub repository"
  echo "  --dev .             Current directory (symlink, for development)"
}
