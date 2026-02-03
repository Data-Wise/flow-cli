#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TM - Terminal Manager Dispatcher (aiterm integration)
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/tm-dispatcher.zsh
# Version:      1.0
# Date:         2025-12-30
# Pattern:      command + keyword + options
#
# Usage:        tm <action> [args]
#
# This file integrates aiterm into flow-cli's dispatcher system.
# It provides shell-native commands for speed and delegates to
# the aiterm Python CLI for rich features.
#
# ══════════════════════════════════════════════════════════════════════════════

# ============================================================================
# VERSION COMPATIBILITY
# ============================================================================

AITERM_FLOW_MIN_VERSION="3.6.0"
AITERM_FLOW_TESTED_VERSION="3.7.0"

_tm_check_version() {
    if [[ -z "$FLOW_VERSION" ]]; then
        return 0  # flow-cli not loaded, skip check
    fi

    # Simple version comparison (works for X.Y.Z format)
    if [[ "$FLOW_VERSION" < "$AITERM_FLOW_MIN_VERSION" ]]; then
        echo "Warning: aiterm requires flow-cli >= $AITERM_FLOW_MIN_VERSION (found $FLOW_VERSION)"
        return 1
    fi

    return 0
}

# ============================================================================
# AITERM AVAILABILITY CHECK
# ============================================================================

if ! command -v ait &>/dev/null; then
    _tm_not_installed() {
        echo "aiterm not installed."
        echo ""
        echo "Install with:"
        echo "  brew install data-wise/tap/aiterm"
        echo "  # or"
        echo "  pip install aiterm-dev"
        return 1
    }
    alias tm='_tm_not_installed'
    return 0
fi

# ============================================================================
# TERMINAL DETECTION
# ============================================================================

_tm_detect_terminal() {
    case "$TERM_PROGRAM" in
        iTerm.app)      echo "iterm2" ;;
        ghostty)        echo "ghostty" ;;
        WezTerm)        echo "wezterm" ;;
        Apple_Terminal) echo "terminal" ;;
        vscode)         echo "vscode" ;;
        *)
            if [[ -n "$KITTY_WINDOW_ID" ]]; then
                echo "kitty"
            elif [[ -n "$ALACRITTY_WINDOW_ID" ]]; then
                echo "alacritty"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# ============================================================================
# SHELL-NATIVE COMMANDS (instant, no Python)
# ============================================================================

# Set tab/window title (universal OSC 2)
_tm_set_title() {
    printf '\033]2;%s\007' "$*"
}

# Switch iTerm2 profile
_tm_switch_profile() {
    local profile="${1:-Default}"
    case "$TERM_PROGRAM" in
        iTerm.app)
            printf '\033]1337;SetProfile=%s\007' "$profile"
            ;;
        ghostty)
            echo "Ghostty: Profiles not supported. Use 'tm ghost theme <name>' instead"
            return 1
            ;;
        *)
            echo "Profile switching not supported for $TERM_PROGRAM"
            return 1
            ;;
    esac
}

# Set iTerm2 user variable (for status bar)
_tm_set_var() {
    local key="$1"
    local value="$2"
    if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        printf '\033]1337;SetUserVar=%s=%s\007' "$key" "$(echo -n "$value" | base64)"
    else
        echo "User variables only supported in iTerm2"
        return 1
    fi
}

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

tm() {
    # Check version compatibility on first use
    _tm_check_version

    case "$1" in
        # Shell-native commands (instant)
        title|t)
            shift
            if [[ -z "$*" ]]; then
                echo "Usage: tm title <text>"
                echo "Example: tm title Working on feature-x"
                return 1
            fi
            _tm_set_title "$@"
            ;;

        profile|p)
            shift
            _tm_switch_profile "$@"
            ;;

        var|v)
            shift
            if [[ $# -lt 2 ]]; then
                echo "Usage: tm var <key> <value>"
                echo "Example: tm var task 'Fixing bug'"
                return 1
            fi
            _tm_set_var "$1" "$2"
            ;;

        # Quick info (shell-native)
        which|w)
            _tm_detect_terminal
            ;;

        # Delegate to aiterm Python CLI
        ghost|g|ghostty)
            shift
            # ghostty command added in v0.3.9
            if ait ghostty --help &>/dev/null; then
                command ait ghostty "$@"
            else
                echo "ghostty subcommand requires aiterm >= 0.3.9"
                echo "Installed: $(ait --version 2>&1 | grep 'version' | head -1)"
                echo ""
                echo "Update with: brew upgrade aiterm"
                return 1
            fi
            ;;

        switch|s)
            shift
            command ait switch "$@"
            ;;

        detect|d)
            command ait detect
            ;;

        doctor)
            # Try terminals doctor first (v0.3.9+), fall back to main doctor
            if ait terminals doctor --help &>/dev/null; then
                command ait terminals doctor "$@"
            else
                command ait doctor
            fi
            ;;

        status)
            command ait terminals detect
            ;;

        compare)
            # compare added in v0.3.9
            if ait terminals compare --help &>/dev/null; then
                command ait terminals compare "$@"
            else
                echo "terminals compare requires aiterm >= 0.3.9"
                command ait terminals list
            fi
            ;;

        features)
            command ait terminals features "$@"
            ;;

        # Help
        help|--help|-h)
            _tm_help
            ;;

        # No args = help
        "")
            _tm_help
            ;;

        # Unknown → try aiterm directly
        *)
            command ait "$@"
            ;;
    esac
}

# ============================================================================
# HELP
# ============================================================================

_tm_help() {
    # Color fallbacks
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'
        _C_DIM='\033[2m'
        _C_NC='\033[0m'
        _C_GREEN='\033[32m'
        _C_YELLOW='\033[33m'
        _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ tm - Terminal Manager                        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}tm title <text>${_C_NC}     Set tab/window title
  ${_C_CYAN}tm profile <name>${_C_NC}   Switch iTerm2 profile
  ${_C_CYAN}tm which${_C_NC}            Show detected terminal
  ${_C_CYAN}tm switch${_C_NC}           Apply terminal context

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} tm title \"Feature XYZ\"    ${_C_DIM}# Set window title${_C_NC}
  ${_C_DIM}\$${_C_NC} tm profile dev            ${_C_DIM}# Switch to dev profile${_C_NC}
  ${_C_DIM}\$${_C_NC} tm which                  ${_C_DIM}# Detect current terminal${_C_NC}
  ${_C_DIM}\$${_C_NC} tm ghost theme catppuccin ${_C_DIM}# Set Ghostty theme${_C_NC}

${_C_BLUE}📋 SHELL-NATIVE${_C_NC} ${_C_DIM}(instant)${_C_NC}:
  ${_C_CYAN}tm title <text>${_C_NC}     Set tab/window title
  ${_C_CYAN}tm profile <name>${_C_NC}   Switch iTerm2 profile
  ${_C_CYAN}tm var <key> <val>${_C_NC}  Set iTerm2 status bar variable
  ${_C_CYAN}tm which${_C_NC}            Show detected terminal

${_C_BLUE}📋 AITERM DELEGATION${_C_NC}:
  ${_C_CYAN}tm ghost${_C_NC}            Ghostty status
  ${_C_CYAN}tm ghost theme${_C_NC}      List/set Ghostty themes
  ${_C_CYAN}tm ghost font${_C_NC}       Get/set Ghostty font
  ${_C_CYAN}tm switch${_C_NC}           Apply terminal context
  ${_C_CYAN}tm detect${_C_NC}           Detect project context
  ${_C_CYAN}tm doctor${_C_NC}           Check terminal health
  ${_C_CYAN}tm compare${_C_NC}          Compare terminal features

${_C_MAGENTA}💡 TIP${_C_NC}: Shortcuts: t=title p=profile v=var w=which g=ghost s=switch d=detect
  ${_C_DIM}Aliases: tmt=tm title, tmp=tm profile, tmg=tm ghost, tms=tm switch${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}work${_C_NC} - Start working (auto-sets terminal context)
  ${_C_CYAN}pick${_C_NC} - Project picker
  ${_C_CYAN}cc${_C_NC} - Launch Claude Code
  ${_C_DIM}Full docs: ait --help${_C_NC}
"
}

# ============================================================================
# ALIASES
# ============================================================================

alias tmt='tm title'
alias tmp='tm profile'
alias tmv='tm var'
alias tmw='tm which'
alias tmg='tm ghost'
alias tms='tm switch'
alias tmd='tm detect'

# ============================================================================
# CHPWD HOOK INTEGRATION
# ============================================================================

# Register callback with flow-cli's chpwd system if available
if (( ${+functions[_flow_chpwd_hook]} )); then
    # Add our callback to be called after directory change
    _tm_on_chpwd() {
        # Only if quiet mode requested and aiterm available
        if [[ -n "$TM_AUTO_SWITCH" ]] && command -v ait &>/dev/null; then
            command ait switch --quiet 2>/dev/null
        fi
    }

    # Append to existing chpwd hook
    if [[ -z "$_TM_CHPWD_REGISTERED" ]]; then
        _TM_CHPWD_REGISTERED=1
        # Note: flow-cli's hook system should call registered callbacks
        # This is a placeholder for future integration
    fi
fi

# ============================================================================
# INITIALIZATION
# ============================================================================

# Run version check silently on load
_tm_check_version 2>/dev/null

# Export for subshells
export TM_LOADED=1
