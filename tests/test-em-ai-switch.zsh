#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Email AI Backend Switching
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate _em_ai_switch, _em_ai_toggle, _em_ai_status, _em_ai_cmd
# Tests: backend validation, live env mutation, toggle cycling, status output
#
# Created: 2026-02-18
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP / CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

# Save the real _em_ai_available body for restoration
typeset -g _SAVED_AI_AVAILABLE_BODY=""

setup() {
    typeset -g project_root=""
    if [[ -n "${0:A}" ]]; then project_root="${0:A:h:h}"; fi
    if [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]]; then
        if [[ -f "$PWD/flow.plugin.zsh" ]]; then project_root="$PWD"
        elif [[ -f "$PWD/../flow.plugin.zsh" ]]; then project_root="$PWD/.."
        fi
    fi
    [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]] && { echo "ERROR: Cannot find project root"; exit 1; }

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$project_root"
    exec < /dev/null  # Non-interactive
    source "$project_root/flow.plugin.zsh"

    # Save the real _em_ai_available for manual restoration
    _SAVED_AI_AVAILABLE_BODY="$(whence -f _em_ai_available)"
}

_restore_ai_available() {
    if [[ -n "$_SAVED_AI_AVAILABLE_BODY" ]]; then
        eval "$_SAVED_AI_AVAILABLE_BODY"
    fi
}

cleanup() {
    reset_mocks
    _restore_ai_available
    unset FLOW_EMAIL_AI
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: _em_ai_switch Valid Backends
# ═══════════════════════════════════════════════════════════════

test_ai_switch_claude() {
    test_case "_em_ai_switch claude succeeds"
    _em_ai_switch "claude" &>/dev/null
    if [[ $? -eq 0 && "$FLOW_EMAIL_AI" == "claude" ]]; then
        test_pass
    else
        test_fail "Expected FLOW_EMAIL_AI=claude, got '$FLOW_EMAIL_AI'"
    fi
}

test_ai_switch_gemini() {
    test_case "_em_ai_switch gemini succeeds"
    _em_ai_switch "gemini" &>/dev/null
    if [[ $? -eq 0 && "$FLOW_EMAIL_AI" == "gemini" ]]; then
        test_pass
    else
        test_fail "Expected FLOW_EMAIL_AI=gemini, got '$FLOW_EMAIL_AI'"
    fi
}

test_ai_switch_none() {
    test_case "_em_ai_switch none succeeds"
    _em_ai_switch "none" &>/dev/null
    if [[ $? -eq 0 && "$FLOW_EMAIL_AI" == "none" ]]; then
        test_pass
    else
        test_fail "Expected FLOW_EMAIL_AI=none, got '$FLOW_EMAIL_AI'"
    fi
}

test_ai_switch_auto() {
    test_case "_em_ai_switch auto succeeds"
    _em_ai_switch "auto" &>/dev/null
    if [[ $? -eq 0 && "$FLOW_EMAIL_AI" == "auto" ]]; then
        test_pass
    else
        test_fail "Expected FLOW_EMAIL_AI=auto, got '$FLOW_EMAIL_AI'"
    fi
}

test_ai_switch_updates_backends_default() {
    test_case "_em_ai_switch updates _EM_AI_BACKENDS[default]"
    _em_ai_switch "gemini" &>/dev/null
    if [[ "${_EM_AI_BACKENDS[default]}" == "gemini" ]]; then
        test_pass
    else
        test_fail "Expected _EM_AI_BACKENDS[default]=gemini, got '${_EM_AI_BACKENDS[default]}'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: _em_ai_switch Invalid Backend
# ═══════════════════════════════════════════════════════════════

test_ai_switch_invalid_returns_1() {
    test_case "_em_ai_switch nonexistent returns 1"
    local output
    output=$(_em_ai_switch "nonexistent" 2>&1)
    if [[ $? -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit code 1 for invalid backend"
    fi
}

test_ai_switch_invalid_shows_available() {
    test_case "_em_ai_switch invalid shows available backends"
    local output
    output=$(_em_ai_switch "nonexistent" 2>&1)
    if [[ "$output" == *"Available:"* || "$output" == *"Valid:"* ]]; then
        test_pass
    else
        test_fail "Expected error output with available backends, got: $output"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 3: _em_ai_toggle Cycles Backends
# ═══════════════════════════════════════════════════════════════

test_ai_toggle_cycles() {
    test_case "_em_ai_toggle cycles through available backends"

    # Override _em_ai_available directly (avoids create_mock eval issues)
    _em_ai_available() { echo "claude gemini"; }

    # Start from claude
    export FLOW_EMAIL_AI="claude"
    _em_ai_toggle &>/dev/null

    if [[ "$FLOW_EMAIL_AI" == "gemini" ]]; then
        test_pass
    else
        test_fail "Expected toggle from claude -> gemini, got '$FLOW_EMAIL_AI'"
    fi

    _restore_ai_available
}

test_ai_toggle_wraps_around() {
    test_case "_em_ai_toggle wraps from last to first"

    # Override _em_ai_available directly
    _em_ai_available() { echo "claude gemini"; }

    # Start from gemini (should wrap to claude)
    export FLOW_EMAIL_AI="gemini"
    _em_ai_toggle &>/dev/null

    if [[ "$FLOW_EMAIL_AI" == "claude" ]]; then
        test_pass
    else
        test_fail "Expected toggle from gemini -> claude, got '$FLOW_EMAIL_AI'"
    fi

    _restore_ai_available
}

test_ai_toggle_no_backends() {
    test_case "_em_ai_toggle with no backends returns 1"

    # Override _em_ai_available to return empty
    _em_ai_available() { echo ""; }

    local output
    output=$(_em_ai_toggle 2>&1)
    if [[ $? -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit 1 when no backends available"
    fi

    _restore_ai_available
}

# ═══════════════════════════════════════════════════════════════
# Section 4: _em_ai_status Output
# ═══════════════════════════════════════════════════════════════

test_ai_status_shows_current() {
    test_case "_em_ai_status output contains Current:"
    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_ai_status 2>&1)
    if [[ "$output" == *"Current:"* ]]; then
        test_pass
    else
        test_fail "Status output missing 'Current:'"
    fi
}

test_ai_status_shows_available() {
    test_case "_em_ai_status output contains Available:"
    local output
    output=$(_em_ai_status 2>&1)
    if [[ "$output" == *"Available:"* ]]; then
        test_pass
    else
        test_fail "Status output missing 'Available:'"
    fi
}

test_ai_status_shows_timeout() {
    test_case "_em_ai_status output contains Timeout:"
    local output
    output=$(_em_ai_status 2>&1)
    if [[ "$output" == *"Timeout:"* ]]; then
        test_pass
    else
        test_fail "Status output missing 'Timeout:'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 5: _em_ai_cmd Routing
# ═══════════════════════════════════════════════════════════════

test_ai_cmd_empty_calls_status() {
    test_case "_em_ai_cmd with no arg calls status"
    create_mock "_em_ai_status" 'echo "STATUS_CALLED"'
    local output
    output=$(_em_ai_cmd 2>&1)
    if [[ "$output" == *"STATUS_CALLED"* ]]; then
        test_pass
    else
        test_fail "Expected status to be called, got: $output"
    fi
    reset_mocks
}

test_ai_cmd_toggle_calls_toggle() {
    test_case "_em_ai_cmd toggle calls toggle"
    create_mock "_em_ai_toggle" 'echo "TOGGLE_CALLED"'
    local output
    output=$(_em_ai_cmd "toggle" 2>&1)
    if [[ "$output" == *"TOGGLE_CALLED"* ]]; then
        test_pass
    else
        test_fail "Expected toggle to be called, got: $output"
    fi
    reset_mocks
}

test_ai_cmd_backend_name_calls_switch() {
    test_case "_em_ai_cmd with backend name calls switch"
    create_mock "_em_ai_switch" 'echo "SWITCH_CALLED $1"'
    local output
    output=$(_em_ai_cmd "gemini" 2>&1)
    if [[ "$output" == *"SWITCH_CALLED gemini"* ]]; then
        test_pass
    else
        test_fail "Expected switch called with gemini, got: $output"
    fi
    reset_mocks
}

test_ai_cmd_auto_calls_switch() {
    test_case "_em_ai_cmd auto calls switch with auto"
    create_mock "_em_ai_switch" 'echo "SWITCH_CALLED $1"'
    local output
    output=$(_em_ai_cmd "auto" 2>&1)
    if [[ "$output" == *"SWITCH_CALLED auto"* ]]; then
        test_pass
    else
        test_fail "Expected switch called with auto, got: $output"
    fi
    reset_mocks
}

# ═══════════════════════════════════════════════════════════════
# Section 6: _em_ai_backend_for_op Reads Live Env
# ═══════════════════════════════════════════════════════════════

test_backend_for_op_reads_env() {
    test_case "_em_ai_backend_for_op reads live FLOW_EMAIL_AI"
    export FLOW_EMAIL_AI="gemini"
    local result
    result=$(_em_ai_backend_for_op "summarize")
    if [[ "$result" == "gemini" ]]; then
        test_pass
    else
        test_fail "Expected 'gemini', got '$result'"
    fi
}

test_backend_for_op_defaults_to_claude() {
    test_case "_em_ai_backend_for_op defaults to claude"
    unset FLOW_EMAIL_AI
    # Reset the associative array default too
    _EM_AI_BACKENDS[default]="claude"
    local result
    result=$(_em_ai_backend_for_op "classify")
    if [[ "$result" == "claude" ]]; then
        test_pass
    else
        test_fail "Expected 'claude' default, got '$result'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 7: extra_args in _EM_AI_BACKENDS
# ═══════════════════════════════════════════════════════════════

test_backends_has_gemini_extra_args() {
    test_case "_EM_AI_BACKENDS has gemini_extra_args key"
    if [[ -n "${_EM_AI_BACKENDS[gemini_extra_args]+set}" ]]; then
        test_pass
    else
        test_fail "gemini_extra_args key missing from _EM_AI_BACKENDS"
    fi
}

test_backends_has_claude_extra_args() {
    test_case "_EM_AI_BACKENDS has claude_extra_args key"
    if [[ -n "${_EM_AI_BACKENDS[claude_extra_args]+set}" ]]; then
        test_pass
    else
        test_fail "claude_extra_args key missing from _EM_AI_BACKENDS"
    fi
}

test_gemini_extra_args_default() {
    test_case "gemini_extra_args defaults to '-e none'"
    local gemini_args="${_EM_AI_BACKENDS[gemini_extra_args]}"
    if [[ "$gemini_args" == *"-e none"* ]]; then
        test_pass
    else
        test_fail "Expected gemini_extra_args to contain '-e none', got '$gemini_args'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "Email AI Backend Switching"

    setup

    echo "${CYAN}Section 1: _em_ai_switch Valid Backends${RESET}"
    test_ai_switch_claude
    test_ai_switch_gemini
    test_ai_switch_none
    test_ai_switch_auto
    test_ai_switch_updates_backends_default
    echo ""

    echo "${CYAN}Section 2: _em_ai_switch Invalid Backend${RESET}"
    test_ai_switch_invalid_returns_1
    test_ai_switch_invalid_shows_available
    echo ""

    echo "${CYAN}Section 3: _em_ai_toggle Cycles Backends${RESET}"
    test_ai_toggle_cycles
    test_ai_toggle_wraps_around
    test_ai_toggle_no_backends
    echo ""

    echo "${CYAN}Section 4: _em_ai_status Output${RESET}"
    test_ai_status_shows_current
    test_ai_status_shows_available
    test_ai_status_shows_timeout
    echo ""

    echo "${CYAN}Section 5: _em_ai_cmd Routing${RESET}"
    test_ai_cmd_empty_calls_status
    test_ai_cmd_toggle_calls_toggle
    test_ai_cmd_backend_name_calls_switch
    test_ai_cmd_auto_calls_switch
    echo ""

    echo "${CYAN}Section 6: _em_ai_backend_for_op Reads Live Env${RESET}"
    test_backend_for_op_reads_env
    test_backend_for_op_defaults_to_claude
    echo ""

    echo "${CYAN}Section 7: extra_args in _EM_AI_BACKENDS${RESET}"
    test_backends_has_gemini_extra_args
    test_backends_has_claude_extra_args
    test_gemini_extra_args_default
    echo ""

    cleanup
    test_suite_end
    exit $?
}

# Run tests
main
