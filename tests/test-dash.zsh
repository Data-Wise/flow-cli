#!/usr/bin/env zsh
# Test script for dash command
# Tests: dashboard display, modes, categories, interactive features
# Generated: 2025-12-30

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    local project_root=""
    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi
    if [[ -z "$project_root" || ! -f "$project_root/commands/dash.zsh" ]]; then
        if [[ -f "$PWD/commands/dash.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/dash.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi
    if [[ -z "$project_root" || ! -f "$project_root/commands/dash.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source the plugin
    source "$project_root/flow.plugin.zsh" 2>/dev/null

    echo ""
}

# ============================================================================
# TESTS: dash command existence
# ============================================================================

test_dash_exists() {
    log_test "dash command exists"

    if type dash &>/dev/null; then
        pass
    else
        fail "dash command not found"
    fi
}

test_dash_help_exists() {
    log_test "_dash_help function exists"

    if type _dash_help &>/dev/null; then
        pass
    else
        fail "_dash_help function not found"
    fi
}

# ============================================================================
# TESTS: dash help output
# ============================================================================

test_dash_help_runs() {
    log_test "dash help runs without error"

    local output=$(dash help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_help_shows_usage() {
    log_test "dash help shows usage information"

    local output=$(dash help 2>&1)

    if [[ "$output" == *"dash"* && "$output" == *"-i"* ]]; then
        pass
    else
        fail "Help should show dash and -i option"
    fi
}

test_dash_help_shows_categories() {
    log_test "dash help shows category examples"

    local output=$(dash help 2>&1)

    if [[ "$output" == *"dev"* || "$output" == *"r"* || "$output" == *"research"* ]]; then
        pass
    else
        fail "Help should mention category names"
    fi
}

test_dash_help_flag() {
    log_test "dash --help works"

    local output=$(dash --help 2>&1)

    if [[ "$output" == *"dash"* ]]; then
        pass
    else
        fail "dash --help should show help"
    fi
}

test_dash_h_flag() {
    log_test "dash -h works"

    local output=$(dash -h 2>&1)

    if [[ "$output" == *"dash"* ]]; then
        pass
    else
        fail "dash -h should show help"
    fi
}

# ============================================================================
# TESTS: dash default output
# ============================================================================

test_dash_default_runs() {
    log_test "dash (no args) runs without error"

    local output=$(dash 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_default_shows_header() {
    log_test "dash shows dashboard header"

    local output=$(dash 2>&1)

    if [[ "$output" == *"FLOW DASHBOARD"* || "$output" == *"━"* ]]; then
        pass
    else
        fail "Should show dashboard header"
    fi
}

test_dash_no_errors() {
    log_test "dash output has no error patterns"

    local output=$(dash 2>&1)

    if [[ "$output" != *"error"* && "$output" != *"command not found"* && "$output" != *"undefined"* ]]; then
        pass
    else
        fail "Output contains error patterns"
    fi
}

# ============================================================================
# TESTS: dash modes
# ============================================================================

test_dash_all_flag() {
    log_test "dash --all runs without error"

    local output=$(dash --all 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_a_flag() {
    log_test "dash -a runs without error"

    local output=$(dash -a 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: dash categories
# ============================================================================

test_dash_category_dev() {
    log_test "dash dev runs without error"

    local output=$(dash dev 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_category_r() {
    log_test "dash r runs without error"

    local output=$(dash r 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_category_research() {
    log_test "dash research runs without error"

    local output=$(dash research 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_category_teach() {
    log_test "dash teach runs without error"

    local output=$(dash teach 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_category_quarto() {
    log_test "dash quarto runs without error"

    local output=$(dash quarto 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_dash_category_apps() {
    log_test "dash apps runs without error"

    local output=$(dash apps 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: DASH_CATEGORIES variable
# ============================================================================

test_dash_categories_defined() {
    log_test "DASH_CATEGORIES variable is defined"

    if [[ -n "${(k)DASH_CATEGORIES[@]}" ]]; then
        pass
    else
        fail "DASH_CATEGORIES not defined"
    fi
}

test_dash_categories_has_dev() {
    log_test "DASH_CATEGORIES has dev entry"

    if [[ -n "${DASH_CATEGORIES[dev]}" ]]; then
        pass
    else
        fail "DASH_CATEGORIES[dev] not found"
    fi
}

test_dash_categories_has_r() {
    log_test "DASH_CATEGORIES has r entry"

    if [[ -n "${DASH_CATEGORIES[r]}" ]]; then
        pass
    else
        fail "DASH_CATEGORIES[r] not found"
    fi
}

# ============================================================================
# TESTS: helper functions
# ============================================================================

test_dash_header_function() {
    log_test "_dash_header function exists"

    if type _dash_header &>/dev/null; then
        pass
    else
        fail "_dash_header not found"
    fi
}

test_dash_current_function() {
    log_test "_dash_current function exists"

    if type _dash_current &>/dev/null; then
        pass
    else
        fail "_dash_current not found"
    fi
}

test_dash_quick_access_function() {
    log_test "_dash_quick_access function exists"

    if type _dash_quick_access &>/dev/null; then
        pass
    else
        fail "_dash_quick_access not found"
    fi
}

test_dash_categories_function() {
    log_test "_dash_categories function exists"

    if type _dash_categories &>/dev/null; then
        pass
    else
        fail "_dash_categories not found"
    fi
}

test_dash_interactive_function() {
    log_test "_dash_interactive function exists"

    if type _dash_interactive &>/dev/null; then
        pass
    else
        fail "_dash_interactive not found"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Dash Command Tests${NC}"
    echo "${YELLOW}========================================${NC}"

    setup

    echo "${CYAN}--- Command existence tests ---${NC}"
    test_dash_exists
    test_dash_help_exists

    echo ""
    echo "${CYAN}--- Help output tests ---${NC}"
    test_dash_help_runs
    test_dash_help_shows_usage
    test_dash_help_shows_categories
    test_dash_help_flag
    test_dash_h_flag

    echo ""
    echo "${CYAN}--- Default output tests ---${NC}"
    test_dash_default_runs
    test_dash_default_shows_header
    test_dash_no_errors

    echo ""
    echo "${CYAN}--- Mode tests ---${NC}"
    test_dash_all_flag
    test_dash_a_flag

    echo ""
    echo "${CYAN}--- Category tests ---${NC}"
    test_dash_category_dev
    test_dash_category_r
    test_dash_category_research
    test_dash_category_teach
    test_dash_category_quarto
    test_dash_category_apps

    echo ""
    echo "${CYAN}--- Configuration tests ---${NC}"
    test_dash_categories_defined
    test_dash_categories_has_dev
    test_dash_categories_has_r

    echo ""
    echo "${CYAN}--- Helper function tests ---${NC}"
    test_dash_header_function
    test_dash_current_function
    test_dash_quick_access_function
    test_dash_categories_function
    test_dash_interactive_function

    # Summary
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Test Summary${NC}"
    echo "${YELLOW}========================================${NC}"
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
