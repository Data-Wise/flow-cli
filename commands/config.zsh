# commands/config.zsh - Configuration management commands
# Provides show, set, edit, reset, profile management

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

flow_config() {
  local cmd="${1:-show}"
  shift 2>/dev/null

  case "$cmd" in
    show|list)     _flow_config_cmd_show "$@" ;;
    get)           _flow_config_cmd_get "$@" ;;
    set)           _flow_config_cmd_set "$@" ;;
    edit)          _flow_config_cmd_edit "$@" ;;
    reset)         _flow_config_cmd_reset "$@" ;;
    save)          _flow_config_cmd_save "$@" ;;
    reload)        _flow_config_cmd_reload "$@" ;;
    wizard|setup)  _flow_config_wizard ;;
    profile)       _flow_config_cmd_profile "$@" ;;
    export)        _flow_config_export ;;
    path)          _flow_config_cmd_path "$@" ;;
    help|--help|-h) _flow_config_help ;;
    *)
      # Check if it's a key=value assignment
      if [[ "$cmd" == *"="* ]]; then
        local key="${cmd%%=*}"
        local value="${cmd#*=}"
        _flow_config_cmd_set "$key" "$value"
      else
        _flow_log_error "Unknown config command: $cmd"
        _flow_config_help
        return 1
      fi
      ;;
  esac
}

# ============================================================================
# COMMAND IMPLEMENTATIONS
# ============================================================================

# Show configuration
_flow_config_cmd_show() {
  local filter=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a|--all) shift ;;  # Show all (default behavior)
      -h|--help) echo "Usage: flow config show [filter]"; return 0 ;;
      *) filter="$1"; shift ;;
    esac
  done

  _flow_config_show "$filter"
}

# Get a specific config value
_flow_config_cmd_get() {
  local key="$1"

  if [[ -z "$key" ]]; then
    _flow_log_error "Usage: flow config get <key>"
    return 1
  fi

  local value=$(_flow_config_get "$key")
  echo "$value"
}

# Set a config value
_flow_config_cmd_set() {
  local key="$1"
  local value="$2"

  if [[ -z "$key" ]]; then
    _flow_log_error "Usage: flow config set <key> <value>"
    echo ""
    echo "Available keys:"
    for k in "${(@ko)FLOW_CONFIG_DEFAULTS}"; do
      echo "  $k"
    done
    return 1
  fi

  if [[ -z "$value" ]]; then
    # If no value, show current
    local current=$(_flow_config_get "$key")
    local default="${FLOW_CONFIG_DEFAULTS[$key]:-}"
    echo "Current: $key = $current"
    [[ "$current" != "$default" ]] && echo "Default: $default"
    return 0
  fi

  # Validate value for known keys
  case "$key" in
    atlas_enabled)
      if [[ ! "$value" =~ ^(auto|yes|no)$ ]]; then
        _flow_log_error "Invalid value. Use: auto, yes, or no"
        return 1
      fi
      ;;
    quiet|debug|show_icons|dopamine_mode|auto_breadcrumb|auto_commit|commit_emoji|timer_sound|ai_verbose)
      if [[ ! "$value" =~ ^(0|1|yes|no|true|false)$ ]]; then
        _flow_log_error "Invalid value. Use: yes/no, 1/0, or true/false"
        return 1
      fi
      # Normalize to yes/no
      case "$value" in
        1|true) value="yes" ;;
        0|false) value="no" ;;
      esac
      ;;
    timer_default|timer_break|timer_long_break|session_timeout|progress_bar_width)
      if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        _flow_log_error "Invalid value. Must be a number"
        return 1
      fi
      ;;
    push_after_finish)
      if [[ ! "$value" =~ ^(yes|no|ask)$ ]]; then
        _flow_log_error "Invalid value. Use: yes, no, or ask"
        return 1
      fi
      ;;
  esac

  local old_value=$(_flow_config_get "$key")
  _flow_config_set "$key" "$value"

  echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $key: $old_value → $value"
  echo ""
  echo "${FLOW_COLORS[muted]}Run 'flow config save' to persist${FLOW_COLORS[reset]}"
}

# Edit config file in editor
_flow_config_cmd_edit() {
  # Ensure config file exists
  if [[ ! -f "$FLOW_CONFIG_FILE" ]]; then
    _flow_config_save
  fi

  local editor="${EDITOR:-${VISUAL:-vim}}"

  echo "Opening config in $editor..."
  "$editor" "$FLOW_CONFIG_FILE"

  # Reload after editing
  if _flow_confirm "Reload configuration?"; then
    _flow_config_load
    _flow_log_success "Configuration reloaded"
  fi
}

# Reset configuration
_flow_config_cmd_reset() {
  local key="$1"
  local force=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force) force=true; shift ;;
      --all) key="--all"; shift ;;
      -h|--help)
        echo "Usage: flow config reset [key|--all] [-f]"
        echo ""
        echo "Options:"
        echo "  <key>      Reset specific key to default"
        echo "  --all      Reset all to defaults"
        echo "  -f         Force without confirmation"
        return 0
        ;;
      *) key="$1"; shift ;;
    esac
  done

  if [[ -z "$key" ]]; then
    _flow_log_error "Usage: flow config reset <key> or flow config reset --all"
    return 1
  fi

  if [[ "$key" == "--all" ]]; then
    if [[ "$force" != "true" ]]; then
      if ! _flow_confirm "Reset ALL configuration to defaults?"; then
        echo "Cancelled"
        return 0
      fi
    fi

    _flow_config_reset_all
    _flow_config_save
    _flow_log_success "All configuration reset to defaults"
  else
    local default="${FLOW_CONFIG_DEFAULTS[$key]:-}"

    if [[ -z "$default" ]]; then
      _flow_log_error "Unknown config key: $key"
      return 1
    fi

    local old_value="${FLOW_CONFIG[$key]:-}"
    _flow_config_reset "$key"

    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $key: $old_value → $default (default)"
    echo ""
    echo "${FLOW_COLORS[muted]}Run 'flow config save' to persist${FLOW_COLORS[reset]}"
  fi
}

# Save configuration to file
_flow_config_cmd_save() {
  _flow_config_save
  _flow_log_success "Configuration saved to: $FLOW_CONFIG_FILE"
}

# Reload configuration from file
_flow_config_cmd_reload() {
  if [[ ! -f "$FLOW_CONFIG_FILE" ]]; then
    _flow_log_warning "No config file found, using defaults"
    return 0
  fi

  _flow_config_load
  _flow_config_apply
  _flow_log_success "Configuration reloaded"
}

# Profile management
_flow_config_cmd_profile() {
  local action="${1:-list}"
  shift 2>/dev/null

  case "$action" in
    list|ls)
      _flow_config_profile_list
      ;;
    save)
      local name="$1"
      if [[ -z "$name" ]]; then
        echo -n "Profile name: "
        read -r name
      fi
      _flow_config_profile_save "$name"
      ;;
    load|use)
      local name="$1"
      if [[ -z "$name" ]]; then
        _flow_log_error "Usage: flow config profile load <name>"
        _flow_config_profile_list
        return 1
      fi
      _flow_config_profile_load "$name"
      ;;
    delete|rm)
      local name="$1"
      if [[ -z "$name" ]]; then
        _flow_log_error "Usage: flow config profile delete <name>"
        return 1
      fi

      if _flow_confirm "Delete profile '$name'?"; then
        _flow_config_profile_delete "$name"
      fi
      ;;
    help|--help|-h)
      echo "Usage: flow config profile <action> [name]"
      echo ""
      echo "Actions:"
      echo "  list           List available profiles"
      echo "  save <name>    Save current config as profile"
      echo "  load <name>    Load a profile"
      echo "  delete <name>  Delete a user profile"
      ;;
    *)
      # Assume it's a profile name to load
      _flow_config_profile_load "$action"
      ;;
  esac
}

# Show config paths
_flow_config_cmd_path() {
  echo ""
  echo "${FLOW_COLORS[header]}CONFIGURATION PATHS${FLOW_COLORS[reset]}"
  echo ""
  echo "  Config file:   $FLOW_CONFIG_FILE"
  echo "  Config dir:    $FLOW_CONFIG_DIR"
  echo "  Profile dir:   $FLOW_PROFILE_DIR"
  echo "  Data dir:      $FLOW_DATA_DIR"
  echo ""

  if [[ -f "$FLOW_CONFIG_FILE" ]]; then
    local size=$(wc -c < "$FLOW_CONFIG_FILE" | tr -d ' ')
    local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$FLOW_CONFIG_FILE" 2>/dev/null || echo "unknown")
    echo "  Config size:   $size bytes"
    echo "  Last modified: $modified"
  else
    echo "  ${FLOW_COLORS[muted]}Config file not yet created${FLOW_COLORS[reset]}"
  fi
  echo ""
}

# ============================================================================
# HELP
# ============================================================================

_flow_config_help() {
  echo ""
  echo "${FLOW_COLORS[bold]}flow config${FLOW_COLORS[reset]} - Manage flow-cli configuration"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow config <command> [options]"
  echo ""
  echo "${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}"
  echo "  show [filter]       Show all config (optionally filter by keyword)"
  echo "  get <key>           Get a specific config value"
  echo "  set <key> <value>   Set a config value"
  echo "  edit                Open config file in editor"
  echo "  reset <key>         Reset a key to default"
  echo "  reset --all         Reset all to defaults"
  echo "  save                Save current config to file"
  echo "  reload              Reload config from file"
  echo "  wizard              Interactive configuration wizard"
  echo "  export              Export config in shell format"
  echo "  path                Show config file paths"
  echo ""
  echo "${FLOW_COLORS[bold]}PROFILES${FLOW_COLORS[reset]}"
  echo "  profile list        List available profiles"
  echo "  profile save <n>    Save current config as profile"
  echo "  profile load <n>    Load a profile"
  echo "  profile delete <n>  Delete a user profile"
  echo ""
  echo "${FLOW_COLORS[bold]}BUILT-IN PROFILES${FLOW_COLORS[reset]}"
  echo "  minimal             Quiet mode, minimal features"
  echo "  developer           Full dev features"
  echo "  adhd                Maximum ADHD support"
  echo "  researcher          Academic workflow optimized"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  flow config show"
  echo "  flow config show timer"
  echo "  flow config set timer_default 30"
  echo "  flow config timer_default=30"
  echo "  flow config reset timer_default"
  echo "  flow config wizard"
  echo "  flow config profile save work"
  echo "  flow config profile load adhd"
  echo ""
  echo "${FLOW_COLORS[bold]}CONFIG KEYS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}Core:${FLOW_COLORS[reset]} projects_root, atlas_enabled, load_dispatchers, quiet, debug"
  echo "  ${FLOW_COLORS[muted]}UI:${FLOW_COLORS[reset]} color_theme, progress_bar_width, show_icons"
  echo "  ${FLOW_COLORS[muted]}Timer:${FLOW_COLORS[reset]} timer_default, timer_break, timer_long_break, timer_sound"
  echo "  ${FLOW_COLORS[muted]}ADHD:${FLOW_COLORS[reset]} auto_breadcrumb, session_timeout, dopamine_mode"
  echo "  ${FLOW_COLORS[muted]}Git:${FLOW_COLORS[reset]} auto_commit, commit_emoji, push_after_finish"
  echo "  ${FLOW_COLORS[muted]}AI:${FLOW_COLORS[reset]} ai_provider, ai_context, ai_verbose"
  echo ""
}
