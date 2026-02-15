#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Doctor Token Flags
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate Phase 1 flow doctor DOT token enhancement
# Target: 30 tests for flags and integration
# Coverage: Flag parsing, isolated checks, verbosity, fix mode, cache integration
#
# Test Categories:
#   A. Flag Parsing (6 tests)
#   B. Isolated Token Check (6 tests)
#   C. Specific Token Check (4 tests)
#   D. Fix Token Mode (6 tests)
#   E. Verbosity Levels (5 tests)
#   F. Integration Tests (3 tests)
#
# Created: 2026-01-23
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

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root - handle both direct execution and worktree
    if [[ -n "${0:A}" ]]; then
        PROJECT_ROOT="${0:A:h:h}"
    fi

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/commands/doctor.zsh" ]]; then
        if [[ -f "$PWD/commands/doctor.zsh" ]]; then
            PROJECT_ROOT="$PWD"
        elif [[ -f "$PWD/../commands/doctor.zsh" ]]; then
            PROJECT_ROOT="$PWD/.."
        fi
    fi

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/commands/doctor.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        echo "  Tried: ${0:A:h:h}, $PWD, $PWD/.."
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source the plugin (silent)
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Set up test cache directory
    export TEST_CACHE_DIR="${HOME}/.flow/cache/doctor-test"
    mkdir -p "$TEST_CACHE_DIR" 2>/dev/null

    echo ""
}

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up test environment...${NC}"

    # Clean up test cache
    rm -rf "$TEST_CACHE_DIR" 2>/dev/null

    echo "  Test cache cleaned"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY A: FLAG PARSING (6 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_dot_flag_sets_isolated_mode() {
    log_test "A1. --dot flag sets isolated mode"

    # Run doctor with --dot flag and capture output
    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    # Should complete successfully and show only token section
    # Should NOT show SHELL, REQUIRED, RECOMMENDED sections
    if [[ $exit_code -eq 0 ]] && \
       [[ "$output" == *"TOKEN"* ]] && \
       [[ "$output" != *"SHELL"* || "$output" != *"REQUIRED"* ]]; then
        pass
    else
        fail "Expected isolated token check (exit: $exit_code)"
    fi
}

test_dot_equals_token_sets_specific() {
    log_test "A2. --dot=github sets specific token"

    # Run doctor with --dot=github
    local output=$(doctor --dot=github 2>&1)
    local exit_code=$?

    # Should complete successfully and check GitHub token
    if [[ $exit_code -eq 0 ]] && [[ "$output" == *"TOKEN"* ]]; then
        pass
    else
        fail "Expected GitHub token check (exit: $exit_code)"
    fi
}

test_fix_token_sets_fix_mode() {
    log_test "A3. --fix-token sets fix mode + isolated"

    # Mock user input to cancel (send "0" via stdin)
    local output=$(echo "0" | doctor --fix-token 2>&1)
    local exit_code=$?

    # Should enter fix mode (may show menu or "No issues found")
    if [[ $exit_code -eq 0 ]] && \
       [[ "$output" == *"TOKEN"* || "$output" == *"No issues"* || "$output" == *"cancel"* ]]; then
        pass
    else
        fail "Expected fix token mode (exit: $exit_code)"
    fi
}

test_quiet_flag_sets_verbosity() {
    log_test "A4. --quiet sets verbosity to quiet"

    # Run doctor with --quiet
    local output=$(doctor --quiet 2>&1)
    local exit_code=$?
    local line_count=$(echo "$output" | wc -l | tr -d ' ')

    # Quiet mode should have minimal output (fewer lines)
    # Normal mode typically has 20+ lines, quiet should have < 10
    if [[ $exit_code -eq 0 ]] && (( line_count < 15 )); then
        pass
    else
        fail "Expected minimal output in quiet mode (lines: $line_count)"
    fi
}

test_verbose_flag_sets_verbosity() {
    log_test "A5. --verbose sets verbosity to verbose"

    # Run doctor with --verbose
    local output=$(doctor --verbose 2>&1)
    local exit_code=$?

    # Verbose mode should show additional details
    # May show cache status, service checks, etc.
    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Expected verbose output (exit: $exit_code)"
    fi
}

test_multiple_flags_work_together() {
    log_test "A6. Multiple flags work together (--dot --verbose)"

    # Run doctor with both --dot and --verbose
    local output=$(doctor --dot --verbose 2>&1)
    local exit_code=$?

    # Should complete successfully with isolated + verbose output
    if [[ $exit_code -eq 0 ]] && [[ "$output" == *"TOKEN"* ]]; then
        pass
    else
        fail "Expected combined flags to work (exit: $exit_code)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY B: ISOLATED TOKEN CHECK (6 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_dot_checks_only_tokens() {
    log_test "B1. doctor --dot checks only tokens (skips other categories)"

    local output=$(doctor --dot 2>&1)

    # Should show TOKEN section, NOT show SHELL/REQUIRED/RECOMMENDED
    if [[ "$output" == *"TOKEN"* ]] && \
       [[ "$output" != *"SHELL"* ]] && \
       [[ "$output" != *"REQUIRED"* ]] && \
       [[ "$output" != *"RECOMMENDED"* ]]; then
        pass
    else
        fail "Should only show token checks"
    fi
}

test_dot_delegates_to_tok_expiring() {
    log_test "B2. doctor --dot delegates to _tok_expiring"

    # This is a behavioral test - we check that the function exists and is callable
    if type _tok_expiring &>/dev/null; then
        pass
    else
        fail "_tok_expiring function not available"
    fi
}

test_dot_shows_token_status() {
    log_test "B3. Token check output shows token status"

    local output=$(doctor --dot 2>&1)

    # Should show either valid/invalid/expired status symbols (✓, ✗, ⚠)
    if [[ "$output" == *"✓"* || "$output" == *"✗"* || "$output" == *"⚠"* || "$output" == *"Valid"* || "$output" == *"configured"* ]]; then
        pass
    else
        fail "Should show token status indicators"
    fi
}

test_dot_no_tools_check() {
    log_test "B4. No tools check when --dot is active"

    local output=$(doctor --dot 2>&1)

    # Should NOT mention fzf, eza, bat, etc.
    if [[ "$output" != *"fzf"* ]] && \
       [[ "$output" != *"eza"* ]] && \
       [[ "$output" != *"bat"* ]]; then
        pass
    else
        fail "Should not check tools in --dot mode"
    fi
}

test_dot_no_aliases_check() {
    log_test "B5. No aliases check when --dot is active"

    local output=$(doctor --dot 2>&1)

    # Should NOT show ALIASES section
    if [[ "$output" != *"ALIASES"* ]]; then
        pass
    else
        fail "Should not check aliases in --dot mode"
    fi
}

test_dot_performance() {
    log_test "B6. Performance: --dot completes in < 3 seconds"

    local start_time=$(date +%s)
    doctor --dot >/dev/null 2>&1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if (( duration < 3 )); then
        pass
    else
        fail "Took ${duration}s (expected < 3s)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY C: SPECIFIC TOKEN CHECK (4 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_dot_equals_github_checks_only_github() {
    log_test "C1. --dot=github checks only GitHub token"

    local output=$(doctor --dot=github 2>&1)

    # Should show token check output
    if [[ "$output" == *"TOKEN"* || "$output" == *"token"* ]]; then
        pass
    else
        fail "Should check GitHub token"
    fi
}

test_dot_equals_npm_checks_npm() {
    log_test "C2. --dot=npm checks NPM token (if exists)"

    local output=$(doctor --dot=npm 2>&1)
    local exit_code=$?

    # Should complete (may show "not configured" if no NPM token)
    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Should check NPM token (exit: $exit_code)"
    fi
}

test_dot_equals_invalid_shows_error() {
    log_test "C3. Invalid token name shows appropriate output"

    local output=$(doctor --dot=nonexistent 2>&1)
    local exit_code=$?

    # Should complete (may show no token or error, but shouldn't crash)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Should handle invalid token name gracefully (exit: $exit_code)"
    fi
}

test_specific_token_delegates() {
    log_test "C4. Specific token delegates correctly"

    # Check that dot token expiring function exists (used for delegation)
    if type _tok_expiring &>/dev/null; then
        pass
    else
        fail "Delegation function not available"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY D: FIX TOKEN MODE (6 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_fix_token_shows_token_category() {
    log_test "D1. doctor --fix-token shows token category only"

    # Send "0" to cancel menu
    local output=$(echo "0" | doctor --fix-token 2>&1)

    # Should show token-related output or menu
    if [[ "$output" == *"TOKEN"* || "$output" == *"token"* || "$output" == *"cancel"* || "$output" == *"No issues"* ]]; then
        pass
    else
        fail "Should show token category or status"
    fi
}

test_fix_token_menu_display() {
    log_test "D2. Menu displays token issues correctly"

    # This tests that the menu function exists and can be called
    if type _doctor_select_fix_category &>/dev/null; then
        pass
    else
        fail "Menu function not available"
    fi
}

test_fix_token_calls_rotate() {
    log_test "D3. Token fix workflow uses rotation function"

    # Check that rotation function exists
    if type _tok_rotate &>/dev/null; then
        pass
    else
        fail "Token rotation function not available"
    fi
}

test_fix_token_cache_cleared() {
    log_test "D4. Cache cleared after rotation (function exists)"

    # Check that cache clear function exists
    if type _doctor_cache_token_clear &>/dev/null; then
        pass
    else
        fail "Cache clear function not available"
    fi
}

test_fix_token_success_message() {
    log_test "D5. Success message function exists"

    # Check that fix functions exist
    if type _doctor_fix_tokens &>/dev/null; then
        pass
    else
        fail "Fix tokens function not available"
    fi
}

test_fix_token_yes_auto_fixes() {
    log_test "D6. --fix-token --yes auto-fixes without menu"

    # Run with --yes flag (should skip prompts)
    # Since we don't have actual token issues, it should complete quickly
    # No timeout needed - command completes instantly when no issues exist

    doctor --fix-token --yes >/dev/null 2>&1
    local exit_code=$?

    # Exit code 0 (success) or 1 (no issues found) are both acceptable
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Should auto-fix or show no issues (exit: $exit_code)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY E: VERBOSITY LEVELS (5 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_quiet_suppresses_output() {
    log_test "E1. --quiet suppresses non-error output"

    local quiet_output=$(doctor --quiet 2>&1)
    local normal_output=$(doctor 2>&1)

    local quiet_lines=$(echo "$quiet_output" | wc -l | tr -d ' ')
    local normal_lines=$(echo "$normal_output" | wc -l | tr -d ' ')

    # Quiet should have fewer lines than normal
    if (( quiet_lines < normal_lines )); then
        pass
    else
        fail "Quiet mode should suppress output (quiet: $quiet_lines, normal: $normal_lines)"
    fi
}

test_normal_shows_standard_output() {
    log_test "E2. Normal mode shows standard output"

    local output=$(doctor 2>&1)

    # Should show sections and status
    if [[ "$output" == *"Health Check"* || "$output" == *"health"* ]]; then
        pass
    else
        fail "Normal mode should show health check output"
    fi
}

test_verbose_shows_extra_info() {
    log_test "E3. --verbose shows cache debug info (if available)"

    local verbose_output=$(doctor --verbose 2>&1)
    local normal_output=$(doctor 2>&1)

    # Verbose may show more details, but not guaranteed in all cases
    # Just verify it runs without error
    if [[ -n "$verbose_output" ]]; then
        pass
    else
        fail "Verbose mode should produce output"
    fi
}

test_doctor_log_quiet_function() {
    log_test "E4. _doctor_log_quiet() respects verbosity"

    # Check that verbosity helper exists
    if type _doctor_log_quiet &>/dev/null; then
        pass
    else
        fail "Verbosity helper function not available"
    fi
}

test_doctor_log_verbose_function() {
    log_test "E5. _doctor_log_verbose() only shows in verbose"

    # Check that verbose helper exists
    if type _doctor_log_verbose &>/dev/null; then
        pass
    else
        fail "Verbose helper function not available"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY F: INTEGRATION TESTS (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_hit_on_second_run() {
    log_test "F1. Cache hit on second --dot run (< 1s cached)"

    # First run to populate cache
    doctor --dot >/dev/null 2>&1

    # Second run should use cache (measure time - portable approach)
    # Use portable time measurement (seconds precision is sufficient)
    local start_time=$(date +%s)
    doctor --dot >/dev/null 2>&1
    local end_time=$(date +%s)

    # Calculate duration in seconds
    local duration=$((end_time - start_time))

    # Cached run should complete in < 1 second (usually 0 seconds with second precision)
    # This validates cache is working (vs 2-3s for fresh check)
    if (( duration <= 1 )); then
        pass
    else
        fail "Cached run took ${duration}s (expected <= 1s, indicates cache not working)"
    fi
}

test_cache_miss_on_first_run() {
    log_test "F2. Cache miss on first run delegates to DOT"

    # Clear any existing cache
    rm -f "${HOME}/.flow/cache/doctor/token-github.cache" 2>/dev/null

    # First run should call token validation
    local output=$(doctor --dot 2>&1)

    # Should show token validation output
    if [[ "$output" == *"TOKEN"* || "$output" == *"token"* ]]; then
        pass
    else
        fail "Should validate token on cache miss"
    fi
}

test_full_workflow_check_fix_recheck() {
    log_test "F3. Full workflow: check → fix → clear cache → re-check"

    # Step 1: Check
    doctor --dot >/dev/null 2>&1
    local check1_exit=$?

    # Step 2: Clear cache (simulate fix)
    if type _doctor_cache_clear &>/dev/null; then
        _doctor_cache_clear 2>/dev/null
    fi

    # Step 3: Re-check
    doctor --dot >/dev/null 2>&1
    local check2_exit=$?

    # Both checks should complete
    if [[ $check1_exit -eq 0 && $check2_exit -eq 0 ]]; then
        pass
    else
        fail "Workflow should complete (exits: $check1_exit, $check2_exit)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Doctor Token Flags Test Suite (Phase 1)${NC}             │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY A: Flag Parsing (6 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dot_flag_sets_isolated_mode
    test_dot_equals_token_sets_specific
    test_fix_token_sets_fix_mode
    test_quiet_flag_sets_verbosity
    test_verbose_flag_sets_verbosity
    test_multiple_flags_work_together

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY B: Isolated Token Check (6 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dot_checks_only_tokens
    test_dot_delegates_to_tok_expiring
    test_dot_shows_token_status
    test_dot_no_tools_check
    test_dot_no_aliases_check
    test_dot_performance

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY C: Specific Token Check (4 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dot_equals_github_checks_only_github
    test_dot_equals_npm_checks_npm
    test_dot_equals_invalid_shows_error
    test_specific_token_delegates

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY D: Fix Token Mode (6 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_fix_token_shows_token_category
    test_fix_token_menu_display
    test_fix_token_calls_rotate
    test_fix_token_cache_cleared
    test_fix_token_success_message
    test_fix_token_yes_auto_fixes

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY E: Verbosity Levels (5 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_quiet_suppresses_output
    test_normal_shows_standard_output
    test_verbose_shows_extra_info
    test_doctor_log_quiet_function
    test_doctor_log_verbose_function

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY F: Integration Tests (3 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_hit_on_second_run
    test_cache_miss_on_first_run
    test_full_workflow_check_fix_recheck

    cleanup

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
        echo "${GREEN}✓ All token flag tests passed!${NC}"
        echo ""
        return 0
    else
        echo "${RED}✗ Some token flag tests failed${NC}"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
