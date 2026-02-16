#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: TM Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Tests for tm dispatcher — help, subcommand detection, shell-native commands
#
# Test Categories:
#   1. Function Existence (4 tests)
#   2. Help Tests (4 tests)
#   3. Help Content Tests (7 tests)
#   4. Title Command Tests (1 test)
#   5. Var Command Tests (2 tests)
#   6. Which Command Tests (1 test)
#
# Created: 2026-01-23
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/dispatchers/tm-dispatcher.zsh" ]]; then
    if [[ -f "$PWD/lib/dispatchers/tm-dispatcher.zsh" ]]; then
        PROJECT_ROOT="$PWD"
    elif [[ -f "$PWD/../lib/dispatchers/tm-dispatcher.zsh" ]]; then
        PROJECT_ROOT="$PWD/.."
    fi
fi

if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/dispatchers/tm-dispatcher.zsh" ]]; then
    echo "ERROR: Cannot find project root — run from project directory"
    exit 1
fi

# Source dependencies
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null
source "$PROJECT_ROOT/lib/dispatchers/tm-dispatcher.zsh"

# ══════════════════════════════════════════════════════════════════════════════
# 1. FUNCTION EXISTENCE TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_tm_function_exists() {
    test_case "tm function is defined"
    assert_function_exists tm && test_pass
}

test_tm_help_function_exists() {
    test_case "_tm_help function is defined"
    assert_function_exists _tm_help && test_pass
}

test_tm_detect_terminal_function_exists() {
    test_case "_tm_detect_terminal function is defined"
    assert_function_exists _tm_detect_terminal && test_pass
}

test_tm_set_title_function_exists() {
    test_case "_tm_set_title function is defined"
    assert_function_exists _tm_set_title && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# 2. HELP TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_tm_help() {
    test_case "tm help shows usage"
    local output=$(tm help 2>&1)
    assert_contains "$output" "Terminal Manager" && test_pass
}

test_tm_help_h_flag() {
    test_case "tm -h works"
    local output=$(tm -h 2>&1)
    assert_contains "$output" "Terminal Manager" && test_pass
}

test_tm_help_long_flag() {
    test_case "tm --help works"
    local output=$(tm --help 2>&1)
    assert_contains "$output" "Terminal Manager" && test_pass
}

test_tm_no_args_shows_help() {
    test_case "tm with no args shows help"
    local output=$(tm 2>&1)
    assert_contains "$output" "Terminal Manager" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# 3. HELP CONTENT TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_help_shows_title() {
    test_case "help shows title command"
    local output=$(tm help 2>&1)
    assert_contains "$output" "tm title" && test_pass
}

test_help_shows_profile() {
    test_case "help shows profile command"
    local output=$(tm help 2>&1)
    assert_contains "$output" "tm profile" && test_pass
}

test_help_shows_ghost() {
    test_case "help shows ghost command"
    local output=$(tm help 2>&1)
    assert_contains "$output" "tm ghost" && test_pass
}

test_help_shows_switch() {
    test_case "help shows switch command"
    local output=$(tm help 2>&1)
    assert_contains "$output" "tm switch" && test_pass
}

test_help_shows_detect() {
    test_case "help shows detect command"
    local output=$(tm help 2>&1)
    assert_contains "$output" "tm detect" && test_pass
}

test_help_shows_shortcuts() {
    test_case "help shows shortcuts section"
    local output=$(tm help 2>&1)
    assert_contains "$output" "Shortcuts:" && test_pass
}

test_help_shows_aliases() {
    test_case "help shows aliases section"
    local output=$(tm help 2>&1)
    assert_contains "$output" "Aliases:" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# 4. TITLE COMMAND TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_title_no_args() {
    test_case "tm title with no args shows usage"
    local output=$(tm title 2>&1)
    assert_contains "$output" "Usage: tm title" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# 5. VAR COMMAND TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_var_no_args() {
    test_case "tm var with no args shows usage"
    local output=$(tm var 2>&1)
    assert_contains "$output" "Usage: tm var" && test_pass
}

test_var_one_arg() {
    test_case "tm var with one arg shows usage"
    local output=$(tm var key 2>&1)
    assert_contains "$output" "Usage: tm var" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# 6. WHICH COMMAND TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_which_returns_terminal() {
    test_case "tm which returns terminal name"
    local output=$(tm which 2>&1)
    assert_matches_pattern "$output" "(iterm2|ghostty|terminal|vscode|kitty|alacritty|wezterm|unknown)" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    test_suite_start "TM Dispatcher Tests"

    test_suite "Function Existence Tests"
    test_tm_function_exists
    test_tm_help_function_exists
    test_tm_detect_terminal_function_exists
    test_tm_set_title_function_exists

    test_suite "Help Tests"
    test_tm_help
    test_tm_help_h_flag
    test_tm_help_long_flag
    test_tm_no_args_shows_help

    test_suite "Help Content Tests"
    test_help_shows_title
    test_help_shows_profile
    test_help_shows_ghost
    test_help_shows_switch
    test_help_shows_detect
    test_help_shows_shortcuts
    test_help_shows_aliases

    test_suite "Title Command Tests"
    test_title_no_args

    test_suite "Var Command Tests"
    test_var_no_args
    test_var_one_arg

    test_suite "Which Command Tests"
    test_which_returns_terminal

    test_suite_end
    exit $?
}

main "$@"
