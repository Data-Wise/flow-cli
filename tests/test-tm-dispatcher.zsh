#!/usr/bin/env zsh
# Test script for tm dispatcher
# Tests: help, subcommand detection, shell-native commands

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    local project_root=""

    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/tm-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/tm-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/tm-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/tm-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source tm dispatcher
    source "$project_root/lib/dispatchers/tm-dispatcher.zsh"

    echo "  Loaded: tm-dispatcher.zsh"
    echo ""
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_tm_function_exists() {
    log_test "tm function is defined"

    if (( $+functions[tm] )); then
        pass
    else
        fail "tm function not defined"
    fi
}

test_tm_help_function_exists() {
    log_test "_tm_help function is defined"

    if (( $+functions[_tm_help] )); then
        pass
    else
        fail "_tm_help function not defined"
    fi
}

test_tm_detect_terminal_function_exists() {
    log_test "_tm_detect_terminal function is defined"

    if (( $+functions[_tm_detect_terminal] )); then
        pass
    else
        fail "_tm_detect_terminal function not defined"
    fi
}

test_tm_set_title_function_exists() {
    log_test "_tm_set_title function is defined"

    if (( $+functions[_tm_set_title] )); then
        pass
    else
        fail "_tm_set_title function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_tm_help() {
    log_test "tm help shows usage"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "Terminal Manager"; then
        pass
    else
        fail "Help header not found"
    fi
}

test_tm_help_h_flag() {
    log_test "tm -h works"

    local output=$(tm -h 2>&1)

    if echo "$output" | grep -q "Terminal Manager"; then
        pass
    else
        fail "-h flag not working"
    fi
}

test_tm_help_long_flag() {
    log_test "tm --help works"

    local output=$(tm --help 2>&1)

    if echo "$output" | grep -q "Terminal Manager"; then
        pass
    else
        fail "--help flag not working"
    fi
}

test_tm_no_args_shows_help() {
    log_test "tm with no args shows help"

    local output=$(tm 2>&1)

    if echo "$output" | grep -q "Terminal Manager"; then
        pass
    else
        fail "No args doesn't show help"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_title() {
    log_test "help shows title command"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "tm title"; then
        pass
    else
        fail "title not in help"
    fi
}

test_help_shows_profile() {
    log_test "help shows profile command"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "tm profile"; then
        pass
    else
        fail "profile not in help"
    fi
}

test_help_shows_ghost() {
    log_test "help shows ghost command"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "tm ghost"; then
        pass
    else
        fail "ghost not in help"
    fi
}

test_help_shows_switch() {
    log_test "help shows switch command"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "tm switch"; then
        pass
    else
        fail "switch not in help"
    fi
}

test_help_shows_detect() {
    log_test "help shows detect command"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "tm detect"; then
        pass
    else
        fail "detect not in help"
    fi
}

test_help_shows_shortcuts() {
    log_test "help shows shortcuts section"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "SHORTCUTS"; then
        pass
    else
        fail "shortcuts section not found"
    fi
}

test_help_shows_aliases() {
    log_test "help shows aliases section"

    local output=$(tm help 2>&1)

    if echo "$output" | grep -q "ALIASES"; then
        pass
    else
        fail "aliases section not found"
    fi
}

# ============================================================================
# TITLE COMMAND TESTS
# ============================================================================

test_title_no_args() {
    log_test "tm title with no args shows usage"

    local output=$(tm title 2>&1)

    if echo "$output" | grep -q "Usage: tm title"; then
        pass
    else
        fail "Usage message not shown"
    fi
}

# ============================================================================
# VAR COMMAND TESTS
# ============================================================================

test_var_no_args() {
    log_test "tm var with no args shows usage"

    local output=$(tm var 2>&1)

    if echo "$output" | grep -q "Usage: tm var"; then
        pass
    else
        fail "Usage message not shown"
    fi
}

test_var_one_arg() {
    log_test "tm var with one arg shows usage"

    local output=$(tm var key 2>&1)

    if echo "$output" | grep -q "Usage: tm var"; then
        pass
    else
        fail "Usage message not shown for incomplete args"
    fi
}

# ============================================================================
# WHICH COMMAND TESTS
# ============================================================================

test_which_returns_terminal() {
    log_test "tm which returns terminal name"

    local output=$(tm which 2>&1)

    # Should return one of the known terminal names
    if [[ "$output" =~ (iterm2|ghostty|terminal|vscode|kitty|alacritty|wezterm|unknown) ]]; then
        pass
    else
        fail "Unexpected terminal: $output"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  TM Dispatcher Tests                                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Function Existence Tests${NC}"
    echo "────────────────────────────────────────"
    test_tm_function_exists
    test_tm_help_function_exists
    test_tm_detect_terminal_function_exists
    test_tm_set_title_function_exists
    echo ""

    echo "${YELLOW}Help Tests${NC}"
    echo "────────────────────────────────────────"
    test_tm_help
    test_tm_help_h_flag
    test_tm_help_long_flag
    test_tm_no_args_shows_help
    echo ""

    echo "${YELLOW}Help Content Tests${NC}"
    echo "────────────────────────────────────────"
    test_help_shows_title
    test_help_shows_profile
    test_help_shows_ghost
    test_help_shows_switch
    test_help_shows_detect
    test_help_shows_shortcuts
    test_help_shows_aliases
    echo ""

    echo "${YELLOW}Title Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_title_no_args
    echo ""

    echo "${YELLOW}Var Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_var_no_args
    test_var_one_arg
    echo ""

    echo "${YELLOW}Which Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_which_returns_terminal
    echo ""

    echo "════════════════════════════════════════"
    echo "${CYAN}Summary${NC}"
    echo "────────────────────────────────────────"
    echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
