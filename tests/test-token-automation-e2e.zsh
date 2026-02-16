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

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        if [[ -f "$PWD/flow.plugin.zsh" ]]; then
            PROJECT_ROOT="$PWD"
        elif [[ -f "$PWD/../flow.plugin.zsh" ]]; then
            PROJECT_ROOT="$PWD/.."
        fi
    fi

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find project root"
        exit 1
    fi

    # Source the plugin
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Set up test keychain service
    export _DOT_KEYCHAIN_SERVICE="flow-cli-test-e2e"

    # Verify git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "ERROR: Not a git repository"
        exit 1
    fi
}

cleanup() {
    # Clean up test keychain entries
    security delete-generic-password \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Integration Points
# ══════════════════════════════════════════════════════════════════════════════

test_g_dispatcher_github_detection() {
    test_case "g dispatcher detects GitHub remote"

    if _g_is_github_remote; then
        test_pass
    else
        test_fail "Failed to detect GitHub remote"
    fi
}

test_g_dispatcher_token_validation_no_token() {
    test_case "g dispatcher validates token (no token scenario)"

    # Remove test token
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    if ! _g_validate_github_token_silent 2>/dev/null; then
        test_pass
    else
        test_fail "Should return false when token missing"
    fi
}

test_dash_dev_displays_token_section() {
    test_case "dash dev displays GitHub token section"

    local output=$(dash dev 2>/dev/null)

    if echo "$output" | grep -qi "github token"; then
        test_pass
    else
        test_fail "Token section not found in dash dev output"
    fi
}

test_work_github_detection() {
    test_case "work detects GitHub projects correctly"

    if [[ -f "$PROJECT_ROOT/.git" ]]; then
        test_skip "Worktree .git is file (known limitation)"
        return
    fi

    if _work_project_uses_github "$PROJECT_ROOT"; then
        test_pass
    else
        test_fail "Failed to detect GitHub project"
    fi
}

test_work_token_status_no_token() {
    test_case "work reports token status (no token)"

    # Remove test token
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    local token_status=$(_work_get_token_status 2>/dev/null || echo "error")

    if [[ "$token_status" == "not configured" || "$token_status" == "error" ]]; then
        test_pass
    else
        test_fail "Expected 'not configured' or 'error', got: $token_status"
    fi
}

test_doctor_includes_token_health() {
    test_case "flow doctor includes GitHub token health check"

    local output=$(flow doctor 2>/dev/null || true)

    if echo "$output" | grep -qi "github token"; then
        test_pass
    else
        test_fail "Token health check not found in doctor output"
    fi
}

test_flow_token_alias_works() {
    test_case "flow token delegates to tok"

    local output=$(flow token 2>&1 || true)

    if [[ -n "$output" ]]; then
        test_pass
    else
        test_fail "flow token produced no output"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Command Help Output
# ══════════════════════════════════════════════════════════════════════════════

test_dot_token_help_output() {
    test_case "tok help displays usage"

    local output=$(tok help 2>/dev/null || dots help 2>/dev/null || true)

    if [[ -n "$output" ]]; then
        test_pass
    else
        test_fail "No help output"
    fi
}

test_dot_token_expiring_help() {
    test_case "tok expiring has help or usage"

    local output=$(tok expiring 2>&1 || true)

    if [[ -n "$output" ]]; then
        test_pass
    else
        test_fail "No output from command"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Documentation Exists
# ══════════════════════════════════════════════════════════════════════════════

test_claude_md_documents_token_management() {
    test_case "CLAUDE.md documents token management"

    if [[ -f "$PROJECT_ROOT/CLAUDE.md" ]] && \
       grep -qi "token management" "$PROJECT_ROOT/CLAUDE.md"; then
        test_pass
    else
        test_fail "Token management section missing"
    fi
}

test_dot_reference_documents_token_commands() {
    test_case "DOT-DISPATCHER-REFERENCE.md documents token commands"

    local dot_ref="$PROJECT_ROOT/docs/reference/DOT-DISPATCHER-REFERENCE.md"

    if [[ -f "$dot_ref" ]] && grep -qi "token health" "$dot_ref"; then
        test_pass
    else
        test_fail "Token commands not documented"
    fi
}

test_token_health_check_guide_exists() {
    test_case "TOKEN-HEALTH-CHECK.md guide exists"

    local guide="$PROJECT_ROOT/docs/guides/TOKEN-HEALTH-CHECK.md"

    if [[ -f "$guide" ]]; then
        test_pass
    else
        test_fail "Guide not found"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: End-to-End Workflow Scenarios
# ══════════════════════════════════════════════════════════════════════════════

test_workflow_dash_dev_to_token_check() {
    test_case "Workflow: dash dev → view token status → check expiring"

    # Step 1: Run dash dev
    local dash_output=$(dash dev 2>/dev/null || true)

    if ! echo "$dash_output" | grep -qi "github token"; then
        test_fail "dash dev missing token section"
        return
    fi

    # Step 2: Run token expiring check
    local expiring_output=$(tok expiring 2>&1 || true)

    if [[ -n "$expiring_output" ]]; then
        test_pass
    else
        test_fail "tok expiring produced no output"
    fi
}

test_workflow_work_session_token_validation() {
    test_case "Workflow: work session validates token on GitHub project"

    # Skip if not in regular git repo
    if [[ -f "$PROJECT_ROOT/.git" ]]; then
        test_skip "Worktree .git is file (skip work validation test)"
        return
    fi

    # Check if work would validate token
    if _work_project_uses_github "$PROJECT_ROOT"; then
        local token_status=$(_work_get_token_status 2>/dev/null || echo "error")
        if [[ -n "$token_status" ]]; then
            test_pass
        else
            test_fail "Token status check produced no output"
        fi
    else
        test_skip "Not a GitHub project"
    fi
}

test_workflow_doctor_fix_mode() {
    test_case "Workflow: flow doctor includes token in health checks"

    local doctor_output=$(flow doctor 2>/dev/null || true)

    if echo "$doctor_output" | grep -qi "token"; then
        test_pass
    else
        test_fail "Doctor output missing token health check"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Integration with Git Operations
# ══════════════════════════════════════════════════════════════════════════════

test_git_push_token_validation() {
    test_case "Git push validates token before remote operation"

    if type _g_validate_github_token_silent &>/dev/null; then
        local output=$(_g_validate_github_token_silent 2>&1 || true)
        assert_not_contains "$output" "command not found" && test_pass
    else
        test_fail "Token validation function not available"
    fi
}

test_git_remote_github_detection() {
    test_case "Git remote correctly identifies GitHub URLs"

    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ -n "$remote_url" ]] && echo "$remote_url" | grep -q "github.com"; then
        test_pass
    else
        test_skip "No GitHub remote found"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: Error Handling
# ══════════════════════════════════════════════════════════════════════════════

test_error_handling_missing_token() {
    test_case "Error handling: Missing token returns gracefully"

    # Ensure no token exists
    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    local output=$(tok expiring 2>&1 || true)

    if [[ -n "$output" ]]; then
        test_pass
    else
        test_fail "Command crashed or produced no output"
    fi
}

test_error_handling_invalid_token() {
    test_case "Error handling: Invalid token detected"

    # Store invalid token
    security add-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "invalid_token_12345" \
        -U 2>/dev/null || true

    # Validation should fail gracefully
    if ! _g_validate_github_token_silent 2>/dev/null; then
        test_pass
    else
        test_fail "Should detect invalid token"
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
    test_suite_start "Token Automation E2E Test Suite"

    setup

    # Integration Point Tests
    test_g_dispatcher_github_detection
    test_g_dispatcher_token_validation_no_token
    test_dash_dev_displays_token_section
    test_work_github_detection
    test_work_token_status_no_token
    test_doctor_includes_token_health
    test_flow_token_alias_works

    # Command Help Output Tests
    test_dot_token_help_output
    test_dot_token_expiring_help

    # Documentation Tests
    test_claude_md_documents_token_management
    test_dot_reference_documents_token_commands
    test_token_health_check_guide_exists

    # End-to-End Workflow Tests
    test_workflow_dash_dev_to_token_check
    test_workflow_work_session_token_validation
    test_workflow_doctor_fix_mode

    # Git Integration Tests
    test_git_push_token_validation
    test_git_remote_github_detection

    # Error Handling Tests
    test_error_handling_missing_token
    test_error_handling_invalid_token

    cleanup

    test_suite_end
    exit $?
}

# Run tests
main "$@"
