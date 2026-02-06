#!/bin/zsh
#
# Obsidian CLI Ops (obs)
# ======================
# CLI tool for managing Obsidian vaults with AI-powered graph analysis.
#
# Version: 3.0.0-dev (Proposal A - Pure Obsidian Manager)
# Author: Data-Wise
# Project: obsidian-cli-ops
#
# DEPENDENCIES:
# - python3 (with requirements.txt)
# - jq (for vault operations)
#
# CONFIGURATION:
# - Database: ~/.config/obs/obsidian_vaults.db
# - Last vault: ~/.config/obs/last_vault
# - iCloud default: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents

# --- Configuration ---
LAST_VAULT_FILE="$HOME/.config/obs/last_vault"
ICLOUD_OBSIDIAN="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"

_ensure_config_dir() {
    mkdir -p "$HOME/.config/obs"
}

_save_last_vault() {
    local vault_id=$1
    _ensure_config_dir
    echo "$vault_id" > "$LAST_VAULT_FILE"
    _log_verbose "Saved last vault: $vault_id"
}

_get_last_vault() {
    if [[ -f "$LAST_VAULT_FILE" ]]; then
        cat "$LAST_VAULT_FILE"
    fi
}

# Defaults
VERBOSE=false
VERSION="3.0.0-dev"

# --- Helper Functions ---

_log() {
    local type=$1
    local msg=$2

    # Check if colors should be disabled
    if [[ -n "$NO_COLOR" ]] || [[ ! -t 1 ]]; then
        # No color output
        case $type in
            "INFO") echo "[INFO] $msg" ;;
            "SUCCESS") echo "[OK] $msg" ;;
            "WARN") echo "[WARN] $msg" ;;
            "ERROR") echo "[ERROR] $msg" ;;
        esac
    else
        # Colored output
        case $type in
            "INFO") echo "\033[0;34m[INFO]\033[0m $msg" ;;
            "SUCCESS") echo "\033[0;32m[OK]\033[0m $msg" ;;
            "WARN") echo "\033[0;33m[WARN]\033[0m $msg" ;;
            "ERROR") echo "\033[0;31m[ERROR]\033[0m $msg" ;;
        esac
    fi
}

_log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        if [[ -n "$NO_COLOR" ]] || [[ ! -t 1 ]]; then
            echo "[VERBOSE] $1"
        else
            echo "\033[0;90m[VERBOSE]\033[0m $1"
        fi
    fi
}

# --- Subcommands ---

_obs_help() {
    # Color fallbacks (in case core.zsh not loaded)
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
${_C_BOLD}│ obs - Obsidian Vault Manager                │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}obs${_C_NC}                 List vaults
  ${_C_CYAN}obs stats <vault>${_C_NC}   Show vault statistics
  ${_C_CYAN}obs discover <path>${_C_NC} Find vaults in directory

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} obs                      ${_C_DIM}# List all vaults${_C_NC}
  ${_C_DIM}\$${_C_NC} obs stats research       ${_C_DIM}# Stats for vault${_C_NC}
  ${_C_DIM}\$${_C_NC} obs discover ~/Documents ${_C_DIM}# Find new vaults${_C_NC}
  ${_C_DIM}\$${_C_NC} obs analyze research     ${_C_DIM}# Graph analysis${_C_NC}

${_C_BLUE}📋 VAULT COMMANDS${_C_NC}:
  ${_C_CYAN}obs vaults${_C_NC}           List all registered vaults
  ${_C_CYAN}obs stats [vault]${_C_NC}    Show vault statistics
  ${_C_CYAN}obs discover <path>${_C_NC}  Find vaults in directory
  ${_C_CYAN}obs analyze <vault>${_C_NC}  Analyze vault graph metrics

${_C_BLUE}📋 AI FEATURES${_C_NC}:
  ${_C_CYAN}obs ai status${_C_NC}        Show AI provider status
  ${_C_CYAN}obs ai setup${_C_NC}         Interactive AI setup wizard
  ${_C_CYAN}obs ai test${_C_NC}          Test all AI providers
  ${_C_CYAN}obs ai similar <n>${_C_NC}   Find similar notes
  ${_C_CYAN}obs ai analyze <n>${_C_NC}   Analyze note with AI
  ${_C_CYAN}obs ai duplicates${_C_NC}    Find duplicate notes

${_C_MAGENTA}💡 TIP${_C_NC}: Use ${_C_CYAN}obs stats <vault_id>${_C_NC} for detailed vault info
  ${_C_DIM}Get vault IDs with: obs vaults${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}dot${_C_NC} - Dotfile management
  ${_C_CYAN}mcp${_C_NC} - MCP server management
"
}

# Legacy alias for backward compatibility
obs_help() { _obs_help "$@"; }

obs_version() {
    echo "obs (Obsidian CLI Ops) version $VERSION"
    echo ""
    echo "A command-line tool for managing Obsidian vaults"
    echo "with AI-powered knowledge graph analysis."
    echo ""
    echo "Repository: https://github.com/Data-Wise/obsidian-cli-ops"
    echo "Documentation: https://data-wise.github.io/obsidian-cli-ops/"
}

# --- Legacy v1.x Commands Removed ---
# The following v1.x commands were removed in Phase 7.1 Part 3 (CLI consolidation):
# - obs_check() → dependency checking (low value)
# - obs_audit() → vault structure audit (OBS_ROOT required)
# - obs_sync() → configuration sync (OBS_ROOT required)
# - obs_install() → plugin installation (OBS_ROOT required)
# - obs_search() → plugin search (low usage)
# - obs_list() → vault listing (replaced by 'obs vaults')

# --- Knowledge Graph Commands (v2.0) ---

_get_python_cli() {
    # Get path to Python CLI
    # When obs.zsh is in src/, Python CLI is in src/python/
    local script_path="${(%):-%x}"  # Path to current script
    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"
    local python_cli="$script_dir/python/obs_cli.py"

    if [[ ! -f "$python_cli" ]]; then
        _log "ERROR" "Python CLI not found at: $python_cli" >&2
        _log "ERROR" "Script dir: $script_dir" >&2
        return 1
    fi

    echo "$python_cli"
}

obs_discover() {
    local python_cli=$(_get_python_cli) || return 1
    local vault_path=${1:-.}  # Default to current directory

    _log_verbose "Running vault discovery in: $vault_path"

    # Build command
    local cmd=("$python_cli" "discover" "$vault_path")

    # Add verbose flag if enabled
    if [[ "$VERBOSE" == "true" ]]; then
        cmd+=(--verbose)
    fi

    # Add --scan flag if requested
    if [[ "$2" == "--scan" ]]; then
        cmd+=(--scan)
    fi

    /opt/homebrew/bin/python3 "${cmd[@]}"
}

obs_analyze() {
    local python_cli=$(_get_python_cli) || return 1
    local vault_id=$1

    if [[ -z "$vault_id" ]]; then
        _log "ERROR" "Vault ID required"
        echo "Usage: obs analyze <vault_id>"
        echo ""
        echo "Get vault IDs with: obs vaults"
        return 1
    fi

    _log_verbose "Analyzing vault: $vault_id"

    # Build command
    local cmd=("$python_cli" "analyze" "$vault_id")

    # Add verbose flag if enabled
    if [[ "$VERBOSE" == "true" ]]; then
        cmd+=(--verbose)
    fi

    /opt/homebrew/bin/python3 "${cmd[@]}"
}

obs_vaults() {
    local python_cli=$(_get_python_cli) || return 1

    _log_verbose "Listing vaults in database"

    /opt/homebrew/bin/python3 "$python_cli" vaults
}

obs_stats() {
    local python_cli=$(_get_python_cli) || return 1
    local vault_id=$1

    _log_verbose "Showing statistics"

    if [[ -n "$vault_id" ]]; then
        /opt/homebrew/bin/python3 "$python_cli" stats --vault "$vault_id"
    else
        /opt/homebrew/bin/python3 "$python_cli" stats
    fi
}

# --- AI Commands (v2.0) ---

obs_ai() {
    local python_cli=$(_get_python_cli) || return 1
    local subcmd=$1
    shift

    case "$subcmd" in
        status)
            _log_verbose "Showing AI provider status"
            /opt/homebrew/bin/python3 "$python_cli" "ai" "status"
            ;;

        setup)
            _log_verbose "Running AI setup wizard"
            /opt/homebrew/bin/python3 "$python_cli" "ai" "setup"
            ;;

        test)
            _log_verbose "Testing AI providers"
            local cmd=("$python_cli" "ai" "test")

            # Add --provider flag if specified
            if [[ "$1" == "--provider" ]]; then
                cmd+=(--provider "$2")
            fi

            /opt/homebrew/bin/python3 "${cmd[@]}"
            ;;

        similar)
            local note_id=$1
            if [[ -z "$note_id" ]]; then
                _log "ERROR" "Note ID required"
                echo "Usage: obs ai similar <note_id>"
                return 1
            fi
            _log_verbose "Finding similar notes"
            /opt/homebrew/bin/python3 "$python_cli" "ai" "similar" "$note_id"
            ;;

        analyze)
            local note_id=$1
            if [[ -z "$note_id" ]]; then
                _log "ERROR" "Note ID required"
                echo "Usage: obs ai analyze <note_id>"
                return 1
            fi
            _log_verbose "Analyzing note with AI"
            /opt/homebrew/bin/python3 "$python_cli" "ai" "analyze" "$note_id"
            ;;

        duplicates)
            local vault_id=$1
            if [[ -z "$vault_id" ]]; then
                _log "ERROR" "Vault ID required"
                echo "Usage: obs ai duplicates <vault_id>"
                return 1
            fi
            _log_verbose "Finding duplicate notes"
            /opt/homebrew/bin/python3 "$python_cli" "ai" "duplicates" "$vault_id"
            ;;

        *)
            _log "ERROR" "Unknown ai subcommand: $subcmd"
            echo "Usage: obs ai <subcommand>"
            echo ""
            echo "Subcommands:"
            echo "  status              - Show AI provider status"
            echo "  setup               - Interactive AI setup wizard"
            echo "  test                - Test all AI providers"
            echo "  test --provider X   - Test specific provider"
            echo "  similar <note_id>   - Find similar notes"
            echo "  analyze <note_id>   - Analyze note with AI"
            echo "  duplicates <vault>  - Find duplicate notes"
            return 1
            ;;
    esac
}

# --- Option D Commands Removed ---
# The following commands were removed in Phase 7.1 Part 3 (CLI consolidation):
# - obs_switch() → replaced by 'obs' (default command shows vault list)
# - obs_open() → replaced by 'obs stats <vault_id>'
# - obs_manage() → functionality split into 'obs discover' and 'obs stats'
# - obs_graph() → replaced by 'obs analyze <vault_id>'

# --- Dispatch ---
obs() {
    # Handle help flags early (before global flag parser eats them)
    if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        _obs_help
        return 0
    fi

    # Parse global flags first
    while [[ "$1" == --* ]]; do
        case "$1" in
            --verbose|-v)
                VERBOSE=true
                _log_verbose "Verbose mode enabled"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local cmd=$1
    if [[ -n "$cmd" ]]; then
        shift
    fi

    # Default behavior (no command): Show vault list
    if [[ -z "$cmd" ]]; then
        obs_vaults
        return $?
    fi

    # Route to command handlers
    case "$cmd" in
        "help"|"--help"|"-h")
            _obs_help
            ;;
        "version")
            obs_version
            ;;
        "discover")
            obs_discover "$@"
            ;;
        "analyze")
            obs_analyze "$@"
            ;;
        "vaults")
            obs_vaults "$@"
            ;;
        "stats")
            obs_stats "$@"
            ;;
        "ai")
            obs_ai "$@"
            ;;
        *)
            _log "ERROR" "Unknown command: $cmd"
            echo ""
            _obs_help
            return 1
            ;;
    esac
}

# --- Execution Guard ---
# Execute the main function if the script is run directly.
# Check zsh_eval_context for Zsh and BASH_SOURCE for Bash.
if [[ "${zsh_eval_context[-1]}" == "toplevel" || "${BASH_SOURCE[0]}" == "${0}" ]]; then
    obs "$@"
fi
