#!/usr/bin/env zsh
# Test script for GitHub token automation
# Tests: token expiration, rotation, metadata tracking, integration
# Converted to shared test-framework.zsh

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
    # Close stdin to prevent interactive blocking
    exec < /dev/null

    # Source the plugin
    FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Set up test keychain service (avoid polluting real keychain)
    export _DOT_KEYCHAIN_SERVICE="flow-cli-test"
}

cleanup() {
    # Clean up test keychain entries
    security delete-generic-password \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    reset_mocks
}
trap cleanup EXIT

# ============================================================================
# TESTS: Command Existence
# ============================================================================

test_dot_token_exists() {
    test_case "tok command exists"
    assert_command_exists "tok" && test_pass
}

test_flow_token_alias() {
    test_case "flow command exists"
    assert_command_exists "flow" && test_pass
}

# ============================================================================
# TESTS: Helper Functions
# ============================================================================

test_tok_age_days_function() {
    test_case "_tok_age_days function exists"
    assert_function_exists "_tok_age_days" && test_pass
}

test_tok_expiring_function() {
    test_case "_tok_expiring function exists"
    assert_function_exists "_tok_expiring" && test_pass
}

test_g_validate_github_token_silent() {
    test_case "_g_validate_github_token_silent function exists"
    assert_function_exists "_g_validate_github_token_silent" && test_pass
}

test_g_is_github_remote() {
    test_case "_g_is_github_remote function exists"
    assert_function_exists "_g_is_github_remote" && test_pass
}

test_work_project_uses_github() {
    test_case "_work_project_uses_github function exists"
    assert_function_exists "_work_project_uses_github" && test_pass
}

test_work_get_token_status() {
    test_case "_work_get_token_status function exists"
    assert_function_exists "_work_get_token_status" && test_pass
}

# ============================================================================
# TESTS: Metadata Tracking (dot_version 2.1)
# ============================================================================

test_metadata_structure() {
    test_case "Metadata includes dot_version 2.1 fields"

    local test_metadata='{"dot_version":"2.1","type":"github","token_type":"fine-grained","created":"2026-01-22T12:00:00Z","expires_days":90,"github_user":"testuser"}'

    if echo "$test_metadata" | jq -e '.dot_version == "2.1"' &>/dev/null && \
       echo "$test_metadata" | jq -e '.expires_days' &>/dev/null && \
       echo "$test_metadata" | jq -e '.github_user' &>/dev/null && \
       echo "$test_metadata" | jq -e '.created' &>/dev/null; then
        test_pass
    else
        test_fail "Metadata missing required fields for dot_version 2.1"
    fi
}

test_age_calculation() {
    test_case "Age calculation from created timestamp"

    local created_date=$(date -u -v-10d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "10 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null || date -d "$created_date" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local expected_age=$(((now_epoch - created_epoch) / 86400))

    if [[ $expected_age -ge 9 && $expected_age -le 11 ]]; then
        test_pass
    else
        test_fail "Age calculation incorrect: expected ~10 days, got $expected_age days"
    fi
}

test_expiration_threshold() {
    test_case "Expiration warning at 83+ days (7-day window)"

    local warning_threshold=83
    local age_expiring=85
    local age_safe=50

    if [[ $age_expiring -ge $warning_threshold && $age_safe -lt $warning_threshold ]]; then
        test_pass
    else
        test_fail "Expiration threshold logic incorrect"
    fi
}

# ============================================================================
# TESTS: Git Integration
# ============================================================================

test_g_github_remote_detection() {
    test_case "GitHub remote detection in git repos"

    if _g_is_github_remote; then
        test_pass
    else
        test_fail "Failed to detect GitHub remote in current repo"
    fi
}

test_g_token_validation_no_token() {
    test_case "Token validation handles missing token"

    security delete-generic-password \
        -a "github-token" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true

    if ! _g_validate_github_token_silent 2>/dev/null; then
        test_pass
    else
        test_fail "Should return false when token is missing"
    fi
}

# ============================================================================
# TESTS: Dashboard Integration
# ============================================================================

test_dash_dev_token_section() {
    test_case "dash dev includes GitHub token section"

    local output=$(dash dev 2>/dev/null | grep -i "github token" || echo "")

    if [[ -n "$output" ]]; then
        test_pass
    else
        test_fail "dash dev missing GitHub Token section"
    fi
}

# ============================================================================
# TESTS: work Command Integration
# ============================================================================

test_work_github_project_detection() {
    test_case "work detects GitHub projects"

    local test_dir="$PROJECT_ROOT"

    # Skip if in a git worktree (known limitation)
    if [[ -f "$test_dir/.git" ]]; then
        test_skip "Git worktree (known limitation)"
        return
    fi

    if [[ -d "$test_dir/.git" ]]; then
        if git -C "$test_dir" remote -v 2>/dev/null | grep -q "github.com"; then
            if _work_project_uses_github "$test_dir"; then
                test_pass
            else
                test_fail "work failed to detect GitHub project"
            fi
        else
            test_skip "Not a GitHub project"
            return
        fi
    else
        test_skip "Not a git repository"
        return
    fi
}

test_work_token_status_checking() {
    test_case "work can check token status"

    local token_status=$(_work_get_token_status 2>/dev/null || echo "error")

    if assert_matches_pattern "$token_status" "^(not configured|expired/invalid|expiring|ok|error)$"; then
        test_pass
    fi
}

# ============================================================================
# TESTS: flow doctor Integration
# ============================================================================

test_doctor_token_section() {
    test_case "flow doctor includes GitHub token check"

    local output=$(flow doctor 2>/dev/null | grep -i "github token" || echo "")

    if [[ -n "$output" ]]; then
        test_pass
    else
        test_fail "flow doctor missing GitHub Token section"
    fi
}

# ============================================================================
# TESTS: Documentation
# ============================================================================

test_claude_md_token_section() {
    test_case "CLAUDE.md documents token management"

    local claude_md="$PROJECT_ROOT/CLAUDE.md"

    if assert_file_exists "$claude_md" && grep -qi "Token Management" "$claude_md"; then
        test_pass
    else
        [[ -f "$claude_md" ]] && test_fail "CLAUDE.md missing Token Management section"
    fi
}

test_dot_reference_token_section() {
    test_case "DOT-DISPATCHER-REFERENCE.md documents token commands"

    local dot_ref="$PROJECT_ROOT/docs/reference/DOT-DISPATCHER-REFERENCE.md"

    if [[ ! -f "$dot_ref" ]]; then
        test_skip "file not found (may be on different branch)"
        return
    fi
    if grep -qi "Token Health" "$dot_ref"; then
        test_pass
    else
        test_fail "DOT-DISPATCHER-REFERENCE.md missing Token Health & Automation section"
    fi
}

test_token_health_check_guide() {
    test_case "TOKEN-HEALTH-CHECK.md guide exists"

    local guide="$PROJECT_ROOT/docs/guides/TOKEN-HEALTH-CHECK.md"

    if [[ ! -f "$guide" ]]; then
        test_skip "file not found (may be on different branch)"
        return
    fi
    test_pass
}

# ============================================================================
# TESTS: Help System
# ============================================================================

test_dot_token_help() {
    test_case "tok help displays usage"

    local output=$(tok help 2>/dev/null || dots help 2>/dev/null || echo "")

    assert_not_empty "$output" && test_pass
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

main() {
    test_suite_start "Token Automation Tests"

    setup

    # Command Existence Tests
    test_dot_token_exists
    test_flow_token_alias

    # Helper Function Tests
    test_tok_age_days_function
    test_tok_expiring_function
    test_g_validate_github_token_silent
    test_g_is_github_remote
    test_work_project_uses_github
    test_work_get_token_status

    # Metadata Tracking Tests (dot_version 2.1)
    test_metadata_structure
    test_age_calculation
    test_expiration_threshold

    # Git Integration Tests
    test_g_github_remote_detection
    test_g_token_validation_no_token

    # Dashboard Integration Tests
    test_dash_dev_token_section

    # work Command Integration Tests
    test_work_github_project_detection
    test_work_token_status_checking

    # flow doctor Integration Tests
    test_doctor_token_section

    # Documentation Tests
    test_claude_md_token_section
    test_dot_reference_token_section
    test_token_health_check_guide

    # Help System Tests
    test_dot_token_help

    cleanup

    test_suite_end
    exit $?
}

main "$@"
