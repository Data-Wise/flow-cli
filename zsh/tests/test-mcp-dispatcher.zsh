#!/usr/bin/env zsh
# test-mcp-dispatcher.zsh - Test MCP dispatcher
# Run with: zsh test-mcp-dispatcher.zsh

# Colors for output
autoload -U colors && colors

# Source dependencies
SCRIPT_DIR="${0:A:h}"
FUNCTIONS_DIR="${SCRIPT_DIR}/../functions"

# Source core utilities if available (optional)
[[ -f "${FUNCTIONS_DIR}/core-utils.zsh" ]] && source "${FUNCTIONS_DIR}/core-utils.zsh"

# Source MCP dispatcher
source "${FUNCTIONS_DIR}/mcp-dispatcher.zsh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_start() {
    ((TESTS_RUN++))
    echo ""
    echo "${fg[cyan]}TEST $TESTS_RUN:${reset_color} $1"
}

test_pass() {
    ((TESTS_PASSED++))
    echo "${fg[green]}  ✓ PASS${reset_color}"
}

test_fail() {
    ((TESTS_FAILED++))
    echo "${fg[red]}  ✗ FAIL${reset_color}: $1"
}

# === Tests ===

echo ""
echo "${fg[bold]}╭─────────────────────────────────────────────╮${reset_color}"
echo "${fg[bold]}│ MCP Dispatcher Test Suite                  │${reset_color}"
echo "${fg[bold]}╰─────────────────────────────────────────────╯${reset_color}"

# Test 1: Check MCP_SERVERS_DIR variable is set
test_start "MCP_SERVERS_DIR variable"
if [[ -n "$MCP_SERVERS_DIR" ]]; then
    echo "  Value: $MCP_SERVERS_DIR"
    test_pass
else
    test_fail "MCP_SERVERS_DIR not set"
fi

# Test 2: Check main dispatcher exists
test_start "mcp() dispatcher function"
if (( $+functions[mcp] )); then
    test_pass
else
    test_fail "mcp() function not found"
fi

# Test 3: Check internal functions exist - _mcp_list
test_start "_mcp_list internal function"
if (( $+functions[_mcp_list] )); then
    test_pass
else
    test_fail "_mcp_list function not found"
fi

# Test 4: Check internal functions exist - _mcp_cd
test_start "_mcp_cd internal function"
if (( $+functions[_mcp_cd] )); then
    test_pass
else
    test_fail "_mcp_cd function not found"
fi

# Test 5: Check internal functions exist - _mcp_edit
test_start "_mcp_edit internal function"
if (( $+functions[_mcp_edit] )); then
    test_pass
else
    test_fail "_mcp_edit function not found"
fi

# Test 6: Check internal functions exist - _mcp_test
test_start "_mcp_test internal function"
if (( $+functions[_mcp_test] )); then
    test_pass
else
    test_fail "_mcp_test function not found"
fi

# Test 7: Check internal functions exist - _mcp_status
test_start "_mcp_status internal function"
if (( $+functions[_mcp_status] )); then
    test_pass
else
    test_fail "_mcp_status function not found"
fi

# Test 8: Check internal functions exist - _mcp_readme
test_start "_mcp_readme internal function"
if (( $+functions[_mcp_readme] )); then
    test_pass
else
    test_fail "_mcp_readme function not found"
fi

# Test 9: Check internal functions exist - _mcp_pick
test_start "_mcp_pick internal function"
if (( $+functions[_mcp_pick] )); then
    test_pass
else
    test_fail "_mcp_pick function not found"
fi

# Test 10: Check help function exists - _mcp_help
test_start "_mcp_help internal function"
if (( $+functions[_mcp_help] )); then
    test_pass
else
    test_fail "_mcp_help function not found"
fi

# Test 11: Check alias - mcpp
test_start "mcpp alias (mcp pick)"
if alias mcpp &>/dev/null; then
    local alias_value="$(alias mcpp)"
    if [[ "$alias_value" == *"mcp pick"* ]]; then
        test_pass
    else
        test_fail "mcpp alias points to wrong command: $alias_value"
    fi
else
    test_fail "mcpp alias not found"
fi

# Test 12: Old functions should NOT exist (migration complete)
test_start "Old mcp-* functions removed"
if (( $+functions[mcp-list] )); then
    test_fail "Old mcp-list function still exists (should be removed)"
elif (( $+functions[mcp-cd] )); then
    test_fail "Old mcp-cd function still exists (should be removed)"
elif (( $+functions[mcp-test] )); then
    test_fail "Old mcp-test function still exists (should be removed)"
else
    test_pass
fi

# === Results ===

echo ""
echo ""
echo "${fg[bold]}╭─────────────────────────────────────────────╮${reset_color}"
echo "${fg[bold]}│ Test Results                                │${reset_color}"
echo "${fg[bold]}╰─────────────────────────────────────────────╯${reset_color}"
echo ""
echo "  Total:  $TESTS_RUN"
echo "  ${fg[green]}Passed: $TESTS_PASSED${reset_color}"
echo "  ${fg[red]}Failed: $TESTS_FAILED${reset_color}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${fg[green]}${fg[bold]}✓ ALL TESTS PASSED${reset_color}"
    echo ""
    exit 0
else
    echo "${fg[red]}${fg[bold]}✗ SOME TESTS FAILED${reset_color}"
    echo ""
    exit 1
fi
