#!/usr/bin/env zsh

# =============================================================================
# lib/analysis-display.zsh
# Display layer for teach analyze command
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
# =============================================================================

# Load guard - prevent double-sourcing
if [[ -n "$_FLOW_ANALYSIS_DISPLAY_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_ANALYSIS_DISPLAY_LOADED=1


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
    # Use subshell for complete isolation from parent shell options
    (
        results_file="$1"
        analyzed_file="$2"
        error_count=0
        warning_count=0

        echo ""
        echo "${FLOW_BLUE}🔗 PREREQUISITES${FLOW_RESET}"

        if ! command -v jq >/dev/null 2>&1; then
            echo "  (Install jq for detailed prerequisite view)"
            return 0
        fi

        # Extract the week number from the analyzed file
        analyzed_week=""
        if [[ "$analyzed_file" =~ week-0*([0-9]+) ]]; then
            analyzed_week="${match[1]}"
        else
            analyzed_week="1"
        fi

        # Get concepts introduced in the analyzed file's week
        typeset -a introduced_concepts
        while IFS= read -r concept_id; do
            concept_id="${concept_id//\"/}"
            [[ -z "$concept_id" ]] && continue
            introduced_concepts+=("$concept_id")
        done < <(jq -r --arg week "$analyzed_week" \
            '.concepts | to_entries[] | select(.value.introduced_in.week == ($week | tonumber)) | .key' \
            "$results_file" 2>/dev/null)

        if [[ ${#introduced_concepts[@]} -eq 0 ]]; then
            echo "  No concepts introduced this week"
            return 0
        fi

        echo ""
        echo "  ${FLOW_BOLD}For concepts introduced in Week ${analyzed_week}:${FLOW_RESET}"
        echo ""

        # Display each concept with its prerequisites
        for concept_id in "${introduced_concepts[@]}"; do
            concept_name=$(jq -r --arg cid "$concept_id" \
                '.concepts[$cid].name // $cid' "$results_file" 2>/dev/null)

            echo "  ${FLOW_BOLD}${concept_name}${FLOW_RESET}"

            # Get direct prerequisites for this concept
            typeset -a direct_prereqs
            typeset -A seen_prereqs  # Track to avoid duplicates
            while IFS= read -r prereq_id; do
                prereq_id="${prereq_id//\"/}"
                [[ -z "$prereq_id" || "$prereq_id" == "null" ]] && continue
                [[ "$prereq_id" == "$concept_id" ]] && continue  # Skip self-references
                [[ -n "${seen_prereqs[$prereq_id]}" ]] && continue  # Skip duplicates
                seen_prereqs[$prereq_id]=1
                direct_prereqs+=("$prereq_id")
            done < <(jq -r --arg cid "$concept_id" \
                '.concepts[$cid].prerequisites[]? // empty' "$results_file" 2>/dev/null)

            if [[ ${#direct_prereqs[@]} -eq 0 ]]; then
                echo "    ${FLOW_GREEN}✓${FLOW_RESET} No prerequisites"
            else
                # Display each direct prerequisite
                for prereq_id in "${direct_prereqs[@]}"; do
                    # Final safety check: skip if this prerequisite is the same as the concept
                    [[ "$prereq_id" == "$concept_id" ]] && continue

                    prereq_name=$(jq -r --arg pid "$prereq_id" \
                        '.concepts[$pid].name // $pid' "$results_file" 2>/dev/null)

                    # Get prerequisite week
                    prereq_info=$(jq -r --arg pid "$prereq_id" \
                        '.concepts[$pid] // null' "$results_file" 2>/dev/null)

                    if [[ "$prereq_info" == "null" || -z "$prereq_info" ]]; then
                        echo "    ${FLOW_RED}✗${FLOW_RESET} ${prereq_name} ${FLOW_RED}(missing)${FLOW_RESET}"
                        error_count=$((error_count + 1))
                    else
                        prereq_week=$(echo "$prereq_info" | jq -r '.introduced_in.week // "?"' 2>/dev/null)

                        if [[ "$prereq_week" == "?" ]]; then
                            echo "    ${FLOW_YELLOW}⚠${FLOW_RESET} ${prereq_name} ${FLOW_YELLOW}(unknown week)${FLOW_RESET}"
                            warning_count=$((warning_count + 1))
                        elif [[ "$prereq_week" -gt "$analyzed_week" ]]; then
                            echo "    ${FLOW_YELLOW}⚠${FLOW_RESET} ${prereq_name} ${FLOW_YELLOW}(Week ${prereq_week} - future)${FLOW_RESET}"
                            warning_count=$((warning_count + 1))
                        else
                            # Valid prerequisite - show it with its transitive dependencies
                            echo "    ${FLOW_GREEN}✓${FLOW_RESET} ${prereq_name} ${FLOW_BLUE}(Week ${prereq_week})${FLOW_RESET}"

                            # Get transitive prerequisites (prerequisites of this prerequisite)
                            typeset -a transitive_prereqs
                            typeset -A seen_trans
                            while IFS= read -r trans_prereq_id; do
                                trans_prereq_id="${trans_prereq_id//\"/}"
                                [[ -z "$trans_prereq_id" || "$trans_prereq_id" == "null" ]] && continue
                                [[ "$trans_prereq_id" == "$prereq_id" ]] && continue  # Skip self
                                [[ "$trans_prereq_id" == "$concept_id" ]] && continue  # Skip circular ref to parent
                                [[ -n "${seen_trans[$trans_prereq_id]}" ]] && continue  # Skip duplicates
                                seen_trans[$trans_prereq_id]=1
                                transitive_prereqs+=("$trans_prereq_id")
                            done < <(jq -r --arg pid "$prereq_id" \
                                '.concepts[$pid].prerequisites[]? // empty' "$results_file" 2>/dev/null)

                            # Show transitive dependencies if any
                            if [[ ${#transitive_prereqs[@]} -gt 0 ]]; then
                                for trans_prereq_id in "${transitive_prereqs[@]}"; do
                                    trans_prereq_name=$(jq -r --arg pid "$trans_prereq_id" \
                                        '.concepts[$pid].name // $pid' "$results_file" 2>/dev/null)
                                    trans_prereq_week=$(jq -r --arg pid "$trans_prereq_id" \
                                        '.concepts[$pid].introduced_in.week // "?"' "$results_file" 2>/dev/null)
                                    echo "       ${FLOW_BLUE}└─${FLOW_RESET} ${trans_prereq_name} ${FLOW_BLUE}(Week ${trans_prereq_week}, via ${prereq_name})${FLOW_RESET}"
                                done
                            fi
                        fi
                    fi
                done
            fi

            echo ""
        done

        return $error_count
    )
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

_display_ai_section() {
    local results_file="$1"

    if [[ ! -f "$results_file" ]] || ! command -v jq >/dev/null 2>&1; then
        return
    fi

    # Check if AI data exists in the graph
    local has_ai
    has_ai=$(jq '[.concepts | to_entries[] | select(.value.bloom_level != null)] | length' "$results_file" 2>/dev/null)

    if [[ "$has_ai" -eq 0 || -z "$has_ai" ]]; then
        return
    fi

    echo ""
    echo "${FLOW_BLUE}🤖 AI ANALYSIS${FLOW_RESET}"
    echo "┌────────────────────────────────────────────────────┐"
    echo "│ Concept            | Bloom    | Load | Time        │"
    echo "├────────────────────┼──────────┼──────┼─────────────┤"

    jq -r '.concepts | to_entries[] | select(.value.bloom_level != null) |
        "\(.value.name // .key)|\(.value.bloom_level)|\(.value.cognitive_load)|\(.value.teaching_time_minutes // "?")"' \
        "$results_file" 2>/dev/null | \
    while IFS='|' read -r name bloom load time; do
        # Truncate name to 18 chars
        local short_name="${name:0:18}"
        # Color-code cognitive load
        local load_color="${FLOW_GREEN}"
        if (( $(echo "$load > 0.7" | bc -l 2>/dev/null || echo 0) )); then
            load_color="${FLOW_RED}"
        elif (( $(echo "$load > 0.4" | bc -l 2>/dev/null || echo 0) )); then
            load_color="${FLOW_YELLOW}"
        fi
        printf "│ %-18s │ %-8s │ ${load_color}%.1f${FLOW_RESET}  │ %3s min     │\n" \
            "$short_name" "$bloom" "$load" "$time"
    done

    echo "└────────────────────────────────────────────────────┘"

    # Show AI summary if available
    local avg_load dominant_bloom total_time
    avg_load=$(jq -r '.metadata.ai_summary.avg_cognitive_load // empty' "$results_file" 2>/dev/null)
    dominant_bloom=$(jq -r '.metadata.ai_summary.dominant_bloom_level // empty' "$results_file" 2>/dev/null)
    total_time=$(jq -r '.metadata.ai_summary.estimated_total_time_minutes // empty' "$results_file" 2>/dev/null)

    if [[ -n "$avg_load" || -n "$dominant_bloom" ]]; then
        echo ""
        echo "  ${FLOW_BOLD}AI Summary:${FLOW_RESET}"
        [[ -n "$dominant_bloom" ]] && echo "    Dominant level: ${FLOW_GREEN}$dominant_bloom${FLOW_RESET}"
        [[ -n "$avg_load" ]] && printf "    Avg load:       %.2f\n" "$avg_load"
        [[ -n "$total_time" ]] && echo "    Total time:     ${total_time} min"
    fi

    # Show related concepts (first 5)
    local related
    related=$(jq -r '[.concepts | to_entries[] | select(.value.related_concepts != null) | .value.related_concepts[]] | unique | .[0:5] | join(", ")' "$results_file" 2>/dev/null)

    if [[ -n "$related" && "$related" != "null" ]]; then
        echo ""
        echo "  ${FLOW_BOLD}Key relationships:${FLOW_RESET} $related"
    fi
}

_display_slide_section() {
    local slide_data="$1"

    if [[ -z "$slide_data" || "$slide_data" == "{}" ]]; then
        return
    fi

    local break_count=0
    local concept_count=0
    local total_time=0

    if command -v jq &>/dev/null; then
        break_count=$(echo "$slide_data" | jq '.slide_breaks | length' 2>/dev/null || echo 0)
        concept_count=$(echo "$slide_data" | jq '.key_concepts_for_emphasis | length' 2>/dev/null || echo 0)
        total_time=$(echo "$slide_data" | jq '.time_estimate.total_minutes // 0' 2>/dev/null || echo 0)
    fi

    echo ""
    echo "${FLOW_BLUE}📐 SLIDE OPTIMIZATION${FLOW_RESET}"
    echo "┌────────────────────────────────────────────────────┐"
    echo "│ Metric                     | Value                 │"
    echo "├────────────────────────────┼───────────────────────┤"
    printf "│ %-26s │ %-21s │\n" "Suggested breaks" "$break_count"
    printf "│ %-26s │ %-21s │\n" "Key concepts" "$concept_count"
    printf "│ %-26s │ %-21s │\n" "Estimated time" "${total_time} min"
    echo "└────────────────────────────────────────────────────┘"

    # Show break suggestions (top 3)
    if [[ $break_count -gt 0 ]] && command -v jq &>/dev/null; then
        echo ""
        echo "  ${FLOW_BOLD}Break suggestions:${FLOW_RESET}"
        echo "$slide_data" | jq -r '.slide_breaks[:3][] | "  [\(.priority)] \(.section) → \(.suggested_sub_slides) sub-slides"' 2>/dev/null
        [[ $break_count -gt 3 ]] && echo "  ... and $((break_count - 3)) more (use --preview-breaks for full list)"
    fi

    # Show key concepts (top 5)
    if [[ $concept_count -gt 0 ]] && command -v jq &>/dev/null; then
        echo ""
        echo "  ${FLOW_BOLD}Key concepts for emphasis:${FLOW_RESET}"
        echo "$slide_data" | jq -r '.key_concepts_for_emphasis[:5][] | "  • \(.name)"' 2>/dev/null
        [[ $concept_count -gt 5 ]] && echo "  ... and $((concept_count - 5)) more"
    fi
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
