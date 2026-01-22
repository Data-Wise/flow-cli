#!/usr/bin/env zsh

# Source helper libraries
source "${0:A:h:h}/lib/concept-extraction.zsh"
source "${0:A:h:h}/lib/prerequisite-checker.zsh"

# Color scheme (use FLOW_COLORS from core.zsh if available, else define)
: ${FLOW_GREEN:='\033[38;5;154m'}
: ${FLOW_BLUE:='\033[38;5;75m'}
: ${FLOW_YELLOW:='\033[38;5;221m'}
: ${FLOW_RED:='\033[38;5;203m'}
: ${FLOW_BOLD:='\033[1m'}
: ${FLOW_RESET:='\033[0m'}

_display_analysis_header() {
    local title="$1"
    local subtitle="$2"
    local width=55
    local border=┌─
    local border_bottom=╰─
    local corners=┐
    local corners_bottom=╯
    local top_border="${border}${(r:$(($width - 2))::─:)}${corners}"
    local bottom_border="${border_bottom}${(r:$(($width - 2))::─:)}${corners_bottom}"
    echo "${FLOW_BLUE}${top_border}${FLOW_RESET}"
    echo "${FLOW_BLUE}│${FLOW_RESET}${FLOW_BOLD}  ${title}${FLOW_RESET}  ${FLOW_BLUE}│${FLOW_RESET}"
    echo "${FLOW_BLUE}│${FLOW_RESET}  ${subtitle}  ${FLOW_BLUE}│${FLOW_RESET}"
    echo "${FLOW_BLUE}${bottom_border}${FLOW_RESET}"
}

_display_concepts_section() {
    local results_file="$1"
    echo ""
    echo "${FLOW_BLUE}📊 CONCEPT COVERAGE${FLOW_RESET}"
    echo "┌────────────────────────────────────────────────────┐"
    echo "│ Concept                    | Status                │"
    echo "├────────────────────────────┼───────────────────────┤"

    if command -v jq >/dev/null 2>&1; then
        # Use jq to iterate concepts with correct path
        jq -r '.concepts | to_entries[] | "\(.value.name)|\(.value.introduced_in.week)"' "$results_file" 2>/dev/null | \
        while IFS='|' read -r concept_name week_num; do
            local concept_status="✓ Introduced (Week ${week_num})"
            printf "│ %-26s │ %-21s │\n" "$concept_name" "$concept_status"
        done
    else
        echo "│ (Install jq for detailed concept view)              │"
    fi
    echo "└────────────────────────────────────────────────────┘"
}

_display_prerequisites_section() {
    local results_file="$1"
    local error_count=0
    local warning_count=0

    echo ""
    echo "${FLOW_BLUE}🔗 PREREQUISITES${FLOW_RESET}"
    echo "┌────────────────────────────────────────────────────┐"
    echo "│ Prerequisite          | Status                     │"
    echo "├───────────────────────┼────────────────────────────┤"

    if command -v yq >/dev/null 2>&1; then
        yq -r '.prerequisites[] | .name + " | " + .status + " (Week " + .week + ")"' "$results_file" 2>/dev/null | \
        while IFS='|' read -r prereq prereq_status week; do
            local status_indicator="✓"
            local color="${FLOW_GREEN}"

            case "$prereq_status" in
                "error")
                    status_indicator="✗"
                    color="${FLOW_RED}"
                    error_count=$((error_count + 1))
                    ;;
                "warning")
                    status_indicator="⚠"
                    color="${FLOW_YELLOW}"
                    warning_count=$((warning_count + 1))
                    ;;
            esac

            printf "│ %-21s │ ${color}%s${FLOW_RESET} %-18s │\n" "$prereq" "$status_indicator" "${prereq_status} ${week}"
        done
    else
        echo "│ (Install yq for detailed prerequisite view)       │"
    fi
    echo "└────────────────────────────────────────────────────┘"

    return $error_count
}

_display_violations_section() {
    local results_file="$1"
    
    if [[ ! -f "$results_file" ]] || ! command -v yq >/dev/null 2>&1; then
        return
    fi
    
    local violations
    violations=$(yq -r '.violations // [] | length' "$results_file" 2>/dev/null)
    
    if [[ "$violations" -eq 0 ]]; then
        return
    fi
    
    echo ""
    echo "${FLOW_YELLOW}⚠️ VIOLATIONS DETECTED${FLOW_RESET}"
    
    yq -r '.violations[] | "- " + .type + ": " + .message' "$results_file" 2>/dev/null | \
    while read -r violation; do
        echo "${FLOW_YELLOW}${violation}${FLOW_RESET}"
    done
}

_display_summary_section() {
    local results_file="$1"
    local exit_code="$2"
    
    local error_count=0
    local warning_count=0
    
    if command -v yq >/dev/null 2>&1; then
        error_count=$(yq -r '.violations // [] | map(select(.severity == "error")) | length' "$results_file" 2>/dev/null)
        warning_count=$(yq -r '.violations // [] | map(select(.severity == "warning")) | length' "$results_file" 2>/dev/null)
    fi
    
    echo ""
    echo "${FLOW_BLUE}╭─────────────────────────────────────────────────────╮${FLOW_RESET}"
    echo "${FLOW_BLUE}│${FLOW_RESET}${FLOW_BOLD}                      SUMMARY${FLOW_RESET}                        ${FLOW_BLUE}│${FLOW_RESET}"
    echo "${FLOW_BLUE}╰─────────────────────────────────────────────────────╯${FLOW_RESET}"
    echo ""
    
    if [[ "$exit_code" -eq 0 ]]; then
        echo "  ${FLOW_GREEN}Status: ✓ READY TO DEPLOY${FLOW_RESET} (${error_count} errors, ${warning_count} warnings)"
        echo ""
        echo "  ${FLOW_GREEN}✓${FLOW_RESET} All prerequisites satisfied"
        echo "  ${FLOW_GREEN}✓${FLOW_RESET} All concepts properly defined"
    else
        echo "  ${FLOW_YELLOW}Status: ⚠️ WARNINGS DETECTED${FLOW_RESET} (${error_count} errors, ${warning_count} warnings)"
        echo ""
        echo "  ${FLOW_YELLOW}⚠${FLOW_RESET} Some prerequisites not satisfied"
        echo "  ${FLOW_YELLOW}⚠${FLOW_RESET} Review violations above"
    fi
    
    echo ""
    echo "${FLOW_BOLD}Next steps:${FLOW_RESET}"
    if [[ "$exit_code" -eq 0 ]]; then
        echo "  1. Deploy content: ${FLOW_BLUE}teach dispatcher deploy --preview${FLOW_RESET}"
        echo "  2. Or continue editing: ${FLOW_BLUE}quarto preview${FLOW_RESET}"
    else
        echo "  1. Fix prerequisite issues in content"
        echo "  2. Re-run analysis: ${FLOW_BLUE}teach analyze <file>${FLOW_RESET}"
    fi
}

_teach_analyze() {
    local file_path="$1"
    local mode="${2:-moderate}"
    
    # Validate arguments
    if [[ -z "$file_path" ]]; then
        echo "${FLOW_RED}Error: File path required${FLOW_RESET}"
        echo "Usage: teach analyze <file> [--mode strict|moderate]"
        return 1
    fi
    
    # Check file exists
    if [[ ! -f "$file_path" ]]; then
        echo "${FLOW_RED}Error: File not found: $file_path${FLOW_RESET}"
        return 1
    fi
    
    # Show progress
    echo "${FLOW_BLUE}Analyzing: $file_path${FLOW_RESET}"
    printf "${FLOW_BLUE}Building concept graph...${FLOW_RESET} "

    # Determine course directory from file path
    local course_dir
    if [[ "$file_path" == *"/lectures/"* ]]; then
        course_dir="${file_path%/lectures/*}"
    else
        course_dir="${file_path:h}"
    fi

    # Build concept graph (pass course directory, not file)
    local results_file
    results_file=$(_build_concept_graph "$course_dir" 2>/dev/null)

    if [[ -z "$results_file" || ! -f "$results_file" ]]; then
        echo "${FLOW_RED}✗${FLOW_RESET}"
        echo "${FLOW_RED}Error: Failed to build concept graph${FLOW_RESET}"
        return 1
    fi

    echo "${FLOW_GREEN}✓${FLOW_RESET}"

    printf "${FLOW_BLUE}Checking prerequisites...${FLOW_RESET} "

    # Check prerequisites
    _check_prerequisites "$results_file" >/dev/null 2>&1
    local check_result=$?

    echo "${FLOW_GREEN}✓${FLOW_RESET}"

    # Save concept graph to .teach/concepts.json
    mkdir -p "$course_dir/.teach" 2>/dev/null
    if [[ -d "$course_dir/.teach" ]]; then
        cp "$results_file" "$course_dir/.teach/concepts.json" 2>/dev/null
    fi
    
    echo ""
    
    # Display results
    _display_analysis_header "Content Analysis Report - ${file_path:t}" "Mode: $mode | Phase: 0 (heuristic-only)"
    
    _display_concepts_section "$results_file"
    
    _display_prerequisites_section "$results_file"
    local prereq_exit=$?
    
    _display_violations_section "$results_file"
    
    _display_summary_section "$results_file" "$prereq_exit"
    echo ""
    
    # Return exit code (0 for success, 1 for errors)
    return $prereq_exit
}
