#!/usr/bin/env zsh
# test-teach-analyze-phase3-integration.zsh - Integration tests for teach analyze Phase 3
# Run with: zsh tests/test-teach-analyze-phase3-integration.zsh
#
# Test Suites:
# - Flag Parsing (5 tests)
# - AI Flow with Mock (5 tests)
# - Cost Display (3 tests)
# - Fallback Behavior (4 tests)
# - Display Enhancement (3 tests)
# Total: 20 tests

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

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should not contain substring}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        test_fail "$message (should NOT contain: '$needle')"
        return 1
    fi
}

assert_file_exists() {
    local path="$1"
    local message="${2:-File should exist}"

    if [[ -f "$path" ]]; then
        return 0
    else
        test_fail "$message ($path)"
        return 1
    fi
}

# ============================================================================
# SETUP: Create test course structure
# ============================================================================

# Suppress flow log functions
_flow_log_error() { : ; }
_flow_log_debug() { : ; }
_flow_log_success() { : ; }
_flow_log_info() { : ; }
_flow_log_warning() { : ; }

# Define color variables
FLOW_GREEN=''
FLOW_BLUE=''
FLOW_YELLOW=''
FLOW_RED=''
FLOW_BOLD=''
FLOW_RESET=''

# Source libraries
source "$PROJECT_ROOT/lib/concept-extraction.zsh"
source "$PROJECT_ROOT/lib/prerequisite-checker.zsh"
source "$PROJECT_ROOT/lib/ai-analysis.zsh"

# Source the report generator (stub if not present)
if [[ -f "$PROJECT_ROOT/lib/report-generator.zsh" ]]; then
    source "$PROJECT_ROOT/lib/report-generator.zsh"
else
    _report_generate() { return 0; }
fi

# Source the main command
source "$PROJECT_ROOT/commands/teach-analyze.zsh"

# Create test course
TEST_COURSE="$TEST_DIR/test-course"
mkdir -p "$TEST_COURSE/lectures"
mkdir -p "$TEST_COURSE/.teach"

# Week 1 lecture
cat > "$TEST_COURSE/lectures/week-01-intro.qmd" << 'EOF'
---
title: 'Introduction to Statistics'
week: 1
concepts:
  introduces:
    - descriptive-stats
    - data-types
---

# Introduction to Statistics

This lecture covers basic statistical concepts.
EOF

# Week 3 lecture
cat > "$TEST_COURSE/lectures/week-03-correlation.qmd" << 'EOF'
---
title: 'Correlation Analysis'
week: 3
concepts:
  introduces:
    - correlation
    - scatter-plots
  requires:
    - descriptive-stats
---

# Correlation

Understanding relationships between variables.
EOF

# Week 5 lecture
cat > "$TEST_COURSE/lectures/week-05-regression.qmd" << 'EOF'
---
title: 'Linear Regression'
week: 5
concepts:
  introduces:
    - simple-regression
    - residual-analysis
  requires:
    - correlation
    - descriptive-stats
---

# Linear Regression

Building on correlation to make predictions.
The method of least squares minimizes residual sum of squares.
Assumptions include linearity, independence, normality, and equal variance.
EOF

# ============================================================================
# SUITE 1: Flag Parsing (5 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 1: Flag Parsing${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Test 1.1: --ai flag is accepted
test_start "ai_flag_accepted"
local output
output=$(_teach_analyze "$TEST_COURSE/lectures/week-01-intro.qmd" --ai --quiet 2>&1)
# Should not say "Unknown option"
if assert_not_contains "$output" "Unknown option"; then
    test_pass
fi

# Test 1.2: --costs flag is accepted
test_start "costs_flag_accepted"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-01-intro.qmd" --costs --quiet 2>&1)
if assert_not_contains "$output" "Unknown option"; then
    test_pass
fi

# Test 1.3: --costs alone shows summary (no file needed)
test_start "costs_alone_shows_summary"
# Push to test course dir temporarily
pushd "$TEST_COURSE" >/dev/null
output=$(_teach_analyze --costs 2>&1)
popd >/dev/null
# Should show cost info (either "No AI analysis costs" or the summary)
if assert_contains "$output" "cost" || assert_contains "$output" "Cost" || assert_contains "$output" "No AI"; then
    test_pass
fi

# Test 1.4: --ai with --quiet suppresses progress
test_start "ai_quiet_suppresses"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-01-intro.qmd" --ai --quiet 2>&1)
# In quiet mode, should not show "Running AI analysis" text
if assert_not_contains "$output" "Running AI"; then
    test_pass
fi

# Test 1.5: Help text mentions --ai
test_start "help_mentions_ai"
output=$(_teach_analyze --help 2>&1)
if assert_contains "$output" "--ai"; then
    test_pass
fi

# ============================================================================
# SUITE 2: AI Flow with Mock (5 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 2: AI Flow with Mock${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Create a mock claude script
MOCK_CLAUDE="$TEST_DIR/mock-claude"
cat > "$MOCK_CLAUDE" << 'MOCK'
#!/bin/bash
# Mock Claude CLI that returns AI analysis JSON
cat << 'JSON'
{
    "concepts": {
        "simple-regression": {
            "related_concepts": ["multiple-regression", "anova"],
            "keywords": ["slope", "intercept", "least-squares"],
            "bloom_level": "apply",
            "cognitive_load": 0.65,
            "teaching_time_minutes": 50
        },
        "residual-analysis": {
            "related_concepts": ["diagnostics", "outliers"],
            "keywords": ["residual", "fitted-values", "QQ-plot"],
            "bloom_level": "analyze",
            "cognitive_load": 0.7,
            "teaching_time_minutes": 35
        }
    },
    "summary": {
        "total_concepts_analyzed": 2,
        "avg_cognitive_load": 0.675,
        "dominant_bloom_level": "apply",
        "estimated_total_time_minutes": 85
    }
}
JSON
MOCK
chmod +x "$MOCK_CLAUDE"

# Override PATH to use mock claude
export PATH="$TEST_DIR:$PATH"
ln -sf "$MOCK_CLAUDE" "$TEST_DIR/claude"

# Test 2.1: AI analysis produces enhanced graph
test_start "ai_produces_enhanced_graph"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-05-regression.qmd" --ai --quiet 2>&1)
local concepts_file="$TEST_COURSE/.teach/concepts.json"
if [[ -f "$concepts_file" ]]; then
    local bloom
    bloom=$(jq -r '.concepts["simple-regression"].bloom_level // "null"' "$concepts_file" 2>/dev/null)
    if [[ "$bloom" == "apply" ]]; then
        test_pass
    else
        test_fail "Should have bloom_level=apply (got: $bloom)"
    fi
else
    test_fail "concepts.json should exist"
fi

# Test 2.2: AI adds related_concepts
test_start "ai_adds_related_concepts"
if [[ -f "$concepts_file" ]]; then
    local related
    related=$(jq '.concepts["simple-regression"].related_concepts | length' "$concepts_file" 2>/dev/null)
    if [[ "$related" -gt 0 ]]; then
        test_pass
    else
        test_fail "Should have related_concepts (got: $related)"
    fi
else
    test_fail "concepts.json should exist"
fi

# Test 2.3: AI adds keywords
test_start "ai_adds_keywords"
if [[ -f "$concepts_file" ]]; then
    local kw
    kw=$(jq '.concepts["simple-regression"].keywords | length' "$concepts_file" 2>/dev/null)
    if [[ "$kw" -gt 0 ]]; then
        test_pass
    else
        test_fail "Should have keywords (got: $kw)"
    fi
else
    test_fail "concepts.json should exist"
fi

# Test 2.4: AI preserves heuristic data
test_start "ai_preserves_heuristic_data"
if [[ -f "$concepts_file" ]]; then
    local prereqs
    prereqs=$(jq -r '.concepts["simple-regression"].prerequisites[0] // "null"' "$concepts_file" 2>/dev/null)
    if [[ "$prereqs" == "correlation" ]]; then
        test_pass
    else
        test_fail "Should preserve prerequisites (got: $prereqs)"
    fi
else
    test_fail "concepts.json should exist"
fi

# Test 2.5: AI extraction_method updated
test_start "ai_extraction_method_updated"
if [[ -f "$concepts_file" ]]; then
    local method
    method=$(jq -r '.metadata.extraction_method' "$concepts_file" 2>/dev/null)
    if [[ "$method" == "frontmatter+ai" ]]; then
        test_pass
    else
        test_fail "Should be frontmatter+ai (got: $method)"
    fi
else
    test_fail "concepts.json should exist"
fi

# ============================================================================
# SUITE 3: Cost Display (3 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 3: Cost Display${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Test 3.1: --costs flag shows cost after AI analysis
test_start "costs_after_ai_analysis"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-05-regression.qmd" --ai --costs --quiet 2>&1)
if assert_contains "$output" "API calls" || assert_contains "$output" "cost" || assert_contains "$output" "Cost"; then
    test_pass
fi

# Test 3.2: Cost file exists after AI analysis
test_start "cost_file_exists_after_ai"
if assert_file_exists "$TEST_COURSE/.teach/$_AI_COSTS_FILE"; then
    test_pass
fi

# Test 3.3: Cost file has entries
test_start "cost_file_has_entries"
local entry_count
entry_count=$(jq '.entries | length' "$TEST_COURSE/.teach/$_AI_COSTS_FILE" 2>/dev/null)
if [[ "$entry_count" -gt 0 ]]; then
    test_pass
else
    test_fail "Cost file should have entries (got: $entry_count)"
fi

# ============================================================================
# SUITE 4: Fallback Behavior (4 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 4: Fallback Behavior${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Remove mock claude to test fallback
rm -f "$TEST_DIR/claude"

# Test 4.1: Without --ai flag, normal analysis works
test_start "without_ai_normal_works"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-01-intro.qmd" --quiet 2>&1)
local exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    test_pass
else
    test_fail "Normal analysis should work without --ai"
fi

# Test 4.2: With --ai but no claude, falls back gracefully
test_start "ai_no_claude_fallback"
# Ensure claude is not in PATH for this test
local save_path="$PATH"
export PATH="/usr/bin:/bin"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-01-intro.qmd" --ai --quiet 2>&1)
exit_code=$?
export PATH="$save_path"
# Should still succeed (heuristic-only)
if [[ $exit_code -eq 0 ]]; then
    test_pass
else
    test_fail "Should fallback to heuristic (exit: $exit_code)"
fi

# Test 4.3: Fallback preserves heuristic graph (run with full PATH)
test_start "fallback_preserves_graph"
# Run with full PATH so heuristic tools (yq/jq) work, but no claude
rm -f "$TEST_DIR/claude" 2>/dev/null
output=$(_teach_analyze "$TEST_COURSE/lectures/week-01-intro.qmd" --ai --quiet 2>&1)
if [[ -f "$TEST_COURSE/.teach/concepts.json" ]]; then
    local total
    total=$(jq '.metadata.total_concepts' "$TEST_COURSE/.teach/concepts.json" 2>/dev/null)
    if [[ "$total" -gt 0 ]]; then
        test_pass
    else
        test_fail "Should have concepts in graph (got: $total)"
    fi
else
    test_fail "concepts.json should exist after fallback"
fi

# Test 4.4: Phase indicator shows heuristic-only on fallback
test_start "phase_indicator_heuristic"
local save_path2="$PATH"
export PATH="/usr/bin:/bin"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-01-intro.qmd" --ai 2>&1)
export PATH="$save_path2"
if assert_contains "$output" "heuristic-only"; then
    test_pass
fi

# ============================================================================
# SUITE 5: Display Enhancement (3 tests)
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${YELLOW}Suite 5: Display Enhancement${RESET}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Restore mock claude
ln -sf "$MOCK_CLAUDE" "$TEST_DIR/claude"

# Test 5.1: AI display section shows with --ai
test_start "ai_display_section_shown"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-05-regression.qmd" --ai 2>&1)
if assert_contains "$output" "AI ANALYSIS" || assert_contains "$output" "AI"; then
    test_pass
fi

# Test 5.2: Phase label shows AI-enhanced
test_start "phase_label_ai_enhanced"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-05-regression.qmd" --ai 2>&1)
if assert_contains "$output" "AI-enhanced" || assert_contains "$output" "Phase: 3"; then
    test_pass
fi

# Test 5.3: Without --ai, no AI section shown
test_start "no_ai_no_section"
output=$(_teach_analyze "$TEST_COURSE/lectures/week-05-regression.qmd" 2>&1)
if assert_not_contains "$output" "AI ANALYSIS"; then
    test_pass
fi

# ============================================================================
# CLEANUP
# ============================================================================

# Remove mock from PATH
rm -f "$TEST_DIR/claude"

# ============================================================================
# RESULTS
# ============================================================================

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "Phase 3 Integration Tests Complete"
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
