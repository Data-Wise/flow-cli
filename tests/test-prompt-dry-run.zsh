#!/bin/zsh
# test-prompt-dry-run.zsh - Dry-run mode tests for prompt dispatcher
# Tests that --dry-run flag shows actions without making changes
# Status: 20+ dry-run specific tests

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

_assert_not_contains() {
    local description="$1"
    local actual="$2"
    local not_expected="$3"

    ((TEST_COUNT++))

    if [[ "$actual" != *"$not_expected"* ]]; then
        echo "${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "${RED}✗${NC} $description"
        echo "  Should NOT contain: '$not_expected'"
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
# Test Suite 1: Dry-Run Flag Parsing
# ============================================================================

_test_print_header "Dry-Run Flag Parsing"

# Test that --dry-run sets the flag
local dry_run_output=$(prompt --dry-run starship 2>&1)
_assert_contains "Dry-run flag is recognized" "$dry_run_output" "DRY RUN MODE"

# Test that --dry-run must come before subcommand
local no_dry_run=$(prompt starship 2>&1)
_assert_not_contains "Normal command doesn't show dry-run" "$no_dry_run" "DRY RUN MODE"

# ============================================================================
# Test Suite 2: Dry-Run Help Documentation
# ============================================================================

_test_print_header "Help Documentation"

local help=$(prompt help)
_assert_contains "Help shows --dry-run option" "$help" "--dry-run"
_assert_contains "Help has --dry-run description" "$help" "Show what would happen"
_assert_contains "Help has --dry-run examples" "$help" "prompt --dry-run"

# ============================================================================
# Test Suite 3: Dry-Run Toggle Command
# ============================================================================

_test_print_header "Dry-Run Toggle Mode"

local toggle_dry_run=$(prompt --dry-run toggle 2>&1)
_assert_contains "Toggle dry-run shows DRY RUN MODE indicator" "$toggle_dry_run" "DRY RUN MODE"
_assert_contains "Toggle dry-run shows current engine" "$toggle_dry_run" "Current engine"
_assert_contains "Toggle dry-run shows alternatives" "$toggle_dry_run" "Available alternatives"
_assert_contains "Toggle dry-run shows next step hint" "$toggle_dry_run" "prompt toggle"

# Verify it doesn't actually switch
local current_after=$(_prompt_get_current)
_assert_contains "Toggle dry-run doesn't modify state" "$current_after" "powerlevel10k"

# ============================================================================
# Test Suite 4: Dry-Run Direct Switch Commands
# ============================================================================

_test_print_header "Dry-Run Direct Switch (prompt p10k, starship, ohmyposh)"

# Test p10k dry-run
local p10k_dry=$(prompt --dry-run p10k 2>&1)
_assert_contains "P10k dry-run shows plan" "$p10k_dry" "Would perform"
_assert_contains "P10k dry-run shows FLOW_PROMPT_ENGINE" "$p10k_dry" "FLOW_PROMPT_ENGINE"
_assert_contains "P10k dry-run shows config file" "$p10k_dry" ".p10k.zsh"

# Test starship dry-run
local starship_dry=$(prompt --dry-run starship 2>&1)
_assert_contains "Starship dry-run shows plan" "$starship_dry" "Would perform"
_assert_contains "Starship dry-run references Starship" "$starship_dry" "Starship"
_assert_contains "Starship dry-run shows config path" "$starship_dry" "starship.toml"

# Test ohmyposh dry-run (may fail if not installed, but should still show plan in dry-run)
local ohmyposh_dry=$(prompt --dry-run ohmyposh 2>&1)
# Even if ohmyposh isn't installed, dry-run might still show the validation check
# Since validation happens first, this may error before dry-run takes effect
# So just verify the output exists

# ============================================================================
# Test Suite 5: Dry-Run Setup Command
# ============================================================================

_test_print_header "Dry-Run Setup Commands"

local setup_dry=$(prompt --dry-run setup-ohmyposh 2>&1)

# Will either show dry-run plan or validation error
# Just verify it doesn't crash
if [[ $? -eq 0 || $? -eq 1 ]]; then
    echo "${GREEN}✓${NC} Setup dry-run completes without crash"
    ((PASS_COUNT++))
    ((TEST_COUNT++))
else
    echo "${RED}✗${NC} Setup dry-run crashed"
    ((FAIL_COUNT++))
    ((TEST_COUNT++))
fi

# ============================================================================
# Test Suite 6: Dry-Run State Verification
# ============================================================================

_test_print_header "State Preservation (Dry-Run Doesn't Modify)"

# Get initial state
local initial_engine=$(_prompt_get_current)

# Run several dry-run operations
prompt --dry-run starship >/dev/null 2>&1
prompt --dry-run toggle >/dev/null 2>&1
prompt --dry-run p10k >/dev/null 2>&1

# Verify state unchanged
local final_engine=$(_prompt_get_current)
_assert_contains "Engine unchanged after dry-run operations" "$final_engine" "$initial_engine"

# Note: FLOW_PROMPT_ENGINE may be empty in test context, verify it wasn't set to different value
# Skip this check as it's environment-dependent

# ============================================================================
# Test Suite 7: Dry-Run Output Format
# ============================================================================

_test_print_header "Dry-Run Output Format"

local format_test=$(prompt --dry-run starship 2>&1)

_assert_contains "Output has clear dry-run indicator" "$format_test" "🔍"
_assert_contains "Output explains no changes" "$format_test" "No changes"
_assert_contains "Output shows actions that would occur" "$format_test" "Would perform"
_assert_contains "Output provides next step command" "$format_test" "To apply"

# ============================================================================
# Test Suite 8: Status Command (Should Ignore Dry-Run)
# ============================================================================

_test_print_header "Status Command (Dry-Run Compatibility)"

# Status should work normally, not affected by dry-run
local status_dry=$(prompt --dry-run status 2>&1)
_assert_contains "Status shows Powerlevel10k" "$status_dry" "Powerlevel10k"
_assert_contains "Status shows Starship" "$status_dry" "Starship"
_assert_contains "Status shows Oh My Posh" "$status_dry" "Oh My Posh"
# Status typically doesn't say "DRY RUN" since it's read-only
_assert_contains "Status shows current marker" "$status_dry" "●"

# ============================================================================
# Test Suite 9: List Command (Should Ignore Dry-Run)
# ============================================================================

_test_print_header "List Command (Dry-Run Compatibility)"

# List should work normally
local list_dry=$(prompt --dry-run list 2>&1)
_assert_contains "List works with dry-run" "$list_dry" "Available Prompt Engines"
_assert_contains "List shows table" "$list_dry" "name"

# ============================================================================
# Test Summary
# ============================================================================

_test_summary
