# lib/plugin-loader.zsh - Plugin system for flow-cli
# Provides plugin discovery, loading, and hook management

# ============================================================================
# PLUGIN SYSTEM CONFIGURATION
# ============================================================================

# Plugin directories (searched in order)
typeset -ga FLOW_PLUGIN_PATHS=(
  "${FLOW_PLUGIN_PATH:-}"                           # Custom paths (colon-separated)
  "${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugins"  # User plugins
  "${FLOW_PLUGIN_DIR}/plugins"                      # Bundled plugins
)

# Plugin state
typeset -gA _FLOW_PLUGINS=()           # name -> path
typeset -gA _FLOW_PLUGIN_VERSIONS=()   # name -> version
typeset -gA _FLOW_PLUGIN_ENABLED=()    # name -> 0|1
typeset -ga _FLOW_PLUGIN_LOAD_ORDER=() # Load order for dependencies

# Hook registry
typeset -gA _FLOW_HOOKS=()             # event -> callback1:callback2:...

# Available hook events
typeset -ga FLOW_HOOK_EVENTS=(
  "post-work"       # After work <project>
  "pre-finish"      # Before finish
  "post-finish"     # After finish
  "session-start"   # Shell starts
  "session-end"     # Shell exits
  "project-change"  # Directory change to project
  "pre-command"     # Before any flow command
  "post-command"    # After any flow command
)

# Plugin registry file
FLOW_PLUGIN_REGISTRY="${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugin-registry.json"

# ============================================================================
# PLUGIN REGISTRATION
# ============================================================================

# Register a plugin (called by plugins in their main.zsh)
# Usage: _flow_plugin_register "name" "version" ["description"]
_flow_plugin_register() {
  local name="$1"
  local version="${2:-1.0.0}"
  local description="${3:-}"

  if [[ -z "$name" ]]; then
    _flow_log_error "Plugin registration requires a name"
    return 1
  fi

  _FLOW_PLUGINS[$name]="${_FLOW_CURRENT_PLUGIN_PATH:-unknown}"
  _FLOW_PLUGIN_VERSIONS[$name]="$version"
  _FLOW_PLUGIN_ENABLED[$name]=1
  _FLOW_PLUGIN_LOAD_ORDER+=("$name")

  [[ -n "${FLOW_DEBUG:-}" ]] && _flow_log_info "Registered plugin: $name v$version"

  return 0
}

# Check if a plugin is registered
# Usage: _flow_plugin_exists "name"
_flow_plugin_exists() {
  [[ -n "${_FLOW_PLUGINS[$1]:-}" ]]
}

# Check if a plugin is enabled
# Usage: _flow_plugin_enabled "name"
_flow_plugin_enabled() {
  [[ "${_FLOW_PLUGIN_ENABLED[$1]:-0}" == "1" ]]
}

# Get plugin version
# Usage: _flow_plugin_version "name"
_flow_plugin_version() {
  echo "${_FLOW_PLUGIN_VERSIONS[$1]:-unknown}"
}

# Get plugin path
# Usage: _flow_plugin_path "name"
_flow_plugin_path() {
  echo "${_FLOW_PLUGINS[$1]:-}"
}

# ============================================================================
# PLUGIN DISCOVERY
# ============================================================================

# Discover all available plugins
# Returns: list of plugin paths
_flow_plugin_discover() {
  local -a discovered=()
  local search_path plugin_path

  # Expand FLOW_PLUGIN_PATH if set (colon-separated)
  if [[ -n "${FLOW_PLUGIN_PATH:-}" ]]; then
    local -a custom_paths
    IFS=':' read -rA custom_paths <<< "$FLOW_PLUGIN_PATH"
    FLOW_PLUGIN_PATHS=("${custom_paths[@]}" "${FLOW_PLUGIN_PATHS[@]}")
  fi

  for search_path in "${FLOW_PLUGIN_PATHS[@]}"; do
    [[ -z "$search_path" || ! -d "$search_path" ]] && continue

    # Find single-file plugins (*.zsh)
    for plugin_path in "$search_path"/*.zsh(N); do
      [[ -f "$plugin_path" ]] && discovered+=("$plugin_path")
    done

    # Find directory plugins (with main.zsh or plugin.json)
    for plugin_path in "$search_path"/*(N/); do
      if [[ -f "$plugin_path/main.zsh" ]] || [[ -f "$plugin_path/plugin.json" ]]; then
        discovered+=("$plugin_path")
      fi
    done
  done

  # Return unique paths
  printf '%s\n' "${discovered[@]}" | sort -u
}

# Get plugin metadata from plugin.json or infer from file
# Usage: _flow_plugin_metadata "/path/to/plugin"
# Output: name|version|description|type
_flow_plugin_metadata() {
  local plugin_path="$1"
  local name version description type

  if [[ -f "$plugin_path" ]]; then
    # Single file plugin
    name="${${plugin_path:t}%.zsh}"
    version="1.0.0"
    description="Single-file plugin"
    type="file"

    # Try to extract version from file header
    local header_version=$(command grep -m1 "^# Version:" "$plugin_path" 2>/dev/null | command cut -d: -f2 | tr -d ' ')
    [[ -n "$header_version" ]] && version="$header_version"

  elif [[ -d "$plugin_path" ]]; then
    # Directory plugin
    name="${plugin_path:t}"
    type="directory"

    if [[ -f "$plugin_path/plugin.json" ]] && command -v jq >/dev/null 2>&1; then
      # Parse plugin.json
      name=$(jq -r '.name // empty' "$plugin_path/plugin.json" 2>/dev/null)
      version=$(jq -r '.version // "1.0.0"' "$plugin_path/plugin.json" 2>/dev/null)
      description=$(jq -r '.description // empty' "$plugin_path/plugin.json" 2>/dev/null)
    else
      version="1.0.0"
      description="Directory plugin"
    fi
  else
    return 1
  fi

  echo "${name}|${version}|${description}|${type}"
}

# ============================================================================
# PLUGIN LOADING
# ============================================================================

# Load a single plugin
# Usage: _flow_plugin_load "/path/to/plugin"
_flow_plugin_load() {
  local plugin_path="$1"
  local plugin_name plugin_file

  if [[ ! -e "$plugin_path" ]]; then
    _flow_log_error "Plugin not found: $plugin_path"
    return 1
  fi

  # Determine plugin name and entry file
  if [[ -f "$plugin_path" ]]; then
    # Single file plugin
    plugin_name="${${plugin_path:t}%.zsh}"
    plugin_file="$plugin_path"
  elif [[ -d "$plugin_path" ]]; then
    # Directory plugin
    plugin_name="${plugin_path:t}"

    if [[ -f "$plugin_path/main.zsh" ]]; then
      plugin_file="$plugin_path/main.zsh"
    elif [[ -f "$plugin_path/$plugin_name.zsh" ]]; then
      plugin_file="$plugin_path/$plugin_name.zsh"
    else
      _flow_log_error "No entry point found for plugin: $plugin_name"
      return 1
    fi
  fi

  # Check if already loaded
  if _flow_plugin_exists "$plugin_name"; then
    [[ -n "${FLOW_DEBUG:-}" ]] && _flow_log_info "Plugin already loaded: $plugin_name"
    return 0
  fi

  # Check dependencies if plugin.json exists
  if [[ -d "$plugin_path" && -f "$plugin_path/plugin.json" ]]; then
    if ! _flow_plugin_check_deps "$plugin_path/plugin.json"; then
      _flow_log_warning "Plugin $plugin_name has unmet dependencies, skipping"
      return 1
    fi
  fi

  # Set current plugin path for registration
  _FLOW_CURRENT_PLUGIN_PATH="$plugin_path"

  # Source the plugin
  if source "$plugin_file" 2>/dev/null; then
    # Auto-register if plugin didn't call _flow_plugin_register
    if ! _flow_plugin_exists "$plugin_name"; then
      _flow_plugin_register "$plugin_name"
    fi

    [[ -n "${FLOW_DEBUG:-}" ]] && _flow_log_success "Loaded plugin: $plugin_name"
    unset _FLOW_CURRENT_PLUGIN_PATH
    return 0
  else
    _flow_log_error "Failed to load plugin: $plugin_name"
    unset _FLOW_CURRENT_PLUGIN_PATH
    return 1
  fi
}

# Load all enabled plugins
_flow_plugin_load_all() {
  local plugin_path
  local -a plugins

  # Get discovered plugins
  plugins=("${(@f)$(_flow_plugin_discover)}")

  for plugin_path in "${plugins[@]}"; do
    [[ -z "$plugin_path" ]] && continue

    local metadata=$(_flow_plugin_metadata "$plugin_path")
    local name="${metadata%%|*}"

    # Check if plugin is disabled in registry
    if _flow_plugin_is_disabled "$name"; then
      [[ -n "${FLOW_DEBUG:-}" ]] && _flow_log_info "Skipping disabled plugin: $name"
      continue
    fi

    _flow_plugin_load "$plugin_path"
  done
}

# Check plugin dependencies
# Usage: _flow_plugin_check_deps "/path/to/plugin.json"
_flow_plugin_check_deps() {
  local json_file="$1"

  if ! command -v jq >/dev/null 2>&1; then
    # Can't check deps without jq, assume OK
    return 0
  fi

  # Check tool dependencies
  local -a tools
  tools=($(jq -r '.dependencies.tools[]? // empty' "$json_file" 2>/dev/null))

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      _flow_log_warning "Missing dependency: $tool"
      return 1
    fi
  done

  # Check flow version
  local required_flow=$(jq -r '.dependencies.flow // empty' "$json_file" 2>/dev/null)
  if [[ -n "$required_flow" ]]; then
    # Simple version check (could be enhanced)
    local current_flow="${FLOW_VERSION:-0.0.0}"
    # For now, just warn - don't block
    [[ -n "${FLOW_DEBUG:-}" ]] && _flow_log_info "Plugin requires flow $required_flow (current: $current_flow)"
  fi

  return 0
}

# ============================================================================
# PLUGIN ENABLE/DISABLE
# ============================================================================

# Enable a plugin
# Usage: _flow_plugin_enable "name"
_flow_plugin_enable() {
  local name="$1"

  _FLOW_PLUGIN_ENABLED[$name]=1
  _flow_plugin_registry_save
  _flow_log_success "Enabled plugin: $name"
}

# Disable a plugin
# Usage: _flow_plugin_disable "name"
_flow_plugin_disable() {
  local name="$1"

  _FLOW_PLUGIN_ENABLED[$name]=0
  _flow_plugin_registry_save
  _flow_log_success "Disabled plugin: $name (reload shell to take effect)"
}

# Check if plugin is disabled in registry
_flow_plugin_is_disabled() {
  local name="$1"

  if [[ -f "$FLOW_PLUGIN_REGISTRY" ]] && command -v jq >/dev/null 2>&1; then
    local disabled=$(jq -r ".disabled[] // empty | select(. == \"$name\")" "$FLOW_PLUGIN_REGISTRY" 2>/dev/null)
    [[ -n "$disabled" ]]
  else
    return 1
  fi
}

# Save plugin registry
_flow_plugin_registry_save() {
  local registry_dir="${FLOW_PLUGIN_REGISTRY:h}"

  # Ensure directory exists
  [[ ! -d "$registry_dir" ]] && mkdir -p "$registry_dir"

  # Build disabled list
  local -a disabled=()
  for name in "${(k)_FLOW_PLUGIN_ENABLED[@]}"; do
    [[ "${_FLOW_PLUGIN_ENABLED[$name]}" == "0" ]] && disabled+=("\"$name\"")
  done

  # Write registry
  cat > "$FLOW_PLUGIN_REGISTRY" <<EOF
{
  "version": "1.0",
  "disabled": [${(j:,:)disabled}],
  "updated": "$(date -Iseconds)"
}
EOF
}

# Load plugin registry
_flow_plugin_registry_load() {
  if [[ -f "$FLOW_PLUGIN_REGISTRY" ]] && command -v jq >/dev/null 2>&1; then
    local -a disabled
    disabled=($(jq -r '.disabled[]? // empty' "$FLOW_PLUGIN_REGISTRY" 2>/dev/null))

    for name in "${disabled[@]}"; do
      _FLOW_PLUGIN_ENABLED[$name]=0
    done
  fi
}

# ============================================================================
# HOOK SYSTEM
# ============================================================================

# Register a hook callback
# Usage: _flow_hook_register "event" "callback_function"
_flow_hook_register() {
  local event="$1"
  local callback="$2"

  # Validate event
  if [[ ! " ${FLOW_HOOK_EVENTS[*]} " =~ " $event " ]]; then
    _flow_log_error "Invalid hook event: $event"
    _flow_log_info "Valid events: ${FLOW_HOOK_EVENTS[*]}"
    return 1
  fi

  # Validate callback exists
  if ! typeset -f "$callback" >/dev/null 2>&1; then
    _flow_log_error "Hook callback function not found: $callback"
    return 1
  fi

  # Add to registry (colon-separated list)
  if [[ -n "${_FLOW_HOOKS[$event]:-}" ]]; then
    _FLOW_HOOKS[$event]="${_FLOW_HOOKS[$event]}:$callback"
  else
    _FLOW_HOOKS[$event]="$callback"
  fi

  [[ -n "${FLOW_DEBUG:-}" ]] && _flow_log_info "Registered hook: $event -> $callback"
  return 0
}

# Run all callbacks for an event
# Usage: _flow_hook_run "event" [args...]
_flow_hook_run() {
  local event="$1"
  shift
  local args=("$@")

  local callbacks="${_FLOW_HOOKS[$event]:-}"
  [[ -z "$callbacks" ]] && return 0

  local -a callback_list
  IFS=':' read -rA callback_list <<< "$callbacks"

  local callback
  for callback in "${callback_list[@]}"; do
    [[ -z "$callback" ]] && continue

    if typeset -f "$callback" >/dev/null 2>&1; then
      [[ -n "${FLOW_DEBUG:-}" ]] && _flow_log_info "Running hook: $event -> $callback"

      # Run callback, capture errors but don't fail
      if ! "$callback" "${args[@]}" 2>&1; then
        _flow_log_warning "Hook callback failed: $callback"
      fi
    fi
  done

  return 0
}

# List registered hooks
_flow_hook_list() {
  echo "Registered hooks:"
  for event in "${FLOW_HOOK_EVENTS[@]}"; do
    local callbacks="${_FLOW_HOOKS[$event]:-}"
    if [[ -n "$callbacks" ]]; then
      echo "  $event:"
      local -a callback_list
      IFS=':' read -rA callback_list <<< "$callbacks"
      for cb in "${callback_list[@]}"; do
        echo "    - $cb"
      done
    fi
  done
}

# ============================================================================
# PLUGIN LISTING
# ============================================================================

# List all plugins with status
_flow_plugin_list() {
  local show_available="${1:-false}"

  echo ""
  echo "${FLOW_COLORS[header]}INSTALLED PLUGINS${FLOW_COLORS[reset]}"
  echo ""

  if (( ${#_FLOW_PLUGINS[@]} == 0 )); then
    echo "  ${FLOW_COLORS[muted]}No plugins installed${FLOW_COLORS[reset]}"
  else
    for name in "${_FLOW_PLUGIN_LOAD_ORDER[@]}"; do
      local version="${_FLOW_PLUGIN_VERSIONS[$name]:-?}"
      local path="${_FLOW_PLUGINS[$name]:-?}"
      local enabled="${_FLOW_PLUGIN_ENABLED[$name]:-1}"

      local status_icon="✓"
      local status_color="${FLOW_COLORS[success]}"
      if [[ "$enabled" == "0" ]]; then
        status_icon="○"
        status_color="${FLOW_COLORS[muted]}"
      fi

      printf "  %s %s%-15s%s v%-8s %s%s%s\n" \
        "$status_icon" \
        "$status_color" "$name" "${FLOW_COLORS[reset]}" \
        "$version" \
        "${FLOW_COLORS[muted]}" "$path" "${FLOW_COLORS[reset]}"
    done
  fi

  # Show discovered but not loaded plugins
  if [[ "$show_available" == "true" ]]; then
    echo ""
    echo "${FLOW_COLORS[header]}AVAILABLE (not loaded)${FLOW_COLORS[reset]}"
    echo ""

    local -a discovered
    discovered=("${(@f)$(_flow_plugin_discover)}")
    local found_available=false

    for plugin_path in "${discovered[@]}"; do
      [[ -z "$plugin_path" ]] && continue

      local metadata=$(_flow_plugin_metadata "$plugin_path")
      local name="${metadata%%|*}"

      if ! _flow_plugin_exists "$name"; then
        found_available=true
        printf "  ○ %s%-15s%s %s%s%s\n" \
          "${FLOW_COLORS[muted]}" "$name" "${FLOW_COLORS[reset]}" \
          "${FLOW_COLORS[muted]}" "$plugin_path" "${FLOW_COLORS[reset]}"
      fi
    done

    if [[ "$found_available" == "false" ]]; then
      echo "  ${FLOW_COLORS[muted]}All discovered plugins are loaded${FLOW_COLORS[reset]}"
    fi
  fi

  echo ""
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize plugin system
_flow_plugin_init() {
  # Load registry (disabled plugins list)
  _flow_plugin_registry_load

  # Create user plugin directory if it doesn't exist
  local user_plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugins"
  [[ ! -d "$user_plugin_dir" ]] && mkdir -p "$user_plugin_dir"

  # Load all enabled plugins
  _flow_plugin_load_all

  # Run session-start hooks
  _flow_hook_run "session-start"
}

# Cleanup on shell exit
_flow_plugin_cleanup() {
  _flow_hook_run "session-end"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get plugin config value
# Usage: _flow_plugin_config_get "key" ["default"]
_flow_plugin_config_get() {
  local key="$1"
  local default="${2:-}"
  local plugin_name="${_FLOW_CURRENT_PLUGIN_NAME:-}"

  # Check plugin-specific config
  local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugins/${plugin_name}/config.zsh"

  if [[ -f "$config_file" ]]; then
    source "$config_file"
    local var_name="${plugin_name:u}_${key:u}"
    var_name="${var_name//-/_}"
    echo "${(P)var_name:-$default}"
  else
    echo "$default"
  fi
}

# Create a new plugin from template
# Usage: _flow_plugin_create "name" ["directory"]
_flow_plugin_create() {
  local name="$1"
  local base_dir="${2:-${XDG_CONFIG_HOME:-$HOME/.config}/flow/plugins}"
  local plugin_dir="$base_dir/$name"

  if [[ -e "$plugin_dir" ]]; then
    _flow_log_error "Plugin already exists: $plugin_dir"
    return 1
  fi

  mkdir -p "$plugin_dir"

  # Create plugin.json
  cat > "$plugin_dir/plugin.json" <<EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Description of $name plugin",
  "author": "${USER:-unknown}",
  "commands": [],
  "dependencies": {
    "tools": [],
    "flow": ">=3.3.0"
  },
  "hooks": {}
}
EOF

  # Create main.zsh
  cat > "$plugin_dir/main.zsh" <<EOF
# $name plugin for flow-cli
# Created: $(date +%Y-%m-%d)

# Register plugin
_flow_plugin_register "$name" "1.0.0" "Description of $name plugin"

# ============================================================================
# COMMANDS
# ============================================================================

# Example command
${name}_hello() {
  echo "Hello from $name plugin!"
}

# ============================================================================
# HOOKS (optional)
# ============================================================================

# Example: Run after 'work <project>'
# _${name}_on_work() {
#   local project="\$1"
#   echo "[$name] Started working on: \$project"
# }
# _flow_hook_register "post-work" "_${name}_on_work"
EOF

  _flow_log_success "Created plugin: $plugin_dir"
  echo ""
  echo "Next steps:"
  echo "  1. Edit $plugin_dir/main.zsh"
  echo "  2. Reload shell: exec zsh"
  echo "  3. Verify: flow plugin list"
}
