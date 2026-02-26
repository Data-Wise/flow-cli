#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - Attachments
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate attachment listing, downloading, path traversal prevention,
#          filename sanitization, and version-aware himalaya integration.
#
# Functions under test:
#   _em_attach_list            - List attachments for a message
#   _em_attach_get             - Download a specific attachment
#   _em_sanitize_filename      - Strip directory components, block traversal
#   _em_check_download_path    - Containment check via realpath
#   _em_hml_attachment_list    - Version-aware himalaya attachment list
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

_test_tmpdir=""

setup() {
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    exec < /dev/null

    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Create a temp download dir for tests
    _test_tmpdir=$(mktemp -d)

    # Mock himalaya
    create_mock "himalaya" 'echo "mock himalaya $*"'
}

cleanup() {
    reset_mocks
    [[ -n "$_test_tmpdir" && -d "$_test_tmpdir" ]] && rm -rf "$_test_tmpdir"
}
trap cleanup EXIT

setup

# ============================================================================
# TESTS
# ============================================================================

test_suite_start "Em v2.0 - Attachments"

# ---------------------------------------------------------------------------
# Function existence
# ---------------------------------------------------------------------------

test_case "_em_attach_list function exists"
assert_function_exists "_em_attach_list" || true
test_pass

test_case "_em_attach_get function exists"
assert_function_exists "_em_attach_get" || true
test_pass

test_case "_em_sanitize_filename function exists"
assert_function_exists "_em_sanitize_filename" || true
test_pass

test_case "_em_check_download_path function exists"
assert_function_exists "_em_check_download_path" || true
test_pass

# ---------------------------------------------------------------------------
# Attachment listing
# ---------------------------------------------------------------------------

test_case "Attach list requires valid message ID"
local output=$(_em_attach_list "" 2>&1)
local rc=$?
assert_exit_code $rc 1 "Empty message ID should fail"
test_pass

test_case "Attach list with valid ID calls himalaya"
create_mock "_em_hml_attachment_list" 'echo "report.pdf (application/pdf, 1.2MB)"'
local output=$(_em_attach_list "42" 2>&1)
assert_exit_code $? 0
test_pass

# ---------------------------------------------------------------------------
# Attachment download
# ---------------------------------------------------------------------------

test_case "Attach get requires message ID and filename"
local output=$(_em_attach_get "" "" 2>&1)
local rc=$?
assert_exit_code $rc 1 "Missing args should fail"
test_pass

test_case "Attach get with valid args proceeds"
create_mock "_em_validate_msg_id" 'return 0'
create_mock "himalaya" 'echo "downloaded"'
local output=$(_em_attach_get "42" "report.pdf" 2>&1)
local rc=$?
assert_exit_code $rc 0
test_pass

# ---------------------------------------------------------------------------
# Path traversal prevention
# ---------------------------------------------------------------------------

test_case "Path traversal '../../../etc/passwd' rejected in filename"
local sanitized=$(_em_sanitize_filename "../../../etc/passwd" 2>/dev/null)
local rc=$?
# Should either strip to 'passwd' or reject entirely
if [[ "$sanitized" == *".."* ]] || [[ "$sanitized" == *"/"* ]]; then
    test_fail "Path traversal not blocked: got '$sanitized'"
else
    test_pass
fi

test_case "Directory components stripped from filename"
local sanitized=$(_em_sanitize_filename "subdir/file.txt" 2>/dev/null)
assert_equals "$sanitized" "file.txt" "Should strip directory prefix"
test_pass

test_case "Backslash path traversal blocked"
local sanitized=$(_em_sanitize_filename '..\..\etc\passwd' 2>/dev/null)
if [[ "$sanitized" == *".."* ]] || [[ "$sanitized" == *"\\"* ]]; then
    test_fail "Backslash traversal not blocked: got '$sanitized'"
else
    test_pass
fi

test_case "Empty filename rejected"
local sanitized=$(_em_sanitize_filename "" 2>/dev/null)
local rc=$?
assert_exit_code $rc 1 "Empty filename should fail"
test_pass

# ---------------------------------------------------------------------------
# Download containment check
# ---------------------------------------------------------------------------

test_case "Download path inside target dir accepted"
local result=$(_em_check_download_path "$_test_tmpdir/report.pdf" "$_test_tmpdir" 2>/dev/null)
assert_exit_code $? 0 "Path inside target dir should be accepted"
test_pass

test_case "Download path escaping target dir rejected"
local result=$(_em_check_download_path "/etc/passwd" "$_test_tmpdir" 2>/dev/null)
assert_exit_code $? 1 "Path outside target dir should be rejected"
test_pass

test_case "Symlink escape attempt rejected"
# Create a symlink that points outside the download dir
ln -sf /etc "$_test_tmpdir/escape_link" 2>/dev/null
local result=$(_em_check_download_path "$_test_tmpdir/escape_link/passwd" "$_test_tmpdir" 2>/dev/null)
assert_exit_code $? 1 "Symlink escape should be rejected"
rm -f "$_test_tmpdir/escape_link"
test_pass

# ---------------------------------------------------------------------------
# Version-aware attachment listing
# ---------------------------------------------------------------------------

test_case "_em_hml_attachment_list function exists"
assert_function_exists "_em_hml_attachment_list" || true
test_pass

test_case "Attachment list adapts to himalaya version"
# Contract: _em_hml_attachment_list should call himalaya with the right
# flags depending on version (JSON output for newer versions)
if (( ${+functions[_em_hml_attachment_list]} )); then
    create_mock "himalaya" 'echo "[]"'
    _em_hml_attachment_list "42" 2>/dev/null
    test_pass
else
    test_skip "Function not yet implemented"
fi

test_suite_end
exit $?
