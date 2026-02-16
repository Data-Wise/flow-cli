#!/usr/bin/env zsh
# Test script for dash command
# Tests: dashboard display, modes, categories, interactive features
# Generated: 2025-12-30
# Modernized: 2026-02-16 (shared test-framework.zsh)

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${RESET}"
        exit 1
    fi

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }

    # Close stdin to prevent any interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app" \
             "$TEST_ROOT/r-packages/active/mock-pkg" "$TEST_ROOT/teaching/stat-101" \
             "$TEST_ROOT/research/mock-study" "$TEST_ROOT/quarto/mock-site"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app \
               "$TEST_ROOT"/r-packages/active/mock-pkg "$TEST_ROOT"/teaching/stat-101 \
               "$TEST_ROOT"/research/mock-study "$TEST_ROOT"/quarto/mock-site; do
        echo "## Status: active\n## Progress: 50" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"
}

# ============================================================================
# CLEANUP
# ============================================================================

cleanup() {
    reset_mocks
    [[ -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}

# ============================================================================
# TESTS: dash command existence
# ============================================================================

test_dash_exists() {
    test_case "dash command exists"
    assert_function_exists "dash" && test_pass
}

test_dash_help_exists() {
    test_case "_dash_help function exists"
    assert_function_exists "_dash_help" && test_pass
}

# ============================================================================
# TESTS: dash help output
# ============================================================================

test_dash_help_runs() {
    test_case "dash help runs without error"
    local output=$(dash help 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "dash help should exit 0" && test_pass
}

test_dash_help_shows_usage() {
    test_case "dash help shows usage information"
    local output=$(dash help 2>&1)
    assert_contains "$output" "dash" "Help should mention dash" && \
    assert_contains "$output" "-i" "Help should show -i option" && test_pass
}

test_dash_help_shows_categories() {
    test_case "dash help shows category examples"
    local output=$(dash help 2>&1)
    # At least one category name should appear
    if [[ "$output" == *"dev"* || "$output" == *"r"* || "$output" == *"research"* ]]; then
        test_pass
    else
        test_fail "Help should mention category names"
    fi
}

test_dash_help_flag() {
    test_case "dash --help works"
    local output=$(dash --help 2>&1)
    assert_contains "$output" "dash" "dash --help should show help" && test_pass
}

test_dash_h_flag() {
    test_case "dash -h works"
    local output=$(dash -h 2>&1)
    assert_contains "$output" "dash" "dash -h should show help" && test_pass
}

# ============================================================================
# TESTS: dash default output
# ============================================================================

test_dash_default_runs() {
    test_case "dash (no args) runs without error"
    local output=$(dash 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "dash should exit 0"
    assert_not_contains "$output" "command not found" "dash should not produce 'command not found'" && test_pass
}

test_dash_default_shows_header() {
    test_case "dash shows dashboard header"
    local output=$(dash 2>&1)
    if [[ "$output" == *"FLOW DASHBOARD"* || "$output" == *"━"* ]]; then
        test_pass
    else
        test_fail "Should show dashboard header"
    fi
}

test_dash_no_errors() {
    test_case "dash output has no error patterns"
    local output=$(dash 2>&1)
    assert_not_contains "$output" "error" "Output should not contain 'error'"
    assert_not_contains "$output" "command not found" "Output should not contain 'command not found'"
    assert_not_contains "$output" "undefined" "Output should not contain 'undefined'" && test_pass
}

# ============================================================================
# TESTS: dash modes
# ============================================================================

test_dash_all_flag() {
    test_case "dash --all runs without error"
    local output=$(dash --all 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "dash --all should exit 0"
    assert_not_contains "$output" "command not found" "dash --all should not produce errors" && test_pass
}

test_dash_a_flag() {
    test_case "dash -a runs without error"
    local output=$(dash -a 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "dash -a should exit 0"
    assert_not_contains "$output" "command not found" "dash -a should not produce errors" && test_pass
}

# ============================================================================
# TESTS: dash categories
# ============================================================================

test_dash_category_dev() {
    test_case "dash dev runs without error"
    local output=$(dash dev 2>&1)
    assert_exit_code $? 0 "dash dev should exit 0"
    assert_not_contains "$output" "command not found" && test_pass
}

test_dash_category_r() {
    test_case "dash r runs without error"
    local output=$(dash r 2>&1)
    assert_exit_code $? 0 "dash r should exit 0"
    assert_not_contains "$output" "command not found" && test_pass
}

test_dash_category_research() {
    test_case "dash research runs without error"
    local output=$(dash research 2>&1)
    assert_exit_code $? 0 "dash research should exit 0"
    assert_not_contains "$output" "command not found" && test_pass
}

test_dash_category_teach() {
    test_case "dash teach runs without error"
    local output=$(dash teach 2>&1)
    assert_exit_code $? 0 "dash teach should exit 0"
    assert_not_contains "$output" "command not found" && test_pass
}

test_dash_category_quarto() {
    test_case "dash quarto runs without error"
    local output=$(dash quarto 2>&1)
    assert_exit_code $? 0 "dash quarto should exit 0"
    assert_not_contains "$output" "command not found" && test_pass
}

test_dash_category_apps() {
    test_case "dash apps runs without error"
    local output=$(dash apps 2>&1)
    assert_exit_code $? 0 "dash apps should exit 0"
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: DASH_CATEGORIES variable
# ============================================================================

test_dash_categories_defined() {
    test_case "DASH_CATEGORIES variable is defined"
    assert_not_empty "${(k)DASH_CATEGORIES[@]}" "DASH_CATEGORIES should be defined" && test_pass
}

test_dash_categories_has_dev() {
    test_case "DASH_CATEGORIES has dev entry"
    assert_not_empty "${DASH_CATEGORIES[dev]}" "DASH_CATEGORIES[dev] should exist" && test_pass
}

test_dash_categories_has_r() {
    test_case "DASH_CATEGORIES has r entry"
    assert_not_empty "${DASH_CATEGORIES[r]}" "DASH_CATEGORIES[r] should exist" && test_pass
}

# ============================================================================
# TESTS: helper functions
# ============================================================================

test_dash_header_function() {
    test_case "_dash_header function exists"
    assert_function_exists "_dash_header" && test_pass
}

test_dash_current_function() {
    test_case "_dash_current function exists"
    assert_function_exists "_dash_current" && test_pass
}

test_dash_quick_access_function() {
    test_case "_dash_quick_access function exists"
    assert_function_exists "_dash_quick_access" && test_pass
}

test_dash_categories_function() {
    test_case "_dash_categories function exists"
    assert_function_exists "_dash_categories" && test_pass
}

test_dash_interactive_function() {
    test_case "_dash_interactive function exists"
    assert_function_exists "_dash_interactive" && test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Dash Command Tests"

    setup

    echo "${CYAN}--- Command existence tests ---${RESET}"
    test_dash_exists
    test_dash_help_exists

    echo ""
    echo "${CYAN}--- Help output tests ---${RESET}"
    test_dash_help_runs
    test_dash_help_shows_usage
    test_dash_help_shows_categories
    test_dash_help_flag
    test_dash_h_flag

    echo ""
    echo "${CYAN}--- Default output tests ---${RESET}"
    test_dash_default_runs
    test_dash_default_shows_header
    test_dash_no_errors

    echo ""
    echo "${CYAN}--- Mode tests ---${RESET}"
    test_dash_all_flag
    test_dash_a_flag

    echo ""
    echo "${CYAN}--- Category tests ---${RESET}"
    test_dash_category_dev
    test_dash_category_r
    test_dash_category_research
    test_dash_category_teach
    test_dash_category_quarto
    test_dash_category_apps

    echo ""
    echo "${CYAN}--- Configuration tests ---${RESET}"
    test_dash_categories_defined
    test_dash_categories_has_dev
    test_dash_categories_has_r

    echo ""
    echo "${CYAN}--- Helper function tests ---${RESET}"
    test_dash_header_function
    test_dash_current_function
    test_dash_quick_access_function
    test_dash_categories_function
    test_dash_interactive_function

    # Cleanup and summary
    cleanup
    print_summary
    exit $?
}

main "$@"
