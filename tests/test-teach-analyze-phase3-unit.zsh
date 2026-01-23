#!/usr/bin/env zsh
# test-teach-analyze-phase3-unit.zsh - Unit tests for teach analyze Phase 3 (AI)
# Run with: zsh tests/test-teach-analyze-phase3-unit.zsh
#
# Test Suites:
# - AI Availability (5 tests)
# - Prompt Building (5 tests)
# - Response Parsing (8 tests)
# - Graph Enhancement (7 tests)
# - Cost Tracking (5 tests)
# - Cost Summary (5 tests)
# Total: 35 tests

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Test directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR}/.."
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
    echo -n "${CYAN}TEST: $1${RESET} ... "
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    echo "${GREEN}✓ PASS${RESET}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo "${RED}✗ FAIL${RESET}"
    echo "  ${RED}→ $1${RESET}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should be equal}"

    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        test_fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        test_fail "$message (expected to contain: '$needle')"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"

    if [[ -n "$value" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_json_valid() {
    local json="$1"
    local message="${2:-Should be valid JSON}"

    if echo "$json" | jq empty 2>/dev/null; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_json_field() {
    local json="$1"
    local field="$2"
    local expected="$3"
    local message="${4:-JSON field should match}"

    local actual
    actual=$(echo "$json" | jq -r "$field" 2>/dev/null)

    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        test_fail "$message (field $field: expected '$expected', got '$actual')"
        return 1
    fi
}

# ============================================================================
# SETUP: Source the AI analysis library
# ============================================================================

# Suppress flow log functions
_flow_log_error() { : ; }
_flow_log_debug() { : ; }
_flow_log_success() { : ; }
_flow_log_info() { : ; }
_flow_log_warning() { : ; }

# Define color variables used by the library
FLOW_GREEN=''
FLOW_BLUE=''
FLOW_YELLOW=''
FLOW_RED=''
FLOW_BOLD=''
FLOW_RESET=''

# Source the library
source "$PROJECT_ROOT/lib/ai-analysis.zsh"

# ============================================================================
# SUITE 1: AI Availability (5 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 1: AI Availability${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Test 1.1: _ai_check_available with claude present
test_start "check_available_with_claude"
if command -v claude &>/dev/null; then
    _ai_check_available
    if [[ $? -eq 0 ]]; then
        test_pass
    else
        test_fail "Should return 0 when claude is available"
    fi
else
    # Claude not available in test env - mock it
    mock_claude() { echo "mock"; }
    alias claude=mock_claude
    # Test that it correctly detects absence
    _ai_check_available
    if [[ $? -ne 0 ]]; then
        test_pass  # Correctly reports unavailable
    else
        test_fail "Should return 1 when claude is not available"
    fi
    unalias claude 2>/dev/null
fi

# Test 1.2: _ai_analyze_file with missing file
test_start "analyze_file_missing_file"
local result
result=$(_ai_analyze_file "/nonexistent/file.qmd" "{}" "true")
if [[ "$result" == "{}" ]]; then
    test_pass
else
    test_fail "Should return {} for missing file"
fi

# Test 1.3: _ai_analyze_file with empty file
test_start "analyze_file_empty_content"
local empty_file="$TEST_DIR/empty.qmd"
touch "$empty_file"
result=$(_ai_analyze_file "$empty_file" "{}" "true")
if [[ "$result" == "{}" ]]; then
    test_pass
else
    test_fail "Should return {} for empty file"
fi

# Test 1.4: Constants are defined
test_start "constants_defined"
if [[ -n "$_AI_MAX_CONTENT_LENGTH" && -n "$_AI_COSTS_FILE" && -n "$_AI_KEYCHAIN_ACCOUNT" ]]; then
    test_pass
else
    test_fail "Constants should be defined"
fi

# Test 1.5: Max content length is reasonable
test_start "max_content_length_reasonable"
if [[ "$_AI_MAX_CONTENT_LENGTH" -ge 10000 && "$_AI_MAX_CONTENT_LENGTH" -le 200000 ]]; then
    test_pass
else
    test_fail "Max content length should be 10K-200K (got: $_AI_MAX_CONTENT_LENGTH)"
fi

# ============================================================================
# SUITE 2: Prompt Building (5 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 2: Prompt Building${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Test 2.1: Build prompt with content
test_start "build_prompt_basic"
local content="# Linear Regression\n\nThis lecture covers the basics of linear regression."
local prompt
prompt=$(_ai_build_prompt "$content" "{}")
if assert_contains "$prompt" "bloom_level" && assert_contains "$prompt" "cognitive_load"; then
    test_pass
fi

# Test 2.2: Build prompt includes content
test_start "build_prompt_includes_content"
prompt=$(_ai_build_prompt "Test content about statistics" "{}")
if assert_contains "$prompt" "Test content about statistics"; then
    test_pass
fi

# Test 2.3: Build prompt mentions JSON output
test_start "build_prompt_requests_json"
prompt=$(_ai_build_prompt "content" "{}")
if assert_contains "$prompt" "JSON"; then
    test_pass
fi

# Test 2.4: Build prompt includes existing concepts
test_start "build_prompt_with_concepts"
local concepts='{"regression": {"id": "regression"}, "correlation": {"id": "correlation"}}'
prompt=$(_ai_build_prompt "content" "$concepts")
if assert_contains "$prompt" "regression" && assert_contains "$prompt" "correlation"; then
    test_pass
fi

# Test 2.5: Build prompt handles empty concepts
test_start "build_prompt_empty_concepts"
prompt=$(_ai_build_prompt "content" "{}")
if assert_contains "$prompt" "none detected"; then
    test_pass
fi

# ============================================================================
# SUITE 3: Response Parsing (8 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 3: Response Parsing${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Test 3.1: Parse valid JSON response
test_start "parse_valid_json"
local valid_response='{
    "concepts": {
        "regression": {
            "related_concepts": ["correlation", "anova"],
            "keywords": ["slope", "intercept"],
            "bloom_level": "apply",
            "cognitive_load": 0.6,
            "teaching_time_minutes": 45
        }
    },
    "summary": {
        "total_concepts_analyzed": 1,
        "avg_cognitive_load": 0.6,
        "dominant_bloom_level": "apply"
    }
}'
local parsed
parsed=$(_ai_parse_response "$valid_response")
if assert_json_valid "$parsed" && assert_json_field "$parsed" '.concepts.regression.bloom_level' "apply"; then
    test_pass
fi

# Test 3.2: Parse response with code fences
test_start "parse_response_with_fences"
local fenced_response='Here is the analysis:

```json
{
    "concepts": {
        "variance": {
            "related_concepts": ["std-dev"],
            "keywords": ["spread"],
            "bloom_level": "understand",
            "cognitive_load": 0.4,
            "teaching_time_minutes": 20
        }
    },
    "summary": {"total_concepts_analyzed": 1}
}
```'
parsed=$(_ai_parse_response "$fenced_response")
if assert_json_valid "$parsed"; then
    test_pass
fi

# Test 3.3: Parse empty response
test_start "parse_empty_response"
parsed=$(_ai_parse_response "")
if [[ "$parsed" == "{}" ]]; then
    test_pass
else
    test_fail "Empty response should return {}"
fi

# Test 3.4: Parse invalid JSON
test_start "parse_invalid_json"
parsed=$(_ai_parse_response "This is not JSON at all")
if [[ "$parsed" == "{}" ]]; then
    test_pass
else
    test_fail "Invalid JSON should return {}"
fi

# Test 3.5: Parse response adds ai_confidence
test_start "parse_adds_confidence"
parsed=$(_ai_parse_response "$valid_response")
local confidence
confidence=$(echo "$parsed" | jq -r '.concepts.regression.ai_confidence' 2>/dev/null)
if [[ "$confidence" == "0.85" ]]; then
    test_pass
else
    test_fail "Should add ai_confidence=0.85 (got: $confidence)"
fi

# Test 3.6: Parse response without concepts key
test_start "parse_no_concepts_key"
local no_concepts='{"data": "something else"}'
parsed=$(_ai_parse_response "$no_concepts")
if [[ "$parsed" == "{}" ]]; then
    test_pass
else
    test_fail "Response without 'concepts' key should return {}"
fi

# Test 3.7: Parse response with multiple concepts
test_start "parse_multiple_concepts"
local multi_response='{
    "concepts": {
        "mean": {"bloom_level": "remember", "cognitive_load": 0.2, "related_concepts": [], "keywords": ["average"], "teaching_time_minutes": 15},
        "variance": {"bloom_level": "understand", "cognitive_load": 0.5, "related_concepts": ["std-dev"], "keywords": ["spread"], "teaching_time_minutes": 25}
    },
    "summary": {"total_concepts_analyzed": 2}
}'
parsed=$(_ai_parse_response "$multi_response")
local count
count=$(echo "$parsed" | jq '.concepts | length' 2>/dev/null)
if [[ "$count" == "2" ]]; then
    test_pass
else
    test_fail "Should parse 2 concepts (got: $count)"
fi

# Test 3.8: Parse preserves all fields
test_start "parse_preserves_fields"
parsed=$(_ai_parse_response "$valid_response")
local keywords
keywords=$(echo "$parsed" | jq -r '.concepts.regression.keywords | join(",")' 2>/dev/null)
if [[ "$keywords" == "slope,intercept" ]]; then
    test_pass
else
    test_fail "Should preserve keywords (got: $keywords)"
fi

# ============================================================================
# SUITE 4: Graph Enhancement (7 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 4: Graph Enhancement${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Setup base graph
local base_graph='{
    "version": "1.0",
    "schema_version": "concept-graph-v1",
    "metadata": {
        "last_updated": "2026-01-22T00:00:00Z",
        "total_concepts": 2,
        "weeks": 5,
        "extraction_method": "frontmatter"
    },
    "concepts": {
        "regression": {
            "id": "regression",
            "name": "Regression",
            "prerequisites": ["correlation"],
            "introduced_in": {"week": 5, "lecture": "lectures/week-05.qmd", "line_number": 12}
        },
        "correlation": {
            "id": "correlation",
            "name": "Correlation",
            "prerequisites": [],
            "introduced_in": {"week": 3, "lecture": "lectures/week-03.qmd", "line_number": 8}
        }
    }
}'

local ai_data='{
    "concepts": {
        "regression": {
            "related_concepts": ["anova", "residuals"],
            "keywords": ["slope", "intercept", "least-squares"],
            "bloom_level": "apply",
            "cognitive_load": 0.65,
            "teaching_time_minutes": 50,
            "ai_confidence": 0.85
        }
    },
    "summary": {
        "total_concepts_analyzed": 1,
        "avg_cognitive_load": 0.65,
        "dominant_bloom_level": "apply",
        "estimated_total_time_minutes": 50
    }
}'

# Test 4.1: Enhance graph adds AI fields
test_start "enhance_adds_bloom_level"
local enhanced
enhanced=$(_ai_enhance_concept_graph "$base_graph" "$ai_data")
local bloom
bloom=$(echo "$enhanced" | jq -r '.concepts.regression.bloom_level' 2>/dev/null)
if [[ "$bloom" == "apply" ]]; then
    test_pass
else
    test_fail "Should add bloom_level=apply (got: $bloom)"
fi

# Test 4.2: Enhance graph adds cognitive_load
test_start "enhance_adds_cognitive_load"
local load
load=$(echo "$enhanced" | jq -r '.concepts.regression.cognitive_load' 2>/dev/null)
if [[ "$load" == "0.65" ]]; then
    test_pass
else
    test_fail "Should add cognitive_load=0.65 (got: $load)"
fi

# Test 4.3: Enhance graph adds related_concepts
test_start "enhance_adds_related_concepts"
local related_count
related_count=$(echo "$enhanced" | jq '.concepts.regression.related_concepts | length' 2>/dev/null)
if [[ "$related_count" == "2" ]]; then
    test_pass
else
    test_fail "Should add 2 related concepts (got: $related_count)"
fi

# Test 4.4: Enhance graph preserves existing data
test_start "enhance_preserves_existing"
local prereqs
prereqs=$(echo "$enhanced" | jq -r '.concepts.regression.prerequisites[0]' 2>/dev/null)
if [[ "$prereqs" == "correlation" ]]; then
    test_pass
else
    test_fail "Should preserve prerequisites (got: $prereqs)"
fi

# Test 4.5: Enhance graph leaves non-AI concepts unchanged
test_start "enhance_leaves_others_unchanged"
local corr_bloom
corr_bloom=$(echo "$enhanced" | jq -r '.concepts.correlation.bloom_level // "null"' 2>/dev/null)
if [[ "$corr_bloom" == "null" ]]; then
    test_pass
else
    test_fail "Non-AI concepts should not have bloom_level (got: $corr_bloom)"
fi

# Test 4.6: Enhance graph updates extraction_method
test_start "enhance_updates_method"
local method
method=$(echo "$enhanced" | jq -r '.metadata.extraction_method' 2>/dev/null)
if [[ "$method" == "frontmatter+ai" ]]; then
    test_pass
else
    test_fail "Should update extraction_method (got: $method)"
fi

# Test 4.7: Enhance with empty AI data returns original
test_start "enhance_empty_ai_returns_original"
enhanced=$(_ai_enhance_concept_graph "$base_graph" "{}")
local original_method
original_method=$(echo "$enhanced" | jq -r '.metadata.extraction_method' 2>/dev/null)
if [[ "$original_method" == "frontmatter" ]]; then
    test_pass
else
    test_fail "Empty AI should return original graph"
fi

# ============================================================================
# SUITE 5: Cost Tracking (5 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 5: Cost Tracking${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Setup course dir with .teach
local cost_course="$TEST_DIR/cost-course"
mkdir -p "$cost_course/lectures"
mkdir -p "$cost_course/.teach"

# Create a lecture file
cat > "$cost_course/lectures/week-01.qmd" << 'EOF'
---
title: "Introduction"
week: 1
concepts:
  introduces:
    - statistics-basics
---

# Introduction to Statistics
EOF

# Test 5.1: Track usage creates cost file
test_start "track_usage_creates_file"
_ai_track_usage "$cost_course/lectures/week-01.qmd" 5 "sample response text here for token estimation"
if [[ -f "$cost_course/.teach/$_AI_COSTS_FILE" ]]; then
    test_pass
else
    test_fail "Should create cost file"
fi

# Test 5.2: Cost file has valid JSON
test_start "cost_file_valid_json"
if jq empty "$cost_course/.teach/$_AI_COSTS_FILE" 2>/dev/null; then
    test_pass
else
    test_fail "Cost file should be valid JSON"
fi

# Test 5.3: Cost entry has required fields
test_start "cost_entry_has_fields"
local entry
entry=$(jq '.entries[0]' "$cost_course/.teach/$_AI_COSTS_FILE" 2>/dev/null)
local has_file has_ts has_dur
has_file=$(echo "$entry" | jq 'has("file")' 2>/dev/null)
has_ts=$(echo "$entry" | jq 'has("timestamp")' 2>/dev/null)
has_dur=$(echo "$entry" | jq 'has("duration_seconds")' 2>/dev/null)
if [[ "$has_file" == "true" && "$has_ts" == "true" && "$has_dur" == "true" ]]; then
    test_pass
else
    test_fail "Entry should have file, timestamp, duration_seconds"
fi

# Test 5.4: Track multiple usages appends
test_start "track_multiple_appends"
_ai_track_usage "$cost_course/lectures/week-01.qmd" 8 "another response"
local count
count=$(jq '.entries | length' "$cost_course/.teach/$_AI_COSTS_FILE" 2>/dev/null)
if [[ "$count" == "2" ]]; then
    test_pass
else
    test_fail "Should have 2 entries (got: $count)"
fi

# Test 5.5: Token estimation is reasonable
test_start "token_estimation_reasonable"
local tokens
tokens=$(jq '.entries[0].estimated_tokens' "$cost_course/.teach/$_AI_COSTS_FILE" 2>/dev/null)
# "sample response text here for token estimation" = 48 chars, ~12 tokens
if [[ "$tokens" -gt 0 && "$tokens" -lt 1000 ]]; then
    test_pass
else
    test_fail "Token estimate should be reasonable (got: $tokens)"
fi

# ============================================================================
# SUITE 6: Cost Summary (5 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 6: Cost Summary${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Test 6.1: Cost summary text format
test_start "cost_summary_text"
local summary
summary=$(_ai_get_cost_summary "$cost_course" "text")
if assert_contains "$summary" "API calls"; then
    test_pass
fi

# Test 6.2: Cost summary JSON format
test_start "cost_summary_json"
summary=$(_ai_get_cost_summary "$cost_course" "json")
if assert_json_valid "$summary"; then
    test_pass
fi

# Test 6.3: Cost summary JSON has total_calls
test_start "cost_summary_total_calls"
summary=$(_ai_get_cost_summary "$cost_course" "json")
local total
total=$(echo "$summary" | jq '.total_calls' 2>/dev/null)
if [[ "$total" == "2" ]]; then
    test_pass
else
    test_fail "Should report 2 total calls (got: $total)"
fi

# Test 6.4: Cost summary for empty course
test_start "cost_summary_empty_course"
local empty_course="$TEST_DIR/empty-course"
mkdir -p "$empty_course/.teach"
summary=$(_ai_get_cost_summary "$empty_course" "text")
if assert_contains "$summary" "No AI analysis costs"; then
    test_pass
fi

# Test 6.5: Cost summary JSON for empty course
test_start "cost_summary_json_empty"
summary=$(_ai_get_cost_summary "$empty_course" "json")
local total_empty
total_empty=$(echo "$summary" | jq '.total_calls' 2>/dev/null)
if [[ "$total_empty" == "0" ]]; then
    test_pass
else
    test_fail "Empty course should have 0 calls (got: $total_empty)"
fi

# ============================================================================
# RESULTS
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "Phase 3 Unit Tests Complete"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "  Total:  $TESTS_RUN"
echo "  ${GREEN}Passed: $TESTS_PASSED${RESET}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "  ${RED}Failed: $TESTS_FAILED${RESET}"
fi
echo ""

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi
exit 0
