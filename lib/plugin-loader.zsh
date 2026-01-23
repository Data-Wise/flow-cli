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

# =============================================================================
# Function: _flow_plugin_register
# Purpose: Register a plugin with the flow-cli plugin system
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name (unique identifier)
#   $2 - (optional) Plugin version [default: 1.0.0]
#   $3 - (optional) Plugin description [default: empty]
#
# Returns:
#   0 - Plugin registered successfully
#   1 - Registration failed (empty name)
#
# Output:
#   stderr - Error message if name is empty
#   stdout - Debug info if FLOW_DEBUG is set
#
# Example:
#   _flow_plugin_register "my-plugin" "2.0.0" "A helpful plugin"
#   _flow_plugin_register "simple-plugin"  # Uses defaults
#
# Dependencies:
#   - _flow_log_error (lib/core.zsh)
#   - _flow_log_info (lib/core.zsh)
#
# Notes:
#   - Called by plugins in their main.zsh entry point
#   - Stores plugin path from _FLOW_CURRENT_PLUGIN_PATH
#   - Automatically marks plugin as enabled
#   - Adds to _FLOW_PLUGIN_LOAD_ORDER for dependency tracking
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_exists
# Purpose: Check if a plugin is registered in the plugin system
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name to check
#
# Returns:
#   0 - Plugin exists (is registered)
#   1 - Plugin does not exist
#
# Output:
#   None
#
# Example:
#   if _flow_plugin_exists "my-plugin"; then
#     echo "Plugin is registered"
#   fi
#
# Dependencies:
#   None
#
# Notes:
#   - Only checks if plugin is registered, not if it's enabled
#   - Use _flow_plugin_enabled to check enabled status
# =============================================================================
_flow_plugin_exists() {
  [[ -n "${_FLOW_PLUGINS[$1]:-}" ]]
}

# =============================================================================
# Function: _flow_plugin_enabled
# Purpose: Check if a plugin is currently enabled
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name to check
#
# Returns:
#   0 - Plugin is enabled
#   1 - Plugin is disabled or not registered
#
# Output:
#   None
#
# Example:
#   if _flow_plugin_enabled "my-plugin"; then
#     # Run plugin-specific code
#   fi
#
# Dependencies:
#   None
#
# Notes:
#   - Returns false for non-existent plugins
#   - Enabled status persists in plugin registry
# =============================================================================
_flow_plugin_enabled() {
  [[ "${_FLOW_PLUGIN_ENABLED[$1]:-0}" == "1" ]]
}

# =============================================================================
# Function: _flow_plugin_version
# Purpose: Get the version string of a registered plugin
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Version string (e.g., "1.2.3") or "unknown" if not found
#
# Example:
#   local version=$(_flow_plugin_version "my-plugin")
#   echo "Plugin version: $version"
#
# Dependencies:
#   None
#
# Notes:
#   - Returns "unknown" for unregistered plugins
#   - Version format follows semver convention
# =============================================================================
_flow_plugin_version() {
  echo "${_FLOW_PLUGIN_VERSIONS[$1]:-unknown}"
}

# =============================================================================
# Function: _flow_plugin_path
# Purpose: Get the filesystem path of a registered plugin
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Full path to plugin directory/file, or empty if not found
#
# Example:
#   local path=$(_flow_plugin_path "my-plugin")
#   if [[ -n "$path" ]]; then
#     ls "$path"
#   fi
#
# Dependencies:
#   None
#
# Notes:
#   - Returns empty string for unregistered plugins
#   - Path may be a directory or single .zsh file
# =============================================================================
_flow_plugin_path() {
  echo "${_FLOW_PLUGINS[$1]:-}"
}

# ============================================================================
# PLUGIN DISCOVERY
# ============================================================================

# =============================================================================
# Function: _flow_plugin_discover
# Purpose: Discover all available plugins in configured plugin paths
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Newline-separated list of unique plugin paths (sorted)
#
# Example:
#   local -a plugins
#   plugins=("${(@f)$(_flow_plugin_discover)}")
#   echo "Found ${#plugins[@]} plugins"
#
# Dependencies:
#   None
#
# Notes:
#   - Searches FLOW_PLUGIN_PATHS in order (custom, user, bundled)
#   - Supports single-file plugins (*.zsh)
#   - Supports directory plugins (with main.zsh or plugin.json)
#   - FLOW_PLUGIN_PATH env var adds custom paths (colon-separated)
#   - Returns deduplicated, sorted list
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_metadata
# Purpose: Extract metadata from a plugin (from plugin.json or inferred)
# =============================================================================
# Arguments:
#   $1 - (required) Path to plugin (file or directory)
#
# Returns:
#   0 - Metadata extracted successfully
#   1 - Invalid path or plugin not found
#
# Output:
#   stdout - Pipe-delimited string: "name|version|description|type"
#            type is either "file" or "directory"
#
# Example:
#   local metadata=$(_flow_plugin_metadata "/path/to/my-plugin")
#   local name="${metadata%%|*}"
#   # Or parse all fields:
#   IFS='|' read -r name version description type <<< "$metadata"
#
# Dependencies:
#   - jq (optional, for parsing plugin.json)
#
# Notes:
#   - For single-file plugins, extracts version from "# Version:" header
#   - For directory plugins, prefers plugin.json if jq is available
#   - Falls back to defaults: version=1.0.0, description=inferred
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_load
# Purpose: Load and initialize a single plugin from path
# =============================================================================
# Arguments:
#   $1 - (required) Path to plugin (file or directory)
#
# Returns:
#   0 - Plugin loaded successfully
#   1 - Plugin not found, no entry point, or load failed
#
# Output:
#   stderr - Error messages for failures
#   stdout - Debug info if FLOW_DEBUG is set
#
# Example:
#   _flow_plugin_load "/path/to/my-plugin"
#   _flow_plugin_load "$HOME/.config/flow/plugins/my-plugin.zsh"
#
# Dependencies:
#   - _flow_log_error (lib/core.zsh)
#   - _flow_log_warning (lib/core.zsh)
#   - _flow_log_success (lib/core.zsh)
#   - _flow_log_info (lib/core.zsh)
#   - _flow_plugin_exists
#   - _flow_plugin_check_deps
#   - _flow_plugin_register
#
# Notes:
#   - Single-file plugins: sources the .zsh file directly
#   - Directory plugins: looks for main.zsh or <name>.zsh
#   - Checks dependencies from plugin.json before loading
#   - Auto-registers if plugin doesn't call _flow_plugin_register
#   - Skips if plugin is already loaded
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_load_all
# Purpose: Discover and load all enabled plugins
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds (individual failures are logged but don't fail)
#
# Output:
#   stderr - Warnings/errors for individual plugin failures
#   stdout - Debug info if FLOW_DEBUG is set
#
# Example:
#   _flow_plugin_load_all
#
# Dependencies:
#   - _flow_plugin_discover
#   - _flow_plugin_metadata
#   - _flow_plugin_is_disabled
#   - _flow_plugin_load
#   - _flow_log_info (lib/core.zsh)
#
# Notes:
#   - Discovers all plugins via _flow_plugin_discover
#   - Skips plugins marked as disabled in registry
#   - Called automatically by _flow_plugin_init
#   - Failed plugin loads don't prevent other plugins from loading
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_check_deps
# Purpose: Verify a plugin's dependencies are satisfied
# =============================================================================
# Arguments:
#   $1 - (required) Path to plugin.json file
#
# Returns:
#   0 - All dependencies satisfied (or jq not available)
#   1 - One or more dependencies missing
#
# Output:
#   stderr - Warnings for missing dependencies
#   stdout - Debug info if FLOW_DEBUG is set
#
# Example:
#   if _flow_plugin_check_deps "/path/to/plugin/plugin.json"; then
#     _flow_plugin_load "/path/to/plugin"
#   fi
#
# Dependencies:
#   - jq (optional, returns 0 if jq not available)
#   - _flow_log_warning (lib/core.zsh)
#   - _flow_log_info (lib/core.zsh)
#
# Notes:
#   - Checks tools in dependencies.tools array
#   - Checks flow version in dependencies.flow (warning only)
#   - Gracefully handles missing jq (assumes deps OK)
#   - Tool checks use `command -v` for availability
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_enable
# Purpose: Enable a plugin and persist the setting
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name to enable
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Success message
#
# Example:
#   _flow_plugin_enable "my-plugin"
#
# Dependencies:
#   - _flow_plugin_registry_save
#   - _flow_log_success (lib/core.zsh)
#
# Notes:
#   - Updates in-memory state immediately
#   - Persists to plugin registry file
#   - Plugin will be loaded on next shell start
#   - To load immediately, use _flow_plugin_load
# =============================================================================
_flow_plugin_enable() {
  local name="$1"

  _FLOW_PLUGIN_ENABLED[$name]=1
  _flow_plugin_registry_save
  _flow_log_success "Enabled plugin: $name"
}

# =============================================================================
# Function: _flow_plugin_disable
# Purpose: Disable a plugin and persist the setting
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name to disable
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Success message with reload reminder
#
# Example:
#   _flow_plugin_disable "my-plugin"
#
# Dependencies:
#   - _flow_plugin_registry_save
#   - _flow_log_success (lib/core.zsh)
#
# Notes:
#   - Updates in-memory state immediately
#   - Persists to plugin registry file
#   - Requires shell reload to fully unload plugin
#   - Already-loaded code remains in memory until restart
# =============================================================================
_flow_plugin_disable() {
  local name="$1"

  _FLOW_PLUGIN_ENABLED[$name]=0
  _flow_plugin_registry_save
  _flow_log_success "Disabled plugin: $name (reload shell to take effect)"
}

# =============================================================================
# Function: _flow_plugin_is_disabled
# Purpose: Check if a plugin is disabled in the persistent registry
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name to check
#
# Returns:
#   0 - Plugin is explicitly disabled
#   1 - Plugin is not disabled (or registry unavailable)
#
# Output:
#   None
#
# Example:
#   if _flow_plugin_is_disabled "my-plugin"; then
#     echo "Plugin is disabled"
#   fi
#
# Dependencies:
#   - jq (optional, returns 1 if jq not available)
#
# Notes:
#   - Reads from FLOW_PLUGIN_REGISTRY file
#   - Returns false if registry doesn't exist
#   - Returns false if jq is not available
#   - Different from _flow_plugin_enabled (checks runtime state)
# =============================================================================
_flow_plugin_is_disabled() {
  local name="$1"

  if [[ -f "$FLOW_PLUGIN_REGISTRY" ]] && command -v jq >/dev/null 2>&1; then
    local disabled=$(jq -r ".disabled[] // empty | select(. == \"$name\")" "$FLOW_PLUGIN_REGISTRY" 2>/dev/null)
    [[ -n "$disabled" ]]
  else
    return 1
  fi
}

# =============================================================================
# Function: _flow_plugin_registry_save
# Purpose: Persist plugin enable/disable state to registry file
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   None (writes to FLOW_PLUGIN_REGISTRY file)
#
# Example:
#   _FLOW_PLUGIN_ENABLED[my-plugin]=0
#   _flow_plugin_registry_save
#
# Dependencies:
#   None
#
# Notes:
#   - Creates registry directory if needed
#   - Writes JSON format with version, disabled list, timestamp
#   - Only stores disabled plugins (enabled is default)
#   - Called automatically by _flow_plugin_enable/_flow_plugin_disable
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_registry_load
# Purpose: Load plugin enable/disable state from registry file
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   None (updates _FLOW_PLUGIN_ENABLED array)
#
# Example:
#   _flow_plugin_registry_load
#   # _FLOW_PLUGIN_ENABLED now reflects persisted state
#
# Dependencies:
#   - jq (optional, no-op if jq not available)
#
# Notes:
#   - Reads from FLOW_PLUGIN_REGISTRY file
#   - No-op if registry file doesn't exist
#   - No-op if jq is not available
#   - Called automatically by _flow_plugin_init
# =============================================================================
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

# =============================================================================
# Function: _flow_hook_register
# Purpose: Register a callback function for a hook event
# =============================================================================
# Arguments:
#   $1 - (required) Event name (must be in FLOW_HOOK_EVENTS)
#   $2 - (required) Callback function name (must exist)
#
# Returns:
#   0 - Hook registered successfully
#   1 - Invalid event name or callback not found
#
# Output:
#   stderr - Error messages for invalid event/callback
#   stdout - Debug info if FLOW_DEBUG is set
#
# Example:
#   _my_plugin_on_finish() {
#     echo "Work session finished!"
#   }
#   _flow_hook_register "post-finish" "_my_plugin_on_finish"
#
# Dependencies:
#   - _flow_log_error (lib/core.zsh)
#   - _flow_log_info (lib/core.zsh)
#
# Notes:
#   - Valid events: post-work, pre-finish, post-finish, session-start,
#     session-end, project-change, pre-command, post-command
#   - Multiple callbacks can be registered for same event
#   - Callbacks stored as colon-separated list in _FLOW_HOOKS
#   - Callback must be a defined function at registration time
# =============================================================================
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

# =============================================================================
# Function: _flow_hook_run
# Purpose: Execute all registered callbacks for a hook event
# =============================================================================
# Arguments:
#   $1 - (required) Event name to trigger
#   $@ - (optional) Additional arguments passed to callbacks
#
# Returns:
#   0 - Always succeeds (individual callback failures are logged)
#
# Output:
#   stdout - Combined output from all callbacks
#   stderr - Warnings for failed callbacks
#
# Example:
#   _flow_hook_run "post-work" "$project_name"
#   _flow_hook_run "session-start"
#
# Dependencies:
#   - _flow_log_info (lib/core.zsh)
#   - _flow_log_warning (lib/core.zsh)
#
# Notes:
#   - Callbacks execute in registration order
#   - Failed callbacks don't prevent others from running
#   - No-op if no callbacks registered for event
#   - Arguments after event name are passed to each callback
# =============================================================================
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

# =============================================================================
# Function: _flow_hook_list
# Purpose: Display all registered hooks and their callbacks
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted list of events and their registered callbacks
#
# Example:
#   _flow_hook_list
#   # Output:
#   # Registered hooks:
#   #   post-work:
#   #     - _my_plugin_on_work
#   #   session-start:
#   #     - _another_callback
#
# Dependencies:
#   None
#
# Notes:
#   - Only shows events that have registered callbacks
#   - Events without callbacks are not displayed
#   - Useful for debugging plugin hook registration
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_list
# Purpose: Display all installed plugins with their status
# =============================================================================
# Arguments:
#   $1 - (optional) "true" to show available but not loaded plugins
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted plugin list with name, version, path, status
#
# Example:
#   _flow_plugin_list           # Show installed only
#   _flow_plugin_list "true"    # Also show available plugins
#
# Dependencies:
#   - _flow_plugin_discover
#   - _flow_plugin_metadata
#   - _flow_plugin_exists
#
# Notes:
#   - Shows checkmark for enabled, circle for disabled
#   - Displays version and installation path
#   - "Available" section shows discovered but unloaded plugins
#   - Uses FLOW_COLORS for terminal formatting
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_init
# Purpose: Initialize the plugin system and load all enabled plugins
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Debug info if FLOW_DEBUG is set
#
# Example:
#   _flow_plugin_init  # Called once during shell startup
#
# Dependencies:
#   - _flow_plugin_registry_load
#   - _flow_plugin_load_all
#   - _flow_hook_run
#
# Notes:
#   - Should be called once during shell initialization
#   - Loads registry (disabled plugins list)
#   - Creates user plugin directory if missing
#   - Loads all enabled plugins
#   - Triggers "session-start" hook after loading
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_cleanup
# Purpose: Clean up plugin system on shell exit
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   None
#
# Example:
#   # Typically called via zshexit hook:
#   zshexit() { _flow_plugin_cleanup }
#
# Dependencies:
#   - _flow_hook_run
#
# Notes:
#   - Triggers "session-end" hook for cleanup tasks
#   - Should be registered with shell exit mechanism
#   - Allows plugins to save state, close connections, etc.
# =============================================================================
_flow_plugin_cleanup() {
  _flow_hook_run "session-end"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# =============================================================================
# Function: _flow_plugin_config_get
# Purpose: Retrieve a configuration value for the current plugin
# =============================================================================
# Arguments:
#   $1 - (required) Configuration key name
#   $2 - (optional) Default value if key not found [default: empty]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Configuration value or default
#
# Example:
#   # In a plugin's main.zsh:
#   local api_key=$(_flow_plugin_config_get "api_key" "default_key")
#   local timeout=$(_flow_plugin_config_get "timeout" "30")
#
# Dependencies:
#   None
#
# Notes:
#   - Config file: ~/.config/flow/plugins/<plugin>/config.zsh
#   - Key is converted to PLUGIN_NAME_KEY_NAME format
#   - Underscores replace hyphens in names
#   - Uses _FLOW_CURRENT_PLUGIN_NAME to determine context
#   - Returns default if config file doesn't exist
# =============================================================================
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

# =============================================================================
# Function: _flow_plugin_create
# Purpose: Create a new plugin from template with boilerplate structure
# =============================================================================
# Arguments:
#   $1 - (required) Plugin name (used for directory and identifiers)
#   $2 - (optional) Base directory [default: ~/.config/flow/plugins]
#
# Returns:
#   0 - Plugin created successfully
#   1 - Plugin already exists at target path
#
# Output:
#   stdout - Success message and next steps instructions
#   stderr - Error if plugin already exists
#
# Example:
#   _flow_plugin_create "my-awesome-plugin"
#   _flow_plugin_create "custom-plugin" "/custom/plugins/dir"
#
# Dependencies:
#   - _flow_log_error (lib/core.zsh)
#   - _flow_log_success (lib/core.zsh)
#
# Notes:
#   - Creates plugin.json with metadata template
#   - Creates main.zsh with example command and hook
#   - Sets author to $USER and date to current date
#   - Plugin is ready to customize after creation
#   - Requires shell reload to activate new plugin
# =============================================================================
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
