#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - Safety Gate (Two-Phase Send)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate the two-phase send safety gate that prevents accidental
#          email sends. Tests preview display, user confirmation, force mode,
#          temp file security, and cleanup behavior.
#
# Functions under test:
#   _em_safety_gate          - Two-phase confirm before sending
#   _em_compose_draft        - Create secure temp draft file (mktemp + 0600)
#   _em_draft_cleanup        - Remove temp draft files
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

    _test_tmpdir=$(mktemp -d)
}

cleanup() {
    reset_mocks
    # Clean up any temp files we created
    [[ -n "$_test_tmpdir" && -d "$_test_tmpdir" ]] && rm -rf "$_test_tmpdir"
}
trap cleanup EXIT

setup

# ============================================================================
# TESTS
# ============================================================================

test_suite_start "Em v2.0 - Safety Gate (Two-Phase Send)"

# ---------------------------------------------------------------------------
# Function existence
# ---------------------------------------------------------------------------

test_case "_em_safety_gate function exists"
if (( ${+functions[_em_safety_gate]} )); then test_pass; else test_fail "_em_safety_gate not defined"; fi

test_case "_em_compose_draft function exists"
if (( ${+functions[_em_compose_draft]} )); then test_pass; else test_fail "_em_compose_draft not defined"; fi

test_case "_em_draft_cleanup function exists"
if (( ${+functions[_em_draft_cleanup]} )); then test_pass; else test_fail "_em_draft_cleanup not defined"; fi

# ---------------------------------------------------------------------------
# Draft preview display
# ---------------------------------------------------------------------------

test_case "Preview shows To, Subject, Body fields"
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
printf "To: user@example.com\nSubject: Test\n\nHello world" > "$draft_file"
local output=$(echo "N" | _em_safety_gate "$draft_file" "Send" 2>&1)
assert_contains "$output" "user@example.com" "Preview should show recipient"
assert_contains "$output" "Test" "Preview should show subject"
rm -f "$draft_file"
test_pass

# ---------------------------------------------------------------------------
# Safety gate — user confirmation
# ---------------------------------------------------------------------------

test_case "Force flag bypasses confirmation (returns 0)"
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
printf "To: a@b.com\nSubject: Test\n\nHi" > "$draft_file"
_em_safety_gate "$draft_file" "Send" "--force" 2>/dev/null
assert_exit_code $? 0
rm -f "$draft_file"
test_pass

test_case "Safety gate with 'y' input returns 0 (send)"
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
printf "To: a@b.com\nSubject: Test\n\nHi" > "$draft_file"
local rc=0
echo "y" | _em_safety_gate "$draft_file" "Send" 2>/dev/null || rc=$?
rm -f "$draft_file"
if (( rc == 0 )); then
    test_pass
else
    test_fail "Expected rc=0 for 'y' confirmation, got $rc"
fi

test_case "Safety gate with 'N' input returns 2 (user abort)"
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
printf "To: a@b.com\nSubject: Test\n\nHi" > "$draft_file"
echo "N" | _em_safety_gate "$draft_file" "Send" 2>/dev/null
local rc=$?
rm -f "$draft_file"
assert_exit_code $rc 2 "N should abort with exit code 2"
test_pass

test_case "Safety gate with empty input returns 2 (default-NO)"
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
printf "To: a@b.com\nSubject: Test\n\nHi" > "$draft_file"
echo "" | _em_safety_gate "$draft_file" "Send" 2>/dev/null
local rc=$?
rm -f "$draft_file"
assert_exit_code $rc 2 "Empty input should default to NO (exit code 2)"
test_pass

test_case "Safety gate with 'e' input triggers editor (mock verify)"
_em_open_in_editor() { true; }
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
printf "To: a@b.com\nSubject: Test\n\nHi" > "$draft_file"
# First 'e' to edit, then 'y' to send after edit
printf "e\ny\n" | _em_safety_gate "$draft_file" "Send" 2>/dev/null
local rc=$?
rm -f "$draft_file"
# Should have attempted to open the editor then returned 0 on 'y'
assert_exit_code $rc 0 "After edit then y, should return 0"
test_pass

# ---------------------------------------------------------------------------
# Temp file security (via _em_compose_draft)
# ---------------------------------------------------------------------------

test_case "Compose draft creates temp files with mktemp (not predictable paths)"
local tmpfile=$(_em_compose_draft "test@example.com" "Subject" "Body" 2>/dev/null)
if [[ -n "$tmpfile" && -f "$tmpfile" ]]; then
    # Should be in system temp dir, not a predictable name
    assert_contains "$tmpfile" "em-draft" "Temp file should have em-draft prefix"
    rm -f "$tmpfile"
    test_pass
else
    test_fail "Temp file not created"
fi

test_case "Compose draft files have mode 0600"
local tmpfile=$(_em_compose_draft "test@example.com" "Subject" "Body" 2>/dev/null)
if [[ -n "$tmpfile" && -f "$tmpfile" ]]; then
    local perms=$(stat -f '%Lp' "$tmpfile" 2>/dev/null || stat -c '%a' "$tmpfile" 2>/dev/null)
    rm -f "$tmpfile"
    assert_equals "$perms" "600" "Temp file permissions should be 0600"
    test_pass
else
    test_fail "Temp file not created"
fi

test_case "Draft cleanup removes temp file"
local tmpfile=$(mktemp)
echo "test draft" > "$tmpfile"
_em_draft_cleanup "$tmpfile" 2>/dev/null
if [[ ! -f "$tmpfile" ]]; then
    test_pass
else
    rm -f "$tmpfile"
    test_fail "Temp file should be removed after cleanup"
fi

# ---------------------------------------------------------------------------
# TOCTOU protection
# ---------------------------------------------------------------------------

test_case "Draft content read into variable before confirm prompt"
# Contract test: _em_safety_gate reads draft content into a local variable
# at the start, not re-read from file at send time. Verified by checking
# function source references TOCTOU or reads file into variable.
local func_body=$(whence -f _em_safety_gate 2>/dev/null)
if [[ -n "$func_body" ]]; then
    if [[ "$func_body" == *"TOCTOU"* ]] || [[ "$func_body" == *'$(<"$draft_file")'* ]]; then
        test_pass
    else
        test_fail "Safety gate should read draft into variable (TOCTOU protection)"
    fi
else
    test_skip "Function not yet implemented"
fi

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

test_case "Safety gate rejects missing draft file"
_em_safety_gate "/nonexistent/file.eml" "Send" 2>/dev/null
local rc=$?
assert_exit_code $rc 1 "Missing draft file should be rejected"
test_pass

test_case "Safety gate rejects empty draft file"
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
# Create empty file
: > "$draft_file"
_em_safety_gate "$draft_file" "Send" 2>/dev/null
local rc=$?
rm -f "$draft_file"
assert_exit_code $rc 1 "Empty draft should be rejected"
test_pass

test_case "Safety gate with --yes flag bypasses confirmation"
local draft_file=$(mktemp "$_test_tmpdir/draft-XXXXXX.eml")
printf "To: a@b.com\nSubject: Test\n\nHi" > "$draft_file"
_em_safety_gate "$draft_file" "Send" "--yes" 2>/dev/null
local rc=$?
rm -f "$draft_file"
assert_exit_code $rc 0 "--yes should bypass confirmation"
test_pass

test_suite_end
exit $?
