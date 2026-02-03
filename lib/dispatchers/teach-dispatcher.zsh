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

# Source teach-migrate command (v5.20.0 - Lesson Plan Extraction #298)
if [[ -z "$_FLOW_TEACH_MIGRATE_LOADED" ]]; then
    local migrate_path="${0:A:h:h}/../commands/teach-migrate.zsh"
    [[ -f "$migrate_path" ]] && source "$migrate_path"
    typeset -g _FLOW_TEACH_MIGRATE_LOADED=1
fi

# Source teach-templates command (v5.20.0 - Template Support #301)
if [[ -z "$_FLOW_TEACH_TEMPLATES_LOADED" ]]; then
    local templates_path="${0:A:h:h}/../commands/teach-templates.zsh"
    [[ -f "$templates_path" ]] && source "$templates_path"
    typeset -g _FLOW_TEACH_TEMPLATES_LOADED=1
fi

# Source teach-macros command (v5.21.0 - LaTeX Macro Support)
if [[ -z "$_FLOW_TEACH_MACROS_LOADED" ]]; then
    local macros_path="${0:A:h:h}/../commands/teach-macros.zsh"
    [[ -f "$macros_path" ]] && source "$macros_path"
    typeset -g _FLOW_TEACH_MACROS_LOADED=1
fi

# Source teach-plan command (v5.22.0 - Lesson Plan CRUD #278)
if [[ -z "$_FLOW_TEACH_PLAN_LOADED" ]]; then
    local plan_path="${0:A:h:h}/../commands/teach-plan.zsh"
    [[ -f "$plan_path" ]] && source "$plan_path"
    typeset -g _FLOW_TEACH_PLAN_LOADED=1
fi

# Source teach-prompt command (v5.23.0 - AI Prompt Management)
if [[ -z "$_FLOW_TEACH_PROMPT_LOADED" ]]; then
    local prompt_path="${0:A:h:h}/../commands/teach-prompt.zsh"
    [[ -f "$prompt_path" ]] && source "$prompt_path"
    typeset -g _FLOW_TEACH_PROMPT_LOADED=1
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
_teach_validate_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach validate${FLOW_COLORS[reset]} - Validate Quarto Files                   ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach validate [files...] [options]
  ${FLOW_COLORS[cmd]}teach validate --yaml <file>
  ${FLOW_COLORS[cmd]}teach validate --watch

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}val${FLOW_COLORS[reset]} → validate

${FLOW_COLORS[bold]}VALIDATION MODES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--yaml${FLOW_COLORS[reset]}         YAML frontmatter only (fast)
  ${FLOW_COLORS[cmd]}--syntax${FLOW_COLORS[reset]}       YAML + syntax check
  ${FLOW_COLORS[cmd]}--render${FLOW_COLORS[reset]}       Full render validation
  ${FLOW_COLORS[cmd]}--custom${FLOW_COLORS[reset]}       Run custom validators
  ${FLOW_COLORS[cmd]}--lint${FLOW_COLORS[reset]}         Run Quarto-aware lint rules (.teach/validators/lint-*.zsh)
  ${FLOW_COLORS[cmd]}--quick-checks${FLOW_COLORS[reset]} Run fast lint subset only (Phase 1 rules)
  ${FLOW_COLORS[cmd]}--deep${FLOW_COLORS[reset]}         Full validation + concept analysis (Layer 6)
  ${FLOW_COLORS[cmd]}--concepts${FLOW_COLORS[reset]}     Concept prerequisite validation only

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--validators${FLOW_COLORS[reset]} <list>  Comma-separated validator list (with --custom)
  ${FLOW_COLORS[cmd]}--watch, -w${FLOW_COLORS[reset]}          Watch mode (fswatch)
  ${FLOW_COLORS[cmd]}--stats${FLOW_COLORS[reset]}              Show validation statistics
  ${FLOW_COLORS[cmd]}--quiet, -q${FLOW_COLORS[reset]}          Minimal output

${FLOW_COLORS[bold]}CUSTOM VALIDATORS${FLOW_COLORS[reset]}
  Place scripts in ${FLOW_COLORS[accent]}.teach/validators/${FLOW_COLORS[reset]}
  Built-in: check-citations, check-links, check-formatting
  Run: teach validate --custom

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Quick YAML check${FLOW_COLORS[reset]}
  $ teach validate --yaml lectures/week-05/

  ${FLOW_COLORS[muted]}# Full render validation${FLOW_COLORS[reset]}
  $ teach validate --render

  ${FLOW_COLORS[muted]}# Deep validation with concept analysis${FLOW_COLORS[reset]}
  $ teach validate --deep

  ${FLOW_COLORS[muted]}# Watch for changes${FLOW_COLORS[reset]}
  $ teach validate --watch

  ${FLOW_COLORS[muted]}# Run custom validators${FLOW_COLORS[reset]}
  $ teach validate --custom

${FLOW_COLORS[bold]}EXIT CODES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}0${FLOW_COLORS[reset]} - All valid
  ${FLOW_COLORS[error]}1${FLOW_COLORS[reset]} - Warnings
  ${FLOW_COLORS[error]}2${FLOW_COLORS[reset]} - Errors

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Pre-commit hooks auto-validate on commit
  • Use ${FLOW_COLORS[accent]}--yaml${FLOW_COLORS[reset]} for quick checks
  • Install fswatch for --watch mode

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-QUARTO-WORKFLOW-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} - Health checks
  ${FLOW_COLORS[cmd]}teach cache${FLOW_COLORS[reset]} - Cache management

EOF
}

# Help for teach cache command
_teach_cache_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach cache${FLOW_COLORS[reset]} - Cache Management                          ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach cache <command> [options]

${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}status${FLOW_COLORS[reset]}              Show cache statistics
  ${FLOW_COLORS[cmd]}clear${FLOW_COLORS[reset]}               Clear all cache
  ${FLOW_COLORS[cmd]}rebuild${FLOW_COLORS[reset]}             Rebuild frozen content
  ${FLOW_COLORS[cmd]}analyze${FLOW_COLORS[reset]}             Analyze cache usage
  ${FLOW_COLORS[cmd]}clean${FLOW_COLORS[reset]}               Clean stale entries

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--lectures${FLOW_COLORS[reset]}          Target lectures only
  ${FLOW_COLORS[cmd]}--assignments${FLOW_COLORS[reset]}       Target assignments only
  ${FLOW_COLORS[cmd]}--old [days]${FLOW_COLORS[reset]}        Clear entries older than N days
  ${FLOW_COLORS[cmd]}--unused${FLOW_COLORS[reset]}            Clear unused cache
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}              JSON output

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Show cache status${FLOW_COLORS[reset]}
  $ teach cache status

  ${FLOW_COLORS[muted]}# Clear lecture cache only${FLOW_COLORS[reset]}
  $ teach cache clear --lectures

  ${FLOW_COLORS[muted]}# Rebuild frozen content${FLOW_COLORS[reset]}
  $ teach cache rebuild

  ${FLOW_COLORS[muted]}# Analyze cache usage${FLOW_COLORS[reset]}
  $ teach cache analyze

  ${FLOW_COLORS[muted]}# Clear entries older than 7 days${FLOW_COLORS[reset]}
  $ teach cache clean --old 7

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Cache is stored in ${FLOW_COLORS[accent]}_freeze/${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}teach cache status${FLOW_COLORS[reset]} to diagnose issues
  • Clear cache before re-rendering from scratch

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach clean${FLOW_COLORS[reset]} - Delete _freeze/ and _site/
  ${FLOW_COLORS[cmd]}qu${FLOW_COLORS[reset]} - Quarto commands

EOF
}

# Help for teach profiles command
_teach_profiles_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach profiles${FLOW_COLORS[reset]} - Quarto Profile Management             ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach profiles [list|switch|create] [name]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Manage Quarto profiles for different output formats:
  • default     - Standard web output
  • draft       - Draft mode (faster rendering)
  • print       - Print-optimized
  • slides      - Presentation mode

${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}list, ls${FLOW_COLORS[reset]}             List available profiles
  ${FLOW_COLORS[cmd]}switch <name>${FLOW_COLORS[reset]}        Activate profile
  ${FLOW_COLORS[cmd]}create <name>${FLOW_COLORS[reset]}        Create new profile

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# List profiles${FLOW_COLORS[reset]}
  $ teach profiles list

  ${FLOW_COLORS[muted]}# Switch to draft mode${FLOW_COLORS[reset]}
  $ teach profiles switch draft

  ${FLOW_COLORS[muted]}# Create custom profile${FLOW_COLORS[reset]}
  $ teach profiles create my-config

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Profiles defined in ${FLOW_COLORS[accent]}_quarto.yml${FLOW_COLORS[reset]}
  • Draft mode renders ~2x faster
  • Quarto profiles are separate from R package profiles

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}qu${FLOW_COLORS[reset]} - Quarto commands
  ${FLOW_COLORS[cmd]}teach cache${FLOW_COLORS[reset]} - Cache management

EOF
}

# Help for teach clean command
_teach_clean_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach clean${FLOW_COLORS[reset]} - Clean Build Artifacts                   ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach clean [options]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Remove Quarto build artifacts to start fresh:
  • _freeze/     - Cached render output
  • _site/       - Generated website files
  • .quarto/     - Quarto cache

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--freeze${FLOW_COLORS[reset]}             Clear _freeze/ only
  ${FLOW_COLORS[cmd]}--site${FLOW_COLORS[reset]}               Clear _site/ only
  ${FLOW_COLORS[cmd]}--all${FLOW_COLORS[reset]}                Clear everything (default)
  ${FLOW_COLORS[cmd]}--dry-run${FLOW_COLORS[reset]}            Show what would be deleted

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Clear everything${FLOW_COLORS[reset]}
  $ teach clean

  ${FLOW_COLORS[muted]}# Clear cache only${FLOW_COLORS[reset]}
  $ teach clean --freeze

  ${FLOW_COLORS[muted]}# Preview what will be deleted${FLOW_COLORS[reset]}
  $ teach clean --dry-run

${FLOW_COLORS[bold]}WARNING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[error]}This action cannot be undone!${FLOW_COLORS[reset]}
  Use ${FLOW_COLORS[accent]}--dry-run${FLOW_COLORS[reset]} first to preview.

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Run ${FLOW_COLORS[accent]}teach clean${FLOW_COLORS[reset]} before full re-render
  • Use ${FLOW_COLORS[accent]}teach cache rebuild${FLOW_COLORS[reset]} for smarter clear

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach cache${FLOW_COLORS[reset]} - Selective cache management
  ${FLOW_COLORS[cmd]}qu${FLOW_COLORS[reset]} - Quarto commands

EOF
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

    # Special case: slides --from-lecture (v5.15.0+)
    # Converts lecture .qmd files to RevealJS slides
    if [[ "$subcommand" == "slides" ]]; then
        local from_lecture=""
        local week_num=""
        local optimize=false
        local preview_breaks=false
        local apply_suggestions=false
        local key_concepts=false
        for ((i=1; i<=${#args[@]}; i++)); do
            if [[ "${args[$i]}" == "--from-lecture" ]]; then
                from_lecture="${args[$((i+1))]}"
            elif [[ "${args[$i]}" =~ ^--from-lecture= ]]; then
                from_lecture="${args[$i]#*=}"
            elif [[ "${args[$i]}" == "--week" || "${args[$i]}" == "-w" ]]; then
                week_num="${args[$((i+1))]}"
            elif [[ "${args[$i]}" =~ ^--week= ]]; then
                week_num="${args[$i]#*=}"
            elif [[ "${args[$i]}" =~ ^-w= ]]; then
                week_num="${args[$i]#*=}"
            elif [[ "${args[$i]}" == "--optimize" ]]; then
                optimize=true
            elif [[ "${args[$i]}" == "--preview-breaks" ]]; then
                preview_breaks=true
                optimize=true
            elif [[ "${args[$i]}" == "--apply-suggestions" ]]; then
                apply_suggestions=true
                optimize=true
            elif [[ "${args[$i]}" == "--key-concepts" ]]; then
                key_concepts=true
                optimize=true
            fi
        done

        # If --from-lecture provided OR --week provided (auto-detect lecture files)
        if [[ -n "$from_lecture" ]] || [[ -n "$week_num" ]]; then
            # If --optimize: run slide analysis, optionally preview, then generate
            if [[ "$optimize" == "true" ]]; then
                _teach_slides_optimized "$from_lecture" "$week_num" "$preview_breaks" "$apply_suggestions" "$key_concepts" "${args[@]}"
            else
                _teach_slides_from_lecture "$from_lecture" "$week_num" "${args[@]}"
            fi
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

    # Auto-resolve teaching prompt (v5.23.0 - Prompt Management)
    if typeset -f _teach_resolve_prompt >/dev/null 2>&1; then
        local prompt_path
        prompt_path=$(_teach_resolve_prompt "$subcommand" 2>/dev/null)
        if [[ -n "$prompt_path" && -f "$prompt_path" ]]; then
            # Build extra vars from current context
            typeset -A _scholar_prompt_vars
            [[ -n "$topic" ]] && _scholar_prompt_vars[TOPIC]="$topic"
            [[ -n "$TEACH_WEEK" ]] && _scholar_prompt_vars[WEEK]="$TEACH_WEEK"
            [[ -n "$style" ]] && _scholar_prompt_vars[STYLE]="$style"

            local rendered_prompt
            rendered_prompt=$(_teach_render_prompt "$prompt_path" _scholar_prompt_vars 2>/dev/null)
            if [[ -n "$rendered_prompt" ]]; then
                scholar_cmd="$scholar_cmd --prompt \"$rendered_prompt\""
            fi
        fi
    fi

    # Build full command string for commit message (v5.11.0+)
    local full_command="teach $subcommand ${args[*]}"

    # Execute with subcommand for spinner message
    _teach_execute "$scholar_cmd" "$verbose" "$subcommand" "$topic" "$full_command"
}

# ============================================================================
# SLIDES FROM LECTURE (v5.15.0+)
# Converts lecture .qmd files to RevealJS slides
# ============================================================================

# Generate slides from lecture .qmd files
# Usage: _teach_slides_from_lecture [lecture_file] [week_num] [extra_args...]
_teach_slides_from_lecture() {
    local from_lecture="$1"
    local week_num="$2"
    shift 2
    local -a extra_args=("$@")
    local config_file=".flow/teach-config.yml"
    local -a lecture_files=()
    local verbose=false
    local dry_run=false
    local output_dir="slides"

    # Parse extra args for verbose and dry-run
    for arg in "${extra_args[@]}"; do
        [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && verbose=true
        [[ "$arg" == "--dry-run" ]] && dry_run=true
    done

    # ─────────────────────────────────────────────────────────────────────
    # Step 1: Determine lecture files to convert
    # ─────────────────────────────────────────────────────────────────────

    if [[ -n "$from_lecture" ]]; then
        # Explicit file provided
        if [[ -f "$from_lecture" ]]; then
            lecture_files+=("$from_lecture")
        else
            _teach_error "Lecture file not found: $from_lecture"
            return 1
        fi
    elif [[ -n "$week_num" ]]; then
        # Week number provided - look up files from teach-config.yml
        if [[ ! -f "$config_file" ]]; then
            _teach_error "No teach-config.yml found" "Run 'teach init' first"
            return 1
        fi

        if ! command -v yq &>/dev/null; then
            _teach_error "yq required for config parsing" "Install: brew install yq"
            return 1
        fi

        # Check if week has parts structure
        local has_parts
        has_parts=$(yq ".semester_info.weeks[] | select(.number == $week_num) | .parts // null" "$config_file" 2>/dev/null)

        if [[ "$has_parts" != "null" && -n "$has_parts" ]]; then
            # Multi-part week - get all part files
            local -a part_files
            part_files=($(yq ".semester_info.weeks[] | select(.number == $week_num) | .parts[].file" "$config_file" 2>/dev/null))
            for pf in "${part_files[@]}"; do
                if [[ -f "$pf" ]]; then
                    lecture_files+=("$pf")
                else
                    _teach_warn "Part file not found: $pf"
                fi
            done
        else
            # Single lecture week - try to find lecture file
            local lecture_pattern="lectures/week-$(printf '%02d' $week_num)*.qmd"
            for f in $~lecture_pattern; do
                [[ -f "$f" ]] && lecture_files+=("$f")
            done
        fi

        if [[ ${#lecture_files[@]} -eq 0 ]]; then
            _teach_error "No lecture files found for week $week_num"
            return 1
        fi
    else
        _teach_error "Specify --from-lecture FILE or --week N"
        return 1
    fi

    [[ "$verbose" == "true" ]] && echo "📄 Found ${#lecture_files[@]} lecture file(s) to convert"

    # ─────────────────────────────────────────────────────────────────────
    # Step 2: Process each lecture file
    # ─────────────────────────────────────────────────────────────────────

    local -a generated_files=()

    for lecture_file in "${lecture_files[@]}"; do
        [[ "$verbose" == "true" ]] && echo "📖 Processing: $lecture_file"

        # Generate output filename
        local basename="${lecture_file:t:r}"  # Remove path and extension
        local output_file="${output_dir}/${basename}_slides.qmd"

        # Create output directory if needed
        [[ ! -d "$output_dir" ]] && mkdir -p "$output_dir"

        if [[ "$dry_run" == "true" ]]; then
            echo ""
            echo "📋 Dry-run: Would generate slides from $lecture_file"
            echo "   Output: $output_file"
            _teach_lecture_to_slides_preview "$lecture_file"
        else
            # Generate the slides
            _teach_convert_lecture_to_slides "$lecture_file" "$output_file" "$verbose"
            local exit_code=$?

            if [[ $exit_code -eq 0 ]]; then
                generated_files+=("$output_file")
                echo "✅ Generated: $output_file"
            else
                _teach_warn "Failed to convert: $lecture_file"
            fi
        fi
    done

    # ─────────────────────────────────────────────────────────────────────
    # Step 3: Summary
    # ─────────────────────────────────────────────────────────────────────

    if [[ "$dry_run" != "true" && ${#generated_files[@]} -gt 0 ]]; then
        echo ""
        echo "📊 Generated ${#generated_files[@]} slide file(s):"
        for f in "${generated_files[@]}"; do
            echo "   • $f"
        done
        echo ""
        echo "💡 Next steps:"
        echo "   1. Review and customize the generated slides"
        echo "   2. Run: quarto preview ${generated_files[1]}"
        echo "   3. Add to _quarto.yml navigation if needed"
    fi

    return 0
}

# ============================================================================
# SLIDES WITH OPTIMIZATION (Phase 4)
# Runs slide optimizer before generating slides
# ============================================================================

# Generate slides with AI-powered optimization
# Usage: _teach_slides_optimized <from_lecture> <week_num> <preview> <apply> <key_concepts> [args...]
_teach_slides_optimized() {
    local from_lecture="$1"
    local week_num="$2"
    local preview_breaks="$3"
    local apply_suggestions="$4"
    local key_concepts="$5"
    shift 5
    local -a extra_args=("$@")

    # Source slide optimizer if not already loaded
    if ! typeset -f _slide_optimize >/dev/null 2>&1; then
        source "${0:A:h:h}/slide-optimizer.zsh" 2>/dev/null || {
            _teach_error "Slide optimizer not available" "Ensure lib/slide-optimizer.zsh exists"
            return 1
        }
    fi

    # Resolve lecture files (same logic as _teach_slides_from_lecture)
    local config_file=".flow/teach-config.yml"
    local -a lecture_files=()

    if [[ -n "$from_lecture" && -f "$from_lecture" ]]; then
        lecture_files+=("$from_lecture")
    elif [[ -n "$week_num" ]]; then
        local lecture_pattern="lectures/week-$(printf '%02d' $week_num)*.qmd"
        for f in $~lecture_pattern; do
            [[ -f "$f" ]] && lecture_files+=("$f")
        done
    fi

    if [[ ${#lecture_files[@]} -eq 0 ]]; then
        _teach_error "No lecture files found" "Specify --from-lecture FILE or --week N"
        return 1
    fi

    echo "📐 Slide Optimization Mode"
    echo "═══════════════════════════════════════════════════"
    echo ""

    local -a generated_files=()

    for lecture_file in "${lecture_files[@]}"; do
        echo "📖 Optimizing: ${lecture_file:t}"

        # Step 1: Build concept graph if not available (auto-analyze)
        local concept_graph=""
        local course_dir="${lecture_file:h:h}"
        [[ "$course_dir" == "${lecture_file:t}" ]] && course_dir="."
        if [[ -f "$course_dir/.teach/concepts.json" ]]; then
            concept_graph=$(cat "$course_dir/.teach/concepts.json" 2>/dev/null)
        else
            # Auto-analyze: source and run _teach_analyze to build concept graph
            if ! typeset -f _teach_analyze >/dev/null 2>&1; then
                local analyze_cmd="${FLOW_PLUGIN_DIR:-${0:A:h:h}}/commands/teach-analyze.zsh"
                [[ -f "$analyze_cmd" ]] && source "$analyze_cmd"
            fi
            if typeset -f _teach_analyze >/dev/null 2>&1; then
                echo "  ℹ️  No concept graph found — running analysis first..."
                (cd "$course_dir" && _teach_analyze "$lecture_file" "--quiet") >/dev/null 2>&1
                [[ -f "$course_dir/.teach/concepts.json" ]] && \
                    concept_graph=$(cat "$course_dir/.teach/concepts.json" 2>/dev/null)
            fi
        fi

        local optimization
        optimization=$(_slide_optimize "$lecture_file" "$concept_graph" "false")

        if [[ -z "$optimization" || "$optimization" == "{}" ]]; then
            echo "  ⚠️  No optimization suggestions for this file"
            echo ""
            continue
        fi

        # Step 2: If preview mode, show preview and continue
        if [[ "$preview_breaks" == "true" ]]; then
            _slide_preview_breaks "$optimization"
            continue
        fi

        # Step 2b: If --key-concepts only, show concepts and continue
        if [[ "$key_concepts" == "true" && "$apply_suggestions" != "true" ]]; then
            echo ""
            echo "  🔑 Key Concepts for Callout Boxes:"
            echo "  ─────────────────────────────────────"
            if command -v jq &>/dev/null; then
                echo "$optimization" | jq -r '.key_concepts_for_emphasis[]? | "  • \(.name) (\(.source))"' 2>/dev/null
                local concept_count
                concept_count=$(echo "$optimization" | jq '.key_concepts_for_emphasis | length' 2>/dev/null || echo 0)
                echo ""
                echo "  ${concept_count} concept(s) identified"
            else
                echo "  (jq required for concept display)"
            fi
            echo ""
            # Also show timing estimate
            local est_time
            est_time=$(echo "$optimization" | jq '.time_estimate.total_minutes // 0' 2>/dev/null || echo 0)
            [[ "$est_time" -gt 0 ]] && echo "  ⏱️  Estimated presentation time: ${est_time} min"
            echo ""
            continue
        fi

        # Step 3: Generate optimized slides
        local output_dir="slides"
        local basename="${lecture_file:t:r}"
        local output_file="${output_dir}/${basename}_slides.qmd"
        [[ ! -d "$output_dir" ]] && mkdir -p "$output_dir"

        if [[ "$apply_suggestions" == "true" ]]; then
            # Apply break suggestions directly
            _slide_apply_breaks "$lecture_file" "$output_file" "$optimization"
            if [[ $? -eq 0 ]]; then
                generated_files+=("$output_file")
                echo "  ✅ Generated (optimized): $output_file"
            else
                _teach_warn "Failed to apply optimizations: $lecture_file"
            fi
        else
            # Generate slides normally, then show optimization suggestions
            _teach_convert_lecture_to_slides "$lecture_file" "$output_file" "false"
            if [[ $? -eq 0 ]]; then
                generated_files+=("$output_file")
                echo "  ✅ Generated: $output_file"

                # Show optimization summary
                local break_count=0
                if command -v jq &>/dev/null; then
                    break_count=$(echo "$optimization" | jq '.slide_breaks | length' 2>/dev/null || echo 0)
                fi
                echo "  💡 $break_count optimization suggestions available (use --apply-suggestions)"
            fi
        fi

        # Show key concepts if requested (alongside generation)
        if [[ "$key_concepts" == "true" && "$apply_suggestions" == "true" ]] && command -v jq &>/dev/null; then
            local concept_list
            concept_list=$(echo "$optimization" | jq -r '.key_concepts_for_emphasis[]? | .name' 2>/dev/null | paste -sd', ' -)
            [[ -n "$concept_list" ]] && echo "  🔑 Callout concepts: $concept_list"
        fi

        # Cache optimization results
        if [[ -d "$course_dir/.teach" ]]; then
            echo "$optimization" > "$course_dir/.teach/slide-optimization-${basename}.json" 2>/dev/null
        fi

        echo ""
    done

    # Summary
    if [[ ${#generated_files[@]} -gt 0 && "$preview_breaks" != "true" ]]; then
        echo "═══════════════════════════════════════════════════"
        echo "📊 Generated ${#generated_files[@]} optimized slide file(s)"
        echo ""
        echo "💡 Next steps:"
        echo "   1. Review slides: quarto preview ${generated_files[1]}"
        if [[ "$apply_suggestions" != "true" ]]; then
            echo "   2. Apply optimizations: teach slides --optimize --apply-suggestions --from-lecture ${lecture_files[1]}"
        fi
        echo "   3. Key concepts: teach slides --optimize --key-concepts --from-lecture ${lecture_files[1]}"
    elif [[ "$key_concepts" == "true" && "$preview_breaks" != "true" ]]; then
        echo "═══════════════════════════════════════════════════"
        echo "💡 To generate slides with these concepts as callouts:"
        echo "   teach slides --optimize --apply-suggestions --from-lecture ${lecture_files[1]}"
    fi

    return 0
}

# Preview what would be extracted from lecture file (dry-run)
_teach_lecture_to_slides_preview() {
    local lecture_file="$1"

    # Count sections, code chunks, callouts
    local h2_count h3_count code_chunks callouts

    h2_count=$(grep -c "^## " "$lecture_file" 2>/dev/null || echo 0)
    h3_count=$(grep -c "^### " "$lecture_file" 2>/dev/null || echo 0)
    code_chunks=$(grep -c '```{r' "$lecture_file" 2>/dev/null || echo 0)
    callouts=$(grep -c '::: {.callout' "$lecture_file" 2>/dev/null || echo 0)

    echo ""
    echo "   Content analysis:"
    echo "   ├── H2 sections (slides):    $h2_count"
    echo "   ├── H3 subsections:          $h3_count"
    echo "   ├── R code chunks:           $code_chunks"
    echo "   └── Callout boxes:           $callouts"
    echo ""
    echo "   Estimated slides: ~$((h2_count + h3_count / 2))"
}

# Convert a single lecture file to RevealJS slides
# Usage: _teach_convert_lecture_to_slides <input_file> <output_file> [verbose]
_teach_convert_lecture_to_slides() {
    local input_file="$1"
    local output_file="$2"
    local verbose="${3:-false}"

    # Extract YAML frontmatter using yq for proper parsing
    local title subtitle author date
    title=$(yq '.title // ""' "$input_file" 2>/dev/null)
    subtitle=$(yq '.subtitle // ""' "$input_file" 2>/dev/null)
    author=$(yq '.author // ""' "$input_file" 2>/dev/null)
    date=$(yq '.date // ""' "$input_file" 2>/dev/null)

    # Generate RevealJS YAML header
    {
        echo "---"
        echo "title: \"${title:-Lecture Slides}\""
        echo "subtitle: \"${subtitle:-}\""
        echo "author: \"${author:-}\""
        echo "date: \"${date:-}\""
        echo "format:"
        echo "  revealjs:"
        echo "    theme: [default, custom.scss]"
        echo "    slide-number: true"
        echo "    chalkboard: true"
        echo "    code-line-numbers: true"
        echo "    code-overflow: wrap"
        echo "    highlight-style: github"
        echo "    footer: \"${title:-}\""
        echo "execute:"
        echo "  echo: true"
        echo "  warning: false"
        echo "---"
        echo ""
    } > "$output_file"

    # Process the lecture content
    # Skip the YAML frontmatter and process the rest
    local in_frontmatter=false
    local frontmatter_count=0
    local in_code_block=false
    local in_callout=false
    local callout_depth=0
    local current_section=""
    local slide_count=0
    local line=""

    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Track frontmatter
        if [[ "$line" == "---" ]]; then
            ((frontmatter_count++))
            if [[ $frontmatter_count -le 2 ]]; then
                continue  # Skip YAML frontmatter
            fi
        fi

        # Skip until past frontmatter
        [[ $frontmatter_count -lt 2 ]] && continue

        # Track code blocks (don't modify content inside)
        if [[ "$line" =~ ^\`\`\` ]]; then
            in_code_block=$([[ "$in_code_block" == "true" ]] && echo "false" || echo "true")
        fi

        # Track callouts
        if [[ "$line" =~ '^:::' && "$line" =~ '\{\.callout' ]]; then
            in_callout=true
            ((callout_depth++))
        elif [[ "$line" == ":::" && "$in_callout" == "true" ]]; then
            ((callout_depth--))
            [[ $callout_depth -eq 0 ]] && in_callout=false
        fi

        # Convert H1 to slide title (level 1 becomes title slide)
        if [[ "$line" =~ ^#\  && ! "$line" =~ ^##\  ]]; then
            # H1 becomes a section title slide
            printf '\n' >> "$output_file"
            printf '%s {.center}\n' "$line" >> "$output_file"
            printf '\n' >> "$output_file"
            ((slide_count++))
            continue
        fi

        # H2 becomes new slide
        if [[ "$line" =~ ^##\  && ! "$line" =~ ^###\  ]]; then
            printf '\n' >> "$output_file"
            printf '%s\n' "$line" >> "$output_file"
            ((slide_count++))
            continue
        fi

        # H3 with content becomes slide with incremental reveal
        if [[ "$line" =~ ^###\  ]]; then
            printf '\n' >> "$output_file"
            printf '%s\n' "$line" >> "$output_file"
            continue
        fi

        # Convert TL;DR boxes to callout-note for slides
        if [[ "$line" =~ ':::.+\{\.tldr-box\}' ]]; then
            printf '::: {.callout-tip}\n' >> "$output_file"
            printf '## Key Points\n' >> "$output_file"
            continue
        fi

        # Convert checkpoint questions to interactive elements
        if [[ "$line" =~ "Checkpoint Question" ]]; then
            printf '\n' >> "$output_file"
            printf '::: {.callout-warning}\n' >> "$output_file"
            printf '## 🤔 Checkpoint\n' >> "$output_file"
            continue
        fi

        # Pass through code chunks (important for R examples)
        # Use printf '%s\n' to preserve LaTeX backslashes like \tau, \beta, \alpha
        if [[ "$in_code_block" == "true" ]] || [[ "$line" =~ ^\`\`\` ]]; then
            printf '%s\n' "$line" >> "$output_file"
            continue
        fi

        # Convert columns to slide-friendly format
        if [[ "$line" =~ ':::.+\{\.columns\}' ]]; then
            printf '\n' >> "$output_file"
            printf ':::: {.columns}\n' >> "$output_file"
            continue
        fi

        if [[ "$line" =~ ':::.+\{\.column' ]]; then
            printf '\n' >> "$output_file"
            printf '%s\n' "$line" >> "$output_file"
            continue
        fi

        # Pass through most content
        # IMPORTANT: Use printf '%s\n' instead of echo to preserve LaTeX backslashes
        # echo interprets escape sequences like \t (tab), \b (backspace), \v (vertical tab)
        # which corrupts LaTeX commands like \tau, \beta, \varepsilon, \underbrace, \alpha
        printf '%s\n' "$line" >> "$output_file"

    done < "$input_file"

    [[ "$verbose" == "true" ]] && echo "   Created $slide_count slides"

    return 0
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

# Help for teach status command (v5.14.0 - Task 3, upgraded to box style)
_teach_status_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach status${FLOW_COLORS[reset]} - Show Teaching Project Status           ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach status [options]
  ${FLOW_COLORS[cmd]}teach status --performance    # Performance dashboard
  ${FLOW_COLORS[cmd]}teach status --full           # Detailed legacy view

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}s${FLOW_COLORS[reset]} → status

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Displays comprehensive status of your teaching project including:
  • Course information (name, semester, year)
  • Current branch and git status
  • Config validation status
  • Content inventory (lectures, exams, assignments)
  • Deployment status and open PRs
  • Backup summary

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--performance${FLOW_COLORS[reset]}         Show performance trends and metrics (Phase 2 Wave 5)
  ${FLOW_COLORS[cmd]}--full${FLOW_COLORS[reset]}                Show detailed status view (legacy)
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}                JSON output for scripting

${FLOW_COLORS[bold]}PERFORMANCE DASHBOARD${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach status --performance${FLOW_COLORS[reset]}
  Shows:
  • Render times (last 7 days)
  • Cache hit rates
  • Trend analysis with ASCII graphs
  • Optimization recommendations

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Show full project status${FLOW_COLORS[reset]}
  $ teach status

  ${FLOW_COLORS[muted]}# Performance dashboard${FLOW_COLORS[reset]}
  $ teach status --performance

  ${FLOW_COLORS[muted]}# Short alias${FLOW_COLORS[reset]}
  $ teach s

${FLOW_COLORS[bold]}EXIT CODES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}0${FLOW_COLORS[reset]} - Success
  ${FLOW_COLORS[error]}1${FLOW_COLORS[reset]} - Not a teaching project

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}--performance${FLOW_COLORS[reset]} to track render times
  • Add to CI: ${FLOW_COLORS[cmd]}teach status --json${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} - Health checks
  ${FLOW_COLORS[cmd]}teach backup${FLOW_COLORS[reset]} - Backup management

EOF
}

# Help for teach week command (v5.14.0 - Task 3, upgraded to box style)
_teach_week_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach week${FLOW_COLORS[reset]} - Show Current Week Information           ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach week [WEEK_NUMBER]
  ${FLOW_COLORS[cmd]}teach week --current             # Show current week
  ${FLOW_COLORS[cmd]}teach week --syllabus            # Show from syllabus

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}w${FLOW_COLORS[reset]} → week

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Shows information about the current week or a specific week:
  • Week number calculation from semester start
  • Topics from lesson plan (if available)
  • Content deadlines for the week
  • Upcoming assessments and assignments

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--current, -c${FLOW_COLORS[reset]}          Show current week (default)
  ${FLOW_COLORS[cmd]}--syllabus, -s${FLOW_COLORS[reset]}         Extract from syllabus dates
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}                 JSON output for scripting

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Show current week${FLOW_COLORS[reset]}
  $ teach week

  ${FLOW_COLORS[muted]}# Show week 8 info${FLOW_COLORS[reset]}
  $ teach week 8

  ${FLOW_COLORS[muted]}# Short alias${FLOW_COLORS[reset]}
  $ teach w

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Configure semester dates in ${FLOW_COLORS[accent]}.flow/teach-config.yml${FLOW_COLORS[reset]}
  • Create lesson plans in ${FLOW_COLORS[accent]}.flow/lesson-plans/${FLOW_COLORS[reset]} for detailed info

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach status${FLOW_COLORS[reset]} - Full project status
  ${FLOW_COLORS[cmd]}teach dates${FLOW_COLORS[reset]} - Date management

EOF
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
            echo "       teach slides --week N [options]      # Convert lecture to slides"
            echo "       teach slides --from-lecture FILE     # Convert specific file"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Slides-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --theme NAME         Slide theme (default, academic, minimal)"
            echo "  --from-lecture FILE  Convert lecture .qmd to slides (preserves R code)"
            echo "  --week N, -w N       Auto-detect lecture file(s) from config"
            echo "  --format FORMAT      Output format (quarto, markdown)"
            echo "  --dry-run            Preview content analysis without generating"
            echo "  --verbose, -v        Show detailed progress"
            echo ""
            echo "${FLOW_COLORS[bold]}LECTURE CONVERSION (v5.15.0+)${FLOW_COLORS[reset]}"
            echo "  Converts existing lecture .qmd files to RevealJS slides."
            echo "  Preserves R code chunks, callouts, columns, and examples."
            echo "  Multi-part weeks (defined in teach-config.yml) generate separate slides."
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach slides --week 1                     # Convert Week 1 lecture(s)"
            echo "  teach slides --week 1 --dry-run           # Preview what would be generated"
            echo "  teach slides --from-lecture lectures/week-01_intro.qmd  # Specific file"
            echo "  teach slides \"Multiple Regression\"        # Generate from topic (Scholar)"
            echo "  teach slides \"GLMs\" --theme minimal       # With theme"
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
    local with_templates=false

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
            --with-templates)
                with_templates=true
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

    # Initialize templates if requested (v5.20.0 - Template Support #301)
    if [[ "$with_templates" == "true" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[info]}Setting up templates...${FLOW_COLORS[reset]}"

        # Create template directories
        local template_dir
        template_dir=$(_teach_create_template_dirs)

        # Count templates synced
        local content_count=0
        local prompts_count=0

        # Sync templates from plugin
        local plugin_dir="$(_template_get_plugin_dir)"

        # Sync prompts (from claude-prompts/)
        if [[ -d "$plugin_dir/claude-prompts" ]]; then
            for tmpl in "$plugin_dir/claude-prompts"/*.md(.N); do
                cp "$tmpl" "$template_dir/prompts/"
                ((prompts_count++))
            done
        fi

        # Sync content templates (from .template files)
        for tmpl in "$plugin_dir"/*.template(.N); do
            local name="${${tmpl:t}%.template}.qmd"
            cp "$tmpl" "$template_dir/content/$name"
            ((content_count++))
        done

        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/content/ ($content_count templates)"
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/prompts/ ($prompts_count templates)"
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/metadata/"
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Created .flow/templates/checklists/"
    fi

    echo ""
    echo "${FLOW_COLORS[success]}✅ Teaching project initialized!${FLOW_COLORS[reset]}"
    echo ""
    echo "  Next steps:"
    echo "    1. Review config: teach config"
    echo "    2. Check environment: teach doctor"
    if [[ "$with_templates" == "true" ]]; then
        echo "    3. List templates: teach templates list"
        echo "    4. Create content: teach templates new lecture week-01"
    else
        echo "    3. Generate content: teach exam \"Topic\""
    fi
    echo ""
}

# Help for teach config
_teach_config_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach config${FLOW_COLORS[reset]} - Edit Course Configuration            ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach config${FLOW_COLORS[reset]} [options]

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}c${FLOW_COLORS[reset]} → config

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Opens ${FLOW_COLORS[accent]}.flow/teach-config.yml${FLOW_COLORS[reset]} in your default editor for editing.
  The file is created by ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} if it doesn't exist.

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--help, -h${FLOW_COLORS[reset]}          Show this help message
  ${FLOW_COLORS[cmd]}--edit${FLOW_COLORS[reset]}              Open in editor (default behavior)
  ${FLOW_COLORS[cmd]}--view${FLOW_COLORS[reset]}              View config without opening editor
  ${FLOW_COLORS[cmd]}--cat${FLOW_COLORS[reset]}               Print to stdout

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Edit config in default editor${FLOW_COLORS[reset]}
  $ teach config

  ${FLOW_COLORS[muted]}# View without editing${FLOW_COLORS[reset]}
  $ teach config --view

  ${FLOW_COLORS[muted]}# Print to terminal${FLOW_COLORS[reset]}
  $ teach config --cat

${FLOW_COLORS[bold]}CONFIG SECTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}course${FLOW_COLORS[reset]}         Course name, semester, year
  ${FLOW_COLORS[accent]}git${FLOW_COLORS[reset]}            Branch names, auto-commit settings
  ${FLOW_COLORS[accent]}scholar${FLOW_COLORS[reset]}        Default Scholar settings
  ${FLOW_COLORS[accent]}backup${FLOW_COLORS[reset]}         Retention policies
  ${FLOW_COLORS[accent]}deploy${FLOW_COLORS[reset]}         Deployment settings

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Set ${FLOW_COLORS[accent]}EDITOR${FLOW_COLORS[reset]} env var to prefer specific editor
  • Use ${FLOW_COLORS[cmd]}yq${FLOW_COLORS[reset]} for CLI editing: yq eval '.course.name = "STAT 440"' -i
  • Run ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} after editing to validate

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} - Initialize teaching project
  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} - Health checks

EOF
}

_teach_config_edit() {
    local config_file=".flow/teach-config.yml"
    if [[ -f "$config_file" ]]; then
        ${EDITOR:-code} "$config_file"
    else
        _teach_error "No teach-config.yml found" "Run 'teach init' first"
        return 1
    fi
}

_teach_config_view() {
    local config_file=".flow/teach-config.yml"
    if [[ -f "$config_file" ]]; then
        echo "${FLOW_COLORS[info]}=== .flow/teach-config.yml ===${FLOW_COLORS[reset]}"
        cat "$config_file"
    else
        _teach_error "No teach-config.yml found" "Run 'teach init' first"
        return 1
    fi
}

_teach_config_cat() {
    local config_file=".flow/teach-config.yml"
    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        _teach_error "No teach-config.yml found" "Run 'teach init' first"
        return 1
    fi
}

# Help for teach init
_teach_init_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} - Initialize Teaching Project                ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} [course_name] [options]
  ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} --config <file>
  ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} --github

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}i${FLOW_COLORS[reset]} → init

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--config FILE${FLOW_COLORS[reset]}       Load configuration from external file
  ${FLOW_COLORS[cmd]}--github${FLOW_COLORS[reset]}            Create GitHub repository (requires gh CLI)
  ${FLOW_COLORS[cmd]}--with-templates${FLOW_COLORS[reset]}    Initialize .flow/templates/ with defaults
  ${FLOW_COLORS[cmd]}--help, -h${FLOW_COLORS[reset]}          Show this help message

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Creates ${FLOW_COLORS[accent]}.flow/teach-config.yml${FLOW_COLORS[reset]} with default settings for:
    • Course information (name, semester, year)
    • Git workflow (draft/production branches)
    • Teaching mode settings (auto-commit, auto-push)
    • Backup retention policies
    • Template directories (with --with-templates)

${FLOW_COLORS[bold]}INTERACTIVE SETUP${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]}          # Interactive prompts for all settings
  ${FLOW_COLORS[cmd]}teach init "STAT 440"${FLOW_COLORS[reset]}  # Pre-fill course name, prompt rest

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Interactive setup${FLOW_COLORS[reset]}
  $ teach init

  ${FLOW_COLORS[muted]}# With course name${FLOW_COLORS[reset]}
  $ teach init "STAT 545"

  ${FLOW_COLORS[muted]}# Load external config${FLOW_COLORS[reset]}
  $ teach init --config ./my-config.yml

  ${FLOW_COLORS[muted]}# Create GitHub repo${FLOW_COLORS[reset]}
  $ teach init "STAT 545" --github

  ${FLOW_COLORS[muted]}# Initialize with templates${FLOW_COLORS[reset]}
  $ teach init "STAT 545" --with-templates

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}.flow/teach-config.yml${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}.teach/lesson-plan.yml${FLOW_COLORS[reset]} (optional template)
  Creates: ${FLOW_COLORS[accent]}.flow/templates/${FLOW_COLORS[reset]} (with --with-templates)

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Run ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} after init to verify setup
  • Use ${FLOW_COLORS[cmd]}teach config${FLOW_COLORS[reset]} to edit settings later
  • Configure ${FLOW_COLORS[accent]}.teach/lesson-plan.yml${FLOW_COLORS[reset]} for customized Scholar output

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📚 Tutorial: docs/tutorials/TEACHING-QUICK-START.md
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach config${FLOW_COLORS[reset]} - Edit course configuration
  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} - Health checks

EOF
}

# ============================================================================
# HELP FOR TEACH ANALYZE COMMAND
# ============================================================================

_teach_analyze_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach analyze${FLOW_COLORS[reset]} - Intelligent Content Analysis              ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach analyze${FLOW_COLORS[reset]} <file>

${FLOW_COLORS[success]}🔥 QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach analyze lectures/week-05-regression.qmd
  ${FLOW_COLORS[dim]}# Validates concepts and prerequisites${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}WHAT IT DOES${FLOW_COLORS[reset]}
  1. Extracts concepts from frontmatter (concepts: field)
  2. Builds concept graph across all lectures
  3. Validates prerequisite ordering (earlier weeks only)
  4. Reports violations with suggestions
  5. (--ai) AI-powered concept enhancement via Claude

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--mode${FLOW_COLORS[reset]} strict|moderate|relaxed   Strictness level
  ${FLOW_COLORS[cmd]}--report${FLOW_COLORS[reset]} [FILE]                  Generate report
  ${FLOW_COLORS[cmd]}--format${FLOW_COLORS[reset]} markdown|json            Report format
  ${FLOW_COLORS[cmd]}--interactive${FLOW_COLORS[reset]}, -i                 Guided interactive mode
  ${FLOW_COLORS[cmd]}--ai${FLOW_COLORS[reset]}                             AI-powered analysis (Phase 3)
  ${FLOW_COLORS[cmd]}--costs${FLOW_COLORS[reset]}                          Show AI usage costs
  ${FLOW_COLORS[cmd]}--slide-breaks${FLOW_COLORS[reset]}                   Analyze slide structure (Phase 4)
  ${FLOW_COLORS[cmd]}--preview-breaks${FLOW_COLORS[reset]}                 Show slide break preview (then exit)

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[info]}Basic analysis:${FLOW_COLORS[reset]}
    ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach analyze lectures/week-05-regression.qmd
    ${FLOW_COLORS[dim]}# Checks prerequisites for Week 5${FLOW_COLORS[reset]}

  ${FLOW_COLORS[info]}AI-powered:${FLOW_COLORS[reset]}
    ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach analyze --ai lectures/week-05-regression.qmd
    ${FLOW_COLORS[dim]}# Adds bloom levels, cognitive load, related concepts${FLOW_COLORS[reset]}

  ${FLOW_COLORS[info]}Slide optimization:${FLOW_COLORS[reset]}
    ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach analyze --slide-breaks lectures/week-05-regression.qmd
    ${FLOW_COLORS[dim]}# Suggests optimal slide structure, key concepts${FLOW_COLORS[reset]}

  ${FLOW_COLORS[info]}What gets checked:${FLOW_COLORS[reset]}
    • Concepts are defined in frontmatter
    • Prerequisites exist in earlier weeks
    • No future-week dependencies
    • (--ai) Bloom level, cognitive load, relationships

${FLOW_COLORS[info]}💡 TIPS${FLOW_COLORS[reset]}
  • Add ${FLOW_COLORS[cmd]}concepts:${FLOW_COLORS[reset]} field to lecture frontmatter
  • Use concept IDs consistently across lectures
  • Run before deployment to catch ordering issues
  • Use ${FLOW_COLORS[cmd]}--ai${FLOW_COLORS[reset]} for deeper analysis (requires Claude CLI)

${FLOW_COLORS[bold]}FRONTMATTER EXAMPLE${FLOW_COLORS[reset]}
  ---
  title: "Linear Regression"
  week: 5
  concepts:
    introduces:
      - id: simple-regression
      - id: r-squared
    requires:
      - correlation  # From Week 3
      - variance     # From Week 1
  ---

${FLOW_COLORS[dim]}📚 See also:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach validate${FLOW_COLORS[reset]}   Run quality checks
  ${FLOW_COLORS[dim]}docs/guides/INTELLIGENT-CONTENT-ANALYSIS.md${FLOW_COLORS[reset]}
EOF
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
  ${FLOW_COLORS[cmd]} teach lecture <topic> [options]
  ${FLOW_COLORS[cmd]} teach lecture --week N --topic "title"

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}lec${FLOW_COLORS[reset]} → lecture

${FLOW_COLORS[bold]}REQUIRED FILES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}.flow/teach-config.yml${FLOW_COLORS[reset]}      Course metadata (required)
  ${FLOW_COLORS[accent]}.teach/lesson-plan.yml${FLOW_COLORS[reset]} Content preferences (optional, improves output)
  Run ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} to verify configuration

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

${FLOW_COLORS[bold]}TROUBLESHOOTING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[error]}"YAML parse error"${FLOW_COLORS[reset]}
    → Run: teach validate --yaml <file>
    → Check: .flow/teach-config.yml syntax

  ${FLOW_COLORS[error]}"Scholar API timeout"${FLOW_COLORS[reset]}
    → Check connection: teach doctor --check scholar
    → Retry with: teach lecture "topic" --retry

  ${FLOW_COLORS[error]}"File not staged"${FLOW_COLORS[reset]}
    → Manual stage: git add lectures/week-NN/

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

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
  ${FLOW_COLORS[cmd]} teach doctor [options]
  ${FLOW_COLORS[cmd]} teach doctor --fix          # Auto-fix issues
  ${FLOW_COLORS[cmd]} teach doctor --json         # CI/CD output

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}doc${FLOW_COLORS[reset]} → doctor

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

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

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
  ${FLOW_COLORS[cmd]} teach deploy [files...] [options]
  ${FLOW_COLORS[cmd]} teach deploy --preview      # Preview changes only
  ${FLOW_COLORS[cmd]} teach deploy --auto-commit  # Auto-commit changes

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}d${FLOW_COLORS[reset]} → deploy

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

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup${FLOW_COLORS[reset]} - Create restore point
  ${FLOW_COLORS[cmd]}qu${FLOW_COLORS[reset]} - Quarto commands
  ${FLOW_COLORS[cmd]}g${FLOW_COLORS[reset]} - Git commands

EOF
}

_teach_slides_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach slides${FLOW_COLORS[reset]} - Generate Presentation Slides            ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach slides <topic> [options]
  ${FLOW_COLORS[cmd]}teach slides --week N --topic "title"

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}sl${FLOW_COLORS[reset]} → slides

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate slides for this week${FLOW_COLORS[reset]}
  $ teach slides "Linear Regression" --week 5

  ${FLOW_COLORS[muted]}# Create with Quarto revealjs (recommended)${FLOW_COLORS[reset]}
  $ teach slides "ANOVA" --template quarto --week 6

  ${FLOW_COLORS[muted]}# Customized slides with theme${FLOW_COLORS[reset]}
  $ teach slides "ML Intro" --template quarto --theme academic --difficulty medium

${FLOW_COLORS[bold]}TOPIC SELECTION${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}<topic>${FLOW_COLORS[reset]}                  Slides topic or title
  ${FLOW_COLORS[cmd]}--week N, -w N${FLOW_COLORS[reset]}           Week number (for file naming)
  ${FLOW_COLORS[cmd]}--topic "text", -t${FLOW_COLORS[reset]}       Override topic in prompts

${FLOW_COLORS[bold]}TEMPLATE OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--template FORMAT${FLOW_COLORS[reset]}        markdown | quarto
  ${FLOW_COLORS[cmd]}--theme NAME${FLOW_COLORS[reset]}             default | academic | minimal

${FLOW_COLORS[bold]}CONTENT FLAGS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--explanation, -e${FLOW_COLORS[reset]}           Include detailed explanations
  ${FLOW_COLORS[cmd]}--no-explanation${FLOW_COLORS[reset]}             Skip detailed explanations
  ${FLOW_COLORS[cmd]}--math, -m${FLOW_COLORS[reset]}                  Include math notation
  ${FLOW_COLORS[cmd]}--code, -c${FLOW_COLORS[reset]}                  Include code examples
  ${FLOW_COLORS[cmd]}--diagrams, -d${FLOW_COLORS[reset]}              Include diagrams

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic slides generation${FLOW_COLORS[reset]}
  $ teach slides "Multiple Regression"

  ${FLOW_COLORS[muted]}# Week-based with consistent naming${FLOW_COLORS[reset]}
  $ teach slides "Logistic Regression" --week 8

  ${FLOW_COLORS[muted]}# Full-featured slides${FLOW_COLORS[reset]}
  $ teach slides "Neural Networks" --week 10 --template quarto --theme academic --difficulty hard --math --code

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}slides/week-NN/slides-NN-<topic>.${FLOW_COLORS[reset]}
  Auto-backs up existing files before overwriting

${FLOW_COLORS[bold]}FROM-LECTURE MODE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--from-lecture FILE${FLOW_COLORS[reset]}     Convert lecture .qmd to slides
  ${FLOW_COLORS[cmd]}--week N${FLOW_COLORS[reset]}                 Auto-detect lecture files for week

${FLOW_COLORS[bold]}OPTIMIZATION FLAGS (Phase 4)${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--optimize${FLOW_COLORS[reset]}               AI-powered slide structure analysis
  ${FLOW_COLORS[cmd]}--preview-breaks${FLOW_COLORS[reset]}         Show suggested breaks before generating
  ${FLOW_COLORS[cmd]}--apply-suggestions${FLOW_COLORS[reset]}      Auto-apply slide break suggestions
  ${FLOW_COLORS[cmd]}--key-concepts${FLOW_COLORS[reset]}           Emphasize key concepts with callouts

  ${FLOW_COLORS[muted]}# Convert lecture to optimized slides${FLOW_COLORS[reset]}
  $ teach slides --from-lecture week-05.qmd --optimize
  $ teach slides --week 5 --optimize --preview-breaks
  $ teach slides --week 5 --optimize --apply-suggestions

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}--template quarto${FLOW_COLORS[reset]} for revealjs slides
  • Use ${FLOW_COLORS[accent]}--theme academic${FLOW_COLORS[reset]} for professional look
  • Use ${FLOW_COLORS[accent]}--optimize${FLOW_COLORS[reset]} for AI-powered slide structure
  • Preview with ${FLOW_COLORS[cmd]}quarto preview${FLOW_COLORS[reset]}
  • Auto-staged for git after generation

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach lecture${FLOW_COLORS[reset]} - Lecture notes
  ${FLOW_COLORS[cmd]}teach analyze --slide-breaks${FLOW_COLORS[reset]} - Slide optimization analysis
  ${FLOW_COLORS[cmd]}teach quiz${FLOW_COLORS[reset]} - Quiz questions

EOF
}

_teach_exam_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach exam${FLOW_COLORS[reset]} - Generate Exam Questions               ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach exam <topic> [options]
  ${FLOW_COLORS[cmd]}teach exam --questions N --duration minutes

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}e${FLOW_COLORS[reset]} → exam

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate exam on topic${FLOW_COLORS[reset]}
  $ teach exam "Linear Regression"

  ${FLOW_COLORS[muted]}# Specific number of questions${FLOW_COLORS[reset]}
  $ teach exam "Hypothesis Testing" --questions 10

  ${FLOW_COLORS[muted]}# With time limit and question types${FLOW_COLORS[reset]}
  $ teach exam "ANOVA" --questions 8 --duration 60 --types "short answer:5,problem:3"

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--questions N${FLOW_COLORS[reset]}            Number of questions (default: 5)
  ${FLOW_COLORS[cmd]}--duration N${FLOW_COLORS[reset]}             Duration in minutes
  ${FLOW_COLORS[cmd]}--types TYPES${FLOW_COLORS[reset]}            Question type breakdown
  ${FLOW_COLORS[cmd]}--format FORMAT${FLOW_COLORS[reset]}          quarto | qti | markdown
  ${FLOW_COLORS[cmd]}--difficulty easy|medium|hard${FLOW_COLORS[reset]}  Content depth

${FLOW_COLORS[bold]}CONTENT FLAGS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--explanation, -e${FLOW_COLORS[reset]}           Include answer explanations
  ${FLOW_COLORS[cmd]}--math, -m${FLOW_COLORS[reset]}                  Include math notation
  ${FLOW_COLORS[cmd]}--code, -c${FLOW_COLORS[reset]}                  Include code problems

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic exam generation${FLOW_COLORS[reset]}
  $ teach exam "Multiple Regression"

  ${FLOW_COLORS[muted]}# Detailed exam with explanations${FLOW_COLORS[reset]}
  $ teach exam "Logistic Regression" --questions 10 --explanation --math

  ${FLOW_COLORS[muted]}# Quiz-style format${FLOW_COLORS[reset]}
  $ teach exam "Basics Review" --questions 20 --duration 30 --format qti

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}exams/exam-<topic>-YYYY-MM-DD.${FLOW_COLORS[reset]}
  Auto-backs up existing files before overwriting

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}--types${FLOW_COLORS[reset]} to control question mix
  • Preview with ${FLOW_COLORS[cmd]}--format markdown${FLOW_COLORS[reset]} first
  • Auto-staged for git after generation

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach quiz${FLOW_COLORS[reset]} - Quiz questions
  ${FLOW_COLORS[cmd]}teach rubric${FLOW_COLORS[reset]} - Grading rubric

EOF
}

_teach_quiz_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach quiz${FLOW_COLORS[reset]} - Generate Quiz Questions                  ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach quiz <topic> [options]
  ${FLOW_COLORS[cmd]}teach quiz --questions N --time-limit minutes

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}q${FLOW_COLORS[reset]} → quiz

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate quiz on topic${FLOW_COLORS[reset]}
  $ teach quiz "Linear Regression"

  ${FLOW_COLORS[muted]}# Specific number of questions${FLOW_COLORS[reset]}
  $ teach quiz "Hypothesis Testing" --questions 10

  ${FLOW_COLORS[muted]}# Timed quiz${FLOW_COLORS[reset]}
  $ teach quiz "ANOVA" --questions 5 --time-limit 15

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--questions N${FLOW_COLORS[reset]}            Number of questions (default: 5)
  ${FLOW_COLORS[cmd]}--time-limit N${FLOW_COLORS[reset]}           Time limit in minutes
  ${FLOW_COLORS[cmd]}--format FORMAT${FLOW_COLORS[reset]}          quarto | qti | markdown
  ${FLOW_COLORS[cmd]}--difficulty easy|medium|hard${FLOW_COLORS[reset]}  Content depth

${FLOW_COLORS[bold]}CONTENT FLAGS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--explanation, -e${FLOW_COLORS[reset]}           Include answer explanations
  ${FLOW_COLORS[cmd]}--math, -m${FLOW_COLORS[reset]}                  Include math notation
  ${FLOW_COLORS[cmd]}--code, -c${FLOW_COLORS[reset]}                  Include code questions

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic quiz generation${FLOW_COLORS[reset]}
  $ teach quiz "Multiple Regression"

  ${FLOW_COLORS[muted]}# Quick check quiz${FLOW_COLORS[reset]}
  $ teach quiz "Logistic Regression" --questions 5 --time-limit 10

  ${FLOW_COLORS[muted]}# Detailed quiz with explanations${FLOW_COLORS[reset]}
  $ teach quiz "ANOVA" --questions 10 --explanation --math

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}quizzes/quiz-<topic>-YYYY-MM-DD.${FLOW_COLORS[reset]}
  Auto-backs up existing files before overwriting

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}--time-limit${FLOW_COLORS[reset]} for practice quizzes
  • Preview with ${FLOW_COLORS[cmd]}--format markdown${FLOW_COLORS[reset]} first
  • Auto-staged for git after generation

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach exam${FLOW_COLORS[reset]} - Exam questions
  ${FLOW_COLORS[cmd]}teach assignment${FLOW_COLORS[reset]} - Homework assignments

EOF
}

_teach_assignment_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach assignment${FLOW_COLORS[reset]} - Generate Homework Assignment        ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach assignment <topic> [options]
  ${FLOW_COLORS[cmd]}teach assignment --due-date "YYYY-MM-DD" --points N

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}hw${FLOW_COLORS[reset]} → assignment

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate assignment on topic${FLOW_COLORS[reset]}
  $ teach assignment "Linear Regression"

  ${FLOW_COLORS[muted]}# Assignment with due date${FLOW_COLORS[reset]}
  $ teach assignment "ANOVA" --due-date "2024-02-15" --points 100

  ${FLOW_COLORS[muted]}# Detailed assignment${FLOW_COLORS[reset]}
  $ teach assignment "ML Intro" --due-date "2024-02-20" --points 50 --explanation

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--due-date DATE${FLOW_COLORS[reset]}          Due date (YYYY-MM-DD or "Week N")
  ${FLOW_COLORS[cmd]}--points N${FLOW_COLORS[reset]}               Total points
  ${FLOW_COLORS[cmd]}--format FORMAT${FLOW_COLORS[reset]}          quarto | markdown
  ${FLOW_COLORS[cmd]}--difficulty easy|medium|hard${FLOW_COLORS[reset]}  Content depth

${FLOW_COLORS[bold]}CONTENT FLAGS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--explanation, -e${FLOW_COLORS[reset]}           Include solution explanations
  ${FLOW_COLORS[cmd]}--math, -m${FLOW_COLORS[reset]}                  Include math problems
  ${FLOW_COLORS[cmd]}--code, -c${FLOW_COLORS[reset]}                  Include programming problems
  ${FLOW_COLORS[cmd]}--practice-problems, -p${FLOW_COLORS[reset]}     Include practice problems

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic assignment generation${FLOW_COLORS[reset]}
  $ teach assignment "Multiple Regression"

  ${FLOW_COLORS[muted]}# Complete assignment with due date${FLOW_COLORS[reset]}
  $ teach assignment "Logistic Regression" --due-date "2024-02-15" --points 100

  ${FLOW_COLORS[muted]}# Programming-focused assignment${FLOW_COLORS[reset]}
  $ teach assignment "Data Wrangling" --code --practice-problems --points 50

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}assignments/assignment-<topic>-YYYY-MM-DD.${FLOW_COLORS[reset]}
  Auto-backs up existing files before overwriting

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}--due-date${FLOW_COLORS[reset]} for semester planning
  • Preview with ${FLOW_COLORS[cmd]}--format markdown${FLOW_COLORS[reset]} first
  • Auto-staged for git after generation

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach rubric${FLOW_COLORS[reset]} - Grading rubric
  ${FLOW_COLORS[cmd]}teach feedback${FLOW_COLORS[reset]} - Student feedback

EOF
}

_teach_syllabus_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach syllabus${FLOW_COLORS[reset]} - Generate Course Syllabus             ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach syllabus [course_name] [options]
  ${FLOW_COLORS[cmd]}teach syllabus --format quarto

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}syl${FLOW_COLORS[reset]} → syllabus

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate syllabus from config${FLOW_COLORS[reset]}
  $ teach syllabus

  ${FLOW_COLORS[muted]}# Generate for specific course${FLOW_COLORS[reset]}
  $ teach syllabus "STAT 440"

  ${FLOW_COLORS[muted]}# PDF format${FLOW_COLORS[reset]}
  $ teach syllabus --format pdf

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--format FORMAT${FLOW_COLORS[reset]}          quarto | markdown | pdf
  ${FLOW_COLORS[cmd]}--template TYPE${FLOW_COLORS[reset]}          default | detailed

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic syllabus generation${FLOW_COLORS[reset]}
  $ teach syllabus

  ${FLOW_COLORS[muted]}# With course name${FLOW_COLORS[reset]}
  $ teach syllabus "STAT 545"

  ${FLOW_COLORS[muted]}# PDF format for printing${FLOW_COLORS[reset]}
  $ teach syllabus --format pdf

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}syllabus.md${FLOW_COLORS[reset]} or ${FLOW_COLORS[accent]}syllabus.pdf${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Uses course info from ${FLOW_COLORS[accent]}.flow/teach-config.yml${FLOW_COLORS[reset]}
  • Run ${FLOW_COLORS[cmd]}teach init${FLOW_COLORS[reset]} first to set up config
  • Preview with ${FLOW_COLORS[cmd]}quarto preview syllabus.${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach config${FLOW_COLORS[reset]} - Edit course configuration
  ${FLOW_COLORS[cmd]}teach dates${FLOW_COLORS[reset]} - Date management

EOF
}

_teach_rubric_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach rubric${FLOW_COLORS[reset]} - Generate Grading Rubric               ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach rubric <assignment_name> [options]
  ${FLOW_COLORS[cmd]}teach rubric --criteria N

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}rb${FLOW_COLORS[reset]} → rubric

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate rubric for assignment${FLOW_COLORS[reset]}
  $ teach rubric "Final Project"

  ${FLOW_COLORS[muted]}# Rubric with specific criteria${FLOW_COLORS[reset]}
  $ teach rubric "Lab Report" --criteria 4

  ${FLOW_COLORS[muted]}# Week-based rubric${FLOW_COLORS[reset]}
  $ teach rubric "Homework 5" --week 10

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--criteria N${FLOW_COLORS[reset]}             Number of criteria (default: 4)
  ${FLOW_COLORS[cmd]}--format FORMAT${FLOW_COLORS[reset]}          quarto | markdown
  ${FLOW_COLORS[cmd]}--week N${FLOW_COLORS[reset]}                 Week number (for lesson plan)

${FLOW_COLORS[bold]}CONTENT FLAGS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--explanation, -e${FLOW_COLORS[reset]}           Include grading explanations

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic rubric generation${FLOW_COLORS[reset]}
  $ teach rubric "Final Project"

  ${FLOW_COLORS[muted]}# Custom criteria count${FLOW_COLORS[reset]}
  $ teach rubric "Lab Report" --criteria 5

  ${FLOW_COLORS[muted]}# Detailed rubric${FLOW_COLORS[reset]}
  $ teach rubric "Research Paper" --criteria 6 --explanation

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}rubrics/rubric-<assignment_name>-YYYY-MM-DD.${FLOW_COLORS[reset]}
  Auto-backs up existing files before overwriting

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}--criteria${FLOW_COLORS[reset]} to control rubric detail
  • Preview with ${FLOW_COLORS[cmd]}--format markdown${FLOW_COLORS[reset]} first
  • Auto-staged for git after generation

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach assignment${FLOW_COLORS[reset]} - Generate assignment
  ${FLOW_COLORS[cmd]}teach feedback${FLOW_COLORS[reset]} - Student feedback

EOF
}

_teach_feedback_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach feedback${FLOW_COLORS[reset]} - Generate Student Feedback            ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach feedback <student_work> [options]
  ${FLOW_COLORS[cmd]}teach feedback "homework3-smith.pdf"

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}fb${FLOW_COLORS[reset]} → feedback

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Generate feedback on student work${FLOW_COLORS[reset]}
  $ teach feedback "homework3-smith.pdf"

  ${FLOW_COLORS[muted]}# Supportive tone feedback${FLOW_COLORS[reset]}
  $ teach feedback "project.R" --tone supportive

  ${FLOW_COLORS[muted]}# Detailed feedback${FLOW_COLORS[reset]}
  $ teach feedback "essay.docx" --tone detailed

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--tone TONE${FLOW_COLORS[reset]}              supportive | direct | detailed
  ${FLOW_COLORS[cmd]}--format FORMAT${FLOW_COLORS[reset]}          markdown | text

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic feedback generation${FLOW_COLORS[reset]}
  $ teach feedback "homework3-smith.pdf"

  ${FLOW_COLORS[muted]}# Supportive tone${FLOW_COLORS[reset]}
  $ teach feedback "project.R" --tone supportive

  ${FLOW_COLORS[muted]}# Detailed feedback${FLOW_COLORS[reset]}
  $ teach feedback "essay.docx" --tone detailed --format markdown

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}feedback/feedback-<student_work>-YYYY-MM-DD.${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}--tone${FLOW_COLORS[reset]} to match feedback style
  • Supports PDF, DOCX, R, MD files
  • Preview with ${FLOW_COLORS[cmd]}--format text${FLOW_COLORS[reset]} first

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach rubric${FLOW_COLORS[reset]} - Grading rubric
  ${FLOW_COLORS[cmd]}teach assignment${FLOW_COLORS[reset]} - Generate assignment

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

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md

EOF
}

_teach_dispatcher_help() {
    # Color fallbacks
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
${_C_BOLD}│ teach - Teaching Workflow Commands            │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach lecture${_C_NC} <topic>     Generate lecture notes
  ${_C_CYAN}teach deploy${_C_NC}              Deploy course website
  ${_C_CYAN}teach validate${_C_NC} --render   Full validation
  ${_C_CYAN}teach status${_C_NC}              Project dashboard
  ${_C_CYAN}teach doctor${_C_NC} --fix        Fix dependency issues

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach init \"STAT 440\"           ${_C_DIM}# Initialize project${_C_NC}
  ${_C_DIM}\$${_C_NC} teach lecture \"Intro\" --week 1  ${_C_DIM}# Create lecture${_C_NC}
  ${_C_DIM}\$${_C_NC} teach validate --render           ${_C_DIM}# Full validation${_C_NC}
  ${_C_DIM}\$${_C_NC} teach deploy --preview            ${_C_DIM}# Preview deploy${_C_NC}

${_C_BLUE}📋 SETUP & CONFIGURATION${_C_NC}:
  ${_C_CYAN}teach init${_C_NC} [name]         Initialize teaching project
  ${_C_CYAN}teach config${_C_NC}              Edit configuration
  ${_C_CYAN}teach doctor${_C_NC}              Health checks (--fix to auto-fix)
  ${_C_CYAN}teach hooks${_C_NC}               Git hook management
  ${_C_CYAN}teach dates${_C_NC}               Date management
  ${_C_CYAN}teach plan${_C_NC}                Lesson plan CRUD
  ${_C_CYAN}teach templates${_C_NC}           Template management
  ${_C_CYAN}teach macros${_C_NC}              LaTeX macro management
  ${_C_CYAN}teach prompt${_C_NC}              AI prompt management
  ${_C_CYAN}teach migrate-config${_C_NC}      Extract lesson plans

${_C_BLUE}📋 CONTENT CREATION${_C_NC} ${_C_DIM}(Scholar AI)${_C_NC}:
  ${_C_CYAN}teach lecture${_C_NC} <topic>     Generate lecture notes
  ${_C_CYAN}teach slides${_C_NC} <topic>      Presentation slides
  ${_C_CYAN}teach exam${_C_NC} <topic>        Comprehensive exam
  ${_C_CYAN}teach quiz${_C_NC} <topic>        Quiz questions
  ${_C_CYAN}teach assignment${_C_NC} <topic>  Homework assignment
  ${_C_CYAN}teach syllabus${_C_NC} <course>   Course syllabus
  ${_C_CYAN}teach rubric${_C_NC} <assign>     Grading rubric
  ${_C_CYAN}teach feedback${_C_NC} <work>     Student feedback

${_C_BLUE}📋 VALIDATION & QUALITY${_C_NC}:
  ${_C_CYAN}teach analyze${_C_NC} <file>      Validate prerequisites
  ${_C_CYAN}teach validate${_C_NC} [files]    Validate .qmd files
  ${_C_CYAN}teach profiles${_C_NC}            Profile management
  ${_C_CYAN}teach cache${_C_NC}               Cache operations
  ${_C_CYAN}teach clean${_C_NC}               Delete _freeze/ + _site/

${_C_BLUE}📋 DEPLOYMENT & MANAGEMENT${_C_NC}:
  ${_C_CYAN}teach deploy${_C_NC} [files]      Deploy course website
  ${_C_CYAN}teach status${_C_NC}              Project dashboard
  ${_C_CYAN}teach week${_C_NC}                Current week info
  ${_C_CYAN}teach backup${_C_NC}              Backup management
  ${_C_CYAN}teach archive${_C_NC}             Archive semester

${_C_MAGENTA}💡 TIP${_C_NC}: Content generation requires Scholar plugin
  ${_C_DIM}teach lecture → scholar:teaching:lecture (AI-powered)${_C_NC}
  ${_C_DIM}Shortcuts: i=init lec=lecture e=exam d=deploy s=status${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}qu${_C_NC} - Quarto commands (qu preview, qu render)
  ${_C_CYAN}g${_C_NC} - Git commands (g status, g push)
  ${_C_CYAN}work${_C_NC} - Session management
"
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
            case "$1" in
                --help|-h|help) _teach_slides_help; return 0 ;;
                *) _teach_scholar_wrapper "slides" "$@" ;;
            esac
            ;;

        exam|e)
            case "$1" in
                --help|-h|help) _teach_exam_help; return 0 ;;
                *) _teach_scholar_wrapper "exam" "$@" ;;
            esac
            ;;

        quiz|q)
            case "$1" in
                --help|-h|help) _teach_quiz_help; return 0 ;;
                *) _teach_scholar_wrapper "quiz" "$@" ;;
            esac
            ;;

        assignment|hw)
            case "$1" in
                --help|-h|help) _teach_assignment_help; return 0 ;;
                *) _teach_scholar_wrapper "assignment" "$@" ;;
            esac
            ;;

        syllabus|syl)
            case "$1" in
                --help|-h|help) _teach_syllabus_help; return 0 ;;
                *) _teach_scholar_wrapper "syllabus" "$@" ;;
            esac
            ;;

        rubric|rb)
            case "$1" in
                --help|-h|help) _teach_rubric_help; return 0 ;;
                *) _teach_scholar_wrapper "rubric" "$@" ;;
            esac
            ;;

        feedback|fb)
            case "$1" in
                --help|-h|help) _teach_feedback_help; return 0 ;;
                *) _teach_scholar_wrapper "feedback" "$@" ;;
            esac
            ;;

        demo)
            _teach_scholar_wrapper "demo" "$@"
            ;;

        # ============================================
        # LOCAL COMMANDS (no Claude needed)
        # ============================================
        init|i)
            case "$1" in
                --help|-h|help) _teach_init_help; return 0 ;;
                *) _teach_init "$@" ;;
            esac
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
            case "$1" in
                --help|-h|help) _teach_config_help; return 0 ;;
                --view) _teach_config_view "$@" ;;
                --cat) _teach_config_cat "$@" ;;
                *) _teach_config_edit "$@" ;;
            esac
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

        # Lesson plan management (v5.22.0 - Issue #278)
        plan|pl)
            case "$1" in
                --help|-h|help) _teach_plan_help; return 0 ;;
                *) _teach_plan "$@" ;;
            esac
            ;;

        # Migration (v5.20.0 - Lesson Plan Extraction #298)
        migrate-config|migrate)
            case "$1" in
                --help|-h|help) _teach_migrate_help; return 0 ;;
                *) _teach_migrate_config "$@" ;;
            esac
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
            case "$1" in
                --help|-h|help) _teach_validate_help; return 0 ;;
                *) teach-validate "$@" ;;
            esac
            ;;

        # Concept analysis (Phase 0: teach analyze)
        analyze|concept|concepts)
            case "$1" in
                --help|-h|help)
                    _teach_analyze_help
                    return 0
                    ;;
                *)
                    _teach_analyze "$@"
                    ;;
            esac
            ;;

        # Cache management (Week 3-4: Cache Management)
        cache|c)
            case "$1" in
                --help|-h|help) _teach_cache_help; return 0 ;;
                *) teach_cache "$@" ;;
            esac
            ;;

        # Clean command (delete _freeze/ + _site/)
        clean|cl)
            case "$1" in
                --help|-h|help) _teach_clean_help; return 0 ;;
                *) teach_clean "$@" ;;
            esac
            ;;

        # Profile management (Phase 2 - Wave 1: Profile Management)
        profiles|profile|prof)
            case "$1" in
                --help|-h|help) _teach_profiles_help; return 0 ;;
                *) _teach_profiles "$@" ;;
            esac
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

        # Template management (v5.20.0 - Template Support #301)
        templates|tmpl|tpl)
            case "$1" in
                --help|-h|help) _teach_templates_help; return 0 ;;
                *) _teach_templates "$@" ;;
            esac
            ;;

        # LaTeX macro management (v5.21.0 - LaTeX Macro Support)
        macros|macro|m)
            case "$1" in
                --help|-h|help) _teach_macros_help; return 0 ;;
                *) _teach_macros "$@" ;;
            esac
            ;;

        # AI prompt management (v5.23.0 - Prompt Management)
        prompt|pr)
            case "$1" in
                --help|-h|help) _teach_prompt_help; return 0 ;;
                *) _teach_prompt "$@" ;;
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
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} - Create Timestamped Backup         ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} [content_path] [name]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Creates timestamped snapshots of teaching content for recovery.
  Backups are stored in ${FLOW_COLORS[accent]}.backups/${FLOW_COLORS[reset]} with metadata tracking.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}content_path${FLOW_COLORS[reset]}     Path to content (default: current directory)
  ${FLOW_COLORS[cmd]}name${FLOW_COLORS[reset]}             Optional name (auto-timestamped if omitted)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}           JSON output for scripting
  ${FLOW_COLORS[cmd]}--quiet, -q${FLOW_COLORS[reset]}      Minimal output

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Backup current directory (auto timestamp)${FLOW_COLORS[reset]}
  $ teach backup create .

  ${FLOW_COLORS[muted]}# Backup specific lecture${FLOW_COLORS[reset]}
  $ teach backup create lectures/week-01

  ${FLOW_COLORS[muted]}# Backup with custom name${FLOW_COLORS[reset]}
  $ teach backup create . "Before Midterm"

  ${FLOW_COLORS[muted]}# Backup exam folder${FLOW_COLORS[reset]}
  $ teach backup create exams/midterm

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}.backups/<path>.<timestamp>/${FLOW_COLORS[reset]}
  Updates: ${FLOW_COLORS[accent]}.backups/.metadata${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to see all backups
  • Run ${FLOW_COLORS[accent]}teach doctor${FLOW_COLORS[reset]} to verify backup system
  • Backups are incremental (efficient storage)

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  Guide: docs/guides/BACKUP-SYSTEM-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List backups
  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} - Restore from backup
  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} - Delete backup

EOF
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
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List All Backups                 ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} [content_path]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Displays all backups for a content directory with size, file count,
  and timestamp information.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}content_path${FLOW_COLORS[reset]}    Path to content (default: current directory)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}          JSON output for scripting
  ${FLOW_COLORS[cmd]}--short${FLOW_COLORS[reset]}         Compact output (names only)

${FLOW_COLORS[bold]}SORTING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}Default${FLOW_COLORS[reset]}       Newest first (by timestamp)
  ${FLOW_COLORS[accent]}--oldest${FLOW_COLORS[reset]}      Oldest first
  ${FLOW_COLORS[accent]}--size${FLOW_COLORS[reset]}        Largest first

${FLOW_COLORS[bold]}FILTERING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--recent N${FLOW_COLORS[reset]}      Show N most recent backups
  ${FLOW_COLORS[cmd]}--pattern "glob"${FLOW_COLORS[reset]} Filter by name pattern

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# List all backups (current directory)${FLOW_COLORS[reset]}
  $ teach backup list

  ${FLOW_COLORS[muted]}# List backups for specific content${FLOW_COLORS[reset]}
  $ teach backup list lectures/week-01

  ${FLOW_COLORS[muted]}# Show compact output${FLOW_COLORS[reset]}
  $ teach backup list --short

  ${FLOW_COLORS[muted]}# Show only 5 most recent${FLOW_COLORS[reset]}
  $ teach backup list --recent 5

${FLOW_COLORS[bold]}OUTPUT COLUMNS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}Name${FLOW_COLORS[reset]}       Backup identifier with timestamp
  ${FLOW_COLORS[accent]}Size${FLOW_COLORS[reset]}       Total size on disk
  ${FLOW_COLORS[accent]}Files${FLOW_COLORS[reset]}      Number of files in backup
  ${FLOW_COLORS[accent]}Date${FLOW_COLORS[reset]}       Creation timestamp

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}teach backup restore <name>${FLOW_COLORS[reset]} to restore
  • Backup names include timestamps for easy identification
  • Combine with ${FLOW_COLORS[accent]}--json${FLOW_COLORS[reset]} for scripting

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} - Create backup
  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} - Restore from backup

EOF
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
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} - Restore From Backup             ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} <backup_name>

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Restores content from a backup snapshot. Requires confirmation
  before overwriting current content.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}backup_name${FLOW_COLORS[reset]}    Name or partial name of backup to restore
                          (use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to see available backups)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--force${FLOW_COLORS[reset]}        Skip confirmation prompt
  ${FLOW_COLORS[cmd]}--dry-run${FLOW_COLORS[reset]}      Show what would be restored (no changes)

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# First, list available backups${FLOW_COLORS[reset]}
  $ teach backup list

  ${FLOW_COLORS[muted]}# Restore specific backup (with confirmation)${FLOW_COLORS[reset]}
  $ teach backup restore lectures.2026-01-20-1430

  ${FLOW_COLORS[muted]}# Restore without confirmation${FLOW_COLORS[reset]}
  $ teach backup restore lectures.2026-01-20-1430 --force

  ${FLOW_COLORS[muted]}# Preview restore (no changes)${FLOW_COLORS[reset]}
  $ teach backup restore lectures.2026-01-20-1430 --dry-run

${FLOW_COLORS[bold]}WARNING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[error]}⚠ This will OVERWRITE current content!${FLOW_COLORS[reset]}

  Before restoring:
  • Ensure you have a current backup (${FLOW_COLORS[accent]}teach backup create${FLOW_COLORS[reset]})
  • Check what changed (${FLOW_COLORS[accent]}git diff${FLOW_COLORS[reset]})
  • Consider using ${FLOW_COLORS[accent]}--dry-run${FLOW_COLORS[reset]} first

${FLOW_COLORS[bold]}EXIT CODES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}0${FLOW_COLORS[reset]}   Success - backup restored
  ${FLOW_COLORS[accent]}1${FLOW_COLORS[reset]}   Error - backup not found or restore failed
  ${FLOW_COLORS[accent]}2${FLOW_COLORS[reset]}   Cancelled - user declined confirmation

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to find exact backup name
  • Partial names work (e.g., "lectures.2026-01-20")
  • Backups are in ${FLOW_COLORS[accent]}.backups/<path>.<timestamp>/${FLOW_COLORS[reset]}

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List available backups
  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} - Create new backup

EOF
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
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} - Delete Backup                  ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} <backup_name> [options]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Permanently deletes a backup. Use with caution - deleted backups
  cannot be recovered.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}backup_name${FLOW_COLORS[reset]}    Name of backup to delete
                          (use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to see backups)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--force, -f${FLOW_COLORS[reset]}    Skip confirmation prompt
  ${FLOW_COLORS[cmd]}--dry-run${FLOW_COLORS[reset]}      Show what would be deleted (no changes)

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Delete with confirmation (recommended)${FLOW_COLORS[reset]}
  $ teach backup delete lectures.2026-01-20-1430

  ${FLOW_COLORS[muted]}# Force delete (no confirmation)${FLOW_COLORS[reset]}
  $ teach backup delete old-backup --force

  ${FLOW_COLORS[muted]}# Preview deletion${FLOW_COLORS[reset]}
  $ teach backup delete lectures.2026-01-20-1430 --dry-run

${FLOW_COLORS[bold]}CONFIRMATION${FLOW_COLORS[reset]}
  Without ${FLOW_COLORS[cmd]}--force${FLOW_COLORS[reset]}, you will be prompted:

    Delete backup? [y/N]

  Type ${FLOW_COLORS[accent]}y${FLOW_COLORS[reset]} to confirm, ${FLOW_COLORS[accent]}N${FLOW_COLORS[reset]} or ${FLOW_COLORS[accent]}Enter${FLOW_COLORS[reset]} to cancel.

${FLOW_COLORS[bold]}WARNING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[error]}⚠ Deletions are permanent!${FLOW_COLORS[reset]}

  Before deleting:
  • Verify you have other backups or the content is no longer needed
  • Use ${FLOW_COLORS[accent]}--dry-run${FLOW_COLORS[reset]} to preview
  • Consider ${FLOW_COLORS[accent]}teach backup archive${FLOW_COLORS[reset]} for semester-end cleanup

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Partial names work (e.g., "lectures.2026-01")
  • Combine with ${FLOW_COLORS[accent]}teach backup list --recent${FLOW_COLORS[reset]} to find old backups
  • Run ${FLOW_COLORS[accent]}teach doctor${FLOW_COLORS[reset]} to check backup system health

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List backups
  ${FLOW_COLORS[cmd]}teach backup archive${FLOW_COLORS[reset]} - Archive semester backups

EOF
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
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup archive${FLOW_COLORS[reset]} - Archive Semester Backups        ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup archive${FLOW_COLORS[reset]} <semester_name> [options]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Archives backups at the end of a semester based on retention policies.
  Reduces storage while preserving important backups.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}semester_name${FLOW_COLORS[reset]}    Semester identifier (e.g., spring-2026, fall-2025)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--dry-run${FLOW_COLORS[reset]}        Preview actions without making changes
  ${FLOW_COLORS[cmd]}--force${FLOW_COLORS[reset]}          Skip confirmation prompt
  ${FLOW_COLORS[cmd]}--compress${FLOW_COLORS[reset]}       Create compressed archive (.tar.gz)

${FLOW_COLORS[bold]}RETENTION POLICIES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}archive${FLOW_COLORS[reset]}       Keep forever - exams, syllabi, rubrics
  ${FLOW_COLORS[accent]}semester${FLOW_COLORS[reset]}      Delete at semester end - lectures, slides

  Backups are processed according to their retention policy setting.

${FLOW_COLORS[bold]}SEMESTER NAMING${FLOW_COLORS[reset]}
  Use standard semester identifiers:

  ${FLOW_COLORS[cmd]}spring-YYYY${FLOW_COLORS[reset]}      Spring semester (Jan - May)
  ${FLOW_COLORS[cmd]}summer-YYYY${FLOW_COLORS[reset]}      Summer session (May - Aug)
  ${FLOW_COLORS[cmd]}fall-YYYY${FLOW_COLORS[reset]}        Fall semester (Aug - Dec)

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Archive spring 2026 semester (with confirmation)${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026

  ${FLOW_COLORS[muted]}# Preview archive actions${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026 --dry-run

  ${FLOW_COLORS[muted]}# Force archive (no confirmation)${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026 --force

  ${FLOW_COLORS[muted]}# Create compressed archive${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026 --compress

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}.backups/.archive/${FLOW_COLORS[reset]}
  • Compressed archives (.tar.gz) for long-term storage
  • Metadata updated with archive status
  • Original backups removed after archiving

${FLOW_COLORS[bold]}WARNING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[warning]}⚠ Run after semester ends${FLOW_COLORS[reset]}

  Best practices:
  • Archive AFTER final grades are submitted
  • Keep exams and syllabi (archive policy)
  • Remove lectures and slides (semester policy)
  • Use ${FLOW_COLORS[accent]}--dry-run${FLOW_COLORS[reset]} first to preview

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Combine with ${FLOW_COLORS[accent]}teach doctor --fix${FLOW_COLORS[reset]} for storage optimization
  • Compressed archives save significant space
  • Keep archives off-site for disaster recovery

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List all backups
  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} - Delete individual backups
  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} - Check backup system health

EOF
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

# Backup help (upgraded to FLOW_COLORS)
_teach_backup_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup${FLOW_COLORS[reset]} - Content Backup System                    ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup <subcommand> [args]

${FLOW_COLORS[bold]}SUBCOMMANDS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}create [path]${FLOW_COLORS[reset]}          Create timestamped backup
  ${FLOW_COLORS[cmd]}list [path]${FLOW_COLORS[reset]}            List all backups
  ${FLOW_COLORS[cmd]}restore <name>${FLOW_COLORS[reset]}         Restore from backup
  ${FLOW_COLORS[cmd]}delete <name>${FLOW_COLORS[reset]}          Delete backup (with confirmation)
  ${FLOW_COLORS[cmd]}archive <semester>${FLOW_COLORS[reset]}     Archive semester backups

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Create backup${FLOW_COLORS[reset]}
  $ teach backup create lectures/week-01

  ${FLOW_COLORS[muted]}# List all backups${FLOW_COLORS[reset]}
  $ teach backup list

  ${FLOW_COLORS[muted]}# Restore from backup${FLOW_COLORS[reset]}
  $ teach backup restore lectures.2026-01-20-1430

  ${FLOW_COLORS[muted]}# Archive semester (end of semester)${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026

${FLOW_COLORS[bold]}BACKUP STRUCTURE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}.backups/${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}├── lectures.2026-01-20-1430/${FLOW_COLORS[reset]}    Timestamped snapshots
  ${FLOW_COLORS[muted]}├── lectures.2026-01-19-0900/${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}└── metadata.json${FLOW_COLORS[reset]}                Backup metadata

${FLOW_COLORS[bold]}RETENTION POLICIES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}archive${FLOW_COLORS[reset]}    Keep forever (exams, syllabi)
  ${FLOW_COLORS[accent]}semester${FLOW_COLORS[reset]}   Delete at semester end (lectures)

${FLOW_COLORS[muted]}Get subcommand help: teach backup <subcommand> --help${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}SEE ALSO${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach clean${FLOW_COLORS[reset]} - Clean build artifacts
  ${FLOW_COLORS[cmd]}teach deploy${FLOW_COLORS[reset]} - Deploy course website

EOF
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
