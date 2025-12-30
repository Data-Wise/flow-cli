# cc-dispatcher.zsh - Claude Code Dispatcher
# Smart Claude Code workflows for ADHD-optimized development

# ============================================================================
# CLAUDE CODE DISPATCHER
# ============================================================================

cc() {
    # No arguments → launch Claude in current directory (acceptEdits mode)
    if [[ $# -eq 0 ]]; then
        claude --permission-mode acceptEdits
        return
    fi

    # Check if first arg is a known subcommand
    local is_subcommand=0
    case "$1" in
        pick|yolo|y|plan|p|now|n|resume|r|continue|c|ask|a|file|f|diff|d|rpkg|print|pr|opus|o|haiku|h|wt|worktree|w|help|--help|-h)
            is_subcommand=1
            ;;
    esac

    # If not a subcommand, assume it's a project name (direct jump)
    if [[ $is_subcommand -eq 0 ]]; then
        local project_name="$1"
        shift
        if (( $+functions[pick] )); then
            # Use pick's direct jump, then launch Claude
            if pick "$project_name"; then
                claude --permission-mode acceptEdits "$@"
            fi
        else
            echo "❌ pick function not available" >&2
            return 1
        fi
        return
    fi

    case "$1" in
        # Pick project first, then launch
        pick)
            shift
            if (( $+functions[pick] )); then
                # Pass remaining args to pick (for filtering), not claude
                pick "$@" && claude --permission-mode acceptEdits
            else
                echo "❌ pick function not available" >&2
                return 1
            fi
            ;;

        # Launch modes
        yolo|y)
            shift
            # Check for 'pick' subcommand: cc yolo pick
            if [[ "$1" == "pick" ]]; then
                shift
                if (( $+functions[pick] )); then
                    # Pass remaining args to pick (for filtering), not claude
                    pick "$@" && claude --dangerously-skip-permissions
                else
                    echo "❌ pick function not available" >&2
                    return 1
                fi
            # Check if next arg is a project name (direct jump)
            elif [[ -n "$1" && "$1" != -* ]]; then
                local project_name="$1"
                shift
                if (( $+functions[pick] )); then
                    pick "$project_name" && claude --dangerously-skip-permissions "$@"
                else
                    claude --dangerously-skip-permissions "$@"
                fi
            else
                # No args after yolo → launch in current directory
                claude --dangerously-skip-permissions "$@"
            fi
            ;;

        plan|p)
            shift
            # Check for 'pick' subcommand: cc plan pick
            if [[ "$1" == "pick" ]]; then
                shift
                if (( $+functions[pick] )); then
                    # Pass remaining args to pick (for filtering), not claude
                    pick "$@" && claude --permission-mode plan
                else
                    echo "❌ pick function not available" >&2
                    return 1
                fi
            # Check if next arg is a project name (direct jump)
            elif [[ -n "$1" && "$1" != -* ]]; then
                local project_name="$1"
                shift
                if (( $+functions[pick] )); then
                    pick "$project_name" && claude --permission-mode plan "$@"
                else
                    claude --permission-mode plan "$@"
                fi
            else
                # No args after plan → launch in current directory
                claude --permission-mode plan "$@"
            fi
            ;;

        # Direct launch (DEPRECATED - default now does this)
        now|n)
            echo "⚠️  'cc now' is deprecated. Just use 'cc' (default is current dir now)" >&2
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
            # Check for 'pick' subcommand: cc opus pick
            if [[ "$1" == "pick" ]]; then
                shift
                if (( $+functions[pick] )); then
                    # Pass remaining args to pick (for filtering), not claude
                    pick "$@" && claude --model opus --permission-mode acceptEdits
                else
                    echo "❌ pick function not available" >&2
                    return 1
                fi
            # Check if next arg is a project name (direct jump)
            elif [[ -n "$1" && "$1" != -* ]]; then
                local project_name="$1"
                shift
                if (( $+functions[pick] )); then
                    pick "$project_name" && claude --model opus --permission-mode acceptEdits "$@"
                else
                    claude --model opus --permission-mode acceptEdits "$@"
                fi
            else
                # No args after opus → launch in current directory
                claude --model opus --permission-mode acceptEdits "$@"
            fi
            ;;

        haiku|h)
            shift
            # Check for 'pick' subcommand: cc haiku pick
            if [[ "$1" == "pick" ]]; then
                shift
                if (( $+functions[pick] )); then
                    # Pass remaining args to pick (for filtering), not claude
                    pick "$@" && claude --model haiku --permission-mode acceptEdits
                else
                    echo "❌ pick function not available" >&2
                    return 1
                fi
            # Check if next arg is a project name (direct jump)
            elif [[ -n "$1" && "$1" != -* ]]; then
                local project_name="$1"
                shift
                if (( $+functions[pick] )); then
                    pick "$project_name" && claude --model haiku --permission-mode acceptEdits "$@"
                else
                    claude --model haiku --permission-mode acceptEdits "$@"
                fi
            else
                # No args after haiku → launch in current directory
                claude --model haiku --permission-mode acceptEdits "$@"
            fi
            ;;

        # Worktree integration
        wt|worktree|w)
            shift
            _cc_worktree "$@"
            ;;

        # Help
        help|--help|-h)
            _cc_help
            ;;

        # Unknown command - should not reach here due to is_subcommand check
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
  ${_C_DIM}\$${_C_NC} cc                        ${_C_DIM}# Launch Claude HERE (current dir)${_C_NC}
  ${_C_DIM}\$${_C_NC} cc pick                   ${_C_DIM}# Pick project → Claude${_C_NC}
  ${_C_DIM}\$${_C_NC} cc flow                   ${_C_DIM}# Direct jump to flow-cli → Claude${_C_NC}

${_C_BLUE}🚀 LAUNCH MODES${_C_NC}:
  ${_C_CYAN}cc${_C_NC}                 Launch Claude HERE (acceptEdits mode)
  ${_C_CYAN}cc pick${_C_NC}            Pick project → Claude (acceptEdits)
  ${_C_CYAN}cc <project>${_C_NC}       Direct jump → Claude (no picker!)
  ${_C_CYAN}cc yolo${_C_NC}            Launch HERE in YOLO mode (skip permissions)
  ${_C_CYAN}cc yolo pick${_C_NC}       Pick project → YOLO mode
  ${_C_CYAN}cc plan${_C_NC}            Launch HERE in Plan mode
  ${_C_CYAN}cc plan pick${_C_NC}       Pick project → Plan mode

${_C_BLUE}🔄 SESSION${_C_NC}:
  ${_C_CYAN}cc resume${_C_NC}          Resume with Claude session picker
  ${_C_CYAN}cc continue${_C_NC}        Continue most recent Claude conversation

${_C_BLUE}❓ QUICK ACTIONS${_C_NC}:
  ${_C_CYAN}cc ask <question>${_C_NC}  Quick question (print mode)
  ${_C_CYAN}cc file <file>${_C_NC}     Analyze a file
  ${_C_CYAN}cc diff${_C_NC}            Review uncommitted changes
  ${_C_CYAN}cc rpkg${_C_NC}            R package context helper

${_C_BLUE}🎯 MODEL SELECTION${_C_NC}:
  ${_C_CYAN}cc opus${_C_NC}            Launch HERE with Opus model
  ${_C_CYAN}cc opus pick${_C_NC}       Pick project → Opus model
  ${_C_CYAN}cc haiku${_C_NC}           Launch HERE with Haiku model
  ${_C_CYAN}cc haiku pick${_C_NC}      Pick project → Haiku model

${_C_BLUE}📋 OTHER${_C_NC}:
  ${_C_CYAN}cc print <prompt>${_C_NC}  Print mode (non-interactive)
  ${_C_CYAN}cc help${_C_NC}            Show this help

${_C_MAGENTA}💡 DIRECT JUMP EXAMPLES${_C_NC}:
  cc flow           Direct → flow-cli + Claude
  cc med            Direct → mediationverse + Claude
  cc yolo stat      Direct → stat-440 + YOLO Claude

${_C_BLUE}🌳 WORKTREE${_C_NC}:
  ${_C_CYAN}cc wt <branch>${_C_NC}      Launch Claude in worktree (creates if needed)
  ${_C_CYAN}cc wt${_C_NC}               List worktrees
  ${_C_CYAN}cc wt pick${_C_NC}          Pick existing worktree → Claude
  ${_C_CYAN}cc wt yolo <branch>${_C_NC} Worktree + YOLO mode
  ${_C_CYAN}cc wt plan <branch>${_C_NC} Worktree + Plan mode
  ${_C_CYAN}cc wt opus <branch>${_C_NC} Worktree + Opus model

${_C_MAGENTA}💡 SHORTCUTS${_C_NC}:
  y = yolo, p = plan, r = resume, c = continue
  a = ask, f = file, d = diff, o = opus, h = haiku, pr = print
  w = wt (worktree)

${_C_MAGENTA}💡 WORKTREE ALIASES${_C_NC}:
  ccw = cc wt, ccwy = cc wt yolo, ccwp = cc wt pick
"
}

# ============================================================================
# WORKTREE INTEGRATION
# ============================================================================

_cc_worktree() {
    local mode=""
    local mode_args=""
    local branch=""

    # Parse mode if provided (yolo, plan, opus, haiku)
    case "$1" in
        yolo|y)
            mode="yolo"
            mode_args="--dangerously-skip-permissions"
            shift
            ;;
        plan|p)
            mode="plan"
            mode_args="--permission-mode plan"
            shift
            ;;
        opus|o)
            mode="opus"
            mode_args="--model opus --permission-mode acceptEdits"
            shift
            ;;
        haiku|h)
            mode="haiku"
            mode_args="--model haiku --permission-mode acceptEdits"
            shift
            ;;
        pick)
            shift
            _cc_worktree_pick "$@"
            return
            ;;
        help|--help|-h)
            _cc_worktree_help
            return
            ;;
    esac

    branch="$1"

    # No branch = list worktrees
    if [[ -z "$branch" ]]; then
        echo -e "${_C_BLUE}📋 Current worktrees:${_C_NC}"
        wt list
        echo ""
        echo -e "${_C_DIM}Usage: cc wt <branch> or cc wt pick${_C_NC}"
        return
    fi

    # Get or create worktree
    local wt_path
    wt_path=$(_wt_get_path "$branch")

    if [[ -z "$wt_path" ]]; then
        echo -e "${_C_BLUE}ℹ Creating worktree for $branch...${_C_NC}"
        wt create "$branch"
        wt_path=$(_wt_get_path "$branch")
    fi

    if [[ -z "$wt_path" ]]; then
        echo -e "${_C_RED}✗ Failed to get/create worktree for $branch${_C_NC}"
        return 1
    fi

    # Launch Claude in worktree
    echo -e "${_C_GREEN}✓ Launching Claude in $wt_path${_C_NC}"
    if [[ -n "$mode" ]]; then
        echo -e "${_C_DIM}Mode: $mode${_C_NC}"
    fi
    cd "$wt_path" && eval "claude $mode_args"
}

_cc_worktree_pick() {
    # Check for fzf
    if ! command -v fzf >/dev/null 2>&1; then
        echo -e "${_C_RED}✗ fzf required for pick mode${_C_NC}"
        echo ""
        echo -e "${_C_DIM}Install: brew install fzf${_C_NC}"
        echo ""
        echo "Current worktrees:"
        wt list
        return 1
    fi

    # Get worktrees in fzf-friendly format
    local selected
    selected=$(git worktree list --porcelain 2>/dev/null | \
        grep "^worktree " | \
        cut -d' ' -f2- | \
        fzf --prompt="Select worktree: " --height=40% --reverse)

    if [[ -n "$selected" ]]; then
        echo -e "${_C_GREEN}✓ Launching Claude in $selected${_C_NC}"
        cd "$selected" && claude --permission-mode acceptEdits
    else
        echo -e "${_C_DIM}No worktree selected${_C_NC}"
    fi
}

_cc_worktree_help() {
    echo -e "
${_C_YELLOW}╔════════════════════════════════════════════════════════════╗${_C_NC}
${_C_YELLOW}║${_C_NC}  ${_C_CYAN}CC WT${_C_NC} - Claude Code in Worktrees                        ${_C_YELLOW}║${_C_NC}
${_C_YELLOW}╚════════════════════════════════════════════════════════════╝${_C_NC}

${_C_YELLOW}💡 QUICK START${_C_NC}:
  ${_C_DIM}\$${_C_NC} cc wt feature/auth       ${_C_DIM}# Claude in worktree (creates if needed)${_C_NC}
  ${_C_DIM}\$${_C_NC} cc wt pick               ${_C_DIM}# Pick existing worktree → Claude${_C_NC}
  ${_C_DIM}\$${_C_NC} cc wt                    ${_C_DIM}# List worktrees${_C_NC}

${_C_BLUE}📋 COMMANDS${_C_NC}:
  ${_C_CYAN}cc wt <branch>${_C_NC}       Launch Claude in worktree
  ${_C_CYAN}cc wt${_C_NC}                List worktrees
  ${_C_CYAN}cc wt pick${_C_NC}           fzf picker for worktrees

${_C_BLUE}🚀 MODE CHAINING${_C_NC}:
  ${_C_CYAN}cc wt yolo <branch>${_C_NC}  Worktree + YOLO mode
  ${_C_CYAN}cc wt plan <branch>${_C_NC}  Worktree + Plan mode
  ${_C_CYAN}cc wt opus <branch>${_C_NC}  Worktree + Opus model
  ${_C_CYAN}cc wt haiku <branch>${_C_NC} Worktree + Haiku model

${_C_MAGENTA}💡 ALIASES${_C_NC}:
  ccw   = cc wt
  ccwy  = cc wt yolo
  ccwp  = cc wt pick

${_C_MAGENTA}💡 EXAMPLES${_C_NC}:
  ccw feature/auth     Launch in worktree
  ccwy feature/auth    YOLO mode in worktree
  ccwp                 Pick from existing worktrees
"
}

# ============================================================================
# ALIASES
# ============================================================================

alias ccw='cc wt'
alias ccwy='cc wt yolo'
alias ccwp='cc wt pick'
