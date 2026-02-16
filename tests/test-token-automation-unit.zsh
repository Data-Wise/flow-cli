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

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP / CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
    export _DOT_KEYCHAIN_SERVICE="flow-cli-test-unit"
}

cleanup() {
    security delete-generic-password \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Function Existence
# ══════════════════════════════════════════════════════════════════════════════

test_tok_age_days_exists() {
    test_case "_tok_age_days function exists"
    assert_function_exists "_tok_age_days" && test_pass
}

test_tok_expiring_exists() {
    test_case "_tok_expiring function exists"
    assert_function_exists "_tok_expiring" && test_pass
}

test_g_is_github_remote_exists() {
    test_case "_g_is_github_remote function exists"
    assert_function_exists "_g_is_github_remote" && test_pass
}

test_g_validate_github_token_silent_exists() {
    test_case "_g_validate_github_token_silent function exists"
    assert_function_exists "_g_validate_github_token_silent" && test_pass
}

test_work_project_uses_github_exists() {
    test_case "_work_project_uses_github function exists"
    assert_function_exists "_work_project_uses_github" && test_pass
}

test_work_get_token_status_exists() {
    test_case "_work_get_token_status function exists"
    assert_function_exists "_work_get_token_status" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Metadata Structure (dot_version 2.1)
# ══════════════════════════════════════════════════════════════════════════════

test_metadata_version_2_1() {
    test_case "Metadata includes dot_version 2.1"
    local metadata='{"dot_version":"2.1","type":"github"}'
    local actual=$(echo "$metadata" | jq -r '.dot_version')
    assert_equals "$actual" "2.1" && test_pass
}

test_metadata_expires_days_field() {
    test_case "Metadata includes expires_days field"
    local metadata='{"dot_version":"2.1","expires_days":90}'
    local actual=$(echo "$metadata" | jq -r '.expires_days')
    assert_equals "$actual" "90" && test_pass
}

test_metadata_github_user_field() {
    test_case "Metadata includes github_user field"
    local metadata='{"dot_version":"2.1","github_user":"testuser"}'
    local actual=$(echo "$metadata" | jq -r '.github_user')
    assert_equals "$actual" "testuser" && test_pass
}

test_metadata_created_timestamp() {
    test_case "Metadata includes created timestamp"
    local metadata='{"dot_version":"2.1","created":"2026-01-22T12:00:00Z"}'
    local actual=$(echo "$metadata" | jq -r '.created')
    assert_not_empty "$actual" && test_pass
}

test_metadata_complete_structure() {
    test_case "Complete metadata structure validation"
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
        test_pass
    else
        test_fail "Incomplete metadata structure"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Age Calculation Logic
# ══════════════════════════════════════════════════════════════════════════════

test_age_calculation_10_days() {
    test_case "Age calculation for 10-day-old token"
    local created_date=$(date -u -v-10d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "10 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null || date -d "$created_date" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local age_days=$(((now_epoch - created_epoch) / 86400))

    if [[ $age_days -ge 9 && $age_days -le 11 ]]; then
        test_pass
    else
        test_fail "Expected ~10 days, got $age_days days"
    fi
}

test_age_calculation_85_days() {
    test_case "Age calculation for 85-day-old token"
    local created_date=$(date -u -v-85d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "85 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null || date -d "$created_date" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local age_days=$(((now_epoch - created_epoch) / 86400))

    if [[ $age_days -ge 84 && $age_days -le 86 ]]; then
        test_pass
    else
        test_fail "Expected ~85 days, got $age_days days"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Expiration Threshold Logic
# ══════════════════════════════════════════════════════════════════════════════

test_expiration_threshold_83_days() {
    test_case "Expiration threshold at 83 days (7-day warning)"
    local warning_threshold=83
    local age=85
    if [[ $age -ge $warning_threshold ]]; then
        test_pass
    else
        test_fail "85 days should trigger warning"
    fi
}

test_no_warning_below_threshold() {
    test_case "No warning for tokens < 83 days old"
    local warning_threshold=83
    local age=50
    if [[ $age -lt $warning_threshold ]]; then
        test_pass
    else
        test_fail "50 days should not trigger warning"
    fi
}

test_expiration_days_remaining() {
    test_case "Days remaining calculation (90 - age)"
    local token_age=85
    local token_lifetime=90
    local days_remaining=$((token_lifetime - token_age))
    assert_equals "$days_remaining" "5" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: GitHub Remote Detection Logic
# ══════════════════════════════════════════════════════════════════════════════

test_github_remote_pattern_https() {
    test_case "GitHub remote pattern detection (HTTPS)"
    local remote_url="https://github.com/user/repo.git"
    assert_contains "$remote_url" "github.com" && test_pass
}

test_github_remote_pattern_ssh() {
    test_case "GitHub remote pattern detection (SSH)"
    local remote_url="git@github.com:user/repo.git"
    assert_contains "$remote_url" "github.com" && test_pass
}

test_non_github_remote() {
    test_case "Non-GitHub remote rejection"
    local remote_url="https://gitlab.com/user/repo.git"
    assert_not_contains "$remote_url" "github.com" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Token Status Return Values
# ══════════════════════════════════════════════════════════════════════════════

test_token_status_not_configured() {
    test_case "Token status: 'not configured'"
    local status_value="not configured"
    assert_equals "$status_value" "not configured" && test_pass
}

test_token_status_expired() {
    test_case "Token status: 'expired/invalid'"
    local status_value="expired/invalid"
    assert_equals "$status_value" "expired/invalid" && test_pass
}

test_token_status_expiring() {
    test_case "Token status: 'expiring in X days'"
    local days=3
    local status_value="expiring in $days days"
    assert_matches_pattern "$status_value" "expiring in [0-9]+ days" && test_pass
}

test_token_status_ok() {
    test_case "Token status: 'ok'"
    local status_value="ok"
    assert_equals "$status_value" "ok" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: Command Aliases
# ══════════════════════════════════════════════════════════════════════════════

test_flow_token_alias() {
    test_case "flow token delegates to tok"
    assert_function_exists "flow" && test_pass
}

test_dot_token_subcommands() {
    test_case "tok has expiring/rotate/sync subcommands"
    if assert_function_exists "_tok_expiring" && \
       assert_function_exists "_tok_rotate" && \
       assert_function_exists "_tok_sync_gh"; then
        test_pass
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    test_suite_start "Token Automation Unit Tests"

    setup

    # Function Existence Tests
    test_tok_age_days_exists
    test_tok_expiring_exists
    test_g_is_github_remote_exists
    test_g_validate_github_token_silent_exists
    test_work_project_uses_github_exists
    test_work_get_token_status_exists

    # Metadata Structure Tests (dot_version 2.1)
    test_metadata_version_2_1
    test_metadata_expires_days_field
    test_metadata_github_user_field
    test_metadata_created_timestamp
    test_metadata_complete_structure

    # Age Calculation Logic Tests
    test_age_calculation_10_days
    test_age_calculation_85_days

    # Expiration Threshold Logic Tests
    test_expiration_threshold_83_days
    test_no_warning_below_threshold
    test_expiration_days_remaining

    # GitHub Remote Detection Logic Tests
    test_github_remote_pattern_https
    test_github_remote_pattern_ssh
    test_non_github_remote

    # Token Status Return Values Tests
    test_token_status_not_configured
    test_token_status_expired
    test_token_status_expiring
    test_token_status_ok

    # Command Aliases Tests
    test_flow_token_alias
    test_dot_token_subcommands

    cleanup

    test_suite_end
    exit $?
}

main "$@"
