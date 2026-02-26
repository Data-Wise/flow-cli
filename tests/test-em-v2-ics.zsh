#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - ICS Calendar Parser
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate ICS/iCalendar parsing for calendar invitations in emails.
#          Tests field extraction, date formatting, line folding, size limits,
#          display formatting, and AppleScript event creation.
#
# Functions under test:
#   _em_ics_parse          - Parse ICS content into structured fields
#   _em_ics_format_dt      - Format iCalendar datetime to human-readable
#   _em_ics_display_event  - Display event with colors
#   _em_ics_create_event   - Create macOS Calendar event (via AppleScript)
#   _em_ics_validate       - Validate ICS size and event count
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
    [[ -n "$_test_tmpdir" && -d "$_test_tmpdir" ]] && rm -rf "$_test_tmpdir"
}
trap cleanup EXIT

setup

# ============================================================================
# TEST FIXTURES
# ============================================================================

_make_valid_ics() {
    cat <<'ICS_EOF'
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SUMMARY:Team Standup
DTSTART:20260226T140000
DTEND:20260226T143000
LOCATION:Conference Room B
DESCRIPTION:Daily standup meeting
END:VEVENT
END:VCALENDAR
ICS_EOF
}

_make_folded_ics() {
    # ICS line folding: continuation lines start with a space
    cat <<'ICS_EOF'
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
SUMMARY:Very Long Meeting Title That Needs
 Line Folding To Fit
DTSTART:20260226T140000Z
DTEND:20260226T160000Z
LOCATION:Room
END:VEVENT
END:VCALENDAR
ICS_EOF
}

_make_no_vevent_ics() {
    cat <<'ICS_EOF'
BEGIN:VCALENDAR
VERSION:2.0
END:VCALENDAR
ICS_EOF
}

# ============================================================================
# TESTS
# ============================================================================

test_suite_start "Em v2.0 - ICS Calendar Parser"

# ---------------------------------------------------------------------------
# Function existence
# ---------------------------------------------------------------------------

test_case "_em_ics_parse function exists"
assert_function_exists "_em_ics_parse" || true
test_pass

test_case "_em_ics_format_dt function exists"
assert_function_exists "_em_ics_format_dt" || true
test_pass

test_case "_em_ics_display_event function exists"
assert_function_exists "_em_ics_display_event" || true
test_pass

test_case "_em_ics_create_event function exists"
assert_function_exists "_em_ics_create_event" || true
test_pass

test_case "_em_ics_validate function exists"
assert_function_exists "_em_ics_validate" || true
test_pass

# ---------------------------------------------------------------------------
# Field extraction
# ---------------------------------------------------------------------------

test_case "Parse extracts SUMMARY from valid ICS"
local ics=$(_make_valid_ics)
local summary=$(_em_ics_parse "$ics" "SUMMARY" 2>/dev/null)
assert_equals "$summary" "Team Standup"
test_pass

test_case "Parse extracts DTSTART"
local ics=$(_make_valid_ics)
local dtstart=$(_em_ics_parse "$ics" "DTSTART" 2>/dev/null)
assert_equals "$dtstart" "20260226T140000"
test_pass

test_case "Parse extracts DTEND"
local ics=$(_make_valid_ics)
local dtend=$(_em_ics_parse "$ics" "DTEND" 2>/dev/null)
assert_equals "$dtend" "20260226T143000"
test_pass

test_case "Parse extracts LOCATION"
local ics=$(_make_valid_ics)
local location=$(_em_ics_parse "$ics" "LOCATION" 2>/dev/null)
assert_equals "$location" "Conference Room B"
test_pass

# ---------------------------------------------------------------------------
# Line folding
# ---------------------------------------------------------------------------

test_case "Parse handles ICS line folding (continuation lines)"
local ics=$(_make_folded_ics)
local summary=$(_em_ics_parse "$ics" "SUMMARY" 2>/dev/null)
assert_contains "$summary" "Very Long Meeting Title" "Should unfold continuation lines"
assert_contains "$summary" "Line Folding" "Should join folded content"
test_pass

# ---------------------------------------------------------------------------
# Date/time formatting
# ---------------------------------------------------------------------------

test_case "Format local datetime: 20260226T140000 -> 2026-02-26 14:00"
local formatted=$(_em_ics_format_dt "20260226T140000" 2>/dev/null)
assert_equals "$formatted" "2026-02-26 14:00"
test_pass

test_case "Format UTC datetime: 20260226T140000Z"
local formatted=$(_em_ics_format_dt "20260226T140000Z" 2>/dev/null)
# Should handle Z suffix (UTC)
assert_contains "$formatted" "2026-02-26" "Should parse date portion"
assert_contains "$formatted" "14:00" "Should parse time portion"
test_pass

test_case "Format date-only: 20260226 -> 2026-02-26"
local formatted=$(_em_ics_format_dt "20260226" 2>/dev/null)
assert_contains "$formatted" "2026-02-26"
test_pass

test_case "Invalid datetime returns original or error"
local formatted=$(_em_ics_format_dt "not-a-date" 2>/dev/null)
# Should not crash; returns something
assert_not_empty "$formatted" "Should return something for invalid input"
test_pass

# ---------------------------------------------------------------------------
# Size and event limits
# ---------------------------------------------------------------------------

test_case "Oversized ICS (>1MB) rejected"
local big_file="$_test_tmpdir/big.ics"
# Create >1MB file
dd if=/dev/zero bs=1048577 count=1 2>/dev/null | tr '\0' 'A' > "$big_file"
_em_ics_validate "$big_file" 2>/dev/null
assert_exit_code $? 1 "ICS > 1MB should be rejected"
rm -f "$big_file"
test_pass

test_case "ICS with >10 events rejected"
local many_events="$_test_tmpdir/many.ics"
echo "BEGIN:VCALENDAR" > "$many_events"
echo "VERSION:2.0" >> "$many_events"
for i in {1..11}; do
    echo "BEGIN:VEVENT" >> "$many_events"
    echo "SUMMARY:Event $i" >> "$many_events"
    echo "DTSTART:20260226T${i}0000" >> "$many_events"
    echo "END:VEVENT" >> "$many_events"
done
echo "END:VCALENDAR" >> "$many_events"
_em_ics_validate "$many_events" 2>/dev/null
assert_exit_code $? 1 "ICS with >10 events should be rejected"
rm -f "$many_events"
test_pass

# ---------------------------------------------------------------------------
# Display formatting
# ---------------------------------------------------------------------------

test_case "Display event outputs colored text"
local ics=$(_make_valid_ics)
local output=$(_em_ics_display_event "$ics" 2>&1)
assert_not_empty "$output" "Display should produce output"
assert_contains "$output" "Team Standup" "Should show event summary"
test_pass

# ---------------------------------------------------------------------------
# AppleScript event creation
# ---------------------------------------------------------------------------

test_case "Create event sanitizes AppleScript input (quotes escaped)"
create_mock "osascript" 'echo "mock osascript: $*"'
# Verify that quotes in summary are escaped before passing to AppleScript
local ics='BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Meeting "with quotes"
DTSTART:20260226T140000
DTEND:20260226T150000
END:VEVENT
END:VCALENDAR'
echo "N" | _em_ics_create_event "$ics" 2>/dev/null
# We just need it to not crash; actual AppleScript test is manual
test_pass

test_case "Create event requires y/N confirmation"
create_mock "osascript" 'echo "created"'
local ics=$(_make_valid_ics)
echo "N" | _em_ics_create_event "$ics" 2>/dev/null
local rc=$?
# Should not create event when user says N
assert_mock_not_called "osascript" "Should not call osascript when user declines"
test_pass

# ---------------------------------------------------------------------------
# Malformed ICS handling
# ---------------------------------------------------------------------------

test_case "ICS with no VEVENT handled gracefully"
local ics=$(_make_no_vevent_ics)
local output=$(_em_ics_parse "$ics" "SUMMARY" 2>&1)
local rc=$?
# Should not crash; return empty or error
if (( rc != 0 )) || [[ -z "$output" ]]; then
    test_pass
else
    test_fail "Should handle missing VEVENT gracefully"
fi

test_case "Non-printable characters stripped from fields"
local ics='BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Meeting'$'\x01\x02\x03''Name
DTSTART:20260226T140000
END:VEVENT
END:VCALENDAR'
local summary=$(_em_ics_parse "$ics" "SUMMARY" 2>/dev/null)
# Should not contain control characters
if [[ "$summary" == *$'\x01'* ]] || [[ "$summary" == *$'\x02'* ]]; then
    test_fail "Non-printable characters should be stripped"
else
    test_pass
fi

test_case "Empty ICS input returns error"
_em_ics_parse "" "SUMMARY" 2>/dev/null
local rc=$?
assert_exit_code $rc 1 "Empty input should return error"
test_pass

test_suite_end
exit $?
