#!/bin/zsh
# test-smart-functions.zsh
# Unit tests for smart function dispatchers
# Created: 2025-12-14
# Run: zsh test-smart-functions.zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results array
typeset -a FAILED_TESTS

# Source the smart functions
SMART_FUNCS="$HOME/.config/zsh/functions/smart-dispatchers.zsh"
if [[ ! -f "$SMART_FUNCS" ]]; then
    echo "${RED}Error: Smart functions file not found: $SMART_FUNCS${NC}"
    exit 1
fi

source "$SMART_FUNCS"

# Test helper functions
assert_function_exists() {
    local func_name="$1"
    ((TESTS_RUN++))

    if typeset -f "$func_name" >/dev/null 2>&1; then
        echo "${GREEN}✓${NC} Test $TESTS_RUN: Function $func_name exists"
        ((TESTS_PASSED++))
        return 0
    else
        echo "${RED}✗${NC} Test $TESTS_RUN: Function $func_name does NOT exist"
        FAILED_TESTS+=("Test $TESTS_RUN: Function $func_name should exist")
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_help_works() {
    local func_name="$1"
    ((TESTS_RUN++))

    local output=$($func_name help 2>&1)

    if [[ -n "$output" && "$output" =~ "$func_name" ]]; then
        echo "${GREEN}✓${NC} Test $TESTS_RUN: $func_name help works"
        ((TESTS_PASSED++))
        return 0
    else
        echo "${RED}✗${NC} Test $TESTS_RUN: $func_name help FAILED"
        FAILED_TESTS+=("Test $TESTS_RUN: $func_name help should show help text")
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_output_contains() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    ((TESTS_RUN++))

    if [[ "$actual" =~ "$expected" ]]; then
        echo "${GREEN}✓${NC} Test $TESTS_RUN: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo "${RED}✗${NC} Test $TESTS_RUN: $test_name"
        echo "    Expected to contain: $expected"
        echo "    Got: ${actual:0:100}..."
        FAILED_TESTS+=("Test $TESTS_RUN: $test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_output_not_empty() {
    local test_name="$1"
    local actual="$2"
    ((TESTS_RUN++))

    if [[ -n "$actual" ]]; then
        echo "${GREEN}✓${NC} Test $TESTS_RUN: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo "${RED}✗${NC} Test $TESTS_RUN: $test_name"
        echo "    Expected non-empty output"
        FAILED_TESTS+=("Test $TESTS_RUN: $test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# ============================================
# Start Tests
# ============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Smart Function Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# Test 1-8: Function Existence
# ============================================

echo "📦 Testing Function Existence..."
assert_function_exists "r"
assert_function_exists "qu"
assert_function_exists "cc"
assert_function_exists "gm"
assert_function_exists "focus"
assert_function_exists "note"
assert_function_exists "obs"
assert_function_exists "workflow"
echo ""

# ============================================
# Test 9-16: Help Systems
# ============================================

echo "📚 Testing Help Systems..."
assert_help_works "r"
assert_help_works "qu"
assert_help_works "cc"
assert_help_works "gm"
assert_help_works "focus"
assert_help_works "note"
assert_help_works "obs"
assert_help_works "workflow"
echo ""

# ============================================
# Test 17-25: r() Function
# ============================================

echo "🔧 Testing r() function..."

# Test help contains expected sections
output=$(r help 2>&1)
assert_output_contains "r help contains CORE WORKFLOW" "CORE WORKFLOW" "$output"
assert_output_contains "r help contains COMBINED" "COMBINED" "$output"
assert_output_contains "r help contains SHORTCUTS STILL WORK" "SHORTCUTS STILL WORK" "$output"

# Test unknown action returns error
output=$(r unknown_action 2>&1)
assert_output_contains "r unknown_action shows error" "Unknown action" "$output"

# Test h alias for help
output=$(r h 2>&1)
assert_output_contains "r h works as help alias" "R Package Development" "$output"

# Test short aliases
output=$(r help 2>&1)
assert_output_contains "r help mentions 'r load'" "r load" "$output"
assert_output_contains "r help mentions 'r test'" "r test" "$output"
assert_output_contains "r help mentions 'r doc'" "r doc" "$output"
assert_output_contains "r help mentions 'r check'" "r check" "$output"

echo ""

# ============================================
# Test 26-32: qu() Function
# ============================================

echo "📝 Testing qu() function..."

# Test help with no arguments
output=$(qu 2>&1)
assert_output_contains "qu with no args shows help" "Quarto" "$output"

# Test help contains expected sections
output=$(qu help 2>&1)
assert_output_contains "qu help contains CORE" "CORE" "$output"
assert_output_contains "qu help contains preview" "preview" "$output"
assert_output_contains "qu help contains render" "render" "$output"

# Test unknown action
output=$(qu unknown_action 2>&1)
assert_output_contains "qu unknown_action shows error" "Unknown action" "$output"

# Test h alias
output=$(qu h 2>&1)
assert_output_contains "qu h works as help alias" "Quarto" "$output"

# Test shortcuts mentioned
output=$(qu help 2>&1)
assert_output_contains "qu help mentions qp shortcut" "qp" "$output"

echo ""

# ============================================
# Test 33-40: cc() Function
# ============================================

echo "🤖 Testing cc() function..."

# Test help
output=$(cc help 2>&1)
assert_output_contains "cc help contains SESSION" "SESSION" "$output"
assert_output_contains "cc help contains MODEL" "MODEL" "$output"
assert_output_contains "cc help contains PERMISSION" "PERMISSION" "$output"
assert_output_contains "cc help contains QUICK TASKS" "QUICK TASKS" "$output"

# Test session aliases
output=$(cc help 2>&1)
assert_output_contains "cc help mentions continue" "continue" "$output"
assert_output_contains "cc help mentions resume" "resume" "$output"
assert_output_contains "cc help mentions latest" "latest" "$output"

# Test model aliases
assert_output_contains "cc help mentions sonnet" "sonnet" "$output"
assert_output_contains "cc help mentions opus" "opus" "$output"

echo ""

# ============================================
# Test 41-48: gm() Function
# ============================================

echo "💎 Testing gm() function..."

# Test help
output=$(gm help 2>&1)
assert_output_contains "gm help contains POWER MODES" "POWER MODES" "$output"
assert_output_contains "gm help contains SESSION" "SESSION" "$output"
assert_output_contains "gm help contains MANAGEMENT" "MANAGEMENT" "$output"

# Test power modes
output=$(gm help 2>&1)
assert_output_contains "gm help mentions yolo" "yolo" "$output"
assert_output_contains "gm help mentions sandbox" "sandbox" "$output"
assert_output_contains "gm help mentions debug" "debug" "$output"

# Test h alias
output=$(gm h 2>&1)
assert_output_contains "gm h works as help alias" "Gemini" "$output"

# Test web search mentioned
assert_output_contains "gm help mentions web search" "web" "$output"

echo ""

# ============================================
# Test 49-56: focus() Function
# ============================================

echo "⏱️  Testing focus() function..."

# Test help
output=$(focus help 2>&1)
assert_output_contains "focus help contains START TIMER" "START TIMER" "$output"
assert_output_contains "focus help contains MANAGE" "MANAGE" "$output"

# Test timer durations mentioned
output=$(focus help 2>&1)
assert_output_contains "focus help mentions 15 min" "15" "$output"
assert_output_contains "focus help mentions 25 min" "25" "$output"
assert_output_contains "focus help mentions 50 min" "50" "$output"
assert_output_contains "focus help mentions 90 min" "90" "$output"

# Test management commands
assert_output_contains "focus help mentions check" "check" "$output"
assert_output_contains "focus help mentions stop" "stop" "$output"

echo ""

# ============================================
# Test 57-62: note() Function
# ============================================

echo "📔 Testing note() function..."

# Test help with no args
output=$(note 2>&1)
assert_output_contains "note with no args shows help" "Notes Sync" "$output"

# Test help sections
output=$(note help 2>&1)
assert_output_contains "note help contains SYNC" "SYNC" "$output"
assert_output_contains "note help contains STATUS" "STATUS" "$output"

# Test shortcuts mentioned
assert_output_contains "note help mentions ns" "ns" "$output"
assert_output_contains "note help mentions pstat" "pstat" "$output"

# Test unknown action
output=$(note unknown_action 2>&1)
assert_output_contains "note unknown_action shows error" "Unknown action" "$output"

echo ""

# ============================================
# Test 63-68: obs() Function
# ============================================

echo "📓 Testing obs() function..."

# Test help with no args
output=$(obs 2>&1)
assert_output_contains "obs with no args shows help" "Obsidian" "$output"

# Test help sections
output=$(obs help 2>&1)
assert_output_contains "obs help contains CORE" "CORE" "$output"
assert_output_contains "obs help contains PROJECT" "PROJECT" "$output"

# Test commands mentioned
assert_output_contains "obs help mentions dashboard" "dashboard" "$output"
assert_output_contains "obs help mentions sync" "sync" "$output"

# Test shortcuts
assert_output_contains "obs help mentions od" "od" "$output"

echo ""

# ============================================
# Test 69-75: workflow() Function
# ============================================

echo "📊 Testing workflow() function..."

# Test help
output=$(workflow help 2>&1)
assert_output_contains "workflow help contains VIEW" "VIEW" "$output"
assert_output_contains "workflow help contains SESSION" "SESSION" "$output"

# Test commands mentioned
output=$(workflow help 2>&1)
assert_output_contains "workflow help mentions today" "today" "$output"
assert_output_contains "workflow help mentions week" "week" "$output"
assert_output_contains "workflow help mentions started" "started" "$output"

# Test shortcuts
assert_output_contains "workflow help mentions wl" "wl" "$output"

# Test h alias
output=$(workflow h 2>&1)
assert_output_contains "workflow h works as help alias" "Activity Logging" "$output"

echo ""

# ============================================
# Test 76-80: Backward Compatibility
# ============================================

echo "🔄 Testing Backward Compatibility..."

# These functions should not interfere with existing aliases
# We test that the functions exist and work alongside the old system

# Test that full command names still work (via aliases in .zshrc)
# Note: We can't test these directly without sourcing full .zshrc
# but we can verify the functions themselves work

output=$(r help 2>&1)
assert_output_contains "r function preserves old alias info" "SHORTCUTS STILL WORK" "$output"

output=$(qu help 2>&1)
assert_output_contains "qu function preserves old alias info" "SHORTCUTS STILL WORK" "$output"

output=$(cc help 2>&1)
assert_output_contains "cc function preserves old alias info" "SHORTCUTS STILL WORK" "$output"

output=$(gm help 2>&1)
assert_output_contains "gm function preserves old alias info" "SHORTCUTS STILL WORK" "$output"

output=$(focus help 2>&1)
assert_output_contains "focus function preserves old alias info" "SHORTCUTS STILL WORK" "$output"

echo ""

# ============================================
# Test 81-85: Edge Cases
# ============================================

echo "🧪 Testing Edge Cases..."

# Test functions with empty strings
output=$(r "" 2>&1)
assert_output_contains "r with empty string shows error or help" "Unknown action" "$output"

# Test functions with special characters (should handle gracefully)
output=$(r "test;echo" 2>&1)
assert_output_contains "r with special chars shows error" "Unknown action" "$output"

# Test multiple help variations
output=$(r help 2>&1)
output2=$(r h 2>&1)
((TESTS_RUN++))
if [[ "$output" == "$output2" ]]; then
    echo "${GREEN}✓${NC} Test $TESTS_RUN: r help and r h produce same output"
    ((TESTS_PASSED++))
else
    echo "${RED}✗${NC} Test $TESTS_RUN: r help and r h should produce same output"
    FAILED_TESTS+=("Test $TESTS_RUN: r help and r h should match")
    ((TESTS_FAILED++))
fi

# Test that help doesn't execute commands
output=$(r help 2>&1)
((TESTS_RUN++))
if [[ ! "$output" =~ "Rscript" ]]; then
    echo "${GREEN}✓${NC} Test $TESTS_RUN: r help doesn't execute Rscript"
    ((TESTS_PASSED++))
else
    echo "${RED}✗${NC} Test $TESTS_RUN: r help shouldn't show Rscript execution"
    FAILED_TESTS+=("Test $TESTS_RUN: help should not execute commands")
    ((TESTS_FAILED++))
fi

# Test case sensitivity
output=$(r HELP 2>&1)
assert_output_contains "r HELP (uppercase) shows error" "Unknown action" "$output"

echo ""

# ============================================
# Test 86-90: Action Aliases
# ============================================

echo "🔗 Testing Action Aliases..."

# Test short action aliases work in help
output=$(r help 2>&1)
assert_output_contains "r help shows load|l" "load" "$output"

output=$(qu help 2>&1)
assert_output_contains "qu help shows preview|p" "preview" "$output"

output=$(cc help 2>&1)
assert_output_contains "cc help shows continue|c" "continue" "$output"

output=$(gm help 2>&1)
assert_output_contains "gm help shows sandbox|s" "sandbox" "$output"

output=$(focus help 2>&1)
assert_output_contains "focus help shows check|c" "check" "$output"

echo ""

# ============================================
# Summary
# ============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total Tests: $TESTS_RUN"
echo "${GREEN}Passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo "Failed: $TESTS_FAILED"
fi
echo ""

# Calculate pass rate
if [[ $TESTS_RUN -gt 0 ]]; then
    PASS_RATE=$(( TESTS_PASSED * 100 / TESTS_RUN ))
    echo "Pass Rate: $PASS_RATE%"
    echo ""
fi

# Show failed tests
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "${RED}Failed Tests:${NC}"
    for failed in "${FAILED_TESTS[@]}"; do
        echo "  - $failed"
    done
    echo ""
fi

# Exit code
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo "${RED}❌ Some tests failed${NC}"
    exit 1
fi
