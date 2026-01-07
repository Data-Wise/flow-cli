# flow.plugin.zsh - ZSH Plugin Entry Point
# ADHD-optimized workflow management for developers
#
# Installation:
#   antidote: antidote install data-wise/flow-cli
#   zinit:    zinit light data-wise/flow-cli
#   manual:   source /path/to/flow.plugin.zsh

# Plugin directory detection
0=${(%):-%N}
FLOW_PLUGIN_DIR=${0:A:h}

# ============================================================================
# CONFIGURATION
# ============================================================================

# Default paths (override in .zshrc before sourcing)
: ${FLOW_CONFIG_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/flow}
: ${FLOW_DATA_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/flow}
: ${FLOW_PROJECTS_ROOT:=$HOME/projects}

# Feature flags
: ${FLOW_ATLAS_ENABLED:=auto}       # auto|yes|no
: ${FLOW_LOAD_DISPATCHERS:=yes}     # Load v, g, mcp, obs dispatchers

# ============================================================================
# CORE LIBRARY
# ============================================================================

source "$FLOW_PLUGIN_DIR/lib/core.zsh"
source "$FLOW_PLUGIN_DIR/lib/config.zsh"
source "$FLOW_PLUGIN_DIR/lib/atlas-bridge.zsh"
source "$FLOW_PLUGIN_DIR/lib/project-detector.zsh"
source "$FLOW_PLUGIN_DIR/lib/tui.zsh"
source "$FLOW_PLUGIN_DIR/lib/plugin-loader.zsh"
source "$FLOW_PLUGIN_DIR/lib/ai-recipes.zsh"
source "$FLOW_PLUGIN_DIR/lib/ai-usage.zsh"
source "$FLOW_PLUGIN_DIR/lib/help-browser.zsh"
source "$FLOW_PLUGIN_DIR/lib/inventory.zsh"

# ============================================================================
# COMMANDS
# ============================================================================

for cmd_file in "$FLOW_PLUGIN_DIR/commands/"*.zsh(N); do
  source "$cmd_file"
done

# ============================================================================
# OPTIONAL: SPECIALIZED DISPATCHERS
# ============================================================================

if [[ "$FLOW_LOAD_DISPATCHERS" == "yes" ]]; then
  # Disable ZSH builtin 'r' (history repeat) to allow R dispatcher
  disable r

  for disp_file in "$FLOW_PLUGIN_DIR/lib/dispatchers/"*.zsh(N); do
    source "$disp_file"
  done
fi

# ============================================================================
# EXTERNAL INTEGRATIONS (via symlinks in zsh/functions/)
# ============================================================================

# Load symlinked integrations if they exist and resolve
for fn_file in "$FLOW_PLUGIN_DIR/zsh/functions/"*.zsh(N); do
  if [[ -L "$fn_file" ]] && [[ -e "$fn_file" ]]; then
    source "$fn_file"
  fi
done

# ============================================================================
# COMPLETIONS
# ============================================================================

fpath=("$FLOW_PLUGIN_DIR/completions" $fpath)

if [[ -d "$FLOW_PLUGIN_DIR/completions" ]]; then
  autoload -Uz compinit
  # Rebuild completion cache once per day
  if [[ -n "$FLOW_PLUGIN_DIR/completions"(#qNmh-20) ]]; then
    compinit -C
  else
    compinit
  fi
fi

# ============================================================================
# MAN PAGES
# ============================================================================

if [[ -d "$FLOW_PLUGIN_DIR/man" ]]; then
  export MANPATH="$FLOW_PLUGIN_DIR/man:${MANPATH:-}"
fi

# ============================================================================
# HOOKS
# ============================================================================

autoload -Uz add-zsh-hook

if [[ -f "$FLOW_PLUGIN_DIR/hooks/chpwd.zsh" ]]; then
  source "$FLOW_PLUGIN_DIR/hooks/chpwd.zsh"
  add-zsh-hook chpwd _flow_chpwd_hook
fi

if [[ -f "$FLOW_PLUGIN_DIR/hooks/precmd.zsh" ]]; then
  source "$FLOW_PLUGIN_DIR/hooks/precmd.zsh"
  add-zsh-hook precmd _flow_precmd_hook
fi

# ============================================================================
# INITIALIZATION
# ============================================================================

[[ -d "$FLOW_CONFIG_DIR" ]] || mkdir -p "$FLOW_CONFIG_DIR"
[[ -d "$FLOW_DATA_DIR" ]] || mkdir -p "$FLOW_DATA_DIR"

# Initialize atlas
_flow_init_atlas

# Initialize plugin system
_flow_plugin_init

# Export loaded marker
export FLOW_PLUGIN_LOADED=1
export FLOW_VERSION="4.8.1"

# Register exit hook for plugin cleanup
add-zsh-hook zshexit _flow_plugin_cleanup

# Welcome message (disable with FLOW_QUIET=1)
if [[ -z "$FLOW_QUIET" ]] && [[ -z "$FLOW_WELCOMED" ]]; then
  local plugin_count=${#_FLOW_PLUGINS[@]}
  if _flow_has_atlas; then
    _flow_log_debug "flow-cli v$FLOW_VERSION (atlas: connected, plugins: $plugin_count)"
  else
    _flow_log_debug "flow-cli v$FLOW_VERSION (standalone, plugins: $plugin_count)"
  fi
  export FLOW_WELCOMED=1
fi
