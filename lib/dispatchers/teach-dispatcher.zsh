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
    echo "${FLOW_COLORS[bold]}teach${FLOW_COLORS[reset]} - Teaching workflow dispatcher"
    echo ""
    echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
    echo "  teach <command> [args]"
    echo ""
    echo "${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[cmd]}init${FLOW_COLORS[reset]}    [name]    Initialize teaching workflow (teach-init)"
    echo "  ${FLOW_COLORS[cmd]}exam${FLOW_COLORS[reset]}    [name]    Create exam/quiz (teach-exam)"
    echo "  ${FLOW_COLORS[cmd]}deploy${FLOW_COLORS[reset]}            Deploy draft → production"
    echo "  ${FLOW_COLORS[cmd]}archive${FLOW_COLORS[reset]}           Archive semester"
    echo "  ${FLOW_COLORS[cmd]}config${FLOW_COLORS[reset]}            Edit teach-config.yml"
    echo "  ${FLOW_COLORS[cmd]}status${FLOW_COLORS[reset]}            Show teaching project status"
    echo "  ${FLOW_COLORS[cmd]}week${FLOW_COLORS[reset]}              Show current week number"
    echo ""
    echo "${FLOW_COLORS[bold]}SHORTCUTS${FLOW_COLORS[reset]}"
    echo "  i=init, e=exam, d=deploy, a=archive, c=config, s=status, w=week"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach init \"STAT 545\"     # Initialize new course"
    echo "  teach init -y \"STAT 440\"  # Non-interactive mode"
    echo "  teach exam \"Midterm 1\"    # Create exam"
    echo "  teach deploy              # Deploy to production"
    echo "  teach status              # Check project status"
    echo ""
    echo "${FLOW_COLORS[bold]}DOCUMENTATION${FLOW_COLORS[reset]}"
    echo "  https://data-wise.github.io/flow-cli/guides/teaching-workflow/"
}
