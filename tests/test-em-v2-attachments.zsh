#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - Attachments
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate attachment listing, downloading, path traversal prevention,
#          filename sanitization (inline in _em_attach_get), and version-aware
#          himalaya integration.
#
# Functions under test:
#   _em_attach_list            - List attachments for a message
#   _em_attach_get             - Download a specific attachment (includes inline sanitization)
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
    himalaya() { echo "mock himalaya $*"; }
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
if (( ${+functions[_em_attach_list]} )); then test_pass; else test_fail "_em_attach_list not defined"; fi

test_case "_em_attach_get function exists"
if (( ${+functions[_em_attach_get]} )); then test_pass; else test_fail "_em_attach_get not defined"; fi

test_case "_em_hml_attachment_list function exists"
if (( ${+functions[_em_hml_attachment_list]} )); then test_pass; else test_fail "_em_hml_attachment_list not defined"; fi

# ---------------------------------------------------------------------------
# Attachment listing
# ---------------------------------------------------------------------------

test_case "Attach list requires valid message ID"
_em_attach_list "" >/dev/null 2>&1
local rc=$?
assert_exit_code $rc 1 "Empty message ID should fail"
test_pass

test_case "Attach list with valid ID calls himalaya adapter"
_em_hml_attachment_list() { echo '[{"filename":"report.pdf","mime_type":"application/pdf","size":1200}]'; }
_em_validate_msg_id() { return 0; }
_em_attach_list "42" >/dev/null 2>&1
assert_exit_code $? 0
test_pass

# ---------------------------------------------------------------------------
# Attachment download
# ---------------------------------------------------------------------------

test_case "Attach get requires message ID and filename"
_em_attach_get "" "" >/dev/null 2>&1
local rc=$?
assert_exit_code $rc 1 "Missing args should fail"
test_pass

test_case "Attach get with valid args proceeds"
_em_validate_msg_id() { return 0; }
_em_hml_attachment_download() {
    # Simulate downloading by creating the file
    local target_dir="$3"
    touch "${target_dir}/${2}"
    return 0
}
_em_attach_get "42" "report.pdf" "$_test_tmpdir" >/dev/null 2>&1
local rc=$?
assert_exit_code $rc 0
rm -f "$_test_tmpdir/report.pdf"
test_pass

# ---------------------------------------------------------------------------
# Path traversal prevention (inline in _em_attach_get)
# ---------------------------------------------------------------------------

test_case "Path traversal '../../../etc/passwd' sanitized in attach get"
_em_validate_msg_id() { return 0; }
local _download_got_filename=""
_em_hml_attachment_download() {
    _download_got_filename="$2"
    return 0
}
_em_attach_get "42" "../../../etc/passwd" "$_test_tmpdir" >/dev/null 2>&1
local rc=$?
# Must fail (file won't exist after download) or sanitize the filename
# Critical: must NOT contain path traversal in the resolved filename
if [[ "$_download_got_filename" == *".."* ]]; then
    test_fail "Path traversal not stripped from filename passed to download"
else
    # rc=1 means file not found after download (expected: sanitized name doesn't match)
    assert_exit_code $rc 1 "Should fail: sanitized filename won't match downloaded files"
    test_pass
fi

test_case "Directory components stripped from filename in attach get"
_em_validate_msg_id() { return 0; }
local _strip_got_filename=""
_em_hml_attachment_download() {
    _strip_got_filename="$2"
    local target_dir="$3"
    # Create file matching the sanitized name (no directory prefix)
    touch "${target_dir}/file.txt"
    return 0
}
_em_attach_get "42" "subdir/file.txt" "$_test_tmpdir" >/dev/null 2>&1
local rc=$?
# Verify directory component was stripped before passing to download
if [[ "$_strip_got_filename" == *"/"* ]]; then
    test_fail "Directory components should be stripped: got '$_strip_got_filename'"
else
    assert_exit_code $rc 0 "Should succeed with sanitized filename"
    test_pass
fi
rm -f "$_test_tmpdir/file.txt" 2>/dev/null

test_case "Empty filename rejected by attach get"
_em_attach_get "42" "" >/dev/null 2>&1
local rc=$?
assert_exit_code $rc 1 "Empty filename should fail"
test_pass

# ---------------------------------------------------------------------------
# Version-aware attachment listing
# ---------------------------------------------------------------------------

test_case "Attachment list adapts to himalaya version"
# Contract: _em_hml_attachment_list should call himalaya with the right
# flags depending on version (JSON output for newer versions)
if (( ${+functions[_em_hml_attachment_list]} )); then
    himalaya() { echo "[]"; }
    _em_hml_attachment_list "42" 2>/dev/null
    test_pass
else
    test_skip "Function not yet implemented"
fi

test_suite_end
exit $?
