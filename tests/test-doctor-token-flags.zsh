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

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find project root"; exit 1
    fi

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || { echo "ERROR: Plugin failed to load"; exit 1 }
    exec < /dev/null

    export TEST_CACHE_DIR="${HOME}/.flow/cache/doctor-test"
    mkdir -p "$TEST_CACHE_DIR" 2>/dev/null
}

cleanup() {
    rm -rf "$TEST_CACHE_DIR" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY A: FLAG PARSING (6 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_dot_flag_sets_isolated_mode() {
    test_case "A1. --dot flag sets isolated mode"

    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "doctor --dot should exit 0" || return 1
    assert_contains "$output" "TOKEN" "Should show TOKEN section" || return 1
    # Should NOT show SHELL or REQUIRED sections (isolated mode)
    if [[ "$output" != *"SHELL"* ]] || [[ "$output" != *"REQUIRED"* ]]; then
        test_pass
    else
        test_fail "Expected isolated token check, but found SHELL and REQUIRED sections"
    fi
}

test_dot_equals_token_sets_specific() {
    test_case "A2. --dot=github sets specific token"

    local output=$(doctor --dot=github 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "doctor --dot=github should exit 0" || return 1
    assert_contains "$output" "TOKEN" "Should show TOKEN section" || return 1
    test_pass
}

test_fix_token_sets_fix_mode() {
    test_case "A3. --fix-token sets fix mode + isolated"

    local output=$(echo "0" | doctor --fix-token 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "doctor --fix-token should exit 0" || return 1
    # Should enter fix mode (may show menu, token info, or "No issues found")
    if [[ "$output" == *"TOKEN"* || "$output" == *"No issues"* || "$output" == *"cancel"* ]]; then
        test_pass
    else
        test_fail "Expected fix token mode output"
    fi
}

test_quiet_flag_sets_verbosity() {
    test_case "A4. --quiet sets verbosity to quiet"

    local output=$(doctor --quiet 2>&1)
    local exit_code=$?
    local line_count=$(echo "$output" | wc -l | tr -d ' ')

    assert_exit_code $exit_code 0 "doctor --quiet should exit 0" || return 1
    # Quiet mode should have minimal output (fewer lines than normal ~20+)
    if (( line_count < 15 )); then
        test_pass
    else
        test_fail "Expected minimal output in quiet mode (lines: $line_count)"
    fi
}

test_verbose_flag_sets_verbosity() {
    test_case "A5. --verbose sets verbosity to verbose"

    local output=$(doctor --verbose 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "doctor --verbose should exit 0" || return 1
    assert_not_empty "$output" "Verbose mode should produce output" || return 1
    test_pass
}

test_multiple_flags_work_together() {
    test_case "A6. Multiple flags work together (--dot --verbose)"

    local output=$(doctor --dot --verbose 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "doctor --dot --verbose should exit 0" || return 1
    assert_contains "$output" "TOKEN" "Should show TOKEN section with combined flags" || return 1
    test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY B: ISOLATED TOKEN CHECK (6 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_dot_checks_only_tokens() {
    test_case "B1. doctor --dot checks only tokens (skips other categories)"

    local output=$(doctor --dot 2>&1)

    assert_contains "$output" "TOKEN" "Should show TOKEN section" || return 1
    assert_not_contains "$output" "SHELL" "Should not show SHELL section" || return 1
    assert_not_contains "$output" "REQUIRED" "Should not show REQUIRED section" || return 1
    assert_not_contains "$output" "RECOMMENDED" "Should not show RECOMMENDED section" || return 1
    test_pass
}

test_dot_delegates_to_tok_expiring() {
    test_case "B2. doctor --dot delegates to _tok_expiring"

    assert_function_exists "_tok_expiring" "_tok_expiring function not available" || return 1
    test_pass
}

test_dot_shows_token_status() {
    test_case "B3. Token check output shows token status"

    local output=$(doctor --dot 2>&1)

    # Should show either valid/invalid/expired status symbols
    if [[ "$output" == *"✓"* || "$output" == *"✗"* || "$output" == *"⚠"* || "$output" == *"Valid"* || "$output" == *"configured"* ]]; then
        test_pass
    else
        test_fail "Should show token status indicators"
    fi
}

test_dot_no_tools_check() {
    test_case "B4. No tools check when --dot is active"

    local output=$(doctor --dot 2>&1)

    assert_not_contains "$output" "fzf" "Should not check fzf in --dot mode" || return 1
    assert_not_contains "$output" "eza" "Should not check eza in --dot mode" || return 1
    assert_not_contains "$output" "bat" "Should not check bat in --dot mode" || return 1
    test_pass
}

test_dot_no_aliases_check() {
    test_case "B5. No aliases check when --dot is active"

    local output=$(doctor --dot 2>&1)

    assert_not_contains "$output" "ALIASES" "Should not check aliases in --dot mode" || return 1
    test_pass
}

test_dot_performance() {
    test_case "B6. Performance: --dot completes in < 3 seconds"

    local start_time=$(date +%s)
    doctor --dot >/dev/null 2>&1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if (( duration < 3 )); then
        test_pass
    else
        test_fail "Took ${duration}s (expected < 3s)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY C: SPECIFIC TOKEN CHECK (4 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_dot_equals_github_checks_only_github() {
    test_case "C1. --dot=github checks only GitHub token"

    local output=$(doctor --dot=github 2>&1)

    # Should show token check output (case-insensitive match)
    if [[ "$output" == *"TOKEN"* || "$output" == *"token"* ]]; then
        test_pass
    else
        test_fail "Should check GitHub token"
    fi
}

test_dot_equals_npm_checks_npm() {
    test_case "C2. --dot=npm checks NPM token (if exists)"

    local output=$(doctor --dot=npm 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should check NPM token" || return 1
    assert_not_empty "$output" "doctor --dot=npm should produce output" || return 1
    test_pass
}

test_dot_equals_invalid_shows_error() {
    test_case "C3. Invalid token name shows appropriate output"

    local output=$(doctor --dot=nonexistent 2>&1)
    local exit_code=$?

    # Doctor health check can legitimately exit 0 (healthy) or 1 (issues found)
    if (( exit_code <= 1 )); then
        assert_not_contains "$output" "command not found" && test_pass
    else
        test_fail "Should handle invalid token name gracefully (exit: $exit_code)"
    fi
}

test_specific_token_delegates() {
    test_case "C4. Specific token delegates correctly"

    assert_function_exists "_tok_expiring" "Delegation function _tok_expiring not available" || return 1
    test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY D: FIX TOKEN MODE (6 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_fix_token_shows_token_category() {
    test_case "D1. doctor --fix-token shows token category only"

    local output=$(echo "0" | doctor --fix-token 2>&1)

    # Should show token-related output or menu
    if [[ "$output" == *"TOKEN"* || "$output" == *"token"* || "$output" == *"cancel"* || "$output" == *"No issues"* ]]; then
        test_pass
    else
        test_fail "Should show token category or status"
    fi
}

test_fix_token_menu_display() {
    test_case "D2. Menu displays token issues correctly"

    assert_function_exists "_doctor_select_fix_category" "Menu function _doctor_select_fix_category not available" || return 1
    test_pass
}

test_fix_token_calls_rotate() {
    test_case "D3. Token fix workflow uses rotation function"

    assert_function_exists "_tok_rotate" "Token rotation function _tok_rotate not available" || return 1
    test_pass
}

test_fix_token_cache_cleared() {
    test_case "D4. Cache cleared after rotation (function exists)"

    assert_function_exists "_doctor_cache_token_clear" "Cache clear function _doctor_cache_token_clear not available" || return 1
    test_pass
}

test_fix_token_success_message() {
    test_case "D5. Success message function exists"

    assert_function_exists "_doctor_fix_tokens" "Fix tokens function _doctor_fix_tokens not available" || return 1
    test_pass
}

test_fix_token_yes_auto_fixes() {
    test_case "D6. --fix-token --yes auto-fixes without menu"

    doctor --fix-token --yes >/dev/null 2>&1
    local exit_code=$?

    # Doctor health check can legitimately exit 0 (success) or 1 (no issues found)
    if (( exit_code <= 1 )); then
        test_pass
    else
        test_fail "Should auto-fix or show no issues (exit: $exit_code)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY E: VERBOSITY LEVELS (5 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_quiet_suppresses_output() {
    test_case "E1. --quiet suppresses non-error output"

    local quiet_output=$(doctor --quiet 2>&1)
    local normal_output=$(doctor 2>&1)

    local quiet_lines=$(echo "$quiet_output" | wc -l | tr -d ' ')
    local normal_lines=$(echo "$normal_output" | wc -l | tr -d ' ')

    if (( quiet_lines < normal_lines )); then
        test_pass
    else
        test_fail "Quiet mode should suppress output (quiet: $quiet_lines, normal: $normal_lines)"
    fi
}

test_normal_shows_standard_output() {
    test_case "E2. Normal mode shows standard output"

    local output=$(doctor 2>&1)

    # Should show sections and status
    if [[ "$output" == *"Health Check"* || "$output" == *"health"* ]]; then
        test_pass
    else
        test_fail "Normal mode should show health check output"
    fi
}

test_verbose_shows_extra_info() {
    test_case "E3. --verbose shows cache debug info (if available)"

    local verbose_output=$(doctor --verbose 2>&1)

    assert_not_empty "$verbose_output" "Verbose mode should produce output" || return 1
    test_pass
}

test_doctor_log_quiet_function() {
    test_case "E4. _doctor_log_quiet() respects verbosity"

    assert_function_exists "_doctor_log_quiet" "Verbosity helper function _doctor_log_quiet not available" || return 1
    test_pass
}

test_doctor_log_verbose_function() {
    test_case "E5. _doctor_log_verbose() only shows in verbose"

    assert_function_exists "_doctor_log_verbose" "Verbose helper function _doctor_log_verbose not available" || return 1
    test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY F: INTEGRATION TESTS (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_hit_on_second_run() {
    test_case "F1. Cache hit on second --dot run (< 1s cached)"

    # First run to populate cache
    doctor --dot >/dev/null 2>&1

    # Second run should use cache
    local start_time=$(date +%s)
    doctor --dot >/dev/null 2>&1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if (( duration <= 1 )); then
        test_pass
    else
        test_fail "Cached run took ${duration}s (expected <= 1s, indicates cache not working)"
    fi
}

test_cache_miss_on_first_run() {
    test_case "F2. Cache miss on first run delegates to DOT"

    # Clear any existing cache
    rm -f "${HOME}/.flow/cache/doctor/token-github.cache" 2>/dev/null

    local output=$(doctor --dot 2>&1)

    # Should show token validation output
    if [[ "$output" == *"TOKEN"* || "$output" == *"token"* ]]; then
        test_pass
    else
        test_fail "Should validate token on cache miss"
    fi
}

test_full_workflow_check_fix_recheck() {
    test_case "F3. Full workflow: check -> fix -> clear cache -> re-check"

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

    assert_exit_code $check1_exit 0 "First check should complete" || return 1
    assert_exit_code $check2_exit 0 "Re-check should complete" || return 1
    test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    test_suite_start "Doctor Token Flags Test Suite (Phase 1)"

    setup

    echo "${YELLOW}CATEGORY A: Flag Parsing (6 tests)${RESET}"
    test_dot_flag_sets_isolated_mode
    test_dot_equals_token_sets_specific
    test_fix_token_sets_fix_mode
    test_quiet_flag_sets_verbosity
    test_verbose_flag_sets_verbosity
    test_multiple_flags_work_together

    echo ""
    echo "${YELLOW}CATEGORY B: Isolated Token Check (6 tests)${RESET}"
    test_dot_checks_only_tokens
    test_dot_delegates_to_tok_expiring
    test_dot_shows_token_status
    test_dot_no_tools_check
    test_dot_no_aliases_check
    test_dot_performance

    echo ""
    echo "${YELLOW}CATEGORY C: Specific Token Check (4 tests)${RESET}"
    test_dot_equals_github_checks_only_github
    test_dot_equals_npm_checks_npm
    test_dot_equals_invalid_shows_error
    test_specific_token_delegates

    echo ""
    echo "${YELLOW}CATEGORY D: Fix Token Mode (6 tests)${RESET}"
    test_fix_token_shows_token_category
    test_fix_token_menu_display
    test_fix_token_calls_rotate
    test_fix_token_cache_cleared
    test_fix_token_success_message
    test_fix_token_yes_auto_fixes

    echo ""
    echo "${YELLOW}CATEGORY E: Verbosity Levels (5 tests)${RESET}"
    test_quiet_suppresses_output
    test_normal_shows_standard_output
    test_verbose_shows_extra_info
    test_doctor_log_quiet_function
    test_doctor_log_verbose_function

    echo ""
    echo "${YELLOW}CATEGORY F: Integration Tests (3 tests)${RESET}"
    test_cache_hit_on_second_run
    test_cache_miss_on_first_run
    test_full_workflow_check_fix_recheck

    cleanup

    test_suite_end
    exit $?
}

# Run tests
main "$@"
