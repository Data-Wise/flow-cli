#!/bin/zsh
# test-prompt-unit.zsh - Comprehensive unit tests for prompt dispatcher
# Tests individual functions in isolation
# Status: 60+ unit tests

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
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

_assert_not_empty() {
    local description="$1"
    local actual="$2"

    ((TEST_COUNT++))

    if [[ -n "$actual" ]]; then
        echo "${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "${RED}✗${NC} $description"
        echo "  Expected: non-empty value"
        echo "  Got: empty"
        ((FAIL_COUNT++))
        return 1
    fi
}

_assert_regex_match() {
    local description="$1"
    local actual="$2"
    local regex="$3"

    ((TEST_COUNT++))

    if [[ "$actual" =~ $regex ]]; then
        echo "${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "${RED}✗${NC} $description"
        echo "  Expected pattern: '$regex'"
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
# Test Suite 1: Dispatcher Entry Point
# ============================================================================

_test_print_header "Dispatcher Entry Point (prompt function)"

# Test with no arguments (should show help)
local no_args=$(prompt 2>&1)
_assert_contains "No args shows help" "$no_args" "PROMPT DISPATCHER"

# Test with help flag
local help=$(prompt --help 2>&1)
_assert_contains "Help flag works" "$help" "USAGE"

# Test invalid command
local invalid=$(prompt foobar 2>&1)
_assert_contains "Invalid command shows error" "$invalid" "Unknown command"

# Test all valid subcommands exist
_assert_contains "Has status subcommand" "$(prompt 2>&1)" "status"
_assert_contains "Has toggle subcommand" "$(prompt 2>&1)" "toggle"
_assert_contains "Has list subcommand" "$(prompt 2>&1)" "list"

# ============================================================================
# Test Suite 2: Engine Registry Data Structure
# ============================================================================

_test_print_header "Engine Registry Data Structure"

# Test all engines have required fields
local engines=(powerlevel10k starship ohmyposh)
for engine in "${engines[@]}"; do
    local name="${PROMPT_ENGINES[${engine}_name]}"
    local display="${PROMPT_ENGINES[${engine}_display]}"
    local config="${PROMPT_ENGINES[${engine}_config]}"
    local desc="${PROMPT_ENGINES[${engine}_description]}"

    _assert_not_empty "$engine has name field" "$name"
    _assert_not_empty "$engine has display field" "$display"
    _assert_not_empty "$engine has config field" "$config"
    _assert_not_empty "$engine has description field" "$desc"
done

# Test engine names are correct
_assert_equals "P10k name correct" "${PROMPT_ENGINES[powerlevel10k_name]}" "powerlevel10k"
_assert_equals "Starship name correct" "${PROMPT_ENGINES[starship_name]}" "starship"
_assert_equals "OhMyPosh name correct" "${PROMPT_ENGINES[ohmyposh_name]}" "ohmyposh"

# Test config paths are correct
_assert_contains "P10k config has .config" "${PROMPT_ENGINES[powerlevel10k_config]}" ".config"
_assert_contains "Starship config has .config" "${PROMPT_ENGINES[starship_config]}" ".config"
_assert_contains "OhMyPosh config has .config" "${PROMPT_ENGINES[ohmyposh_config]}" ".config"

# ============================================================================
# Test Suite 3: Helper Function - Get Current
# ============================================================================

_test_print_header "Helper: _prompt_get_current()"

# Test default behavior
local current=$(_prompt_get_current)
_assert_equals "Default returns p10k" "$current" "powerlevel10k"

# Test with environment variable
current=$(FLOW_PROMPT_ENGINE=starship _prompt_get_current)
_assert_equals "Respects FLOW_PROMPT_ENGINE=starship" "$current" "starship"

current=$(FLOW_PROMPT_ENGINE=ohmyposh _prompt_get_current)
_assert_equals "Respects FLOW_PROMPT_ENGINE=ohmyposh" "$current" "ohmyposh"

# Test invalid engine falls back to default
current=$(FLOW_PROMPT_ENGINE=invalid_engine _prompt_get_current)
_assert_equals "Invalid engine defaults to p10k" "$current" "powerlevel10k"

# Test empty env var defaults
current=$(FLOW_PROMPT_ENGINE="" _prompt_get_current)
_assert_equals "Empty env defaults to p10k" "$current" "powerlevel10k"

# ============================================================================
# Test Suite 4: Helper Function - Get Alternatives
# ============================================================================

_test_print_header "Helper: _prompt_get_alternatives()"

# Test alternatives when current is p10k
local alts=$(FLOW_PROMPT_ENGINE=powerlevel10k _prompt_get_alternatives | tr '\n' ' ')
_assert_contains "P10k alternatives includes starship" "$alts" "starship"
_assert_contains "P10k alternatives includes ohmyposh" "$alts" "ohmyposh"

# Test alternatives when current is starship
alts=$(FLOW_PROMPT_ENGINE=starship _prompt_get_alternatives | tr '\n' ' ')
_assert_contains "Starship alternatives includes p10k" "$alts" "powerlevel10k"
_assert_contains "Starship alternatives includes ohmyposh" "$alts" "ohmyposh"

# Test alternatives when current is ohmyposh
alts=$(FLOW_PROMPT_ENGINE=ohmyposh _prompt_get_alternatives | tr '\n' ' ')
_assert_contains "OhMyPosh alternatives includes starship" "$alts" "starship"
_assert_contains "OhMyPosh alternatives includes p10k" "$alts" "powerlevel10k"

# ============================================================================
# Test Suite 5: Help Output Structure
# ============================================================================

_test_print_header "Help Output Structure"

local help=$(prompt help)

# Test all sections present
_assert_contains "Help has title" "$help" "PROMPT DISPATCHER"
_assert_contains "Help has usage" "$help" "USAGE"
_assert_contains "Help has subcommands section" "$help" "SUBCOMMANDS"
_assert_contains "Help has examples" "$help" "EXAMPLES"
_assert_contains "Help has setup section" "$help" "SETUP"

# Test all subcommands documented
_assert_contains "Help documents status" "$help" "status"
_assert_contains "Help documents toggle" "$help" "toggle"
_assert_contains "Help documents starship" "$help" "starship"
_assert_contains "Help documents p10k" "$help" "p10k"
_assert_contains "Help documents ohmyposh" "$help" "ohmyposh"
_assert_contains "Help documents list" "$help" "list"
_assert_contains "Help documents help" "$help" "help"
_assert_contains "Help documents setup" "$help" "setup-ohmyposh"

# Test all examples present
_assert_contains "Help has status example" "$help" "prompt status"
_assert_contains "Help has toggle example" "$help" "prompt toggle"
_assert_contains "Help has setup example" "$help" "prompt setup-ohmyposh"

# ============================================================================
# Test Suite 6: Status Output Structure
# ============================================================================

_test_print_header "Status Output Structure"

local status_output=$(prompt status)

# Test format
_assert_contains "Status has header" "$status_output" "Prompt Engines"
_assert_contains "Status has bullet symbol" "$status_output" "●"
_assert_contains "Status has circle symbol" "$status_output" "○"
_assert_contains "Status shows current indicator" "$status_output" "current"
_assert_contains "Status shows toggle hint" "$status_output" "prompt toggle"

# Test all engines shown
_assert_contains "Status shows Powerlevel10k" "$status_output" "Powerlevel10k"
_assert_contains "Status shows Starship" "$status_output" "Starship"
_assert_contains "Status shows Oh My Posh" "$status_output" "Oh My Posh"

# Test descriptions shown
_assert_contains "Status shows P10k description" "$status_output" "Feature-rich"
_assert_contains "Status shows Starship description" "$status_output" "Minimal"
_assert_contains "Status shows OhMyPosh description" "$status_output" "Modular"

# ============================================================================
# Test Suite 7: List Output Structure
# ============================================================================

_test_print_header "List Output Structure"

local list=$(prompt list)

# Test table format
_assert_contains "List has header" "$list" "Available Prompt Engines"
_assert_contains "List has column headers" "$list" "name"
_assert_contains "List has active column" "$list" "active"
_assert_contains "List has config column" "$list" "config file"
_assert_contains "List has legend" "$list" "Legend"

# Test all engines in table
_assert_contains "List shows Powerlevel10k" "$list" "Powerlevel10k"
_assert_contains "List shows Starship" "$list" "Starship"
_assert_contains "List shows Oh My Posh" "$list" "Oh My Posh"

# Test indicators
_assert_contains "List has current bullet" "$list" "●"
_assert_contains "List has available circle" "$list" "○"

# ============================================================================
# Test Suite 8: Error Messages
# ============================================================================

_test_print_header "Error Messages and Feedback"

# Test invalid subcommand
local error=$(prompt badcommand 2>&1)
_assert_contains "Invalid command error includes command name" "$error" "badcommand"
_assert_contains "Invalid command error helpful" "$error" "Unknown command"

# Test no arguments shows help (not error)
local default=$(prompt 2>&1)
_assert_contains "No args defaults to help" "$default" "DISPATCHER"

# ============================================================================
# Test Suite 9: Array and Registry Size
# ============================================================================

_test_print_header "Data Structure Sizes"

# Count engines
local engine_count=${#PROMPT_ENGINE_NAMES[@]}
_assert_equals "Exactly 3 engines registered" "$engine_count" "3"

# Verify P10k fields exist
[[ -n "${PROMPT_ENGINES[powerlevel10k_name]}" ]] && ((TEST_COUNT++)) && ((PASS_COUNT++)) && \
    echo "${GREEN}✓${NC} P10k has name field"
[[ -n "${PROMPT_ENGINES[powerlevel10k_display]}" ]] && ((TEST_COUNT++)) && ((PASS_COUNT++)) && \
    echo "${GREEN}✓${NC} P10k has display field"
[[ -n "${PROMPT_ENGINES[powerlevel10k_config]}" ]] && ((TEST_COUNT++)) && ((PASS_COUNT++)) && \
    echo "${GREEN}✓${NC} P10k has config field"
[[ -n "${PROMPT_ENGINES[powerlevel10k_description]}" ]] && ((TEST_COUNT++)) && ((PASS_COUNT++)) && \
    echo "${GREEN}✓${NC} P10k has description field"

# ============================================================================
# Test Summary
# ============================================================================

_test_summary
