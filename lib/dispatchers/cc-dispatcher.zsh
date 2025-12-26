# cc-dispatcher.zsh - Claude Code Dispatcher
# Smart Claude Code workflows for ADHD-optimized development

# ============================================================================
# CLAUDE CODE DISPATCHER
# ============================================================================

cc() {
    # No arguments → pick project + launch claude in acceptEdits mode
    if [[ $# -eq 0 ]]; then
        if (( $+functions[pick] )); then
            pick && claude --permission-mode acceptEdits
        else
            claude --permission-mode acceptEdits
        fi
        return
    fi

    case "$1" in
        # Launch modes
        yolo|y)
            shift
            if (( $+functions[pick] )); then
                pick && claude --dangerously-skip-permissions "$@"
            else
                claude --dangerously-skip-permissions "$@"
            fi
            ;;

        plan|p)
            shift
            if (( $+functions[pick] )); then
                pick && claude --permission-mode plan "$@"
            else
                claude --permission-mode plan "$@"
            fi
            ;;

        # Direct launch (no picker)
        now|n)
            shift
            claude --permission-mode acceptEdits "$@"
            ;;

        # Resume/continue
        resume|r)
            shift
            claude -r "$@"
            ;;

        continue|c)
            claude -c
            ;;

        # Quick question (print mode)
        ask|a)
            shift
            if [[ -z "$*" ]]; then
                echo "Usage: cc ask <question>"
                echo "Example: cc ask how do I handle missing data in R?"
                return 1
            fi
            claude -p "$*"
            ;;

        # Analyze file
        file|f)
            shift
            local file="$1"
            shift
            local prompt="${*:-Explain this code in detail}"
            if [[ -z "$file" ]]; then
                echo "Usage: cc file <file> [prompt]"
                echo "Example: cc file R/myfunction.R explain this code"
                return 1
            fi
            if [[ ! -f "$file" ]]; then
                echo "Error: File not found: $file"
                return 1
            fi
            claude -p "$prompt" < "$file"
            ;;

        # Review git diff
        diff|d)
            shift
            if ! git rev-parse --git-dir > /dev/null 2>&1; then
                echo "Error: Not in a git repository"
                return 1
            fi
            local prompt="${*:-Review these changes for quality and correctness}"
            git diff | claude "$prompt"
            ;;

        # R package helper
        rpkg)
            shift
            if [[ ! -f "DESCRIPTION" ]]; then
                echo "Error: Not in an R package directory (no DESCRIPTION file)"
                return 1
            fi
            local pkg_name=$(grep "^Package:" DESCRIPTION | cut -d' ' -f2)
            claude "I'm working on the R package '$pkg_name'. $*"
            ;;

        # Print mode
        print|pr)
            shift
            claude -p "$@"
            ;;

        # Model selection
        opus|o)
            shift
            if (( $+functions[pick] )); then
                pick && claude --model opus --permission-mode acceptEdits "$@"
            else
                claude --model opus --permission-mode acceptEdits "$@"
            fi
            ;;

        haiku|h)
            shift
            if (( $+functions[pick] )); then
                pick && claude --model haiku --permission-mode acceptEdits "$@"
            else
                claude --model haiku --permission-mode acceptEdits "$@"
            fi
            ;;

        # Help
        help|--help|-h)
            _cc_help
            ;;

        # Unknown command
        *)
            echo "Unknown command: $1"
            echo "Run 'cc help' for usage"
            return 1
            ;;
    esac
}

# ============================================================================
# HELP
# ============================================================================

_cc_help() {
    # Use flow-cli colors if available, otherwise define fallbacks
    local _C_CYAN="${_C_CYAN:-\033[0;36m}"
    local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
    local _C_BLUE="${_C_BLUE:-\033[0;34m}"
    local _C_MAGENTA="${_C_MAGENTA:-\033[0;35m}"
    local _C_DIM="${_C_DIM:-\033[2m}"
    local _C_NC="${_C_NC:-\033[0m}"

    echo "
${_C_YELLOW}╔════════════════════════════════════════════════════════════╗${_C_NC}
${_C_YELLOW}║${_C_NC}  ${_C_CYAN}CC${_C_NC} - Claude Code Dispatcher                              ${_C_YELLOW}║${_C_NC}
${_C_YELLOW}╚════════════════════════════════════════════════════════════╝${_C_NC}

${_C_YELLOW}💡 QUICK START${_C_NC}:
  ${_C_DIM}\$${_C_NC} cc                        ${_C_DIM}# Pick project → acceptEdits mode${_C_NC}
  ${_C_DIM}\$${_C_NC} cc yolo                   ${_C_DIM}# Pick project → YOLO mode${_C_NC}
  ${_C_DIM}\$${_C_NC} cc now                    ${_C_DIM}# Launch here (no picker)${_C_NC}

${_C_BLUE}🚀 LAUNCH MODES${_C_NC}:
  ${_C_CYAN}cc${_C_NC}                 Pick project → acceptEdits mode
  ${_C_CYAN}cc yolo${_C_NC}            Pick project → YOLO mode (skip all permissions)
  ${_C_CYAN}cc plan${_C_NC}            Pick project → Plan mode (review before executing)
  ${_C_CYAN}cc now${_C_NC}             Launch here without picker

${_C_BLUE}🔄 SESSION${_C_NC}:
  ${_C_CYAN}cc resume${_C_NC}          Resume with session picker
  ${_C_CYAN}cc continue${_C_NC}        Continue most recent conversation

${_C_BLUE}❓ QUICK ACTIONS${_C_NC}:
  ${_C_CYAN}cc ask <question>${_C_NC}  Quick question (print mode)
  ${_C_CYAN}cc file <file>${_C_NC}     Analyze a file
  ${_C_CYAN}cc diff${_C_NC}            Review uncommitted changes
  ${_C_CYAN}cc rpkg${_C_NC}            R package context helper

${_C_BLUE}🎯 MODEL SELECTION${_C_NC}:
  ${_C_CYAN}cc opus${_C_NC}            Pick project → Use Opus model
  ${_C_CYAN}cc haiku${_C_NC}           Pick project → Use Haiku model

${_C_BLUE}📋 OTHER${_C_NC}:
  ${_C_CYAN}cc print <prompt>${_C_NC}  Print mode (non-interactive)
  ${_C_CYAN}cc help${_C_NC}            Show this help

${_C_MAGENTA}💡 SHORTCUTS${_C_NC}:
  y = yolo, p = plan, n = now, r = resume, c = continue
  a = ask, f = file, d = diff, o = opus, h = haiku, pr = print

${_C_MAGENTA}💡 TIP${_C_NC}: Run ${_C_CYAN}cc${_C_NC} with no arguments to pick a project and start coding!
"
}
