#!/bin/zsh
# test-prompt-dispatcher.zsh - Comprehensive tests for prompt dispatcher
# Test coverage: 40+ unit tests

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
# Test Suite 1: Help Output
# ============================================================================

_test_print_header "Help Command Output"

local help_output=$(prompt help)
_assert_contains "Help shows dispatcher name" "$help_output" "PROMPT DISPATCHER"
_assert_contains "Help shows status subcommand" "$help_output" "status"
_assert_contains "Help shows toggle subcommand" "$help_output" "toggle"
_assert_contains "Help shows starship subcommand" "$help_output" "starship"
_assert_contains "Help shows p10k subcommand" "$help_output" "p10k"
_assert_contains "Help shows ohmyposh subcommand" "$help_output" "ohmyposh"
_assert_contains "Help shows list subcommand" "$help_output" "list"

# ============================================================================
# Test Suite 2: Status Output
# ============================================================================

_test_print_header "Status Command Output"

local status_output=$(prompt status)
_assert_contains "Status shows header" "$status_output" "Prompt Engines"
_assert_contains "Status shows Powerlevel10k" "$status_output" "Powerlevel10k"
_assert_contains "Status shows Starship" "$status_output" "Starship"
_assert_contains "Status shows Oh My Posh" "$status_output" "Oh My Posh"
_assert_contains "Status shows config files" "$status_output" ".config"
_assert_contains "Status shows current indicator" "$status_output" "●"

# ============================================================================
# Test Suite 3: List Output
# ============================================================================

_test_print_header "List Command Output"

local list_output=$(prompt list)
_assert_contains "List shows header" "$list_output" "Available Prompt Engines"
_assert_contains "List shows Powerlevel10k" "$list_output" "Powerlevel10k"
_assert_contains "List shows Starship" "$list_output" "Starship"
_assert_contains "List shows Oh My Posh" "$list_output" "Oh My Posh"
_assert_contains "List shows current indicator" "$list_output" "●"
_assert_contains "List shows available indicator" "$list_output" "○"
_assert_contains "List shows config paths" "$list_output" ".config"
_assert_contains "List shows legend" "$list_output" "Legend"

# ============================================================================
# Test Suite 4: Engine Registry
# ============================================================================

_test_print_header "Engine Registry"

_assert_equals "P10k name registered" "${PROMPT_ENGINES[powerlevel10k_name]}" "powerlevel10k"
_assert_equals "Starship name registered" "${PROMPT_ENGINES[starship_name]}" "starship"
_assert_equals "OhMyPosh name registered" "${PROMPT_ENGINES[ohmyposh_name]}" "ohmyposh"

_assert_equals "P10k display name" "${PROMPT_ENGINES[powerlevel10k_display]}" "Powerlevel10k"
_assert_equals "Starship display name" "${PROMPT_ENGINES[starship_display]}" "Starship"
_assert_equals "OhMyPosh display name" "${PROMPT_ENGINES[ohmyposh_display]}" "Oh My Posh"

_assert_contains "P10k has description" "${PROMPT_ENGINES[powerlevel10k_description]}" "Feature-rich"
_assert_contains "Starship has description" "${PROMPT_ENGINES[starship_description]}" "Minimal"
_assert_contains "OhMyPosh has description" "${PROMPT_ENGINES[ohmyposh_description]}" "Modular"

# ============================================================================
# Test Suite 5: Get Current Engine
# ============================================================================

_test_print_header "Get Current Engine Function"

local current=$(_prompt_get_current)
local has_value="yes"
[[ -z "$current" ]] && has_value="no"
_assert_equals "Get current returns a value" "$has_value" "yes"

_assert_equals "Current engine is valid" "$current" "powerlevel10k"

# Test with environment variable
current=$(FLOW_PROMPT_ENGINE=starship _prompt_get_current)
_assert_equals "Respects FLOW_PROMPT_ENGINE for starship" "$current" "starship"

current=$(FLOW_PROMPT_ENGINE=ohmyposh _prompt_get_current)
_assert_equals "Respects FLOW_PROMPT_ENGINE for ohmyposh" "$current" "ohmyposh"

# Test with invalid engine
current=$(FLOW_PROMPT_ENGINE=invalid _prompt_get_current)
_assert_equals "Defaults to p10k for invalid engine" "$current" "powerlevel10k"

# ============================================================================
# Test Suite 6: Get Alternatives Function
# ============================================================================

_test_print_header "Get Alternatives Function"

local alts=$(FLOW_PROMPT_ENGINE=powerlevel10k _prompt_get_alternatives | tr '\n' ' ')
_assert_contains "Alternatives includes starship" "$alts" "starship"
_assert_contains "Alternatives includes ohmyposh" "$alts" "ohmyposh"

# ============================================================================
# Test Suite 7: Invalid Commands
# ============================================================================

_test_print_header "Invalid Commands"

local invalid_output=$(prompt invalid 2>&1)
_assert_contains "Invalid command shows error" "$invalid_output" "Unknown command"

# ============================================================================
# Test Summary
# ============================================================================

_test_summary
