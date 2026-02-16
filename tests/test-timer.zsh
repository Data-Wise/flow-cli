#!/usr/bin/env zsh
# Test script for timer command (Pomodoro/focus timers)
# Tests: timer help, status, stop (non-blocking tests only)
# Generated: 2025-12-31
# Modernized: 2026-02-16 (shared test-framework.zsh)

# NOTE: Tests avoid running actual timers (which would sleep)
# Focus on command existence, help, status, and control functions

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find project root"
        exit 1
    fi
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || { echo "ERROR: Plugin failed to load"; exit 1 }
    exec < /dev/null
}

cleanup() {
    # Remove any timer state files created during tests
    if [[ -n "$FLOW_DATA_DIR" && -f "${FLOW_DATA_DIR}/timer.state" ]]; then
        rm -f "${FLOW_DATA_DIR}/timer.state"
    fi
}
trap cleanup EXIT

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_timer_exists() {
    test_case "timer command exists"
    assert_function_exists "timer" && test_pass
}

test_timer_help_exists() {
    test_case "_flow_timer_help function exists"
    assert_function_exists "_flow_timer_help" && test_pass
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_timer_focus_exists() {
    test_case "_flow_timer_focus function exists"
    assert_function_exists "_flow_timer_focus" && test_pass
}

test_timer_break_exists() {
    test_case "_flow_timer_break function exists"
    assert_function_exists "_flow_timer_break" && test_pass
}

test_timer_stop_exists() {
    test_case "_flow_timer_stop function exists"
    assert_function_exists "_flow_timer_stop" && test_pass
}

test_timer_status_exists() {
    test_case "_flow_timer_status function exists"
    assert_function_exists "_flow_timer_status" && test_pass
}

test_timer_pomodoro_exists() {
    test_case "_flow_timer_pomodoro function exists"
    assert_function_exists "_flow_timer_pomodoro" && test_pass
}

test_timer_progress_mini_exists() {
    test_case "_flow_timer_progress_mini function exists"
    assert_function_exists "_flow_timer_progress_mini" && test_pass
}

# ============================================================================
# TESTS: Help output
# ============================================================================

test_timer_help_runs() {
    test_case "timer help runs without error"
    local output=$(timer help 2>&1)
    assert_exit_code $? 0 "timer help should exit 0"
    assert_not_empty "$output" "timer help should produce output" && test_pass
}

test_timer_help_flag() {
    test_case "timer --help runs without error"
    local output=$(timer --help 2>&1)
    assert_exit_code $? 0 "timer --help should exit 0"
    assert_not_empty "$output" "timer --help should produce output" && test_pass
}

test_timer_h_flag() {
    test_case "timer -h runs without error"
    local output=$(timer -h 2>&1)
    assert_exit_code $? 0 "timer -h should exit 0"
    assert_not_empty "$output" "timer -h should produce output" && test_pass
}

test_timer_help_shows_commands() {
    test_case "timer help shows available subcommands"
    local output=$(timer help 2>&1)
    # Help should mention at least one of the core subcommands
    if [[ "$output" == *"start"* || "$output" == *"focus"* || "$output" == *"break"* || "$output" == *"pomodoro"* ]]; then
        test_pass
    else
        test_fail "Help should list timer subcommands (start/focus/break/pomodoro)"
    fi
}

test_timer_help_shows_examples() {
    test_case "timer help shows usage examples"
    local output=$(timer help 2>&1)
    assert_contains "$output" "timer" "Help should reference the timer command" && test_pass
}

# ============================================================================
# TESTS: Status command (non-blocking)
# ============================================================================

test_timer_status_runs() {
    test_case "timer status runs without error"
    local output=$(timer status 2>&1)
    assert_exit_code $? 0 "timer status should exit 0" && \
    assert_not_contains "$output" "command not found" && test_pass
}

test_timer_status_alias() {
    test_case "timer st (alias) runs without error"
    local output=$(timer st 2>&1)
    assert_exit_code $? 0 "timer st should exit 0" && \
    assert_not_contains "$output" "command not found" && test_pass
}

test_timer_default_shows_status() {
    test_case "timer (no args) shows status"
    local output=$(timer 2>&1)
    # Default action is status — should mention timer or indicate no active timer
    if [[ "$output" == *"timer"* || "$output" == *"No active"* ]]; then
        test_pass
    else
        test_fail "Default should show status (expected 'timer' or 'No active' in output)"
    fi
}

test_timer_status_no_timer() {
    test_case "timer status shows no active timer when none running"
    # Ensure no timer is running first
    timer stop 2>/dev/null
    local output=$(timer status 2>&1)
    if [[ "$output" == *"No active"* || "$output" == *"no"* ]]; then
        test_pass
    else
        test_fail "Should indicate no active timer"
    fi
}

# ============================================================================
# TESTS: Stop command (non-blocking)
# ============================================================================

test_timer_stop_runs() {
    test_case "timer stop runs without error"
    local output=$(timer stop 2>&1)
    assert_exit_code $? 0 "timer stop should exit 0" && \
    assert_not_contains "$output" "command not found" && test_pass
}

test_timer_stop_when_no_timer() {
    test_case "timer stop handles no active timer gracefully"
    # Ensure no timer is running
    timer stop 2>/dev/null
    local output=$(timer stop 2>&1)
    assert_exit_code $? 0 "timer stop should succeed even with no timer" && \
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: Data directory
# ============================================================================

test_flow_data_dir_defined() {
    test_case "FLOW_DATA_DIR variable is defined"
    assert_not_empty "$FLOW_DATA_DIR" "FLOW_DATA_DIR not defined" && test_pass
}

test_flow_data_dir_exists() {
    test_case "FLOW_DATA_DIR directory exists or can be created"
    if [[ -d "$FLOW_DATA_DIR" ]] || mkdir -p "$FLOW_DATA_DIR" 2>/dev/null; then
        test_pass
    else
        test_fail "Cannot access or create FLOW_DATA_DIR"
    fi
}

# ============================================================================
# TESTS: Timer state file management
# ============================================================================

test_timer_state_file_cleanup() {
    test_case "timer stop removes state file"
    # Create a dummy state file
    local timer_file="${FLOW_DATA_DIR}/timer.state"
    mkdir -p "$FLOW_DATA_DIR" 2>/dev/null
    echo "type=test" > "$timer_file"

    timer stop 2>/dev/null

    if [[ ! -f "$timer_file" ]]; then
        test_pass
    else
        rm -f "$timer_file"
        test_fail "State file should be removed after stop"
    fi
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_timer_help_no_errors() {
    test_case "timer help has no error patterns"
    local output=$(timer help 2>&1)
    assert_not_contains "$output" "command not found" "Help output should not contain 'command not found'"
    assert_not_contains "$output" "syntax error" "Help output should not contain 'syntax error'" && test_pass
}

test_timer_uses_emoji() {
    test_case "timer output uses emoji"
    local output=$(timer help 2>&1)
    if [[ "$output" == *"⏱️"* || "$output" == *"🍅"* || "$output" == *"☕"* || "$output" == *"🎯"* ]]; then
        test_pass
    else
        test_fail "Should use emoji for ADHD-friendly output"
    fi
}

# ============================================================================
# TESTS: Command parsing
# ============================================================================

test_timer_number_arg() {
    test_case "timer help mentions minutes/duration"
    local output=$(timer help 2>&1)
    assert_contains "$output" "25" "help should mention default duration" && test_pass
}

test_timer_invalid_command() {
    test_case "timer handles invalid subcommand"
    local output=$(timer invalidcmd123 2>&1)
    # Should show help or error message
    if [[ "$output" == *"help"* || "$output" == *"Usage"* || "$output" == *"timer"* ]]; then
        test_pass
    else
        test_fail "Should show help for invalid command"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite "Timer Command Tests"

    setup

    echo "${CYAN}--- Command existence tests ---${RESET}"
    test_timer_exists
    test_timer_help_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${RESET}"
    test_timer_focus_exists
    test_timer_break_exists
    test_timer_stop_exists
    test_timer_status_exists
    test_timer_pomodoro_exists
    test_timer_progress_mini_exists

    echo ""
    echo "${CYAN}--- Help output tests ---${RESET}"
    test_timer_help_runs
    test_timer_help_flag
    test_timer_h_flag
    test_timer_help_shows_commands
    test_timer_help_shows_examples

    echo ""
    echo "${CYAN}--- Status command tests ---${RESET}"
    test_timer_status_runs
    test_timer_status_alias
    test_timer_default_shows_status
    test_timer_status_no_timer

    echo ""
    echo "${CYAN}--- Stop command tests ---${RESET}"
    test_timer_stop_runs
    test_timer_stop_when_no_timer

    echo ""
    echo "${CYAN}--- Data directory tests ---${RESET}"
    test_flow_data_dir_defined
    test_flow_data_dir_exists

    echo ""
    echo "${CYAN}--- State management tests ---${RESET}"
    test_timer_state_file_cleanup

    echo ""
    echo "${CYAN}--- Output quality tests ---${RESET}"
    test_timer_help_no_errors
    test_timer_uses_emoji

    echo ""
    echo "${CYAN}--- Command parsing tests ---${RESET}"
    test_timer_number_arg
    test_timer_invalid_command

    cleanup
    test_suite_end
}

main "$@"
