# teach-content.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_validate_flags() {
    local cmd="$1"
    shift
    local -A valid_flags

    # Start with universal flags (available to all Scholar commands)
    valid_flags=("${(@kv)TEACH_CONTENT_FLAGS}")
    valid_flags+=("${(@kv)TEACH_SELECTION_FLAGS}")

    # Add command-specific flags
    case "$cmd" in
        exam)       valid_flags+=("${(@kv)TEACH_EXAM_FLAGS}") ;;
        quiz)       valid_flags+=("${(@kv)TEACH_QUIZ_FLAGS}") ;;
        slides)     valid_flags+=("${(@kv)TEACH_SLIDES_FLAGS}") ;;
        assignment) valid_flags+=("${(@kv)TEACH_ASSIGNMENT_FLAGS}") ;;
        syllabus)   valid_flags+=("${(@kv)TEACH_SYLLABUS_FLAGS}") ;;
        rubric)     valid_flags+=("${(@kv)TEACH_RUBRIC_FLAGS}") ;;
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

# Load lesson plan from YAML file (Phase 3 - v5.13.0+, updated v5.19.2)
# Usage: _teach_load_lesson_plan <week_number>
# Sets: TEACH_PLAN_TOPIC, TEACH_PLAN_STYLE, TEACH_PLAN_OBJECTIVES,
#       TEACH_PLAN_SUBTOPICS, TEACH_PLAN_KEY_CONCEPTS, TEACH_PLAN_PREREQUISITES
# Returns: 0 if loaded, 1 if not found or invalid
# Priority: 1) lesson-plans.yml, 2) embedded weeks in teach-config.yml

_teach_load_lesson_plan() {
    local week="$1"
    local plans_file=".flow/lesson-plans.yml"
    local config_file=".flow/teach-config.yml"

    # Clear previous plan data
    typeset -g TEACH_PLAN_TOPIC=""
    typeset -g TEACH_PLAN_STYLE=""
    typeset -g TEACH_PLAN_OBJECTIVES=""
    typeset -g TEACH_PLAN_SUBTOPICS=""
    typeset -g TEACH_PLAN_KEY_CONCEPTS=""
    typeset -g TEACH_PLAN_PREREQUISITES=""

    # Check yq availability
    if ! command -v yq &>/dev/null; then
        _teach_warn "yq not available for lesson plan parsing" \
            "Install: brew install yq"
        return 1
    fi

    # 1. Primary: Check if lesson-plans.yml exists (preferred format)
    if [[ -f "$plans_file" ]]; then
        local week_data
        week_data=$(yq ".weeks[] | select(.number == $week)" "$plans_file" 2>/dev/null)

        if [[ -z "$week_data" ]]; then
            _teach_error "Week $week not found in lesson-plans.yml"
            return 1
        fi

        # Extract fields from week data
        TEACH_PLAN_TOPIC=$(echo "$week_data" | yq '.topic // ""')
        TEACH_PLAN_STYLE=$(echo "$week_data" | yq '.style // ""')
        TEACH_PLAN_OBJECTIVES=$(echo "$week_data" | yq '.objectives[]' 2>/dev/null | paste -sd '|' -)
        TEACH_PLAN_SUBTOPICS=$(echo "$week_data" | yq '.subtopics[]' 2>/dev/null | paste -sd '|' -)
        TEACH_PLAN_KEY_CONCEPTS=$(echo "$week_data" | yq '.key_concepts[]' 2>/dev/null | paste -sd '|' -)
        TEACH_PLAN_PREREQUISITES=$(echo "$week_data" | yq '.prerequisites[]' 2>/dev/null | paste -sd '|' -)

        # Validate required fields
        if [[ -z "$TEACH_PLAN_TOPIC" ]]; then
            _teach_warn "Lesson plan missing required 'topic' field for week $week"
            return 1
        fi

        return 0
    fi

    # 2. Fallback: Check for embedded weeks in teach-config.yml
    if _teach_has_embedded_weeks; then
        _teach_warn "Using embedded weeks in teach-config.yml" \
            "Consider migrating: teach migrate-config"
        return $(_teach_load_embedded_week "$week")
    fi

    # 3. Error: Neither exists
    _teach_error "lesson-plans.yml not found" \
        "Run: teach migrate-config"
    return 1
}

# Check if teach-config.yml has embedded weeks (v5.19.2)
# Usage: _teach_has_embedded_weeks
# Returns: 0 if embedded weeks exist, 1 otherwise

_teach_has_embedded_weeks() {
    local config_file=".flow/teach-config.yml"

    [[ -f "$config_file" ]] || return 1

    # Check yq availability (caller should have checked, but be safe)
    command -v yq &>/dev/null || return 1

    # Check if semester_info.weeks exists and has items
    local weeks_count
    weeks_count=$(yq '.semester_info.weeks | length' "$config_file" 2>/dev/null)

    [[ -n "$weeks_count" && "$weeks_count" -gt 0 ]]
}

# Load week from embedded teach-config.yml (backward compat, v5.19.2)
# Usage: _teach_load_embedded_week <week_number>
# Sets: TEACH_PLAN_* variables
# Returns: 0 if loaded, 1 if not found

_teach_load_embedded_week() {
    local week="$1"
    local config_file=".flow/teach-config.yml"

    local week_data
    week_data=$(yq ".semester_info.weeks[] | select(.number == $week)" "$config_file" 2>/dev/null)

    if [[ -z "$week_data" ]]; then
        _teach_error "Week $week not found in teach-config.yml"
        return 1
    fi

    # Extract fields (same structure as lesson-plans.yml)
    TEACH_PLAN_TOPIC=$(echo "$week_data" | yq '.topic // ""')
    TEACH_PLAN_STYLE=$(echo "$week_data" | yq '.style // ""')
    TEACH_PLAN_OBJECTIVES=$(echo "$week_data" | yq '.objectives[]' 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_SUBTOPICS=$(echo "$week_data" | yq '.subtopics[]' 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_KEY_CONCEPTS=$(echo "$week_data" | yq '.key_concepts[]' 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_PREREQUISITES=$(echo "$week_data" | yq '.prerequisites[]' 2>/dev/null | paste -sd '|' -)

    # Validate required fields
    if [[ -z "$TEACH_PLAN_TOPIC" ]]; then
        _teach_warn "Embedded week missing required 'topic' field for week $week"
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

    # Check for common course materials (v5.14.0 - Task 9: Added lesson-plan.yml)
    local -a potential_files=(
        "lesson-plan.yml"           # Primary lesson plan (Task 9)
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
# NEW HELP FUNCTIONS (Tasks 1-4)
# ============================================================================

# Help for teach validate command

