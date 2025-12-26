# example plugin for flow-cli
# Demonstrates plugin capabilities: commands, hooks, and API usage
#
# Created: 2025-12-26
# Version: 1.0.0

# ============================================================================
# REGISTRATION
# ============================================================================

_flow_plugin_register "example" "1.0.0" "Example plugin demonstrating flow-cli capabilities"

# ============================================================================
# COMMANDS
# ============================================================================

# Simple hello command
example_hello() {
  echo ""
  echo "${FLOW_COLORS[header]}👋 HELLO FROM EXAMPLE PLUGIN${FLOW_COLORS[reset]}"
  echo ""
  echo "  This is a demonstration plugin showing how to:"
  echo "  • Register commands"
  echo "  • Use flow-cli colors and utilities"
  echo "  • Hook into flow events"
  echo ""
  echo "  Plugin path: ${_FLOW_PLUGINS[example]:-unknown}"
  echo "  Plugin version: ${_FLOW_PLUGIN_VERSIONS[example]:-unknown}"
  echo ""
}

# Status command showing plugin info
example_status() {
  echo ""
  echo "${FLOW_COLORS[header]}📊 EXAMPLE PLUGIN STATUS${FLOW_COLORS[reset]}"
  echo ""

  # Show plugin info
  echo "  ${FLOW_COLORS[bold]}Plugin Info${FLOW_COLORS[reset]}"
  echo "  Name:     example"
  echo "  Version:  ${_FLOW_PLUGIN_VERSIONS[example]:-unknown}"
  echo "  Path:     ${_FLOW_PLUGINS[example]:-unknown}"
  echo ""

  # Show registered hooks
  echo "  ${FLOW_COLORS[bold]}Registered Hooks${FLOW_COLORS[reset]}"
  local has_hooks=false
  for event in "${FLOW_HOOK_EVENTS[@]}"; do
    local callbacks="${_FLOW_HOOKS[$event]:-}"
    if [[ "$callbacks" == *"_example_"* ]]; then
      echo "  ✓ $event"
      has_hooks=true
    fi
  done
  [[ "$has_hooks" == "false" ]] && echo "  (none)"
  echo ""

  # Show flow-cli info
  echo "  ${FLOW_COLORS[bold]}Flow-CLI Context${FLOW_COLORS[reset]}"
  echo "  Version:  ${FLOW_VERSION:-unknown}"
  echo "  Plugins:  ${#_FLOW_PLUGINS[@]} loaded"

  if _flow_in_project 2>/dev/null; then
    local proj=$(_flow_project_name "$(_flow_find_project_root)" 2>/dev/null)
    echo "  Project:  $proj"
  else
    echo "  Project:  (not in project)"
  fi
  echo ""
}

# ============================================================================
# HOOKS
# ============================================================================

# Called after 'work <project>'
_example_on_work() {
  local project="$1"

  # Only show message if FLOW_DEBUG is set (to avoid cluttering output)
  if [[ -n "${FLOW_DEBUG:-}" ]]; then
    echo ""
    echo "${FLOW_COLORS[muted]}[example plugin] Started working on: $project${FLOW_COLORS[reset]}"
  fi
}

# Called after 'finish'
_example_on_finish() {
  local project="$1"

  if [[ -n "${FLOW_DEBUG:-}" ]]; then
    echo ""
    echo "${FLOW_COLORS[muted]}[example plugin] Finished working on: $project${FLOW_COLORS[reset]}"
  fi
}

# Register hooks
_flow_hook_register "post-work" "_example_on_work"
_flow_hook_register "post-finish" "_example_on_finish"

# ============================================================================
# HELP
# ============================================================================

example_help() {
  echo ""
  echo "${FLOW_COLORS[bold]}example${FLOW_COLORS[reset]} - Example plugin for flow-cli"
  echo ""
  echo "${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}"
  echo "  example_hello     Show hello message"
  echo "  example_status    Show plugin status"
  echo "  example_help      Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}HOOKS${FLOW_COLORS[reset]}"
  echo "  post-work         Logs when you start working"
  echo "  post-finish       Logs when you finish"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  # Run hello command"
  echo "  example_hello"
  echo ""
  echo "  # Check plugin status"
  echo "  example_status"
  echo ""
  echo "  # Enable debug output for hooks"
  echo "  FLOW_DEBUG=1 work myproject"
  echo ""
}
