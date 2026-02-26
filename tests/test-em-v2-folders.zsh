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

    # Mock himalaya directly — create_mock breaks with bodies containing double quotes
    himalaya() { echo "mock himalaya $*"; }
}

cleanup() {
    reset_mocks 2>/dev/null
    unset -f himalaya 2>/dev/null
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
# Mock the low-level wrapper directly (avoid create_mock for functions with $ in body)
local _folder_create_called=0
_em_hml_folder_create() { _folder_create_called=$((_folder_create_called + 1)); echo "created $*"; }
local output=$(_em_create_folder "Archive" 2>&1)
# Verify the wrapper was called (subshell increments don't propagate, check output instead)
assert_contains "$output" "created" "Should call himalaya wrapper"
# Restore original function
source "$PROJECT_ROOT/lib/em-himalaya.zsh" 2>/dev/null
test_pass

test_case "Create folder with empty name fails"
_em_create_folder "" 2>/dev/null
assert_exit_code $? 1 "Empty folder name should fail"
test_pass

test_case "Create folder with leading dash fails (option injection)"
_em_create_folder "-flag" 2>/dev/null
assert_exit_code $? 1 "Leading dash should be rejected"
test_pass

# ---------------------------------------------------------------------------
# Folder deletion (type-to-confirm)
# ---------------------------------------------------------------------------

test_case "Delete folder requires type-to-confirm"
# Mock low-level wrapper directly
_em_hml_folder_delete() { echo "deleted"; }
# User types wrong confirmation
echo "wrong" | _em_delete_folder "Archive" 2>/dev/null
local rc=$?
# _em_delete_folder returns 2 (not 1) when confirmation doesn't match
assert_exit_code $rc 2 "Wrong confirmation should abort delete (rc=2)"
test_pass

test_case "Delete folder with correct confirmation succeeds"
_em_hml_folder_delete() { echo "deleted"; }
# User types the folder name to confirm
echo "Archive" | _em_delete_folder "Archive" 2>/dev/null
local rc=$?
assert_exit_code $rc 0 "Correct confirmation should proceed"
# Restore original
source "$PROJECT_ROOT/lib/em-himalaya.zsh" 2>/dev/null
test_pass

# ---------------------------------------------------------------------------
# Low-level wrappers use '--' separator
# ---------------------------------------------------------------------------

test_case "_em_hml_folder_create uses '--' before folder name"
# Re-source to ensure original functions are intact
source "$PROJECT_ROOT/lib/em-himalaya.zsh" 2>/dev/null
himalaya() { echo "himalaya $*"; }
if (( ${+functions[_em_hml_folder_create]} )); then
    local output=$(_em_hml_folder_create "TestFolder" 2>&1)
    assert_contains "$output" "--" "Should use '--' separator before folder name"
    test_pass
else
    test_skip "Function not yet implemented"
fi

test_case "_em_hml_folder_delete uses '--' before folder name"
if (( ${+functions[_em_hml_folder_delete]} )); then
    himalaya() { echo "himalaya $*"; }
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
# NOTE: split 'local' from assignment to preserve $?
local output
output=$(_em_create_folder "foo/bar" 2>&1)
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
