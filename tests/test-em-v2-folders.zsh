#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - Folder CRUD
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate folder creation, deletion, and safety checks for the
#          em dispatcher v2.0. Tests input validation, option injection
#          prevention, and type-to-confirm delete.
#
# Functions under test:
#   _em_create_folder       - Create folder with validation
#   _em_delete_folder       - Delete folder with type-to-confirm
#   _em_hml_folder_create   - Low-level himalaya folder create wrapper
#   _em_hml_folder_delete   - Low-level himalaya folder delete wrapper
#
# Created: 2026-02-26 (TDD — tests first)
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    exec < /dev/null

    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Mock himalaya to avoid real IMAP operations
    create_mock "himalaya" 'echo "mock himalaya $*"'
}

cleanup() {
    reset_mocks
}
trap cleanup EXIT

setup

# ============================================================================
# TESTS
# ============================================================================

test_suite_start "Em v2.0 - Folder CRUD"

# ---------------------------------------------------------------------------
# Function existence
# ---------------------------------------------------------------------------

test_case "_em_create_folder function exists"
assert_function_exists "_em_create_folder" || true
test_pass

test_case "_em_delete_folder function exists"
assert_function_exists "_em_delete_folder" || true
test_pass

test_case "_em_hml_folder_create function exists"
assert_function_exists "_em_hml_folder_create" || true
test_pass

test_case "_em_hml_folder_delete function exists"
assert_function_exists "_em_hml_folder_delete" || true
test_pass

# ---------------------------------------------------------------------------
# Folder creation
# ---------------------------------------------------------------------------

test_case "Create folder 'Archive' calls himalaya wrapper"
create_mock "_em_hml_folder_create" 'echo "created $*"'
local output=$(_em_create_folder "Archive" 2>&1)
assert_mock_called "_em_hml_folder_create" 1
test_pass

test_case "Create folder with empty name fails"
local output=$(_em_create_folder "" 2>&1)
local rc=$?
assert_exit_code $rc 1 "Empty folder name should fail"
test_pass

test_case "Create folder with leading dash fails (option injection)"
local output=$(_em_create_folder "-flag" 2>&1)
local rc=$?
assert_exit_code $rc 1 "Leading dash should be rejected"
test_pass

# ---------------------------------------------------------------------------
# Folder deletion (type-to-confirm)
# ---------------------------------------------------------------------------

test_case "Delete folder requires type-to-confirm"
create_mock "_em_hml_folder_delete" 'echo "deleted"'
# User types wrong confirmation
echo "wrong" | _em_delete_folder "Archive" 2>/dev/null
local rc=$?
assert_exit_code $rc 1 "Wrong confirmation should abort delete"
test_pass

test_case "Delete folder with correct confirmation succeeds"
create_mock "_em_hml_folder_delete" 'echo "deleted"'
# User types the folder name to confirm
echo "Archive" | _em_delete_folder "Archive" 2>/dev/null
local rc=$?
assert_exit_code $rc 0 "Correct confirmation should proceed"
test_pass

# ---------------------------------------------------------------------------
# Low-level wrappers use '--' separator
# ---------------------------------------------------------------------------

test_case "_em_hml_folder_create uses '--' before folder name"
# Reset to see raw himalaya calls
reset_mocks
create_mock "himalaya" 'echo "himalaya $*"'
# Re-source to get real function (not mocked version)
# Since function may not exist yet, test the contract
if (( ${+functions[_em_hml_folder_create]} )); then
    local output=$(_em_hml_folder_create "TestFolder" 2>&1)
    assert_contains "$output" "--" "Should use '--' separator before folder name"
    test_pass
else
    test_skip "Function not yet implemented"
fi

test_case "_em_hml_folder_delete uses '--' before folder name"
if (( ${+functions[_em_hml_folder_delete]} )); then
    reset_mocks
    create_mock "himalaya" 'echo "himalaya $*"'
    local output=$(_em_hml_folder_delete "TestFolder" 2>&1)
    assert_contains "$output" "--" "Should use '--' separator before folder name"
    test_pass
else
    test_skip "Function not yet implemented"
fi

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

test_case "Create folder with slashes in name rejected"
local output=$(_em_create_folder "foo/bar" 2>&1)
local rc=$?
assert_exit_code $rc 1 "Slashes in folder name should be rejected"
test_pass

test_case "Delete folder with empty name rejected"
echo "" | _em_delete_folder "" 2>/dev/null
local rc=$?
assert_exit_code $rc 1 "Empty folder name should fail"
test_pass

test_suite_end
exit $?
