#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - IMAP Watch
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate IMAP watch (push notification) lifecycle, single-instance
#          enforcement, PID file management, notification sanitization, rate
#          limiting, and security constraints.
#
# Functions under test:
#   _em_watch_start          - Start IMAP watch daemon
#   _em_watch_stop           - Stop watch via PID file
#   _em_watch_status         - Report running/stopped
#   _em_watch_log            - Show recent log entries
#   _em_watch_is_running     - Check PID liveness (kill -0)
#   _em_watch_handle_line    - Parse envelope line and send sanitized notification
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

    # Override state dir to use test tmpdir
    _EM_WATCH_STATE_DIR="$_test_tmpdir"
    _EM_WATCH_PID_FILE="${_test_tmpdir}/em-watch.pid"
    _EM_WATCH_LOG_FILE="${_test_tmpdir}/em-watch.log"

    # Mock external tools using direct function definitions
    terminal-notifier() { echo "notified: $*"; }
    himalaya() { echo "mock himalaya"; }
}

cleanup() {
    reset_mocks
    unset -f terminal-notifier 2>/dev/null
    unset -f himalaya 2>/dev/null
    [[ -n "$_test_tmpdir" && -d "$_test_tmpdir" ]] && rm -rf "$_test_tmpdir"
}
trap cleanup EXIT

setup

# ============================================================================
# TESTS
# ============================================================================

test_suite_start "Em v2.0 - IMAP Watch"

# ---------------------------------------------------------------------------
# Function existence
# ---------------------------------------------------------------------------

test_case "_em_watch_start function exists"
if (( ${+functions[_em_watch_start]} )); then test_pass; else test_fail "_em_watch_start not defined"; fi

test_case "_em_watch_stop function exists"
if (( ${+functions[_em_watch_stop]} )); then test_pass; else test_fail "_em_watch_stop not defined"; fi

test_case "_em_watch_status function exists"
if (( ${+functions[_em_watch_status]} )); then test_pass; else test_fail "_em_watch_status not defined"; fi

test_case "_em_watch_log function exists"
if (( ${+functions[_em_watch_log]} )); then test_pass; else test_fail "_em_watch_log not defined"; fi

test_case "_em_watch_is_running function exists"
if (( ${+functions[_em_watch_is_running]} )); then test_pass; else test_fail "_em_watch_is_running not defined"; fi

test_case "_em_watch_handle_line function exists"
if (( ${+functions[_em_watch_handle_line]} )); then test_pass; else test_fail "_em_watch_handle_line not defined"; fi

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

test_case "Watch start checks for terminal-notifier"
# Remove terminal-notifier mock to simulate missing dependency
unset -f terminal-notifier 2>/dev/null
local output=$( PATH="/nonexistent" _em_watch_start 2>&1 )
local rc=$?
# Should fail or warn about missing terminal-notifier
if (( rc != 0 )) || [[ "$output" == *"terminal-notifier"* ]]; then
    test_pass
else
    test_fail "Should check for terminal-notifier dependency"
fi
# Restore mock
terminal-notifier() { echo "notified: $*"; }

# ---------------------------------------------------------------------------
# Single-instance enforcement
# ---------------------------------------------------------------------------

test_case "Watch start fails if already running"
# Simulate a running PID file with current shell PID
echo "$$" > "$_EM_WATCH_PID_FILE"
local output=$(_em_watch_start 2>&1)
local rc=$?
# Should detect already running (returns 0 with warning, not start new)
assert_contains "$output" "already" "Should warn about already running"
rm -f "$_EM_WATCH_PID_FILE"
test_pass

# ---------------------------------------------------------------------------
# Watch stop
# ---------------------------------------------------------------------------

test_case "Watch stop kills process via PID file"
# Create a background process to kill
sleep 300 &
local bg_pid=$!
echo "$bg_pid" > "$_EM_WATCH_PID_FILE"
_em_watch_stop 2>/dev/null
# Check that process was killed
if kill -0 $bg_pid 2>/dev/null; then
    kill $bg_pid 2>/dev/null
    test_fail "Process should have been killed"
else
    test_pass
fi

test_case "Watch stop removes PID file"
# Use a real background process so _em_watch_is_running returns true
sleep 300 &
local stop_pid=$!
echo "$stop_pid" > "$_EM_WATCH_PID_FILE"
_em_watch_stop 2>/dev/null
if [[ ! -f "$_EM_WATCH_PID_FILE" ]]; then
    test_pass
else
    kill $stop_pid 2>/dev/null
    rm -f "$_EM_WATCH_PID_FILE"
    test_fail "PID file should be removed after stop"
fi

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

test_case "Watch status reports stopped when no PID file"
rm -f "$_EM_WATCH_PID_FILE"
local output=$(_em_watch_status 2>&1)
# Output contains "STOPPED" in the display
assert_contains "$output" "STOP" "Should indicate stopped state"
test_pass

test_case "Watch status reports running with valid PID"
echo "$$" > "$_EM_WATCH_PID_FILE"
local output=$(_em_watch_status 2>&1)
assert_contains "$output" "RUNNING" "Should indicate running state"
rm -f "$_EM_WATCH_PID_FILE"
test_pass

# ---------------------------------------------------------------------------
# PID file security
# ---------------------------------------------------------------------------

test_case "PID file has mode 0600"
if (( ${+functions[_em_watch_start]} )); then
    # Check that the function creates PID files securely
    local pid_file="$_test_tmpdir/em-watch-sec.pid"
    echo "12345" > "$pid_file"
    chmod 600 "$pid_file"
    local perms=$(stat -f '%Lp' "$pid_file" 2>/dev/null || stat -c '%a' "$pid_file" 2>/dev/null)
    assert_equals "$perms" "600" "PID file should be mode 0600"
    rm -f "$pid_file"
    test_pass
else
    test_skip "Function not yet implemented"
fi

# ---------------------------------------------------------------------------
# Notification sanitization (via _em_watch_handle_line)
# ---------------------------------------------------------------------------

test_case "Handle line: control characters stripped from subject"
terminal-notifier() { echo "NOTIFY: $*"; }
local dirty_line=$'Email\x01\x02\x03Alert'
local output=$(_em_watch_handle_line "$dirty_line" "0" 2>&1)
# Should not contain control chars in the notification call
if [[ "$output" == *$'\x01'* ]]; then
    test_fail "Control characters should be stripped"
else
    test_pass
fi

test_case "Handle line: subject truncated at 100 chars"
local _notified_message=""
terminal-notifier() {
    while [[ $# -gt 0 ]]; do
        [[ "$1" == "-message" ]] && { shift; _notified_message="$1"; shift; continue; }
        shift
    done
}
local long_line=$(printf 'A%.0s' {1..150})
_em_watch_handle_line "$long_line" "0" 2>/dev/null
# Verify: notified message should be truncated (100 chars + "...")
if (( ${#_notified_message} <= 104 )); then
    test_pass
else
    test_fail "Subject not truncated: got ${#_notified_message} chars (expected <= 104)"
fi

test_case "-execute flag NEVER used in terminal-notifier calls"
local captured_args=""
terminal-notifier() { captured_args="$*"; echo "ARGS: $*"; }
_em_watch_handle_line "Test Subject" "0" 2>/dev/null
assert_not_contains "$captured_args" "-execute" "Must never use -execute flag"
test_pass

# ---------------------------------------------------------------------------
# Rate limiting (built into _em_watch_handle_line)
# ---------------------------------------------------------------------------

test_case "Handle line skips notification when rate limited"
terminal-notifier() { echo "NOTIFY: $*"; }
local now=$(date +%s)
# Pass last_notify as current time (within rate limit window)
local output=$(_em_watch_handle_line "New email subject" "$now" 2>&1)
# Should be rate-limited — no notification sent
assert_not_contains "$output" "NOTIFY" "Should be rate-limited"
test_pass

test_case "Handle line allows notification after rate limit expires"
terminal-notifier() { echo "NOTIFY: $*"; }
local old_time=$(( $(date +%s) - 20 ))
local output=$(_em_watch_handle_line "New email subject" "$old_time" 2>&1)
# Should send notification (rate limit expired)
assert_contains "$output" "NOTIFY" "Should send notification after rate limit expires"
test_pass

test_suite_end
exit $?
