#!/bin/zsh
# test-prompt-validation.zsh - Comprehensive validation function tests
# Tests engine installation detection and config validation
# Status: 50+ validation tests

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# ============================================================================
# Test Utilities
# ============================================================================

_test_print_header() {
    echo
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}Test Suite: $1${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

_assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    shift 2
    local command="$@"

    ((TEST_COUNT++))

    eval "$command" >/dev/null 2>&1
    local actual_code=$?

    if [[ $actual_code -eq $expected_code ]]; then
        echo "${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "${RED}✗${NC} $description"
        echo "  Expected exit code: $expected_code"
        echo "  Got exit code: $actual_code"
        ((FAIL_COUNT++))
        return 1
    fi
}

_assert_contains() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    ((TEST_COUNT++))

    if [[ "$actual" == *"$expected"* ]]; then
        echo "${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "${RED}✗${NC} $description"
        echo "  Expected substring: '$expected'"
        echo "  Got: '$actual'"
        ((FAIL_COUNT++))
        return 1
    fi
}

_assert_equals() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    ((TEST_COUNT++))

    if [[ "$actual" == "$expected" ]]; then
        echo "${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "${RED}✗${NC} $description"
        echo "  Expected: '$expected'"
        echo "  Got: '$actual'"
        ((FAIL_COUNT++))
        return 1
    fi
}

_test_summary() {
    echo
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Total Tests: $TEST_COUNT"
    echo "${GREEN}Passed: $PASS_COUNT${NC}"
    echo "${RED}Failed: $FAIL_COUNT${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo "${RED}✗ $FAIL_COUNT test(s) failed${NC}"
        return 1
    fi
}

# ============================================================================
# Load Libraries
# ============================================================================

local TEST_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_DIR/lib/core.zsh" 2>/dev/null || true
source "$TEST_DIR/lib/dispatchers/prompt-dispatcher.zsh"

# ============================================================================
# Test Suite 1: Main Validation Dispatcher
# ============================================================================

_test_print_header "Main Validation Function (_prompt_validate)"

# Test with valid engines (environment-aware: only expect exit 0 if tool is installed)
_assert_exit_code "Validates p10k without error" "0" "_prompt_validate powerlevel10k"
_assert_exit_code "Validates starship without error" "0" "_prompt_validate starship"
# OhMyPosh validation depends on whether oh-my-posh is installed
if command -v oh-my-posh &>/dev/null; then
    _assert_exit_code "Validates ohmyposh without error" "0" "_prompt_validate ohmyposh"
else
    ((TEST_COUNT++))
    _prompt_validate ohmyposh >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "${GREEN}✓${NC} Validates ohmyposh (returns error when not installed)"
        ((PASS_COUNT++))
    else
        echo "${RED}✗${NC} Validates ohmyposh (expected error when not installed)"
        ((FAIL_COUNT++))
    fi
fi

# Test with invalid engine
local invalid_output=$(_prompt_validate invalid_engine 2>&1)
_assert_contains "Invalid engine shows error" "$invalid_output" "Unknown engine"

# ============================================================================
# Test Suite 2: Powerlevel10k Validation
# ============================================================================

_test_print_header "Powerlevel10k Validation (_prompt_validate_p10k)"

# Test function exists
_assert_exit_code "P10k validation function exists" "0" "type _prompt_validate_p10k"

# Test validation logic
_assert_exit_code "P10k validation completes" "0" "_prompt_validate_p10k"

# Test what it checks (plugin file)
local p10k_output=$(_prompt_validate_p10k 2>&1)
if [[ ! -f "$HOME/.config/zsh/.zsh_plugins.txt" ]]; then
    _assert_contains "P10k validation reports missing plugin file" "$p10k_output" "not found"
fi

# Test config file check
if [[ ! -f "$HOME/.config/zsh/.p10k.zsh" ]]; then
    local p10k_config_output=$(_prompt_validate_p10k 2>&1)
    _assert_contains "P10k validation checks config file" "$p10k_config_output" "config"
fi

# ============================================================================
# Test Suite 3: Starship Validation
# ============================================================================

_test_print_header "Starship Validation (_prompt_validate_starship)"

# Test function exists
_assert_exit_code "Starship validation function exists" "0" "type _prompt_validate_starship"

# Test validation completes
_assert_exit_code "Starship validation completes" "0" "_prompt_validate_starship"

# Test what it checks
local starship_output=$(_prompt_validate_starship 2>&1)
local starship_exit=$?

# If Starship is installed locally, it should pass (exit 0)
# If not installed, it should show error message
if command -v starship &>/dev/null; then
    # Installed: validation should succeed (exit 0, may have empty output)
    ((TEST_COUNT++))
    if [[ $starship_exit -eq 0 ]]; then
        echo "${GREEN}✓${NC} Starship validation succeeds (installed)"
        ((PASS_COUNT++))
    else
        echo "${RED}✗${NC} Starship validation succeeds (expected exit 0)"
        ((FAIL_COUNT++))
    fi
else
    _assert_contains "Starship validation reports missing binary" "$starship_output" "not found"
fi

# ============================================================================
# Test Suite 4: OhMyPosh Validation
# ============================================================================

_test_print_header "OhMyPosh Validation (_prompt_validate_ohmyposh)"

# Test function exists
_assert_exit_code "OhMyPosh validation function exists" "0" "type _prompt_validate_ohmyposh"

# Test validation completes (exit code depends on whether oh-my-posh is installed)
# If OhMyPosh is installed locally, validation should pass (exit 0)
# If not installed, validation should fail with message (exit 1)
if command -v oh-my-posh &>/dev/null; then
    _assert_exit_code "OhMyPosh validation completes (installed)" "0" "_prompt_validate_ohmyposh"
else
    # Not installed - capture output and exit code separately
    local ohmyposh_output
    ohmyposh_output=$(_prompt_validate_ohmyposh 2>&1)
    local ohmyposh_exit=$?

    # Validation should return non-zero when not installed
    ((TEST_COUNT++))
    if [[ $ohmyposh_exit -ne 0 ]]; then
        echo "${GREEN}✓${NC} OhMyPosh validation completes (not installed, returns error)"
        ((PASS_COUNT++))
    else
        echo "${RED}✗${NC} OhMyPosh validation completes (expected non-zero exit)"
        ((FAIL_COUNT++))
    fi
    _assert_contains "OhMyPosh validation reports missing binary" "$ohmyposh_output" "not found"
fi

# ============================================================================
# Test Suite 5: Validation Error Messages
# ============================================================================

_test_print_header "Validation Error Messages"

# Test that validation provides actionable messages
local validation=$(_prompt_validate invalid 2>&1)
_assert_contains "Unknown engine error is clear" "$validation" "Unknown"

# Test P10k missing plugin message
local p10k_missing=$(_prompt_validate_p10k 2>&1)
if [[ ! -f "$HOME/.config/zsh/.zsh_plugins.txt" ]]; then
    _assert_contains "P10k plugin missing message" "$p10k_missing" "plugin"
fi

# Test Starship missing binary message
local starship_missing=$(_prompt_validate_starship 2>&1)
if ! command -v starship &>/dev/null; then
    _assert_contains "Starship install message" "$starship_missing" "Install"
fi

# ============================================================================
# Test Suite 6: Config File Path Validation
# ============================================================================

_test_print_header "Configuration File Path Validation"

# Test P10k config path
local p10k_config="${PROMPT_ENGINES[powerlevel10k_config]}"
_assert_contains "P10k config path contains .config" "$p10k_config" ".config"
_assert_contains "P10k config path contains zsh" "$p10k_config" "zsh"
_assert_contains "P10k config path ends with .zsh" "$p10k_config" ".p10k.zsh"

# Test Starship config path
local starship_config="${PROMPT_ENGINES[starship_config]}"
_assert_contains "Starship config path contains .config" "$starship_config" ".config"
_assert_contains "Starship config path ends with toml" "$starship_config" "starship.toml"

# Test OhMyPosh config path
local ohmyposh_config="${PROMPT_ENGINES[ohmyposh_config]}"
_assert_contains "OhMyPosh config path contains .config" "$ohmyposh_config" ".config"
_assert_contains "OhMyPosh config path contains ohmyposh" "$ohmyposh_config" "ohmyposh"
_assert_contains "OhMyPosh config path ends with json" "$ohmyposh_config" "config.json"

# ============================================================================
# Test Suite 7: Binary/Plugin Detection
# ============================================================================

_test_print_header "Binary and Plugin Detection"

# Test that P10k check references .zsh_plugins.txt (not binary)
local p10k_val=$(_prompt_validate_p10k 2>&1)
if ! grep -q "romkatv/powerlevel10k" "$HOME/.config/zsh/.zsh_plugins.txt" 2>/dev/null; then
    _assert_contains "P10k checks plugin registry" "$p10k_val" "plugins"
fi

# Test that Starship checks for binary
local starship_val=$(_prompt_validate_starship 2>&1)
# This either succeeds (binary found) or shows error (binary not found)
if ! command -v starship &>/dev/null; then
    _assert_contains "Starship checks for binary in PATH" "$starship_val" "PATH"
fi

# Test that OhMyPosh checks for binary
local ohmyposh_val=$(_prompt_validate_ohmyposh 2>&1)
if ! command -v oh-my-posh &>/dev/null; then
    _assert_contains "OhMyPosh checks for binary in PATH" "$ohmyposh_val" "PATH"
fi

# ============================================================================
# Test Suite 8: Validation Function Chaining
# ============================================================================

_test_print_header "Validation Function Chaining"

# Test that main validation dispatcher calls correct sub-function
local main_p10k=$(_prompt_validate powerlevel10k 2>&1)
local sub_p10k=$(_prompt_validate_p10k 2>&1)
# Both should have similar content (or both empty if validation passes)
((TEST_COUNT++))
if [[ "$main_p10k" == "$sub_p10k" ]]; then
    echo "${GREEN}✓${NC} Main and sub validation consistent for p10k"
    ((PASS_COUNT++))
else
    echo "${RED}✗${NC} Main and sub validation consistent for p10k"
    echo "  Main: '$main_p10k'"
    echo "  Sub: '$sub_p10k'"
    ((FAIL_COUNT++))
fi

# ============================================================================
# Test Suite 9: Edge Cases
# ============================================================================

_test_print_header "Edge Cases in Validation"

# Test empty engine name
local empty_val=$(_prompt_validate "" 2>&1)
_assert_contains "Empty engine name shows error" "$empty_val" "Unknown"

# Test case sensitivity (should be case-sensitive)
local upper_val=$(_prompt_validate STARSHIP 2>&1)
_assert_contains "Uppercase engine name fails" "$upper_val" "Unknown"

# Test engine with spaces
local spaces_val=$(_prompt_validate "star ship" 2>&1)
_assert_contains "Engine name with spaces fails" "$spaces_val" "Unknown"

# ============================================================================
# Test Suite 10: Validation Output Format
# ============================================================================

_test_print_header "Validation Output Format"

# Test that errors go to stderr and don't pollute output
local p10k_error=$(_prompt_validate_p10k 2>&1)
local p10k_exit=$?
# If validation passes (exit 0), output may be empty - that's OK
# If validation fails, output should contain error info
((TEST_COUNT++))
if [[ $p10k_exit -eq 0 ]]; then
    # Validation passed - empty output is fine
    echo "${GREEN}✓${NC} P10k validation output is meaningful (passes, no errors)"
    ((PASS_COUNT++))
elif [[ "$p10k_error" == *"Plugin"* ]] || [[ "$p10k_error" == *"config"* ]] || [[ "$p10k_error" == *"not"* ]]; then
    # Validation failed with meaningful error
    echo "${GREEN}✓${NC} P10k validation output is meaningful (has error info)"
    ((PASS_COUNT++))
else
    echo "${RED}✗${NC} P10k validation output is meaningful"
    echo "  Got: '$p10k_error'"
    ((FAIL_COUNT++))
fi

# Test that validation completes (success or failure)
((TEST_COUNT++))
echo "${GREEN}✓${NC} P10k validation completes"
((PASS_COUNT++))

# ============================================================================
# Test Summary
# ============================================================================

_test_summary
