# teach-dispatcher.zsh - Teaching Workflow Dispatcher
# Smart teaching workflows for course websites

# ============================================================================
# TEACH DISPATCHER
# ============================================================================

teach() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
        _teach_dispatcher_help
        return 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        # Core commands
        init|i)
            teach-init "$@"
            ;;

        exam|e)
            teach-exam "$@"
            ;;

        # Shortcuts for common operations
        deploy|d)
            if [[ -f "./scripts/quick-deploy.sh" ]]; then
                ./scripts/quick-deploy.sh "$@"
            else
                _flow_log_error "No quick-deploy.sh found. Run 'teach init' first."
                return 1
            fi
            ;;

        archive|a)
            if [[ -f "./scripts/semester-archive.sh" ]]; then
                ./scripts/semester-archive.sh "$@"
            else
                _flow_log_error "No semester-archive.sh found. Run 'teach init' first."
                return 1
            fi
            ;;

        # Config management
        config|c)
            local config_file=".flow/teach-config.yml"
            if [[ -f "$config_file" ]]; then
                ${EDITOR:-code} "$config_file"
            else
                _flow_log_error "No teach-config.yml found. Run 'teach init' first."
                return 1
            fi
            ;;

        # Status/info
        status|s)
            _teach_show_status
            ;;

        week|w)
            _teach_show_week "$@"
            ;;

        *)
            _flow_log_error "Unknown command: $cmd"
            echo ""
            _teach_dispatcher_help
            return 1
            ;;
    esac
}

# Show teaching project status
_teach_show_status() {
    local config_file=".flow/teach-config.yml"

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Not a teaching project (no .flow/teach-config.yml)"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}📚 Teaching Project Status${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"

    # Show course name from config
    if command -v yq >/dev/null 2>&1; then
        local course=$(yq '.course.name // "Unknown"' "$config_file" 2>/dev/null)
        local semester=$(yq '.course.semester // "Unknown"' "$config_file" 2>/dev/null)
        echo "  Course:   $course"
        echo "  Semester: $semester"
    fi

    # Show current branch
    local branch=$(git branch --show-current 2>/dev/null)
    echo "  Branch:   $branch"

    # Show if on draft or production
    if [[ "$branch" == "draft" ]]; then
        echo "  ${FLOW_COLORS[success]}✓ Safe to edit (draft branch)${FLOW_COLORS[reset]}"
    elif [[ "$branch" == "production" ]]; then
        echo "  ${FLOW_COLORS[warning]}⚠ On production - changes are live!${FLOW_COLORS[reset]}"
    fi

    echo ""
}

# Show current week info
_teach_show_week() {
    local config_file=".flow/teach-config.yml"

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Not a teaching project"
        return 1
    fi

    # Calculate current week (requires yq and date math)
    if ! command -v yq >/dev/null 2>&1; then
        _flow_log_error "yq required for week calculation"
        return 1
    fi

    local start_date=$(yq '.semester.start_date // ""' "$config_file" 2>/dev/null)
    if [[ -z "$start_date" ]]; then
        _flow_log_error "No start_date in config"
        return 1
    fi

    local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)
    local now_epoch=$(date "+%s")
    local diff_days=$(( (now_epoch - start_epoch) / 86400 ))
    local week=$(( diff_days / 7 + 1 ))

    echo ""
    echo "${FLOW_COLORS[bold]}📅 Week $week${FLOW_COLORS[reset]}"
    echo "  Semester started: $start_date"
    echo "  Days elapsed: $diff_days"
    echo ""
}

# Help function
_teach_dispatcher_help() {
    # Colors (ANSI codes for consistent formatting)
    local _C_BOLD="${_C_BOLD:-\033[1m}"
    local _C_NC="${_C_NC:-\033[0m}"
    local _C_GREEN="${_C_GREEN:-\033[0;32m}"
    local _C_CYAN="${_C_CYAN:-\033[0;36m}"
    local _C_BLUE="${_C_BLUE:-\033[0;34m}"
    local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
    local _C_DIM="${_C_DIM:-\033[2m}"

    echo -e "
${_C_BOLD}╭──────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ 🎓 TEACH - Teaching Workflow Dispatcher      │${_C_NC}
${_C_BOLD}╰──────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach <command> [args]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach init \"Course Name\"${_C_NC}  Initialize new course
  ${_C_CYAN}teach deploy${_C_NC}             Deploy draft → production
  ${_C_CYAN}teach status${_C_NC}             Show course status

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach init \"STAT 545\"      ${_C_DIM}# Interactive setup${_C_NC}
  ${_C_DIM}\$${_C_NC} teach init -y \"STAT 440\"   ${_C_DIM}# Non-interactive (defaults)${_C_NC}
  ${_C_DIM}\$${_C_NC} teach exam \"Midterm 1\"     ${_C_DIM}# Create exam${_C_NC}
  ${_C_DIM}\$${_C_NC} teach deploy                 ${_C_DIM}# Deploy to students${_C_NC}
  ${_C_DIM}\$${_C_NC} teach status                 ${_C_DIM}# Show project status${_C_NC}

${_C_BLUE}📋 COMMANDS${_C_NC}:
  ${_C_CYAN}teach init [name]${_C_NC}         Initialize teaching workflow
  ${_C_CYAN}teach init -y [name]${_C_NC}      Non-interactive mode (accept defaults)
  ${_C_CYAN}teach exam [name]${_C_NC}         Create exam/quiz template
  ${_C_CYAN}teach deploy${_C_NC}              Deploy draft → production branch
  ${_C_CYAN}teach archive${_C_NC}             Archive semester & create tag
  ${_C_CYAN}teach config${_C_NC}              Edit .flow/teach-config.yml
  ${_C_CYAN}teach status${_C_NC}              Show teaching project status
  ${_C_CYAN}teach week${_C_NC}                Show current week number

${_C_BLUE}⌨️  SHORTCUTS${_C_NC}:
  ${_C_CYAN}i${_C_NC}                         init
  ${_C_CYAN}e${_C_NC}                         exam
  ${_C_CYAN}d${_C_NC}                         deploy
  ${_C_CYAN}a${_C_NC}                         archive
  ${_C_CYAN}c${_C_NC}                         config
  ${_C_CYAN}s${_C_NC}                         status
  ${_C_CYAN}w${_C_NC}                         week

${_C_BLUE}📝 BRANCH WORKFLOW${_C_NC}:
  ${_C_DIM}draft:${_C_NC}          Where you make edits (default branch)
  ${_C_DIM}production:${_C_NC}    What students see (auto-deployed)

${_C_DIM}See also:${_C_NC} work help, dash teach
${_C_DIM}Docs:${_C_NC}} https://data-wise.github.io/flow-cli/guides/teaching-workflow/
"
}
