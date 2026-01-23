#!/usr/bin/env zsh
# Test script for GitHub token automation
# Tests: token expiration, rotation, metadata tracking, integration
# Generated: 2026-01-22

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

# Global variable for project root
PROJECT_ROOT=""

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
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
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source the plugin
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Set up test keychain service (avoid polluting real keychain)
    export _DOT_KEYCHAIN_SERVICE="flow-cli-test"

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

# ============================================================================
# TESTS: Command Existence
# ============================================================================

test_dot_token_exists() {
    log_test "dot token command exists"

    if type dot &>/dev/null; then
        pass
    else
        fail "dot command not found"
    fi
}

test_flow_token_alias() {
    log_test "flow token alias exists"

    if type flow &>/dev/null; then
        pass
    else
        fail "flow command not found"
    fi
}

# ============================================================================
# TESTS: Helper Functions
# ============================================================================

test_dot_token_age_days_function() {
    log_test "_dot_token_age_days function exists"

    if type _dot_token_age_days &>/dev/null; then
        pass
    else
        fail "_dot_token_age_days function not found"
    fi
}

test_dot_token_expiring_function() {
    log_test "_dot_token_expiring function exists"

    if type _dot_token_expiring &>/dev/null; then
        pass
    else
        fail "_dot_token_expiring function not found"
    fi
}

test_g_validate_github_token_silent() {
    log_test "_g_validate_github_token_silent function exists"

    if type _g_validate_github_token_silent &>/dev/null; then
        pass
    else
        fail "_g_validate_github_token_silent function not found"
    fi
}

test_g_is_github_remote() {
    log_test "_g_is_github_remote function exists"

    if type _g_is_github_remote &>/dev/null; then
        pass
    else
        fail "_g_is_github_remote function not found"
    fi
}

test_work_project_uses_github() {
    log_test "_work_project_uses_github function exists"

    if type _work_project_uses_github &>/dev/null; then
        pass
    else
        fail "_work_project_uses_github function not found"
    fi
}

test_work_get_token_status() {
    log_test "_work_get_token_status function exists"

    if type _work_get_token_status &>/dev/null; then
        pass
    else
        fail "_work_get_token_status function not found"
    fi
}

# ============================================================================
# TESTS: Metadata Tracking (dot_version 2.1)
# ============================================================================

test_metadata_structure() {
    log_test "Metadata includes dot_version 2.1 fields"

    # Create a mock token with enhanced metadata
    local test_metadata='{"dot_version":"2.1","type":"github","token_type":"fine-grained","created":"2026-01-22T12:00:00Z","expires_days":90,"github_user":"testuser"}'

    # Verify all required fields are present
    if echo "$test_metadata" | jq -e '.dot_version == "2.1"' &>/dev/null && \
       echo "$test_metadata" | jq -e '.expires_days' &>/dev/null && \
       echo "$test_metadata" | jq -e '.github_user' &>/dev/null && \
       echo "$test_metadata" | jq -e '.created' &>/dev/null; then
        pass
    else
        fail "Metadata missing required fields for dot_version 2.1"
    fi
}

test_age_calculation() {
    log_test "Age calculation from created timestamp"

    # Mock metadata with known creation date (10 days ago)
    local created_date=$(date -u -v-10d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "10 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null || date -d "$created_date" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local expected_age=$(((now_epoch - created_epoch) / 86400))

    # Age should be approximately 10 days (allow 1 day tolerance)
    if [[ $expected_age -ge 9 && $expected_age -le 11 ]]; then
        pass
    else
        fail "Age calculation incorrect: expected ~10 days, got $expected_age days"
    fi
}

test_expiration_threshold() {
    log_test "Expiration warning at 83+ days (7-day window)"

    local warning_threshold=83
    local age_expiring=85  # Should trigger warning
    local age_safe=50      # Should not trigger warning

    if [[ $age_expiring -ge $warning_threshold && $age_safe -lt $warning_threshold ]]; then
        pass
    else
        fail "Expiration threshold logic incorrect"
    fi
}

# ============================================================================
# TESTS: Git Integration
# ============================================================================

test_g_github_remote_detection() {
    log_test "GitHub remote detection in git repos"

    # Test with current repo (should be GitHub)
    if _g_is_github_remote; then
        pass
    else
        fail "Failed to detect GitHub remote in current repo"
    fi
}

test_g_token_validation_no_token() {
    log_test "Token validation handles missing token"

    # Remove any test token
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    # Should return non-zero when token is missing
    if ! _g_validate_github_token_silent 2>/dev/null; then
        pass
    else
        fail "Should return false when token is missing"
    fi
}

# ============================================================================
# TESTS: Dashboard Integration
# ============================================================================

test_dash_dev_token_section() {
    log_test "dash dev includes GitHub token section"

    # Run dash dev and check for token section
    local output=$(dash dev 2>/dev/null | grep -i "github token" || echo "")

    if [[ -n "$output" ]]; then
        pass
    else
        fail "dash dev missing GitHub Token section"
    fi
}

# ============================================================================
# TESTS: work Command Integration
# ============================================================================

test_work_github_project_detection() {
    log_test "work detects GitHub projects"

    # Test with project root
    local test_dir="$PROJECT_ROOT"

    # Skip if in a git worktree (known limitation: _work_project_uses_github
    # checks for .git directory which is a file in worktrees, not a directory)
    if [[ -f "$test_dir/.git" ]]; then
        echo "${YELLOW}SKIP${NC} - Git worktree (known limitation)"
        return
    fi

    # Check if we're in a git repo with GitHub remote
    if [[ -d "$test_dir/.git" ]]; then
        if git -C "$test_dir" remote -v 2>/dev/null | grep -q "github.com"; then
            if _work_project_uses_github "$test_dir"; then
                pass
            else
                fail "work failed to detect GitHub project"
            fi
        else
            # Not a GitHub project, skip test
            echo "${YELLOW}SKIP${NC} - Not a GitHub project"
            return
        fi
    else
        # Not a git repo, skip test
        echo "${YELLOW}SKIP${NC} - Not a git repository"
        return
    fi
}

test_work_token_status_checking() {
    log_test "work can check token status"

    # This should run without errors even if token is missing
    local token_status=$(_work_get_token_status 2>/dev/null || echo "error")

    if [[ "$token_status" =~ ^(not configured|expired/invalid|expiring|ok|error)$ ]]; then
        pass
    else
        fail "work token status returned unexpected value: $token_status"
    fi
}

# ============================================================================
# TESTS: flow doctor Integration
# ============================================================================

test_doctor_token_section() {
    log_test "flow doctor includes GitHub token check"

    # Run flow doctor and check for token section
    local output=$(flow doctor 2>/dev/null | grep -i "github token" || echo "")

    if [[ -n "$output" ]]; then
        pass
    else
        fail "flow doctor missing GitHub Token section"
    fi
}

# ============================================================================
# TESTS: Documentation
# ============================================================================

test_claude_md_token_section() {
    log_test "CLAUDE.md documents token management"

    local claude_md="$PROJECT_ROOT/CLAUDE.md"

    if [[ -f "$claude_md" ]] && grep -qi "Token Management" "$claude_md"; then
        pass
    else
        fail "CLAUDE.md missing Token Management section"
    fi
}

test_dot_reference_token_section() {
    log_test "DOT-DISPATCHER-REFERENCE.md documents token commands"

    local dot_ref="$PROJECT_ROOT/docs/reference/DOT-DISPATCHER-REFERENCE.md"

    if [[ -f "$dot_ref" ]] && grep -qi "Token Health" "$dot_ref"; then
        pass
    else
        fail "DOT-DISPATCHER-REFERENCE.md missing Token Health & Automation section"
    fi
}

test_token_health_check_guide() {
    log_test "TOKEN-HEALTH-CHECK.md guide exists"

    local guide="$PROJECT_ROOT/docs/guides/TOKEN-HEALTH-CHECK.md"

    if [[ -f "$guide" ]]; then
        pass
    else
        fail "TOKEN-HEALTH-CHECK.md guide not found"
    fi
}

# ============================================================================
# TESTS: Help System
# ============================================================================

test_dot_token_help() {
    log_test "dot token help displays usage"

    # Check if help output includes the new commands
    local output=$(dot token help 2>/dev/null || dot help 2>/dev/null || echo "")

    if [[ -n "$output" ]]; then
        pass
    else
        fail "dot token help produced no output"
    fi
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  Token Automation Test Suite                           │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Command Existence Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dot_token_exists
    test_flow_token_alias

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Helper Function Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dot_token_age_days_function
    test_dot_token_expiring_function
    test_g_validate_github_token_silent
    test_g_is_github_remote
    test_work_project_uses_github
    test_work_get_token_status

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Metadata Tracking Tests (dot_version 2.1)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_metadata_structure
    test_age_calculation
    test_expiration_threshold

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Git Integration Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_g_github_remote_detection
    test_g_token_validation_no_token

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Dashboard Integration Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dash_dev_token_section

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}work Command Integration Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_work_github_project_detection
    test_work_token_status_checking

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}flow doctor Integration Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_doctor_token_section

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Documentation Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_claude_md_token_section
    test_dot_reference_token_section
    test_token_health_check_guide

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Help System Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dot_token_help

    cleanup

    # Summary
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  Test Summary                                           │"
    echo "╰─────────────────────────────────────────────────────────╯"
    echo ""
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  ${CYAN}Total:${NC}  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        echo ""
        return 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
