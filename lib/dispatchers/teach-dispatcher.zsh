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

# Source git helpers for teaching workflow integration (v5.11.0+)
if [[ -z "$_FLOW_GIT_HELPERS_LOADED" ]]; then
    local git_helpers_path="${0:A:h:h}/git-helpers.zsh"
    [[ -f "$git_helpers_path" ]] && source "$git_helpers_path"
    typeset -g _FLOW_GIT_HELPERS_LOADED=1
fi

# Source git helpers for teaching workflow integration (v5.11.0+)
if [[ -z "$_FLOW_GIT_HELPERS_LOADED" ]]; then
    local git_helpers_path="${0:A:h:h}/git-helpers.zsh"
    [[ -f "$git_helpers_path" ]] && source "$git_helpers_path"
    typeset -g _FLOW_GIT_HELPERS_LOADED=1
fi

# ============================================================================
# TEACH DISPATCHER
# ============================================================================

# ============================================================================
# FLAG VALIDATION
# ============================================================================

# Universal content flags (v5.13.0+)
# These can be added to any Scholar command for content customization
typeset -gA TEACH_CONTENT_FLAGS=(
    # Content flags with short forms
    [explanation]="flag"
    [e]="flag"  # short for --explanation
    [no-explanation]="flag"

    [proof]="flag"
    [no-proof]="flag"

    [math]="flag"
    [m]="flag"  # short for --math
    [no-math]="flag"

    [examples]="flag"
    [x]="flag"  # short for --examples
    [no-examples]="flag"

    [code]="flag"
    [c]="flag"  # short for --code
    [no-code]="flag"

    [diagrams]="flag"
    [d]="flag"  # short for --diagrams
    [no-diagrams]="flag"

    [practice-problems]="flag"
    [p]="flag"  # short for --practice-problems
    [no-practice-problems]="flag"

    [definitions]="flag"
    [no-definitions]="flag"

    [references]="flag"
    [r]="flag"  # short for --references
    [no-references]="flag"
)

# Universal selection flags (v5.13.0+)
typeset -gA TEACH_SELECTION_FLAGS=(
    [topic]="string"
    [t]="string"  # short for --topic

    [week]="number"
    [w]="number"  # short for --week

    [style]="conceptual|computational|rigorous|applied"

    [interactive]="flag"
    [i]="flag"  # short for --interactive

    [revise]="string"
    [context]="flag"
)

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

# Validate content flags for conflicts (v5.13.0+)
# Usage: _teach_validate_content_flags [flags...]
# Returns: 0 if valid, 1 if conflicts detected
_teach_validate_content_flags() {
    local -a args=("$@")
    local -A seen_base_flags

    # Check for conflicting flag pairs (--foo vs --no-foo)
    for arg in "${args[@]}"; do
        if [[ "$arg" =~ ^--(no-)?(.+)$ ]]; then
            local negation="${match[1]}"
            local base_flag="${match[2]}"

            # Skip if not a content flag
            [[ -z "${TEACH_CONTENT_FLAGS[$base_flag]}" ]] && continue

            # Check if we've seen the opposite form
            if [[ -n "$negation" ]]; then
                # This is --no-X, check if we saw --X
                if [[ -n "${seen_base_flags[$base_flag]}" && "${seen_base_flags[$base_flag]}" == "positive" ]]; then
                    _teach_error "Conflicting flags" \
                        "Both --${base_flag} and --no-${base_flag} specified. These are mutually exclusive."
                    echo ""
                    echo "Fix: Keep one or the other"
                    echo "  teach slides -w 8 --${base_flag}        # Include ${base_flag}"
                    echo "  teach slides -w 8 --no-${base_flag}     # Exclude ${base_flag}"
                    return 1
                fi
                seen_base_flags[$base_flag]="negative"
            else
                # This is --X, check if we saw --no-X
                if [[ -n "${seen_base_flags[$base_flag]}" && "${seen_base_flags[$base_flag]}" == "negative" ]]; then
                    _teach_error "Conflicting flags" \
                        "Both --${base_flag} and --no-${base_flag} specified. These are mutually exclusive."
                    echo ""
                    echo "Fix: Keep one or the other"
                    echo "  teach slides -w 8 --${base_flag}        # Include ${base_flag}"
                    echo "  teach slides -w 8 --no-${base_flag}     # Exclude ${base_flag}"
                    return 1
                fi
                seen_base_flags[$base_flag]="positive"
            fi
        fi
    done

    return 0
}

# Parse topic and week from arguments (v5.13.0+)
# Usage: _teach_parse_topic_week [flags...]
# Sets: TEACH_TOPIC, TEACH_WEEK
# Returns: 0 if valid, 1 if invalid
_teach_parse_topic_week() {
    local -a args=("$@")
    typeset -g TEACH_TOPIC=""
    typeset -g TEACH_WEEK=""
    local topic_specified=false
    local week_specified=false

    # Parse flags
    for ((i=1; i<=${#args[@]}; i++)); do
        local arg="${args[$i]}"

        case "$arg" in
            --topic=*|--t=*)
                TEACH_TOPIC="${arg#*=}"
                topic_specified=true
                ;;
            --topic|--t|-t)
                # Next arg is the value
                ((i++))
                TEACH_TOPIC="${args[$i]}"
                topic_specified=true
                ;;
            --week=*|--w=*)
                TEACH_WEEK="${arg#*=}"
                week_specified=true
                ;;
            --week|--w|-w)
                # Next arg is the value
                ((i++))
                TEACH_WEEK="${args[$i]}"
                week_specified=true
                ;;
        esac
    done

    # Validation: Check for conflicts
    if [[ "$topic_specified" == "true" && "$week_specified" == "true" ]]; then
        _teach_warn "Both --topic and --week specified" \
            "Using --topic (--week will be ignored)"
        TEACH_WEEK=""  # Clear week if topic takes precedence
    fi

    # If neither specified, that's OK - caller will handle defaults
    return 0
}

# ============================================================================
# CONTENT PRESET SYSTEM (Phase 2 - v5.13.0+)
# ============================================================================

# Style preset definitions
# Maps style names to their included content flags
typeset -gA TEACH_STYLE_PRESETS=(
    # Conceptual: Intuition-focused, theory introduction
    [conceptual]="explanation definitions examples"

    # Computational: Hands-on, lab-style
    [computational]="explanation examples code practice-problems"

    # Rigorous: Graduate level, formal treatment
    [rigorous]="definitions explanation math proof"

    # Applied: Real-world applications
    [applied]="explanation examples code practice-problems"
)

# Resolve content flags from style preset + overrides (v5.13.0+)
# Usage: _teach_resolve_content <style> [flags...]
# Sets: TEACH_CONTENT_RESOLVED (space-separated list of enabled content flags)
# Returns: 0 if valid, 1 if invalid style
_teach_resolve_content() {
    local style="$1"
    shift
    local -a args=("$@")
    typeset -g TEACH_CONTENT_RESOLVED=""

    # Start with preset if style specified
    local -A enabled_flags
    if [[ -n "$style" ]]; then
        local preset_content="${TEACH_STYLE_PRESETS[$style]}"
        if [[ -z "$preset_content" ]]; then
            _teach_error "Unknown style preset: $style" \
                "Valid styles: conceptual, computational, rigorous, applied"
            return 1
        fi

        # Initialize enabled flags from preset
        for flag in ${(s: :)preset_content}; do
            enabled_flags[$flag]=1
        done
    fi

    # Process explicit content flags (additions and removals)
    for arg in "${args[@]}"; do
        if [[ "$arg" =~ ^--(no-)?(.+)$ ]]; then
            local negation="${match[1]}"
            local flag_name="${match[2]}"

            # Skip if not a content flag
            [[ -z "${TEACH_CONTENT_FLAGS[$flag_name]}" ]] && continue

            if [[ -n "$negation" ]]; then
                # --no-X: Remove from enabled set
                unset "enabled_flags[$flag_name]"
            else
                # --X: Add to enabled set
                enabled_flags[$flag_name]=1
            fi
        # Check for short form flags (-e, -m, -x, etc)
        elif [[ "$arg" =~ ^-([emxcdpr])$ ]]; then
            local short="${match[1]}"
            local long_flag=""

            # Map short form to long form
            case "$short" in
                e) long_flag="explanation" ;;
                m) long_flag="math" ;;
                x) long_flag="examples" ;;
                c) long_flag="code" ;;
                d) long_flag="diagrams" ;;
                p) long_flag="practice-problems" ;;
                r) long_flag="references" ;;
            esac

            [[ -n "$long_flag" ]] && enabled_flags[$long_flag]=1
        fi
    done

    # Build resolved content string
    TEACH_CONTENT_RESOLVED="${(k)enabled_flags}"
    return 0
}

# Build Scholar prompt instructions from resolved content flags (v5.13.0+)
# Usage: _teach_build_content_instructions
# Requires: TEACH_CONTENT_RESOLVED to be set
# Returns: Content instruction string for Scholar prompt
_teach_build_content_instructions() {
    [[ -z "$TEACH_CONTENT_RESOLVED" ]] && return 0

    local -a instructions=()

    # Map content flags to Scholar instructions
    local -A content_instructions=(
        [explanation]="Include conceptual explanations"
        [definitions]="Include formal definitions"
        [math]="Use formal mathematical notation"
        [proof]="Include mathematical proofs"
        [examples]="Include worked numerical examples"
        [code]="Include code demonstrations (R/Python)"
        [diagrams]="Include visual diagrams and plots"
        [practice-problems]="Include practice exercises"
        [references]="Include citations and references"
    )

    # Build instructions array
    for flag in ${(s: :)TEACH_CONTENT_RESOLVED}; do
        local instruction="${content_instructions[$flag]}"
        [[ -n "$instruction" ]] && instructions+=("$instruction")
    done

    # Return as newline-separated string
    printf "%s\n" "${instructions[@]}"
}

# ============================================================================
# LESSON PLAN INTEGRATION (Phase 3 - v5.13.0+)
# ============================================================================

# Load lesson plan from YAML file (Phase 3 - v5.13.0+)
# Usage: _teach_load_lesson_plan <week_number>
# Sets: TEACH_PLAN_TOPIC, TEACH_PLAN_STYLE, TEACH_PLAN_OBJECTIVES,
#       TEACH_PLAN_SUBTOPICS, TEACH_PLAN_KEY_CONCEPTS, TEACH_PLAN_PREREQUISITES
# Returns: 0 if loaded, 1 if not found or invalid
_teach_load_lesson_plan() {
    local week="$1"
    local plan_file=".flow/lesson-plans/week-${week}.yml"

    # Clear previous plan data
    typeset -g TEACH_PLAN_TOPIC=""
    typeset -g TEACH_PLAN_STYLE=""
    typeset -g TEACH_PLAN_OBJECTIVES=""
    typeset -g TEACH_PLAN_SUBTOPICS=""
    typeset -g TEACH_PLAN_KEY_CONCEPTS=""
    typeset -g TEACH_PLAN_PREREQUISITES=""

    # Check if plan file exists
    if [[ ! -f "$plan_file" ]]; then
        return 1
    fi

    # Check yq availability
    if ! command -v yq &>/dev/null; then
        _teach_warn "yq not available for lesson plan parsing" \
            "Install: brew install yq"
        return 1
    fi

    # Parse lesson plan fields
    TEACH_PLAN_TOPIC=$(yq '.topic // ""' "$plan_file" 2>/dev/null)
    TEACH_PLAN_STYLE=$(yq '.style // ""' "$plan_file" 2>/dev/null)

    # Parse array fields (objectives, subtopics, key_concepts, prerequisites)
    TEACH_PLAN_OBJECTIVES=$(yq '.objectives[] // ""' "$plan_file" 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_SUBTOPICS=$(yq '.subtopics[] // ""' "$plan_file" 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_KEY_CONCEPTS=$(yq '.key_concepts[] // ""' "$plan_file" 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_PREREQUISITES=$(yq '.prerequisites[] // ""' "$plan_file" 2>/dev/null | paste -sd '|' -)

    # Validate required fields
    if [[ -z "$TEACH_PLAN_TOPIC" ]]; then
        _teach_warn "Lesson plan missing required 'topic' field: $plan_file"
        return 1
    fi

    return 0
}

# Look up topic from semester_info.weeks (fallback) (Phase 3 - v5.13.0+)
# Usage: _teach_lookup_topic <week_number>
# Returns: topic string if found, empty if not found
_teach_lookup_topic() {
    local week="$1"
    local config_file=".flow/teach-config.yml"

    # Check config exists
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    # Check yq availability
    if ! command -v yq &>/dev/null; then
        return 1
    fi

    # Look up topic from semester_info.weeks
    local topic
    topic=$(yq ".semester_info.weeks[] | select(.number == $week) | .topic // \"\"" "$config_file" 2>/dev/null)

    echo "$topic"
}

# Prompt user when lesson plan is missing (Phase 3 - v5.13.0+)
# Usage: _teach_prompt_missing_plan <week> <topic>
# Returns: 0 if user confirms, 1 if user cancels
_teach_prompt_missing_plan() {
    local week="$1"
    local topic="$2"

    echo ""
    echo "${FLOW_COLORS[warn]}⚠️  No lesson plan found for Week $week${FLOW_COLORS[reset]}"
    echo ""

    if [[ -n "$topic" ]]; then
        echo "Topic from config: \"$topic\""
    else
        echo "No topic found in config either"
    fi

    echo ""
    echo -n "${FLOW_COLORS[prompt]}Continue with this topic? [Y/n]:${FLOW_COLORS[reset]} "
    read -r confirm

    case "$confirm" in
        n|N|no|No|NO)
            echo ""
            echo "${FLOW_COLORS[info]}Cancelled${FLOW_COLORS[reset]}"
            return 1
            ;;
        *)
            echo ""
            echo "${FLOW_COLORS[dim]}Hint: Create a lesson plan with: teach plan create $week${FLOW_COLORS[reset]}"
            echo ""
            return 0
            ;;
    esac
}

# Integrate lesson plan into Scholar wrapper (Phase 3 - v5.13.0+)
# Usage: _teach_integrate_lesson_plan <week>
# Sets: TEACH_TOPIC (from plan), style (if not specified)
# Returns: 0 if integrated, 1 if cancelled
_teach_integrate_lesson_plan() {
    local week="$1"
    local style_override="$2"  # Style from command line (if any)

    # Try to load lesson plan
    if _teach_load_lesson_plan "$week"; then
        # Lesson plan loaded successfully

        # Use topic from lesson plan
        typeset -g TEACH_TOPIC="$TEACH_PLAN_TOPIC"

        # Use style from lesson plan if not overridden
        if [[ -z "$style_override" && -n "$TEACH_PLAN_STYLE" ]]; then
            # Set global style variable for content resolution
            typeset -g TEACH_RESOLVED_STYLE="$TEACH_PLAN_STYLE"
        else
            typeset -g TEACH_RESOLVED_STYLE="$style_override"
        fi

        return 0
    else
        # Lesson plan not found, try fallback
        local fallback_topic
        fallback_topic=$(_teach_lookup_topic "$week")

        if [[ -n "$fallback_topic" ]]; then
            # Found topic in config, prompt user
            if _teach_prompt_missing_plan "$week" "$fallback_topic"; then
                typeset -g TEACH_TOPIC="$fallback_topic"
                typeset -g TEACH_RESOLVED_STYLE="$style_override"
                return 0
            else
                return 1  # User cancelled
            fi
        else
            # No topic found anywhere
            _teach_error "No topic found for Week $week" \
                "Add topic to teach-config.yml or create lesson plan"
            return 1
        fi
    fi
}

# ============================================================================
# INTERACTIVE MODE (Phase 4 - v5.13.0+)
# ============================================================================

# Interactive style selection wizard (Phase 4 - v5.13.0+)
# Usage: _teach_select_style_interactive
# Returns: Selected style name (conceptual, computational, rigorous, applied)
_teach_select_style_interactive() {
    echo ""
    echo "${FLOW_COLORS[info]}📚 Content Style${FLOW_COLORS[reset]}"
    echo ""
    echo "What style should this content use?"
    echo ""
    echo "  ${FLOW_COLORS[bold]}[1]${FLOW_COLORS[reset]} conceptual    Explanation + definitions + examples"
    echo "  ${FLOW_COLORS[bold]}[2]${FLOW_COLORS[reset]} computational Explanation + examples + code + practice"
    echo "  ${FLOW_COLORS[bold]}[3]${FLOW_COLORS[reset]} rigorous      Definitions + explanation + math + proofs"
    echo "  ${FLOW_COLORS[bold]}[4]${FLOW_COLORS[reset]} applied       Explanation + examples + code + practice"
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Your choice [1-4]:${FLOW_COLORS[reset]} "

    read -r choice

    case "$choice" in
        1) echo "conceptual" ;;
        2) echo "computational" ;;
        3) echo "rigorous" ;;
        4) echo "applied" ;;
        *)
            echo ""
            echo "${FLOW_COLORS[warn]}Invalid choice, using default: computational${FLOW_COLORS[reset]}"
            echo "computational"
            ;;
    esac
}

# Interactive topic selection from schedule (Phase 4 - v5.13.0+)
# Usage: _teach_select_topic_interactive
# Returns: Selected week number
_teach_select_topic_interactive() {
    local config_file=".flow/teach-config.yml"

    # Check config exists
    if [[ ! -f "$config_file" ]]; then
        _teach_error "No teach-config.yml found" \
            "Run 'teach init' first"
        return 1
    fi

    # Check yq available
    if ! command -v yq &>/dev/null; then
        _teach_error "yq required for topic selection" \
            "Install: brew install yq"
        return 1
    fi

    # Get weeks from config
    local -a weeks=()
    local -a topics=()

    # Read weeks and topics
    local week_count
    week_count=$(yq '.semester_info.weeks | length' "$config_file" 2>/dev/null)

    if [[ -z "$week_count" || "$week_count" == "0" || "$week_count" == "null" ]]; then
        _teach_error "No weeks found in teach-config.yml" \
            "Add semester_info.weeks to config"
        return 1
    fi

    # Build week and topic arrays
    for ((i=0; i<week_count; i++)); do
        local week_num
        local week_topic
        week_num=$(yq ".semester_info.weeks[$i].number // \"\"" "$config_file" 2>/dev/null)
        week_topic=$(yq ".semester_info.weeks[$i].topic // \"\"" "$config_file" 2>/dev/null)

        if [[ -n "$week_num" && -n "$week_topic" ]]; then
            weeks+=("$week_num")
            topics+=("$week_topic")
        fi
    done

    # Display topic selection menu
    echo ""
    echo "${FLOW_COLORS[info]}📅 Select Week/Topic${FLOW_COLORS[reset]}"
    echo ""

    for ((i=1; i<=${#weeks[@]}; i++)); do
        printf "  ${FLOW_COLORS[bold]}[%2d]${FLOW_COLORS[reset]} Week %-2s  %s\n" \
            "$i" "${weeks[$i]}" "${topics[$i]}"
    done

    echo ""
    echo -n "${FLOW_COLORS[prompt]}Your choice [1-${#weeks[@]}]:${FLOW_COLORS[reset]} "

    read -r choice

    # Validate choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#weeks[@]} )); then
        echo "${weeks[$choice]}"
        return 0
    else
        echo ""
        echo "${FLOW_COLORS[error]}Invalid choice${FLOW_COLORS[reset]}"
        return 1
    fi
}

# Interactive wizard for content generation (Phase 4 - v5.13.0+)
# Usage: _teach_interactive_wizard <subcommand> <week_or_topic> <style>
# Returns: 0 if successful, 1 if cancelled
_teach_interactive_wizard() {
    local subcommand="$1"
    local week_or_topic="$2"  # Can be empty
    local style="$3"          # Can be empty

    echo ""
    echo "${FLOW_COLORS[bold]}╭────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[bold]}│ 🎓 Interactive Teaching Content Generator     │${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[bold]}╰────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"

    # Step 1: Select week/topic if not provided
    if [[ -z "$week_or_topic" ]]; then
        local selected_week
        selected_week=$(_teach_select_topic_interactive) || return 1

        typeset -g TEACH_WEEK="$selected_week"
        typeset -g TEACH_TOPIC=""  # Will be set by lesson plan integration
    fi

    # Step 2: Select style if not provided
    if [[ -z "$style" ]]; then
        style=$(_teach_select_style_interactive)
    fi

    # Return the selected style
    echo "$style"
    return 0
}

# ============================================================================
# REVISION WORKFLOW (Phase 5 - v5.13.0+)
# ============================================================================

# Analyze file to detect content type (Phase 5 - v5.13.0+)
# Usage: _teach_analyze_file <file_path>
# Returns: Content type (slides, exam, quiz, assignment, lecture, syllabus, rubric)
_teach_analyze_file() {
    local file="$1"

    # Check file exists
    if [[ ! -f "$file" ]]; then
        _teach_error "File not found: $file"
        return 1
    fi

    # Detect from filename patterns
    case "$file" in
        *slide*|*presentation*)
            echo "slides"
            return 0
            ;;
        *exam*)
            echo "exam"
            return 0
            ;;
        *quiz*)
            echo "quiz"
            return 0
            ;;
        *assignment*|*homework*|*hw*)
            echo "assignment"
            return 0
            ;;
        *lecture*|*notes*)
            echo "lecture"
            return 0
            ;;
        *syllabus*)
            echo "syllabus"
            return 0
            ;;
        *rubric*)
            echo "rubric"
            return 0
            ;;
    esac

    # Fallback: analyze content
    if grep -qi "revealjs\|beamer\|slides" "$file"; then
        echo "slides"
    elif grep -qi "exam\|test" "$file"; then
        echo "exam"
    elif grep -qi "quiz" "$file"; then
        echo "quiz"
    elif grep -qi "assignment\|homework" "$file"; then
        echo "assignment"
    else
        echo "unknown"
    fi
}

# Revision menu with 6 options (Phase 5 - v5.13.0+)
# Usage: _teach_revision_menu <file_path> <content_type>
# Returns: Revision instruction string
_teach_revision_menu() {
    local file="$1"
    local content_type="$2"

    echo ""
    echo "${FLOW_COLORS[info]}📝 Revise: ${file}${FLOW_COLORS[reset]}"
    echo ""
    echo "What would you like to improve?"
    echo ""
    echo "  ${FLOW_COLORS[bold]}[1]${FLOW_COLORS[reset]} Expand content        Add more detail"
    echo "  ${FLOW_COLORS[bold]}[2]${FLOW_COLORS[reset]} Add examples          Include practical examples"
    echo "  ${FLOW_COLORS[bold]}[3]${FLOW_COLORS[reset]} Simplify language     Make more accessible"
    echo "  ${FLOW_COLORS[bold]}[4]${FLOW_COLORS[reset]} Add visuals           Suggest images/diagrams"
    echo "  ${FLOW_COLORS[bold]}[5]${FLOW_COLORS[reset]} Custom instructions   Enter specific feedback"
    echo "  ${FLOW_COLORS[bold]}[6]${FLOW_COLORS[reset]} Full regenerate       Start fresh"
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Your choice [1-6]:${FLOW_COLORS[reset]} "

    read -r choice

    case "$choice" in
        1)
            echo "Expand the content with more detail and depth. Add explanations for key concepts."
            return 0
            ;;
        2)
            echo "Add practical, worked examples to illustrate the concepts. Include step-by-step solutions."
            return 0
            ;;
        3)
            echo "Simplify the language and make the content more accessible. Use clearer explanations and avoid jargon."
            return 0
            ;;
        4)
            echo "Add visual elements: diagrams, charts, plots, or illustrations. Suggest where visuals would help understanding."
            return 0
            ;;
        5)
            echo ""
            echo "${FLOW_COLORS[prompt]}Enter your revision instructions:${FLOW_COLORS[reset]}"
            read -r custom_instructions
            echo "$custom_instructions"
            return 0
            ;;
        6)
            echo "REGENERATE"
            return 0
            ;;
        *)
            echo ""
            echo "${FLOW_COLORS[warn]}Invalid choice, using default: expand content${FLOW_COLORS[reset]}"
            echo "Expand the content with more detail and depth."
            return 0
            ;;
    esac
}

# Show diff preview before/after revision (Phase 5 - v5.13.0+)
# Usage: _teach_show_diff_preview <original_file> <revised_file>
_teach_show_diff_preview() {
    local original="$1"
    local revised="$2"

    if [[ ! -f "$original" || ! -f "$revised" ]]; then
        _teach_warn "Cannot show diff: file(s) missing"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[info]}📊 Changes Preview:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    # Use git diff if in git repo, otherwise use diff
    if git rev-parse --git-dir &>/dev/null; then
        git diff --no-index --color=always "$original" "$revised" 2>/dev/null || \
            diff -u "$original" "$revised" 2>/dev/null
    else
        diff -u "$original" "$revised" 2>/dev/null
    fi

    echo ""
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
}

# Main revision workflow (Phase 5 - v5.13.0+)
# Usage: _teach_revise_workflow <file_path>
# Returns: 0 if successful, 1 if cancelled
_teach_revise_workflow() {
    local file="$1"

    # Validate file
    if [[ ! -f "$file" ]]; then
        _teach_error "File not found: $file" \
            "Check the file path and try again"
        return 1
    fi

    # Analyze file to detect content type
    local content_type
    content_type=$(_teach_analyze_file "$file")

    # Show revision menu
    local revision_instruction
    revision_instruction=$(_teach_revision_menu "$file" "$content_type")

    # Check for full regeneration
    if [[ "$revision_instruction" == "REGENERATE" ]]; then
        echo ""
        echo "${FLOW_COLORS[warn]}⚠️  Full regeneration will replace the file${FLOW_COLORS[reset]}"
        echo -n "${FLOW_COLORS[prompt]}Continue? [y/N]:${FLOW_COLORS[reset]} "
        read -r confirm

        case "$confirm" in
            y|Y|yes|Yes|YES)
                # Set flag for full regeneration
                typeset -g TEACH_REVISE_MODE="regenerate"
                typeset -g TEACH_REVISE_FILE="$file"
                return 0
                ;;
            *)
                echo ""
                echo "${FLOW_COLORS[info]}Cancelled${FLOW_COLORS[reset]}"
                return 1
                ;;
        esac
    else
        # Set revision mode and instructions
        typeset -g TEACH_REVISE_MODE="improve"
        typeset -g TEACH_REVISE_FILE="$file"
        typeset -g TEACH_REVISE_INSTRUCTIONS="$revision_instruction"
        return 0
    fi
}

# ============================================================================
# CONTEXT INTEGRATION (Phase 6 - v5.13.0+)
# ============================================================================

# Build context from course materials (Phase 6 - v5.13.0+)
# Usage: _teach_build_context
# Returns: Context string with course materials
_teach_build_context() {
    local -a context_files=()
    local context_text=""

    # Check for common course materials
    local -a potential_files=(
        ".flow/teach-config.yml"
        "syllabus.md"
        "syllabus.qmd"
        "README.md"
        "COURSE-INFO.md"
    )

    # Collect existing files
    for file in "${potential_files[@]}"; do
        if [[ -f "$file" ]]; then
            context_files+=("$file")
        fi
    done

    # Build context text
    if [[ ${#context_files[@]} -gt 0 ]]; then
        context_text="Course context from: ${context_files[*]}"

        # Add brief content from each file (first 10 lines)
        for file in "${context_files[@]}"; do
            context_text="${context_text}\n\nFrom ${file}:\n"
            context_text="${context_text}$(head -10 "$file" 2>/dev/null)"
        done
    fi

    echo "$context_text"
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
# Usage: _teach_execute <scholar_cmd> [verbose] [subcommand] [topic] [full_command]
_teach_execute() {
    local scholar_cmd="$1"
    local verbose="${2:-false}"
    local subcommand="${3:-}"
    local topic="${4:-}"
    local full_command="${5:-}"

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
        _teach_post_generation_hooks "$subcommand" "$output" "$topic" "$full_command"
    fi

    return $exit_code
}

# ============================================================================
# POST-GENERATION HOOKS (Full Auto)
# ============================================================================

# Run after Scholar generates content
# - Auto-stage generated files
# - Update .STATUS file
# - Interactive commit workflow (Phase 1 - v5.11.0+)
_teach_post_generation_hooks() {
    local subcommand="$1"
    local output="$2"
    local topic="${3:-}"
    local full_command="${4:-}"

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

        # Phase 4 (v5.11.0+): Check for teaching mode
        # If teaching mode is enabled, use streamlined auto-commit workflow
        # Otherwise, use Phase 1 interactive workflow
        if _git_in_repo && [[ ${#generated_files[@]} -gt 0 ]]; then
            # Read teaching mode config
            local teaching_mode auto_commit
            teaching_mode=$(yq '.workflow.teaching_mode // false' teach-config.yml 2>/dev/null)
            auto_commit=$(yq '.workflow.auto_commit // false' teach-config.yml 2>/dev/null)

            if [[ "$teaching_mode" == "true" && "$auto_commit" == "true" ]]; then
                # Teaching mode: Streamlined auto-commit workflow
                _teach_auto_commit_workflow "$subcommand" "$topic" "$full_command" "${generated_files[@]}"
            else
                # Standard mode: Interactive workflow (Phase 1)
                _teach_interactive_commit_workflow "$subcommand" "$topic" "$full_command" "${generated_files[@]}"
            fi
        else
            echo "  Next: Review and 'teach deploy' when ready"
        fi
    fi
}

# ============================================================================
# INTERACTIVE COMMIT WORKFLOW (Phase 1 - v5.11.0+)
# ============================================================================

# Interactive commit workflow after content generation
# Usage: _teach_interactive_commit_workflow <subcommand> <topic> <full_command> <file1> [file2...]
_teach_interactive_commit_workflow() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    shift 3
    local -a files=("$@")

    # Get course info from teach-config.yml
    local course_name semester year
    course_name=$(yq '.course.name // ""' teach-config.yml 2>/dev/null)
    semester=$(yq '.course.semester // ""' teach-config.yml 2>/dev/null)
    year=$(yq '.course.year // ""' teach-config.yml 2>/dev/null)

    # Fallback if config doesn't exist or yq not available
    [[ -z "$course_name" ]] && course_name="Teaching Project"
    [[ -z "$semester" ]] && semester="N/A"
    [[ -z "$year" ]] && year=$(date +%Y)

    # Show next steps prompt
    echo ""
    echo "${FLOW_COLORS[info]}📝 Next steps:${FLOW_COLORS[reset]}"
    echo "   1. Review content (opens in \$EDITOR)"
    echo "   2. Commit to git"
    echo ""

    # Use AskUserQuestion for interactive prompt
    # Note: This is implemented using read for now, will be enhanced with proper AskUserQuestion integration
    echo "${FLOW_COLORS[prompt]}Review and commit this content?${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Review in editor first (Recommended)"
    echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} Commit now with auto-generated message"
    echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Skip commit (I'll do it manually)"
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "

    read -r choice

    case "$choice" in
        1)
            # Review in editor workflow
            _teach_review_then_commit "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year" "${files[@]}"
            ;;
        2)
            # Commit now workflow
            _teach_commit_now "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year" "${files[@]}"
            ;;
        3|*)
            # Skip commit
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} File(s) staged. Commit manually when ready."
            echo "  ${FLOW_COLORS[dim]}Tip: Use 'g commit' or standard git commands${FLOW_COLORS[reset]}"
            ;;
    esac
}

# Review in editor then commit workflow
_teach_review_then_commit() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    local course_name="$4"
    local semester="$5"
    local year="$6"
    shift 6
    local -a files=("$@")

    echo ""
    echo "${FLOW_COLORS[info]}Opening file(s) in editor...${FLOW_COLORS[reset]}"

    # Determine editor (respect $EDITOR, fallback to nvim/vim/nano)
    local editor="${EDITOR:-nvim}"
    command -v "$editor" &>/dev/null || editor="vim"
    command -v "$editor" &>/dev/null || editor="nano"

    # Open first file in editor (blocking)
    "$editor" "${files[1]}"

    # After editor closes, re-prompt for commit
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Ready to commit? [Y/n]:${FLOW_COLORS[reset]} "
    read -r confirm

    case "$confirm" in
        n|N|no|No|NO)
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} File(s) staged. Commit manually when ready."
            ;;
        *)
            # Proceed with commit
            _teach_commit_now "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year" "${files[@]}"
            ;;
    esac
}

# Commit now with auto-generated message workflow
_teach_commit_now() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    local course_name="$4"
    local semester="$5"
    local year="$6"
    shift 6
    local -a files=("$@")

    # Generate commit message using git-helpers
    local commit_msg
    commit_msg=$(_git_teaching_commit_message "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year")

    # Show commit message preview
    echo ""
    echo "${FLOW_COLORS[info]}Commit message:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo "$commit_msg"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    # Commit the staged changes
    if _git_commit_teaching_content "$commit_msg"; then
        echo ""

        # Ask about pushing to remote
        echo -n "${FLOW_COLORS[prompt]}Push to remote? [y/N]:${FLOW_COLORS[reset]} "
        read -r push_confirm

        case "$push_confirm" in
            y|Y|yes|Yes|YES)
                echo ""
                if _git_push_current_branch; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✅ Changes committed and pushed!${FLOW_COLORS[reset]}"
                else
                    echo ""
                    echo "${FLOW_COLORS[warn]}⚠️  Committed locally but push failed${FLOW_COLORS[reset]}"
                    echo "  ${FLOW_COLORS[dim]}Run 'g push' manually when ready${FLOW_COLORS[reset]}"
                fi
                ;;
            *)
                echo ""
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed locally"
                echo "  ${FLOW_COLORS[dim]}Run 'g push' to push to remote${FLOW_COLORS[reset]}"
                ;;
        esac
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to commit${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[dim]}Check git status and try again${FLOW_COLORS[reset]}"
    fi
}

# ============================================================================
# TEACHING MODE AUTO-COMMIT WORKFLOW (Phase 4 - v5.11.0+)
# ============================================================================

# Auto-commit workflow for teaching mode (streamlined, no prompts)
# Usage: _teach_auto_commit_workflow <subcommand> <topic> <full_command> <file1> [file2...]
_teach_auto_commit_workflow() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    shift 3
    local -a files=("$@")

    # Get course info from teach-config.yml
    local course_name semester year
    course_name=$(yq '.course.name // ""' teach-config.yml 2>/dev/null)
    semester=$(yq '.course.semester // ""' teach-config.yml 2>/dev/null)
    year=$(yq '.course.year // ""' teach-config.yml 2>/dev/null)

    # Fallback if config doesn't exist or yq not available
    [[ -z "$course_name" ]] && course_name="Teaching Project"
    [[ -z "$semester" ]] && semester="N/A"
    [[ -z "$year" ]] && year=$(date +%Y)

    # Generate commit message using git-helpers
    local commit_msg
    commit_msg=$(_git_teaching_commit_message "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year")

    # Show teaching mode indicator
    echo ""
    echo "${FLOW_COLORS[success]}🎓 Teaching Mode: Auto-committing...${FLOW_COLORS[reset]}"

    # Commit the staged changes
    if _git_commit_teaching_content "$commit_msg"; then
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed: ${FLOW_COLORS[dim]}${subcommand} for ${topic}${FLOW_COLORS[reset]}"

        # Check auto_push setting
        local auto_push
        auto_push=$(yq '.workflow.auto_push // false' teach-config.yml 2>/dev/null)

        if [[ "$auto_push" == "true" ]]; then
            # Auto-push is enabled, but still ask for confirmation (safety)
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Push to remote? [Y/n]:${FLOW_COLORS[reset]} "
            read -r push_confirm

            case "$push_confirm" in
                n|N|no|No|NO)
                    echo ""
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed locally"
                    echo "  ${FLOW_COLORS[dim]}Run 'g push' to push to remote${FLOW_COLORS[reset]}"
                    ;;
                *)
                    if _git_push_current_branch; then
                        echo ""
                        echo "${FLOW_COLORS[success]}✅ Committed and pushed!${FLOW_COLORS[reset]}"
                    else
                        echo ""
                        echo "${FLOW_COLORS[warn]}⚠️  Committed locally but push failed${FLOW_COLORS[reset]}"
                    fi
                    ;;
            esac
        else
            # auto_push is false (default), don't ask
            echo "  ${FLOW_COLORS[dim]}Run 'teach deploy' when ready${FLOW_COLORS[reset]}"
        fi
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to auto-commit${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[dim]}Falling back to manual workflow${FLOW_COLORS[reset]}"
    fi
}

# ============================================================================
# TEACH DEPLOY - BRANCH-AWARE PR WORKFLOW (Phase 2 - v5.11.0+)
# ============================================================================

# Deploy teaching content from draft to production via PR
# Usage: _teach_deploy [--direct-push]
_teach_deploy() {
    local direct_push=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --direct-push)
                direct_push=true
                shift
                ;;
            --help|-h|help)
                _teach_deploy_help
                return 0
                ;;
            *)
                _teach_error "Unknown flag: $1" "Run 'teach deploy --help' for usage"
                return 1
                ;;
        esac
    done

    # Check if in git repo
    if ! _git_in_repo; then
        _teach_error "Not in a git repository" \
            "Initialize git first with: git init"
        return 1
    fi

    # Check if config file exists first (standard location: .flow/teach-config.yml)
    local config_file=".flow/teach-config.yml"
    if [[ ! -f "$config_file" ]]; then
        _teach_error ".flow/teach-config.yml not found" \
            "Run 'teach init' to create the configuration"
        return 1
    fi

    # Read git configuration from teach-config.yml with fallback values
    local draft_branch prod_branch auto_pr require_clean
    draft_branch=$(yq '.git.draft_branch // .branches.draft // "draft"' "$config_file" 2>/dev/null) || draft_branch="draft"
    prod_branch=$(yq '.git.production_branch // .branches.production // "main"' "$config_file" 2>/dev/null) || prod_branch="main"
    auto_pr=$(yq '.git.auto_pr // true' "$config_file" 2>/dev/null) || auto_pr="true"
    require_clean=$(yq '.git.require_clean // true' "$config_file" 2>/dev/null) || require_clean="true"

    # Read workflow configuration (Phase 4 - v5.11.0+)
    local teaching_mode auto_push
    teaching_mode=$(yq '.workflow.teaching_mode // false' "$config_file" 2>/dev/null) || teaching_mode="false"
    auto_push=$(yq '.workflow.auto_push // false' "$config_file" 2>/dev/null) || auto_push="false"

    # Read course info for PR title
    local course_name
    course_name=$(yq '.course.name // "Teaching Project"' "$config_file" 2>/dev/null) || course_name="Teaching Project"

    echo ""
    echo "${FLOW_COLORS[info]}🔍 Pre-flight Checks${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Check 1: Verify we're on draft branch
    local current_branch=$(_git_current_branch)
    if [[ "$current_branch" != "$draft_branch" ]]; then
        echo "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Not on $draft_branch branch (currently on: $current_branch)"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Switch to $draft_branch branch? [Y/n]:${FLOW_COLORS[reset]} "
        read -r switch_confirm

        case "$switch_confirm" in
            n|N|no|No|NO)
                return 1
                ;;
            *)
                git checkout "$draft_branch" || {
                    _teach_error "Failed to switch to $draft_branch"
                    return 1
                }
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Switched to $draft_branch"
                ;;
        esac
    else
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} On $draft_branch branch"
    fi

    # Check 2: Verify no uncommitted changes (if required)
    if [[ "$require_clean" == "true" ]]; then
        if ! _git_is_clean; then
            echo "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Uncommitted changes detected"
            echo ""
            echo "  ${FLOW_COLORS[dim]}Commit or stash changes before deploying${FLOW_COLORS[reset]}"
            echo "  ${FLOW_COLORS[dim]}Or disable with: git.require_clean: false${FLOW_COLORS[reset]}"
            return 1
        else
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No uncommitted changes"
        fi
    fi

    # Check 3: Check for unpushed commits (Phase 4 - teaching mode aware)
    if _git_has_unpushed_commits; then
        echo "${FLOW_COLORS[warn]}⚠️  ${FLOW_COLORS[reset]} Unpushed commits detected"
        echo ""

        # Teaching mode: auto-push if enabled, otherwise prompt
        if [[ "$teaching_mode" == "true" && "$auto_push" == "true" ]]; then
            echo "${FLOW_COLORS[info]}🎓 Teaching mode: Auto-pushing...${FLOW_COLORS[reset]}"
            if _git_push_current_branch; then
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
            else
                return 1
            fi
        else
            # Standard mode or teaching mode without auto_push: prompt user
            echo -n "${FLOW_COLORS[prompt]}Push to origin/$draft_branch first? [Y/n]:${FLOW_COLORS[reset]} "
            read -r push_confirm

            case "$push_confirm" in
                n|N|no|No|NO)
                    echo "${FLOW_COLORS[warn]}Continuing without push...${FLOW_COLORS[reset]}"
                    ;;
                *)
                    if _git_push_current_branch; then
                        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                    else
                        return 1
                    fi
                    ;;
            esac
        fi
    else
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Remote is up-to-date"
    fi

    # Check 4: Conflict detection
    if _git_detect_production_conflicts "$draft_branch" "$prod_branch"; then
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No conflicts with production"
    else
        local commits_ahead=$(git rev-list --count "origin/${prod_branch}..origin/${draft_branch}" 2>/dev/null || echo 0)
        echo "${FLOW_COLORS[warn]}⚠️  ${FLOW_COLORS[reset]} Production ($prod_branch) has new commits"
        echo ""
        echo "${FLOW_COLORS[prompt]}Production branch has updates. Rebase first?${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Yes - Rebase $draft_branch onto $prod_branch (Recommended)"
        echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} No - Continue anyway (may have merge conflicts in PR)"
        echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Cancel deployment"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "
        read -r rebase_choice

        case "$rebase_choice" in
            1)
                if _git_rebase_onto_production "$draft_branch" "$prod_branch"; then
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Rebase successful"
                else
                    return 1
                fi
                ;;
            2)
                echo "${FLOW_COLORS[warn]}Continuing without rebase...${FLOW_COLORS[reset]}"
                ;;
            3|*)
                echo "Deployment cancelled"
                return 1
                ;;
        esac
    fi

    echo ""

    # Generate PR details
    local commit_count=$(_git_get_commit_count "$draft_branch" "$prod_branch")
    local pr_title="Deploy: $course_name Updates"
    local pr_body=$(_git_generate_pr_body "$draft_branch" "$prod_branch")

    # Show PR preview
    echo "${FLOW_COLORS[info]}📋 Pull Request Preview${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[bold]}Title:${FLOW_COLORS[reset]} $pr_title"
    echo "${FLOW_COLORS[bold]}From:${FLOW_COLORS[reset]} $draft_branch → $prod_branch"
    echo "${FLOW_COLORS[bold]}Commits:${FLOW_COLORS[reset]} $commit_count"
    echo ""

    # Decide whether to create PR or direct push
    if [[ "$direct_push" == "true" ]]; then
        echo "${FLOW_COLORS[warn]}⚠️  Direct push mode (bypassing PR)${FLOW_COLORS[reset]}"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Push directly to $prod_branch? [y/N]:${FLOW_COLORS[reset]} "
        read -r direct_confirm

        case "$direct_confirm" in
            y|Y|yes|Yes|YES)
                git push origin "$draft_branch:$prod_branch" && \
                    echo "${FLOW_COLORS[success]}✅ Pushed to $prod_branch${FLOW_COLORS[reset]}" || \
                    return 1
                ;;
            *)
                echo "Direct push cancelled"
                return 1
                ;;
        esac
    elif [[ "$auto_pr" == "true" ]]; then
        # Create PR workflow
        echo "${FLOW_COLORS[prompt]}Create pull request?${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Yes - Create PR (Recommended)"
        echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} Push to $draft_branch only (no PR)"
        echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Cancel"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "
        read -r pr_choice

        case "$pr_choice" in
            1)
                echo ""
                if _git_create_deploy_pr "$draft_branch" "$prod_branch" "$pr_title" "$pr_body"; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✅ Pull Request Created${FLOW_COLORS[reset]}"
                    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
                    echo ""
                    echo "  Next steps:"
                    echo "  1. Review PR on GitHub"
                    echo "  2. Merge when ready"
                    echo "  3. Site will auto-deploy after merge"
                    echo ""
                else
                    return 1
                fi
                ;;
            2)
                if _git_push_current_branch; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                    echo "  ${FLOW_COLORS[dim]}Create PR manually on GitHub when ready${FLOW_COLORS[reset]}"
                else
                    return 1
                fi
                ;;
            3|*)
                echo "Deployment cancelled"
                return 1
                ;;
        esac
    else
        # auto_pr is false - just push to draft
        if _git_push_current_branch; then
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
            echo "  ${FLOW_COLORS[dim]}Create PR manually on GitHub${FLOW_COLORS[reset]}"
        else
            return 1
        fi
    fi
}

# Help for teach deploy
_teach_deploy_help() {
    echo "teach deploy - Deploy teaching content via PR workflow"
    echo ""
    echo "Usage: teach deploy [options]"
    echo ""
    echo "Options:"
    echo "  --direct-push    Bypass PR and push directly to production (advanced)"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Workflow:"
    echo "  1. Verify on draft branch"
    echo "  2. Check for uncommitted changes"
    echo "  3. Detect conflicts with production"
    echo "  4. Create pull request (draft → production)"
    echo ""
    echo "Configuration (teach-config.yml):"
    echo "  git:"
    echo "    draft_branch: draft          # Development branch"
    echo "    production_branch: main      # Production branch"
    echo "    auto_pr: true                # Auto-create PR"
    echo "    require_clean: true          # Require clean state"
    echo ""
    echo "Examples:"
    echo "  teach deploy                   # Standard PR workflow"
    echo "  teach deploy --direct-push     # Bypass PR (not recommended)"
}

# ============================================================================
# GIT CLEANUP WORKFLOW (Phase 3 - v5.11.0+)
# ============================================================================

# Interactive cleanup prompt for uncommitted teaching files
# Usage: _teach_git_cleanup_prompt <file1> [file2...]
_teach_git_cleanup_prompt() {
    local -a files=("$@")

    echo "${FLOW_COLORS[prompt]}Clean up uncommitted changes?${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Commit teaching files (Recommended)"
    echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} Stash teaching files"
    echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} View diff first"
    echo "  ${FLOW_COLORS[dim]}[4]${FLOW_COLORS[reset]} Leave as-is"
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Your choice [1-4]:${FLOW_COLORS[reset]} "

    read -r choice

    case "$choice" in
        1)
            # Commit teaching files
            _teach_git_commit_files "${files[@]}"
            ;;
        2)
            # Stash teaching files
            _teach_git_stash_files "${files[@]}"
            ;;
        3)
            # View diff then re-prompt
            _teach_git_view_diff "${files[@]}"
            echo ""
            _teach_git_cleanup_prompt "${files[@]}"
            ;;
        4|*)
            # Leave as-is
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Files left uncommitted"
            echo "  ${FLOW_COLORS[dim]}Commit manually when ready${FLOW_COLORS[reset]}"
            ;;
    esac
}

# Commit teaching files with auto-generated message
_teach_git_commit_files() {
    local -a files=("$@")

    # Get course info
    local course_name semester year
    course_name=$(yq '.course.name // "Teaching Project"' teach-config.yml 2>/dev/null)
    semester=$(yq '.course.semester // ""' teach-config.yml 2>/dev/null)
    year=$(yq '.course.year // ""' teach-config.yml 2>/dev/null)
    [[ -z "$year" || "$year" == "null" ]] && year=$(date +%Y)

    # Stage files
    for file in "${files[@]}"; do
        git add "$file" 2>/dev/null
    done

    # Generate commit message
    local file_list=$(printf ", %s" "${files[@]}")
    file_list=${file_list:2}  # Remove leading ", "

    local commit_msg="teach: update teaching content

Modified files: $file_list
Course: $course_name ($semester $year)

Generated via: teach status cleanup"

    # Show commit message
    echo ""
    echo "${FLOW_COLORS[info]}Commit message:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo "$commit_msg"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    # Commit
    if git commit -m "$commit_msg" 2>/dev/null; then
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed ${#files[@]} file(s)"

        # Offer to push
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Push to remote? [y/N]:${FLOW_COLORS[reset]} "
        read -r push_confirm

        case "$push_confirm" in
            y|Y|yes|Yes|YES)
                if _git_push_current_branch; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✅ Changes committed and pushed!${FLOW_COLORS[reset]}"
                else
                    echo ""
                    echo "${FLOW_COLORS[warn]}⚠️  Committed locally but push failed${FLOW_COLORS[reset]}"
                fi
                ;;
            *)
                echo ""
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed locally"
                echo "  ${FLOW_COLORS[dim]}Run 'g push' to push to remote${FLOW_COLORS[reset]}"
                ;;
        esac
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to commit${FLOW_COLORS[reset]}"
    fi
}

# Stash teaching files
_teach_git_stash_files() {
    local -a files=("$@")

    local stash_msg="Teaching WIP: $(date +%Y-%m-%d)"

    echo ""
    echo "${FLOW_COLORS[info]}Stashing ${#files[@]} file(s)...${FLOW_COLORS[reset]}"

    # Use git stash push with specific files
    if git stash push -m "$stash_msg" -- "${files[@]}" 2>&1; then
        echo ""
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Files stashed: $stash_msg"
        echo "  ${FLOW_COLORS[dim]}Restore with: git stash pop${FLOW_COLORS[reset]}"
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to stash files${FLOW_COLORS[reset]}"
    fi
}

# View diff for teaching files
_teach_git_view_diff() {
    local -a files=("$@")

    echo ""
    echo "${FLOW_COLORS[info]}Diff for teaching files:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    git diff -- "${files[@]}"

    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
}

# Main Scholar wrapper function
_teach_scholar_wrapper() {
    local subcommand="$1"
    shift
    local -a args=()
    local verbose=false
    local topic=""
    local style=""

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
            --style)
                # Extract style preset
                shift
                style="$1"
                shift
                ;;
            --style=*)
                # Extract style preset (--style=computational)
                style="${1#*=}"
                shift
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

    # ==================================================================
    # PHASE 5: Revision Workflow (v5.13.0+)
    # ==================================================================

    # Check for --revise flag
    local revise_file=""
    for ((i=1; i<=${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "--revise" ]]; then
            revise_file="${args[$((i+1))]}"
            break
        elif [[ "${args[$i]}" =~ ^--revise= ]]; then
            revise_file="${args[$i]#*=}"
            break
        fi
    done

    # If revise mode, run revision workflow
    if [[ -n "$revise_file" ]]; then
        _teach_revise_workflow "$revise_file" || return 1

        # Revision workflow sets TEACH_REVISE_MODE, TEACH_REVISE_FILE, TEACH_REVISE_INSTRUCTIONS
        # These will be used when building the Scholar command
    fi

    # ==================================================================
    # END PHASE 5
    # ==================================================================

    # ==================================================================
    # PHASE 6: Context Integration (v5.13.0+)
    # ==================================================================

    # Check for --context flag
    local use_context=false
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--context" ]]; then
            use_context=true
            break
        fi
    done

    # Build context if requested
    local course_context=""
    if [[ "$use_context" == "true" ]]; then
        course_context=$(_teach_build_context)
    fi

    # ==================================================================
    # END PHASE 6
    # ==================================================================

    # ==================================================================
    # PHASE 1-2: Enhanced Flag Processing (v5.13.0+)
    # ==================================================================

    # 1. Validate content flags for conflicts
    _teach_validate_content_flags "${args[@]}" || return 1

    # 2. Parse topic and week selection flags
    _teach_parse_topic_week "${args[@]}" || return 1

    # ==================================================================
    # PHASE 4: Interactive Mode (v5.13.0+)
    # ==================================================================

    # Check if interactive mode was requested
    local interactive=false
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--interactive" || "$arg" == "-i" ]]; then
            interactive=true
            break
        fi
    done

    # Run interactive wizard if requested
    if [[ "$interactive" == "true" ]]; then
        # Run wizard (it will set TEACH_WEEK and return style)
        local wizard_style
        wizard_style=$(_teach_interactive_wizard "$subcommand" "$topic" "$style") || return 1

        # Use wizard result
        if [[ -z "$style" ]]; then
            style="$wizard_style"
        fi
    fi

    # ==================================================================
    # END PHASE 4
    # ==================================================================

    # ==================================================================
    # PHASE 3: Lesson Plan Integration (v5.13.0+)
    # ==================================================================

    # If week was specified, integrate lesson plan
    if [[ -n "$TEACH_WEEK" ]]; then
        _teach_integrate_lesson_plan "$TEACH_WEEK" "$style" || return 1

        # Use resolved style from lesson plan
        style="$TEACH_RESOLVED_STYLE"

        # topic is already set in TEACH_TOPIC by integrate function
        # but we also want to update the local variable
        topic="$TEACH_TOPIC"
    fi

    # ==================================================================
    # END PHASE 3
    # ==================================================================

    # 3. Resolve content from style preset + overrides
    _teach_resolve_content "$style" "${args[@]}" || return 1

    # 4. Build content instructions for Scholar prompt
    local content_instructions=$(_teach_build_content_instructions)

    # ==================================================================
    # END PHASE 1-2
    # ==================================================================

    # Validate flags BEFORE preflight (fail fast with helpful message)
    _teach_validate_flags "$subcommand" "${args[@]}" || return 1

    # Run preflight checks (includes config validation)
    _teach_preflight || return 1

    # Build and execute Scholar command
    local scholar_cmd
    scholar_cmd=$(_teach_build_command "$subcommand" "${args[@]}") || return 1

    # Append content instructions to Scholar command if present
    if [[ -n "$content_instructions" ]]; then
        # Add content instructions as additional context
        scholar_cmd="$scholar_cmd --instructions \"$content_instructions\""
    fi

    # Append revision instructions (Phase 5)
    if [[ -n "$TEACH_REVISE_INSTRUCTIONS" ]]; then
        scholar_cmd="$scholar_cmd --revise-instructions \"$TEACH_REVISE_INSTRUCTIONS\""
        scholar_cmd="$scholar_cmd --revise-file \"$TEACH_REVISE_FILE\""
    fi

    # Append course context (Phase 6)
    if [[ -n "$course_context" ]]; then
        scholar_cmd="$scholar_cmd --context \"$course_context\""
    fi

    # Build full command string for commit message (v5.11.0+)
    local full_command="teach $subcommand ${args[*]}"

    # Execute with subcommand for spinner message
    _teach_execute "$scholar_cmd" "$verbose" "$subcommand" "$topic" "$full_command"
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

    # Universal flags section (applies to all Scholar commands)
    _show_universal_flags() {
        echo ""
        echo "${FLOW_COLORS[bold]}Universal Flags (v5.13.0+):${FLOW_COLORS[reset]}"
        echo ""
        echo "${FLOW_COLORS[info]}Topic Selection:${FLOW_COLORS[reset]}"
        echo "  --topic TOPIC, -t    Explicit topic (bypasses lesson plan)"
        echo "  --week N, -w         Week number (uses lesson plan if exists)"
        echo ""
        echo "${FLOW_COLORS[info]}Content Style Presets:${FLOW_COLORS[reset]}"
        echo "  --style conceptual       Explanation + definitions + examples"
        echo "  --style computational    Explanation + examples + code + practice"
        echo "  --style rigorous         Definitions + explanation + math + proof"
        echo "  --style applied          Explanation + examples + code + practice"
        echo ""
        echo "${FLOW_COLORS[info]}Content Customization:${FLOW_COLORS[reset]}"
        echo "  --explanation, -e        Include conceptual explanations"
        echo "  --definitions            Include formal definitions"
        echo "  --proof                  Include mathematical proofs"
        echo "  --math, -m               Include mathematical notation"
        echo "  --examples, -x           Include numerical examples"
        echo "  --code, -c               Include code snippets"
        echo "  --diagrams, -d           Include diagrams/visualizations"
        echo "  --practice-problems, -p  Include practice problems"
        echo "  --references, -r         Include citations/references"
        echo ""
        echo "${FLOW_COLORS[dim]}  Negation: --no-explanation, --no-proof, etc.${FLOW_COLORS[reset]}"
        echo ""
        echo "${FLOW_COLORS[info]}Workflow Modes:${FLOW_COLORS[reset]}"
        echo "  --interactive, -i        Interactive wizard (step-by-step)"
        echo "  --revise FILE            Revision workflow (improve existing)"
        echo "  --context                Include course context from materials"
        echo ""
    }

    case "$cmd" in
        lecture)
            echo "teach lecture - Generate lecture content from topic"
            echo ""
            echo "Usage: teach lecture \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Lecture-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --outline         Generate outline only (no full content)"
            echo "  --notes           Include speaker notes"
            echo "  --from-plan WEEK  Generate from lesson plan file"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[dim]}Note: /teaching:lecture awaiting Scholar implementation${FLOW_COLORS[reset]}"
            ;;
        slides)
            echo "teach slides - Generate presentation slides"
            echo ""
            echo "Usage: teach slides \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Slides-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --theme NAME       Slide theme (default, academic, minimal)"
            echo "  --from-lecture FILE  Generate from lecture file"
            echo "  --format FORMAT    Output format (quarto, markdown)"
            echo "  --dry-run          Preview without saving"
            ;;
        exam)
            echo "teach exam - Generate exam questions"
            echo ""
            echo "Usage: teach exam \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Exam-Specific Options:${FLOW_COLORS[reset]}"
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
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Quiz-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --questions N      Number of questions (default: 10)"
            echo "  --time-limit MIN   Time limit in minutes (default: 15)"
            echo "  --format FORMAT    Output format (quarto, qti, markdown)"
            echo "  --dry-run          Preview without saving"
            ;;
        assignment)
            echo "teach assignment - Generate homework assignment"
            echo ""
            echo "Usage: teach assignment \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Assignment-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --due-date DATE   Due date (YYYY-MM-DD)"
            echo "  --points N        Total points (default: 100)"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            ;;
        syllabus)
            echo "teach syllabus - Generate course syllabus"
            echo ""
            echo "Usage: teach syllabus [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Syllabus-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --format FORMAT   Output format (quarto, markdown, pdf)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[dim]}Note: Uses course info from .flow/teach-config.yml${FLOW_COLORS[reset]}"
            ;;
        rubric)
            echo "teach rubric - Generate grading rubric"
            echo ""
            echo "Usage: teach rubric \"Assignment Name\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Rubric-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --criteria N      Number of criteria"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            ;;
        feedback)
            echo "teach feedback - Generate student feedback"
            echo ""
            echo "Usage: teach feedback \"Student Work\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Feedback-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --tone TONE       Feedback tone (supportive, direct, detailed)"
            echo "  --format FORMAT   Output format (markdown, text)"
            echo "  --dry-run         Preview without saving"
            ;;
        demo)
            echo "teach demo - Create demo course materials"
            echo ""
            echo "Usage: teach demo [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Demo-Specific Options:${FLOW_COLORS[reset]}"
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
            # teach init temporarily removed - being reimplemented in v5.14.0
            # See Task 10: teach init Enhancements (--config, --github flags)
            _flow_log_error "'teach init' temporarily unavailable"
            echo ""
            echo "The teach init command is being reimplemented with new features."
            echo "Will be available in flow-cli v5.14.0"
            echo ""
            echo "For now, manually create .flow/teach-config.yml or use an existing teaching project."
            return 1
            ;;

        # Shortcuts for common operations
        deploy|d)
            # Phase 2 (v5.11.0+): Branch-aware deployment with PR workflow
            _teach_deploy "$@"
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

    # Teaching mode indicator (Phase 4 - v5.11.0+)
    if command -v yq >/dev/null 2>&1; then
        local teaching_mode=$(yq '.workflow.teaching_mode // false' "$config_file" 2>/dev/null)
        local auto_commit=$(yq '.workflow.auto_commit // false' "$config_file" 2>/dev/null)

        if [[ "$teaching_mode" == "true" ]]; then
            if [[ "$auto_commit" == "true" ]]; then
                echo "  Mode:     ${FLOW_COLORS[success]}🎓 Teaching mode enabled (auto-commit)${FLOW_COLORS[reset]}"
            else
                echo "  Mode:     ${FLOW_COLORS[success]}🎓 Teaching mode enabled${FLOW_COLORS[reset]}"
            fi
        fi
    fi

    # ============================================
    # GIT STATUS (Phase 3 - v5.11.0+)
    # ============================================
    if _git_in_repo; then
        echo ""
        echo "${FLOW_COLORS[bold]}🔧 Git Status${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

        # Get teaching-related uncommitted files
        local -a teaching_files=()
        while IFS= read -r file; do
            [[ -n "$file" ]] && teaching_files+=("$file")
        done < <(_git_teaching_files)

        if [[ ${#teaching_files[@]} -gt 0 ]]; then
            echo "  ${FLOW_COLORS[warn]}⚠️  ${teaching_files[@]} uncommitted changes (teaching content)${FLOW_COLORS[reset]}"
            echo ""
            for file in "${teaching_files[@]}"; do
                # Get file status (M/A/D etc)
                local status=$(git status --porcelain "$file" 2>/dev/null | awk '{print $1}')
                local status_label
                case "$status" in
                    M) status_label="${FLOW_COLORS[warn]}M${FLOW_COLORS[reset]}" ;;
                    A) status_label="${FLOW_COLORS[success]}A${FLOW_COLORS[reset]}" ;;
                    D) status_label="${FLOW_COLORS[error]}D${FLOW_COLORS[reset]}" ;;
                    ??) status_label="${FLOW_COLORS[muted]}??${FLOW_COLORS[reset]}" ;;
                    *) status_label="$status" ;;
                esac
                printf "    %s  %s\n" "$status_label" "$file"
            done

            # Offer interactive cleanup
            echo ""
            _teach_git_cleanup_prompt "${teaching_files[@]}"
        else
            if _git_is_clean; then
                echo "  ${FLOW_COLORS[success]}✓ No uncommitted changes${FLOW_COLORS[reset]}"
            else
                echo "  ${FLOW_COLORS[muted]}No teaching content changes${FLOW_COLORS[reset]}"
                echo "  ${FLOW_COLORS[dim]}(Other files modified - use 'g status' to see all)${FLOW_COLORS[reset]}"
            fi
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
