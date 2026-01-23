#!/usr/bin/env zsh

# lib/report-generator.zsh
# Report generation library for teach analyze command
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
# Phase 2: Report generation system
#
# Features:
#   - Markdown and JSON output formats
#   - Summary statistics (concept count, violations, coverage)
#   - Detailed prerequisite violation listing
#   - Concept graph visualization (text-based)
#   - Per-week breakdown
#
# Usage:
#   _report_generate <course_dir> [--format markdown|json] [--output FILE]

# Load guard - prevent double-sourcing
if [[ -n "$_FLOW_REPORT_GENERATOR_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_REPORT_GENERATOR_LOADED=1

# Disable zsh options that cause variable assignments to print
# This prevents debug output when LOCAL_OPTIONS is enabled by prompt frameworks
unsetopt local_options 2>/dev/null
unsetopt print_exit_value 2>/dev/null
setopt NO_local_options 2>/dev/null

# Source core library for colors and logging
if [[ -f "${0:A:h}/core.zsh" ]]; then
    source "${0:A:h}/core.zsh"
fi

# =============================================================================
# Constants and Defaults
# =============================================================================

# Report version for schema compatibility
REPORT_VERSION="1.0"

# Default output format
DEFAULT_REPORT_FORMAT="markdown"

# =============================================================================
# Function: _report_generate
# Purpose: Main entry point for report generation
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory containing .teach/concepts.json
#   --format FORMAT: Output format (markdown|json), default: markdown
#   --output FILE: Optional output file path
#   --violations-only: Only include violations section
#   --summary-only: Only include summary section
#
# Returns:
#   0 - Success
#   1 - Error (missing concepts.json, invalid format)
#
# Output:
#   stdout - Generated report content (if no --output specified)
#   file - Report saved to specified path (if --output specified)
#
# Example:
#   _report_generate /path/to/course --format markdown
#   _report_generate /path/to/course --format json --output report.json
# =============================================================================
_report_generate() {
    local course_dir=""
    local format="$DEFAULT_REPORT_FORMAT"
    local output_file=""
    local violations_only=false
    local summary_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                shift
                format="${1:-markdown}"
                ;;
            --output)
                shift
                output_file="$1"
                ;;
            --violations-only)
                violations_only=true
                ;;
            --summary-only)
                summary_only=true
                ;;
            -*)
                _flow_log_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$course_dir" ]]; then
                    course_dir="$1"
                fi
                ;;
        esac
        shift
    done

    # Validate course directory
    if [[ -z "$course_dir" ]]; then
        course_dir="$PWD"
    fi

    if [[ ! -d "$course_dir" ]]; then
        _flow_log_error "Course directory not found: $course_dir"
        return 1
    fi

    # Check for concepts.json
    local concepts_file="$course_dir/.teach/concepts.json"
    if [[ ! -f "$concepts_file" ]]; then
        _flow_log_error "Concept graph not found: $concepts_file"
        _flow_log_info "Run 'teach analyze' first to generate the concept graph"
        return 1
    fi

    # Validate format
    case "$format" in
        markdown|md)
            format="markdown"
            ;;
        json)
            ;;
        *)
            _flow_log_error "Invalid format: $format (use markdown or json)"
            return 1
            ;;
    esac

    # Generate report based on format
    local report_content=""
    if [[ "$format" == "markdown" ]]; then
        report_content=$(_report_format_markdown "$course_dir" "$violations_only" "$summary_only")
    else
        report_content=$(_report_format_json "$course_dir" "$violations_only" "$summary_only")
    fi

    # Output report
    if [[ -n "$output_file" ]]; then
        _report_save "$report_content" "$output_file"
    else
        echo "$report_content"
    fi
}

# =============================================================================
# Function: _report_format_markdown
# Purpose: Generate markdown-formatted analysis report
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#   $2 - violations_only: Boolean, only show violations
#   $3 - summary_only: Boolean, only show summary
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - Markdown report content
# =============================================================================
_report_format_markdown() {
    local course_dir="$1"
    local violations_only="${2:-false}"
    local summary_only="${3:-false}"

    local concepts_file="$course_dir/.teach/concepts.json"
    local course_name
    course_name=$(basename "$course_dir")

    # Get summary stats
    local -A stats
    _report_summary_stats "$concepts_file" stats

    # Start building report
    local report=""

    # Header
    report+="# Concept Analysis Report\n\n"
    report+="**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")\n"
    report+="**Course:** $course_name\n"
    report+="**Report Version:** $REPORT_VERSION\n\n"

    # Summary section
    if [[ "$violations_only" != "true" ]]; then
        report+="## Summary\n\n"
        report+="| Metric | Value |\n"
        report+="|--------|-------|\n"
        report+="| Total Concepts | ${stats[total_concepts]} |\n"
        report+="| Total Weeks | ${stats[total_weeks]} |\n"
        report+="| Error Violations | ${stats[error_count]} |\n"
        report+="| Warning Violations | ${stats[warning_count]} |\n"
        report+="| Coverage | ${stats[coverage]}% |\n\n"

        if [[ "${stats[error_count]}" -eq 0 && "${stats[warning_count]}" -eq 0 ]]; then
            report+="**Status:** Ready to Deploy\n\n"
        else
            report+="**Status:** Review Required (${stats[error_count]} errors, ${stats[warning_count]} warnings)\n\n"
        fi
    fi

    # Exit early if summary only
    if [[ "$summary_only" == "true" ]]; then
        echo -e "$report"
        return 0
    fi

    # Violations section
    local violations_table
    violations_table=$(_report_violations_table "$course_dir" "markdown")
    if [[ -n "$violations_table" ]]; then
        report+="## Prerequisite Violations\n\n"
        report+="$violations_table\n\n"
    elif [[ "$violations_only" != "true" ]]; then
        report+="## Prerequisite Violations\n\n"
        report+="No violations found.\n\n"
    fi

    # Exit early if violations only
    if [[ "$violations_only" == "true" ]]; then
        echo -e "$report"
        return 0
    fi

    # Concept graph section
    report+="## Concept Map (by week)\n\n"
    report+="\`\`\`\n"
    report+=$(_report_concept_graph_text "$course_dir")
    report+="\n\`\`\`\n\n"

    # Per-week breakdown
    report+="## Week-by-Week Breakdown\n\n"
    report+=$(_report_week_breakdown "$course_dir" "markdown")
    report+="\n"

    # Recommendations section
    report+="## Recommendations\n\n"
    local recommendations
    recommendations=$(_report_recommendations "$course_dir")
    if [[ -n "$recommendations" ]]; then
        report+="$recommendations\n"
    else
        report+="No recommendations at this time. All prerequisites are satisfied.\n"
    fi

    echo -e "$report"
}

# =============================================================================
# Function: _report_format_json
# Purpose: Generate JSON-formatted analysis report
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#   $2 - violations_only: Boolean, only show violations
#   $3 - summary_only: Boolean, only show summary
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - JSON report content
# =============================================================================
_report_format_json() {
    local course_dir="$1"
    local violations_only="${2:-false}"
    local summary_only="${3:-false}"

    local concepts_file="$course_dir/.teach/concepts.json"
    local course_name
    course_name=$(basename "$course_dir")

    # Get summary stats
    local -A stats
    _report_summary_stats "$concepts_file" stats

    # Build JSON using jq
    local json_report

    # Start with metadata
    json_report=$(jq -n \
        --arg version "$REPORT_VERSION" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --arg course "$course_name" \
        --arg course_dir "$course_dir" \
        '{
            report_version: $version,
            generated_at: $timestamp,
            course: {
                name: $course,
                directory: $course_dir
            }
        }')

    # Add summary stats
    json_report=$(echo "$json_report" | jq \
        --argjson total_concepts "${stats[total_concepts]:-0}" \
        --argjson total_weeks "${stats[total_weeks]:-0}" \
        --argjson error_count "${stats[error_count]:-0}" \
        --argjson warning_count "${stats[warning_count]:-0}" \
        --argjson coverage "${stats[coverage]:-0}" \
        '.summary = {
            total_concepts: $total_concepts,
            total_weeks: $total_weeks,
            error_violations: $error_count,
            warning_violations: $warning_count,
            coverage_percent: $coverage,
            ready_to_deploy: ($error_count == 0)
        }')

    # Exit early if summary only
    if [[ "$summary_only" == "true" ]]; then
        echo "$json_report"
        return 0
    fi

    # Add violations
    local violations_json
    violations_json=$(_report_violations_table "$course_dir" "json")
    if [[ -n "$violations_json" && "$violations_json" != "[]" ]]; then
        json_report=$(echo "$json_report" | jq --argjson violations "$violations_json" '.violations = $violations')
    else
        json_report=$(echo "$json_report" | jq '.violations = []')
    fi

    # Exit early if violations only
    if [[ "$violations_only" == "true" ]]; then
        echo "$json_report"
        return 0
    fi

    # Add concept graph
    local concept_graph_json
    concept_graph_json=$(_report_concept_graph_json "$course_dir")
    json_report=$(echo "$json_report" | jq --argjson graph "$concept_graph_json" '.concept_graph = $graph')

    # Add week breakdown
    local week_breakdown_json
    week_breakdown_json=$(_report_week_breakdown "$course_dir" "json")
    json_report=$(echo "$json_report" | jq --argjson weeks "$week_breakdown_json" '.weeks = $weeks')

    # Add recommendations
    local recommendations_json
    recommendations_json=$(_report_recommendations_json "$course_dir")
    json_report=$(echo "$json_report" | jq --argjson recs "$recommendations_json" '.recommendations = $recs')

    echo "$json_report"
}

# =============================================================================
# Function: _report_summary_stats
# Purpose: Calculate summary statistics from concept graph
# =============================================================================
# Arguments:
#   $1 - concepts_file: Path to concepts.json
#   $2 - stats_var: Name of associative array to populate
#
# Returns:
#   0 - Success
#
# Side Effects:
#   Populates the named associative array with:
#     total_concepts, total_weeks, error_count, warning_count, coverage
# =============================================================================
_report_summary_stats() {
    local concepts_file="$1"
    local stats_var="$2"

    # Initialize stats
    local total_concepts=0
    local total_weeks=0
    local error_count=0
    local warning_count=0
    local coverage=100

    if [[ -f "$concepts_file" ]] && command -v jq &>/dev/null; then
        # Get total concepts
        total_concepts=$(jq -r '.metadata.total_concepts // 0' "$concepts_file" 2>/dev/null)

        # Get total weeks
        total_weeks=$(jq -r '.metadata.weeks // 0' "$concepts_file" 2>/dev/null)

        # Count concepts with prerequisites
        local concepts_with_prereqs
        concepts_with_prereqs=$(jq '[.concepts[] | select(.prerequisites | length > 0)] | length' "$concepts_file" 2>/dev/null)

        # Count concepts where all prerequisites are satisfied
        # This requires checking each concept's prerequisites exist and are from earlier weeks
        local satisfied_count=0
        local violation_details

        # Extract all concept IDs and their weeks
        local -A concept_weeks
        while IFS='|' read -r cid week; do
            [[ -n "$cid" ]] && concept_weeks[$cid]=$week
        done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.introduced_in.week // 0)"' "$concepts_file" 2>/dev/null)"

        # Check each concept's prerequisites
        while IFS='|' read -r cid prereqs week; do
            [[ -z "$cid" ]] && continue
            [[ "$prereqs" == "null" || "$prereqs" == "[]" ]] && continue

            # Parse prerequisites
            local has_error=false
            local has_warning=false

            while read -r prereq; do
                [[ -z "$prereq" ]] && continue

                # Check if prerequisite exists
                if [[ -z "${concept_weeks[$prereq]}" ]]; then
                    has_error=true
                    ((error_count++))
                elif [[ "${concept_weeks[$prereq]}" -ge "$week" ]]; then
                    # Prerequisite is from same week or later
                    has_warning=true
                    ((warning_count++))
                fi
            done <<< "$(echo "$prereqs" | jq -r '.[]' 2>/dev/null)"

        done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.prerequisites // [])|\(.value.introduced_in.week // 0)"' "$concepts_file" 2>/dev/null)"

        # Calculate coverage (percentage of concepts with satisfied prerequisites)
        if [[ "$total_concepts" -gt 0 ]]; then
            local satisfied=$((total_concepts - error_count))
            coverage=$((satisfied * 100 / total_concepts))
        fi
    fi

    # Populate the stats array using eval (ZSH pattern for populating named array)
    eval "${stats_var}[total_concepts]=$total_concepts"
    eval "${stats_var}[total_weeks]=$total_weeks"
    eval "${stats_var}[error_count]=$error_count"
    eval "${stats_var}[warning_count]=$warning_count"
    eval "${stats_var}[coverage]=$coverage"
}

# =============================================================================
# Function: _report_violations_table
# Purpose: Format prerequisite violations as table (markdown or JSON)
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#   $2 - format: Output format (markdown|json)
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - Formatted violations table
# =============================================================================
_report_violations_table() {
    local course_dir="$1"
    local format="${2:-markdown}"

    local concepts_file="$course_dir/.teach/concepts.json"

    if [[ ! -f "$concepts_file" ]] || ! command -v jq &>/dev/null; then
        [[ "$format" == "json" ]] && echo "[]"
        return 0
    fi

    # Build violations array
    local violations_json="[]"
    local -A concept_weeks

    # Extract all concept IDs and their weeks
    while IFS='|' read -r cid week; do
        [[ -n "$cid" ]] && concept_weeks[$cid]=$week
    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.introduced_in.week // 0)"' "$concepts_file" 2>/dev/null)"

    # Check each concept's prerequisites and collect violations
    while IFS='|' read -r cid prereqs_raw week lecture; do
        [[ -z "$cid" ]] && continue
        [[ "$prereqs_raw" == "null" || -z "$prereqs_raw" ]] && continue

        # Parse prerequisites JSON array
        while read -r prereq; do
            [[ -z "$prereq" ]] && continue

            local violation_type=""
            local message=""
            local suggestion=""

            # Check if prerequisite exists
            if [[ -z "${concept_weeks[$prereq]}" ]]; then
                violation_type="missing"
                message="Missing prerequisite: $prereq is not defined in any week"
                suggestion="Add '$prereq' to an earlier week's content"
            elif [[ "${concept_weeks[$prereq]}" -gt "$week" ]]; then
                # Prerequisite is from later week
                violation_type="future"
                message="Future prerequisite: $prereq (Week ${concept_weeks[$prereq]}) required by Week $week"
                suggestion="Move '$prereq' to Week $((week - 1)) or earlier"
            elif [[ "${concept_weeks[$prereq]}" -eq "$week" ]]; then
                # Prerequisite is from same week (warning)
                violation_type="same_week"
                message="Same-week prerequisite: $prereq is in the same week ($week)"
                suggestion="Consider moving '$prereq' to an earlier week for clearer progression"
            fi

            if [[ -n "$violation_type" ]]; then
                violations_json=$(echo "$violations_json" | jq \
                    --arg week "$week" \
                    --arg concept "$cid" \
                    --arg prereq "$prereq" \
                    --arg type "$violation_type" \
                    --arg message "$message" \
                    --arg suggestion "$suggestion" \
                    --arg lecture "$lecture" \
                    '. += [{
                        week: ($week | tonumber),
                        concept: $concept,
                        prerequisite: $prereq,
                        type: $type,
                        severity: (if $type == "missing" or $type == "future" then "error" else "warning" end),
                        message: $message,
                        suggestion: $suggestion,
                        lecture: $lecture
                    }]')
            fi
        done <<< "$(echo "$prereqs_raw" | jq -r '.[]' 2>/dev/null)"

    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.prerequisites // [])|\(.value.introduced_in.week // 0)|\(.value.introduced_in.lecture // "")"' "$concepts_file" 2>/dev/null)"

    # Output based on format
    if [[ "$format" == "json" ]]; then
        echo "$violations_json"
    else
        # Format as markdown table
        local violation_count
        violation_count=$(echo "$violations_json" | jq 'length')

        if [[ "$violation_count" -eq 0 ]]; then
            return 0
        fi

        # Build markdown table
        local table="| Week | Concept | Issue | Suggestion |\n"
        table+="|------|---------|-------|------------|\n"

        while IFS='|' read -r week concept issue suggestion; do
            table+="| $week | $concept | $issue | $suggestion |\n"
        done <<< "$(echo "$violations_json" | jq -r '.[] | "\(.week)|\(.concept)|\(.message)|\(.suggestion)"')"

        echo -e "$table"
    fi
}

# =============================================================================
# Function: _report_concept_graph_text
# Purpose: Generate text-based visualization of concept dependencies
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - Text-based concept graph
# =============================================================================
_report_concept_graph_text() {
    local course_dir="$1"
    local concepts_file="$course_dir/.teach/concepts.json"

    if [[ ! -f "$concepts_file" ]] || ! command -v jq &>/dev/null; then
        echo "(No concept graph available)"
        return 0
    fi

    local output=""
    local current_week=0
    local -A concept_by_week

    # Group concepts by week
    while IFS='|' read -r cid name week prereqs; do
        [[ -z "$cid" ]] && continue
        week=${week:-0}

        # Store concept info
        if [[ -z "${concept_by_week[$week]}" ]]; then
            concept_by_week[$week]="$cid|$name|$prereqs"
        else
            concept_by_week[$week]+="\n$cid|$name|$prereqs"
        fi
    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.name // .key)|\(.value.introduced_in.week // 0)|\(.value.prerequisites // [] | join(","))"' "$concepts_file" 2>/dev/null)"

    # Sort weeks and output
    local sorted_weeks
    sorted_weeks=($(echo "${(k)concept_by_week[@]}" | tr ' ' '\n' | sort -n))

    for week in $sorted_weeks; do
        [[ "$week" -eq 0 ]] && continue

        output+="Week $week:\n"

        # Process each concept in this week
        while IFS='|' read -r cid name prereqs; do
            [[ -z "$cid" ]] && continue

            if [[ -z "$prereqs" || "$prereqs" == "null" ]]; then
                # No prerequisites - standalone concept
                output+="  $cid (introduces: $name)\n"
            else
                # Has prerequisites - show dependency chain
                output+="  $cid (requires: $prereqs)\n"
            fi
        done <<< "$(echo -e "${concept_by_week[$week]}")"

        output+="\n"
    done

    echo -e "$output"
}

# =============================================================================
# Function: _report_concept_graph_json
# Purpose: Generate JSON representation of concept graph
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - JSON concept graph
# =============================================================================
_report_concept_graph_json() {
    local course_dir="$1"
    local concepts_file="$course_dir/.teach/concepts.json"

    if [[ ! -f "$concepts_file" ]] || ! command -v jq &>/dev/null; then
        echo '{"nodes": [], "edges": []}'
        return 0
    fi

    # Build nodes and edges
    local nodes_json="[]"
    local edges_json="[]"

    while IFS='|' read -r cid name week prereqs; do
        [[ -z "$cid" ]] && continue

        # Add node
        nodes_json=$(echo "$nodes_json" | jq \
            --arg id "$cid" \
            --arg name "$name" \
            --argjson week "${week:-0}" \
            '. += [{id: $id, name: $name, week: $week}]')

        # Add edges for prerequisites
        if [[ -n "$prereqs" && "$prereqs" != "null" ]]; then
            for prereq in ${(s:,:)prereqs}; do
                [[ -z "$prereq" ]] && continue
                edges_json=$(echo "$edges_json" | jq \
                    --arg from "$prereq" \
                    --arg to "$cid" \
                    '. += [{from: $from, to: $to, type: "prerequisite"}]')
            done
        fi
    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.name // .key)|\(.value.introduced_in.week // 0)|\(.value.prerequisites // [] | join(","))"' "$concepts_file" 2>/dev/null)"

    jq -n --argjson nodes "$nodes_json" --argjson edges "$edges_json" '{nodes: $nodes, edges: $edges}'
}

# =============================================================================
# Function: _report_week_breakdown
# Purpose: Generate per-week analysis breakdown
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#   $2 - format: Output format (markdown|json)
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - Week-by-week breakdown
# =============================================================================
_report_week_breakdown() {
    local course_dir="$1"
    local format="${2:-markdown}"
    local concepts_file="$course_dir/.teach/concepts.json"

    if [[ ! -f "$concepts_file" ]] || ! command -v jq &>/dev/null; then
        [[ "$format" == "json" ]] && echo "[]"
        return 0
    fi

    # Build week data
    local weeks_json="[]"
    local -A week_concepts
    local -A week_lectures

    # Group concepts by week
    while IFS='|' read -r cid name week prereqs lecture; do
        [[ -z "$cid" ]] && continue
        week=${week:-0}

        # Count concepts per week
        if [[ -z "${week_concepts[$week]}" ]]; then
            week_concepts[$week]=1
        else
            week_concepts[$week]=$((week_concepts[$week] + 1))
        fi

        # Track lectures
        if [[ -n "$lecture" ]]; then
            week_lectures[$week]="$lecture"
        fi
    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.name // .key)|\(.value.introduced_in.week // 0)|\(.value.prerequisites // [] | join(","))|\(.value.introduced_in.lecture // "")"' "$concepts_file" 2>/dev/null)"

    # Build JSON array
    local sorted_weeks
    sorted_weeks=($(echo "${(k)week_concepts[@]}" | tr ' ' '\n' | sort -n))

    for week in $sorted_weeks; do
        [[ "$week" -eq 0 ]] && continue

        weeks_json=$(echo "$weeks_json" | jq \
            --argjson week "$week" \
            --argjson count "${week_concepts[$week]:-0}" \
            --arg lecture "${week_lectures[$week]:-}" \
            '. += [{
                week: $week,
                concept_count: $count,
                lecture: $lecture
            }]')
    done

    # Output based on format
    if [[ "$format" == "json" ]]; then
        echo "$weeks_json"
    else
        # Format as markdown
        local output=""
        local total_weeks
        total_weeks=$(echo "$weeks_json" | jq 'length')

        while IFS='|' read -r week count lecture; do
            output+="### Week $week\n\n"
            output+="- **Concepts introduced:** $count\n"
            if [[ -n "$lecture" ]]; then
                output+="- **Lecture:** \`$lecture\`\n"
            fi
            output+="\n"
        done <<< "$(echo "$weeks_json" | jq -r '.[] | "\(.week)|\(.concept_count)|\(.lecture)"')"

        echo -e "$output"
    fi
}

# =============================================================================
# Function: _report_recommendations
# Purpose: Generate actionable recommendations based on analysis
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - Markdown-formatted recommendations
# =============================================================================
_report_recommendations() {
    local course_dir="$1"
    local concepts_file="$course_dir/.teach/concepts.json"

    if [[ ! -f "$concepts_file" ]] || ! command -v jq &>/dev/null; then
        return 0
    fi

    local recommendations=""
    local rec_num=1
    local -A concept_weeks

    # Extract all concept IDs and their weeks
    while IFS='|' read -r cid week; do
        [[ -n "$cid" ]] && concept_weeks[$cid]=$week
    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.introduced_in.week // 0)"' "$concepts_file" 2>/dev/null)"

    # Check for violations and generate recommendations
    while IFS='|' read -r cid prereqs week; do
        [[ -z "$cid" ]] && continue
        [[ "$prereqs" == "null" || -z "$prereqs" ]] && continue

        while read -r prereq; do
            [[ -z "$prereq" ]] && continue

            if [[ -z "${concept_weeks[$prereq]}" ]]; then
                recommendations+="$rec_num. **Add missing concept:** Define \`$prereq\` in Week $((week - 1)) or earlier before using it in \`$cid\`.\n"
                ((rec_num++))
            elif [[ "${concept_weeks[$prereq]}" -gt "$week" ]]; then
                recommendations+="$rec_num. **Reorder content:** Move \`$prereq\` from Week ${concept_weeks[$prereq]} to Week $((week - 1)) or earlier.\n"
                ((rec_num++))
            elif [[ "${concept_weeks[$prereq]}" -eq "$week" ]]; then
                recommendations+="$rec_num. **Consider reordering:** \`$prereq\` and \`$cid\` are in the same week. Consider introducing \`$prereq\` earlier for clearer progression.\n"
                ((rec_num++))
            fi
        done <<< "$(echo "$prereqs" | jq -r '.[]' 2>/dev/null)"

    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.prerequisites // [])|\(.value.introduced_in.week // 0)"' "$concepts_file" 2>/dev/null)"

    echo -e "$recommendations"
}

# =============================================================================
# Function: _report_recommendations_json
# Purpose: Generate JSON array of recommendations
# =============================================================================
# Arguments:
#   $1 - course_dir: Path to course directory
#
# Returns:
#   0 - Success
#
# Output:
#   stdout - JSON array of recommendations
# =============================================================================
_report_recommendations_json() {
    local course_dir="$1"
    local concepts_file="$course_dir/.teach/concepts.json"

    if [[ ! -f "$concepts_file" ]] || ! command -v jq &>/dev/null; then
        echo "[]"
        return 0
    fi

    local recommendations_json="[]"
    local -A concept_weeks

    # Extract all concept IDs and their weeks
    while IFS='|' read -r cid week; do
        [[ -n "$cid" ]] && concept_weeks[$cid]=$week
    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.introduced_in.week // 0)"' "$concepts_file" 2>/dev/null)"

    # Check for violations and generate recommendations
    while IFS='|' read -r cid prereqs week; do
        [[ -z "$cid" ]] && continue
        [[ "$prereqs" == "null" || -z "$prereqs" ]] && continue

        while read -r prereq; do
            [[ -z "$prereq" ]] && continue

            local rec_type=""
            local action=""
            local priority=""

            if [[ -z "${concept_weeks[$prereq]}" ]]; then
                rec_type="add_missing"
                action="Define '$prereq' in Week $((week - 1)) or earlier"
                priority="high"
            elif [[ "${concept_weeks[$prereq]}" -gt "$week" ]]; then
                rec_type="reorder"
                action="Move '$prereq' from Week ${concept_weeks[$prereq]} to Week $((week - 1)) or earlier"
                priority="high"
            elif [[ "${concept_weeks[$prereq]}" -eq "$week" ]]; then
                rec_type="consider_reorder"
                action="Consider moving '$prereq' to an earlier week"
                priority="low"
            fi

            if [[ -n "$rec_type" ]]; then
                recommendations_json=$(echo "$recommendations_json" | jq \
                    --arg type "$rec_type" \
                    --arg action "$action" \
                    --arg priority "$priority" \
                    --arg concept "$cid" \
                    --arg prereq "$prereq" \
                    --argjson week "$week" \
                    '. += [{
                        type: $type,
                        action: $action,
                        priority: $priority,
                        affected_concept: $concept,
                        affected_prerequisite: $prereq,
                        week: $week
                    }]')
            fi
        done <<< "$(echo "$prereqs" | jq -r '.[]' 2>/dev/null)"

    done <<< "$(jq -r '.concepts | to_entries[] | "\(.key)|\(.value.prerequisites // [])|\(.value.introduced_in.week // 0)"' "$concepts_file" 2>/dev/null)"

    echo "$recommendations_json"
}

# =============================================================================
# Function: _report_save
# Purpose: Save report content to file with atomic write
# =============================================================================
# Arguments:
#   $1 - content: Report content to save
#   $2 - output_file: Path to output file
#
# Returns:
#   0 - Success
#   1 - Error (write failed)
#
# Output:
#   stderr - Success/error messages
# =============================================================================
_report_save() {
    local content="$1"
    local output_file="$2"

    if [[ -z "$output_file" ]]; then
        _flow_log_error "Output file path required"
        return 1
    fi

    # Create parent directory if needed
    local parent_dir="${output_file:h}"
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir" 2>/dev/null || {
            _flow_log_error "Failed to create directory: $parent_dir"
            return 1
        }
    fi

    # Atomic write using temp file
    local temp_file="${output_file}.tmp.$$"

    if ! echo -e "$content" > "$temp_file" 2>/dev/null; then
        _flow_log_error "Failed to write temporary file: $temp_file"
        return 1
    fi

    if ! mv "$temp_file" "$output_file" 2>/dev/null; then
        _flow_log_error "Failed to save report: $output_file"
        rm -f "$temp_file"
        return 1
    fi

    _flow_log_success "Report saved to: $output_file"
    return 0
}

# =============================================================================
# Function: _report_help
# Purpose: Display help for report generation
# =============================================================================
_report_help() {
    cat << 'EOF'
Report Generator for teach analyze
==================================

Generate analysis reports in markdown or JSON format.

USAGE:
  _report_generate <course_dir> [options]

OPTIONS:
  --format FORMAT     Output format: markdown (default) or json
  --output FILE       Save report to file (otherwise prints to stdout)
  --violations-only   Only include violations section
  --summary-only      Only include summary section

EXAMPLES:
  # Generate markdown report to stdout
  _report_generate /path/to/course

  # Generate JSON report to file
  _report_generate /path/to/course --format json --output report.json

  # Generate markdown report to file
  _report_generate /path/to/course --output analysis-report.md

  # Only show violations
  _report_generate /path/to/course --violations-only

REPORT SECTIONS:
  - Summary: Concept count, week count, violations, coverage percentage
  - Prerequisite Violations: Table of issues with suggestions
  - Concept Map: Text-based dependency visualization by week
  - Week Breakdown: Per-week concept counts and lectures
  - Recommendations: Actionable suggestions to fix issues

REQUIREMENTS:
  - jq (JSON processing)
  - .teach/concepts.json must exist (run 'teach analyze' first)

EOF
}
