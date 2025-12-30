#!/usr/bin/env zsh
# Test script for mcp dispatcher
# Tests: help, subcommand detection, error handling

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

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/mcp-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/mcp-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/mcp-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/mcp-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source mcp dispatcher
    source "$project_root/lib/dispatchers/mcp-dispatcher.zsh"

    echo "  Loaded: mcp-dispatcher.zsh"
    echo ""
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_mcp_function_exists() {
    log_test "mcp function is defined"

    if (( $+functions[mcp] )); then
        pass
    else
        fail "mcp function not defined"
    fi
}

test_mcp_help_function_exists() {
    log_test "_mcp_help function is defined"

    if (( $+functions[_mcp_help] )); then
        pass
    else
        fail "_mcp_help function not defined"
    fi
}

test_mcp_list_function_exists() {
    log_test "_mcp_list function is defined"

    if (( $+functions[_mcp_list] )); then
        pass
    else
        fail "_mcp_list function not defined"
    fi
}

test_mcp_cd_function_exists() {
    log_test "_mcp_cd function is defined"

    if (( $+functions[_mcp_cd] )); then
        pass
    else
        fail "_mcp_cd function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_mcp_help() {
    log_test "mcp help shows usage"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "MCP Server Management"; then
        pass
    else
        fail "Help header not found"
    fi
}

test_mcp_help_h_flag() {
    log_test "mcp -h works"

    local output=$(mcp -h 2>&1)

    if echo "$output" | grep -q "MCP Server Management"; then
        pass
    else
        fail "-h flag not working"
    fi
}

test_mcp_help_long_flag() {
    log_test "mcp --help works"

    local output=$(mcp --help 2>&1)

    if echo "$output" | grep -q "MCP Server Management"; then
        pass
    else
        fail "--help flag not working"
    fi
}

test_mcp_help_h_shortcut() {
    log_test "mcp h works (shortcut)"

    local output=$(mcp h 2>&1)

    if echo "$output" | grep -q "MCP Server Management"; then
        pass
    else
        fail "h shortcut not working"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_list() {
    log_test "help shows list command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp list"; then
        pass
    else
        fail "list not in help"
    fi
}

test_help_shows_cd() {
    log_test "help shows cd command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp cd"; then
        pass
    else
        fail "cd not in help"
    fi
}

test_help_shows_test() {
    log_test "help shows test command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp test"; then
        pass
    else
        fail "test not in help"
    fi
}

test_help_shows_edit() {
    log_test "help shows edit command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp edit"; then
        pass
    else
        fail "edit not in help"
    fi
}

test_help_shows_status() {
    log_test "help shows status command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp status"; then
        pass
    else
        fail "status not in help"
    fi
}

test_help_shows_pick() {
    log_test "help shows pick command"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "mcp pick"; then
        pass
    else
        fail "pick not in help"
    fi
}

test_help_shows_shortcuts() {
    log_test "help shows short forms section"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "SHORT FORMS"; then
        pass
    else
        fail "short forms section not found"
    fi
}

test_help_shows_locations() {
    log_test "help shows locations section"

    local output=$(mcp help 2>&1)

    if echo "$output" | grep -q "LOCATIONS"; then
        pass
    else
        fail "locations section not found"
    fi
}

# ============================================================================
# UNKNOWN COMMAND TESTS
# ============================================================================

test_unknown_command() {
    log_test "mcp unknown-cmd shows error"

    local output=$(mcp unknown-xyz-command 2>&1)

    if echo "$output" | grep -q "unknown action"; then
        pass
    else
        fail "Unknown action error not shown"
    fi
}

test_unknown_command_suggests_help() {
    log_test "unknown command suggests mcp help"

    local output=$(mcp foobar 2>&1)

    if echo "$output" | grep -q "mcp help"; then
        pass
    else
        fail "Doesn't suggest mcp help"
    fi
}

# ============================================================================
# EDIT COMMAND VALIDATION TESTS
# ============================================================================

test_edit_no_args() {
    log_test "mcp edit with no args shows usage"

    local output=$(mcp edit 2>&1)

    if echo "$output" | grep -q "mcp edit"; then
        pass
    else
        fail "Usage message not shown"
    fi
}

test_edit_nonexistent() {
    log_test "mcp edit with nonexistent server shows error"

    local output=$(mcp edit nonexistent-server-xyz 2>&1)

    if echo "$output" | grep -q "server not found"; then
        pass
    else
        fail "Error message not shown for missing server"
    fi
}

# ============================================================================
# CD COMMAND TESTS
# ============================================================================

test_cd_nonexistent() {
    log_test "mcp cd with nonexistent server shows error"

    local output=$(mcp cd nonexistent-server-xyz 2>&1)

    if echo "$output" | grep -q "server not found"; then
        pass
    else
        fail "Error message not shown for missing server"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  MCP Dispatcher Tests                                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Function Existence Tests${NC}"
    echo "────────────────────────────────────────"
    test_mcp_function_exists
    test_mcp_help_function_exists
    test_mcp_list_function_exists
    test_mcp_cd_function_exists
    echo ""

    echo "${YELLOW}Help Tests${NC}"
    echo "────────────────────────────────────────"
    test_mcp_help
    test_mcp_help_h_flag
    test_mcp_help_long_flag
    test_mcp_help_h_shortcut
    echo ""

    echo "${YELLOW}Help Content Tests${NC}"
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

    echo "${YELLOW}Unknown Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_unknown_command
    test_unknown_command_suggests_help
    echo ""

    echo "${YELLOW}Validation Tests${NC}"
    echo "────────────────────────────────────────"
    test_edit_no_args
    test_edit_nonexistent
    test_cd_nonexistent
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
