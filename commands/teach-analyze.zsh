#!/usr/bin/env zsh

# teach-analyze.zsh
# Content analysis command for teaching workflow
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
#
# Phase 0: Concept extraction and prerequisite validation
# Phase 2: Report generation (--report flag)
# Phase 3: AI-powered analysis (--ai flag)
# Phase 4: Slide optimization (--slide-breaks flag)

# Source helper libraries
source "${0:A:h:h}/lib/concept-extraction.zsh"
source "${0:A:h:h}/lib/prerequisite-checker.zsh"
source "${0:A:h:h}/lib/report-generator.zsh"
source "${0:A:h:h}/lib/ai-analysis.zsh"
source "${0:A:h:h}/lib/slide-optimizer.zsh"
source "${0:A:h:h}/lib/analysis-display.zsh"

# =============================================================================
# Function: _teach_analyze
# Purpose: Main entry point for content analysis
# =============================================================================
# Arguments:
#   $1 - file_path: Path to .qmd file to analyze (or directory)
#   Options:
#     --mode strict|moderate|relaxed  Analysis strictness (default: moderate)
#     --report [FILE]                 Generate report (optional: specify filename)
#     --format markdown|json          Report format (default: markdown)
#     --summary, -s                   Show compact summary only
#     --quiet, -q                     Suppress progress indicators
#     --interactive, -i               Step through results interactively
#
# Returns:
#   0 - Success (no violations)
#   1 - Error or violations found
#
# Examples:
#   teach analyze lectures/week-05.qmd
#   teach analyze lectures/week-05.qmd --report
#   teach analyze lectures/week-05.qmd --report analysis-report.md --format json
#   teach analyze --all --report course-report.md
#   teach analyze --interactive lectures/week-05.qmd
# =============================================================================
_teach_analyze() {
    local file_path=""
    local mode="moderate"
    local generate_report=false
    local report_file=""
    local report_format="markdown"
    local summary_only=false
    local quiet=false
    local interactive=false
    local use_ai=false
    local show_costs=false
    local slide_breaks=false
    local preview_breaks=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                shift
                mode="${1:-moderate}"
                ;;
            --report)
                generate_report=true
                # Check if next arg is a filename (not starting with -)
                if [[ -n "$2" && "$2" != -* ]]; then
                    shift
                    report_file="$1"
                fi
                ;;
            --format)
                shift
                report_format="${1:-markdown}"
                ;;
            --summary|-s)
                summary_only=true
                ;;
            --quiet|-q)
                quiet=true
                ;;
            --interactive|-i)
                interactive=true
                ;;
            --ai)
                use_ai=true
                ;;
            --costs)
                show_costs=true
                ;;
            --slide-breaks)
                slide_breaks=true
                ;;
            --preview-breaks)
                preview_breaks=true
                slide_breaks=true  # preview implies analysis
                ;;
            --help|-h)
                _teach_analyze_help
                return 0
                ;;
            -*)
                echo "${FLOW_RED}Unknown option: $1${FLOW_RESET}"
                echo "Use 'teach analyze --help' for usage information"
                return 1
                ;;
            *)
                if [[ -z "$file_path" ]]; then
                    file_path="$1"
                fi
                ;;
        esac
        shift
    done

    # If interactive mode, delegate to interactive handler
    if [[ "$interactive" == "true" ]]; then
        _teach_analyze_interactive "$file_path" "$mode"
        return $?
    fi

    # If --costs only (no file needed), show cost summary
    if [[ "$show_costs" == "true" && -z "$file_path" ]]; then
        _ai_get_cost_summary "$PWD" "text"
        return 0
    fi

    # Validate arguments
    if [[ -z "$file_path" ]]; then
        echo "${FLOW_RED}Error: File path required${FLOW_RESET}"
        echo ""
        echo "Usage: teach analyze <file> [options]"
        echo ""
        echo "Examples:"
        echo "  teach analyze lectures/week-05-regression.qmd"
        echo "  teach analyze --slide-breaks lectures/week-05.qmd"
        echo "  teach analyze --interactive"
        echo ""
        echo "Run 'teach analyze --help' for full documentation."
        return 1
    fi

    # Check file exists
    if [[ ! -f "$file_path" ]]; then
        echo "${FLOW_RED}Error: File not found: $file_path${FLOW_RESET}"
        echo ""
        # Suggest alternatives
        local dir="${file_path:h}"
        [[ "$dir" == "$file_path" ]] && dir="."
        if [[ -d "$dir" ]]; then
            local -a candidates=($dir/*.qmd(N))
            if [[ ${#candidates[@]} -gt 0 ]]; then
                echo "Available .qmd files in ${dir}:"
                for f in "${candidates[@]:0:5}"; do
                    echo "  ${FLOW_BLUE}$f${FLOW_RESET}"
                done
                [[ ${#candidates[@]} -gt 5 ]] && echo "  ... and $((${#candidates[@]} - 5)) more"
            fi
        fi
        return 1
    fi

    # Validate file extension
    if [[ "${file_path:e}" != "qmd" && "${file_path:e}" != "md" ]]; then
        echo "${FLOW_YELLOW}Warning: Expected .qmd or .md file, got .${file_path:e}${FLOW_RESET}"
        echo "Analysis works best with Quarto (.qmd) files containing YAML frontmatter."
    fi

    # Check dependencies
    if ! command -v jq &>/dev/null; then
        echo "${FLOW_YELLOW}Warning: jq not installed - some features unavailable${FLOW_RESET}"
        echo "  Install: brew install jq"
    fi
    if ! command -v yq &>/dev/null; then
        echo "${FLOW_YELLOW}Warning: yq not installed - prerequisite checking limited${FLOW_RESET}"
        echo "  Install: brew install yq"
    fi

    # Show progress (unless quiet)
    [[ "$quiet" != "true" ]] && echo "${FLOW_BLUE}Analyzing: $file_path${FLOW_RESET}"
    [[ "$quiet" != "true" ]] && printf "${FLOW_BLUE}Building concept graph...${FLOW_RESET} "

    # Determine course directory from file path
    local course_dir
    if [[ "$file_path" == *"/lectures/"* ]]; then
        course_dir="${file_path%/lectures/*}"
    elif [[ "$file_path" == *"/assignments/"* ]]; then
        course_dir="${file_path%/assignments/*}"
    else
        course_dir="${file_path:h}"
    fi

    # Build concept graph (pass course directory, not file)
    local results_file
    results_file=$(_build_concept_graph "$course_dir" 2>/dev/null)

    if [[ -z "$results_file" || ! -f "$results_file" ]]; then
        [[ "$quiet" != "true" ]] && echo "${FLOW_RED}✗${FLOW_RESET}"
        echo "${FLOW_RED}Error: Failed to build concept graph${FLOW_RESET}"
        return 1
    fi

    [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓${FLOW_RESET}"
    [[ "$quiet" != "true" ]] && printf "${FLOW_BLUE}Checking prerequisites...${FLOW_RESET} "

    # Check prerequisites
    _check_prerequisites "$results_file" >/dev/null 2>&1
    local check_result=$?

    [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓${FLOW_RESET}"

    # Save concept graph to .teach/concepts.json
    mkdir -p "$course_dir/.teach" 2>/dev/null
    if [[ -d "$course_dir/.teach" ]]; then
        cp "$results_file" "$course_dir/.teach/concepts.json" 2>/dev/null
    fi

    # Phase 3: AI-powered analysis (if --ai flag)
    local ai_enhanced=false
    if [[ "$use_ai" == "true" ]]; then
        [[ "$quiet" != "true" ]] && printf "${FLOW_BLUE}Running AI analysis...${FLOW_RESET} "

        local existing_concepts
        existing_concepts=$(cat "$results_file" 2>/dev/null)

        local ai_result
        ai_result=$(_ai_analyze_file "$file_path" "$existing_concepts" "$quiet")

        if [[ -n "$ai_result" && "$ai_result" != "{}" ]]; then
            # Enhance the graph with AI data
            local enhanced_graph
            enhanced_graph=$(_ai_enhance_concept_graph "$(cat "$results_file")" "$ai_result")

            if [[ -n "$enhanced_graph" ]]; then
                echo "$enhanced_graph" > "$results_file"
                cp "$results_file" "$course_dir/.teach/concepts.json" 2>/dev/null
                ai_enhanced=true
                [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓ AI enhanced${FLOW_RESET}"
            fi
        else
            [[ "$quiet" != "true" ]] && echo "${FLOW_YELLOW}⚠ Heuristic-only${FLOW_RESET}"
        fi
    fi

    # Phase 4: Slide optimization (if --slide-breaks flag)
    local slide_data=""
    if [[ "$slide_breaks" == "true" ]]; then
        [[ "$quiet" != "true" ]] && printf "${FLOW_BLUE}Analyzing slide structure...${FLOW_RESET} "

        # Mirror source directory structure in cache
        local _relative_path="${file_path#$course_dir/}"
        local _cache_subdir="${_relative_path:h}"
        local _cache_name="${_relative_path:t:r}"
        local _slide_cache_dir="$course_dir/.teach/analysis-cache/$_cache_subdir"
        mkdir -p "$_slide_cache_dir" 2>/dev/null
        local slide_cache_file="$_slide_cache_dir/${_cache_name}-slides.json"
        local file_hash
        file_hash=$(shasum -a 256 "$file_path" 2>/dev/null | cut -d' ' -f1)

        if [[ -f "$slide_cache_file" && "$preview_breaks" != "true" ]]; then
            local cached_hash
            cached_hash=$(jq -r '.source_hash // ""' "$slide_cache_file" 2>/dev/null)
            if [[ "$cached_hash" == "$file_hash" ]]; then
                slide_data=$(cat "$slide_cache_file")
                [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓ (cached)${FLOW_RESET}"
            fi
        fi

        # Run optimization if not cached
        if [[ -z "$slide_data" || "$slide_data" == "{}" ]]; then
            local concept_graph_content
            concept_graph_content=$(cat "$results_file" 2>/dev/null)

            slide_data=$(_slide_optimize "$file_path" "$concept_graph_content" "$quiet")

            if [[ -n "$slide_data" && "$slide_data" != "{}" ]]; then
                # Store slide optimization in cache with source hash
                if [[ -d "$course_dir/.teach" ]] || mkdir -p "$course_dir/.teach" 2>/dev/null; then
                    if command -v jq &>/dev/null; then
                        echo "$slide_data" | jq --arg hash "$file_hash" '. + {source_hash: $hash}' > "$slide_cache_file" 2>/dev/null
                    else
                        echo "$slide_data" > "$slide_cache_file" 2>/dev/null
                    fi
                fi
                [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓${FLOW_RESET}"
            else
                [[ "$quiet" != "true" ]] && echo "${FLOW_YELLOW}⚠ No suggestions${FLOW_RESET}"
            fi
        fi

        # If --preview-breaks, show preview and exit
        if [[ "$preview_breaks" == "true" && -n "$slide_data" ]]; then
            _slide_preview_breaks "$slide_data"
            return 0
        fi
    fi

    # Generate report if requested
    if [[ "$generate_report" == "true" ]]; then
        [[ "$quiet" != "true" ]] && printf "${FLOW_BLUE}Generating report...${FLOW_RESET} "

        # Default report filename if not specified
        if [[ -z "$report_file" ]]; then
            local timestamp
            timestamp=$(date +"%Y%m%d-%H%M%S")
            if [[ "$report_format" == "json" ]]; then
                report_file="$course_dir/.teach/reports/analysis-${timestamp}.json"
            else
                report_file="$course_dir/.teach/reports/analysis-${timestamp}.md"
            fi
        fi

        # Generate report
        local report_args=("$course_dir" "--format" "$report_format" "--output" "$report_file")
        [[ "$summary_only" == "true" ]] && report_args+=("--summary-only")

        if _report_generate "${report_args[@]}" 2>/dev/null; then
            [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓${FLOW_RESET}"
            [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}Report saved to: $report_file${FLOW_RESET}"
        else
            [[ "$quiet" != "true" ]] && echo "${FLOW_YELLOW}⚠${FLOW_RESET}"
            echo "${FLOW_YELLOW}Warning: Report generation failed${FLOW_RESET}"
        fi
    fi

    # Skip display if summary only with report
    if [[ "$summary_only" == "true" && "$generate_report" == "true" ]]; then
        return $check_result
    fi

    echo ""

    # Display results
    local phase_label
    if [[ "$slide_breaks" == "true" ]]; then
        phase_label="Phase: 4 (slide-optimized)"
    elif [[ "$ai_enhanced" == "true" ]]; then
        phase_label="Phase: 3 (AI-enhanced)"
    else
        phase_label="Phase: 0 (heuristic-only)"
    fi
    _display_analysis_header "Content Analysis Report - ${file_path:t}" "Mode: $mode | $phase_label"

    _display_concepts_section "$results_file"

    # Show AI-enhanced fields if available
    if [[ "$ai_enhanced" == "true" ]]; then
        _display_ai_section "$results_file"
    fi

    # Show slide optimization results if available
    if [[ "$slide_breaks" == "true" && -n "$slide_data" && "$slide_data" != "{}" ]]; then
        _display_slide_section "$slide_data"
    fi

    _display_prerequisites_section "$results_file"
    local prereq_exit=$?

    _display_violations_section "$results_file"

    _display_summary_section "$results_file" "$prereq_exit"

    # Show cost summary if requested
    if [[ "$show_costs" == "true" ]]; then
        echo ""
        echo "${FLOW_BLUE}💰 AI ANALYSIS COSTS${FLOW_RESET}"
        _ai_get_cost_summary "$course_dir" "text"
    fi

    echo ""

    # Return exit code (0 for success, 1 for errors)
    return $prereq_exit
}

# =============================================================================
# Function: _teach_analyze_help
# Purpose: Display help for teach analyze command
# =============================================================================
_teach_analyze_help() {
    cat << 'EOF'
teach analyze - Content Analysis for Teaching Workflow
=======================================================

Analyze course content for concept coverage and prerequisite validation.

USAGE:
  teach analyze <file> [options]
  teach analyze --all [options]
  teach analyze --interactive [file]

ARGUMENTS:
  <file>              Path to .qmd file to analyze

CORE OPTIONS:
  --mode MODE         Analysis strictness: strict|moderate|relaxed (default: moderate)
  --summary, -s       Show compact summary only
  --quiet, -q         Suppress progress indicators
  --interactive, -i   Step through results interactively (ADHD-friendly)

REPORT OPTIONS (Phase 2):
  --report [FILE]     Generate analysis report (optional: specify filename)
  --format FORMAT     Report format: markdown|json (default: markdown)

AI OPTIONS (Phase 3):
  --ai                Enable AI-powered analysis (requires Claude CLI)
  --costs             Show AI analysis cost summary

SLIDE OPTIONS (Phase 4):
  --slide-breaks      Analyze for optimal slide structure
  --preview-breaks    Show suggested slide breaks (detailed preview, then exit)

EXAMPLES:
  # Basic analysis
  teach analyze lectures/week-05-regression.qmd

  # Interactive mode (guided prompts, step-by-step review)
  teach analyze --interactive
  teach analyze -i lectures/week-05-regression.qmd

  # With strictness mode
  teach analyze lectures/week-05-regression.qmd --mode strict

  # Generate markdown report
  teach analyze lectures/week-05-regression.qmd --report

  # Generate JSON report with custom filename
  teach analyze lectures/week-05-regression.qmd --report report.json --format json

  # Quick summary only
  teach analyze lectures/week-05-regression.qmd --summary

  # Silent analysis with report
  teach analyze lectures/week-05-regression.qmd --quiet --report analysis.md

  # AI-powered analysis (Phase 3)
  teach analyze --ai lectures/week-05-regression.qmd
  teach analyze --ai --costs lectures/week-05-regression.qmd

  # Show AI cost summary only
  teach analyze --costs

  # Slide optimization (Phase 4)
  teach analyze --slide-breaks lectures/week-05-regression.qmd
  teach analyze --preview-breaks lectures/week-05-regression.qmd

INTERACTIVE MODE:
  The --interactive flag provides an ADHD-friendly guided experience:

  1. Select analysis scope (file, week, or entire course)
  2. Choose strictness mode (relaxed, moderate, strict)
  3. Watch real-time progress
  4. Review issues one-by-one with fix suggestions
  5. Get clear next steps

REPORT SECTIONS:
  - Summary: Concept count, week count, violations, coverage percentage
  - Prerequisite Violations: Table of issues with suggestions
  - Concept Map: Text-based dependency visualization by week
  - Week Breakdown: Per-week concept counts and lectures
  - Recommendations: Actionable suggestions to fix issues

FRONTMATTER FORMAT:
  Add to your .qmd files:

  ---
  title: 'Linear Regression'
  week: 5
  concepts:
    introduces:
      - regression-basics
      - residual-analysis
    requires:
      - correlation
      - variance
  ---

REQUIREMENTS:
  - jq (JSON processing)
  - yq (YAML processing)

SEE ALSO:
  teach validate    Syntax and render validation
  teach status      Project status overview
  teach deploy      Deploy to GitHub Pages

EOF
}

# =============================================================================
# Function: _teach_analyze_interactive
# Purpose: Interactive mode for step-by-step content analysis
# =============================================================================
# Arguments:
#   $1 - file_path: Path to .qmd file to analyze (optional)
#   $2 - mode: Analysis strictness (default: moderate)
#
# Returns:
#   0 - Success (no violations or all reviewed)
#   1 - Error or violations found
#
# Example:
#   _teach_analyze_interactive lectures/week-05.qmd
#   _teach_analyze_interactive "" moderate
# =============================================================================
_teach_analyze_interactive() {
    local file_path="$1"
    local mode="${2:-moderate}"
    local scope="file"
    local course_dir=""

    # Display interactive header
    _interactive_header

    # Step 1: Select analysis scope
    if [[ -z "$file_path" ]]; then
        scope=$(_interactive_select_scope)
        [[ -z "$scope" ]] && return 1
    fi

    # Step 2: Select strictness mode
    mode=$(_interactive_select_mode "$mode")
    [[ -z "$mode" ]] && return 1

    # Step 3: Determine files to analyze based on scope
    local -a files_to_analyze
    case "$scope" in
        file)
            if [[ -z "$file_path" ]]; then
                file_path=$(_interactive_select_file)
                [[ -z "$file_path" ]] && return 1
            fi
            files_to_analyze=("$file_path")
            ;;
        week)
            local week_num
            week_num=$(_interactive_select_week)
            [[ -z "$week_num" ]] && return 1
            files_to_analyze=($(_get_files_for_week "$week_num"))
            ;;
        course)
            files_to_analyze=($(_get_all_course_files))
            ;;
    esac

    if [[ ${#files_to_analyze[@]} -eq 0 ]]; then
        echo ""
        echo "${FLOW_YELLOW}No files found to analyze.${FLOW_RESET}"
        return 1
    fi

    # Step 4: Run analysis with progress
    echo ""
    echo "${FLOW_BLUE}Analyzing ${#files_to_analyze[@]} file(s)...${FLOW_RESET}"
    _interactive_progress_start

    # Determine course directory
    if [[ -n "${files_to_analyze[1]}" ]]; then
        local first_file="${files_to_analyze[1]}"
        if [[ "$first_file" == *"/lectures/"* ]]; then
            course_dir="${first_file%/lectures/*}"
        elif [[ "$first_file" == *"/assignments/"* ]]; then
            course_dir="${first_file%/assignments/*}"
        else
            course_dir="${first_file:h}"
        fi
    else
        course_dir="$PWD"
    fi

    # Build concept graph
    local results_file
    results_file=$(_build_concept_graph "$course_dir" 2>/dev/null)

    if [[ -z "$results_file" || ! -f "$results_file" ]]; then
        _interactive_progress_fail
        echo "${FLOW_RED}Error: Failed to build concept graph${FLOW_RESET}"
        return 1
    fi

    # Save to .teach/concepts.json
    mkdir -p "$course_dir/.teach" 2>/dev/null
    if [[ -d "$course_dir/.teach" ]]; then
        cp "$results_file" "$course_dir/.teach/concepts.json" 2>/dev/null
    fi

    _interactive_progress_done

    # Step 5: Display results progressively
    echo ""
    _interactive_display_results "$results_file" "$mode"
    local analysis_result=$?

    # Step 6: Review violations interactively
    if [[ $analysis_result -ne 0 ]]; then
        echo ""
        _interactive_review_violations "$results_file" "$course_dir"
    fi

    # Step 7: Show next steps
    echo ""
    _interactive_next_steps "$analysis_result"

    return $analysis_result
}

# =============================================================================
# Interactive Helper Functions
# =============================================================================

_interactive_header() {
    echo ""
    echo "${FLOW_BLUE}╭─────────────────────────────────────────────────────╮${FLOW_RESET}"
    echo "${FLOW_BLUE}│${FLOW_RESET}${FLOW_BOLD}   Intelligent Content Analysis (Interactive)${FLOW_RESET}       ${FLOW_BLUE}│${FLOW_RESET}"
    echo "${FLOW_BLUE}╰─────────────────────────────────────────────────────╯${FLOW_RESET}"
    echo ""
}

_interactive_select_scope() {
    echo "${FLOW_BOLD}Select analysis scope:${FLOW_RESET}"
    echo ""
    echo "  ${FLOW_GREEN}1)${FLOW_RESET} Current file only"
    echo "  ${FLOW_GREEN}2)${FLOW_RESET} Specific week"
    echo "  ${FLOW_GREEN}3)${FLOW_RESET} Entire course"
    echo "  ${FLOW_GREEN}q)${FLOW_RESET} Cancel"
    echo ""

    local choice
    printf "${FLOW_BLUE}Select [1-3]: ${FLOW_RESET}"
    read -r choice

    case "$choice" in
        1) echo "file" ;;
        2) echo "week" ;;
        3) echo "course" ;;
        q|Q) return 1 ;;
        *)
            echo "${FLOW_YELLOW}Invalid choice, defaulting to 'file'${FLOW_RESET}" >&2
            echo "file"
            ;;
    esac
}

_interactive_select_mode() {
    local current_mode="${1:-moderate}"

    echo ""
    echo "${FLOW_BOLD}Select strictness mode:${FLOW_RESET}"
    echo ""

    local relaxed_marker="" moderate_marker="" strict_marker=""
    case "$current_mode" in
        relaxed)  relaxed_marker=" ${FLOW_GREEN}(current)${FLOW_RESET}" ;;
        moderate) moderate_marker=" ${FLOW_GREEN}(current)${FLOW_RESET}" ;;
        strict)   strict_marker=" ${FLOW_GREEN}(current)${FLOW_RESET}" ;;
    esac

    echo "  ${FLOW_GREEN}1)${FLOW_RESET} Relaxed  - Warnings only${relaxed_marker}"
    echo "  ${FLOW_GREEN}2)${FLOW_RESET} Moderate - Default balance${moderate_marker}"
    echo "  ${FLOW_GREEN}3)${FLOW_RESET} Strict   - All issues${strict_marker}"
    echo "  ${FLOW_GREEN}q)${FLOW_RESET} Cancel"
    echo ""

    local choice
    printf "${FLOW_BLUE}Select [1-3, Enter for current]: ${FLOW_RESET}"
    read -r choice

    case "$choice" in
        1) echo "relaxed" ;;
        2) echo "moderate" ;;
        3) echo "strict" ;;
        q|Q) return 1 ;;
        "") echo "$current_mode" ;;  # Keep current
        *)
            echo "${FLOW_YELLOW}Invalid choice, using '$current_mode'${FLOW_RESET}" >&2
            echo "$current_mode"
            ;;
    esac
}

_interactive_select_file() {
    local lectures_dir="$PWD/lectures"

    if [[ ! -d "$lectures_dir" ]]; then
        # Try to find lectures directory
        if [[ -d "./lectures" ]]; then
            lectures_dir="./lectures"
        else
            echo "${FLOW_YELLOW}No lectures directory found. Enter file path:${FLOW_RESET}" >&2
            local file_input
            printf "${FLOW_BLUE}File path: ${FLOW_RESET}"
            read -r file_input
            if [[ -f "$file_input" ]]; then
                echo "$file_input"
            else
                echo "${FLOW_RED}File not found: $file_input${FLOW_RESET}" >&2
                return 1
            fi
            return 0
        fi
    fi

    # List available .qmd files
    echo ""
    echo "${FLOW_BOLD}Available files:${FLOW_RESET}"
    echo ""

    local -a qmd_files
    qmd_files=($(find "$lectures_dir" -name "*.qmd" -type f 2>/dev/null | sort))

    if [[ ${#qmd_files[@]} -eq 0 ]]; then
        echo "${FLOW_YELLOW}No .qmd files found in lectures directory${FLOW_RESET}" >&2
        return 1
    fi

    local i=1
    for f in "${qmd_files[@]}"; do
        local filename="${f:t}"
        echo "  ${FLOW_GREEN}$i)${FLOW_RESET} $filename"
        ((i++))
    done
    echo "  ${FLOW_GREEN}q)${FLOW_RESET} Cancel"
    echo ""

    local choice
    printf "${FLOW_BLUE}Select file [1-${#qmd_files[@]}]: ${FLOW_RESET}"
    read -r choice

    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        return 1
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#qmd_files[@]} ]]; then
        echo "${qmd_files[$choice]}"
    else
        echo "${FLOW_YELLOW}Invalid choice${FLOW_RESET}" >&2
        return 1
    fi
}

_interactive_select_week() {
    echo ""
    echo "${FLOW_BOLD}Enter week number:${FLOW_RESET}"
    echo ""

    local week_num
    printf "${FLOW_BLUE}Week number (1-15): ${FLOW_RESET}"
    read -r week_num

    if [[ "$week_num" =~ ^[0-9]+$ ]] && [[ "$week_num" -ge 1 ]] && [[ "$week_num" -le 15 ]]; then
        echo "$week_num"
    else
        echo "${FLOW_YELLOW}Invalid week number${FLOW_RESET}" >&2
        return 1
    fi
}

_get_files_for_week() {
    local week_num="$1"
    local lectures_dir="${PWD}/lectures"

    # Format week number with leading zero if needed
    local week_pattern
    if [[ "$week_num" -lt 10 ]]; then
        week_pattern="week-0${week_num}"
    else
        week_pattern="week-${week_num}"
    fi

    find "$lectures_dir" -name "*${week_pattern}*.qmd" -type f 2>/dev/null | sort
}

_get_all_course_files() {
    local lectures_dir="${PWD}/lectures"
    find "$lectures_dir" -name "*.qmd" -type f 2>/dev/null | sort
}

_interactive_progress_start() {
    printf "  ${FLOW_BLUE}Building concept graph...${FLOW_RESET} "
}

_interactive_progress_done() {
    echo "${FLOW_GREEN}Done${FLOW_RESET}"
}

_interactive_progress_fail() {
    echo "${FLOW_RED}Failed${FLOW_RESET}"
}

_interactive_display_results() {
    local results_file="$1"
    local mode="$2"

    # Count concepts and violations
    local concept_count=0
    local violation_count=0
    local warning_count=0
    local error_count=0

    if command -v jq >/dev/null 2>&1; then
        concept_count=$(jq -r '.metadata.total_concepts // 0' "$results_file" 2>/dev/null)

        # Count violations by iterating through concepts
        local violations_json
        violations_json=$(jq -r '
            [.concepts | to_entries[] |
             select(.value.prerequisites | length > 0) |
             .value.prerequisites[] as $prereq |
             select(
                 (.value.introduced_in.week as $week |
                  [.concepts | to_entries[] |
                   select(.value.id == $prereq) |
                   .value.introduced_in.week] |
                  if length > 0 then .[0] > $week else true end)
             )
            ] | length
        ' "$results_file" 2>/dev/null)

        violation_count="${violations_json:-0}"
    fi

    # Display summary
    echo "${FLOW_BLUE}╭─────────────────────────────────────────────────────╮${FLOW_RESET}"
    echo "${FLOW_BLUE}│${FLOW_RESET}${FLOW_BOLD}                   Analysis Results                 ${FLOW_RESET}${FLOW_BLUE}│${FLOW_RESET}"
    echo "${FLOW_BLUE}╰─────────────────────────────────────────────────────╯${FLOW_RESET}"
    echo ""

    echo "  ${FLOW_BOLD}Concepts found:${FLOW_RESET}     ${FLOW_GREEN}$concept_count${FLOW_RESET}"

    if [[ "$violation_count" -gt 0 ]]; then
        echo "  ${FLOW_BOLD}Issues found:${FLOW_RESET}       ${FLOW_YELLOW}$violation_count${FLOW_RESET}"
        return 1
    else
        echo "  ${FLOW_BOLD}Issues found:${FLOW_RESET}       ${FLOW_GREEN}0${FLOW_RESET}"
        echo ""
        echo "  ${FLOW_GREEN}All prerequisites satisfied.${FLOW_RESET}"
        return 0
    fi
}

_interactive_review_violations() {
    local results_file="$1"
    local course_dir="$2"

    echo ""
    echo "${FLOW_BOLD}Review issues:${FLOW_RESET}"
    echo ""

    # Get concepts with prerequisite issues
    local -a violations
    local i=1

    if command -v jq >/dev/null 2>&1; then
        # Find concepts that have prerequisites from later weeks or missing
        while IFS= read -r violation_line; do
            [[ -z "$violation_line" ]] && continue

            local concept_id prereq_id concept_week prereq_week
            concept_id=$(echo "$violation_line" | jq -r '.concept_id' 2>/dev/null)
            prereq_id=$(echo "$violation_line" | jq -r '.prereq_id' 2>/dev/null)
            concept_week=$(echo "$violation_line" | jq -r '.concept_week' 2>/dev/null)
            prereq_week=$(echo "$violation_line" | jq -r '.prereq_week' 2>/dev/null)

            [[ -z "$concept_id" || "$concept_id" == "null" ]] && continue

            # Display violation
            echo ""
            echo "  ${FLOW_YELLOW}$i.${FLOW_RESET} ${FLOW_BOLD}Prerequisite Issue${FLOW_RESET}"

            if [[ "$prereq_week" == "null" || -z "$prereq_week" ]]; then
                echo "     ${FLOW_RED}Missing prerequisite:${FLOW_RESET} '$prereq_id'"
                echo "     ${FLOW_BLUE}Used by:${FLOW_RESET} '$concept_id' (Week $concept_week)"
                echo ""
                echo "     ${FLOW_GREEN}Suggestion:${FLOW_RESET} Add '$prereq_id' to an earlier week"
            else
                echo "     ${FLOW_YELLOW}Future prerequisite:${FLOW_RESET} '$prereq_id' (Week $prereq_week)"
                echo "     ${FLOW_BLUE}Used by:${FLOW_RESET} '$concept_id' (Week $concept_week)"
                echo ""
                echo "     ${FLOW_GREEN}Suggestion:${FLOW_RESET} Move '$prereq_id' to Week $((concept_week - 1)) or earlier"
            fi

            # Ask for action
            echo ""
            printf "     ${FLOW_BLUE}Action: [s]kip, [n]ote, [q]uit review: ${FLOW_RESET}"

            local action
            read -r action

            case "$action" in
                s|S|"")
                    echo "     ${FLOW_YELLOW}Skipped${FLOW_RESET}"
                    ;;
                n|N)
                    printf "     ${FLOW_BLUE}Note: ${FLOW_RESET}"
                    local note
                    read -r note
                    echo "     ${FLOW_GREEN}Note saved${FLOW_RESET} (for future reference)"
                    ;;
                q|Q)
                    echo "     ${FLOW_YELLOW}Review ended${FLOW_RESET}"
                    return 0
                    ;;
            esac

            ((i++))
        done <<< "$(jq -c '
            .concepts | to_entries[] |
            select(.value.prerequisites | length > 0) |
            .value as $concept |
            .value.prerequisites[] as $prereq |
            {
                concept_id: $concept.id,
                concept_week: $concept.introduced_in.week,
                prereq_id: $prereq,
                prereq_week: null
            }
        ' "$results_file" 2>/dev/null)"
    fi

    if [[ $i -eq 1 ]]; then
        echo "  ${FLOW_GREEN}No issues to review.${FLOW_RESET}"
    else
        echo ""
        echo "  ${FLOW_BLUE}Review complete.${FLOW_RESET} Reviewed $((i-1)) issue(s)."
    fi
}

_interactive_next_steps() {
    local analysis_result="$1"

    echo "${FLOW_BLUE}╭─────────────────────────────────────────────────────╮${FLOW_RESET}"
    echo "${FLOW_BLUE}│${FLOW_RESET}${FLOW_BOLD}                    Next Steps                      ${FLOW_RESET}${FLOW_BLUE}│${FLOW_RESET}"
    echo "${FLOW_BLUE}╰─────────────────────────────────────────────────────╯${FLOW_RESET}"
    echo ""

    if [[ "$analysis_result" -eq 0 ]]; then
        echo "  ${FLOW_GREEN}Status: Ready to deploy${FLOW_RESET}"
        echo ""
        echo "  ${FLOW_BOLD}1.${FLOW_RESET} Preview changes:  ${FLOW_BLUE}teach deploy --preview${FLOW_RESET}"
        echo "  ${FLOW_BOLD}2.${FLOW_RESET} Deploy content:   ${FLOW_BLUE}teach deploy${FLOW_RESET}"
        echo "  ${FLOW_BOLD}3.${FLOW_RESET} Continue editing: ${FLOW_BLUE}quarto preview${FLOW_RESET}"
    else
        echo "  ${FLOW_YELLOW}Status: Review required${FLOW_RESET}"
        echo ""
        echo "  ${FLOW_BOLD}1.${FLOW_RESET} Fix prerequisite issues in your content"
        echo "  ${FLOW_BOLD}2.${FLOW_RESET} Re-run analysis:  ${FLOW_BLUE}teach analyze --interactive${FLOW_RESET}"
        echo "  ${FLOW_BOLD}3.${FLOW_RESET} Generate report:  ${FLOW_BLUE}teach analyze --report${FLOW_RESET}"
    fi
    echo ""
}
