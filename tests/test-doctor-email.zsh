#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Doctor Email Integration
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate email doctor integration in commands/doctor.zsh
# Coverage: Function existence, conditional gates, tracking arrays,
#           config summary output, semver comparison
#
# Test Categories:
#   1. Function Existence (5 tests)
#   2. Conditional Gate: em loaded (1 test)
#   3. Conditional Gate: em NOT loaded (1 test)
#   4. Tracking Arrays (2 tests)
#   5. Config Summary Output (2 tests)
#   6. Semver Comparison (2 tests)
#
# Created: 2026-02-12
# ══════════════════════════════════════════════════════════════════════════════

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

# Resolve project root at top level (${0:A} doesn't work inside functions)
SCRIPT_DIR="${0:A:h}"
FLOW_ROOT="${SCRIPT_DIR:h}"

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    if [[ ! -f "$FLOW_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root at $FLOW_ROOT${NC}"
        exit 1
    fi

    echo "  Project root: $FLOW_ROOT"

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    export FLOW_QUIET FLOW_ATLAS_ENABLED

    source "$FLOW_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${NC}"
        exit 1
    }

    # Close stdin to prevent any interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    trap "rm -rf '$TEST_ROOT'" EXIT
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev"
    echo "## Status: active\n## Progress: 50" > "$TEST_ROOT/dev-tools/mock-dev/.STATUS"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 1: FUNCTION EXISTENCE (5 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_doctor_check_email_exists() {
    log_test "_doctor_check_email function exists"

    if (( ${+functions[_doctor_check_email]} )); then
        pass
    else
        fail "_doctor_check_email not found after sourcing"
    fi
}

test_doctor_check_email_cmd_exists() {
    log_test "_doctor_check_email_cmd function exists"

    if (( ${+functions[_doctor_check_email_cmd]} )); then
        pass
    else
        fail "_doctor_check_email_cmd not found after sourcing"
    fi
}

test_doctor_email_connectivity_exists() {
    log_test "_doctor_email_connectivity function exists"

    if (( ${+functions[_doctor_email_connectivity]} )); then
        pass
    else
        fail "_doctor_email_connectivity not found after sourcing"
    fi
}

test_doctor_email_setup_exists() {
    log_test "_doctor_email_setup function exists"

    if (( ${+functions[_doctor_email_setup]} )); then
        pass
    else
        fail "_doctor_email_setup not found after sourcing"
    fi
}

test_doctor_fix_email_exists() {
    log_test "_doctor_fix_email function exists"

    if (( ${+functions[_doctor_fix_email]} )); then
        pass
    else
        fail "_doctor_fix_email not found after sourcing"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 2: CONDITIONAL GATE — em LOADED (1 test)
# ══════════════════════════════════════════════════════════════════════════════

test_email_section_shown_when_em_loaded() {
    log_test "doctor output contains EMAIL section when em() is loaded"

    # Define a stub em() so the conditional gate fires
    em() { : }

    local output=$(doctor 2>&1)

    # Clean up stub
    unfunction em 2>/dev/null

    if echo "$output" | grep -q "EMAIL"; then
        pass
    else
        fail "Expected 'EMAIL' section header in output"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 3: CONDITIONAL GATE — em NOT LOADED (1 test)
# ══════════════════════════════════════════════════════════════════════════════

test_email_section_hidden_when_em_not_loaded() {
    log_test "doctor output does NOT contain EMAIL when em() is absent"

    # Ensure no em function exists
    unfunction em 2>/dev/null

    local output=$(doctor 2>&1)

    if echo "$output" | grep -q "EMAIL"; then
        fail "EMAIL section should not appear without em() loaded"
    else
        pass
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 4: TRACKING ARRAYS (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_missing_email_brew_is_array() {
    log_test "_doctor_missing_email_brew is an array after doctor run (em loaded)"

    # Define stub em() for the gate
    em() { : }

    doctor >/dev/null 2>&1

    # Clean up stub
    unfunction em 2>/dev/null

    local var_type="${(t)_doctor_missing_email_brew}"

    if [[ "$var_type" == *array* ]]; then
        pass
    else
        fail "Expected array type, got: ${var_type:-undefined}"
    fi
}

test_missing_email_pip_is_array() {
    log_test "_doctor_missing_email_pip is an array after doctor run (em loaded)"

    # Define stub em() for the gate
    em() { : }

    doctor >/dev/null 2>&1

    # Clean up stub
    unfunction em 2>/dev/null

    local var_type="${(t)_doctor_missing_email_pip}"

    if [[ "$var_type" == *array* ]]; then
        pass
    else
        fail "Expected array type, got: ${var_type:-undefined}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 5: CONFIG SUMMARY OUTPUT (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_config_label_in_output() {
    log_test "doctor output contains 'Config:' when em is loaded"

    # Define stub em()
    em() { : }

    local output=$(doctor 2>&1)

    # Clean up stub
    unfunction em 2>/dev/null

    if echo "$output" | grep -q "Config:"; then
        pass
    else
        fail "Expected 'Config:' label in email section output"
    fi
}

test_ai_backend_in_output() {
    log_test "doctor output contains 'AI backend:' when em is loaded"

    # Define stub em()
    em() { : }

    local output=$(doctor 2>&1)

    # Clean up stub
    unfunction em 2>/dev/null

    if echo "$output" | grep -q "AI backend:"; then
        pass
    else
        fail "Expected 'AI backend:' in email config summary"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 6: SEMVER COMPARISON (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_semver_lt_returns_true_when_less() {
    log_test "_em_semver_lt 0.9.0 < 1.0.0 returns 0 (true)"

    # Ensure the function is available (loaded via email-dispatcher)
    if ! (( ${+functions[_em_semver_lt]} )); then
        # Try sourcing email dispatcher directly
        source "$FLOW_ROOT/lib/dispatchers/email-dispatcher.zsh" 2>/dev/null
    fi

    if (( ${+functions[_em_semver_lt]} )); then
        if _em_semver_lt "0.9.0" "1.0.0"; then
            pass
        else
            fail "0.9.0 should be less than 1.0.0"
        fi
    else
        fail "_em_semver_lt function not available"
    fi
}

test_semver_lt_returns_false_when_greater() {
    log_test "_em_semver_lt 1.1.0 < 1.0.0 returns 1 (false)"

    if (( ${+functions[_em_semver_lt]} )); then
        if _em_semver_lt "1.1.0" "1.0.0"; then
            fail "1.1.0 should NOT be less than 1.0.0"
        else
            pass
        fi
    else
        fail "_em_semver_lt function not available"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Doctor Email Integration Test Suite${NC}                  │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 1: Function Existence (5 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_doctor_check_email_exists
    test_doctor_check_email_cmd_exists
    test_doctor_email_connectivity_exists
    test_doctor_email_setup_exists
    test_doctor_fix_email_exists

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 2: Conditional Gate — em loaded (1 test)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_email_section_shown_when_em_loaded

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 3: Conditional Gate — em NOT loaded (1 test)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_email_section_hidden_when_em_not_loaded

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 4: Tracking Arrays (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_missing_email_brew_is_array
    test_missing_email_pip_is_array

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 5: Config Summary Output (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_config_label_in_output
    test_ai_backend_in_output

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 6: Semver Comparison (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_semver_lt_returns_true_when_less
    test_semver_lt_returns_false_when_greater

    # Summary
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Test Summary${NC}                                         │"
    echo "╰─────────────────────────────────────────────────────────╯"
    echo ""
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  ${CYAN}Total:${NC}  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All email doctor tests passed!${NC}"
        echo ""
        return 0
    else
        echo "${RED}✗ Some email doctor tests failed${NC}"
        echo ""
        return 1
    fi
}

main "$@"
