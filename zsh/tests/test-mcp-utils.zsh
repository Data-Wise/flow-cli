#!/usr/bin/env zsh
# test-mcp-utils.zsh - Test MCP utilities
# Run with: zsh test-mcp-utils.zsh

# Colors for output
autoload -U colors && colors

# Source dependencies
SCRIPT_DIR="${0:A:h}"
FUNCTIONS_DIR="${SCRIPT_DIR}/../functions"

# Source core utilities (needed for print_ functions)
source "${FUNCTIONS_DIR}/core-utils.zsh"

# Source MCP utilities
source "${FUNCTIONS_DIR}/mcp-utils.zsh"

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

print_header "MCP Utilities Test Suite"

# Test 1: Check MCP_SERVERS_DIR variable is set
test_start "MCP_SERVERS_DIR variable"
if [[ -n "$MCP_SERVERS_DIR" ]]; then
    echo "  Value: $MCP_SERVERS_DIR"
    test_pass
else
    test_fail "MCP_SERVERS_DIR not set"
fi

# Test 2: Check function exists - mcp-list
test_start "mcp-list function exists"
if (( $+functions[mcp-list] )); then
    test_pass
else
    test_fail "mcp-list function not found"
fi

# Test 3: Check function exists - mcp-cd
test_start "mcp-cd function exists"
if (( $+functions[mcp-cd] )); then
    test_pass
else
    test_fail "mcp-cd function not found"
fi

# Test 4: Check function exists - mcp-edit
test_start "mcp-edit function exists"
if (( $+functions[mcp-edit] )); then
    test_pass
else
    test_fail "mcp-edit function not found"
fi

# Test 5: Check function exists - mcp-test
test_start "mcp-test function exists"
if (( $+functions[mcp-test] )); then
    test_pass
else
    test_fail "mcp-test function not found"
fi

# Test 6: Check function exists - mcp-status
test_start "mcp-status function exists"
if (( $+functions[mcp-status] )); then
    test_pass
else
    test_fail "mcp-status function not found"
fi

# Test 7: Check function exists - mcp-pick
test_start "mcp-pick function exists"
if (( $+functions[mcp-pick] )); then
    test_pass
else
    test_fail "mcp-pick function not found"
fi

# Test 8: Check function exists - mcp-help
test_start "mcp-help function exists"
if (( $+functions[mcp-help] )); then
    test_pass
else
    test_fail "mcp-help function not found"
fi

# Test 9: Check aliases are set
test_start "Aliases defined"
local aliases_ok=true
local missing_aliases=()

for alias_name in ml mc mcpl mcpc mcpe mcpt mcps mcpr mcpp mcph mcp; do
    if ! alias "$alias_name" &>/dev/null; then
        aliases_ok=false
        missing_aliases+=("$alias_name")
    fi
done

if $aliases_ok; then
    test_pass
else
    test_fail "Missing aliases: ${missing_aliases[*]}"
fi

# Test 10: Check MCP configs exist
test_start "MCP configuration files"
local configs_ok=true
local missing_configs=()

if [[ ! -f "$MCP_DESKTOP_CONFIG" ]]; then
    configs_ok=false
    missing_configs+=("Desktop/CLI")
fi

if [[ ! -f "$MCP_BROWSER_CONFIG" ]]; then
    configs_ok=false
    missing_configs+=("Browser")
fi

if $configs_ok; then
    test_pass
else
    test_fail "Missing configs: ${missing_configs[*]}"
fi

# Test 11: Test mcp-help output
test_start "mcp-help produces output"
local help_output=$(mcp-help 2>&1)
if [[ -n "$help_output" ]] && [[ "$help_output" == *"MCP Server Management"* ]]; then
    test_pass
else
    test_fail "mcp-help did not produce expected output"
fi

# Test 12: Test mcp-list with current structure (should fail gracefully if dir doesn't exist yet)
test_start "mcp-list handles missing directory"
if [[ ! -d "$MCP_SERVERS_DIR" ]]; then
    local list_output=$(mcp-list 2>&1)
    if [[ "$list_output" == *"not found"* ]]; then
        test_pass
    else
        test_fail "Expected error message for missing directory"
    fi
else
    echo "  Directory exists, testing normal operation..."
    local list_output=$(mcp-list 2>&1)
    if [[ -n "$list_output" ]]; then
        test_pass
    else
        test_fail "mcp-list produced no output"
    fi
fi

# === Summary ===

echo ""
print_header "Test Results"

echo "${fg[cyan]}Tests Run:${reset_color}    $TESTS_RUN"
echo "${fg[green]}Passed:${reset_color}       $TESTS_PASSED"
echo "${fg[red]}Failed:${reset_color}       $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_success "All tests passed! ✨"
    exit 0
else
    print_error "Some tests failed"
    exit 1
fi
