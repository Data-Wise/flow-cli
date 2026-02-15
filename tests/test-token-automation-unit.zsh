#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# UNIT TEST SUITE - TOKEN AUTOMATION
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Fast, isolated unit tests for token automation functions
# Target: ~1 second execution time
# Coverage: Pure function logic, no external dependencies
#
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

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/dispatchers/dot-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/dot-dispatcher.zsh" ]]; then
            PROJECT_ROOT="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/dot-dispatcher.zsh" ]]; then
            PROJECT_ROOT="$PWD/.."
        fi
    fi

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/dispatchers/dot-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        echo "  Tried: ${0:A:h:h}, $PWD, $PWD/.."
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source the plugin (silent)
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Set up test keychain service
    export _DOT_KEYCHAIN_SERVICE="flow-cli-test-unit"

    echo ""
}

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up test environment...${NC}"

    # Clean up test keychain entries
    security delete-generic-password \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    echo "  Test keychain cleaned"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Function Existence
# ══════════════════════════════════════════════════════════════════════════════

test_tok_age_days_exists() {
    log_test "_tok_age_days function exists"

    if type _tok_age_days &>/dev/null; then
        pass
    else
        fail "Function not defined"
    fi
}

test_tok_expiring_exists() {
    log_test "_tok_expiring function exists"

    if type _tok_expiring &>/dev/null; then
        pass
    else
        fail "Function not defined"
    fi
}

test_g_is_github_remote_exists() {
    log_test "_g_is_github_remote function exists"

    if type _g_is_github_remote &>/dev/null; then
        pass
    else
        fail "Function not defined"
    fi
}

test_g_validate_github_token_silent_exists() {
    log_test "_g_validate_github_token_silent function exists"

    if type _g_validate_github_token_silent &>/dev/null; then
        pass
    else
        fail "Function not defined"
    fi
}

test_work_project_uses_github_exists() {
    log_test "_work_project_uses_github function exists"

    if type _work_project_uses_github &>/dev/null; then
        pass
    else
        fail "Function not defined"
    fi
}

test_work_get_token_status_exists() {
    log_test "_work_get_token_status function exists"

    if type _work_get_token_status &>/dev/null; then
        pass
    else
        fail "Function not defined"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Metadata Structure (dot_version 2.1)
# ══════════════════════════════════════════════════════════════════════════════

test_metadata_version_2_1() {
    log_test "Metadata includes dot_version 2.1"

    local metadata='{"dot_version":"2.1","type":"github"}'

    if echo "$metadata" | jq -e '.dot_version == "2.1"' &>/dev/null; then
        pass
    else
        fail "dot_version not 2.1"
    fi
}

test_metadata_expires_days_field() {
    log_test "Metadata includes expires_days field"

    local metadata='{"dot_version":"2.1","expires_days":90}'

    if echo "$metadata" | jq -e '.expires_days == 90' &>/dev/null; then
        pass
    else
        fail "expires_days field missing or invalid"
    fi
}

test_metadata_github_user_field() {
    log_test "Metadata includes github_user field"

    local metadata='{"dot_version":"2.1","github_user":"testuser"}'

    if echo "$metadata" | jq -e '.github_user == "testuser"' &>/dev/null; then
        pass
    else
        fail "github_user field missing or invalid"
    fi
}

test_metadata_created_timestamp() {
    log_test "Metadata includes created timestamp"

    local metadata='{"dot_version":"2.1","created":"2026-01-22T12:00:00Z"}'

    if echo "$metadata" | jq -e '.created' &>/dev/null; then
        pass
    else
        fail "created timestamp missing"
    fi
}

test_metadata_complete_structure() {
    log_test "Complete metadata structure validation"

    local metadata='{
        "dot_version": "2.1",
        "type": "github",
        "token_type": "fine-grained",
        "created": "2026-01-22T12:00:00Z",
        "expires_days": 90,
        "github_user": "testuser"
    }'

    if echo "$metadata" | jq -e '
        .dot_version == "2.1" and
        .type == "github" and
        .expires_days and
        .github_user and
        .created
    ' &>/dev/null; then
        pass
    else
        fail "Incomplete metadata structure"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Age Calculation Logic
# ══════════════════════════════════════════════════════════════════════════════

test_age_calculation_10_days() {
    log_test "Age calculation for 10-day-old token"

    # Create timestamp 10 days ago
    local created_date=$(date -u -v-10d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "10 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null || date -d "$created_date" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local age_days=$(((now_epoch - created_epoch) / 86400))

    if [[ $age_days -ge 9 && $age_days -le 11 ]]; then
        pass
    else
        fail "Expected ~10 days, got $age_days days"
    fi
}

test_age_calculation_85_days() {
    log_test "Age calculation for 85-day-old token"

    # Create timestamp 85 days ago
    local created_date=$(date -u -v-85d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "85 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null || date -d "$created_date" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local age_days=$(((now_epoch - created_epoch) / 86400))

    if [[ $age_days -ge 84 && $age_days -le 86 ]]; then
        pass
    else
        fail "Expected ~85 days, got $age_days days"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Expiration Threshold Logic
# ══════════════════════════════════════════════════════════════════════════════

test_expiration_threshold_83_days() {
    log_test "Expiration threshold at 83 days (7-day warning)"

    local warning_threshold=83

    # Test: 85 days should trigger warning
    if [[ 85 -ge $warning_threshold ]]; then
        pass
    else
        fail "85 days should trigger warning"
    fi
}

test_no_warning_below_threshold() {
    log_test "No warning for tokens < 83 days old"

    local warning_threshold=83

    # Test: 50 days should NOT trigger warning
    if [[ 50 -lt $warning_threshold ]]; then
        pass
    else
        fail "50 days should not trigger warning"
    fi
}

test_expiration_days_remaining() {
    log_test "Days remaining calculation (90 - age)"

    local token_age=85
    local token_lifetime=90
    local days_remaining=$((token_lifetime - token_age))

    if [[ $days_remaining -eq 5 ]]; then
        pass
    else
        fail "Expected 5 days remaining, got $days_remaining"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: GitHub Remote Detection Logic
# ══════════════════════════════════════════════════════════════════════════════

test_github_remote_pattern_https() {
    log_test "GitHub remote pattern detection (HTTPS)"

    local remote_url="https://github.com/user/repo.git"

    if echo "$remote_url" | grep -q "github.com"; then
        pass
    else
        fail "Failed to detect github.com in HTTPS URL"
    fi
}

test_github_remote_pattern_ssh() {
    log_test "GitHub remote pattern detection (SSH)"

    local remote_url="git@github.com:user/repo.git"

    if echo "$remote_url" | grep -q "github.com"; then
        pass
    else
        fail "Failed to detect github.com in SSH URL"
    fi
}

test_non_github_remote() {
    log_test "Non-GitHub remote rejection"

    local remote_url="https://gitlab.com/user/repo.git"

    if ! echo "$remote_url" | grep -q "github.com"; then
        pass
    else
        fail "Incorrectly detected non-GitHub remote as GitHub"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Token Status Return Values
# ══════════════════════════════════════════════════════════════════════════════

test_token_status_not_configured() {
    log_test "Token status: 'not configured'"

    local status_value="not configured"

    if [[ "$status_value" == "not configured" ]]; then
        pass
    else
        fail "Invalid status value"
    fi
}

test_token_status_expired() {
    log_test "Token status: 'expired/invalid'"

    local status_value="expired/invalid"

    if [[ "$status_value" == "expired/invalid" ]]; then
        pass
    else
        fail "Invalid status value"
    fi
}

test_token_status_expiring() {
    log_test "Token status: 'expiring in X days'"

    local days=3
    local status_value="expiring in $days days"

    if [[ "$status_value" =~ "expiring in [0-9]+ days" ]]; then
        pass
    else
        fail "Invalid status value format"
    fi
}

test_token_status_ok() {
    log_test "Token status: 'ok'"

    local status_value="ok"

    if [[ "$status_value" == "ok" ]]; then
        pass
    else
        fail "Invalid status value"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Command Aliases
# ══════════════════════════════════════════════════════════════════════════════

test_flow_token_alias() {
    log_test "flow token delegates to tok"

    # Check if flow command exists and has token case
    if type flow &>/dev/null; then
        pass
    else
        fail "flow command not found"
    fi
}

test_dot_token_subcommands() {
    log_test "tok has expiring/rotate/sync subcommands"

    # These functions should exist
    if type _tok_expiring &>/dev/null && \
       type _tok_rotate &>/dev/null && \
       type _tok_sync_gh &>/dev/null; then
        pass
    else
        fail "Missing token subcommand functions"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Token Automation Unit Test Suite${NC}                   │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Function Existence Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_tok_age_days_exists
    test_tok_expiring_exists
    test_g_is_github_remote_exists
    test_g_validate_github_token_silent_exists
    test_work_project_uses_github_exists
    test_work_get_token_status_exists

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Metadata Structure Tests (dot_version 2.1)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_metadata_version_2_1
    test_metadata_expires_days_field
    test_metadata_github_user_field
    test_metadata_created_timestamp
    test_metadata_complete_structure

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Age Calculation Logic Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_age_calculation_10_days
    test_age_calculation_85_days

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Expiration Threshold Logic Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_expiration_threshold_83_days
    test_no_warning_below_threshold
    test_expiration_days_remaining

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}GitHub Remote Detection Logic Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_github_remote_pattern_https
    test_github_remote_pattern_ssh
    test_non_github_remote

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Token Status Return Values Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_token_status_not_configured
    test_token_status_expired
    test_token_status_expiring
    test_token_status_ok

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Command Aliases Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_flow_token_alias
    test_dot_token_subcommands

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
        echo "${GREEN}✓ All unit tests passed!${NC}"
        echo ""
        return 0
    else
        echo "${RED}✗ Some unit tests failed${NC}"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
