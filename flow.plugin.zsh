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
: ${FLOW_LOAD_DISPATCHERS:=yes}     # Load v, g, mcp dispatchers

# ============================================================================
# CORE LIBRARY
# ============================================================================

source "$FLOW_PLUGIN_DIR/lib/core.zsh"
source "$FLOW_PLUGIN_DIR/lib/config.zsh"
source "$FLOW_PLUGIN_DIR/lib/atlas-bridge.zsh"
source "$FLOW_PLUGIN_DIR/lib/dotfile-helpers.zsh"
source "$FLOW_PLUGIN_DIR/lib/project-detector.zsh"
source "$FLOW_PLUGIN_DIR/lib/project-cache.zsh"
source "$FLOW_PLUGIN_DIR/lib/tui.zsh"
source "$FLOW_PLUGIN_DIR/lib/plugin-loader.zsh"
source "$FLOW_PLUGIN_DIR/lib/ai-recipes.zsh"
source "$FLOW_PLUGIN_DIR/lib/ai-usage.zsh"
source "$FLOW_PLUGIN_DIR/lib/help-browser.zsh"
source "$FLOW_PLUGIN_DIR/lib/inventory.zsh"
source "$FLOW_PLUGIN_DIR/lib/teaching-utils.zsh"
source "$FLOW_PLUGIN_DIR/lib/teach-style-helpers.zsh"
source "$FLOW_PLUGIN_DIR/lib/keychain-helpers.zsh"
source "$FLOW_PLUGIN_DIR/lib/backup-helpers.zsh"
source "$FLOW_PLUGIN_DIR/lib/cache-helpers.zsh"
source "$FLOW_PLUGIN_DIR/lib/cache-analysis.zsh"
source "$FLOW_PLUGIN_DIR/lib/status-dashboard.zsh"
source "$FLOW_PLUGIN_DIR/lib/email-helpers.zsh"
source "$FLOW_PLUGIN_DIR/lib/em-himalaya.zsh"
source "$FLOW_PLUGIN_DIR/lib/em-cache.zsh"
source "$FLOW_PLUGIN_DIR/lib/em-ai.zsh"
source "$FLOW_PLUGIN_DIR/lib/em-render.zsh"
source "$FLOW_PLUGIN_DIR/lib/em-ics.zsh"
source "$FLOW_PLUGIN_DIR/lib/em-watch.zsh"
source "$FLOW_PLUGIN_DIR/lib/tok-sync.zsh"

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

  # Commands flow-cli deliberately provides even when a PATH binary of the
  # same name exists (e.g. `cc` launches Claude Code, not the C compiler;
  # `r` is the R-package dispatcher, not Homebrew's R launcher). Pre-set
  # FLOW_INTENTIONAL_SHADOWS before sourcing the plugin to customize.
  if (( ! ${+FLOW_INTENTIONAL_SHADOWS} )); then
    typeset -ga FLOW_INTENTIONAL_SHADOWS=(r mcp cc)
  fi

  # Binary-precedence guard (B3): after sourcing the dispatcher files, drop any
  # newly-defined command function that would shadow an external PATH binary
  # — unless it's an intentional shadow (above) or forced via
  # FLOW_FORCE_DISPATCHER_<NAME>=1. Stops a broken dispatcher (historically
  # `obs`, which needed a Python CLI flow-cli never shipped) from masking a
  # working binary. Keys on the functions actually defined, so it needs no
  # filename convention and skips `_`-prefixed helpers automatically.
  #
  # Perf: snapshots the function table once around the whole batch (not per
  # file) and reads the fork-free ${commands} hash instead of $(whence -p),
  # keeping the guard's startup cost down on flow-cli's <10ms budget.
  _flow_load_dispatcher() {
    local -a _before _after _new
    _before=( ${(k)functions} )

    local file
    for file in "$@"; do
      source "$file"
    done

    _after=( ${(k)functions} )
    _new=( ${_after:|_before} )

    local fn force
    for fn in $_new; do
      [[ "$fn" == _* ]] && continue                            # internal helper
      (( ${FLOW_INTENTIONAL_SHADOWS[(Ie)$fn]} )) && continue   # deliberate shadow
      force="FLOW_FORCE_DISPATCHER_${fn:u}"
      [[ -n "${(P)force}" ]] && continue                       # explicit override
      [[ -n "${commands[$fn]}" ]] || continue                  # no PATH binary
      [[ -n "$FLOW_DEBUG" ]] && \
        print -ru2 -- "flow: dispatcher '$fn' shadows ${commands[$fn]} — skipped (set $force=1 or add to FLOW_INTENTIONAL_SHADOWS to keep)"
      unfunction "$fn"
    done
  }

  _flow_load_dispatcher "$FLOW_PLUGIN_DIR/lib/dispatchers/"*.zsh(N)
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
export FLOW_VERSION="7.9.0"

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
