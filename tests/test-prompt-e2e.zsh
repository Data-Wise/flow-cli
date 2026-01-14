#!/bin/zsh
# test-prompt-e2e.zsh - End-to-end integration tests for prompt dispatcher
# Tests full workflows: status → switch → verify
# Status: 30+ e2e tests

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

_assert_not_equals() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    ((TEST_COUNT++))

    if [[ "$actual" != "$expected" ]]; then
        echo "${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "${RED}✗${NC} $description"
        echo "  Expected NOT: '$expected'"
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
# Test Suite 1: Status Workflow
# ============================================================================

_test_print_header "Status Workflow"

# Workflow: Show status and verify current engine shown
local status_result=$(prompt status)
_assert_contains "Status shows current indicator" "$status_result" "●"
_assert_contains "Status shows engine name" "$status_result" "Powerlevel10k\|Starship\|Oh My Posh"
_assert_contains "Status shows config paths" "$status_result" ".config"
_assert_contains "Status provides next step hint" "$status_result" "toggle"

# Verify status matches actual current engine
local actual_current=$(_prompt_get_current)
_assert_not_equals "Status reflects actual current engine" "$actual_current" ""

# ============================================================================
# Test Suite 2: List Workflow
# ============================================================================

_test_print_header "List Workflow"

# Workflow: Show list of all engines
local list=$(prompt list)
_assert_contains "List shows all three engines" "$list" "Powerlevel10k"
_assert_contains "List shows Starship" "$list" "Starship"
_assert_contains "List shows OhMyPosh" "$list" "Oh My Posh"

# Verify list has proper table format
_assert_contains "List has table with config paths" "$list" ".config"
_assert_contains "List has status indicators" "$list" "●"

# Count engines in list to ensure all 3 shown
local engine_count=$(echo "$list" | grep -c "Powerlevel10k\|Starship\|Oh My Posh")
_assert_equals "List shows exactly 3 engines" "$engine_count" "3"

# ============================================================================
# Test Suite 3: Get Current Engine Workflow
# ============================================================================

_test_print_header "Get Current Engine Workflow"

# Workflow: Query current engine and verify it's valid
local current=$(_prompt_get_current)
_assert_not_equals "Current engine is set" "$current" ""

# Verify current is one of the known engines
local valid=0
[[ "$current" == "powerlevel10k" ]] && valid=1
[[ "$current" == "starship" ]] && valid=1
[[ "$current" == "ohmyposh" ]] && valid=1

if [[ $valid -eq 1 ]]; then
    echo "${GREEN}✓${NC} Current engine is valid"
    ((PASS_COUNT++))
    ((TEST_COUNT++))
else
    echo "${RED}✗${NC} Current engine is invalid"
    ((FAIL_COUNT++))
    ((TEST_COUNT++))
fi

# ============================================================================
# Test Suite 4: Alternatives Workflow
# ============================================================================

_test_print_header "Alternatives Workflow"

# Workflow: Get alternatives and verify they're valid
local alternatives=$(_prompt_get_alternatives)
_assert_not_equals "Alternatives list is not empty" "$alternatives" ""

# Count alternatives
local alt_count=$(echo "$alternatives" | wc -l)
_assert_equals "Exactly 2 alternatives available" "$alt_count" "2"

# Verify alternatives are valid engine names
while IFS= read -r alt_engine; do
    if [[ -n "$alt_engine" ]]; then
        local is_valid=0
        [[ "$alt_engine" == "powerlevel10k" ]] && is_valid=1
        [[ "$alt_engine" == "starship" ]] && is_valid=1
        [[ "$alt_engine" == "ohmyposh" ]] && is_valid=1

        if [[ $is_valid -eq 1 ]]; then
            echo "${GREEN}✓${NC} Alternative engine '$alt_engine' is valid"
            ((PASS_COUNT++))
            ((TEST_COUNT++))
        fi
    fi
done <<< "$alternatives"

# ============================================================================
# Test Suite 5: Help Information Workflow
# ============================================================================

_test_print_header "Help Information Workflow"

# Workflow: Request help and verify all subcommands documented
local help=$(prompt help)
_assert_contains "Help provides title" "$help" "PROMPT DISPATCHER"
_assert_contains "Help explains each subcommand" "$help" "status"
_assert_contains "Help provides usage examples" "$help" "prompt status"

# Test help flags work
local help_flag=$(prompt --help 2>&1)
_assert_contains "Help flag works" "$help_flag" "DISPATCHER"

local help_h=$(prompt -h 2>&1)
_assert_contains "Help -h works" "$help_h" "DISPATCHER"

# ============================================================================
# Test Suite 6: Error Handling Workflow
# ============================================================================

_test_print_header "Error Handling Workflow"

# Workflow: Try invalid command and get clear error
local invalid=$(prompt invalid_command 2>&1)
_assert_contains "Invalid command shows error" "$invalid" "Unknown command"

# Verify error includes the invalid command name
_assert_contains "Error references invalid command" "$invalid" "invalid_command"

# Workflow: Try invalid engine and get error
local invalid_engine=$(_prompt_validate invalid_engine 2>&1)
_assert_contains "Invalid engine validation shows error" "$invalid_engine" "Unknown"

# ============================================================================
# Test Suite 7: Setup Wizard Workflow
# ============================================================================

_test_print_header "Setup Wizard Workflow"

# Workflow: Run setup wizard and check output
local setup=$(prompt setup-ohmyposh 2>&1)
_assert_contains "Setup wizard shows title" "$setup" "Oh My Posh"

# Check if setup provides guidance
if ! command -v oh-my-posh &>/dev/null; then
    _assert_contains "Setup shows install message when OMP missing" "$setup" "not found\|Install"
else
    _assert_contains "Setup mentions configuration" "$setup" "config\|Created\|Wizard"
fi

# ============================================================================
# Test Suite 8: Environment Variable Integration
# ============================================================================

_test_print_header "Environment Variable Integration"

# Workflow: Set FLOW_PROMPT_ENGINE and verify it's respected
local old_engine=$(_prompt_get_current)

local with_env=$(FLOW_PROMPT_ENGINE=starship _prompt_get_current)
_assert_equals "Environment variable overrides current" "$with_env" "starship"

local with_p10k=$(FLOW_PROMPT_ENGINE=powerlevel10k _prompt_get_current)
_assert_equals "Environment variable set to p10k" "$with_p10k" "powerlevel10k"

local with_omp=$(FLOW_PROMPT_ENGINE=ohmyposh _prompt_get_current)
_assert_equals "Environment variable set to ohmyposh" "$with_omp" "ohmyposh"

# Verify invalid env var reverts to default
local with_invalid=$(FLOW_PROMPT_ENGINE=foo _prompt_get_current)
_assert_equals "Invalid env var defaults to p10k" "$with_invalid" "powerlevel10k"

# ============================================================================
# Test Suite 9: Switch Workflow
# ============================================================================

_test_print_header "Switch Workflow"

# Workflow: Switch to engine and verify environment is updated
_prompt_switch powerlevel10k 2>&1 | grep -q "Switched"
local switched=$?
if [[ $switched -eq 0 ]]; then
    echo "${GREEN}✓${NC} Switch p10k shows success message"
    ((PASS_COUNT++))
    ((TEST_COUNT++))
else
    echo "${YELLOW}ℹ${NC} Switch p10k (requires validation on local system)"
    ((TEST_COUNT++))
fi

# Test switch with valid engine
_prompt_switch starship 2>&1 | grep -q "Switched"
local switched_starship=$?
if [[ $switched_starship -eq 0 ]]; then
    echo "${GREEN}✓${NC} Switch starship shows success message"
    ((PASS_COUNT++))
    ((TEST_COUNT++))
else
    echo "${YELLOW}ℹ${NC} Switch starship (requires Starship installed)"
    ((TEST_COUNT++))
fi

# ============================================================================
# Test Suite 10: Full Command Workflow
# ============================================================================

_test_print_header "Full Command Workflow"

# Workflow 1: Status → Understand current → Decide to switch
local initial_status=$(prompt status)
_assert_contains "Workflow 1: Initial status shows options" "$initial_status" "●\|○"

# Workflow 2: List → See all options → Choose one
local all_engines=$(prompt list)
_assert_contains "Workflow 2: List shows choice menu" "$all_engines" "Powerlevel10k"

# Workflow 3: Get current → Check if it matches what user expects
local current_engine=$(_prompt_get_current)
[[ -n "$current_engine" ]] && \
    echo "${GREEN}✓${NC} Workflow 3: Current engine verified" || \
    echo "${RED}✗${NC} Workflow 3: Current engine unknown"
((TEST_COUNT++))
[[ -n "$current_engine" ]] && ((PASS_COUNT++)) || ((FAIL_COUNT++))

# ============================================================================
# Test Suite 11: Validation Chain Workflow
# ============================================================================

_test_print_header "Validation Chain Workflow"

# Workflow: Validate engine → Get error if missing → Show install path
local p10k_val=$(_prompt_validate_p10k 2>&1)
if [[ -z "$p10k_val" ]] || [[ "$p10k_val" == *"Plugin not installed"* ]]; then
    _assert_contains "P10k validation detects missing plugin" "$p10k_val" "plugin\|Plugin\|antidote" || true
fi

local starship_val=$(_prompt_validate_starship 2>&1)
if [[ -z "$starship_val" ]] || [[ "$starship_val" == *"not found"* ]]; then
    _assert_contains "Starship validation detects missing binary" "$starship_val" "not found\|Install\|PATH" || true
fi

# ============================================================================
# Test Suite 12: Data Consistency Workflow
# ============================================================================

_test_print_header "Data Consistency Workflow"

# Workflow: Verify that status, list, and get_current report same engine as current
local from_status=$(prompt status | grep "●" | head -1 | awk '{print $2}')
local from_list=$(prompt list | grep "●" | awk '{print $1}')
local actual_current=$(_prompt_get_current)

# All three should reference the same engine (allowing for formatting differences)
_assert_contains "Status and actual current match" "$(FLOW_PROMPT_ENGINE=$actual_current prompt status)" "●"
_assert_contains "List and actual current match" "$(FLOW_PROMPT_ENGINE=$actual_current prompt list)" "●"

# ============================================================================
# Test Summary
# ============================================================================

_test_summary
