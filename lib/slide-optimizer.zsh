#!/usr/bin/env zsh

# =============================================================================
# lib/slide-optimizer.zsh
# Slide structure optimization for teach analyze Phase 4
# Analyzes lecture content to suggest optimal slide breaks and key concepts
# =============================================================================
#
# Features:
#   - Concept boundary detection (beyond H2/H3 headers)
#   - Key concept identification for callout emphasis
#   - Presentation time estimation per section
#   - Slide break suggestions with rationale
#   - Integration with analysis cache (slide_breaks, key_concepts_for_emphasis)
#   - Preview mode for reviewing suggestions before applying
#
# =============================================================================

# Disable zsh options that cause variable assignments to print
unsetopt local_options 2>/dev/null
unsetopt print_exit_value 2>/dev/null
setopt NO_local_options 2>/dev/null

# Source core library if not already loaded
if ! typeset -f _flow_log_debug >/dev/null 2>&1; then
    source "${0:A:h}/core.zsh" 2>/dev/null || true
fi

# =============================================================================
# CONSTANTS
# =============================================================================

# Estimated minutes per slide (for time estimation)
(( ${+SLIDE_MINUTES_PER_CONTENT} )) || readonly SLIDE_MINUTES_PER_CONTENT=2
(( ${+SLIDE_MINUTES_PER_CODE} )) || readonly SLIDE_MINUTES_PER_CODE=3
(( ${+SLIDE_MINUTES_PER_EXAMPLE} )) || readonly SLIDE_MINUTES_PER_EXAMPLE=4

# Minimum content density for a slide break suggestion (words)
(( ${+SLIDE_MIN_SECTION_WORDS} )) || readonly SLIDE_MIN_SECTION_WORDS=80

# Maximum content per slide before suggesting a break (words)
(( ${+SLIDE_MAX_SECTION_WORDS} )) || readonly SLIDE_MAX_SECTION_WORDS=300

# =============================================================================
# Function: _slide_analyze_structure
# Purpose: Analyze a lecture file's structure for slide optimization
# Arguments:
#   $1 - file_path: Path to lecture .qmd file
# Returns: JSON with structure analysis
# =============================================================================
_slide_analyze_structure() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "{}"
        return 1
    fi

    local -a sections=()
    local current_heading=""
    local current_level=0
    local current_content=""
    local line_num=0
    local in_frontmatter=false
    local frontmatter_count=0
    local in_code_block=false

    # Parse file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        (( line_num++ ))

        # Track YAML frontmatter
        if [[ "$line" == "---" ]]; then
            if [[ $frontmatter_count -lt 2 ]]; then
                (( frontmatter_count++ ))
                if [[ $frontmatter_count -eq 1 ]]; then
                    in_frontmatter=true
                else
                    in_frontmatter=false
                fi
                continue
            fi
        fi
        [[ "$in_frontmatter" == "true" ]] && continue

        # Track code blocks
        if [[ "$line" == '```'* ]]; then
            if [[ "$in_code_block" == "true" ]]; then
                in_code_block=false
            else
                in_code_block=true
            fi
            current_content+="$line"$'\n'
            continue
        fi
        [[ "$in_code_block" == "true" ]] && { current_content+="$line"$'\n'; continue; }

        # Detect headings
        if [[ "$line" =~ '^(#{1,4}) (.+)$' ]]; then
            local hashes="${match[1]}"
            local heading_text="${match[2]}"
            local level=${#hashes}

            # Save previous section if exists
            if [[ -n "$current_heading" ]]; then
                sections+=("${current_level}|${current_heading}|${current_content}")
            fi

            current_heading="$heading_text"
            current_level=$level
            current_content=""
        else
            current_content+="$line"$'\n'
        fi
    done < "$file_path"

    # Save last section
    if [[ -n "$current_heading" ]]; then
        sections+=("${current_level}|${current_heading}|${current_content}")
    fi

    # Build JSON output
    local json_output='{"sections":['
    local first=true

    for section in "${sections[@]}"; do
        local level="${section%%|*}"
        local rest="${section#*|}"
        local heading="${rest%%|*}"
        local content="${rest#*|}"

        # Calculate metrics
        local word_count=$(echo "$content" | wc -w | tr -d '[:space:]')
        local code_chunks=$(echo "$content" | grep -c '```{' 2>/dev/null || true)
        code_chunks=${code_chunks//[^0-9]/}
        : ${code_chunks:=0}
        local callouts=$(echo "$content" | grep -c '::: {.callout' 2>/dev/null || true)
        callouts=${callouts//[^0-9]/}
        : ${callouts:=0}
        local examples=$(echo "$content" | grep -ci 'example\|for instance\|consider\|suppose' 2>/dev/null || true)
        examples=${examples//[^0-9]/}
        : ${examples:=0}
        local definitions=$(echo "$content" | grep -ci 'definition\|defined as\|is called\|refers to' 2>/dev/null || true)
        definitions=${definitions//[^0-9]/}
        : ${definitions:=0}

        [[ "$first" == "true" ]] && first=false || json_output+=','

        # Escape heading for JSON
        heading="${heading//\"/\\\"}"

        json_output+="{\"level\":$level,\"heading\":\"$heading\",\"word_count\":$word_count,\"code_chunks\":$code_chunks,\"callouts\":$callouts,\"examples\":$examples,\"definitions\":$definitions}"
    done

    json_output+='],"total_sections":'${#sections[@]}'}'
    echo "$json_output"
}

# =============================================================================
# Function: _slide_suggest_breaks
# Purpose: Suggest slide breaks based on content analysis
# Arguments:
#   $1 - structure_json: Output from _slide_analyze_structure
#   $2 - concept_graph: JSON concept graph from teach analyze
# Returns: JSON array of slide break suggestions
# =============================================================================
_slide_suggest_breaks() {
    local structure_json="$1"
    local concept_graph="${2:-{}}"

    if [[ -z "$structure_json" || "$structure_json" == "{}" ]]; then
        echo "[]"
        return 0
    fi

    local suggestions='['
    local first=true
    local section_idx=0

    # Extract sections using lightweight parsing
    local sections_array
    sections_array=$(echo "$structure_json" | _slide_extract_sections)

    # Parse each section
    while IFS='|' read -r level heading word_count code_chunks examples definitions; do
        [[ -z "$heading" ]] && continue
        (( section_idx++ ))

        local needs_break=false
        local reason=""
        local priority="medium"

        # Rule 1: Long sections need breaks
        if [[ $word_count -gt $SLIDE_MAX_SECTION_WORDS ]]; then
            needs_break=true
            reason="Section exceeds ${SLIDE_MAX_SECTION_WORDS} words (${word_count}w) - split for readability"
            priority="high"
        fi

        # Rule 2: Sections with multiple code chunks
        if [[ $code_chunks -gt 2 ]]; then
            needs_break=true
            reason="${reason:+$reason; }Multiple code examples ($code_chunks) - separate into individual slides"
            priority="high"
        fi

        # Rule 3: Sections with definitions + examples (concept boundary)
        if [[ $definitions -gt 0 && $examples -gt 0 && $word_count -gt $SLIDE_MIN_SECTION_WORDS ]]; then
            needs_break=true
            reason="${reason:+$reason; }Contains definitions and examples - separate concept intro from application"
            [[ "$priority" != "high" ]] && priority="medium"
        fi

        # Rule 4: H2 sections with many words but no subsections
        if [[ $level -eq 2 && $word_count -gt 150 && $code_chunks -eq 0 ]]; then
            needs_break=true
            reason="${reason:+$reason; }Dense text section without code - add visual breaks"
            [[ "$priority" == "medium" ]] && priority="low"
        fi

        if [[ "$needs_break" == "true" ]]; then
            [[ "$first" == "true" ]] && first=false || suggestions+=','

            # Escape strings for JSON
            heading="${heading//\"/\\\"}"
            reason="${reason//\"/\\\"}"

            # Estimate sub-slides needed
            local sub_slides=2
            [[ $word_count -gt 400 ]] && sub_slides=3
            [[ $code_chunks -gt 3 ]] && sub_slides=$((code_chunks))

            suggestions+="{\"section\":\"$heading\",\"reason\":\"$reason\",\"priority\":\"$priority\",\"suggested_sub_slides\":$sub_slides,\"word_count\":$word_count}"
        fi
    done <<< "$sections_array"

    suggestions+=']'
    echo "$suggestions"
}

# =============================================================================
# Function: _slide_extract_sections
# Purpose: Extract sections from structure JSON into pipe-delimited format
# stdin: structure_json
# Returns: pipe-delimited lines: level|heading|word_count|code_chunks|examples|definitions
# =============================================================================
_slide_extract_sections() {
    local json
    json=$(cat)

    # Use jq if available, otherwise basic parsing
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r '.sections[] | "\(.level)|\(.heading)|\(.word_count)|\(.code_chunks)|\(.examples)|\(.definitions)"' 2>/dev/null
    else
        # Basic regex extraction for each section object
        echo "$json" | tr ',' '\n' | while IFS= read -r chunk; do
            if [[ "$chunk" =~ '"level":([0-9]+)' ]]; then
                local level="${match[1]}"
            fi
            if [[ "$chunk" =~ '"heading":"([^"]*)"' ]]; then
                local heading="${match[1]}"
            fi
            if [[ "$chunk" =~ '"word_count":([0-9]+)' ]]; then
                local wc="${match[1]}"
            fi
            if [[ "$chunk" =~ '"code_chunks":([0-9]+)' ]]; then
                local cc="${match[1]}"
            fi
            if [[ "$chunk" =~ '"examples":([0-9]+)' ]]; then
                local ex="${match[1]}"
            fi
            if [[ "$chunk" =~ '"definitions":([0-9]+)' ]]; then
                local def="${match[1]}"
                echo "${level:-0}|${heading:-}|${wc:-0}|${cc:-0}|${ex:-0}|${def:-0}"
            fi
        done
    fi
}

# =============================================================================
# Function: _slide_identify_key_concepts
# Purpose: Identify key concepts that should be emphasized with callouts
# Arguments:
#   $1 - file_path: Path to lecture .qmd file
#   $2 - concept_graph: JSON concept graph from teach analyze
# Returns: JSON array of key concepts for emphasis
# =============================================================================
_slide_identify_key_concepts() {
    local file_path="$1"
    local concept_graph="${2:-{}}"

    if [[ ! -f "$file_path" ]]; then
        echo "[]"
        return 1
    fi

    local concepts='['
    local first=true

    # Strategy 1: Extract from concept graph (highest confidence)
    if [[ -n "$concept_graph" && "$concept_graph" != "{}" ]]; then
        local graph_concepts
        if command -v jq &>/dev/null; then
            graph_concepts=$(echo "$concept_graph" | jq -r '.concepts[]? | select(.introduced == true) | .name // .id' 2>/dev/null)
        fi

        if [[ -n "$graph_concepts" ]]; then
            while IFS= read -r concept_name; do
                [[ -z "$concept_name" ]] && continue
                [[ "$first" == "true" ]] && first=false || concepts+=','
                concept_name="${concept_name//\"/\\\"}"
                concepts+="{\"name\":\"$concept_name\",\"source\":\"concept_graph\",\"emphasis\":\"callout-tip\"}"
            done <<< "$graph_concepts"
        fi
    fi

    # Strategy 2: Detect definitions and theorems in content
    local -a definition_lines=()
    while IFS= read -r line; do
        # Match common definition patterns (check for keyword at start or after **)
        local matched_def=false
        case "$line" in
            *Definition*:*|*Theorem*:*|*Lemma*:*|*Property*:*|*Principle*:*|"Key Idea"*:*|*Important*:*)
                matched_def=true
                ;;
        esac
        if [[ "$matched_def" == "true" ]]; then
            local concept_text="${line##*: }"
            concept_text="${concept_text:0:80}"  # Truncate
            concept_text="${concept_text//\"/\\\"}"
            [[ "$first" == "true" ]] && first=false || concepts+=','
            concepts+="{\"name\":\"$concept_text\",\"source\":\"content_pattern\",\"emphasis\":\"callout-important\"}"
        fi
    done < "$file_path"

    # Strategy 3: Detect emphasized terms (bold/italic definitions)
    local -a bold_terms=()
    while IFS= read -r line; do
        if [[ "$line" =~ '\*\*([^*]+)\*\*' ]]; then
            local term="${match[1]}"
            # Only include if it looks like a concept (2-5 words, starts with capital)
            local wc=$(echo "$term" | wc -w | tr -d ' ')
            if [[ $wc -ge 2 && $wc -le 5 && "$term" =~ '^[A-Z]' ]]; then
                term="${term//\"/\\\"}"
                [[ "$first" == "true" ]] && first=false || concepts+=','
                concepts+="{\"name\":\"$term\",\"source\":\"emphasis_pattern\",\"emphasis\":\"callout-note\"}"
            fi
        fi
    done < "$file_path"

    concepts+=']'
    echo "$concepts"
}

# =============================================================================
# Function: _slide_estimate_time
# Purpose: Estimate presentation time for lecture content
# Arguments:
#   $1 - structure_json: Output from _slide_analyze_structure
# Returns: JSON with time estimates per section and total
# =============================================================================
_slide_estimate_time() {
    local structure_json="$1"

    if [[ -z "$structure_json" || "$structure_json" == "{}" ]]; then
        echo '{"total_minutes":0,"sections":[]}'
        return 0
    fi

    local total_minutes=0
    local time_sections='['
    local first=true

    local sections_array
    sections_array=$(echo "$structure_json" | _slide_extract_sections)

    while IFS='|' read -r level heading word_count code_chunks examples definitions; do
        [[ -z "$heading" ]] && continue

        # Calculate time: content + code + examples
        local content_time=$(( (word_count / 150) * SLIDE_MINUTES_PER_CONTENT ))
        [[ $content_time -lt 1 ]] && content_time=1
        local code_time=$(( code_chunks * SLIDE_MINUTES_PER_CODE ))
        local example_time=$(( examples * SLIDE_MINUTES_PER_EXAMPLE / 2 ))  # Half since some overlap
        local section_time=$(( content_time + code_time + example_time ))

        total_minutes=$(( total_minutes + section_time ))

        [[ "$first" == "true" ]] && first=false || time_sections+=','
        heading="${heading//\"/\\\"}"
        time_sections+="{\"heading\":\"$heading\",\"minutes\":$section_time}"
    done <<< "$sections_array"

    time_sections+=']'
    echo "{\"total_minutes\":$total_minutes,\"sections\":$time_sections}"
}

# =============================================================================
# Function: _slide_optimize
# Purpose: Full slide optimization combining all analyses
# Arguments:
#   $1 - file_path: Path to lecture .qmd file
#   $2 - concept_graph: JSON concept graph (optional)
#   $3 - quiet: Suppress progress output (optional)
# Returns: JSON with slide_breaks, key_concepts_for_emphasis, time_estimate
# =============================================================================
_slide_optimize() {
    local file_path="$1"
    local concept_graph="${2:-{}}"
    local quiet="${3:-false}"

    if [[ ! -f "$file_path" ]]; then
        echo "{}"
        return 1
    fi

    [[ "$quiet" != "true" ]] && echo "  📐 Analyzing structure..." >&2

    # Step 1: Analyze structure
    local structure
    structure=$(_slide_analyze_structure "$file_path")

    [[ "$quiet" != "true" ]] && echo "  🔍 Detecting slide boundaries..." >&2

    # Step 2: Suggest breaks
    local breaks
    breaks=$(_slide_suggest_breaks "$structure" "$concept_graph")

    [[ "$quiet" != "true" ]] && echo "  ⭐ Identifying key concepts..." >&2

    # Step 3: Identify key concepts
    local key_concepts
    key_concepts=$(_slide_identify_key_concepts "$file_path" "$concept_graph")

    [[ "$quiet" != "true" ]] && echo "  ⏱️  Estimating time..." >&2

    # Step 4: Estimate time
    local time_est
    time_est=$(_slide_estimate_time "$structure")

    # Combine results
    local result
    if command -v jq &>/dev/null; then
        result=$(jq -n \
            --argjson breaks "$breaks" \
            --argjson concepts "$key_concepts" \
            --argjson time "$time_est" \
            '{slide_breaks: $breaks, key_concepts_for_emphasis: $concepts, time_estimate: $time}')
    else
        result="{\"slide_breaks\":$breaks,\"key_concepts_for_emphasis\":$key_concepts,\"time_estimate\":$time_est}"
    fi

    echo "$result"
}

# =============================================================================
# Function: _slide_preview_breaks
# Purpose: Display a formatted preview of slide break suggestions
# Arguments:
#   $1 - optimization_json: Output from _slide_optimize
# Returns: Formatted text output to stdout
# =============================================================================
_slide_preview_breaks() {
    local optimization_json="$1"

    if [[ -z "$optimization_json" || "$optimization_json" == "{}" ]]; then
        echo "  No slide optimization data available."
        return 0
    fi

    local break_count=0
    local concept_count=0
    local total_time=0

    # Extract counts
    if command -v jq &>/dev/null; then
        break_count=$(echo "$optimization_json" | jq '.slide_breaks | length' 2>/dev/null || echo 0)
        concept_count=$(echo "$optimization_json" | jq '.key_concepts_for_emphasis | length' 2>/dev/null || echo 0)
        total_time=$(echo "$optimization_json" | jq '.time_estimate.total_minutes // 0' 2>/dev/null || echo 0)
    fi

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  📐 SLIDE OPTIMIZATION PREVIEW                              │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │  Break suggestions:     $break_count"
    echo "  │  Key concepts:          $concept_count"
    echo "  │  Estimated time:        ${total_time}min"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""

    # Show break suggestions
    if [[ $break_count -gt 0 ]]; then
        echo "  🔀 SUGGESTED BREAKS:"
        echo "  ─────────────────────────────────────────────"

        if command -v jq &>/dev/null; then
            echo "$optimization_json" | jq -r '.slide_breaks[] | "  [\(.priority)] \(.section)\n        → \(.reason)\n        Suggested sub-slides: \(.suggested_sub_slides)\n"' 2>/dev/null
        else
            echo "  (Install jq for detailed break preview)"
        fi
    fi

    # Show key concepts
    if [[ $concept_count -gt 0 ]]; then
        echo "  ⭐ KEY CONCEPTS FOR EMPHASIS:"
        echo "  ─────────────────────────────────────────────"

        if command -v jq &>/dev/null; then
            echo "$optimization_json" | jq -r '.key_concepts_for_emphasis[] | "  • \(.name) [\(.emphasis)]"' 2>/dev/null
        else
            echo "  (Install jq for detailed concept list)"
        fi
        echo ""
    fi

    # Show time breakdown
    if [[ $total_time -gt 0 ]]; then
        echo "  ⏱️  TIME ESTIMATE: ${total_time} minutes total"
        echo "  ─────────────────────────────────────────────"

        if command -v jq &>/dev/null; then
            echo "$optimization_json" | jq -r '.time_estimate.sections[]? | "  \(.heading): \(.minutes)min"' 2>/dev/null
        fi
        echo ""
    fi
}

# =============================================================================
# Function: _slide_apply_breaks
# Purpose: Apply slide break suggestions to a lecture file for slides generation
# Arguments:
#   $1 - file_path: Path to lecture .qmd file
#   $2 - output_file: Path to write optimized slide .qmd
#   $3 - optimization_json: Output from _slide_optimize
# Returns: 0 on success, writes optimized file
# =============================================================================
_slide_apply_breaks() {
    local file_path="$1"
    local output_file="$2"
    local optimization_json="$3"

    if [[ ! -f "$file_path" ]]; then
        return 1
    fi

    if [[ -z "$optimization_json" || "$optimization_json" == "{}" ]]; then
        # No optimization - just copy
        cp "$file_path" "$output_file"
        return 0
    fi

    # Get key concepts for callout insertion
    local -a key_concept_names=()
    if command -v jq &>/dev/null; then
        while IFS= read -r name; do
            [[ -n "$name" ]] && key_concept_names+=("$name")
        done < <(echo "$optimization_json" | jq -r '.key_concepts_for_emphasis[]? | .name' 2>/dev/null)
    fi

    # Process file: add horizontal rules at concept boundaries for slide breaks
    local in_frontmatter=false
    local frontmatter_count=0
    local current_section_words=0
    local break_inserted=false

    {
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Track frontmatter
            if [[ "$line" == "---" ]]; then
                (( frontmatter_count++ ))
                if [[ $frontmatter_count -eq 1 ]]; then
                    in_frontmatter=true
                elif [[ $frontmatter_count -eq 2 ]]; then
                    in_frontmatter=false
                fi
                echo "$line"
                continue
            fi
            [[ "$in_frontmatter" == "true" ]] && { echo "$line"; continue; }

            # At H2/H3 boundaries, reset word count
            if [[ "$line" =~ '^#{2,3} ' ]]; then
                current_section_words=0
                break_inserted=false
                echo "$line"
                continue
            fi

            # Count words in section
            local line_words=$(echo "$line" | wc -w | tr -d ' ')
            current_section_words=$(( current_section_words + line_words ))

            # Insert break if section is too long and we're at a paragraph boundary
            if [[ $current_section_words -gt $SLIDE_MAX_SECTION_WORDS && "$break_inserted" == "false" && -z "$line" ]]; then
                echo ""
                echo "---"
                echo ""
                break_inserted=true
                current_section_words=0
            fi

            # Add callout for key concepts (first mention only)
            local matched_concept=""
            for kc in "${key_concept_names[@]}"; do
                if [[ "$line" == *"$kc"* && -z "$matched_concept" ]]; then
                    matched_concept="$kc"
                fi
            done

            if [[ -n "$matched_concept" ]]; then
                echo "$line"
                echo ""
                echo "::: {.callout-tip}"
                echo "## Key Concept: $matched_concept"
                echo ":::"
                echo ""
                # Remove from list (only first mention)
                key_concept_names=("${key_concept_names[@]:#$matched_concept}")
            else
                echo "$line"
            fi
        done
    } < "$file_path" > "$output_file"

    return 0
}
