#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: CC Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate cc dispatcher functionality
# Tests: help, subcommand detection, keyword recognition, shortcuts, modes
#
# Test Categories:
#   1. Help Tests (3 tests)
#   2. Subcommand Documentation Tests (10 tests)
#   3. Shortcut Documentation Tests (4 tests)
#   4. Validation Tests (5 tests)
#   5. Function Existence Tests (4 tests)
#   6. Unified Grammar Tests - Mode Detection (4 tests)
#   7. Shortcut Expansion Tests (4 tests)
#   8. Explicit HERE Tests (2 tests)
#   9. Alias Tests (1 test)
#
# Created: 2026-02-16
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

setup() {
    # Get project root - try multiple methods (must be global for test functions)
    typeset -g project_root=""

    # Method 1: From script location
    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    # Method 2: Check if we're already in the project
    if [[ -z "$project_root" || ! -f "$project_root/commands/pick.zsh" ]]; then
        if [[ -f "$PWD/commands/pick.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/pick.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    # Method 3: Error if not found
    if [[ -z "$project_root" || ! -f "$project_root/commands/pick.zsh" ]]; then
        echo "ERROR: Cannot find project root - run from project directory"
        exit 1
    fi

    # Source pick first (cc depends on it)
    source "$project_root/commands/pick.zsh"

    # Source cc dispatcher
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

cleanup() {
    reset_mocks
}
trap cleanup EXIT

# ============================================================================
# HELP TESTS
# ============================================================================

test_cc_help() {
    test_case "cc help shows usage"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "Claude Code Dispatcher"; then
        test_pass
    else
        test_fail "Help header not found"
    fi
}

test_cc_help_flag() {
    test_case "cc --help works"

    local output=$(cc --help 2>&1)

    if echo "$output" | grep -q "Claude Code Dispatcher"; then
        test_pass
    else
        test_fail "--help flag not working"
    fi
}

test_cc_help_short_flag() {
    test_case "cc -h works"

    local output=$(cc -h 2>&1)

    if echo "$output" | grep -q "Claude Code Dispatcher"; then
        test_pass
    else
        test_fail "-h flag not working"
    fi
}

# ============================================================================
# SUBCOMMAND DOCUMENTATION TESTS
# ============================================================================

test_help_shows_yolo() {
    test_case "help shows yolo mode"

    local output=$(cc help 2>&1)
    assert_contains "$output" "yolo" || return
    test_pass
}

test_help_shows_plan() {
    test_case "help shows plan mode"

    local output=$(cc help 2>&1)
    assert_contains "$output" "plan" || return
    test_pass
}

test_help_shows_resume() {
    test_case "help shows resume"

    local output=$(cc help 2>&1)
    assert_contains "$output" "resume" || return
    test_pass
}

test_help_shows_continue() {
    test_case "help shows continue"

    local output=$(cc help 2>&1)
    assert_contains "$output" "continue" || return
    test_pass
}

test_help_shows_ask() {
    test_case "help shows ask"

    local output=$(cc help 2>&1)
    assert_contains "$output" "ask" || return
    test_pass
}

test_help_shows_file() {
    test_case "help shows file"

    local output=$(cc help 2>&1)
    assert_contains "$output" "file" || return
    test_pass
}

test_help_shows_diff() {
    test_case "help shows diff"

    local output=$(cc help 2>&1)
    assert_contains "$output" "diff" || return
    test_pass
}

test_help_shows_opus() {
    test_case "help shows opus"

    local output=$(cc help 2>&1)
    assert_contains "$output" "opus" || return
    test_pass
}

test_help_shows_haiku() {
    test_case "help shows haiku"

    local output=$(cc help 2>&1)
    assert_contains "$output" "haiku" || return
    test_pass
}

# REMOVED: test_help_shows_now - "cc now" was deprecated in v3.6.0
# The default behavior (cc with no args) now launches Claude in current dir

test_help_shows_direct_jump() {
    test_case "help shows direct jump"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -qi "direct jump"; then
        test_pass
    else
        test_fail "direct jump not in help"
    fi
}

# ============================================================================
# SHORTCUT DOCUMENTATION TESTS
# ============================================================================

test_help_shows_shortcuts() {
    test_case "help shows shortcuts section"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -qi "shortcut"; then
        test_pass
    else
        test_fail "shortcuts section not found"
    fi
}

test_shortcut_y_documented() {
    test_case "shortcut y = yolo documented"

    local output=$(cc help 2>&1)
    assert_contains "$output" "y=yolo" || return
    test_pass
}

test_shortcut_p_documented() {
    test_case "shortcut p = plan documented"

    local output=$(cc help 2>&1)
    assert_contains "$output" "p=plan" || return
    test_pass
}

test_shortcut_r_documented() {
    test_case "shortcut r = resume documented"

    local output=$(cc help 2>&1)
    assert_contains "$output" "r=resume" || return
    test_pass
}

# ============================================================================
# CC ASK VALIDATION TESTS
# ============================================================================

test_cc_ask_no_args() {
    test_case "cc ask with no args shows usage"

    local output=$(cc ask 2>&1)
    assert_contains "$output" "Usage: cc ask" || return
    assert_not_contains "$output" "command not found" || return
    test_pass
}

# ============================================================================
# CC FILE VALIDATION TESTS
# ============================================================================

test_cc_file_no_args() {
    test_case "cc file with no args shows usage"

    local output=$(cc file 2>&1)
    assert_contains "$output" "Usage: cc file" || return
    assert_not_contains "$output" "command not found" || return
    test_pass
}

test_cc_file_nonexistent() {
    test_case "cc file with nonexistent file shows error"

    local output=$(cc file /nonexistent/file.txt 2>&1)
    assert_contains "$output" "not found" || return
    assert_not_contains "$output" "command not found" || return
    test_pass
}

# ============================================================================
# CC DIFF VALIDATION TESTS
# ============================================================================

test_cc_diff_not_in_repo() {
    test_case "cc diff outside git repo shows error"

    # Run in /tmp which is not a git repo
    local output=$(cd /tmp && cc diff 2>&1)
    assert_contains "$output" "Not in a git repository" || return
    assert_not_contains "$output" "command not found" || return
    test_pass
}

# ============================================================================
# CC RPKG VALIDATION TESTS
# ============================================================================

test_cc_rpkg_not_in_package() {
    test_case "cc rpkg outside R package shows error"

    # Run in /tmp which has no DESCRIPTION file
    local output=$(cd /tmp && cc rpkg 2>&1)
    assert_contains "$output" "Not in an R package" || return
    assert_not_contains "$output" "command not found" || return
    test_pass
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_cc_function_exists() {
    test_case "cc function is defined"

    if (( $+functions[cc] )); then
        test_pass
    else
        test_fail "cc function not defined"
    fi
}

test_cc_help_function_exists() {
    test_case "_cc_help function is defined"

    if (( $+functions[_cc_help] )); then
        test_pass
    else
        test_fail "_cc_help function not defined"
    fi
}

test_cc_dispatch_with_mode_exists() {
    test_case "_cc_dispatch_with_mode function is defined"

    if (( $+functions[_cc_dispatch_with_mode] )); then
        test_pass
    else
        test_fail "_cc_dispatch_with_mode function not defined"
    fi
}

test_cc_worktree_exists() {
    test_case "_cc_worktree function is defined"

    if (( $+functions[_cc_worktree] )); then
        test_pass
    else
        test_fail "_cc_worktree function not defined"
    fi
}

# ============================================================================
# UNIFIED GRAMMAR TESTS (Mode-first vs Target-first)
# ============================================================================

test_mode_detection_yolo() {
    test_case "yolo detected as mode (not target)"

    # Mock the _cc_dispatch_with_mode to verify it's called
    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc yolo >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        test_pass
    else
        test_fail "yolo not detected as mode"
    fi

    # Restore original function
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_mode_detection_plan() {
    test_case "plan detected as mode (not target)"

    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc plan >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        test_pass
    else
        test_fail "plan not detected as mode"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_mode_detection_opus() {
    test_case "opus detected as mode (not target)"

    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc opus >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        test_pass
    else
        test_fail "opus not detected as mode"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_mode_detection_haiku() {
    test_case "haiku detected as mode (not target)"

    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc haiku >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        test_pass
    else
        test_fail "haiku not detected as mode"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

# ============================================================================
# SHORTCUT EXPANSION TESTS
# ============================================================================

test_shortcut_y_expands_to_yolo() {
    test_case "shortcut y expands to yolo"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc y >/dev/null 2>&1 || true

    # y should expand to yolo in the dispatcher
    if [[ "$mode_called" == "y" || "$mode_called" == "yolo" ]]; then
        test_pass
    else
        test_fail "y did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_shortcut_p_expands_to_plan() {
    test_case "shortcut p expands to plan"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc p >/dev/null 2>&1 || true

    if [[ "$mode_called" == "p" || "$mode_called" == "plan" ]]; then
        test_pass
    else
        test_fail "p did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_shortcut_o_expands_to_opus() {
    test_case "shortcut o expands to opus"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc o >/dev/null 2>&1 || true

    if [[ "$mode_called" == "o" || "$mode_called" == "opus" ]]; then
        test_pass
    else
        test_fail "o did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_shortcut_h_expands_to_haiku() {
    test_case "shortcut h expands to haiku"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc h >/dev/null 2>&1 || true

    if [[ "$mode_called" == "h" || "$mode_called" == "haiku" ]]; then
        test_pass
    else
        test_fail "h did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

# ============================================================================
# EXPLICIT HERE TESTS
# ============================================================================

test_explicit_here_dot() {
    test_case "cc . recognized as explicit HERE"

    # The . should be recognized as HERE target
    local output=$(cc . --help 2>&1 || echo "error")

    if [[ "$output" != "error" ]]; then
        assert_not_contains "$output" "command not found" || return
        test_pass
    else
        test_fail "cc . triggered error"
    fi
}

test_explicit_here_word() {
    test_case "cc here recognized as explicit HERE"

    local output=$(cc here --help 2>&1 || echo "error")

    if [[ "$output" != "error" ]]; then
        assert_not_contains "$output" "command not found" || return
        test_pass
    else
        test_fail "cc here triggered error"
    fi
}

# ============================================================================
# ALIAS TESTS
# ============================================================================

test_ccy_alias_exists() {
    test_case "ccy alias exists"

    if alias ccy >/dev/null 2>&1; then
        test_pass
    else
        test_fail "ccy alias not defined"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "CC Dispatcher Tests"

    setup

    echo "${YELLOW}Help Tests${RESET}"
    echo "────────────────────────────────────────"
    test_cc_help
    test_cc_help_flag
    test_cc_help_short_flag
    echo ""

    echo "${YELLOW}Subcommand Documentation Tests${RESET}"
    echo "────────────────────────────────────────"
    test_help_shows_yolo
    test_help_shows_plan
    test_help_shows_resume
    test_help_shows_continue
    test_help_shows_ask
    test_help_shows_file
    test_help_shows_diff
    test_help_shows_opus
    test_help_shows_haiku
    # test_help_shows_now - deprecated in v3.6.0
    test_help_shows_direct_jump
    echo ""

    echo "${YELLOW}Shortcut Documentation Tests${RESET}"
    echo "────────────────────────────────────────"
    test_help_shows_shortcuts
    test_shortcut_y_documented
    test_shortcut_p_documented
    test_shortcut_r_documented
    echo ""

    echo "${YELLOW}Validation Tests${RESET}"
    echo "────────────────────────────────────────"
    test_cc_ask_no_args
    test_cc_file_no_args
    test_cc_file_nonexistent
    test_cc_diff_not_in_repo
    test_cc_rpkg_not_in_package
    echo ""

    echo "${YELLOW}Function Existence Tests${RESET}"
    echo "────────────────────────────────────────"
    test_cc_function_exists
    test_cc_help_function_exists
    test_cc_dispatch_with_mode_exists
    test_cc_worktree_exists
    echo ""

    echo "${YELLOW}Unified Grammar Tests (Mode Detection)${RESET}"
    echo "────────────────────────────────────────"
    test_mode_detection_yolo
    test_mode_detection_plan
    test_mode_detection_opus
    test_mode_detection_haiku
    echo ""

    echo "${YELLOW}Shortcut Expansion Tests${RESET}"
    echo "────────────────────────────────────────"
    test_shortcut_y_expands_to_yolo
    test_shortcut_p_expands_to_plan
    test_shortcut_o_expands_to_opus
    test_shortcut_h_expands_to_haiku
    echo ""

    echo "${YELLOW}Explicit HERE Tests${RESET}"
    echo "────────────────────────────────────────"
    test_explicit_here_dot
    test_explicit_here_word
    echo ""

    echo "${YELLOW}Alias Tests${RESET}"
    echo "────────────────────────────────────────"
    test_ccy_alias_exists
    echo ""

    cleanup

    test_suite_end
    exit $?
}

main "$@"
