# teach-dispatcher.zsh - Teaching Workflow Dispatcher
# Smart teaching workflows for course websites
# Wraps Scholar plugin for unified teaching CLI experience
#
# v5.9.0+ Deep Integration Features:
#   - Config validation with JSON Schema
#   - Hash-based change detection
#   - Progress indicator (spinner + estimate)
#   - Flag validation before Scholar calls
#   - Post-generation hooks (auto-stage, .STATUS, notify)

# Source config validator if not already loaded
if [[ -z "$_FLOW_CONFIG_VALIDATOR_LOADED" ]]; then
    local validator_path="${0:A:h:h}/config-validator.zsh"
    [[ -f "$validator_path" ]] && source "$validator_path"
    typeset -g _FLOW_CONFIG_VALIDATOR_LOADED=1

# Source date management dispatcher if not already loaded
if [[ -z "$_FLOW_TEACH_DATES_LOADED" ]]; then
    local dates_path="${0:A:h}/teach-dates.zsh"
    [[ -f "$dates_path" ]] && source "$dates_path"
    typeset -g _FLOW_TEACH_DATES_LOADED=1
fi
fi

# ============================================================================
# TEACH DISPATCHER
# ============================================================================

# ============================================================================
# FLAG VALIDATION
# ============================================================================

# Known flags per Scholar command
typeset -gA TEACH_EXAM_FLAGS=(
    [questions]="number"
    [duration]="number"
    [types]="string"
    [format]="quarto|qti|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_QUIZ_FLAGS=(
    [questions]="number"
    [time-limit]="number"
    [format]="quarto|qti|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_SLIDES_FLAGS=(
    [theme]="default|academic|minimal"
    [from-lecture]="string"
    [format]="quarto|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_ASSIGNMENT_FLAGS=(
    [due-date]="date"
    [points]="number"
    [format]="quarto|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_SYLLABUS_FLAGS=(
    [format]="quarto|markdown|pdf"
    [dry-run]="flag"
    [verbose]="flag"
)

typeset -gA TEACH_RUBRIC_FLAGS=(
    [criteria]="number"
    [format]="quarto|markdown"
    [dry-run]="flag"
    [verbose]="flag"
)

# Validate flags for a Scholar command
# Usage: _teach_validate_flags <command> [flags...]
# Returns: 0 if valid, 1 if invalid
_teach_validate_flags() {
    local cmd="$1"
    shift
    local -A valid_flags

    # Get valid flags for this command
    case "$cmd" in
        exam)       valid_flags=("${(@kv)TEACH_EXAM_FLAGS}") ;;
        quiz)       valid_flags=("${(@kv)TEACH_QUIZ_FLAGS}") ;;
        slides)     valid_flags=("${(@kv)TEACH_SLIDES_FLAGS}") ;;
        assignment) valid_flags=("${(@kv)TEACH_ASSIGNMENT_FLAGS}") ;;
        syllabus)   valid_flags=("${(@kv)TEACH_SYLLABUS_FLAGS}") ;;
        rubric)     valid_flags=("${(@kv)TEACH_RUBRIC_FLAGS}") ;;
        *)          return 0 ;;  # Unknown command, skip validation
    esac

    # Check each argument
    for arg in "$@"; do
        if [[ "$arg" == --* ]]; then
            local flag="${arg%%=*}"
            flag="${flag#--}"

            # Skip known wrapper flags
            [[ "$flag" == "help" || "$flag" == "verbose" ]] && continue

            if [[ -z "${valid_flags[$flag]}" ]]; then
                _teach_error "Unknown flag: --$flag for 'teach $cmd'"
                echo "  Valid flags: ${(k)valid_flags}" >&2
                echo "  Run 'teach $cmd --help' for details" >&2
                return 1
            fi
        fi
    done

    return 0
}

# ============================================================================
# SCHOLAR WRAPPER INFRASTRUCTURE
# ============================================================================

# Error formatting (consistent with flow-cli style)
_teach_error() {
    local message="$1"
    local recovery="$2"

    echo "❌ teach: $message" >&2
    [[ -n "$recovery" ]] && echo "   $recovery" >&2
    return 1
}

_teach_warn() {
    local message="$1"
    local note="$2"

    echo "⚠️  teach: $message" >&2
    [[ -n "$note" ]] && echo "   $note" >&2
}

# Preflight checks before Scholar invocation
_teach_preflight() {
    local config_file=".flow/teach-config.yml"

    # 1. Check config exists
    if [[ ! -f "$config_file" ]]; then
        _teach_error "No .flow/teach-config.yml found" \
            "Run 'teach init' first or create config manually"
        return 1
    fi

    # 2. Validate config structure (if validator available)
    if typeset -f _teach_validate_config >/dev/null 2>&1; then
        _teach_validate_config "$config_file" --quiet || {
            _teach_warn "Config has validation issues" \
                "Run 'teach status' for details"
        }
    fi

    # 3. Check Scholar section exists (warning only - Scholar will use defaults)
    if typeset -f _teach_has_scholar_config >/dev/null 2>&1; then
        if ! _teach_has_scholar_config "$config_file"; then
            _teach_warn "No 'scholar:' section in config" \
                "Scholar commands will use defaults"
        fi
    elif ! grep -q "^scholar:" "$config_file" 2>/dev/null; then
        _teach_warn "No 'scholar:' section in config" \
            "Scholar commands will use defaults"
    fi

    # 4. Check Claude Code available
    if ! command -v claude &>/dev/null; then
        _teach_error "Claude Code CLI not found" \
            "Install: https://claude.ai/code"
        return 1
    fi

    return 0
}

# Build Scholar command from subcommand and args
_teach_build_command() {
    local subcommand="$1"
    shift
    local -a args=("$@")

    # Map subcommand to Scholar command
    local scholar_cmd
    case "$subcommand" in
        lecture)    scholar_cmd="/teaching:lecture" ;;
        slides)     scholar_cmd="/teaching:slides" ;;
        exam)       scholar_cmd="/teaching:exam" ;;
        quiz)       scholar_cmd="/teaching:quiz" ;;
        assignment) scholar_cmd="/teaching:assignment" ;;
        syllabus)   scholar_cmd="/teaching:syllabus" ;;
        rubric)     scholar_cmd="/teaching:rubric" ;;
        feedback)   scholar_cmd="/teaching:feedback" ;;
        demo)       scholar_cmd="/teaching:demo" ;;
        *)
            _teach_error "Unknown Scholar command: $subcommand"
            return 1
            ;;
    esac

    # Return the Scholar command with args
    echo "$scholar_cmd ${args[*]}"
}

# Execute Scholar command via Claude
# Usage: _teach_execute <scholar_cmd> [verbose] [subcommand]
_teach_execute() {
    local scholar_cmd="$1"
    local verbose="${2:-false}"
    local subcommand="${3:-}"

    if [[ "$verbose" == "true" ]]; then
        echo "🔧 Executing: claude --print \"$scholar_cmd\""
        echo ""
    fi

    # Estimate times for different commands
    local estimate=""
    case "$subcommand" in
        exam)       estimate="~30-60s" ;;
        syllabus)   estimate="~45-90s" ;;
        slides)     estimate="~20-40s" ;;
        quiz)       estimate="~15-30s" ;;
        assignment) estimate="~20-40s" ;;
        rubric)     estimate="~15-25s" ;;
        *)          estimate="~15-30s" ;;
    esac

    # Run with spinner if available
    local output
    local exit_code

    if typeset -f _flow_spinner_start >/dev/null 2>&1; then
        _flow_spinner_start "Generating ${subcommand:-content}..." "$estimate"
        output=$(claude --print "$scholar_cmd" 2>&1)
        exit_code=$?
        _flow_spinner_stop
    else
        # Fallback: no spinner
        output=$(claude --print "$scholar_cmd" 2>&1)
        exit_code=$?
    fi

    # Print output
    echo "$output"

    # Run post-generation hooks if successful
    if [[ $exit_code -eq 0 ]]; then
        _teach_post_generation_hooks "$subcommand" "$output"
    fi

    return $exit_code
}

# ============================================================================
# POST-GENERATION HOOKS (Full Auto)
# ============================================================================

# Run after Scholar generates content
# - Auto-stage generated files
# - Update .STATUS file
# - Show summary notification
_teach_post_generation_hooks() {
    local subcommand="$1"
    local output="$2"

    # Extract generated file paths from output (if Scholar outputs them)
    local -a generated_files=()

    # Look for common patterns in output like:
    # "Created: exams/midterm.md" or "Saved to: quizzes/quiz-1.qmd"
    while IFS= read -r line; do
        if [[ "$line" =~ (Created|Saved|Generated|Wrote)[:\s]+(.+\.(md|qmd|yml|yaml))$ ]]; then
            generated_files+=("${match[2]}")
        fi
    done <<< "$output"

    # Auto-stage generated files
    if [[ ${#generated_files[@]} -gt 0 ]]; then
        for file in "${generated_files[@]}"; do
            if [[ -f "$file" ]]; then
                git add "$file" 2>/dev/null && \
                    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Staged: $file"
            fi
        done
    fi

    # Update .STATUS if it exists
    local status_file=".STATUS"
    if [[ -f "$status_file" ]]; then
        local today=$(date +%Y-%m-%d)
        local update_line="# Last teach ${subcommand}: ${today}"

        # Append or update the last teach line
        if grep -q "^# Last teach" "$status_file" 2>/dev/null; then
            # Update existing line (macOS sed)
            sed -i '' "s/^# Last teach.*$/${update_line}/" "$status_file" 2>/dev/null || \
            sed -i "s/^# Last teach.*$/${update_line}/" "$status_file" 2>/dev/null
        else
            # Append new line
            echo "" >> "$status_file"
            echo "$update_line" >> "$status_file"
        fi
    fi

    # Show summary
    if [[ ${#generated_files[@]} -gt 0 ]]; then
        echo ""
        echo "${FLOW_COLORS[success]}📝 Generated ${#generated_files[@]} file(s)${FLOW_COLORS[reset]}"
        echo "  Next: Review and 'teach deploy' when ready"
    fi
}

# Main Scholar wrapper function
_teach_scholar_wrapper() {
    local subcommand="$1"
    shift
    local -a args=()
    local verbose=false
    local topic=""

    # Parse wrapper-specific flags vs Scholar flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                verbose=true
                shift
                ;;
            --help|-h|help)
                # Show Scholar command help
                _teach_scholar_help "$subcommand"
                return 0
                ;;
            *)
                # First non-flag arg is typically the topic
                if [[ -z "$topic" && ! "$1" =~ ^-- ]]; then
                    topic="$1"
                fi
                args+=("$1")
                shift
                ;;
        esac
    done

    # Special case: lecture --from-plan
    if [[ "$subcommand" == "lecture" ]]; then
        local from_plan=""
        for ((i=1; i<=${#args[@]}; i++)); do
            if [[ "${args[$i]}" == "--from-plan" ]]; then
                from_plan="${args[$((i+1))]}"
                break
            fi
        done

        if [[ -n "$from_plan" ]]; then
            _teach_lecture_from_plan "$from_plan" "${args[@]}"
            return $?
        fi
    fi

    # Validate flags BEFORE preflight (fail fast with helpful message)
    _teach_validate_flags "$subcommand" "${args[@]}" || return 1

    # Run preflight checks (includes config validation)
    _teach_preflight || return 1

    # Build and execute Scholar command
    local scholar_cmd
    scholar_cmd=$(_teach_build_command "$subcommand" "${args[@]}") || return 1

    # Execute with subcommand for spinner message
    _teach_execute "$scholar_cmd" "$verbose" "$subcommand"
}

# Lecture from lesson plan (special workflow)
_teach_lecture_from_plan() {
    local week="$1"
    shift
    local -a extra_args=("$@")
    local plan_file=".flow/lesson-plans/${week}.yml"

    if [[ ! -f "$plan_file" ]]; then
        _teach_error "Lesson plan not found: $plan_file" \
            "Create the lesson plan file first"
        return 1
    fi

    # Check yq available
    if ! command -v yq &>/dev/null; then
        _teach_error "yq required for lesson plan parsing" \
            "Install: brew install yq"
        return 1
    fi

    # Read lesson plan metadata
    local topic objectives
    topic=$(yq '.topic // ""' "$plan_file" 2>/dev/null)
    objectives=$(yq '.objectives | join(", ")' "$plan_file" 2>/dev/null)

    if [[ -z "$topic" ]]; then
        _teach_error "No 'topic' field in lesson plan: $plan_file"
        return 1
    fi

    # Note: /teaching:lecture is NOT yet implemented in Scholar
    _teach_warn "/teaching:lecture not yet in Scholar" \
        "Using slides as workaround (lecture notes coming in Scholar v2.1.0)"

    # Build Scholar command with context from lesson plan
    local scholar_cmd="/teaching:slides \"$topic\""
    [[ -n "$objectives" ]] && scholar_cmd="$scholar_cmd --objectives \"$objectives\""

    _teach_execute "$scholar_cmd" "true"
}

# Help for Scholar commands
_teach_scholar_help() {
    local cmd="$1"

    case "$cmd" in
        lecture)
            echo "teach lecture - Generate lecture content from topic"
            echo ""
            echo "Usage: teach lecture \"Topic\" [options]"
            echo ""
            echo "Options:"
            echo "  --outline         Generate outline only (no full content)"
            echo "  --notes           Include speaker notes"
            echo "  --from-plan WEEK  Generate from lesson plan file"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "Note: /teaching:lecture awaiting Scholar implementation"
            ;;
        slides)
            echo "teach slides - Generate presentation slides"
            echo ""
            echo "Usage: teach slides \"Topic\" [options]"
            echo ""
            echo "Options:"
            echo "  --theme NAME       Slide theme (default, academic, minimal)"
            echo "  --from-lecture FILE  Generate from lecture file"
            echo "  --format FORMAT    Output format (quarto, markdown)"
            echo "  --dry-run          Preview without saving"
            ;;
        exam)
            echo "teach exam - Generate exam questions"
            echo ""
            echo "Usage: teach exam \"Topic\" [options]"
            echo ""
            echo "Options:"
            echo "  --questions N     Number of questions (default: 20)"
            echo "  --duration MIN    Time limit in minutes (default: 120)"
            echo "  --types TYPES     Question types (mc,sa,essay,calc)"
            echo "  --format FORMAT   Output format (quarto, qti, markdown)"
            echo "  --dry-run         Preview without saving"
            ;;
        quiz)
            echo "teach quiz - Generate quiz questions"
            echo ""
            echo "Usage: teach quiz \"Topic\" [options]"
            echo ""
            echo "Options:"
            echo "  --questions N      Number of questions (default: 10)"
            echo "  --time-limit MIN   Time limit in minutes (default: 15)"
            echo "  --format FORMAT    Output format (quarto, qti, markdown)"
            echo "  --dry-run          Preview without saving"
            ;;
        assignment)
            echo "teach assignment - Generate homework assignment"
            echo ""
            echo "Usage: teach assignment \"Topic\" [options]"
            echo ""
            echo "Options:"
            echo "  --due-date DATE   Due date (YYYY-MM-DD)"
            echo "  --points N        Total points (default: 100)"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            ;;
        syllabus)
            echo "teach syllabus - Generate course syllabus"
            echo ""
            echo "Usage: teach syllabus [options]"
            echo ""
            echo "Options:"
            echo "  --format FORMAT   Output format (quarto, markdown, pdf)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "Note: Uses course info from .flow/teach-config.yml"
            ;;
        rubric)
            echo "teach rubric - Generate grading rubric"
            echo ""
            echo "Usage: teach rubric \"Assignment Name\" [options]"
            echo ""
            echo "Options:"
            echo "  --criteria N      Number of criteria"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            ;;
        feedback)
            echo "teach feedback - Generate student feedback"
            echo ""
            echo "Usage: teach feedback \"Student Work\" [options]"
            echo ""
            echo "Options:"
            echo "  --tone TONE       Feedback tone (supportive, direct, detailed)"
            echo "  --format FORMAT   Output format (markdown, text)"
            echo "  --dry-run         Preview without saving"
            ;;
        demo)
            echo "teach demo - Create demo course materials"
            echo ""
            echo "Usage: teach demo [options]"
            echo ""
            echo "Options:"
            echo "  --course-name NAME  Course name (default: STAT-101)"
            echo "  --force             Overwrite existing demo files"
            ;;
        *)
            echo "Unknown command: $cmd"
            echo "Run 'teach help' for available commands"
            ;;
    esac
}

teach() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
        _teach_dispatcher_help
        return 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        # ============================================
        # SCHOLAR WRAPPERS (invoke Claude + Scholar)
        # ============================================
        lecture|lec)
            _teach_scholar_wrapper "lecture" "$@"
            ;;

        slides|sl)
            _teach_scholar_wrapper "slides" "$@"
            ;;

        exam|e)
            _teach_scholar_wrapper "exam" "$@"
            ;;

        quiz|q)
            _teach_scholar_wrapper "quiz" "$@"
            ;;

        assignment|hw)
            _teach_scholar_wrapper "assignment" "$@"
            ;;

        syllabus|syl)
            _teach_scholar_wrapper "syllabus" "$@"
            ;;

        rubric|rb)
            _teach_scholar_wrapper "rubric" "$@"
            ;;

        feedback|fb)
            _teach_scholar_wrapper "feedback" "$@"
            ;;

        demo)
            _teach_scholar_wrapper "demo" "$@"
            ;;

        # ============================================
        # LOCAL COMMANDS (no Claude needed)
        # ============================================
        init|i)
            teach-init "$@"
            ;;

        # Shortcuts for common operations
        deploy|d)
            if [[ -f "./scripts/quick-deploy.sh" ]]; then
                ./scripts/quick-deploy.sh "$@"
            else
                _teach_error "No quick-deploy.sh found" "Run 'teach init' first"
                return 1
            fi
            ;;

        archive|a)
            if [[ -f "./scripts/semester-archive.sh" ]]; then
                ./scripts/semester-archive.sh "$@"
            else
                _teach_error "No semester-archive.sh found" "Run 'teach init' first"
                return 1
            fi
            ;;

        # Config management
        config|c)
            local config_file=".flow/teach-config.yml"
            if [[ -f "$config_file" ]]; then
                ${EDITOR:-code} "$config_file"
            else
                _teach_error "No teach-config.yml found" "Run 'teach init' first"
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

        # Date management
        dates)
            _teach_dates_dispatcher "$@"
            ;;

        *)
            _teach_error "Unknown command: $cmd"
            echo ""
            _teach_dispatcher_help
            return 1
            ;;
    esac
}

# Show teaching project status (Full Inventory)
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
        local year=$(yq '.course.year // ""' "$config_file" 2>/dev/null)
        echo "  Course:   $course"
        [[ -n "$year" && "$year" != "null" ]] && echo "  Term:     $semester $year" || echo "  Semester: $semester"
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

    # Config validation status
    if typeset -f _teach_validate_config >/dev/null 2>&1; then
        if _teach_validate_config "$config_file" --quiet; then
            echo "  Config:   ${FLOW_COLORS[success]}✓ valid${FLOW_COLORS[reset]}"
        else
            echo "  Config:   ${FLOW_COLORS[warning]}⚠ has issues${FLOW_COLORS[reset]}"
        fi
    fi

    # Scholar integration status
    if typeset -f _teach_has_scholar_config >/dev/null 2>&1; then
        if _teach_has_scholar_config "$config_file"; then
            echo "  Scholar:  ${FLOW_COLORS[success]}✓ configured${FLOW_COLORS[reset]}"
        else
            echo "  Scholar:  ${FLOW_COLORS[muted]}not configured${FLOW_COLORS[reset]}"
        fi
    fi

    # ============================================
    # CONTENT INVENTORY (Full)
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}📝 Generated Content${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    local -A content_dirs=(
        [exams]="📄 Exams"
        [quizzes]="❓ Quizzes"
        [assignments]="📋 Assignments"
        [lectures]="🎓 Lectures"
        [slides]="📊 Slides"
        [rubrics]="📏 Rubrics"
    )

    local found_content=false
    for dir label in "${(@kv)content_dirs}"; do
        if [[ -d "$dir" ]]; then
            local count=$(find "$dir" -maxdepth 2 -name "*.md" -o -name "*.qmd" 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$count" -gt 0 ]]; then
                printf "  %-20s %s files\n" "$label:" "$count"
                found_content=true
            fi
        fi
    done

    if ! $found_content; then
        echo "  ${FLOW_COLORS[muted]}No generated content yet${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[muted]}Run 'teach exam \"Topic\"' to get started${FLOW_COLORS[reset]}"
    fi

    # ============================================
    # RECENT ACTIVITY
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}🕐 Recent Activity${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Find recent .md/.qmd files
    local -a recent_files=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && recent_files+=("$file")
    done < <(find . -maxdepth 3 \( -name "*.md" -o -name "*.qmd" \) -newer "$config_file" -type f 2>/dev/null | head -5)

    if [[ ${#recent_files[@]} -gt 0 ]]; then
        for file in "${recent_files[@]}"; do
            local basename=$(basename "$file")
            local mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$file" 2>/dev/null || stat -c '%y' "$file" 2>/dev/null | cut -d. -f1)
            printf "  %-30s %s\n" "$basename" "${FLOW_COLORS[muted]}$mtime${FLOW_COLORS[reset]}"
        done
    else
        echo "  ${FLOW_COLORS[muted]}No recent changes${FLOW_COLORS[reset]}"
    fi

    # Show last teach command from .STATUS
    if [[ -f ".STATUS" ]] && grep -q "^# Last teach" ".STATUS" 2>/dev/null; then
        local last_teach=$(grep "^# Last teach" ".STATUS" | tail -1)
        echo ""
        echo "  ${FLOW_COLORS[muted]}${last_teach#\# }${FLOW_COLORS[reset]}"
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
    local _C_MAGENTA="${_C_MAGENTA:-\033[0;35m}"

    echo -e "
${_C_BOLD}╭──────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ 🎓 TEACH - Teaching Workflow Dispatcher      │${_C_NC}
${_C_BOLD}╰──────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach <command> [args]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach exam \"Topic\"${_C_NC}        Generate exam via Scholar
  ${_C_CYAN}teach quiz \"Topic\"${_C_NC}        Generate quiz via Scholar
  ${_C_CYAN}teach slides \"Topic\"${_C_NC}      Generate slides via Scholar
  ${_C_CYAN}teach deploy${_C_NC}              Deploy draft → production

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach exam \"Hypothesis Testing\" --dry-run  ${_C_DIM}# Preview exam${_C_NC}
  ${_C_DIM}\$${_C_NC} teach quiz \"ANOVA\" --questions 10          ${_C_DIM}# 10-question quiz${_C_NC}
  ${_C_DIM}\$${_C_NC} teach slides \"Regression\" --format quarto  ${_C_DIM}# Quarto slides${_C_NC}
  ${_C_DIM}\$${_C_NC} teach syllabus                               ${_C_DIM}# Generate syllabus${_C_NC}
  ${_C_DIM}\$${_C_NC} teach init \"STAT 545\"                       ${_C_DIM}# Initialize course${_C_NC}

${_C_MAGENTA}📚 SCHOLAR COMMANDS${_C_NC} ${_C_DIM}(via Claude + Scholar plugin)${_C_NC}:
  ${_C_CYAN}teach exam \"Topic\"${_C_NC}        Generate exam questions
  ${_C_CYAN}teach quiz \"Topic\"${_C_NC}        Generate quiz questions
  ${_C_CYAN}teach slides \"Topic\"${_C_NC}      Generate presentation slides
  ${_C_CYAN}teach lecture \"Topic\"${_C_NC}     Generate lecture notes ${_C_DIM}(awaiting Scholar)${_C_NC}
  ${_C_CYAN}teach assignment \"Topic\"${_C_NC}  Generate homework assignment
  ${_C_CYAN}teach syllabus${_C_NC}            Generate course syllabus
  ${_C_CYAN}teach rubric \"Name\"${_C_NC}       Generate grading rubric
  ${_C_CYAN}teach feedback \"Work\"${_C_NC}     Generate student feedback
  ${_C_CYAN}teach demo${_C_NC}                Create demo course (STAT-101)

${_C_BLUE}🏠 LOCAL COMMANDS${_C_NC} ${_C_DIM}(no Claude needed)${_C_NC}:
  ${_C_CYAN}teach init [name]${_C_NC}         Initialize teaching workflow
  ${_C_CYAN}teach deploy${_C_NC}              Deploy draft → production branch
  ${_C_CYAN}teach archive${_C_NC}             Archive semester & create tag
  ${_C_CYAN}teach config${_C_NC}              Edit .flow/teach-config.yml
  ${_C_CYAN}teach status${_C_NC}              Show teaching project status
  ${_C_CYAN}teach week${_C_NC}                Show current week number

${_C_BLUE}🎛️  UNIVERSAL FLAGS${_C_NC} ${_C_DIM}(all Scholar commands)${_C_NC}:
  ${_C_CYAN}--dry-run${_C_NC}                Preview output without saving
  ${_C_CYAN}--format FORMAT${_C_NC}          Output: markdown, quarto, latex, qti
  ${_C_CYAN}--output PATH${_C_NC}            Custom output path
  ${_C_CYAN}--verbose${_C_NC}                Show Scholar command being executed

${_C_BLUE}⌨️  SHORTCUTS${_C_NC}:
  ${_C_CYAN}e${_C_NC}     exam        ${_C_CYAN}q${_C_NC}     quiz        ${_C_CYAN}sl${_C_NC}    slides
  ${_C_CYAN}lec${_C_NC}   lecture     ${_C_CYAN}hw${_C_NC}    assignment  ${_C_CYAN}syl${_C_NC}   syllabus
  ${_C_CYAN}rb${_C_NC}    rubric      ${_C_CYAN}fb${_C_NC}    feedback
  ${_C_CYAN}i${_C_NC}     init        ${_C_CYAN}d${_C_NC}     deploy      ${_C_CYAN}a${_C_NC}     archive
  ${_C_CYAN}c${_C_NC}     config      ${_C_CYAN}s${_C_NC}     status      ${_C_CYAN}w${_C_NC}     week

${_C_BLUE}📝 BRANCH WORKFLOW${_C_NC}:
  ${_C_DIM}draft:${_C_NC}          Where you make edits (default branch)
  ${_C_DIM}production:${_C_NC}    What students see (auto-deployed)

${_C_DIM}Get command help:${_C_NC} teach exam --help
${_C_DIM}See also:${_C_NC} work help, dash teach
${_C_DIM}Docs:${_C_NC} https://data-wise.github.io/flow-cli/guides/teaching-workflow/
"
}
