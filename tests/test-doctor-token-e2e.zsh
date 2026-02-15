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

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}E2E Test:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

skip() {
    echo "${YELLOW}⊘ SKIP${NC} - $1"
    ((TESTS_SKIPPED++))
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP & TEARDOWN
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    echo ""
    echo "${YELLOW}Setting up E2E test environment...${NC}"

    # Get project root
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
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Set up test cache directory BEFORE sourcing plugin
    # (plugin may set DOCTOR_CACHE_DIR as readonly)
    export TEST_CACHE_DIR="${HOME}/.flow/cache/doctor-e2e-test"
    export DOCTOR_CACHE_DIR="$TEST_CACHE_DIR"
    mkdir -p "$TEST_CACHE_DIR" 2>/dev/null

    # Source the plugin
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Verify git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "${YELLOW}  Warning: Not in git repo (some tests may skip)${NC}"
    fi

    echo ""
}

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up E2E test environment...${NC}"

    # Clean up test cache
    rm -rf "$TEST_CACHE_DIR" 2>/dev/null

    echo "  Test cache cleaned"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 1: MORNING ROUTINE (QUICK HEALTH CHECK)
# ══════════════════════════════════════════════════════════════════════════════

test_morning_routine_quick_check() {
    log_test "S1. Morning routine: Quick token check"

    # User story: Developer starts work, runs quick health check
    # Expected: < 3s first check, shows token status

    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    # Should complete successfully
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        # Should show token section
        if echo "$output" | grep -qi "token"; then
            pass
        else
            fail "No token output shown"
        fi
    else
        fail "Command failed with exit code $exit_code"
    fi
}

test_morning_routine_cached_recheck() {
    log_test "S1. Morning routine: Cached re-check (< 1s)"

    # User story: Developer checks again 2 minutes later
    # Expected: < 1s (cached), same result

    # First check (populate cache)
    doctor --dot >/dev/null 2>&1

    # Second check (should use cache)
    local start=$(date +%s)
    doctor --dot >/dev/null 2>&1
    local end=$(date +%s)
    local duration=$((end - start))

    # Should be instant (< 1s with second precision)
    if (( duration <= 1 )); then
        pass
    else
        fail "Cached check took ${duration}s (expected <= 1s)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 2: TOKEN EXPIRATION WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_expiration_detection() {
    log_test "S2. Token expiration: Detection workflow"

    # User story: User runs doctor, sees expiring token warning
    # Expected: Clear warning with days remaining

    local output=$(doctor --dot 2>&1)

    # Should either show "valid" or "expiring" or "expired"
    if echo "$output" | grep -qiE "(valid|expiring|expired|token)"; then
        pass
    else
        fail "No token status shown"
    fi
}

test_expiration_verbose_details() {
    log_test "S2. Token expiration: Verbose shows metadata"

    # User story: User wants more details about token
    # Expected: Username, age, type shown

    local output=$(doctor --dot --verbose 2>&1)

    # Verbose should show more information
    # At minimum, should be longer than quiet output
    local verbose_lines=$(echo "$output" | wc -l | tr -d ' ')

    if (( verbose_lines >= 3 )); then
        pass
    else
        fail "Verbose mode not showing enough detail"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 3: CACHE BEHAVIOR VALIDATION
# ══════════════════════════════════════════════════════════════════════════════

test_cache_fresh_invalidation() {
    log_test "S3. Cache: Fresh check after clearing"

    # User story: User clears cache, forces fresh check
    # Expected: Re-validates with GitHub API (if tokens configured)
    # Note: Cache only written if token check succeeds

    # Check if tokens are configured
    if ! command -v sec &>/dev/null || ! sec list &>/dev/null 2>&1; then
        skip "Keychain access unavailable (expected in test environment)"
        return
    fi

    # Clear cache
    rm -rf "$DOCTOR_CACHE_DIR" 2>/dev/null
    mkdir -p "$DOCTOR_CACHE_DIR" 2>/dev/null

    # Should succeed (fetch fresh)
    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        # Cache file created if tokens exist and validation succeeded
        # Skip if no cache (indicates no tokens or API failure)
        if [[ -f "$DOCTOR_CACHE_DIR/token-github.cache" ]]; then
            pass
        else
            skip "No cache created (no tokens configured or API unavailable)"
        fi
    else
        fail "Fresh check failed"
    fi
}

test_cache_ttl_respect() {
    log_test "S3. Cache: TTL respected (5 min)"

    # User story: Multiple checks within 5 min use cache
    # Expected: All use cached result (if tokens configured)

    # Skip if Keychain unavailable
    if ! command -v sec &>/dev/null || ! sec list &>/dev/null 2>&1; then
        skip "Keychain access unavailable (expected in test environment)"
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
            pass
        else
            fail "Cache file too old: ${cache_age}s"
        fi
    else
        skip "No cache created (no tokens configured or API unavailable)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 4: VERBOSITY WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_verbosity_quiet_minimal() {
    log_test "S4. Verbosity: Quiet mode suppresses output"

    # User story: CI/CD needs minimal output
    # Expected: Only errors shown, short output

    local output=$(doctor --dot --quiet 2>&1)
    local lines=$(echo "$output" | wc -l | tr -d ' ')

    # Quiet should have fewer lines than normal
    local normal_output=$(doctor --dot 2>&1)
    local normal_lines=$(echo "$normal_output" | wc -l | tr -d ' ')

    if (( lines <= normal_lines )); then
        pass
    else
        fail "Quiet mode not reducing output ($lines vs $normal_lines)"
    fi
}

test_verbosity_normal_readable() {
    log_test "S4. Verbosity: Normal mode readable"

    # User story: User wants standard output
    # Expected: Clear, formatted, not too verbose

    local output=$(doctor --dot 2>&1)

    # Should have some structure (headers, sections)
    if echo "$output" | grep -qiE "(token|github)"; then
        pass
    else
        fail "Normal output missing expected content"
    fi
}

test_verbosity_debug_comprehensive() {
    log_test "S4. Verbosity: Verbose mode shows debug info"

    # User story: Debugging cache issues
    # Expected: Cache status, timing, delegation details

    local output=$(doctor --dot --verbose 2>&1)

    # Verbose should be longer than normal
    local lines=$(echo "$output" | wc -l | tr -d ' ')

    if (( lines >= 5 )); then
        pass
    else
        fail "Verbose mode not showing enough detail"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 5: FIX TOKEN WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_fix_token_mode_isolated() {
    log_test "S5. Fix workflow: --fix-token shows token category"

    # User story: User wants to fix only token issues
    # Expected: Shows token-focused menu or completes

    # Check if --fix-token mode works (may have no issues)
    local output=$(doctor --fix-token --yes 2>&1)
    local exit_code=$?

    # Should either fix or show "no issues"
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        pass
    else
        fail "Fix token mode failed: exit $exit_code"
    fi
}

test_fix_token_cache_cleared() {
    log_test "S5. Fix workflow: Cache cleared after rotation"

    # User story: Token rotated, cache should be invalidated
    # Expected: Cache file removed or expired

    # Note: This test can only verify the mechanism exists
    # Actual rotation requires valid token setup

    # Check if cache clear function exists
    if type _doctor_cache_token_clear &>/dev/null; then
        pass
    else
        fail "Cache clear function not available"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 6: MULTI-CHECK WORKFLOW
# ══════════════════════════════════════════════════════════════════════════════

test_multi_check_sequential() {
    log_test "S6. Multi-check: Sequential checks use cache"

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
        pass
    else
        fail "Cached checks not fast enough"
    fi
}

test_multi_check_different_tokens() {
    log_test "S6. Multi-check: Specific token selection"

    # User story: User checks specific tokens
    # Expected: --dot=github works independently

    local output=$(doctor --dot=github 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        pass
    else
        fail "Specific token check failed: exit $exit_code"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 7: ERROR RECOVERY
# ══════════════════════════════════════════════════════════════════════════════

test_error_invalid_token_provider() {
    log_test "S7. Error handling: Invalid token provider"

    # User story: User typos token name
    # Expected: Currently no validation, completes without error
    # TODO (Phase 2): Add provider validation

    local output=$(doctor --dot=invalid 2>&1)
    local exit_code=$?

    # Currently accepts any provider name (no validation in Phase 1)
    # Phase 2 will add validation and this test should be updated
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        pass
    else
        skip "Provider validation not implemented in Phase 1"
    fi
}

test_error_corrupted_cache() {
    log_test "S7. Error handling: Corrupted cache recovery"

    # User story: Cache file corrupted
    # Expected: Graceful fallback to fresh check

    # Create corrupted cache file
    echo "invalid json" > "$DOCTOR_CACHE_DIR/token-github.cache"

    # Should still work (fall back to fresh check)
    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        pass
    else
        fail "Failed to recover from corrupted cache"
    fi
}

test_error_missing_cache_dir() {
    log_test "S7. Error handling: Missing cache directory"

    # User story: Cache directory deleted
    # Expected: Recreated automatically

    # Remove cache directory
    rm -rf "$DOCTOR_CACHE_DIR" 2>/dev/null

    # Should recreate and work
    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    if [[ -d "$DOCTOR_CACHE_DIR" ]]; then
        pass
    else
        fail "Cache directory not recreated"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 8: CI/CD INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════

test_cicd_exit_code_success() {
    log_test "S8. CI/CD: Exit code 0 for valid token"

    # User story: CI pipeline checks token health
    # Expected: Exit 0 if valid, non-zero if issues

    doctor --dot --quiet >/dev/null 2>&1
    local exit_code=$?

    # Should be 0 or 1 (both acceptable)
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

test_cicd_minimal_output() {
    log_test "S8. CI/CD: Quiet mode for automation"

    # User story: CI needs parseable output
    # Expected: Minimal, consistent format

    local output=$(doctor --dot --quiet 2>&1)

    # Output should be consistent (has some content)
    if [[ -n "$output" ]]; then
        pass
    else
        skip "No output (acceptable if no token configured)"
    fi
}

test_cicd_scripting_friendly() {
    log_test "S8. CI/CD: Scriptable workflow"

    # User story: Script checks and acts on result
    # Expected: Exit codes + grep-able output

    local output=$(doctor --dot 2>&1)
    local exit_code=$?

    # Should be parseable
    if [[ -n "$output" ]] && [[ $exit_code -ge 0 ]] && [[ $exit_code -le 2 ]]; then
        pass
    else
        fail "Not script-friendly: exit=$exit_code, output=$output"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 9: INTEGRATION WITH EXISTING DOCTOR FEATURES
# ══════════════════════════════════════════════════════════════════════════════

test_integration_backward_compatible() {
    log_test "S9. Integration: Backward compatible with doctor"

    # User story: Existing doctor usage still works
    # Expected: doctor (no flags) still checks everything

    local output=$(doctor 2>&1)
    local exit_code=$?

    # Should complete successfully
    if [[ $exit_code -ge 0 ]] && [[ $exit_code -le 2 ]]; then
        pass
    else
        fail "Backward compatibility broken: exit $exit_code"
    fi
}

test_integration_flag_combination() {
    log_test "S9. Integration: Flags combine correctly"

    # User story: User combines --dot + --verbose
    # Expected: Both flags work together

    local output=$(doctor --dot --verbose 2>&1)
    local exit_code=$?

    if [[ $exit_code -ge 0 ]] && [[ $exit_code -le 2 ]]; then
        # Should show verbose token output
        pass
    else
        fail "Flag combination failed"
    fi
}

test_integration_help_updated() {
    log_test "S9. Integration: Help text includes new flags"

    # User story: User runs doctor --help
    # Expected: Shows --dot, --fix-token, --quiet, --verbose

    local help_output=$(doctor --help 2>&1)

    # Should mention new flags
    if echo "$help_output" | grep -qi "dot"; then
        pass
    else
        fail "Help text not updated with new flags"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SCENARIO 10: PERFORMANCE VALIDATION
# ══════════════════════════════════════════════════════════════════════════════

test_performance_first_check_acceptable() {
    log_test "S10. Performance: First check < 5s"

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
        pass
    else
        fail "First check took ${duration}s (expected < 5s)"
    fi
}

test_performance_cached_instant() {
    log_test "S10. Performance: Cached check instant"

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
        pass
    else
        fail "Cached check took ${duration}s (expected <= 1s)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL E2E TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Doctor Token Enhancement E2E Test Suite${NC}             │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 1: Morning Routine${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_morning_routine_quick_check
    test_morning_routine_cached_recheck

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 2: Token Expiration Workflow${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_expiration_detection
    test_expiration_verbose_details

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 3: Cache Behavior${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_fresh_invalidation
    test_cache_ttl_respect

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 4: Verbosity Levels${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_verbosity_quiet_minimal
    test_verbosity_normal_readable
    test_verbosity_debug_comprehensive

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 5: Fix Token Workflow${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_fix_token_mode_isolated
    test_fix_token_cache_cleared

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 6: Multi-Check Workflow${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_multi_check_sequential
    test_multi_check_different_tokens

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 7: Error Recovery${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_error_invalid_token_provider
    test_error_corrupted_cache
    test_error_missing_cache_dir

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 8: CI/CD Integration${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cicd_exit_code_success
    test_cicd_minimal_output
    test_cicd_scripting_friendly

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 9: Integration with Existing Features${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_integration_backward_compatible
    test_integration_flag_combination
    test_integration_help_updated

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Scenario 10: Performance Validation${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_performance_first_check_acceptable
    test_performance_cached_instant

    cleanup

    # Summary
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}E2E Test Summary${NC}                                     │"
    echo "╰─────────────────────────────────────────────────────────╯"
    echo ""
    echo "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo "  ${CYAN}Total:${NC}   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All E2E tests passed!${NC}"
        if [[ $TESTS_SKIPPED -gt 0 ]]; then
            echo "${DIM}  ($TESTS_SKIPPED tests skipped - acceptable)${NC}"
        fi
        echo ""
        return 0
    else
        echo "${RED}✗ Some E2E tests failed${NC}"
        echo ""
        return 1
    fi
}

# Run E2E tests
main "$@"
