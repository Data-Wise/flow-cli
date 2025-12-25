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

# Default paths (can be overridden in .zshrc before sourcing)
: ${FLOW_CONFIG_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/flow}
: ${FLOW_DATA_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/flow}
: ${FLOW_PROJECTS_ROOT:=$HOME/projects}

# Atlas integration (optional but recommended)
: ${FLOW_ATLAS_ENABLED:=auto}  # auto|yes|no

# ============================================================================
# CORE LIBRARY
# ============================================================================

# Source core utilities first
source "$FLOW_PLUGIN_DIR/lib/core.zsh"

# Source atlas bridge (handles atlas integration gracefully)
source "$FLOW_PLUGIN_DIR/lib/atlas-bridge.zsh"

# Source project detection
source "$FLOW_PLUGIN_DIR/lib/project-detector.zsh"

# Source TUI components
source "$FLOW_PLUGIN_DIR/lib/tui.zsh"

# ============================================================================
# COMMANDS
# ============================================================================

# Source all command files
for cmd_file in "$FLOW_PLUGIN_DIR/commands/"*.zsh(N); do
  source "$cmd_file"
done

# ============================================================================
# LEGACY ZSH FUNCTIONS (from zsh/functions/)
# ============================================================================

# Source existing functions for backward compatibility
# These will be refactored into commands/ over time
if [[ -d "$FLOW_PLUGIN_DIR/zsh/functions" ]]; then
  for fn_file in "$FLOW_PLUGIN_DIR/zsh/functions/"*.zsh(N); do
    source "$fn_file"
  done
fi

# ============================================================================
# COMPLETIONS
# ============================================================================

# Add completions directory to fpath
fpath=("$FLOW_PLUGIN_DIR/completions" $fpath)

# Load completions if available
if [[ -d "$FLOW_PLUGIN_DIR/completions" ]]; then
  autoload -Uz compinit
  # Only rebuild completion dump once per day
  if [[ -n "$FLOW_PLUGIN_DIR/completions"(#qNmh-20) ]]; then
    compinit -C
  else
    compinit
  fi
fi

# ============================================================================
# HOOKS
# ============================================================================

# Load hook functions
autoload -Uz add-zsh-hook

# Directory change hook (for auto-detection)
if [[ -f "$FLOW_PLUGIN_DIR/hooks/chpwd.zsh" ]]; then
  source "$FLOW_PLUGIN_DIR/hooks/chpwd.zsh"
  add-zsh-hook chpwd _flow_chpwd_hook
fi

# Pre-command hook (for prompt integration)
if [[ -f "$FLOW_PLUGIN_DIR/hooks/precmd.zsh" ]]; then
  source "$FLOW_PLUGIN_DIR/hooks/precmd.zsh"
  add-zsh-hook precmd _flow_precmd_hook
fi

# ============================================================================
# INITIALIZATION
# ============================================================================

# Create config/data directories if they don't exist
[[ -d "$FLOW_CONFIG_DIR" ]] || mkdir -p "$FLOW_CONFIG_DIR"
[[ -d "$FLOW_DATA_DIR" ]] || mkdir -p "$FLOW_DATA_DIR"

# Initialize atlas connection if available
_flow_init_atlas

# Export plugin loaded marker
export FLOW_PLUGIN_LOADED=1

# Print welcome message (can be disabled with FLOW_QUIET=1)
if [[ -z "$FLOW_QUIET" ]] && [[ -z "$FLOW_WELCOMED" ]]; then
  if _flow_has_atlas; then
    _flow_log_debug "flow-cli loaded (atlas: connected)"
  else
    _flow_log_debug "flow-cli loaded (atlas: standalone mode)"
  fi
  export FLOW_WELCOMED=1
fi
