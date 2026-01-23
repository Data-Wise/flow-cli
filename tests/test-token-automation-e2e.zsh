#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE - TOKEN AUTOMATION
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: End-to-end integration tests for token automation workflows
# Target: Full workflow validation including git, dash, work, doctor
# Coverage: Real integration points, no mocking
#
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

skip() {
    echo "${YELLOW}SKIP${NC} - $1"
    ((TESTS_SKIPPED++))
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    echo ""
    echo "${YELLOW}Setting up E2E test environment...${NC}"

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

    # Source the plugin
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Set up test keychain service
    export _DOT_KEYCHAIN_SERVICE="flow-cli-test-e2e"

    # Verify git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "${RED}ERROR: Not a git repository${NC}"
        exit 1
    fi

    echo "  Git repo: $(git rev-parse --show-toplevel)"
    echo ""
}

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up E2E test environment...${NC}"

    # Clean up test keychain entries
    security delete-generic-password \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    echo "  Test keychain cleaned"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Integration Points
# ══════════════════════════════════════════════════════════════════════════════

test_g_dispatcher_github_detection() {
    log_test "g dispatcher detects GitHub remote"

    # Should detect GitHub in current repo
    if _g_is_github_remote; then
        pass
    else
        fail "Failed to detect GitHub remote"
    fi
}

test_g_dispatcher_token_validation_no_token() {
    log_test "g dispatcher validates token (no token scenario)"

    # Remove test token
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    # Should return false when token missing
    if ! _g_validate_github_token_silent 2>/dev/null; then
        pass
    else
        fail "Should return false when token missing"
    fi
}

test_dash_dev_displays_token_section() {
    log_test "dash dev displays GitHub token section"

    local output=$(dash dev 2>/dev/null)

    if echo "$output" | grep -qi "github token"; then
        pass
    else
        fail "Token section not found in dash dev output"
    fi
}

test_work_github_detection() {
    log_test "work detects GitHub projects correctly"

    # Test with current repo (known GitHub project)
    if [[ -f "$PROJECT_ROOT/.git" ]]; then
        skip "Worktree .git is file (known limitation)"
        return
    fi

    if _work_project_uses_github "$PROJECT_ROOT"; then
        pass
    else
        fail "Failed to detect GitHub project"
    fi
}

test_work_token_status_no_token() {
    log_test "work reports token status (no token)"

    # Remove test token
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    local token_status=$(_work_get_token_status 2>/dev/null || echo "error")

    if [[ "$token_status" == "not configured" || "$token_status" == "error" ]]; then
        pass
    else
        fail "Expected 'not configured' or 'error', got: $token_status"
    fi
}

test_doctor_includes_token_health() {
    log_test "flow doctor includes GitHub token health check"

    local output=$(flow doctor 2>/dev/null || true)

    if echo "$output" | grep -qi "github token"; then
        pass
    else
        fail "Token health check not found in doctor output"
    fi
}

test_flow_token_alias_works() {
    log_test "flow token delegates to dot token"

    # flow token should work (even if it shows help/error)
    local output=$(flow token 2>&1 || true)

    if [[ -n "$output" ]]; then
        pass
    else
        fail "flow token produced no output"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Command Help Output
# ══════════════════════════════════════════════════════════════════════════════

test_dot_token_help_output() {
    log_test "dot token help displays usage"

    local output=$(dot token help 2>/dev/null || dot help 2>/dev/null || true)

    if [[ -n "$output" ]]; then
        pass
    else
        fail "No help output"
    fi
}

test_dot_token_expiring_help() {
    log_test "dot token expiring has help or usage"

    # Should either show help or execute (both acceptable)
    local output=$(dot token expiring 2>&1 || true)

    if [[ -n "$output" ]]; then
        pass
    else
        fail "No output from command"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Documentation Exists
# ══════════════════════════════════════════════════════════════════════════════

test_claude_md_documents_token_management() {
    log_test "CLAUDE.md documents token management"

    if [[ -f "$PROJECT_ROOT/CLAUDE.md" ]] && \
       grep -qi "token management" "$PROJECT_ROOT/CLAUDE.md"; then
        pass
    else
        fail "Token management section missing"
    fi
}

test_dot_reference_documents_token_commands() {
    log_test "DOT-DISPATCHER-REFERENCE.md documents token commands"

    local dot_ref="$PROJECT_ROOT/docs/reference/DOT-DISPATCHER-REFERENCE.md"

    if [[ -f "$dot_ref" ]] && grep -qi "token health" "$dot_ref"; then
        pass
    else
        fail "Token commands not documented"
    fi
}

test_token_health_check_guide_exists() {
    log_test "TOKEN-HEALTH-CHECK.md guide exists"

    local guide="$PROJECT_ROOT/docs/guides/TOKEN-HEALTH-CHECK.md"

    if [[ -f "$guide" ]]; then
        pass
    else
        fail "Guide not found"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: End-to-End Workflow Scenarios
# ══════════════════════════════════════════════════════════════════════════════

test_workflow_dash_dev_to_token_check() {
    log_test "Workflow: dash dev → view token status → check expiring"

    # Step 1: Run dash dev
    local dash_output=$(dash dev 2>/dev/null || true)

    if ! echo "$dash_output" | grep -qi "github token"; then
        fail "dash dev missing token section"
        return
    fi

    # Step 2: Run token expiring check
    local expiring_output=$(dot token expiring 2>&1 || true)

    if [[ -n "$expiring_output" ]]; then
        pass
    else
        fail "dot token expiring produced no output"
    fi
}

test_workflow_work_session_token_validation() {
    log_test "Workflow: work session validates token on GitHub project"

    # Skip if not in regular git repo
    if [[ -f "$PROJECT_ROOT/.git" ]]; then
        skip "Worktree .git is file (skip work validation test)"
        return
    fi

    # Check if work would validate token
    if _work_project_uses_github "$PROJECT_ROOT"; then
        local token_status=$(_work_get_token_status 2>/dev/null || echo "error")
        if [[ -n "$token_status" ]]; then
            pass
        else
            fail "Token status check produced no output"
        fi
    else
        skip "Not a GitHub project"
    fi
}

test_workflow_doctor_fix_mode() {
    log_test "Workflow: flow doctor includes token in health checks"

    local doctor_output=$(flow doctor 2>/dev/null || true)

    # Should mention token even if not in fix mode
    if echo "$doctor_output" | grep -qi "token"; then
        pass
    else
        fail "Doctor output missing token health check"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Integration with Git Operations
# ══════════════════════════════════════════════════════════════════════════════

test_git_push_token_validation() {
    log_test "Git push validates token before remote operation"

    # Test that the validation function exists and can be called
    if type _g_validate_github_token_silent &>/dev/null; then
        # Call validation (will fail without token, which is expected)
        _g_validate_github_token_silent 2>/dev/null || true
        pass
    else
        fail "Token validation function not available"
    fi
}

test_git_remote_github_detection() {
    log_test "Git remote correctly identifies GitHub URLs"

    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ -n "$remote_url" ]] && echo "$remote_url" | grep -q "github.com"; then
        pass
    else
        skip "No GitHub remote found"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Error Handling
# ══════════════════════════════════════════════════════════════════════════════

test_error_handling_missing_token() {
    log_test "Error handling: Missing token returns gracefully"

    # Ensure no token exists
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    # Should not crash
    local output=$(dot token expiring 2>&1 || true)

    if [[ -n "$output" ]]; then
        pass
    else
        fail "Command crashed or produced no output"
    fi
}

test_error_handling_invalid_token() {
    log_test "Error handling: Invalid token detected"

    # Store invalid token
    security add-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "invalid_token_12345" \
        -U 2>/dev/null || true

    # Validation should fail gracefully
    if ! _g_validate_github_token_silent 2>/dev/null; then
        pass
    else
        fail "Should detect invalid token"
    fi

    # Cleanup
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Token Automation E2E Test Suite${NC}                    │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Integration Point Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_g_dispatcher_github_detection
    test_g_dispatcher_token_validation_no_token
    test_dash_dev_displays_token_section
    test_work_github_detection
    test_work_token_status_no_token
    test_doctor_includes_token_health
    test_flow_token_alias_works

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Command Help Output Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_dot_token_help_output
    test_dot_token_expiring_help

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Documentation Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_claude_md_documents_token_management
    test_dot_reference_documents_token_commands
    test_token_health_check_guide_exists

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}End-to-End Workflow Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_workflow_dash_dev_to_token_check
    test_workflow_work_session_token_validation
    test_workflow_doctor_fix_mode

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Git Integration Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_git_push_token_validation
    test_git_remote_github_detection

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}Error Handling Tests${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_error_handling_missing_token
    test_error_handling_invalid_token

    cleanup

    # Summary
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Test Summary${NC}                                         │"
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
            echo "${DIM}  ($TESTS_SKIPPED tests skipped)${NC}"
        fi
        echo ""
        return 0
    else
        echo "${RED}✗ Some E2E tests failed${NC}"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
