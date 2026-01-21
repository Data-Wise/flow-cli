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

# Source teach doctor implementation (v5.14.0 - Task 2)
if [[ -z "$_FLOW_TEACH_DOCTOR_LOADED" ]]; then
    local doctor_path="${0:A:h}/teach-doctor-impl.zsh"
    [[ -f "$doctor_path" ]] && source "$doctor_path"
    typeset -g _FLOW_TEACH_DOCTOR_LOADED=1
fi

# Source validation helpers (v4.6.0 - Week 2-3: Validation Commands)
if [[ -z "$_FLOW_VALIDATION_HELPERS_LOADED" ]]; then
    local validation_helpers_path="${0:A:h:h}/validation-helpers.zsh"
    [[ -f "$validation_helpers_path" ]] && source "$validation_helpers_path"
    typeset -g _FLOW_VALIDATION_HELPERS_LOADED=1
fi

# Source teach-validate command (v4.6.0 - Week 2-3: Validation Commands)
if [[ -z "$_FLOW_TEACH_VALIDATE_LOADED" ]]; then
    local validate_path="${0:A:h:h}/../commands/teach-validate.zsh"
    [[ -f "$validate_path" ]] && source "$validate_path"
    typeset -g _FLOW_TEACH_VALIDATE_LOADED=1
fi

# Source index management helpers (v5.14.0 - Quarto Workflow Week 5-7)
if [[ -z "$_FLOW_INDEX_HELPERS_LOADED" ]]; then
    local index_helpers_path="${0:A:h:h}/index-helpers.zsh"
    [[ -f "$index_helpers_path" ]] && source "$index_helpers_path"
    typeset -g _FLOW_INDEX_HELPERS_LOADED=1
fi

# Source enhanced deploy implementation (v5.14.0 - Quarto Workflow Week 5-7)
if [[ -z "$_FLOW_TEACH_DEPLOY_ENHANCED_LOADED" ]]; then
    local deploy_enhanced_path="${0:A:h}/teach-deploy-enhanced.zsh"
    [[ -f "$deploy_enhanced_path" ]] && source "$deploy_enhanced_path"
    typeset -g _FLOW_TEACH_DEPLOY_ENHANCED_LOADED=1
fi

# Source profile helpers (Phase 2 - Wave 1: Profile Management)
if [[ -z "$_FLOW_PROFILE_HELPERS_LOADED" ]]; then
    local profile_helpers_path="${0:A:h:h}/profile-helpers.zsh"
    [[ -f "$profile_helpers_path" ]] && source "$profile_helpers_path"
    typeset -g _FLOW_PROFILE_HELPERS_LOADED=1
fi

# Source R package helpers (Phase 2 - Wave 1: R Package Detection)
if [[ -z "$_FLOW_R_HELPERS_LOADED" ]]; then
    local r_helpers_path="${0:A:h:h}/r-helpers.zsh"
    [[ -f "$r_helpers_path" ]] && source "$r_helpers_path"
    typeset -g _FLOW_R_HELPERS_LOADED=1
fi

# Source renv integration (Phase 2 - Wave 1: renv Support)
if [[ -z "$_FLOW_RENV_INTEGRATION_LOADED" ]]; then
    local renv_path="${0:A:h:h}/renv-integration.zsh"
    [[ -f "$renv_path" ]] && source "$renv_path"
    typeset -g _FLOW_RENV_INTEGRATION_LOADED=1
fi

# Source teach profiles command (Phase 2 - Wave 1: Profile Management)
if [[ -z "$_FLOW_TEACH_PROFILES_LOADED" ]]; then
    local profiles_path="${0:A:h:h}/../commands/teach-profiles.zsh"
    [[ -f "$profiles_path" ]] && source "$profiles_path"
    typeset -g _FLOW_TEACH_PROFILES_LOADED=1
fi

# Source hook installer (v5.14.0 - PR #277 Task 2)
if [[ -z "$_FLOW_HOOK_INSTALLER_LOADED" ]]; then
    local hook_installer_path="${0:A:h:h}/hook-installer.zsh"
    [[ -f "$hook_installer_path" ]] && source "$hook_installer_path"
    typeset -g _FLOW_HOOK_INSTALLER_LOADED=1
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

    # ============================================
    # DEPLOYMENT PREVIEW (v5.14.0 - Task 8)
    # ============================================
    echo ""
    echo "${FLOW_COLORS[info]}📋 Changes Preview${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Show files changed summary
    local files_changed=$(git diff --name-status "$prod_branch"..."$draft_branch" 2>/dev/null)
    if [[ -n "$files_changed" ]]; then
        echo ""
        echo "${FLOW_COLORS[dim]}Files Changed:${FLOW_COLORS[reset]}"
        while IFS=$'\t' read -r file_status file; do
            case "$file_status" in
                M)  echo "  ${FLOW_COLORS[warn]}M${FLOW_COLORS[reset]}  $file" ;;
                A)  echo "  ${FLOW_COLORS[success]}A${FLOW_COLORS[reset]}  $file" ;;
                D)  echo "  ${FLOW_COLORS[error]}D${FLOW_COLORS[reset]}  $file" ;;
                R*) echo "  ${FLOW_COLORS[info]}R${FLOW_COLORS[reset]}  $file" ;;
                *)  echo "  ${FLOW_COLORS[muted]}$file_status${FLOW_COLORS[reset]}  $file" ;;
            esac
        done <<< "$files_changed"

        # Count changes by type
        local modified=$(echo "$files_changed" | grep -c "^M" || echo 0)
        local added=$(echo "$files_changed" | grep -c "^A" || echo 0)
        local deleted=$(echo "$files_changed" | grep -c "^D" || echo 0)
        local total=$(echo "$files_changed" | wc -l | tr -d ' ')

        echo ""
        echo "${FLOW_COLORS[dim]}Summary: $total files ($added added, $modified modified, $deleted deleted)${FLOW_COLORS[reset]}"
    else
        echo "${FLOW_COLORS[muted]}No changes detected${FLOW_COLORS[reset]}"
    fi

    # Offer to view full diff
    echo ""
    echo -n "${FLOW_COLORS[prompt]}View full diff? [y/N]:${FLOW_COLORS[reset]} "
    read -r view_diff

    case "$view_diff" in
        y|Y|yes|Yes|YES)
            echo ""
            echo "${FLOW_COLORS[info]}Showing diff...${FLOW_COLORS[reset]}"
            echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

            # Show colorized diff (if available)
            if command -v delta >/dev/null 2>&1; then
                git diff "$prod_branch"..."$draft_branch" | delta
            elif git config --get core.pager >/dev/null 2>&1; then
                git diff "$prod_branch"..."$draft_branch"
            else
                git --no-pager diff --color=always "$prod_branch"..."$draft_branch" | less -R
            fi

            echo ""
            echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
            ;;
        *)
            # Skip viewing diff
            ;;
    esac

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
    local template=""      # v5.14.0 - Task 9: Template selection

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
            --template)
                # Extract template selection (v5.14.0 - Task 9)
                shift
                template="$1"
                shift
                ;;
            --template=*)
                # Extract template selection (--template=detailed)
                template="${1#*=}"
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
    # PHASE 6: Context Integration (v5.13.0+ / v5.14.0 Task 9)
    # ==================================================================

    # Check for --context flag
    local use_context=false
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--context" ]]; then
            use_context=true
            break
        fi
    done

    # Auto-load context if lesson-plan.yml exists (v5.14.0 - Task 9)
    if [[ -f "lesson-plan.yml" ]]; then
        use_context=true
    fi

    # Build context if requested or if lesson-plan.yml exists
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

    # Append template selection (v5.14.0 - Task 9)
    if [[ -n "$template" ]]; then
        scholar_cmd="$scholar_cmd --template \"$template\""
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

# Archive semester backups (v5.14.0 - Task 5)
_teach_archive_command() {
    local config_file=".flow/teach-config.yml"

    # Help check
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_archive_help
        return 0
    fi

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Not a teaching project (no .flow/teach-config.yml)"
        return 1
    fi

    # Get semester name from config
    local semester year semester_name
    if command -v yq &>/dev/null; then
        semester=$(yq '.course.semester // ""' "$config_file" 2>/dev/null)
        year=$(yq '.course.year // ""' "$config_file" 2>/dev/null)

        if [[ -n "$semester" && -n "$year" ]]; then
            semester_name="${semester,,}-${year}"  # e.g., "spring-2026"
        else
            semester_name=$(date +%Y-%m)
        fi
    else
        semester_name=$(date +%Y-%m)
    fi

    # Allow override via argument
    if [[ -n "$1" ]]; then
        semester_name="$1"
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}📦 Archiving Semester Backups${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""
    echo "  Semester: $semester_name"
    echo ""

    _teach_archive_semester "$semester_name"
}

# Help for teach archive command (v5.14.0 - Task 5)
_teach_archive_help() {
    echo "${FLOW_COLORS[bold]}teach archive${FLOW_COLORS[reset]} - Archive semester backups"
    echo ""
    echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
    echo "  teach archive [SEMESTER_NAME]"
    echo ""
    echo "${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}"
    echo "  Archives backups at the end of a semester based on retention policies:"
    echo "    • Assessments (exams, quizzes, assignments) → archive"
    echo "    • Syllabi & rubrics → archive"
    echo "    • Lectures & slides → delete (semester retention)"
    echo ""
    echo "  Archived backups are moved to .flow/archives/<semester>/"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach archive                    # Archive current semester"
    echo "  teach archive spring-2026        # Archive specific semester"
    echo "  teach a                          # Short alias"
    echo ""
    echo "${FLOW_COLORS[bold]}RETENTION POLICIES${FLOW_COLORS[reset]}"
    echo "  Configure in .flow/teach-config.yml:"
    echo ""
    echo "  backups:"
    echo "    retention:"
    echo "      assessments: archive    # Keep forever"
    echo "      syllabi: archive        # Keep forever"
    echo "      lectures: semester      # Delete at semester end"
    echo ""
}

# Help for teach status command (v5.14.0 - Task 3)
_teach_status_help() {
    echo "${FLOW_COLORS[bold]}teach status${FLOW_COLORS[reset]} - Show teaching project status"
    echo ""
    echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
    echo "  teach status [--performance] [--full]"
    echo ""
    echo "${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}"
    echo "  Displays comprehensive status of your teaching project including:"
    echo "    • Course information (name, semester, year)"
    echo "    • Current branch and git status"
    echo "    • Config validation status"
    echo "    • Content inventory (lectures, exams, assignments)"
    echo ""
    echo "${FLOW_COLORS[bold]}FLAGS${FLOW_COLORS[reset]}"
    echo "  --performance    Show performance trends and metrics (Phase 2 Wave 5)"
    echo "  --full           Show detailed status view (legacy)"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach status                    # Show full project status"
    echo "  teach status --performance      # Show performance dashboard"
    echo "  teach s                         # Short alias"
    echo ""
}

# Help for teach week command (v5.14.0 - Task 3)
_teach_week_help() {
    echo "${FLOW_COLORS[bold]}teach week${FLOW_COLORS[reset]} - Show current week information"
    echo ""
    echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
    echo "  teach week [WEEK_NUMBER]"
    echo ""
    echo "${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}"
    echo "  Shows information about the current week or a specific week:"
    echo "    • Week number calculation from semester start"
    echo "    • Topics from lesson plan (if available)"
    echo "    • Content deadlines for the week"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach week                      # Show current week"
    echo "  teach week 8                    # Show week 8 info"
    echo "  teach w                         # Short alias"
    echo ""
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
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach lecture \"Linear Regression\"              # Basic lecture"
            echo "  teach lecture \"ANOVA\" --week 8                 # From lesson plan week 8"
            echo "  teach lecture \"PCA\" --style computational      # Code-heavy style"
            echo "  teach lecture \"Hypothesis Testing\" --notes     # Include speaker notes"
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
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach slides \"Multiple Regression\"             # Basic slides"
            echo "  teach slides \"Logistic Regression\" --week 10   # From lesson plan"
            echo "  teach slides \"GLMs\" --theme minimal            # Minimal theme"
            echo "  teach slides \"Bayesian Stats\" -x -c            # Examples + code"
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
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach exam \"Midterm 1\"                         # Standard exam"
            echo "  teach exam \"Final Exam\" --questions 30         # 30 questions"
            echo "  teach exam \"Quiz 3\" --week 6 --duration 30     # Short quiz from week 6"
            echo "  teach exam \"Comprehensive Final\" --format qti  # QTI format for LMS"
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
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach quiz \"Week 3 Concepts\"                   # Basic quiz"
            echo "  teach quiz \"Correlation\" --questions 5         # Short 5-question quiz"
            echo "  teach quiz \"Regression\" --week 7               # From lesson plan week 7"
            echo "  teach quiz \"ANOVA\" --time-limit 20 --format qti # 20-min QTI quiz"
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
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach assignment \"Homework 3\"                  # Basic assignment"
            echo "  teach assignment \"Problem Set 5\" --points 50   # 50-point assignment"
            echo "  teach assignment \"Data Analysis\" --week 9 -c   # Week 9, with code"
            echo "  teach assignment \"Project\" --due-date 2026-04-15 # Custom due date"
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
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach syllabus                                   # Generate from config"
            echo "  teach syllabus --format pdf                      # PDF output"
            echo "  teach syllabus --dry-run                         # Preview first"
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
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach rubric \"Final Project\"                   # Project rubric"
            echo "  teach rubric \"Lab Report\" --criteria 4         # 4 criteria rubric"
            echo "  teach rubric \"Homework 5\" --week 10            # From lesson plan"
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
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach feedback \"homework3-smith.pdf\"           # Review homework"
            echo "  teach feedback \"project.R\" --tone supportive   # Supportive tone"
            echo "  teach feedback \"essay.docx\" --tone detailed    # Detailed feedback"
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

# ============================================================================
# TEACH INIT - Initialize teaching project (v5.14.0 - Task 10)
# ============================================================================

# Initialize teaching project with optional external config and GitHub repo
# Usage: _teach_init [course_name] [--config FILE] [--github]
_teach_init() {
    local course_name=""
    local external_config=""
    local create_github=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --config)
                shift
                external_config="$1"
                shift
                ;;
            --github)
                create_github=true
                shift
                ;;
            --help|-h|help)
                _teach_init_help
                return 0
                ;;
            *)
                if [[ -z "$course_name" && ! "$1" =~ ^-- ]]; then
                    course_name="$1"
                fi
                shift
                ;;
        esac
    done

    # Check if already initialized
    if [[ -f ".flow/teach-config.yml" ]]; then
        _flow_log_error "Teaching project already initialized"
        echo ""
        echo "  Config exists: .flow/teach-config.yml"
        echo "  To reconfigure, edit the file or delete it first"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}🎓 Initializing Teaching Project${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""

    # Create .flow directory
    mkdir -p .flow

    # Load from external config if specified (v5.14.0 - Task 10)
    if [[ -n "$external_config" ]]; then
        if [[ ! -f "$external_config" ]]; then
            _flow_log_error "External config not found: $external_config"
            return 1
        fi

        echo "  ${FLOW_COLORS[info]}Loading from:${FLOW_COLORS[reset]} $external_config"
        cp "$external_config" .flow/teach-config.yml

        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Config loaded from external file"
    else
        # Create default config
        local semester=$(date +%B)  # e.g., "January"
        local year=$(date +%Y)

        # Use provided name or prompt
        if [[ -z "$course_name" ]]; then
            course_name="My Course"
        fi

        cat > .flow/teach-config.yml << EOF
course:
  name: "$course_name"
  semester: "$semester $year"
  year: $year

git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  require_clean: true

workflow:
  teaching_mode: false
  auto_commit: false
  auto_push: false

backups:
  retention:
    assessments: archive    # Keep exam/quiz backups forever
    syllabi: archive        # Keep syllabus backups forever
    lectures: semester      # Delete lecture backups at semester end
  archive_dir: .flow/archives
EOF

        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/teach-config.yml"
    fi

    # Initialize git if requested (v5.14.0 - Task 10)
    if [[ "$create_github" == "true" ]]; then
        # Check if gh is available
        if ! command -v gh &>/dev/null; then
            _flow_log_error "GitHub CLI (gh) required for --github flag"
            echo "  Install: brew install gh"
            return 1
        fi

        # Check if already in git repo
        if ! git rev-parse --git-dir &>/dev/null 2>&1; then
            # Initialize git
            git init
            echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Initialized git repository"
        fi

        # Create GitHub repo
        echo ""
        echo "  ${FLOW_COLORS[info]}Creating GitHub repository...${FLOW_COLORS[reset]}"

        local repo_name=$(basename "$PWD")
        if gh repo create "$repo_name" --private --source=. --push 2>&1; then
            echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} GitHub repository created and pushed"
        else
            echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} Failed to create GitHub repo (continuing anyway)"
        fi
    fi

    # Create initial branches if in git repo
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        # Commit the config
        git add .flow/teach-config.yml
        git commit -m "chore: initialize teaching project

Course: $course_name
Initialized via: teach init" 2>/dev/null

        # Create draft branch if it doesn't exist
        if ! git show-ref --verify --quiet refs/heads/draft 2>/dev/null; then
            git branch draft
            echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created draft branch"
        fi
    fi

    echo ""
    echo "${FLOW_COLORS[success]}✅ Teaching project initialized!${FLOW_COLORS[reset]}"
    echo ""
    echo "  Next steps:"
    echo "    1. Review config: teach config"
    echo "    2. Check environment: teach doctor"
    echo "    3. Generate content: teach exam \"Topic\""
    echo ""
}

# Help for teach init
_teach_init_help() {
    echo "${FLOW_COLORS[bold]}teach init${FLOW_COLORS[reset]} - Initialize teaching project"
    echo ""
    echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
    echo "  teach init [course_name] [OPTIONS]"
    echo ""
    echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
    echo "  --config FILE    Load configuration from external file"
    echo "  --github         Create GitHub repository (requires gh CLI)"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}"
    echo "  Creates .flow/teach-config.yml with default settings for:"
    echo "    • Course information (name, semester, year)"
    echo "    • Git workflow (draft/production branches)"
    echo "    • Teaching mode settings (auto-commit, auto-push)"
    echo "    • Backup retention policies"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach init                           # Interactive setup"
    echo "  teach init \"STAT 545\"                # With course name"
    echo "  teach init --config ./my-config.yml  # Load external config"
    echo "  teach init \"STAT 545\" --github       # Create GitHub repo"
    echo ""
}

# ============================================================================
# DISPATCHER HELP
# ============================================================================

_teach_lecture_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach lecture${FLOW_COLORS[reset]} - Generate Lecture Notes                   ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach lecture <topic> [options]
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach lecture --week N --topic "title"

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate lecture for this week${FLOW_COLORS[reset]}
  $ teach lecture "Linear Regression" --week 5

  ${FLOW_COLORS[muted]}# Create with Quarto template (recommended)${FLOW_COLORS[reset]}
  $ teach lecture "ANOVA" --template quarto --week 6

  ${FLOW_COLORS[muted]}# Customized for your course${FLOW_COLORS[reset]}
  $ teach lecture "ML Intro" --template quarto --difficulty medium

${FLOW_COLORS[bold]}TOPIC SELECTION${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}<topic>${FLOW_COLORS[reset]}                  Lecture topic or title
  ${FLOW_COLORS[cmd]}--week N, -w N${FLOW_COLORS[reset]}           Week number (for file naming)
  ${FLOW_COLORS[cmd]}--topic "text", -t${FLOW_COLORS[reset]}       Override topic in prompts

${FLOW_COLORS[bold]}CONTENT STYLE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--template FORMAT${FLOW_COLORS[reset]}        markdown | quarto | typst | pdf | docx
  ${FLOW_COLORS[cmd]}--style formal|casual${FLOW_COLORS[reset]}    Writing tone
  ${FLOW_COLORS[cmd]}--length N${FLOW_COLORS[reset]}               Target page count (20-40)

${FLOW_COLORS[bold]}DIFFICULTY & DETAIL${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--difficulty easy|medium|hard${FLOW_COLORS[reset]}  Content depth
  ${FLOW_COLORS[cmd]}--examples N, -e N${FLOW_COLORS[reset]}            Number of examples
  ${FLOW_COLORS[cmd]}--math-notation LaTeX|unicode|text${FLOW_COLORS[reset]}  Math display

${FLOW_COLORS[bold]}CONTENT FLAGS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--explanation, -e${FLOW_COLORS[reset]}           Include detailed explanations
  ${FLOW_COLORS[cmd]}--no-explanation${FLOW_COLORS[reset]}             Skip detailed explanations
  ${FLOW_COLORS[cmd]}--proof, -p${FLOW_COLORS[reset]}                 Include mathematical proofs
  ${FLOW_COLORS[cmd]}--math, -m${FLOW_COLORS[reset]}                  Include math notation
  ${FLOW_COLORS[cmd]}--code, -c${FLOW_COLORS[reset]}                  Include code examples
  ${FLOW_COLORS[cmd]}--diagrams, -d${FLOW_COLORS[reset]}              Include diagrams
  ${FLOW_COLORS[cmd]}--practice-problems, -pp${FLOW_COLORS[reset]}    Add practice problems

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic lecture generation${FLOW_COLORS[reset]}
  $ teach lecture "Multiple Regression"

  ${FLOW_COLORS[muted]}# Week-based with consistent naming${FLOW_COLORS[reset]}
  $ teach lecture "Logistic Regression" --week 8

  ${FLOW_COLORS[muted]}# Full-featured lecture${FLOW_COLORS[reset]}
  $ teach lecture "Neural Networks" --week 10 --template quarto --difficulty hard --examples 5 --math --code

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}lectures/week-NN/lecture-NN-<topic>.${FLOW_COLORS[reset]}
  Auto-backs up existing files before overwriting

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Create ${FLOW_COLORS[accent]}.teach/lesson-plan.yml${FLOW_COLORS[reset]} first for customized output
  • Use ${FLOW_COLORS[accent]}--week${FLOW_COLORS[reset]} for consistent file naming
  • Preview generated content with ${FLOW_COLORS[cmd]}quarto preview${FLOW_COLORS[reset]}
  • Auto-staged for git after generation

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach slides${FLOW_COLORS[reset]} - Presentation slides
  ${FLOW_COLORS[cmd]}teach exam${FLOW_COLORS[reset]} - Generate assessments
  docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

EOF
}

_teach_doctor_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} - Health Checks & Diagnostics           ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach doctor [options]
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach doctor --fix          # Auto-fix issues
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach doctor --json         # CI/CD output

${FLOW_COLORS[bold]}HEALTH CHECK CATEGORIES${FLOW_COLORS[reset]}

  ${FLOW_COLORS[accent]}1. Dependencies${FLOW_COLORS[reset]}
     Verifies: yq, git, quarto, gh, examark, claude, fswatch

  ${FLOW_COLORS[accent]}2. Project Configuration${FLOW_COLORS[reset]}
     Checks: .flow/teach-config.yml, course.yml, lesson-plan.yml

  ${FLOW_COLORS[accent]}3. Git Setup${FLOW_COLORS[reset]}
     Validates: branches, remote, clean state, commit history

  ${FLOW_COLORS[accent]}4. Scholar Integration${FLOW_COLORS[reset]}
     Tests: API access, template availability, config loading

  ${FLOW_COLORS[accent]}5. Hook Installation${FLOW_COLORS[reset]}
     Status: pre-commit, pre-push, prepare-commit-msg hooks

  ${FLOW_COLORS[accent]}6. Cache Health${FLOW_COLORS[reset]}
     Checks: _freeze/ directory, _site/ state, cache validity

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--fix${FLOW_COLORS[reset]}                Interactive fix mode (install missing tools)
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}               JSON output for CI/CD pipelines
  ${FLOW_COLORS[cmd]}--quiet, -q${FLOW_COLORS[reset]}          Minimal output (show only errors)
  ${FLOW_COLORS[cmd]}--verbose, -v${FLOW_COLORS[reset]}        Detailed diagnostics
  ${FLOW_COLORS[cmd]}--check <category>${FLOW_COLORS[reset]}   Run specific check only

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic health check${FLOW_COLORS[reset]}
  $ teach doctor

  ${FLOW_COLORS[muted]}# Auto-fix missing dependencies${FLOW_COLORS[reset]}
  $ teach doctor --fix

  ${FLOW_COLORS[muted]}# CI/CD output (no colors, machine-readable)${FLOW_COLORS[reset]}
  $ teach doctor --json --quiet

  ${FLOW_COLORS[muted]}# Verbose mode with all details${FLOW_COLORS[reset]}
  $ teach doctor --verbose

  ${FLOW_COLORS[muted]}# Check specific category${FLOW_COLORS[reset]}
  $ teach doctor --check git

${FLOW_COLORS[bold]}EXIT CODES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}0${FLOW_COLORS[reset]} - All checks pass
  ${FLOW_COLORS[warning]}1${FLOW_COLORS[reset]} - Warnings found (non-critical)
  ${FLOW_COLORS[error]}2${FLOW_COLORS[reset]} - Critical errors (must fix)

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Run ${FLOW_COLORS[accent]}teach doctor${FLOW_COLORS[reset]} after fresh clone
  • Use ${FLOW_COLORS[accent]}--fix${FLOW_COLORS[reset]} for automated remediation
  • Add to CI: ${FLOW_COLORS[cmd]}teach doctor --json${FLOW_COLORS[reset]}

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach hooks${FLOW_COLORS[reset]} - Hook management
  ${FLOW_COLORS[cmd]}teach cache${FLOW_COLORS[reset]} - Cache operations
  ${FLOW_COLORS[cmd]}teach config${FLOW_COLORS[reset]} - Project config

EOF
}

_teach_deploy_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach deploy${FLOW_COLORS[reset]} - Deploy Course Website                ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach deploy [files...] [options]
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach deploy --preview      # Preview changes only
  ${FLOW_COLORS[cmd]}${FLOW_COLORS[reset]} teach deploy --auto-commit  # Auto-commit changes

${FLOW_COLORS[bold]}WORKFLOW${FLOW_COLORS[reset]}

  ${FLOW_COLORS[accent]}1. Preview Changes${FLOW_COLORS[reset]}
     $ teach deploy --preview
     Shows all files that will change before creating PR

  ${FLOW_COLORS[accent]}2. Review Output${FLOW_COLORS[reset]}
     - Added: New files (lectures, exams, slides)
     - Modified: Updated content with changes highlighted
     - Removed: Deleted files with confirmation

  ${FLOW_COLORS[accent]}3. Deploy${FLOW_COLORS[reset]}
     $ teach deploy
     Renders, commits, pushes, creates PR to main

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--preview${FLOW_COLORS[reset]}               Show changes without deploying
  ${FLOW_COLORS[cmd]}--auto-commit${FLOW_COLORS[reset]}           Auto-commit rendered files
  ${FLOW_COLORS[cmd]}--auto-tag${FLOW_COLORS[reset]}              Tag deployment with version
  ${FLOW_COLORS[cmd]}--message "text"${FLOW_COLORS[reset]}        Custom commit message
  ${FLOW_COLORS[cmd]}--branch NAME${FLOW_COLORS[reset]}           Source branch (default: draft)
  ${FLOW_COLORS[cmd]}--target NAME${FLOW_COLORS[reset]}           Target branch (default: main)

${FLOW_COLORS[bold]}PARTIAL DEPLOY${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Deploy specific lecture only${FLOW_COLORS[reset]}
  $ teach deploy lectures/week-05/

  ${FLOW_COLORS[muted]}# Deploy multiple files${FLOW_COLORS[reset]}
  $ teach deploy lectures/week-05/ exams/midterm.qmd

  ${FLOW_COLORS[muted]}# Deploy with preview first${FLOW_COLORS[reset]}
  $ teach deploy lectures/week-05/ --preview

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Full site deploy (draft → main)${FLOW_COLORS[reset]}
  $ teach deploy

  ${FLOW_COLORS[muted]}# Preview what will change${FLOW_COLORS[reset]}
  $ teach deploy --preview

  ${FLOW_COLORS[muted]}# Deploy with auto-commit and tagging${FLOW_COLORS[reset]}
  $ teach deploy --auto-commit --auto-tag

  ${FLOW_COLORS[muted]}# Deploy single lecture${FLOW_COLORS[reset]}
  $ teach deploy lectures/week-07/ --auto-commit

  ${FLOW_COLORS[muted]}# Deploy to custom branches${FLOW_COLORS[reset]}
  $ teach deploy --branch feature/new-content --target main

${FLOW_COLORS[bold]}WHAT GETS DEPLOYED${FLOW_COLORS[reset]}
  • Rendered Quarto files (_site/)
  • Updated index links (index.qmd, _quarto.yml)
  • Generated assets (images, figures)
  • Cross-reference updates

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Always use ${FLOW_COLORS[accent]}--preview${FLOW_COLORS[reset]} before first deploy
  • Index automatically updated with new content
  • Changes committed with descriptive messages
  • PR created automatically to main branch

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup${FLOW_COLORS[reset]} - Create restore point
  ${FLOW_COLORS[cmd]}qu${FLOW_COLORS[reset]} - Quarto commands
  ${FLOW_COLORS[cmd]}g${FLOW_COLORS[reset]} - Git commands

EOF
}

# Help for hooks command (v5.14.0 - PR #277 Task 2)
_teach_hooks_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach hooks${FLOW_COLORS[reset]} - Git Hook Management                      ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach hooks${FLOW_COLORS[reset]} <command> [options]

${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}install${FLOW_COLORS[reset]}              Install git hooks for teaching workflow
    ${FLOW_COLORS[muted]}--force, -f${FLOW_COLORS[reset]}       Force reinstall (overwrite existing)

  ${FLOW_COLORS[cmd]}upgrade${FLOW_COLORS[reset]}              Upgrade hooks to latest version
    ${FLOW_COLORS[muted]}--force, -f${FLOW_COLORS[reset]}       Force upgrade even if newer version installed

  ${FLOW_COLORS[cmd]}status${FLOW_COLORS[reset]}               Check hook installation status

  ${FLOW_COLORS[cmd]}uninstall${FLOW_COLORS[reset]}            Remove teaching workflow hooks

${FLOW_COLORS[bold]}HOOKS INSTALLED${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}pre-commit${FLOW_COLORS[reset]}         Validate YAML, check dependencies
  ${FLOW_COLORS[accent]}pre-push${FLOW_COLORS[reset]}           Check for uncommitted changes
  ${FLOW_COLORS[accent]}prepare-commit-msg${FLOW_COLORS[reset]}  Auto-format commit messages

${FLOW_COLORS[bold]}SHORTCUTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}i${FLOW_COLORS[reset]} → install      ${FLOW_COLORS[accent]}up, u${FLOW_COLORS[reset]} → upgrade
  ${FLOW_COLORS[accent]}s${FLOW_COLORS[reset]} → status       ${FLOW_COLORS[accent]}rm${FLOW_COLORS[reset]} → uninstall

${FLOW_COLORS[success]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Install hooks in current project${FLOW_COLORS[reset]}
  teach hooks install

  ${FLOW_COLORS[muted]}# Check hook status${FLOW_COLORS[reset]}
  teach hooks status

  ${FLOW_COLORS[muted]}# Upgrade to latest version${FLOW_COLORS[reset]}
  teach hooks upgrade

  ${FLOW_COLORS[muted]}# Force reinstall${FLOW_COLORS[reset]}
  teach hooks install --force

${FLOW_COLORS[muted]}See also: teach doctor (includes hook checks)${FLOW_COLORS[reset]}
EOF
}

_teach_dispatcher_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach${FLOW_COLORS[reset]} - Teaching Workflow Commands                   ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(3 commands to begin)${FLOW_COLORS[reset]}
  $ teach init "STAT 440"           # Initialize teaching project
  $ teach doctor --fix              # Verify and fix dependencies
  $ teach lecture "Intro" --week 1  # Generate first lecture

${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
📋 SETUP & CONFIGURATION
${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} [name]             Initialize teaching project
    ${FLOW_COLORS[muted]}--config <file>${FLOW_COLORS[reset]}            Load external config
    ${FLOW_COLORS[muted]}--github${FLOW_COLORS[reset]}                   Create GitHub repo
  ${FLOW_COLORS[cmd]}teach config${FLOW_COLORS[reset]}                  Edit configuration
  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]}                  Health checks (6 categories)
    ${FLOW_COLORS[muted]}--fix${FLOW_COLORS[reset]}                       Auto-fix issues
    ${FLOW_COLORS[muted]}--json${FLOW_COLORS[reset]}                      CI/CD output
  ${FLOW_COLORS[cmd]}teach hooks${FLOW_COLORS[reset]}                    Git hook management
    ${FLOW_COLORS[muted]}install | upgrade | status${FLOW_COLORS[reset]}  Hook operations
  ${FLOW_COLORS[cmd]}teach dates${FLOW_COLORS[reset]}                    Date management

${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
✍️ CONTENT CREATION (Scholar AI)
${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach lecture${FLOW_COLORS[reset]} <topic>          Generate lecture notes
    ${FLOW_COLORS[muted]}--week N${FLOW_COLORS[reset]}                    Week-based naming
    ${FLOW_COLORS[muted]}--template FORMAT${FLOW_COLORS[reset]}           markdown | quarto | pdf
    ${FLOW_COLORS[muted]}--difficulty easy|medium|hard${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach slides${FLOW_COLORS[reset]} <topic>           Presentation slides
  ${FLOW_COLORS[cmd]}teach exam${FLOW_COLORS[reset]} <topic>             Comprehensive exam
  ${FLOW_COLORS[cmd]}teach quiz${FLOW_COLORS[reset]} <topic>             Quiz questions
    ${FLOW_COLORS[muted]}--questions N${FLOW_COLORS[reset]}               Number of questions
  ${FLOW_COLORS[cmd]}teach assignment${FLOW_COLORS[reset]} <topic>       Homework assignment
  ${FLOW_COLORS[cmd]}teach syllabus${FLOW_COLORS[reset]} <course>        Course syllabus
  ${FLOW_COLORS[cmd]}teach rubric${FLOW_COLORS[reset]} <assignment>      Grading rubric
  ${FLOW_COLORS[cmd]}teach feedback${FLOW_COLORS[reset]} <work>          Student feedback

${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
✅ VALIDATION & QUALITY
${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach validate${FLOW_COLORS[reset]} [files]          Validate .qmd files
    ${FLOW_COLORS[muted]}--yaml${FLOW_COLORS[reset]}                       YAML frontmatter only
    ${FLOW_COLORS[muted]}--syntax${FLOW_COLORS[reset]}                     YAML + syntax check
    ${FLOW_COLORS[muted]}--render${FLOW_COLORS[reset]}                     Full render validation
    ${FLOW_COLORS[muted]}--watch${FLOW_COLORS[reset]}                      Watch mode
  ${FLOW_COLORS[cmd]}teach profiles${FLOW_COLORS[reset]}                  Profile management
  ${FLOW_COLORS[cmd]}teach cache${FLOW_COLORS[reset]}                     Cache operations
    ${FLOW_COLORS[muted]}status | clear | rebuild${FLOW_COLORS[reset]}    Cache management
  ${FLOW_COLORS[cmd]}teach clean${FLOW_COLORS[reset]}                     Delete _freeze/ + _site/

${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
🚀 DEPLOYMENT & MANAGEMENT
${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach deploy${FLOW_COLORS[reset]} [files]            Deploy course website
    ${FLOW_COLORS[muted]}--preview${FLOW_COLORS[reset]}                    Show changes before PR
    ${FLOW_COLORS[muted]}--auto-commit${FLOW_COLORS[reset]}                Auto-commit rendered files
    ${FLOW_COLORS[muted]}--auto-tag${FLOW_COLORS[reset]}                   Tag deployment
  ${FLOW_COLORS[cmd]}teach status${FLOW_COLORS[reset]}                    Project dashboard
  ${FLOW_COLORS[cmd]}teach week${FLOW_COLORS[reset]}                      Current week info
  ${FLOW_COLORS[cmd]}teach backup${FLOW_COLORS[reset]}                    Backup management
    ${FLOW_COLORS[muted]}create | list | restore | delete${FLOW_COLORS[reset]}  Backup operations
  ${FLOW_COLORS[cmd]}teach archive${FLOW_COLORS[reset]}                   Archive semester

${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
🔧 ADVANCED FEATURES
${FLOW_COLORS[bold]}═══════════════════════════════════════════════════════════${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach demo${FLOW_COLORS[reset]} <topic>              Create demo course
  ${FLOW_COLORS[cmd]}teach validate --custom${FLOW_COLORS[reset]}         Custom validators
  ${FLOW_COLORS[cmd]}teach status --performance${FLOW_COLORS[reset]}      Performance metrics
  ${FLOW_COLORS[cmd]}teach deploy --branch <name>${FLOW_COLORS[reset]}    Custom branches

${FLOW_COLORS[bold]}SHORTCUTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}i${FLOW_COLORS[reset]} → init      ${FLOW_COLORS[accent]}doc${FLOW_COLORS[reset]} → doctor  ${FLOW_COLORS[accent]}val${FLOW_COLORS[reset]} → validate
  ${FLOW_COLORS[accent]}lec${FLOW_COLORS[reset]} → lecture  ${FLOW_COLORS[accent]}sl${FLOW_COLORS[reset]} → slides   ${FLOW_COLORS[accent]}e${FLOW_COLORS[reset]} → exam
  ${FLOW_COLORS[accent]}q${FLOW_COLORS[reset]} → quiz      ${FLOW_COLORS[accent]}hw${FLOW_COLORS[reset]} → assign   ${FLOW_COLORS[accent]}syl${FLOW_COLORS[reset]} → syllabus
  ${FLOW_COLORS[accent]}d${FLOW_COLORS[reset]} → deploy    ${FLOW_COLORS[accent]}bk${FLOW_COLORS[reset]} → backup  ${FLOW_COLORS[accent]}s${FLOW_COLORS[reset]} → status
  ${FLOW_COLORS[accent]}w${FLOW_COLORS[reset]} → week      ${FLOW_COLORS[accent]}c${FLOW_COLORS[reset]} → config

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Setup new course${FLOW_COLORS[reset]}
  $ teach init "STAT 440" --github
  $ teach doctor --fix
  $ teach hooks install

  ${FLOW_COLORS[muted]}# Create content${FLOW_COLORS[reset]}
  $ teach lecture "Linear Regression" --week 5 --template quarto
  $ teach quiz "Hypothesis Testing" --questions 10 --week 4
  $ teach exam "Midterm" --template quarto

  ${FLOW_COLORS[muted]}# Validate before deploy${FLOW_COLORS[reset]}
  $ teach validate --render
  $ teach deploy --preview

  ${FLOW_COLORS[muted]}# Deploy and backup${FLOW_COLORS[reset]}
  $ teach deploy
  $ teach backup create "After Week 5"

${FLOW_COLORS[muted]}📚 SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}qu${FLOW_COLORS[reset]} - Quarto commands (qu preview, qu render)
  ${FLOW_COLORS[cmd]}g${FLOW_COLORS[reset]} - Git commands (g status, g push)
  ${FLOW_COLORS[cmd]}work${FLOW_COLORS[reset]} - Session management
  docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

EOF
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
            case "$1" in
                --help|-h|help) _teach_lecture_help; return 0 ;;
                *) _teach_scholar_wrapper "lecture" "$@" ;;
            esac
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
            # v5.14.0 - Task 10: Reimplemented with --config and --github flags
            _teach_init "$@"
            ;;

        # Shortcuts for common operations
        deploy|d)
            case "$1" in
                --help|-h|help) _teach_deploy_help; return 0 ;;
                *) _teach_deploy_enhanced "$@" ;;
            esac
            ;;

        archive|a)
            # v5.14.0 (Task 5): Use new backup system
            _teach_archive_command "$@"
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
            _teach_show_status "$@"
            ;;

        week|w)
            _teach_show_week "$@"
            ;;

        # Date management
        dates)
            _teach_dates_dispatcher "$@"
            ;;

        # Backup management (v5.14.0 - Task 5)
        backup|bk)
            _teach_backup_command "$@"
            ;;

        # Health check (v5.14.0 - Task 2)
        doctor|doc)
            case "$1" in
                --help|-h|help) _teach_doctor_help; return 0 ;;
                *) _teach_doctor "$@" ;;
            esac
            ;;

        # Validation (Week 2-3: Validation Commands)
        validate|val|v)
            teach-validate "$@"
            ;;

        # Cache management (Week 3-4: Cache Management)
        cache)
            teach_cache "$@"
            ;;

        # Clean command (delete _freeze/ + _site/)
        clean)
            teach_clean "$@"
            ;;

        # Profile management (Phase 2 - Wave 1: Profile Management)
        profiles|profile|prof)
            _teach_profiles "$@"
            ;;

        # Git hooks management (v5.14.0 - PR #277 Task 2)
        hooks|hook)
            local subcmd="$1"
            shift

            case "$subcmd" in
                install|i)
                    _install_git_hooks "$@"
                    ;;
                upgrade|up|u)
                    _upgrade_git_hooks "$@"
                    ;;
                uninstall|remove|rm)
                    _uninstall_git_hooks "$@"
                    ;;
                status|check|s)
                    _check_all_hooks "$@"
                    ;;
                help|--help|-h)
                    _teach_hooks_help
                    ;;
                *)
                    _teach_error "Unknown hooks command: $subcmd"
                    echo ""
                    _teach_hooks_help
                    return 1
                    ;;
            esac
            ;;
        *)
            _teach_error "Unknown command: $cmd"
            echo ""
            _teach_dispatcher_help
            return 1
            ;;
    esac
}

# Show teaching project status (Enhanced Dashboard - Week 8)
_teach_show_status() {
    # Help check
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_status_help
        return 0
    fi

    local config_file=".flow/teach-config.yml"

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Not a teaching project (no .flow/teach-config.yml)"
        return 1
    fi

    # Check for --performance flag (Phase 2 Wave 5)
    if [[ "$1" == "--performance" ]]; then
        # Source performance monitor if not already loaded
        if [[ -z "$_FLOW_PERFORMANCE_MONITOR_LOADED" ]]; then
            local perf_path="${0:A:h}/../performance-monitor.zsh"
            [[ -f "$perf_path" ]] && source "$perf_path"
        fi

        if typeset -f _format_performance_dashboard >/dev/null 2>&1; then
            _format_performance_dashboard 7  # Default: 7 days
            return $?
        else
            _flow_log_error "Performance monitoring not available"
            return 1
        fi
    fi

    # Check for --full flag to show old detailed view
    if [[ "$1" == "--full" ]]; then
        _teach_show_status_full
        return 0
    fi

    # Use enhanced dashboard by default (Week 8)
    if typeset -f _teach_show_status_dashboard >/dev/null 2>&1; then
        _teach_show_status_dashboard
        return $?
    else
        # Fallback to basic status if dashboard not loaded
        _teach_show_status_full
        return $?
    fi
}

# Full status (detailed view - retained for --full flag)
_teach_show_status_full() {
    local config_file=".flow/teach-config.yml"

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
                local file_status=$(git status --porcelain "$file" 2>/dev/null | awk '{print $1}')
                local status_label
                case "$file_status" in
                    M) status_label="${FLOW_COLORS[warn]}M${FLOW_COLORS[reset]}" ;;
                    A) status_label="${FLOW_COLORS[success]}A${FLOW_COLORS[reset]}" ;;
                    D) status_label="${FLOW_COLORS[error]}D${FLOW_COLORS[reset]}" ;;
                    ??) status_label="${FLOW_COLORS[muted]}??${FLOW_COLORS[reset]}" ;;
                    *) status_label="$file_status" ;;
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
    # DEPLOYMENT STATUS (v5.14.0 - Task 7)
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}🚀 Deployment Status${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Check for last deployment commit
    if _git_in_repo; then
        local last_deploy=$(git log --all --grep="deploy" --grep="Publish" -i --format="%h %s (%cr)" --max-count=1 2>/dev/null)
        if [[ -n "$last_deploy" ]]; then
            echo "  Last Deploy:  $last_deploy"
        else
            echo "  Last Deploy:  ${FLOW_COLORS[muted]}No deployments found${FLOW_COLORS[reset]}"
        fi

        # Check for open PRs (requires gh CLI)
        if command -v gh >/dev/null 2>&1; then
            local pr_count=$(gh pr list --state open 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$pr_count" -gt 0 ]]; then
                echo "  Open PRs:     ${FLOW_COLORS[warning]}$pr_count pending${FLOW_COLORS[reset]}"
                # Show first PR details
                local pr_info=$(gh pr list --state open --limit 1 --json number,title,headRefName 2>/dev/null | \
                    command -v jq >/dev/null 2>&1 && jq -r '.[0] | "#\(.number): \(.title) (\(.headRefName))"' 2>/dev/null || echo "")
                [[ -n "$pr_info" ]] && echo "                $pr_info"
            else
                echo "  Open PRs:     ${FLOW_COLORS[success]}None${FLOW_COLORS[reset]}"
            fi
        fi
    fi

    # ============================================
    # BACKUP SUMMARY (v5.14.0 - Task 7)
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}💾 Backup Summary${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    local -A backup_counts=()
    local total_backups=0
    local latest_backup=""
    local latest_backup_time=0

    # Count backups for each content type
    for dir in exams lectures slides assignments quizzes syllabi rubrics; do
        if [[ -d "$dir" ]]; then
            # Find all content folders in this directory
            for content_dir in "$dir"/*(/N); do
                if [[ -d "$content_dir" ]]; then
                    local count=$(_teach_count_backups "$content_dir")
                    if [[ "$count" -gt 0 ]]; then
                        backup_counts[$dir]=$((${backup_counts[$dir]:-0} + count))
                        ((total_backups += count))

                        # Find most recent backup
                        local recent=$(_teach_list_backups "$content_dir" | head -1)
                        if [[ -n "$recent" ]]; then
                            local backup_time=$(stat -f %m "$recent" 2>/dev/null || stat -c %Y "$recent" 2>/dev/null)
                            if [[ "$backup_time" -gt "$latest_backup_time" ]]; then
                                latest_backup_time=$backup_time
                                latest_backup=$(basename "$recent")
                            fi
                        fi
                    fi
                fi
            done
        fi
    done

    # Display summary
    if [[ $total_backups -gt 0 ]]; then
        echo "  Total Backups:  $total_backups"

        # Show last backup time
        if [[ -n "$latest_backup" && "$latest_backup_time" -gt 0 ]]; then
            # Convert timestamp to readable date (macOS/Linux compatible)
            local time_ago
            time_ago=$(date -r "$latest_backup_time" '+%Y-%m-%d %H:%M' 2>/dev/null || \
                       date -d "@$latest_backup_time" '+%Y-%m-%d %H:%M' 2>/dev/null || \
                       echo "$latest_backup")
            echo "  Last Backup:    $time_ago"
        fi

        # Breakdown by type
        if [[ ${#backup_counts[@]} -gt 0 ]]; then
            echo ""
            echo "  ${FLOW_COLORS[dim]}By Content Type:${FLOW_COLORS[reset]}"
            for dir in exams lectures slides assignments quizzes syllabi rubrics; do
                if [[ -n "${backup_counts[$dir]}" && "${backup_counts[$dir]}" -gt 0 ]]; then
                    printf "    %-15s %s backups\n" "$dir:" "${backup_counts[$dir]}"
                fi
            done
        fi
    else
        echo "  ${FLOW_COLORS[muted]}No backups yet${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[dim]}Backups are created automatically when regenerating content${FLOW_COLORS[reset]}"
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

# ==============================================================================
# BACKUP COMMAND (v5.14.0 - Task 5)
# ==============================================================================

# Backup command dispatcher
# Usage: teach backup <subcommand> [args]
_teach_backup_command() {
    local subcmd="${1:-list}"
    shift 2>/dev/null || true

    case "$subcmd" in
        create|c)
            _teach_backup_create "$@"
            ;;
        list|ls|l)
            _teach_backup_list "$@"
            ;;
        restore|r)
            _teach_backup_restore "$@"
            ;;
        delete|del|rm)
            _teach_backup_delete "$@"
            ;;
        archive|a)
            _teach_backup_archive "$@"
            ;;
        help|-h|--help)
            _teach_backup_help
            ;;
        *)
            _flow_log_error "Unknown backup subcommand: $subcmd"
            echo ""
            _teach_backup_help
            return 1
            ;;
    esac
}

# Create backup - Main backup interface
_teach_backup_create() {
    local content_path="$1"
    local backup_name="${2:-}"

    # Help check
    if [[ "$content_path" == "--help" || "$content_path" == "-h" ]]; then
        echo ""
        echo "${FLOW_COLORS[bold]}teach backup create${FLOW_COLORS[reset]} - Create timestamped backup"
        echo ""
        echo "${FLOW_COLORS[bold]}USAGE:${FLOW_COLORS[reset]}"
        echo "  teach backup create [content_path] [name]"
        echo ""
        echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
        echo "  teach backup create lectures/week-01    # Auto timestamp"
        echo "  teach backup create exams/midterm       # Backup exam"
        echo "  teach backup create .                   # Backup all"
        echo ""
        return 0
    fi

    # Default to current directory
    if [[ -z "$content_path" ]]; then
        content_path="."
    fi

    if [[ ! -d "$content_path" ]]; then
        _flow_log_error "Path not found: $content_path"
        return 1
    fi

    # Create backup
    local backup_path=$(_teach_backup_content "$content_path")

    if [[ $? -eq 0 && -n "$backup_path" ]]; then
        _flow_log_success "Backup created: $(basename "$backup_path")"

        # Update metadata
        _teach_backup_update_metadata "$content_path" "$backup_path"

        return 0
    else
        _flow_log_error "Failed to create backup"
        return 1
    fi
}

# List all backups
_teach_backup_list() {
    local content_path="${1:-.}"

    # Help check
    if [[ "$content_path" == "--help" || "$content_path" == "-h" ]]; then
        echo ""
        echo "${FLOW_COLORS[bold]}teach backup list${FLOW_COLORS[reset]} - List all backups"
        echo ""
        echo "${FLOW_COLORS[bold]}USAGE:${FLOW_COLORS[reset]}"
        echo "  teach backup list [content_path]"
        echo ""
        echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
        echo "  teach backup list                   # List all backups"
        echo "  teach backup list lectures/week-01  # List specific backups"
        echo ""
        return 0
    fi

    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        echo ""
        echo "${FLOW_COLORS[muted]}No backups found for: $content_path${FLOW_COLORS[reset]}"
        echo ""
        return 0
    fi

    local backups=$(_teach_list_backups "$content_path")

    if [[ -z "$backups" ]]; then
        echo ""
        echo "${FLOW_COLORS[muted]}No backups found${FLOW_COLORS[reset]}"
        echo ""
        return 0
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}Backups for: $(basename "$content_path")${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    local count=0
    while IFS= read -r backup; do
        local backup_name=$(basename "$backup")
        local size=$(du -sh "$backup" 2>/dev/null | awk '{print $1}')
        local file_count=$(find "$backup" -type f 2>/dev/null | wc -l | tr -d ' ')

        # Extract timestamp from backup name
        local timestamp=$(echo "$backup_name" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{4\}' || echo "")

        echo "  ${FLOW_COLORS[accent]}${backup_name}${FLOW_COLORS[reset]}"
        echo "    Size: ${size}  Files: ${file_count}"

        if [[ -n "$timestamp" ]]; then
            # Convert timestamp to human-readable
            local year="${timestamp:0:4}"
            local month="${timestamp:5:2}"
            local day="${timestamp:8:2}"
            local time="${timestamp:11:2}:${timestamp:13:2}"
            echo "    Date: ${year}-${month}-${day} ${time}"
        fi

        echo ""
        ((count++))
    done <<< "$backups"

    echo "${FLOW_COLORS[success]}Total backups: $count${FLOW_COLORS[reset]}"
    echo ""
}

# Restore from backup
_teach_backup_restore() {
    local backup_name="$1"

    # Help check
    if [[ "$backup_name" == "--help" || "$backup_name" == "-h" || -z "$backup_name" ]]; then
        echo ""
        echo "${FLOW_COLORS[bold]}teach backup restore${FLOW_COLORS[reset]} - Restore from backup"
        echo ""
        echo "${FLOW_COLORS[bold]}USAGE:${FLOW_COLORS[reset]}"
        echo "  teach backup restore <backup_name>"
        echo ""
        echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
        echo "  teach backup list                           # Find backup name"
        echo "  teach backup restore lectures.2026-01-20-1430"
        echo ""
        echo "${FLOW_COLORS[warning]}⚠ WARNING: This will overwrite current content${FLOW_COLORS[reset]}"
        echo ""
        return 0
    fi

    # Use smart path resolution (PR #277 Task 3)
    local found_backup=$(_resolve_backup_path "$backup_name")

    if [[ $? -ne 0 || -z "$found_backup" ]]; then
        echo ""
        echo "Use ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} to see available backups"
        echo ""
        return 1
    fi

    # Get content path (parent of .backups)
    local content_path=$(dirname "$(dirname "$found_backup")")

    # Confirm restore
    echo ""
    echo "${FLOW_COLORS[warning]}⚠ Restore Backup?${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
    echo "  From:     $backup_name"
    echo "  To:       $content_path"
    echo ""
    echo "${FLOW_COLORS[error]}⚠ This will overwrite current content!${FLOW_COLORS[reset]}"
    echo ""

    read -q "REPLY?Proceed with restore? [y/N] "
    local response="$REPLY"
    echo ""

    if [[ ! "$response" =~ ^[yY]$ ]]; then
        echo ""
        echo "${FLOW_COLORS[info]}Cancelled - no changes made${FLOW_COLORS[reset]}"
        echo ""
        return 1
    fi

    # Perform restore
    if command -v rsync &>/dev/null; then
        rsync -a --delete "$found_backup/" "$content_path/" 2>/dev/null
    else
        rm -rf "$content_path"/* 2>/dev/null
        cp -R "$found_backup"/* "$content_path/" 2>/dev/null
    fi

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Restored from backup: $backup_name"
        return 0
    else
        _flow_log_error "Failed to restore backup"
        return 1
    fi
}

# Delete backup
_teach_backup_delete() {
    local backup_name="$1"
    local force=false

    if [[ "$2" == "--force" ]]; then
        force=true
    fi

    # Help check
    if [[ "$backup_name" == "--help" || "$backup_name" == "-h" || -z "$backup_name" ]]; then
        echo ""
        echo "${FLOW_COLORS[bold]}teach backup delete${FLOW_COLORS[reset]} - Delete backup"
        echo ""
        echo "${FLOW_COLORS[bold]}USAGE:${FLOW_COLORS[reset]}"
        echo "  teach backup delete <backup_name> [--force]"
        echo ""
        echo "${FLOW_COLORS[bold]}OPTIONS:${FLOW_COLORS[reset]}"
        echo "  --force    Skip confirmation prompt"
        echo ""
        echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
        echo "  teach backup delete lectures.2026-01-20-1430"
        echo "  teach backup delete old-backup --force"
        echo ""
        return 0
    fi

    # Use smart path resolution (PR #277 Task 3)
    local found_backup=$(_resolve_backup_path "$backup_name")

    if [[ $? -ne 0 || -z "$found_backup" ]]; then
        return 1
    fi

    # Delete with confirmation (unless --force)
    if [[ "$force" == "false" ]]; then
        _teach_delete_backup "$found_backup"
    else
        _teach_delete_backup "$found_backup" --force
    fi

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Deleted backup: $backup_name"
        return 0
    else
        return 1
    fi
}

# Archive semester backups
_teach_backup_archive() {
    local semester_name="${1:-}"

    # Help check
    if [[ "$semester_name" == "--help" || "$semester_name" == "-h" ]]; then
        echo ""
        echo "${FLOW_COLORS[bold]}teach backup archive${FLOW_COLORS[reset]} - Archive semester backups"
        echo ""
        echo "${FLOW_COLORS[bold]}USAGE:${FLOW_COLORS[reset]}"
        echo "  teach backup archive <semester_name>"
        echo ""
        echo "${FLOW_COLORS[bold]}DESCRIPTION:${FLOW_COLORS[reset]}"
        echo "  Archives all backups based on retention policies."
        echo "  - archive policy: Keeps backups in compressed archive"
        echo "  - semester policy: Deletes backups at semester end"
        echo ""
        echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
        echo "  teach backup archive spring-2026"
        echo "  teach backup archive fall-2025"
        echo ""
        return 0
    fi

    if [[ -z "$semester_name" ]]; then
        _flow_log_error "Semester name required"
        echo ""
        echo "Usage: teach backup archive <semester_name>"
        echo "Example: teach backup archive spring-2026"
        echo ""
        return 1
    fi

    # Call the archive function from backup-helpers
    _teach_archive_semester "$semester_name"
}

# Backup help
_teach_backup_help() {
    local _C_BOLD="${_C_BOLD:-\033[1m}"
    local _C_NC="${_C_NC:-\033[0m}"
    local _C_CYAN="${_C_CYAN:-\033[0;36m}"
    local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
    local _C_DIM="${_C_DIM:-\033[2m}"

    echo -e "
${_C_BOLD}╭──────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ 💾 TEACH BACKUP - Content Backup System     │${_C_NC}
${_C_BOLD}╰──────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach backup <subcommand> [args]

${_C_BOLD}SUBCOMMANDS:${_C_NC}
  ${_C_CYAN}create [path]${_C_NC}          Create timestamped backup
  ${_C_CYAN}list [path]${_C_NC}            List all backups
  ${_C_CYAN}restore <name>${_C_NC}         Restore from backup
  ${_C_CYAN}delete <name>${_C_NC}          Delete backup (with confirmation)
  ${_C_CYAN}archive <semester>${_C_NC}     Archive semester backups

${_C_YELLOW}💡 EXAMPLES:${_C_NC}
  ${_C_DIM}\$${_C_NC} teach backup create lectures/week-01    ${_C_DIM}# Create backup${_C_NC}
  ${_C_DIM}\$${_C_NC} teach backup list                       ${_C_DIM}# List all backups${_C_NC}
  ${_C_DIM}\$${_C_NC} teach backup restore lectures.2026-01-20-1430
  ${_C_DIM}\$${_C_NC} teach backup archive spring-2026        ${_C_DIM}# End of semester${_C_NC}

${_C_BOLD}BACKUP STRUCTURE:${_C_NC}
  ${_C_DIM}.backups/${_C_NC}
  ${_C_DIM}├── lectures.2026-01-20-1430/${_C_NC}    Timestamped snapshots
  ${_C_DIM}├── lectures.2026-01-19-0900/${_C_NC}
  ${_C_DIM}└── metadata.json${_C_NC}                Backup metadata

${_C_BOLD}RETENTION POLICIES:${_C_NC}
  ${_C_DIM}archive:${_C_NC}    Keep forever (exams, syllabi)
  ${_C_DIM}semester:${_C_NC}   Delete at semester end (lectures)

${_C_DIM}Get subcommand help:${_C_NC} teach backup <subcommand> --help
"
}

# Update backup metadata
_teach_backup_update_metadata() {
    local content_path="$1"
    local backup_path="$2"
    local metadata_file="$content_path/.backups/metadata.json"

    # Create metadata directory if needed
    mkdir -p "$(dirname "$metadata_file")"

    # Initialize metadata file if it doesn't exist
    if [[ ! -f "$metadata_file" ]]; then
        echo "{\"backups\":[]}" > "$metadata_file"
    fi

    # Get backup info
    local backup_name=$(basename "$backup_path")
    local timestamp=$(date +%s)
    local size=$(du -sh "$backup_path" 2>/dev/null | awk '{print $1}')
    local file_count=$(find "$backup_path" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Add to metadata (simplified - full JSON manipulation would need jq)
    # For now, just append a simple entry
    if command -v jq &>/dev/null; then
        local tmp_file=$(mktemp)
        jq --arg name "$backup_name" \
           --arg ts "$timestamp" \
           --arg size "$size" \
           --arg files "$file_count" \
           '.backups += [{name: $name, timestamp: ($ts|tonumber), size: $size, files: ($files|tonumber)}]' \
           "$metadata_file" > "$tmp_file" && mv "$tmp_file" "$metadata_file"
    fi
}
