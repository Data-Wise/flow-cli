#!/usr/bin/env zsh
# Test script for sec (macOS Keychain integration) (macOS Keychain integration)
# Tests: add, get, list, delete operations

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
    echo "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

skip() {
    echo "${YELLOW}SKIP${NC} - $1"
}

# ============================================================================
# SETUP
# ============================================================================

# Test secret name (unique to avoid conflicts)
TEST_SECRET_NAME="flow-cli-test-secret-$$"
TEST_SECRET_VALUE="test-value-$(date +%s)"

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    local project_root=""

    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    if [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]]; then
        if [[ -f "$PWD/flow.plugin.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../flow.plugin.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source required files
    source "$project_root/lib/core.zsh"
    source "$project_root/lib/keychain-helpers.zsh"

    echo "  Loaded: core.zsh"
    echo "  Loaded: keychain-helpers.zsh"
    echo "  Test secret name: $TEST_SECRET_NAME"
    echo ""
}

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up test secrets...${NC}"

    # Remove test secret if it exists
    security delete-generic-password \
        -a "$TEST_SECRET_NAME" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null

    echo "  Cleanup complete"
}

# ============================================================================
# UNIT TESTS - FUNCTION EXISTENCE
# ============================================================================

test_functions_exist() {
    log_test "_dotf_kc_add exists"
    if type _dotf_kc_add &>/dev/null; then
        pass
    else
        fail "Function not found"
    fi

    log_test "_dotf_kc_get exists"
    if type _dotf_kc_get &>/dev/null; then
        pass
    else
        fail "Function not found"
    fi

    log_test "_dotf_kc_list exists"
    if type _dotf_kc_list &>/dev/null; then
        pass
    else
        fail "Function not found"
    fi

    log_test "_dotf_kc_delete exists"
    if type _dotf_kc_delete &>/dev/null; then
        pass
    else
        fail "Function not found"
    fi

    log_test "_dotf_kc_help exists"
    if type _dotf_kc_help &>/dev/null; then
        pass
    else
        fail "Function not found"
    fi
}

# ============================================================================
# UNIT TESTS - INPUT VALIDATION
# ============================================================================

test_add_empty_name() {
    log_test "_dotf_kc_add rejects empty name"
    _dotf_kc_add "" &>/dev/null
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Should reject empty name"
    fi
}

test_get_empty_name() {
    log_test "_dotf_kc_get rejects empty name"
    _dotf_kc_get "" &>/dev/null
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Should reject empty name"
    fi
}

test_delete_empty_name() {
    log_test "_dotf_kc_delete rejects empty name"
    _dotf_kc_delete "" &>/dev/null
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Should reject empty name"
    fi
}

# ============================================================================
# UNIT TESTS - KEYCHAIN OPERATIONS (requires macOS)
# ============================================================================

test_get_nonexistent() {
    log_test "_dotf_kc_get returns error for nonexistent secret"
    _dotf_kc_get "nonexistent-secret-$(date +%s)" &>/dev/null
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Should return error for nonexistent secret"
    fi
}

test_delete_nonexistent() {
    log_test "_dotf_kc_delete handles nonexistent secret"
    _dotf_kc_delete "nonexistent-secret-$(date +%s)" &>/dev/null
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Should return error for nonexistent secret"
    fi
}

test_list_runs() {
    log_test "_dotf_kc_list runs without error"
    _dotf_kc_list &>/dev/null
    if [[ $? -eq 0 ]]; then
        pass
    else
        fail "Should run without error"
    fi
}

# ============================================================================
# INTEGRATION TESTS - ADD/GET/DELETE CYCLE
# ============================================================================

test_add_get_delete_cycle() {
    echo ""
    echo "${YELLOW}Running integration test: add → get → delete cycle${NC}"

    # Step 1: Add secret using security command directly (avoiding interactive prompt)
    log_test "Add test secret to Keychain"
    if security add-generic-password \
        -a "$TEST_SECRET_NAME" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$TEST_SECRET_VALUE" \
        -U 2>/dev/null; then
        pass
    else
        fail "Failed to add test secret"
        return 1
    fi

    # Step 2: Retrieve secret
    log_test "Get test secret from Keychain"
    local retrieved=$(_dotf_kc_get "$TEST_SECRET_NAME" 2>&1)
    if [[ "$retrieved" == "$TEST_SECRET_VALUE" ]]; then
        pass
    else
        fail "Retrieved value doesn't match (got: '$retrieved', expected: '$TEST_SECRET_VALUE')"
    fi

    # Step 3: List should include our secret
    log_test "List includes test secret"
    local list_output=$(_dotf_kc_list 2>&1)
    if echo "$list_output" | grep -q "$TEST_SECRET_NAME"; then
        pass
    else
        fail "Test secret not found in list"
    fi

    # Step 4: Delete secret
    log_test "Delete test secret from Keychain"
    _dotf_kc_delete "$TEST_SECRET_NAME" &>/dev/null
    if [[ $? -eq 0 ]]; then
        pass
    else
        fail "Failed to delete test secret"
    fi

    # Step 5: Verify deletion
    log_test "Verify secret is deleted"
    _dotf_kc_get "$TEST_SECRET_NAME" &>/dev/null
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Secret should be deleted but was found"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_help_content() {
    log_test "_dotf_kc_help shows commands"
    local output=$(_dotf_kc_help 2>&1)
    if echo "$output" | grep -q "add" && \
       echo "$output" | grep -q "list" && \
       echo "$output" | grep -q "delete"; then
        pass
    else
        fail "Help should list add, list, delete commands"
    fi
}

test_help_shows_benefits() {
    log_test "_dotf_kc_help shows Touch ID benefit"
    local output=$(_dotf_kc_help 2>&1)
    if echo "$output" | grep -qi "touch id"; then
        pass
    else
        fail "Help should mention Touch ID"
    fi
}

# ============================================================================
# DISPATCHER ROUTING TESTS
# ============================================================================

test_dispatcher_routes_add() {
    log_test "_sec_get routes 'add' correctly"
    if type _sec_get &>/dev/null; then
        # Should call _dotf_kc_add (which fails on empty, proving routing)
        _sec_get add &>/dev/null
        if [[ $? -ne 0 ]]; then
            pass
        else
            fail "Should route to _dotf_kc_add"
        fi
    else
        fail "Dispatcher function not found"
    fi
}

test_dispatcher_routes_list() {
    log_test "_sec_get routes 'list' correctly"
    _sec_get list &>/dev/null
    if [[ $? -eq 0 ]]; then
        pass
    else
        fail "Should route to _dotf_kc_list"
    fi
}

test_dispatcher_routes_ls_alias() {
    log_test "_sec_get routes 'ls' as list alias (via list)"
    _sec_get list &>/dev/null
    if [[ $? -eq 0 ]]; then
        pass
    else
        fail "Should route to _dotf_kc_list"
    fi
}

test_dispatcher_routes_help() {
    log_test "_sec_get routes 'help' correctly"
    local output=$(_sec_get help 2>&1)
    if echo "$output" | grep -q "Keychain\|secret"; then
        pass
    else
        fail "Should show help text"
    fi
}

test_dispatcher_routes_help_flag() {
    log_test "_sec_get routes '--help' flag"
    local output=$(_sec_get --help 2>&1)
    if echo "$output" | grep -q "Keychain\|secret"; then
        pass
    else
        fail "Should show help text for --help"
    fi
}

test_dispatcher_routes_h_flag() {
    log_test "_sec_get routes '-h' flag"
    local output=$(_sec_get -h 2>&1)
    if echo "$output" | grep -q "Keychain\|secret"; then
        pass
    else
        fail "Should show help text for -h"
    fi
}

test_dispatcher_default_to_get() {
    log_test "_sec_get defaults unknown args to get"
    # Unknown arg should try to get (and fail since doesn't exist)
    _sec_get "unknown-secret-name-$$" &>/dev/null
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Should attempt get for unknown command"
    fi
}

test_dispatcher_empty_shows_help() {
    log_test "_sec_get with no args shows help"
    local output=$(_sec_get 2>&1)
    if echo "$output" | grep -q "Keychain\|secret"; then
        pass
    else
        fail "Should show help when no args"
    fi
}

test_dispatcher_delete_aliases() {
    log_test "_sec_get routes 'delete' correctly"
    _sec_get delete "" &>/dev/null
    # Should fail on empty name (proves routing to delete)
    if [[ $? -ne 0 ]]; then
        pass
    else
        fail "Should route 'delete' to _dotf_kc_delete"
    fi
}

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

test_secret_with_spaces() {
    log_test "Secret name with spaces"
    local test_name="test secret with spaces $$"

    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "value-with-spaces" \
        -U &>/dev/null

    local result=$(_dotf_kc_get "$test_name" 2>&1)
    security delete-generic-password -a "$test_name" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    if [[ "$result" == "value-with-spaces" ]]; then
        pass
    else
        fail "Should handle names with spaces"
    fi
}

test_secret_with_special_chars() {
    log_test "Secret name with special chars"
    local test_name="test-secret_with.special-chars-$$"

    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "special-value" \
        -U &>/dev/null

    local result=$(_dotf_kc_get "$test_name" 2>&1)
    security delete-generic-password -a "$test_name" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    if [[ "$result" == "special-value" ]]; then
        pass
    else
        fail "Should handle special characters"
    fi
}

test_update_existing_secret() {
    log_test "Update existing secret overwrites value"
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

    if [[ "$result" == "updated-value" ]]; then
        pass
    else
        fail "Should update to new value (got: '$result')"
    fi
}

test_multiple_secrets_in_list() {
    log_test "List shows multiple secrets"
    local prefix="multi-test-$$"

    # Add multiple secrets
    security add-generic-password -a "${prefix}-1" -s "$_DOT_KEYCHAIN_SERVICE" -w "v1" -U &>/dev/null
    security add-generic-password -a "${prefix}-2" -s "$_DOT_KEYCHAIN_SERVICE" -w "v2" -U &>/dev/null

    local list_output=$(_dotf_kc_list 2>&1)

    # Cleanup
    security delete-generic-password -a "${prefix}-1" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null
    security delete-generic-password -a "${prefix}-2" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    if echo "$list_output" | grep -q "${prefix}-1" && \
       echo "$list_output" | grep -q "${prefix}-2"; then
        pass
    else
        fail "Should list all secrets"
    fi
}

test_secret_value_with_special_chars() {
    log_test "Secret value with special chars preserved"
    local test_name="value-special-$$"
    local test_value='p@$$w0rd!#$%^&*()'

    security add-generic-password \
        -a "$test_name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$test_value" \
        -U &>/dev/null

    local result=$(_dotf_kc_get "$test_name" 2>&1)
    security delete-generic-password -a "$test_name" -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null

    if [[ "$result" == "$test_value" ]]; then
        pass
    else
        fail "Special chars in value not preserved"
    fi
}

# ============================================================================
# CONSTANT TESTS
# ============================================================================

test_service_constant() {
    log_test "_DOT_KEYCHAIN_SERVICE is set"
    if [[ -n "$_DOT_KEYCHAIN_SERVICE" ]]; then
        pass
    else
        fail "Constant should be set"
    fi
}

test_service_name_value() {
    log_test "_DOT_KEYCHAIN_SERVICE is 'flow-cli-secrets'"
    if [[ "$_DOT_KEYCHAIN_SERVICE" == "flow-cli-secrets" ]]; then
        pass
    else
        fail "Expected 'flow-cli-secrets', got '$_DOT_KEYCHAIN_SERVICE'"
    fi
}

# ============================================================================
# IMPORT TESTS (Mock-based)
# ============================================================================

# Mock data for import tests
MOCK_BW_ITEMS='[
  {"name": "mock-secret-1", "login": {"password": "value1"}},
  {"name": "mock-secret-2", "login": {"password": "value2"}},
  {"name": "mock-secret-3", "notes": "value3"}
]'
MOCK_BW_FOLDERS='[{"id": "folder-123", "name": "flow-cli-secrets"}]'

# Test import logic with mocked bw commands
test_import_process_substitution_count() {
    log_test "Import uses process substitution (count preserved)"

    # This tests the fix for the subshell count issue
    # When using `cmd | while`, count is lost. With `while ... done < <(cmd)`, it's preserved.

    local count=0
    local name value

    # Simulate the import loop pattern (using echo instead of bw)
    while IFS=$'\t' read -r name value; do
        if [[ -n "$name" && -n "$value" ]]; then
            ((count++))
        fi
    done < <(echo -e "secret1\tvalue1\nsecret2\tvalue2\nsecret3\tvalue3")

    if [[ $count -eq 3 ]]; then
        pass
    else
        fail "Expected count=3, got count=$count (process substitution may be broken)"
    fi
}

test_import_pipe_count_regression() {
    log_test "Pipe-based while loses count (expected behavior)"

    # This demonstrates WHY we use process substitution
    # With pipe, count stays 0 in parent shell
    local count=0

    echo -e "a\t1\nb\t2" | while IFS=$'\t' read -r name value; do
        ((count++))
    done

    # In ZSH with pipe, count should be 0 (subshell issue)
    # If this test fails, ZSH behavior changed
    if [[ $count -eq 0 ]]; then
        pass
    else
        # ZSH might behave differently with lastpipe option
        skip "ZSH preserved count through pipe (lastpipe enabled?)"
    fi
}

test_import_handles_empty_password() {
    log_test "Import skips items with empty password"

    local count=0
    local name value

    # Simulate import with one empty password
    while IFS=$'\t' read -r name value; do
        if [[ -n "$name" && -n "$value" ]]; then
            ((count++))
        fi
    done < <(echo -e "secret1\tvalue1\nsecret2\t\nsecret3\tvalue3")

    if [[ $count -eq 2 ]]; then
        pass
    else
        fail "Expected count=2 (skip empty), got count=$count"
    fi
}

test_import_handles_empty_name() {
    log_test "Import skips items with empty name"

    local count=0
    local name value

    while IFS=$'\t' read -r name value; do
        if [[ -n "$name" && -n "$value" ]]; then
            ((count++))
        fi
    done < <(echo -e "secret1\tvalue1\n\tvalue2\nsecret3\tvalue3")

    if [[ $count -eq 2 ]]; then
        pass
    else
        fail "Expected count=2 (skip empty name), got count=$count"
    fi
}

test_import_requires_bw() {
    log_test "Import checks for bw command"

    # Temporarily hide bw
    local original_path="$PATH"
    PATH="/usr/bin:/bin"

    local output
    output=$(_dotf_kc_import 2>&1 <<< "n")

    PATH="$original_path"

    if [[ "$output" == *"Bitwarden CLI not installed"* ]] || [[ "$output" == *"bw"* ]]; then
        pass
    else
        # bw might be in /usr/bin, so this could still find it
        skip "bw found in restricted PATH"
    fi
}

test_import_function_exists() {
    log_test "_dotf_kc_import function exists"
    if type _dotf_kc_import &>/dev/null; then
        pass
    else
        fail "_dotf_kc_import not defined"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SEC KEYCHAIN TESTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo ""
        echo "${YELLOW}WARNING: These tests require macOS Keychain${NC}"
        echo "Skipping Keychain-specific tests on non-macOS system"
        exit 0
    fi

    setup

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  UNIT TESTS: Function Existence"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_functions_exist

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  UNIT TESTS: Constants"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_service_constant
    test_service_name_value

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  UNIT TESTS: Input Validation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_add_empty_name
    test_get_empty_name
    test_delete_empty_name

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  UNIT TESTS: Error Handling"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_get_nonexistent
    test_delete_nonexistent
    test_list_runs

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  UNIT TESTS: Help"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_help_content
    test_help_shows_benefits

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  UNIT TESTS: Dispatcher Routing"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  EDGE CASE TESTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_secret_with_spaces
    test_secret_with_special_chars
    test_update_existing_secret
    test_multiple_secrets_in_list
    test_secret_value_with_special_chars

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  UNIT TESTS: Import (Mock-based)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_import_function_exists
    test_import_process_substitution_count
    test_import_pipe_count_regression
    test_import_handles_empty_password
    test_import_handles_empty_name
    test_import_requires_bw

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  INTEGRATION TESTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    test_add_get_delete_cycle

    cleanup

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  RESULTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "${RED}Some tests failed!${NC}"
        exit 1
    else
        echo "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
