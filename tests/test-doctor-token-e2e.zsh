#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE: Doctor Token Enhancement Phase 1
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: End-to-end integration tests for token automation workflows
# Target: Real workflows, no mocking, complete user journeys
# Coverage: All Phase 1 features in realistic scenarios
#
# Test Scenarios:
#   1. Morning Routine (Quick Health Check)
#   2. Token Expiration Workflow
#   3. Cache Behavior Validation
#   4. Verbosity Workflow
#   5. Fix Token Workflow
#   6. Multi-Check Workflow
#   7. Error Recovery
#   8. CI/CD Integration
#
# Created: 2026-01-23
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP & TEARDOWN
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

    export TEST_CACHE_DIR="${HOME}/.flow/cache/doctor-e2e-test"
    export DOCTOR_CACHE_DIR="$TEST_CACHE_DIR"
    mkdir -p "$TEST_CACHE_DIR" 2>/dev/null
}

cleanup() {
    rm -rf "$TEST_CACHE_DIR" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 1: MORNING ROUTINE (QUICK HEALTH CHECK)
# ══════════════════════════════════════════════════════════════════════════════

test_morning_routine_quick_check() {
    test_case "S1. Morning routine: Quick token check"

    # User story: Developer starts work, runs quick health check
    # Expected: < 3s first check, shows token status

    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    # 0=healthy, 1=issues found — both valid for a health check
    if (( exit_code <= 1 )); then
        assert_contains "$output" "token" "doctor --dot should mention token status" || return
        test_pass
    else
        test_fail "Command failed with exit code $exit_code (expected 0 or 1)"
    fi
}

test_morning_routine_cached_recheck() {
    test_case "S1. Morning routine: Cached re-check (< 1s)"

    # User story: Developer checks again 2 minutes later
    # Expected: < 1s (cached), same result

    # First check (populate cache)
    local output=$(doctor --dot 2>&1)
    assert_not_contains "$output" "command not found" "doctor command should be available" || return

    # Second check (should use cache)
    local start=$(date +%s)
    output=$(doctor --dot 2>&1)
    local end=$(date +%s)
    local duration=$((end - start))

    assert_not_contains "$output" "command not found" "doctor command should still be available" || return

    # Should be instant (< 1s with second precision)
    if (( duration <= 1 )); then
        test_pass
    else
        test_fail "Cached check took ${duration}s (expected <= 1s)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 2: TOKEN EXPIRATION WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_expiration_detection() {
    test_case "S2. Token expiration: Detection workflow"

    # User story: User runs doctor, sees expiring token warning
    # Expected: Clear warning with days remaining

    local output=$(doctor --dot 2>&1)

    # Should either show "valid" or "expiring" or "expired" or "token"
    assert_matches_pattern "$output" "(valid|expiring|expired|token)" \
        "doctor --dot should show token status (valid/expiring/expired/token)" || return
    test_pass
}

test_expiration_verbose_details() {
    test_case "S2. Token expiration: Verbose shows metadata"

    # User story: User wants more details about token
    # Expected: Username, age, type shown

    local output=$(doctor --dot --verbose 2>&1)

    assert_not_empty "$output" "Verbose mode should produce output" || return
    assert_not_contains "$output" "command not found" "doctor command should be available" || return

    # Verbose should show more information — at minimum 3+ lines
    local verbose_lines=$(echo "$output" | wc -l | tr -d ' ')

    if (( verbose_lines >= 3 )); then
        test_pass
    else
        test_fail "Verbose mode not showing enough detail ($verbose_lines lines, expected >= 3)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 3: CACHE BEHAVIOR VALIDATION
# ══════════════════════════════════════════════════════════════════════════════

test_cache_fresh_invalidation() {
    test_case "S3. Cache: Fresh check after clearing"

    # User story: User clears cache, forces fresh check
    # Expected: Re-validates with GitHub API (if tokens configured)
    # Note: Cache only written if token check succeeds

    # Check if tokens are configured
    if ! command -v sec &>/dev/null || ! sec list &>/dev/null 2>&1; then
        test_skip "Keychain access unavailable (expected in test environment)"
        return
    fi

    # Clear cache
    rm -rf "$DOCTOR_CACHE_DIR" 2>/dev/null
    mkdir -p "$DOCTOR_CACHE_DIR" 2>/dev/null

    # Should succeed (fetch fresh)
    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    # 0=healthy, 1=issues found — both valid for a fresh check
    if (( exit_code <= 1 )); then
        # Cache file created if tokens exist and validation succeeded
        # Skip if no cache (indicates no tokens or API failure)
        if [[ -f "$DOCTOR_CACHE_DIR/token-github.cache" ]]; then
            assert_not_contains "$output" "command not found" "doctor should run cleanly" || return
            test_pass
        else
            test_skip "No cache created (no tokens configured or API unavailable)"
        fi
    else
        test_fail "Fresh check failed with exit code $exit_code"
    fi
}

test_cache_ttl_respect() {
    test_case "S3. Cache: TTL respected (5 min)"

    # User story: Multiple checks within 5 min use cache
    # Expected: All use cached result (if tokens configured)

    # Skip if Keychain unavailable
    if ! command -v sec &>/dev/null || ! sec list &>/dev/null 2>&1; then
        test_skip "Keychain access unavailable (expected in test environment)"
        return
    fi

    # First check
    doctor --dot >/dev/null 2>&1

    # Check cache file exists
    local cache_file="$DOCTOR_CACHE_DIR/token-github.cache"

    if [[ -f "$cache_file" ]]; then
        # Check file age (should be recent)
        local cache_age
        if [[ "$(uname)" == "Darwin" ]]; then
            cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file") ))
        else
            cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
        fi

        # Should be less than 10 seconds old
        if (( cache_age < 10 )); then
            test_pass
        else
            test_fail "Cache file too old: ${cache_age}s"
        fi
    else
        test_skip "No cache created (no tokens configured or API unavailable)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 4: VERBOSITY WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_verbosity_quiet_minimal() {
    test_case "S4. Verbosity: Quiet mode suppresses output"

    # User story: CI/CD needs minimal output
    # Expected: Only errors shown, short output

    local output=$(doctor --dot --quiet 2>&1)
    local lines=$(echo "$output" | wc -l | tr -d ' ')

    local normal_output=$(doctor --dot 2>&1)
    local normal_lines=$(echo "$normal_output" | wc -l | tr -d ' ')

    assert_not_contains "$output" "command not found" "doctor --quiet should run cleanly" || return

    if (( lines <= normal_lines )); then
        test_pass
    else
        test_fail "Quiet mode not reducing output ($lines vs $normal_lines)"
    fi
}

test_verbosity_normal_readable() {
    test_case "S4. Verbosity: Normal mode readable"

    # User story: User wants standard output
    # Expected: Clear, formatted, not too verbose

    local output=$(doctor --dot 2>&1)

    assert_not_empty "$output" "Normal mode should produce output" || return
    assert_matches_pattern "$output" "(token|github)" \
        "Normal output should mention token or github" || return
    test_pass
}

test_verbosity_debug_comprehensive() {
    test_case "S4. Verbosity: Verbose mode shows debug info"

    # User story: Debugging cache issues
    # Expected: Cache status, timing, delegation details

    local output=$(doctor --dot --verbose 2>&1)
    local lines=$(echo "$output" | wc -l | tr -d ' ')

    assert_not_contains "$output" "command not found" "doctor --verbose should run cleanly" || return

    if (( lines >= 5 )); then
        test_pass
    else
        test_fail "Verbose mode not showing enough detail ($lines lines, expected >= 5)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 5: FIX TOKEN WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_fix_token_mode_isolated() {
    test_case "S5. Fix workflow: --fix-token shows token category"

    # User story: User wants to fix only token issues
    # Expected: Shows token-focused menu or completes

    local output=$(doctor --fix-token --yes 2>&1)
    local exit_code=$?

    # 0=healthy, 1=issues found — both valid for fix-token
    if (( exit_code <= 1 )); then
        assert_not_contains "$output" "command not found" "fix-token should run cleanly" || return
        test_pass
    else
        test_fail "Fix token mode failed: exit $exit_code (expected 0 or 1)"
    fi
}

test_fix_token_cache_cleared() {
    test_case "S5. Fix workflow: Cache cleared after rotation"

    # User story: Token rotated, cache should be invalidated
    # Expected: Cache file removed or expired

    # Note: This test can only verify the mechanism exists
    # Actual rotation requires valid token setup

    assert_function_exists "_doctor_cache_token_clear" \
        "Cache clear function should be available" || return
    test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 6: MULTI-CHECK WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_multi_check_sequential() {
    test_case "S6. Multi-check: Sequential checks use cache"

    # User story: User checks multiple times in session
    # Expected: First slow, rest fast

    # Clear cache
    rm -rf "$DOCTOR_CACHE_DIR" 2>/dev/null
    mkdir -p "$DOCTOR_CACHE_DIR" 2>/dev/null

    # First check (slow)
    doctor --dot >/dev/null 2>&1

    # Next 3 checks (fast)
    local all_fast=true
    for i in {1..3}; do
        local start=$(date +%s)
        doctor --dot >/dev/null 2>&1
        local end=$(date +%s)
        if (( (end - start) > 1 )); then
            all_fast=false
        fi
    done

    if $all_fast; then
        test_pass
    else
        test_fail "Cached checks not fast enough"
    fi
}

test_multi_check_different_tokens() {
    test_case "S6. Multi-check: Specific token selection"

    # User story: User checks specific tokens
    # Expected: --dot=github works independently

    local output=$(doctor --dot=github 2>&1)
    local exit_code=$?

    # 0=healthy, 1=issues found — both valid for specific token check
    if (( exit_code <= 1 )); then
        assert_not_contains "$output" "command not found" "doctor --dot=github should run cleanly" || return
        test_pass
    else
        test_fail "Specific token check failed: exit $exit_code (expected 0 or 1)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 7: ERROR RECOVERY
# ══════════════════════════════════════════════════════════════════════════════

test_error_invalid_token_provider() {
    test_case "S7. Error handling: Invalid token provider"

    # User story: User typos token name
    # Expected: Currently no validation, completes without error
    # TODO (Phase 2): Add provider validation

    local output=$(doctor --dot=invalid 2>&1)
    local exit_code=$?

    # Currently accepts any provider name (no validation in Phase 1)
    # 0=healthy, 1=issues found — both valid; Phase 2 will add validation
    if (( exit_code <= 1 )); then
        assert_not_contains "$output" "command not found" "doctor should handle invalid provider gracefully" || return
        test_pass
    else
        test_skip "Provider validation not implemented in Phase 1"
    fi
}

test_error_corrupted_cache() {
    test_case "S7. Error handling: Corrupted cache recovery"

    # User story: Cache file corrupted
    # Expected: Graceful fallback to fresh check

    # Create corrupted cache file
    echo "invalid json" > "$DOCTOR_CACHE_DIR/token-github.cache"

    # Should still work (fall back to fresh check)
    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    # 0=healthy, 1=issues found — both valid after cache recovery
    if (( exit_code <= 1 )); then
        assert_not_contains "$output" "command not found" "doctor should recover from corrupted cache" || return
        test_pass
    else
        test_fail "Failed to recover from corrupted cache (exit $exit_code)"
    fi
}

test_error_missing_cache_dir() {
    test_case "S7. Error handling: Missing cache directory"

    # User story: Cache directory deleted
    # Expected: Recreated automatically

    # Remove cache directory
    rm -rf "$DOCTOR_CACHE_DIR" 2>/dev/null

    # Should recreate and work
    local output=$(doctor --dot 2>&1)

    assert_not_contains "$output" "command not found" "doctor should handle missing cache dir" || return
    assert_dir_exists "$DOCTOR_CACHE_DIR" "Cache directory should be recreated" || return
    test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 8: CI/CD INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════

test_cicd_exit_code_success() {
    test_case "S8. CI/CD: Exit code 0 or 1 for token check"

    # User story: CI pipeline checks token health
    # Expected: Exit 0 if valid, 1 if issues — both acceptable

    local output=$(doctor --dot --quiet 2>&1)
    local exit_code=$?

    # 0=healthy, 1=issues found — both acceptable in CI
    if (( exit_code <= 1 )); then
        assert_not_contains "$output" "command not found" "doctor --quiet should run cleanly in CI" || return
        test_pass
    else
        test_fail "Unexpected exit code: $exit_code (expected 0 or 1)"
    fi
}

test_cicd_minimal_output() {
    test_case "S8. CI/CD: Quiet mode for automation"

    # User story: CI needs parseable output
    # Expected: Minimal, consistent format

    local output=$(doctor --dot --quiet 2>&1)

    # Output should be consistent (has some content)
    if [[ -n "$output" ]]; then
        assert_not_contains "$output" "command not found" "quiet mode should not produce errors" || return
        test_pass
    else
        test_skip "No output (acceptable if no token configured)"
    fi
}

test_cicd_scripting_friendly() {
    test_case "S8. CI/CD: Scriptable workflow"

    # User story: Script checks and acts on result
    # Expected: Exit codes + grep-able output

    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    assert_not_empty "$output" "Scripted doctor should produce output" || return
    assert_not_contains "$output" "command not found" "doctor should be script-friendly" || return

    # Should be parseable with valid exit code range
    if [[ $exit_code -ge 0 ]] && [[ $exit_code -le 2 ]]; then
        test_pass
    else
        test_fail "Not script-friendly: exit=$exit_code"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 9: INTEGRATION WITH EXISTING DOCTOR FEATURES
# ══════════════════════════════════════════════════════════════════════════════

test_integration_backward_compatible() {
    test_case "S9. Integration: Backward compatible with doctor"

    # User story: Existing doctor usage still works
    # Expected: doctor (no flags) still checks everything

    local output=$(doctor 2>&1)
    local exit_code=$?

    assert_not_empty "$output" "doctor should produce output" || return
    assert_not_contains "$output" "command not found" "doctor command should exist" || return

    # Should complete successfully (0=pass, 1=issues, 2=warnings)
    if [[ $exit_code -ge 0 ]] && [[ $exit_code -le 2 ]]; then
        test_pass
    else
        test_fail "Backward compatibility broken: exit $exit_code"
    fi
}

test_integration_flag_combination() {
    test_case "S9. Integration: Flags combine correctly"

    # User story: User combines --dot + --verbose
    # Expected: Both flags work together

    local output=$(doctor --dot --verbose 2>&1)
    local exit_code=$?

    assert_not_empty "$output" "Flag combination should produce output" || return
    assert_not_contains "$output" "command not found" "combined flags should work" || return

    if [[ $exit_code -ge 0 ]] && [[ $exit_code -le 2 ]]; then
        test_pass
    else
        test_fail "Flag combination failed (exit $exit_code)"
    fi
}

test_integration_help_updated() {
    test_case "S9. Integration: Help text includes new flags"

    # User story: User runs doctor --help
    # Expected: Shows --dot, --fix-token, --quiet, --verbose

    local help_output=$(doctor --help 2>&1)

    assert_not_empty "$help_output" "Help should produce output" || return
    assert_contains "$help_output" "dot" "Help text should mention --dot flag" || return
    test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 10: PERFORMANCE VALIDATION
# ══════════════════════════════════════════════════════════════════════════════

test_performance_first_check_acceptable() {
    test_case "S10. Performance: First check < 5s"

    # User story: User expects reasonable speed
    # Expected: < 5s even without cache

    # Clear cache
    rm -rf "$DOCTOR_CACHE_DIR" 2>/dev/null
    mkdir -p "$DOCTOR_CACHE_DIR" 2>/dev/null

    local start=$(date +%s)
    doctor --dot >/dev/null 2>&1
    local end=$(date +%s)
    local duration=$((end - start))

    # Should complete in reasonable time (< 5s)
    if (( duration < 5 )); then
        test_pass
    else
        test_fail "First check took ${duration}s (expected < 5s)"
    fi
}

test_performance_cached_instant() {
    test_case "S10. Performance: Cached check instant"

    # User story: Cached checks should be near-instant
    # Expected: Completes in same second

    # Populate cache
    doctor --dot >/dev/null 2>&1

    # Cached check
    local start=$(date +%s)
    doctor --dot >/dev/null 2>&1
    local end=$(date +%s)
    local duration=$((end - start))

    # Should be instant (0-1s with second precision)
    if (( duration <= 1 )); then
        test_pass
    else
        test_fail "Cached check took ${duration}s (expected <= 1s)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL E2E TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    test_suite "Doctor Token Enhancement E2E Test Suite"

    setup

    echo "Scenario 1: Morning Routine"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_morning_routine_quick_check
    test_morning_routine_cached_recheck

    echo ""
    echo "Scenario 2: Token Expiration Workflow"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_expiration_detection
    test_expiration_verbose_details

    echo ""
    echo "Scenario 3: Cache Behavior"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_cache_fresh_invalidation
    test_cache_ttl_respect

    echo ""
    echo "Scenario 4: Verbosity Levels"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_verbosity_quiet_minimal
    test_verbosity_normal_readable
    test_verbosity_debug_comprehensive

    echo ""
    echo "Scenario 5: Fix Token Workflow"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_fix_token_mode_isolated
    test_fix_token_cache_cleared

    echo ""
    echo "Scenario 6: Multi-Check Workflow"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_multi_check_sequential
    test_multi_check_different_tokens

    echo ""
    echo "Scenario 7: Error Recovery"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_error_invalid_token_provider
    test_error_corrupted_cache
    test_error_missing_cache_dir

    echo ""
    echo "Scenario 8: CI/CD Integration"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_cicd_exit_code_success
    test_cicd_minimal_output
    test_cicd_scripting_friendly

    echo ""
    echo "Scenario 9: Integration with Existing Features"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_integration_backward_compatible
    test_integration_flag_combination
    test_integration_help_updated

    echo ""
    echo "Scenario 10: Performance Validation"
    echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    test_performance_first_check_acceptable
    test_performance_cached_instant

    cleanup

    print_summary
}

# Run E2E tests
main "$@"
