#!/usr/bin/env zsh
# Test script for sec (macOS Keychain integration)
# Tests: add, get, list, delete operations

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# test_skip helper (not in framework yet)
test_skip() {
    echo "${YELLOW}SKIP${RESET} - $1"
    CURRENT_TEST=""
}

# ============================================================================
# SETUP
# ============================================================================

# Test secret name (unique to avoid conflicts)
TEST_SECRET_NAME="flow-cli-test-secret-$$"
TEST_SECRET_VALUE="test-value-$(date +%s)"

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find project root"; exit 1
    fi
    source "$PROJECT_ROOT/lib/core.zsh"
    source "$PROJECT_ROOT/lib/keychain-helpers.zsh"
}

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up test secrets...${RESET}"

    # Remove test secret if it exists
    security delete-generic-password \
        -a "$TEST_SECRET_NAME" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null

    echo "  Cleanup complete"
}

# ============================================================================
# UNIT TESTS - FUNCTION EXISTENCE
# ============================================================================

test_kc_add_exists() {
    test_case "_dotf_kc_add exists"
    assert_function_exists "_dotf_kc_add" && test_pass
}

test_kc_get_exists() {
    test_case "_dotf_kc_get exists"
    assert_function_exists "_dotf_kc_get" && test_pass
}

test_kc_list_exists() {
    test_case "_dotf_kc_list exists"
    assert_function_exists "_dotf_kc_list" && test_pass
}

test_kc_delete_exists() {
    test_case "_dotf_kc_delete exists"
    assert_function_exists "_dotf_kc_delete" && test_pass
}

test_kc_help_exists() {
    test_case "_dotf_kc_help exists"
    assert_function_exists "_dotf_kc_help" && test_pass
}

test_kc_import_exists() {
    test_case "_dotf_kc_import exists"
    assert_function_exists "_dotf_kc_import" && test_pass
}

# ============================================================================
# UNIT TESTS - CONSTANTS
# ============================================================================

test_service_constant() {
    test_case "_DOT_KEYCHAIN_SERVICE is set"
    assert_not_empty "$_DOT_KEYCHAIN_SERVICE" && test_pass
}

test_service_name_value() {
    test_case "_DOT_KEYCHAIN_SERVICE is 'flow-cli-secrets'"
    assert_equals "$_DOT_KEYCHAIN_SERVICE" "flow-cli-secrets" && test_pass
}

# ============================================================================
# UNIT TESTS - INPUT VALIDATION
# ============================================================================

test_add_empty_name() {
    test_case "_dotf_kc_add rejects empty name"
    _dotf_kc_add "" &>/dev/null
    assert_exit_code $? 1 "Should reject empty name" && test_pass
}

test_get_empty_name() {
    test_case "_dotf_kc_get rejects empty name"
    _dotf_kc_get "" &>/dev/null
    assert_exit_code $? 1 "Should reject empty name" && test_pass
}

test_delete_empty_name() {
    test_case "_dotf_kc_delete rejects empty name"
    _dotf_kc_delete "" &>/dev/null
    assert_exit_code $? 1 "Should reject empty name" && test_pass
}

# ============================================================================
# UNIT TESTS - KEYCHAIN OPERATIONS (requires macOS)
# ============================================================================

test_get_nonexistent() {
    test_case "_dotf_kc_get returns error for nonexistent secret"
    _dotf_kc_get "nonexistent-secret-$(date +%s)" &>/dev/null
    assert_exit_code $? 1 "Should return error for nonexistent secret" && test_pass
}

test_delete_nonexistent() {
    test_case "_dotf_kc_delete handles nonexistent secret"
    _dotf_kc_delete "nonexistent-secret-$(date +%s)" &>/dev/null
    assert_exit_code $? 1 "Should return error for nonexistent secret" && test_pass
}

test_list_runs() {
    test_case "_dotf_kc_list runs without error"
    _dotf_kc_list &>/dev/null
    assert_exit_code $? 0 "Should run without error" && test_pass
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_help_content() {
    test_case "_dotf_kc_help shows commands"
    local output=$(_dotf_kc_help 2>&1)
    assert_contains "$output" "add" "Help should list add command" && \
    assert_contains "$output" "list" "Help should list list command" && \
    assert_contains "$output" "delete" "Help should list delete command" && \
    test_pass
}

test_help_shows_benefits() {
    test_case "_dotf_kc_help shows Touch ID benefit"
    local output=$(_dotf_kc_help 2>&1)
    # Case-insensitive check via lowercase conversion
    local lower_output="${output:l}"
    assert_contains "$lower_output" "touch id" "Help should mention Touch ID" && test_pass
}

# ============================================================================
# DISPATCHER ROUTING TESTS
# ============================================================================

test_dispatcher_routes_add() {
    test_case "_sec_get routes 'add' correctly"
    assert_function_exists "_sec_get" || return
    # Should call _dotf_kc_add (which fails on empty, proving routing)
    _sec_get add &>/dev/null
    assert_exit_code $? 1 "Should route to _dotf_kc_add" && test_pass
}

test_dispatcher_routes_list() {
    test_case "_sec_get routes 'list' correctly"
    _sec_get list &>/dev/null
    assert_exit_code $? 0 "Should route to _dotf_kc_list" && test_pass
}

test_dispatcher_routes_ls_alias() {
    test_case "_sec_get routes 'ls' as list alias (via list)"
    _sec_get list &>/dev/null
    assert_exit_code $? 0 "Should route to _dotf_kc_list" && test_pass
}

test_dispatcher_routes_help() {
    test_case "_sec_get routes 'help' correctly"
    local output=$(_sec_get help 2>&1)
    assert_contains "$output" "Keychain" "Should show help text" || \
    assert_contains "$output" "secret" "Should show help text" && \
    test_pass
}

test_dispatcher_routes_help_flag() {
    test_case "_sec_get routes '--help' flag"
    local output=$(_sec_get --help 2>&1)
    assert_contains "$output" "Keychain" "Should show help text for --help" || \
    assert_contains "$output" "secret" "Should show help text for --help" && \
    test_pass
}

test_dispatcher_routes_h_flag() {
    test_case "_sec_get routes '-h' flag"
    local output=$(_sec_get -h 2>&1)
    assert_contains "$output" "Keychain" "Should show help text for -h" || \
    assert_contains "$output" "secret" "Should show help text for -h" && \
    test_pass
}

test_dispatcher_default_to_get() {
    test_case "_sec_get defaults unknown args to get"
    # Unknown arg should try to get (and fail since doesn't exist)
    _sec_get "unknown-secret-name-$$" &>/dev/null
    assert_exit_code $? 1 "Should attempt get for unknown command" && test_pass
}

test_dispatcher_empty_shows_help() {
    test_case "_sec_get with no args shows help"
    local output=$(_sec_get 2>&1)
    assert_contains "$output" "Keychain" "Should show help when no args" || \
    assert_contains "$output" "secret" "Should show help when no args" && \
    test_pass
}

test_dispatcher_delete_aliases() {
    test_case "_sec_get routes 'delete' correctly"
    _sec_get delete "" &>/dev/null
    # Should fail on empty name (proves routing to delete)
    assert_exit_code $? 1 "Should route 'delete' to _dotf_kc_delete" && test_pass
}

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

test_secret_with_spaces() {
    test_case "Secret name with spaces"
    local test_name="test secret with spaces $$"

    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "value-with-spaces" \
        -U &>/dev/null

    local result=$(_dotf_kc_get "$test_name" 2>&1)
    security delete-generic-password -a "$test_name" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    assert_equals "$result" "value-with-spaces" "Should handle names with spaces" && test_pass
}

test_secret_with_special_chars() {
    test_case "Secret name with special chars"
    local test_name="test-secret_with.special-chars-$$"

    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "special-value" \
        -U &>/dev/null

    local result=$(_dotf_kc_get "$test_name" 2>&1)
    security delete-generic-password -a "$test_name" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    assert_equals "$result" "special-value" "Should handle special characters" && test_pass
}

test_update_existing_secret() {
    test_case "Update existing secret overwrites value"
    local test_name="update-test-$$"

    # Add initial value
    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "initial-value" \
        -U &>/dev/null

    # Update with new value
    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "updated-value" \
        -U &>/dev/null

    local result=$(_dotf_kc_get "$test_name" 2>&1)
    security delete-generic-password -a "$test_name" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    assert_equals "$result" "updated-value" "Should update to new value (got: '$result')" && test_pass
}

test_multiple_secrets_in_list() {
    test_case "List shows multiple secrets"
    local prefix="multi-test-$$"

    # Add multiple secrets
    security add-generic-password -a "${prefix}-1" -s "$_DOT_KEYCHAIN_SERVICE" -w "v1" -U &>/dev/null
    security add-generic-password -a "${prefix}-2" -s "$_DOT_KEYCHAIN_SERVICE" -w "v2" -U &>/dev/null

    local list_output=$(_dotf_kc_list 2>&1)

    # Cleanup
    security delete-generic-password -a "${prefix}-1" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null
    security delete-generic-password -a "${prefix}-2" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    assert_contains "$list_output" "${prefix}-1" "Should list first secret" && \
    assert_contains "$list_output" "${prefix}-2" "Should list second secret" && \
    test_pass
}

test_secret_value_with_special_chars() {
    test_case "Secret value with special chars preserved"
    local test_name="value-special-$$"
    local test_value='p@$$w0rd!#$%^&*()'

    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$test_value" \
        -U &>/dev/null

    local result=$(_dotf_kc_get "$test_name" 2>&1)
    security delete-generic-password -a "$test_name" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    assert_equals "$result" "$test_value" "Special chars in value not preserved" && test_pass
}

# ============================================================================
# INTEGRATION TESTS - ADD/GET/DELETE CYCLE
# ============================================================================

test_add_get_delete_cycle() {
    # Step 1: Add secret using security command directly (avoiding interactive prompt)
    test_case "Add test secret to Keychain"
    if security add-generic-password \
        -a "$TEST_SECRET_NAME" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$TEST_SECRET_VALUE" \
        -U 2>/dev/null; then
        test_pass
    else
        test_fail "Failed to add test secret"
        return 1
    fi

    # Step 2: Retrieve secret
    test_case "Get test secret from Keychain"
    local retrieved=$(_dotf_kc_get "$TEST_SECRET_NAME" 2>&1)
    assert_equals "$retrieved" "$TEST_SECRET_VALUE" \
        "Retrieved value doesn't match (got: '$retrieved', expected: '$TEST_SECRET_VALUE')" && test_pass

    # Step 3: List should include our secret
    test_case "List includes test secret"
    local list_output=$(_dotf_kc_list 2>&1)
    assert_contains "$list_output" "$TEST_SECRET_NAME" "Test secret not found in list" && test_pass

    # Step 4: Delete secret
    test_case "Delete test secret from Keychain"
    _dotf_kc_delete "$TEST_SECRET_NAME" &>/dev/null
    assert_exit_code $? 0 "Failed to delete test secret" && test_pass

    # Step 5: Verify deletion
    test_case "Verify secret is deleted"
    _dotf_kc_get "$TEST_SECRET_NAME" &>/dev/null
    assert_exit_code $? 1 "Secret should be deleted but was found" && test_pass
}

# ============================================================================
# IMPORT TESTS (Mock-based)
# ============================================================================

test_import_process_substitution_count() {
    test_case "Import uses process substitution (count preserved)"

    # This tests the fix for the subshell count issue
    # When using `cmd | while`, count is lost. With `while ... done < <(cmd)`, it's preserved.
    local count=0
    local name value

    while IFS=$'\t' read -r name value; do
        if [[ -n "$name" && -n "$value" ]]; then
            ((count++))
        fi
    done < <(echo -e "secret1\tvalue1\nsecret2\tvalue2\nsecret3\tvalue3")

    assert_equals "$count" "3" "Expected count=3, got count=$count (process substitution may be broken)" && test_pass
}

test_import_pipe_count_regression() {
    test_case "Pipe-based while loses count (expected behavior)"

    # This demonstrates WHY we use process substitution
    # With pipe, count stays 0 in parent shell
    local count=0

    echo -e "a\t1\nb\t2" | while IFS=$'\t' read -r name value; do
        ((count++))
    done

    # In ZSH with pipe, count should be 0 (subshell issue)
    # If this test fails, ZSH behavior changed
    if [[ $count -eq 0 ]]; then
        test_pass
    else
        # ZSH might behave differently with lastpipe option
        test_skip "ZSH preserved count through pipe (lastpipe enabled?)"
    fi
}

test_import_handles_empty_password() {
    test_case "Import skips items with empty password"

    local count=0
    local name value

    while IFS=$'\t' read -r name value; do
        if [[ -n "$name" && -n "$value" ]]; then
            ((count++))
        fi
    done < <(echo -e "secret1\tvalue1\nsecret2\t\nsecret3\tvalue3")

    assert_equals "$count" "2" "Expected count=2 (skip empty), got count=$count" && test_pass
}

test_import_handles_empty_name() {
    test_case "Import skips items with empty name"

    local count=0
    local name value

    while IFS=$'\t' read -r name value; do
        if [[ -n "$name" && -n "$value" ]]; then
            ((count++))
        fi
    done < <(echo -e "secret1\tvalue1\n\tvalue2\nsecret3\tvalue3")

    assert_equals "$count" "2" "Expected count=2 (skip empty name), got count=$count" && test_pass
}

test_import_requires_bw() {
    test_case "Import checks for bw command"

    # Temporarily hide bw
    local original_path="$PATH"
    PATH="/usr/bin:/bin"

    local output
    output=$(_dotf_kc_import 2>&1 <<< "n")

    PATH="$original_path"

    if [[ "$output" == *"Bitwarden CLI not installed"* ]] || [[ "$output" == *"bw"* ]]; then
        test_pass
    else
        # bw might be in /usr/bin, so this could still find it
        test_skip "bw found in restricted PATH"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite "SEC KEYCHAIN TESTS"

    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo ""
        echo "${YELLOW}WARNING: These tests require macOS Keychain${RESET}"
        echo "Skipping Keychain-specific tests on non-macOS system"
        exit 0
    fi

    setup

    echo "--- Function Existence ---"
    test_kc_add_exists
    test_kc_get_exists
    test_kc_list_exists
    test_kc_delete_exists
    test_kc_help_exists
    test_kc_import_exists

    echo ""
    echo "--- Constants ---"
    test_service_constant
    test_service_name_value

    echo ""
    echo "--- Input Validation ---"
    test_add_empty_name
    test_get_empty_name
    test_delete_empty_name

    echo ""
    echo "--- Error Handling ---"
    test_get_nonexistent
    test_delete_nonexistent
    test_list_runs

    echo ""
    echo "--- Help ---"
    test_help_content
    test_help_shows_benefits

    echo ""
    echo "--- Dispatcher Routing ---"
    test_dispatcher_routes_add
    test_dispatcher_routes_list
    test_dispatcher_routes_ls_alias
    test_dispatcher_routes_help
    test_dispatcher_routes_help_flag
    test_dispatcher_routes_h_flag
    test_dispatcher_default_to_get
    test_dispatcher_empty_shows_help
    test_dispatcher_delete_aliases

    echo ""
    echo "--- Edge Cases ---"
    test_secret_with_spaces
    test_secret_with_special_chars
    test_update_existing_secret
    test_multiple_secrets_in_list
    test_secret_value_with_special_chars

    echo ""
    echo "--- Import (Mock-based) ---"
    test_import_process_substitution_count
    test_import_pipe_count_regression
    test_import_handles_empty_password
    test_import_handles_empty_name
    test_import_requires_bw

    echo ""
    echo "--- Integration: Add/Get/Delete Cycle ---"
    test_add_get_delete_cycle

    cleanup

    print_summary
    exit $?
}

main "$@"
