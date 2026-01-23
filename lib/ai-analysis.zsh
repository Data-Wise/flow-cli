#!/usr/bin/env zsh

# lib/ai-analysis.zsh
# AI-powered concept analysis using Claude CLI
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
#
# Phase 3: Enhances heuristic concept graph with AI-extracted metadata:
#   - related_concepts: Semantic relationships between concepts
#   - keywords: Key terms associated with each concept
#   - bloom_level: Bloom's taxonomy classification
#   - cognitive_load: Estimated cognitive load (0.0-1.0)
#   - ai_confidence: Confidence score for AI predictions
#
# Architecture:
#   1. Heuristic analysis runs first (Phase 0-2)
#   2. AI analysis enhances the graph (additive only)
#   3. Graceful fallback if Claude unavailable

# Source dependencies
source "${0:A:h}/core.zsh" 2>/dev/null

# =============================================================================
# Constants
# =============================================================================

# Keychain account name for Claude API key (if direct API usage needed)
_AI_KEYCHAIN_ACCOUNT="teach-analyze-claude-api"

# Maximum content length to send to Claude (chars)
_AI_MAX_CONTENT_LENGTH=50000

# Cost file location (relative to course .teach/ dir)
_AI_COSTS_FILE="ai-costs.json"

# =============================================================================
# Function: _ai_check_available
# Purpose: Check if Claude CLI is available for AI analysis
# =============================================================================
# Returns:
#   0 - Claude CLI available
#   1 - Not available
# =============================================================================
_ai_check_available() {
    if command -v claude &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# Function: _ai_analyze_file
# Purpose: Run AI-powered analysis on a single .qmd file
# =============================================================================
# Arguments:
#   $1 - file_path: Path to .qmd file
#   $2 - existing_concepts: JSON string of concepts already extracted (heuristic)
#   $3 - quiet: "true" to suppress progress output
#
# Returns:
#   JSON string with AI-enhanced concept data (stdout)
#   Exit code: 0 on success, 1 on failure
#
# Example:
#   local enhanced=$(_ai_analyze_file "lectures/week-05.qmd" "$concepts_json")
# =============================================================================
_ai_analyze_file() {
    local file_path="$1"
    local existing_concepts="${2:-{}}"
    local quiet="${3:-false}"

    # Validate file
    if [[ ! -f "$file_path" ]]; then
        echo "{}"
        return 1
    fi

    # Check Claude availability
    if ! _ai_check_available; then
        [[ "$quiet" != "true" ]] && echo "${FLOW_YELLOW}⚠ Claude CLI not available, skipping AI analysis${FLOW_RESET}" >&2
        echo "{}"
        return 1
    fi

    # Read file content (truncate if too long)
    local content
    content=$(head -c "$_AI_MAX_CONTENT_LENGTH" "$file_path" 2>/dev/null)

    if [[ -z "$content" ]]; then
        echo "{}"
        return 1
    fi

    # Build the analysis prompt
    local prompt
    prompt=$(_ai_build_prompt "$content" "$existing_concepts")

    # Execute Claude CLI
    [[ "$quiet" != "true" ]] && printf "${FLOW_BLUE}Running AI analysis...${FLOW_RESET} " >&2

    local start_time
    start_time=$(date +%s)

    local ai_response
    ai_response=$(claude --print "$prompt" 2>/dev/null)
    local exit_code=$?

    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - start_time ))

    if [[ $exit_code -ne 0 || -z "$ai_response" ]]; then
        [[ "$quiet" != "true" ]] && echo "${FLOW_YELLOW}⚠ AI analysis failed (fallback to heuristics)${FLOW_RESET}" >&2
        echo "{}"
        return 1
    fi

    [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓${FLOW_RESET} (${duration}s)" >&2

    # Parse and validate the response
    local parsed
    parsed=$(_ai_parse_response "$ai_response")

    if [[ -z "$parsed" || "$parsed" == "{}" || "$parsed" == "null" ]]; then
        echo "{}"
        return 1
    fi

    # Track costs
    _ai_track_usage "$file_path" "$duration" "$ai_response"

    echo "$parsed"
    return 0
}

# =============================================================================
# Function: _ai_build_prompt
# Purpose: Construct the analysis prompt for Claude
# =============================================================================
# Arguments:
#   $1 - content: File content to analyze
#   $2 - existing_concepts: JSON of heuristic-extracted concepts
#
# Returns:
#   Prompt string (stdout)
# =============================================================================
_ai_build_prompt() {
    local content="$1"
    local existing_concepts="$2"

    # Extract concept IDs from existing graph for context
    local concept_ids=""
    if command -v jq &>/dev/null && [[ -n "$existing_concepts" && "$existing_concepts" != "{}" ]]; then
        concept_ids=$(echo "$existing_concepts" | jq -r 'keys | join(", ")' 2>/dev/null)
    fi

    cat << PROMPT
Analyze this teaching content and provide concept metadata as JSON.

EXISTING CONCEPTS (from frontmatter): ${concept_ids:-none detected}

CONTENT:
---
${content}
---

For each concept found in this content, provide:
1. related_concepts: Array of conceptually related topics (not prerequisites, but related ideas)
2. keywords: Array of key terms/vocabulary associated with the concept
3. bloom_level: Bloom's taxonomy level (remember, understand, apply, analyze, evaluate, create)
4. cognitive_load: Estimated cognitive load 0.0-1.0 (0=trivial, 1=extremely complex)
5. teaching_time_minutes: Estimated teaching time for this concept

IMPORTANT: Output ONLY valid JSON with no markdown formatting, no code fences, no explanation. Just the JSON object.

Output format:
{
  "concepts": {
    "concept-id": {
      "related_concepts": ["concept-a", "concept-b"],
      "keywords": ["term1", "term2"],
      "bloom_level": "apply",
      "cognitive_load": 0.5,
      "teaching_time_minutes": 30
    }
  },
  "summary": {
    "total_concepts_analyzed": 3,
    "avg_cognitive_load": 0.5,
    "dominant_bloom_level": "apply",
    "estimated_total_time_minutes": 90
  }
}
PROMPT
}

# =============================================================================
# Function: _ai_parse_response
# Purpose: Parse and validate Claude's JSON response
# =============================================================================
# Arguments:
#   $1 - response: Raw response from Claude CLI
#
# Returns:
#   Validated JSON string (stdout), or empty on failure
# =============================================================================
_ai_parse_response() {
    local response="$1"

    if [[ -z "$response" ]]; then
        echo "{}"
        return 1
    fi

    # Try to extract JSON from response (handle markdown code fences)
    local json_content="$response"

    # Strip markdown code fences if present
    if [[ "$json_content" == *'```json'* ]]; then
        json_content=$(echo "$json_content" | sed -n '/^```json$/,/^```$/p' | sed '1d;$d')
    elif [[ "$json_content" == *'```'* ]]; then
        json_content=$(echo "$json_content" | sed -n '/^```$/,/^```$/p' | sed '1d;$d')
    fi

    # Validate JSON
    if ! command -v jq &>/dev/null; then
        echo "{}"
        return 1
    fi

    # Try parsing as-is first
    if echo "$json_content" | jq empty 2>/dev/null; then
        # Validate expected structure
        local has_concepts
        has_concepts=$(echo "$json_content" | jq 'has("concepts")' 2>/dev/null)

        if [[ "$has_concepts" == "true" ]]; then
            # Add ai_confidence to each concept
            local enhanced
            enhanced=$(echo "$json_content" | jq '
                .concepts |= with_entries(
                    .value += {"ai_confidence": 0.85}
                )
            ' 2>/dev/null)
            echo "$enhanced"
            return 0
        fi
    fi

    # Failed to parse
    echo "{}"
    return 1
}

# =============================================================================
# Function: _ai_enhance_concept_graph
# Purpose: Merge AI analysis results into the heuristic concept graph
# =============================================================================
# Arguments:
#   $1 - graph_json: Existing concept graph (from Phase 0-2)
#   $2 - ai_results: AI analysis results (from _ai_analyze_file)
#
# Returns:
#   Enhanced concept graph JSON (stdout)
# =============================================================================
_ai_enhance_concept_graph() {
    local graph_json="$1"
    local ai_results="$2"

    if [[ -z "$ai_results" || "$ai_results" == "{}" || "$ai_results" == "null" ]]; then
        echo "$graph_json"
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        echo "$graph_json"
        return 0
    fi

    # Merge AI fields into existing concepts
    local enhanced
    enhanced=$(jq -n \
        --argjson graph "$graph_json" \
        --argjson ai "$ai_results" '
        $graph | .concepts |= with_entries(
            .key as $key |
            if ($ai.concepts[$key] // null) != null then
                .value += {
                    related_concepts: ($ai.concepts[$key].related_concepts // []),
                    keywords: ($ai.concepts[$key].keywords // []),
                    bloom_level: ($ai.concepts[$key].bloom_level // "understand"),
                    cognitive_load: ($ai.concepts[$key].cognitive_load // 0.5),
                    teaching_time_minutes: ($ai.concepts[$key].teaching_time_minutes // 30),
                    ai_confidence: ($ai.concepts[$key].ai_confidence // 0.85)
                }
            else
                .
            end
        ) |
        .metadata.extraction_method = "frontmatter+ai" |
        .metadata.ai_summary = ($ai.summary // {})
    ' 2>/dev/null)

    if [[ -n "$enhanced" ]]; then
        echo "$enhanced"
    else
        echo "$graph_json"
    fi
}

# =============================================================================
# Function: _ai_track_usage
# Purpose: Track AI API usage for cost transparency
# =============================================================================
# Arguments:
#   $1 - file_path: Analyzed file
#   $2 - duration_seconds: How long the API call took
#   $3 - response: Raw response (for token estimation)
# =============================================================================
_ai_track_usage() {
    local file_path="$1"
    local duration="$2"
    local response="$3"

    # Find .teach directory
    local teach_dir=""
    if [[ "$file_path" == *"/lectures/"* ]]; then
        teach_dir="${file_path%/lectures/*}/.teach"
    elif [[ "$file_path" == *"/assignments/"* ]]; then
        teach_dir="${file_path%/assignments/*}/.teach"
    else
        teach_dir="${file_path:h}/.teach"
    fi

    # Ensure directory exists
    mkdir -p "$teach_dir" 2>/dev/null || return 0

    local costs_file="$teach_dir/$_AI_COSTS_FILE"

    # Estimate tokens (rough: ~4 chars per token)
    local response_len=${#response}
    local estimated_tokens=$(( response_len / 4 ))

    # Estimated cost (Claude: ~$3/MTok input, ~$15/MTok output for Sonnet)
    # Using conservative Sonnet pricing
    local estimated_cost
    estimated_cost=$(printf "%.4f" $(echo "scale=6; $estimated_tokens * 0.000015" | bc 2>/dev/null || echo "0.0001"))

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local entry
    entry=$(jq -n \
        --arg file "$file_path" \
        --arg ts "$timestamp" \
        --argjson dur "$duration" \
        --argjson tokens "$estimated_tokens" \
        --arg cost "$estimated_cost" \
        '{
            file: $file,
            timestamp: $ts,
            duration_seconds: $dur,
            estimated_tokens: $tokens,
            estimated_cost_usd: ($cost | tonumber)
        }' 2>/dev/null)

    # Append to costs file (create if needed)
    if [[ -f "$costs_file" ]]; then
        local existing
        existing=$(cat "$costs_file" 2>/dev/null)
        if echo "$existing" | jq empty 2>/dev/null; then
            echo "$existing" | jq --argjson entry "$entry" '.entries += [$entry]' > "$costs_file" 2>/dev/null
        else
            echo "{\"entries\": [$entry]}" > "$costs_file"
        fi
    else
        echo "{\"entries\": [$entry]}" > "$costs_file"
    fi
}

# =============================================================================
# Function: _ai_get_cost_summary
# Purpose: Get summary of AI analysis costs
# =============================================================================
# Arguments:
#   $1 - course_dir: Course directory
#   $2 - format: "text" or "json" (default: text)
#
# Returns:
#   Cost summary (stdout)
# =============================================================================
_ai_get_cost_summary() {
    local course_dir="${1:-$PWD}"
    local format="${2:-text}"
    local costs_file="$course_dir/.teach/$_AI_COSTS_FILE"

    if [[ ! -f "$costs_file" ]]; then
        if [[ "$format" == "json" ]]; then
            echo '{"total_calls": 0, "total_cost_usd": 0, "total_tokens": 0}'
        else
            echo "No AI analysis costs recorded yet."
        fi
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        echo "jq required for cost summary"
        return 1
    fi

    local summary
    summary=$(jq '{
        total_calls: (.entries | length),
        total_cost_usd: ([.entries[].estimated_cost_usd] | add // 0),
        total_tokens: ([.entries[].estimated_tokens] | add // 0),
        total_duration_seconds: ([.entries[].duration_seconds] | add // 0),
        last_used: (.entries | last | .timestamp // "never"),
        files_analyzed: ([.entries[].file] | unique | length)
    }' "$costs_file" 2>/dev/null)

    if [[ "$format" == "json" ]]; then
        echo "$summary"
    else
        local total_calls total_cost total_tokens total_duration last_used files_analyzed
        total_calls=$(echo "$summary" | jq -r '.total_calls')
        total_cost=$(echo "$summary" | jq -r '.total_cost_usd')
        total_tokens=$(echo "$summary" | jq -r '.total_tokens')
        total_duration=$(echo "$summary" | jq -r '.total_duration_seconds')
        last_used=$(echo "$summary" | jq -r '.last_used')
        files_analyzed=$(echo "$summary" | jq -r '.files_analyzed')

        echo "AI Analysis Costs"
        echo "  API calls:       $total_calls"
        echo "  Files analyzed:  $files_analyzed"
        echo "  Est. tokens:     $total_tokens"
        echo "  Est. cost:       \$${total_cost}"
        echo "  Total duration:  ${total_duration}s"
        echo "  Last used:       $last_used"
    fi
}

# =============================================================================
# Function: _ai_analyze_course
# Purpose: Run AI analysis on all files in course (with progress)
# =============================================================================
# Arguments:
#   $1 - course_dir: Course directory
#   $2 - existing_graph: JSON concept graph from heuristic analysis
#   $3 - quiet: "true" to suppress progress
#
# Returns:
#   Enhanced concept graph JSON (stdout)
# =============================================================================
_ai_analyze_course() {
    local course_dir="${1:-$PWD}"
    local existing_graph="$2"
    local quiet="${3:-false}"
    local lectures_dir="$course_dir/lectures"

    if [[ ! -d "$lectures_dir" ]]; then
        echo "$existing_graph"
        return 0
    fi

    # Check availability
    if ! _ai_check_available; then
        [[ "$quiet" != "true" ]] && echo "${FLOW_YELLOW}⚠ Claude CLI not available${FLOW_RESET}" >&2
        echo "$existing_graph"
        return 1
    fi

    # Get list of .qmd files
    local -a qmd_files
    qmd_files=($(find "$lectures_dir" -name "*.qmd" -type f 2>/dev/null | sort))

    if [[ ${#qmd_files[@]} -eq 0 ]]; then
        echo "$existing_graph"
        return 0
    fi

    [[ "$quiet" != "true" ]] && echo "${FLOW_BLUE}AI analyzing ${#qmd_files[@]} file(s)...${FLOW_RESET}" >&2

    local enhanced_graph="$existing_graph"
    local analyzed=0
    local failed=0

    for file in "${qmd_files[@]}"; do
        local filename="${file:t}"
        [[ "$quiet" != "true" ]] && printf "  ${FLOW_BLUE}[$((analyzed + failed + 1))/${#qmd_files[@]}]${FLOW_RESET} $filename " >&2

        # Get existing concepts for this file
        local file_concepts
        file_concepts=$(echo "$enhanced_graph" | jq --arg file "${file#$course_dir/}" \
            '[.concepts | to_entries[] | select(.value.introduced_in.lecture == $file) | {(.key): .value}] | add // {}' 2>/dev/null)

        # Run AI analysis on this file
        local ai_result
        ai_result=$(_ai_analyze_file "$file" "$file_concepts" "true")

        if [[ -n "$ai_result" && "$ai_result" != "{}" ]]; then
            enhanced_graph=$(_ai_enhance_concept_graph "$enhanced_graph" "$ai_result")
            ((analyzed++))
            [[ "$quiet" != "true" ]] && echo "${FLOW_GREEN}✓${FLOW_RESET}" >&2
        else
            ((failed++))
            [[ "$quiet" != "true" ]] && echo "${FLOW_YELLOW}⚠${FLOW_RESET}" >&2
        fi
    done

    [[ "$quiet" != "true" ]] && echo "" >&2
    [[ "$quiet" != "true" ]] && echo "  ${FLOW_GREEN}AI analysis: $analyzed succeeded, $failed skipped${FLOW_RESET}" >&2

    echo "$enhanced_graph"
}
