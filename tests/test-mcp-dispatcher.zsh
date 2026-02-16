#!/usr/bin/env zsh
# Test script for mcp dispatcher
# Tests: help, subcommand detection, error handling

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
    local project_root="$PROJECT_ROOT"

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/mcp-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/mcp-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/mcp-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/mcp-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${RESET}"
        exit 1
    fi

    # Source mcp dispatcher
    source "$project_root/lib/dispatchers/mcp-dispatcher.zsh"
}

cleanup() {
    reset_mocks
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_mcp_function_exists() {
    test_case "mcp function is defined"

    if (( $+functions[mcp] )); then
        test_pass
    else
        test_fail "mcp function not defined"
    fi
}

test_mcp_help_function_exists() {
    test_case "_mcp_help function is defined"

    if (( $+functions[_mcp_help] )); then
        test_pass
    else
        test_fail "_mcp_help function not defined"
    fi
}

test_mcp_list_function_exists() {
    test_case "_mcp_list function is defined"

    if (( $+functions[_mcp_list] )); then
        test_pass
    else
        test_fail "_mcp_list function not defined"
    fi
}

test_mcp_cd_function_exists() {
    test_case "_mcp_cd function is defined"

    if (( $+functions[_mcp_cd] )); then
        test_pass
    else
        test_fail "_mcp_cd function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_mcp_help() {
    test_case "mcp help shows usage"

    local output=$(mcp help 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "MCP Server Management"; then
        test_pass
    else
        test_fail "Help header not found"
    fi
}

test_mcp_help_h_flag() {
    test_case "mcp -h works"

    local output=$(mcp -h 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "MCP Server Management"; then
        test_pass
    else
        test_fail "-h flag not working"
    fi
}

test_mcp_help_long_flag() {
    test_case "mcp --help works"

    local output=$(mcp --help 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "MCP Server Management"; then
        test_pass
    else
        test_fail "--help flag not working"
    fi
}

test_mcp_help_h_shortcut() {
    test_case "mcp h works (shortcut)"

    local output=$(mcp h 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "MCP Server Management"; then
        test_pass
    else
        test_fail "h shortcut not working"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_list() {
    test_case "help shows list command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp list"; then
        test_pass
    else
        test_fail "list not in help"
    fi
}

test_help_shows_cd() {
    test_case "help shows cd command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp cd"; then
        test_pass
    else
        test_fail "cd not in help"
    fi
}

test_help_shows_test() {
    test_case "help shows test command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp test"; then
        test_pass
    else
        test_fail "test not in help"
    fi
}

test_help_shows_edit() {
    test_case "help shows edit command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp edit"; then
        test_pass
    else
        test_fail "edit not in help"
    fi
}

test_help_shows_status() {
    test_case "help shows status command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp status"; then
        test_pass
    else
        test_fail "status not in help"
    fi
}

test_help_shows_pick() {
    test_case "help shows pick command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp pick"; then
        test_pass
    else
        test_fail "pick not in help"
    fi
}

test_help_shows_shortcuts() {
    test_case "help shows short forms section"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "SHORT FORMS"; then
        test_pass
    else
        test_fail "short forms section not found"
    fi
}

test_help_shows_locations() {
    test_case "help shows locations section"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "LOCATIONS"; then
        test_pass
    else
        test_fail "locations section not found"
    fi
}

# ============================================================================
# UNKNOWN COMMAND TESTS
# ============================================================================

test_unknown_command() {
    test_case "mcp unknown-cmd shows error"

    local output=$(mcp unknown-xyz-command 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "unknown action"; then
        test_pass
    else
        test_fail "Unknown action error not shown"
    fi
}

test_unknown_command_suggests_help() {
    test_case "unknown command suggests mcp help"

    local output=$(mcp foobar 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "mcp help"; then
        test_pass
    else
        test_fail "Doesn't suggest mcp help"
    fi
}

# ============================================================================
# EDIT COMMAND VALIDATION TESTS
# ============================================================================

test_edit_no_args() {
    test_case "mcp edit with no args shows usage"

    local output=$(mcp edit 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "mcp edit"; then
        test_pass
    else
        test_fail "Usage message not shown"
    fi
}

test_edit_nonexistent() {
    test_case "mcp edit with nonexistent server shows error"

    local output=$(mcp edit nonexistent-server-xyz 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "server not found"; then
        test_pass
    else
        test_fail "Error message not shown for missing server"
    fi
}

# ============================================================================
# CD COMMAND TESTS
# ============================================================================

test_cd_nonexistent() {
    test_case "mcp cd with nonexistent server shows error"

    local output=$(mcp cd nonexistent-server-xyz 2>&1)

    assert_not_contains "$output" "command not found"
    if echo "$output" | grep -q "server not found"; then
        test_pass
    else
        test_fail "Error message not shown for missing server"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "MCP Dispatcher Tests"

    setup

    echo "${YELLOW}Function Existence Tests${RESET}"
    echo "────────────────────────────────────────"
    test_mcp_function_exists
    test_mcp_help_function_exists
    test_mcp_list_function_exists
    test_mcp_cd_function_exists
    echo ""

    echo "${YELLOW}Help Tests${RESET}"
    echo "────────────────────────────────────────"
    test_mcp_help
    test_mcp_help_h_flag
    test_mcp_help_long_flag
    test_mcp_help_h_shortcut
    echo ""

    echo "${YELLOW}Help Content Tests${RESET}"
    echo "────────────────────────────────────────"
    test_help_shows_list
    test_help_shows_cd
    test_help_shows_test
    test_help_shows_edit
    test_help_shows_status
    test_help_shows_pick
    test_help_shows_shortcuts
    test_help_shows_locations
    echo ""

    echo "${YELLOW}Unknown Command Tests${RESET}"
    echo "────────────────────────────────────────"
    test_unknown_command
    test_unknown_command_suggests_help
    echo ""

    echo "${YELLOW}Validation Tests${RESET}"
    echo "────────────────────────────────────────"
    test_edit_no_args
    test_edit_nonexistent
    test_cd_nonexistent
    echo ""

    cleanup

    test_suite_end
    exit $?
}

main "$@"
