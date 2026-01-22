#!/usr/bin/env zsh

# lib/prerequisite-checker.zsh
# Prerequisite validation library for teach analyze command
# Phase 0: Prerequisite checking

# Disable zsh options that cause variable assignments to print
# This prevents debug output when LOCAL_OPTIONS is enabled by prompt frameworks
unsetopt local_options 2>/dev/null
unsetopt print_exit_value 2>/dev/null
setopt NO_local_options 2>/dev/null

# Array to track all violations (for JSON output)
typeset -ga PREREQUISITE_VIOLATIONS=()

# Check all concepts for valid prerequisites
# Returns JSON array of violations
# Globals:
#   PREREQUISITE_VIOLATIONS - Array of violations
# Arguments:
#   $1 - course_data (JSON string with weeks array)
# Returns:
#   JSON array of violations
_check_prerequisites() {
    local course_data="$1"
    local violations_json="[]"
    local week_num concept concept_id prerequisites

    # Reset violations array
    PREREQUISITE_VIOLATIONS=()

    # Build week order mapping
    local -A week_order_map
    local i=1
    while IFS= read -r week_data; do
        local week_name week_num
        week_name=$(echo "$week_data" | jq -r '.week // empty')
        week_num=$(echo "$week_data" | jq -r '.week_num // empty')
        if [[ -n "$week_num" ]]; then
            week_order_map[$week_name]=$week_num
        fi
        ((i++))
    done <<< "$(echo "$course_data" | jq -c '.weeks[]')"

    # Check each week and concept
    while IFS= read -r week_data; do
        week_num=$(echo "$week_data" | jq -r '.week_num // empty')

        while IFS= read -r concept_data; do
            concept_id=$(echo "$concept_data" | jq -r '.id // empty')
            prerequisites=$(echo "$concept_data" | jq -r '.prerequisites // []')

            # Skip concepts without prerequisites
            if [[ "$prerequisites" == "[]" ]] || [[ -z "$prerequisites" ]]; then
                continue
            fi

            # Check each prerequisite
            while IFS= read -r prereq; do
                local prereq_exists prereq_week prereq_week_num
                local violation_type violation_message violation_suggestion

                # Check if prerequisite exists in course
                prereq_exists=$(echo "$course_data" | jq --arg prereq "$prereq" \
                    '[.weeks[].concepts[] | .id] | index($prereq)')

                if [[ "$prereq_exists" == "null" ]]; then
                    # Missing prerequisite (ERROR)
                    violation_type="missing"
                    violation_message="Missing prerequisite: $prereq"
                    violation_suggestion="Add $prereq to earlier week"

                    PREREQUISITE_VIOLATIONS+=("$(cat <<EOF
{
  "concept_id": "$concept_id",
  "type": "$violation_type",
  "week": $week_num,
  "prerequisite_id": "$prereq",
  "message": "$violation_message",
  "suggestion": "$violation_suggestion"
}
EOF
)")
                else
                    # Check if prerequisite is from future week
                    prereq_week=$(echo "$course_data" | jq --arg prereq "$prereq" \
                        '.weeks[] | select(.concepts[].id == $prereq) | .week_num')

                    if [[ -n "$prereq_week" ]] && [[ "$prereq_week" -gt "$week_num" ]]; then
                        # Future prerequisite (WARNING)
                        violation_type="future"
                        violation_message="Future prerequisite: $prereq (Week $prereq_week)"
                        violation_suggestion="Move $prereq to Week $((week_num - 1)) or earlier"

                        PREREQUISITE_VIOLATIONS+=("$(cat <<EOF
{
  "concept_id": "$concept_id",
  "type": "$violation_type",
  "week": $week_num,
  "prerequisite_id": "$prereq",
  "prerequisite_week": $prereq_week,
  "message": "$violation_message",
  "suggestion": "$violation_suggestion"
}
EOF
)")
                    fi
                fi
            done <<< "$(echo "$prerequisites" | jq -r '.[]')"
        done <<< "$(echo "$week_data" | jq -c '.concepts[]')"
    done <<< "$(echo "$course_data" | jq -c '.weeks[]')"

    # Convert violations array to JSON
    if [[ ${#PREREQUISITE_VIOLATIONS[@]} -gt 0 ]]; then
        violations_json=$(printf '%s\n' "${PREREQUISITE_VIOLATIONS[@]}" | jq -s '.')
    fi

    echo "$violations_json"
}

# Check single concept's prerequisites
# Arguments:
#   $1 - concept_id
#   $2 - course_data (JSON string)
# Returns:
#   0 if valid, 1 if violations found
_check_concept_prerequisites() {
    local concept_id="$1"
    local course_data="$2"
    local concept_data week_num prerequisites
    local has_violations=0

    # Get concept data
    concept_data=$(echo "$course_data" | jq --arg cid "$concept_id" \
        '.weeks[].concepts[] | select(.id == $cid)')

    if [[ -z "$concept_data" ]] || [[ "$concept_data" == "null" ]]; then
        _flow_log_error "Concept '$concept_id' not found in course data"
        return 1
    fi

    # Get concept's week
    week_num=$(echo "$concept_data" | jq -r '.week_num')

    # Get prerequisites
    prerequisites=$(echo "$concept_data" | jq -r '.prerequisites // []')

    if [[ "$prerequisites" == "[]" ]]; then
        _flow_log_info "No prerequisites defined for '$concept_id'"
        return 0
    fi

    # Check each prerequisite
    while IFS= read -r prereq; do
        local prereq_exists prereq_week

        # Check existence
        prereq_exists=$(echo "$course_data" | jq --arg prereq "$prereq" \
            '[.weeks[].concepts[] | .id] | index($prereq)')

        if [[ "$prereq_exists" == "null" ]]; then
            _flow_log_error "Missing prerequisite '$prereq' for '$concept_id'"
            has_violations=1
            continue
        fi

        # Check week ordering
        prereq_week=$(echo "$course_data" | jq --arg prereq "$prereq" \
            '.weeks[] | select(.concepts[].id == $prereq) | .week_num')

        if [[ -n "$prereq_week" ]] && [[ "$prereq_week" -gt "$week_num" ]]; then
            _flow_log_warning "Future prerequisite '$prereq' (Week $prereq_week) for '$concept_id' (Week $week_num)"
            has_violations=1
        fi
    done <<< "$(echo "$prerequisites" | jq -r '.[]')"

    return $has_violations
}

# Find prerequisites that don't exist anywhere in course
# Arguments:
#   $1 - concept_id
#   $2 - course_data (JSON string)
# Returns:
#   List of missing prerequisites (one per line)
_find_missing_prerequisites() {
    local concept_id="$1"
    local course_data="$2"
    local concept_data prerequisites

    # Get concept data
    concept_data=$(echo "$course_data" | jq --arg cid "$concept_id" \
        '.weeks[].concepts[] | select(.id == $cid)')

    if [[ -z "$concept_data" ]] || [[ "$concept_data" == "null" ]]; then
        return 1
    fi

    # Get prerequisites
    prerequisites=$(echo "$concept_data" | jq -r '.prerequisites // []')

    if [[ "$prerequisites" == "[]" ]]; then
        return 0
    fi

    # Check each prerequisite
    while IFS= read -r prereq; do
        local prereq_exists
        prereq_exists=$(echo "$course_data" | jq --arg prereq "$prereq" \
            '[.weeks[].concepts[] | .id] | index($prereq)')

        if [[ "$prereq_exists" == "null" ]]; then
            echo "$prereq"
        fi
    done <<< "$(echo "$prerequisites" | jq -r '.[]')"
}

# Find prerequisites from future weeks
# Arguments:
#   $1 - concept_id
#   $2 - course_data (JSON string)
# Returns:
#   List of future prerequisites as "prerequisite_id|week_num" (one per line)
_find_future_prerequisites() {
    local concept_id="$1"
    local course_data="$2"
    local concept_data week_num prerequisites

    # Get concept data
    concept_data=$(echo "$course_data" | jq --arg cid "$concept_id" \
        '.weeks[].concepts[] | select(.id == $cid)')

    if [[ -z "$concept_data" ]] || [[ "$concept_data" == "null" ]]; then
        return 1
    fi

    # Get concept's week
    week_num=$(echo "$concept_data" | jq -r '.week_num')

    # Get prerequisites
    prerequisites=$(echo "$concept_data" | jq -r '.prerequisites // []')

    if [[ "$prerequisites" == "[]" ]]; then
        return 0
    fi

    # Check each prerequisite
    while IFS= read -r prereq; do
        local prereq_week
        prereq_week=$(echo "$course_data" | jq --arg prereq "$prereq" \
            '.weeks[] | select(.concepts[].id == $prereq) | .week_num')

        if [[ -n "$prereq_week" ]] && [[ "$prereq_week" -gt "$week_num" ]]; then
            echo "$prereq|$prereq_week"
        fi
    done <<< "$(echo "$prerequisites" | jq -r '.[]')"
}

# Format prerequisite violation with suggestion
# Arguments:
#   $1 - concept_id
#   $2 - type (missing|future)
#   $3 - week (number)
#   $4 - prerequisite_id
#   $5 - prerequisite_week (optional, for future type)
# Outputs:
#   Formatted violation message with suggestion
_format_prerequisite_violation() {
    local concept_id="$1"
    local violation_type="$2"
    local week="$3"
    local prerequisite_id="$4"
    local prerequisite_week="${5:-}"

    local symbol message suggestion color

    case "$violation_type" in
        missing)
            symbol="✗"
            message="ERROR: Missing prerequisite: $prerequisite_id"
            suggestion="Add $prerequisite_id to earlier week"
            color="${FLOW_COLORS[error]:-31}"
            ;;
        future)
            symbol="⚠"
            message="WARNING: Future prerequisite: $prerequisite_id (Week $prerequisite_week)"
            suggestion="Move $prerequisite_id to Week $((week - 1)) or earlier"
            color="${FLOW_COLORS[warning]:-33}"
            ;;
        *)
            symbol="?"
            message="UNKNOWN: Prerequisite violation: $prereq_id"
            suggestion="Review prerequisite setup"
            color="${FLOW_COLORS[info]:-36}"
            ;;
    esac

    # Output formatted violation
    printf '\e[%smWeek %d: %s\e[0m\n' "$color" "$week" "$concept_id"
    printf '  %s \e[%sm%s\e[0m\n' "$symbol" "$color" "$message"
    printf '     Suggestion: %s\n' "$suggestion"
}

# Get dependency chain for a concept (for Phase 1+)
# Arguments:
#   $1 - concept_id
#   $2 - course_data (JSON string)
# Returns:
#   Dependency chain as newline-separated list of concept IDs
_get_dependency_chain() {
    local concept_id="$1"
    local course_data="$2"
    
    # Build concepts list as JSON array
    local concepts_json
    concepts_json=$(echo "$course_data" | jq -c '[.weeks[].concepts[].id] | unique' 2>/dev/null)
    
    # Build visited list as JSON array
    local visited_json="[]"
    
    # Use global CHAIN variable to accumulate results
    typeset -ga CHAIN
    CHAIN=()
    
    # Build dependency chain
    _build_dependency_chain "$concept_id" "$course_data" "$concepts_json" "$visited_json"
    
    # Output chain (reverse order: prerequisites first, then concept)
    if [[ ${#CHAIN[@]} -gt 0 ]]; then
        printf '%s\n' "${CHAIN[@]}"
    fi
}

# Helper function to recursively build dependency chain
# Arguments:
#   $1 - current_concept_id
#   $2 - course_data (JSON string)
#   $3 - concepts_map (JSON array of concept IDs)
#   $4 - visited (JSON array of visited concept IDs)
#   Uses global CHAIN array to accumulate results
_build_dependency_chain() {
    local current_concept="$1"
    local course_data="$2"
    local concepts_json="$3"
    local visited_json="$4"
    
    # Skip if already visited (prevent cycles)
    if echo "$visited_json" | jq -e --arg cid "$current_concept" 'index($cid) != null' >/dev/null 2>&1; then
        return
    fi
    
    # Skip if concept doesn't exist
    if ! echo "$concepts_json" | jq -e --arg cid "$current_concept" 'index($cid) != null' >/dev/null 2>&1; then
        return
    fi
    
    # Add current concept to visited
    visited_json=$(echo "$visited_json" | jq --arg cid "$current_concept" '. + [$cid]' 2>/dev/null)
    
    # Get concept's prerequisites
    local prerequisites
    prerequisites=$(echo "$course_data" | jq --arg cid "$current_concept" \
        '.weeks[].concepts[] | select(.id == $cid) | .prerequisites // []' 2>/dev/null)
    
    if [[ "$prerequisites" != "[]" ]]; then
        # Recursively process each prerequisite
        local prereq
        while IFS= read -r prereq; do
            [[ -z "$prereq" ]] && continue
            _build_dependency_chain "$prereq" "$course_data" "$concepts_json" "$visited_json"
        done <<< "$(echo "$prerequisites" | jq -r '.[]')"
    fi
    
    # Add current concept to chain (using global CHAIN)
    CHAIN+=("$current_concept")
}
