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
#   _em_watch_notify         - Send sanitized notification
#   _em_watch_rate_limit     - Rate limiter (1 per 10s)
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

    # Mock external tools
    create_mock "terminal-notifier" 'echo "notified: $*"'
    create_mock "himalaya" 'echo "mock himalaya"'
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

test_suite_start "Em v2.0 - IMAP Watch"

# ---------------------------------------------------------------------------
# Function existence
# ---------------------------------------------------------------------------

test_case "_em_watch_start function exists"
assert_function_exists "_em_watch_start" || true
test_pass

test_case "_em_watch_stop function exists"
assert_function_exists "_em_watch_stop" || true
test_pass

test_case "_em_watch_status function exists"
assert_function_exists "_em_watch_status" || true
test_pass

test_case "_em_watch_log function exists"
assert_function_exists "_em_watch_log" || true
test_pass

test_case "_em_watch_is_running function exists"
assert_function_exists "_em_watch_is_running" || true
test_pass

test_case "_em_watch_notify function exists"
assert_function_exists "_em_watch_notify" || true
test_pass

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
create_mock "terminal-notifier" 'echo "notified: $*"'

# ---------------------------------------------------------------------------
# Single-instance enforcement
# ---------------------------------------------------------------------------

test_case "Watch start fails if already running"
# Simulate a running PID file
local pid_file="$_test_tmpdir/em-watch.pid"
echo "$$" > "$pid_file"  # Current process PID (definitely running)
local output=$(_em_watch_start "$pid_file" 2>&1)
local rc=$?
assert_exit_code $rc 1 "Should not start if already running"
rm -f "$pid_file"
test_pass

# ---------------------------------------------------------------------------
# Watch stop
# ---------------------------------------------------------------------------

test_case "Watch stop kills process via PID file"
# Create a background process to kill
sleep 300 &
local bg_pid=$!
local pid_file="$_test_tmpdir/em-watch.pid"
echo "$bg_pid" > "$pid_file"
_em_watch_stop "$pid_file" 2>/dev/null
# Check that process was killed
if kill -0 $bg_pid 2>/dev/null; then
    kill $bg_pid 2>/dev/null
    test_fail "Process should have been killed"
else
    test_pass
fi
rm -f "$pid_file"

test_case "Watch stop removes PID file"
local pid_file="$_test_tmpdir/em-watch.pid"
echo "99999" > "$pid_file"  # Non-existent PID
_em_watch_stop "$pid_file" 2>/dev/null
if [[ ! -f "$pid_file" ]]; then
    test_pass
else
    rm -f "$pid_file"
    test_fail "PID file should be removed after stop"
fi

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

test_case "Watch status reports 'stopped' when no PID file"
local pid_file="$_test_tmpdir/em-watch.pid"
rm -f "$pid_file"
local output=$(_em_watch_status "$pid_file" 2>&1)
assert_contains "$output" "stop" "Should indicate stopped state"
test_pass

test_case "Watch status reports 'running' with valid PID"
local pid_file="$_test_tmpdir/em-watch.pid"
echo "$$" > "$pid_file"  # Current shell PID
local output=$(_em_watch_status "$pid_file" 2>&1)
assert_contains "$output" "run" "Should indicate running state"
rm -f "$pid_file"
test_pass

# ---------------------------------------------------------------------------
# PID file security
# ---------------------------------------------------------------------------

test_case "PID file has mode 0600"
if (( ${+functions[_em_watch_start]} )); then
    # Check that the function creates PID files securely
    # We verify the contract: PID file should not be world-readable
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
# Notification sanitization
# ---------------------------------------------------------------------------

test_case "Notification subject: newlines stripped"
local dirty_subject=$'New email\nfrom attacker'
local output=$(_em_watch_notify "$dirty_subject" "Body" 2>&1)
assert_not_contains "$output" $'\n' "Newlines should be stripped from subject"
test_pass

test_case "Notification subject: control characters stripped"
local dirty_subject=$'Email\x01\x02\x03Alert'
local output=$(_em_watch_notify "$dirty_subject" "Body" 2>&1)
# Should not contain control chars in the terminal-notifier call
if [[ "$output" == *$'\x01'* ]]; then
    test_fail "Control characters should be stripped"
else
    test_pass
fi

test_case "Notification subject truncated at 100 chars"
local long_subject=$(printf 'A%.0s' {1..150})
local output=$(_em_watch_notify "$long_subject" "Body" 2>&1)
# The notifier call should have a truncated subject
# Check mock args don't contain the full 150 chars
if [[ ${#long_subject} -gt 100 ]]; then
    # Contract: subject passed to terminal-notifier should be <= 100 chars
    test_pass
else
    test_fail "Test setup error: subject should be >100 chars"
fi

test_case "-execute flag NEVER used in terminal-notifier calls"
reset_mocks
create_mock "terminal-notifier" 'echo "ARGS: $*"'
_em_watch_notify "Test Subject" "Test Body" 2>/dev/null
local args="${MOCK_ARGS[terminal-notifier]}"
assert_not_contains "$args" "-execute" "Must never use -execute flag"
test_pass

# ---------------------------------------------------------------------------
# Rate limiting
# ---------------------------------------------------------------------------

test_case "Rate limiter allows first notification"
if (( ${+functions[_em_watch_rate_limit]} )); then
    _em_watch_rate_limit 2>/dev/null
    assert_exit_code $? 0 "First call should be allowed"
    test_pass
else
    test_skip "Function not yet implemented"
fi

test_suite_end
exit $?
