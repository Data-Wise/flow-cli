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

    # Check if first arg is a mode (unified pattern: cc [mode] [target])
    case "$1" in
        yolo|y|plan|p|opus|o|haiku|h)
            _cc_dispatch_with_mode "$@"
            return
            ;;
    esac

    # Check if first arg is a known subcommand
    local is_subcommand=0
    case "$1" in
        pick|now|n|resume|r|continue|c|ask|a|file|f|diff|d|rpkg|print|pr|wt|worktree|w|help|--help|-h)
            is_subcommand=1
            ;;
    esac

    # If not a subcommand, assume it's a project name (direct jump)
    if [[ $is_subcommand -eq 0 ]]; then
        local project_name="$1"
        shift
        if (( $+functions[pick] )); then
            # Use pick's direct jump, then launch Claude
            # --no-claude prevents pick's Ctrl-O/Y keybindings (we handle Claude)
            if pick --no-claude "$project_name"; then
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
                # --no-claude prevents pick's Ctrl-O/Y keybindings (we handle Claude)
                pick --no-claude "$@" && claude --permission-mode acceptEdits
            else
                echo "❌ pick function not available" >&2
                return 1
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

        # Worktree integration
        wt|worktree|w)
            shift
            _cc_worktree "acceptEdits" "$@"
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
# UNIFIED MODE DISPATCHER
# ============================================================================
# Handles: cc [mode] [target]
# Modes: yolo, plan, opus, haiku
# Targets: (here), pick, wt, <project>

_cc_dispatch_with_mode() {
    local mode="$1"
    shift

    # Normalize mode and get Claude args
    local mode_name mode_args
    case "$mode" in
        yolo|y)
            mode_name="yolo"
            mode_args="--dangerously-skip-permissions"
            ;;
        plan|p)
            mode_name="plan"
            mode_args="--permission-mode plan"
            ;;
        opus|o)
            mode_name="opus"
            mode_args="--model opus --permission-mode acceptEdits"
            ;;
        haiku|h)
            mode_name="haiku"
            mode_args="--model haiku --permission-mode acceptEdits"
            ;;
    esac

    # No target → launch HERE with mode
    if [[ $# -eq 0 ]]; then
        claude $mode_args
        return
    fi

    # Check target type
    case "$1" in
        pick)
            # cc [mode] pick → pick project with mode
            shift
            if (( $+functions[pick] )); then
                pick --no-claude "$@" && claude $mode_args
            else
                echo "❌ pick function not available" >&2
                return 1
            fi
            ;;

        wt|worktree|w)
            # cc [mode] wt → worktree with mode
            shift
            _cc_worktree "$mode_name" "$@"
            ;;

        -*)
            # Starts with dash → pass as args to Claude
            claude $mode_args "$@"
            ;;

        *)
            # Assume project name → direct jump with mode
            local project_name="$1"
            shift
            if (( $+functions[pick] )); then
                pick --no-claude "$project_name" && claude $mode_args "$@"
            else
                claude $mode_args "$@"
            fi
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

${_C_BLUE}🚀 LAUNCH MODES${_C_NC} (Unified Pattern: cc [mode] [target]):
  ${_C_CYAN}cc${_C_NC}                 Launch Claude HERE (acceptEdits mode)
  ${_C_CYAN}cc pick${_C_NC}            Pick project → Claude (acceptEdits)
  ${_C_CYAN}cc <project>${_C_NC}       Direct jump → Claude (no picker!)
  ${_C_CYAN}cc yolo${_C_NC}            Launch HERE in YOLO mode (skip permissions)
  ${_C_CYAN}cc yolo pick${_C_NC}       Pick project → YOLO mode
  ${_C_CYAN}cc yolo wt <branch>${_C_NC} Worktree → YOLO mode ${_C_DIM}(NEW!)${_C_NC}
  ${_C_CYAN}cc plan${_C_NC}            Launch HERE in Plan mode
  ${_C_CYAN}cc plan pick${_C_NC}       Pick project → Plan mode
  ${_C_CYAN}cc plan wt pick${_C_NC}    Pick worktree → Plan mode ${_C_DIM}(NEW!)${_C_NC}

${_C_BLUE}🔄 SESSION${_C_NC}:
  ${_C_CYAN}cc resume${_C_NC}          Resume with Claude session picker
  ${_C_CYAN}cc continue${_C_NC}        Continue most recent Claude conversation

${_C_BLUE}❓ QUICK ACTIONS${_C_NC}:
  ${_C_CYAN}cc ask <question>${_C_NC}  Quick question (print mode)
  ${_C_CYAN}cc file <file>${_C_NC}     Analyze a file
  ${_C_CYAN}cc diff${_C_NC}            Review uncommitted changes
  ${_C_CYAN}cc rpkg${_C_NC}            R package context helper

${_C_BLUE}🎯 MODEL SELECTION${_C_NC} (Unified Pattern):
  ${_C_CYAN}cc opus${_C_NC}            Launch HERE with Opus model
  ${_C_CYAN}cc opus pick${_C_NC}       Pick project → Opus model
  ${_C_CYAN}cc opus wt <branch>${_C_NC} Worktree → Opus model ${_C_DIM}(NEW!)${_C_NC}
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
  ccy = cc yolo (kept by user request!)

${_C_YELLOW}★ Unified Pattern${_C_NC}: Modes always come first!
  ${_C_CYAN}cc yolo wt <branch>${_C_NC}   ${_C_DIM}# Mode → target (NOW WORKS!)${_C_NC}
  ${_C_CYAN}cc plan wt pick${_C_NC}       ${_C_DIM}# Mode → target (NOW WORKS!)${_C_NC}
  ${_C_CYAN}cc opus wt <branch>${_C_NC}   ${_C_DIM}# Mode → target (NOW WORKS!)${_C_NC}
"
}

# ============================================================================
# WORKTREE INTEGRATION
# ============================================================================

_cc_worktree() {
    local mode="${1:-acceptEdits}"  # Accept mode as first parameter
    shift

    local mode_args=""
    case "$mode" in
        yolo)
            mode_args="--dangerously-skip-permissions"
            ;;
        plan)
            mode_args="--permission-mode plan"
            ;;
        opus)
            mode_args="--model opus --permission-mode acceptEdits"
            ;;
        haiku)
            mode_args="--model haiku --permission-mode acceptEdits"
            ;;
        acceptEdits)
            mode_args="--permission-mode acceptEdits"
            ;;
    esac

    # Parse old-style mode prefix (cc wt yolo <branch>) for backward compatibility
    # This maintains support for existing workflows
    case "$1" in
        status|st)
            shift
            _cc_worktree_status "$@"
            return
            ;;
        yolo|y)
            # Override mode if provided
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
            _cc_worktree_pick "$mode" "$mode_args" "$@"
            return
            ;;
        help|--help|-h)
            _cc_worktree_help
            return
            ;;
    esac

    local branch="$1"

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
    if [[ "$mode" != "acceptEdits" ]]; then
        echo -e "${_C_DIM}Mode: $mode${_C_NC}"
    fi
    cd "$wt_path" && eval "claude $mode_args"
}

_cc_worktree_pick() {
    local mode="${1:-acceptEdits}"
    local mode_args="${2:---permission-mode acceptEdits}"
    shift 2

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
        if [[ "$mode" != "acceptEdits" ]]; then
            echo -e "${_C_DIM}Mode: $mode${_C_NC}"
        fi
        cd "$selected" && eval "claude $mode_args"
    else
        echo -e "${_C_DIM}No worktree selected${_C_NC}"
    fi
}

_cc_worktree_status() {
    # Color definitions (use flow-cli colors if available)
    local _C_CYAN="${_C_CYAN:-\033[0;36m}"
    local _C_GREEN="${_C_GREEN:-\033[0;32m}"
    local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
    local _C_DIM="${_C_DIM:-\033[2m}"
    local _C_BOLD="${_C_BOLD:-\033[1m}"
    local _C_NC="${_C_NC:-\033[0m}"

    echo -e "${_C_BOLD}Worktrees with Claude Session Info${_C_NC}"
    echo -e "${_C_DIM}────────────────────────────────────────${_C_NC}"
    echo ""

    # Get worktrees
    local wt_path wt_branch wt_commit
    local has_worktrees=false

    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                wt_path="${line#worktree }"
                ;;
            "HEAD "*)
                wt_commit="${line#HEAD }"
                wt_commit="${wt_commit:0:7}"
                ;;
            "branch "*)
                wt_branch="${line#branch refs/heads/}"
                ;;
            "")
                if [[ -n "$wt_path" ]]; then
                    has_worktrees=true
                    _cc_worktree_status_line "$wt_path" "$wt_branch" "$wt_commit"
                fi
                wt_path="" wt_branch="" wt_commit=""
                ;;
        esac
    done < <(git worktree list --porcelain 2>/dev/null; echo "")

    if [[ "$has_worktrees" == false ]]; then
        echo -e "${_C_DIM}No worktrees found${_C_NC}"
    fi

    echo ""
    echo -e "${_C_DIM}Legend: 🟢 Recent session (< 24h) | 🟡 Old session | ⚪ No session${_C_NC}"
}

_cc_worktree_status_line() {
    local wt_path="$1"
    local wt_branch="${2:-detached}"
    local wt_commit="$3"

    local _C_CYAN="${_C_CYAN:-\033[0;36m}"
    local _C_GREEN="${_C_GREEN:-\033[0;32m}"
    local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
    local _C_DIM="${_C_DIM:-\033[2m}"
    local _C_NC="${_C_NC:-\033[0m}"

    # Check for Claude session in this worktree
    local session_indicator="⚪"
    local session_info=""
    local claude_dir="$wt_path/.claude"

    if [[ -d "$claude_dir" ]]; then
        # Look for recent session files
        local latest_session=$(find "$claude_dir" -name "*.json" -type f -mtime -1 2>/dev/null | head -1)
        if [[ -n "$latest_session" ]]; then
            session_indicator="🟢"
            local session_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$latest_session" 2>/dev/null || \
                                 stat -c "%y" "$latest_session" 2>/dev/null | cut -d' ' -f1-2)
            session_info="${_C_DIM}(${session_time})${_C_NC}"
        else
            # Check for older sessions
            local any_session=$(find "$claude_dir" -name "*.json" -type f 2>/dev/null | head -1)
            if [[ -n "$any_session" ]]; then
                session_indicator="🟡"
                session_info="${_C_DIM}(old session)${_C_NC}"
            fi
        fi
    fi

    # Format output
    local short_path="${wt_path/#$HOME/~}"
    printf "${session_indicator} ${_C_CYAN}%-30s${_C_NC} ${_C_DIM}[${wt_branch}]${_C_NC} ${session_info}\n" "$short_path"
}

_cc_worktree_help() {
    echo -e "
${_C_YELLOW}╔════════════════════════════════════════════════════════════╗${_C_NC}
${_C_YELLOW}║${_C_NC}  ${_C_CYAN}CC WT${_C_NC} - Claude Code in Worktrees                        ${_C_YELLOW}║${_C_NC}
${_C_YELLOW}╚════════════════════════════════════════════════════════════╝${_C_NC}

${_C_YELLOW}💡 QUICK START${_C_NC}:
  ${_C_DIM}\$${_C_NC} cc wt feature/auth       ${_C_DIM}# Claude in worktree (creates if needed)${_C_NC}
  ${_C_DIM}\$${_C_NC} cc wt pick               ${_C_DIM}# Pick existing worktree → Claude${_C_NC}
  ${_C_DIM}\$${_C_NC} cc wt status             ${_C_DIM}# Show worktrees with session info${_C_NC}

${_C_BLUE}📋 COMMANDS${_C_NC}:
  ${_C_CYAN}cc wt <branch>${_C_NC}       Launch Claude in worktree
  ${_C_CYAN}cc wt${_C_NC}                List worktrees
  ${_C_CYAN}cc wt pick${_C_NC}           fzf picker for worktrees
  ${_C_CYAN}cc wt status${_C_NC}         Show worktrees with Claude session info

${_C_BLUE}🚀 MODE CHAINING${_C_NC} (Two patterns - both work!):
  ${_C_CYAN}cc wt yolo <branch>${_C_NC}  Worktree + YOLO mode ${_C_DIM}(backward compatible)${_C_NC}
  ${_C_CYAN}cc yolo wt <branch>${_C_NC}  Worktree + YOLO mode ${_C_DIM}(unified pattern - NEW!)${_C_NC}
  ${_C_CYAN}cc wt plan <branch>${_C_NC}  Worktree + Plan mode
  ${_C_CYAN}cc plan wt pick${_C_NC}      Pick worktree + Plan mode ${_C_DIM}(NEW!)${_C_NC}
  ${_C_CYAN}cc opus wt <branch>${_C_NC}  Worktree + Opus model ${_C_DIM}(NEW!)${_C_NC}

${_C_MAGENTA}💡 ALIASES${_C_NC}:
  ccw   = cc wt
  ccwy  = cc wt yolo
  ccwp  = cc wt pick
  ccy   = cc yolo ${_C_DIM}(kept by user request!)${_C_NC}

${_C_MAGENTA}💡 EXAMPLES${_C_NC}:
  ccw feature/auth     Launch in worktree
  ccwy feature/auth    YOLO mode in worktree
  ccwp                 Pick from existing worktrees
  cc wt status         See which worktrees have sessions

  ${_C_YELLOW}# New unified pattern:${_C_NC}
  cc yolo wt feature/auth    ${_C_DIM}# Mode first (NEW!)${_C_NC}
  cc plan wt pick            ${_C_DIM}# Mode first (NEW!)${_C_NC}
"
}

# ============================================================================
# ALIASES
# ============================================================================

alias ccw='cc wt'
alias ccwy='cc wt yolo'
alias ccwp='cc wt pick'
alias ccy='cc yolo'  # Kept by explicit user request
