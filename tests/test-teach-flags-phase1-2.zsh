#!/usr/bin/env zsh
# test-teach-flags-phase1-2.zsh - Unit tests for teach dispatcher Phases 1-2
# Tests flag infrastructure and preset system (v5.13.0+)

# ============================================================================
# Test Framework Setup
# ============================================================================

# Source the teach dispatcher
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "${PROJECT_ROOT}/lib/core.zsh"
source "${PROJECT_ROOT}/lib/dispatchers/teach-dispatcher.zsh"

# Test counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Test assertion helper
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo "  ✓ $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        echo "  ✗ $test_name"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local test_name="$2"

    ((TESTS_RUN++))

    if [[ -n "$value" ]]; then
        ((TESTS_PASSED++))
        echo "  ✓ $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        echo "  ✗ $test_name (value is empty)"
        return 1
    fi
}

assert_empty() {
    local value="$1"
    local test_name="$2"

    ((TESTS_RUN++))

    if [[ -z "$value" ]]; then
        ((TESTS_PASSED++))
        echo "  ✓ $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        echo "  ✗ $test_name (value should be empty)"
        echo "    Actual:   $value"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo "  ✓ $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        echo "  ✗ $test_name"
        echo "    Expected to find: $needle"
        echo "    In: $haystack"
        return 1
    fi
}

# ============================================================================
# Phase 1 Tests: Content Flag Validation
# ============================================================================

test_content_flags_no_conflicts() {
    echo "\n📦 Test: Content flag validation - no conflicts"

    _teach_validate_content_flags --explanation --math --examples
    local result=$?

    assert_equals "0" "$result" "No conflicts should pass"
}

test_content_flags_conflict_detection() {
    echo "\n📦 Test: Content flag validation - detect conflicts"

    # Capture stderr to avoid cluttering test output
    _teach_validate_content_flags --math --no-math 2>/dev/null
    local result=$?

    assert_equals "1" "$result" "Conflicting flags should fail"
}

test_content_flags_short_forms() {
    echo "\n📦 Test: Content flag validation - short forms"

    _teach_validate_content_flags -e -m -x
    local result=$?

    assert_equals "0" "$result" "Short form flags should pass"
}

test_content_flags_mixed_forms() {
    echo "\n📦 Test: Content flag validation - mixed forms"

    _teach_validate_content_flags --explanation -m --examples
    local result=$?

    assert_equals "0" "$result" "Mixed long/short forms should pass"
}

# ============================================================================
# Phase 1 Tests: Topic/Week Parsing
# ============================================================================

test_parse_topic_only() {
    echo "\n📦 Test: Topic/week parsing - topic only"

    _teach_parse_topic_week --topic "Linear Regression"

    assert_equals "Linear Regression" "$TEACH_TOPIC" "Topic should be parsed"
    assert_empty "$TEACH_WEEK" "Week should be empty"
}

test_parse_week_only() {
    echo "\n📦 Test: Topic/week parsing - week only"

    _teach_parse_topic_week --week 8

    assert_equals "8" "$TEACH_WEEK" "Week should be parsed"
    assert_empty "$TEACH_TOPIC" "Topic should be empty"
}

test_parse_topic_with_short_flag() {
    echo "\n📦 Test: Topic/week parsing - short flag -t"

    _teach_parse_topic_week -t "ANOVA"

    assert_equals "ANOVA" "$TEACH_TOPIC" "Topic should be parsed from -t"
}

test_parse_week_with_short_flag() {
    echo "\n📦 Test: Topic/week parsing - short flag -w"

    _teach_parse_topic_week -w 12

    assert_equals "12" "$TEACH_WEEK" "Week should be parsed from -w"
}

test_parse_both_topic_and_week() {
    echo "\n📦 Test: Topic/week parsing - both specified"

    # Should warn and use topic (stderr suppressed in test)
    _teach_parse_topic_week --topic "Regression" --week 8 2>/dev/null

    assert_equals "Regression" "$TEACH_TOPIC" "Topic should be set"
    assert_empty "$TEACH_WEEK" "Week should be cleared (topic takes precedence)"
}

test_parse_neither_topic_nor_week() {
    echo "\n📦 Test: Topic/week parsing - neither specified"

    _teach_parse_topic_week --verbose --dry-run

    assert_empty "$TEACH_TOPIC" "Topic should be empty"
    assert_empty "$TEACH_WEEK" "Week should be empty"
}

# ============================================================================
# Phase 2 Tests: Style Presets
# ============================================================================

test_preset_conceptual() {
    echo "\n📦 Test: Style preset - conceptual"

    _teach_resolve_content "conceptual"

    assert_contains "$TEACH_CONTENT_RESOLVED" "explanation" "Should include explanation"
    assert_contains "$TEACH_CONTENT_RESOLVED" "definitions" "Should include definitions"
    assert_contains "$TEACH_CONTENT_RESOLVED" "examples" "Should include examples"
}

test_preset_computational() {
    echo "\n📦 Test: Style preset - computational"

    _teach_resolve_content "computational"

    assert_contains "$TEACH_CONTENT_RESOLVED" "explanation" "Should include explanation"
    assert_contains "$TEACH_CONTENT_RESOLVED" "examples" "Should include examples"
    assert_contains "$TEACH_CONTENT_RESOLVED" "code" "Should include code"
    assert_contains "$TEACH_CONTENT_RESOLVED" "practice-problems" "Should include practice-problems"
}

test_preset_rigorous() {
    echo "\n📦 Test: Style preset - rigorous"

    _teach_resolve_content "rigorous"

    assert_contains "$TEACH_CONTENT_RESOLVED" "definitions" "Should include definitions"
    assert_contains "$TEACH_CONTENT_RESOLVED" "explanation" "Should include explanation"
    assert_contains "$TEACH_CONTENT_RESOLVED" "math" "Should include math"
    assert_contains "$TEACH_CONTENT_RESOLVED" "proof" "Should include proof"
}

test_preset_applied() {
    echo "\n📦 Test: Style preset - applied"

    _teach_resolve_content "applied"

    assert_contains "$TEACH_CONTENT_RESOLVED" "explanation" "Should include explanation"
    assert_contains "$TEACH_CONTENT_RESOLVED" "examples" "Should include examples"
    assert_contains "$TEACH_CONTENT_RESOLVED" "code" "Should include code"
    assert_contains "$TEACH_CONTENT_RESOLVED" "practice-problems" "Should include practice-problems"
}

test_preset_invalid() {
    echo "\n📦 Test: Style preset - invalid preset"

    _teach_resolve_content "invalid_preset" 2>/dev/null
    local result=$?

    assert_equals "1" "$result" "Invalid preset should fail"
}

# ============================================================================
# Phase 2 Tests: Content Resolution with Overrides
# ============================================================================

test_preset_with_addition() {
    echo "\n📦 Test: Content resolution - preset + addition"

    _teach_resolve_content "conceptual" --diagrams

    assert_contains "$TEACH_CONTENT_RESOLVED" "explanation" "Should include preset: explanation"
    assert_contains "$TEACH_CONTENT_RESOLVED" "diagrams" "Should include added: diagrams"
}

test_preset_with_removal() {
    echo "\n📦 Test: Content resolution - preset + removal"

    _teach_resolve_content "rigorous" --no-proof

    assert_contains "$TEACH_CONTENT_RESOLVED" "math" "Should include preset: math"

    # Check that proof is NOT in the resolved content
    if [[ "$TEACH_CONTENT_RESOLVED" == *"proof"* ]]; then
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
        echo "  ✗ Should exclude removed: proof"
    else
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
        echo "  ✓ Should exclude removed: proof"
    fi
}

test_preset_with_multiple_overrides() {
    echo "\n📦 Test: Content resolution - preset + multiple overrides"

    _teach_resolve_content "computational" --no-practice-problems --diagrams --references

    assert_contains "$TEACH_CONTENT_RESOLVED" "code" "Should include preset: code"
    assert_contains "$TEACH_CONTENT_RESOLVED" "diagrams" "Should include added: diagrams"
    assert_contains "$TEACH_CONTENT_RESOLVED" "references" "Should include added: references"

    # Check that practice-problems is NOT in the resolved content
    if [[ "$TEACH_CONTENT_RESOLVED" == *"practice-problems"* ]]; then
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
        echo "  ✗ Should exclude removed: practice-problems"
    else
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
        echo "  ✓ Should exclude removed: practice-problems"
    fi
}

test_no_preset_individual_flags() {
    echo "\n📦 Test: Content resolution - no preset, individual flags"

    _teach_resolve_content "" --math --code --examples

    assert_contains "$TEACH_CONTENT_RESOLVED" "math" "Should include: math"
    assert_contains "$TEACH_CONTENT_RESOLVED" "code" "Should include: code"
    assert_contains "$TEACH_CONTENT_RESOLVED" "examples" "Should include: examples"
}

# ============================================================================
# Phase 2 Tests: Content Instructions Builder
# ============================================================================

test_build_content_instructions() {
    echo "\n📦 Test: Content instructions builder"

    # Set up resolved content
    typeset -g TEACH_CONTENT_RESOLVED="explanation math examples"

    local instructions=$(_teach_build_content_instructions)

    assert_contains "$instructions" "conceptual explanations" "Should include explanation instruction"
    assert_contains "$instructions" "mathematical notation" "Should include math instruction"
    assert_contains "$instructions" "numerical examples" "Should include examples instruction"
}

test_build_content_instructions_empty() {
    echo "\n📦 Test: Content instructions builder - empty"

    # Set up empty resolved content
    typeset -g TEACH_CONTENT_RESOLVED=""

    local instructions=$(_teach_build_content_instructions)

    assert_empty "$instructions" "Instructions should be empty when no content flags"
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "╭──────────────────────────────────────────────────────────────╮"
echo "│ 🧪 Teach Dispatcher Phase 1-2 Unit Tests                    │"
echo "╰──────────────────────────────────────────────────────────────╯"

# Phase 1: Content Flag Validation
test_content_flags_no_conflicts
test_content_flags_conflict_detection
test_content_flags_short_forms
test_content_flags_mixed_forms

# Phase 1: Topic/Week Parsing
test_parse_topic_only
test_parse_week_only
test_parse_topic_with_short_flag
test_parse_week_with_short_flag
test_parse_both_topic_and_week
test_parse_neither_topic_nor_week

# Phase 2: Style Presets
test_preset_conceptual
test_preset_computational
test_preset_rigorous
test_preset_applied
test_preset_invalid

# Phase 2: Content Resolution
test_preset_with_addition
test_preset_with_removal
test_preset_with_multiple_overrides
test_no_preset_individual_flags

# Phase 2: Content Instructions
test_build_content_instructions
test_build_content_instructions_empty

# ============================================================================
# Test Summary
# ============================================================================

echo ""
echo "╭──────────────────────────────────────────────────────────────╮"
echo "│ 📊 Test Results                                              │"
echo "╰──────────────────────────────────────────────────────────────╯"
echo "  Total tests run:    $TESTS_RUN"
echo "  Tests passed:       $TESTS_PASSED"
echo "  Tests failed:       $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo "  ✅ All tests passed!"
    exit 0
else
    echo ""
    echo "  ❌ Some tests failed"
    exit 1
fi
