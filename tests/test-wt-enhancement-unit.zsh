#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS: WT Workflow Enhancement
# ══════════════════════════════════════════════════════════════════════════════
#
# File:    tests/test-wt-enhancement-unit.zsh
# Purpose: Unit tests for wt overview and pick wt actions
# Spec:    docs/specs/SPEC-wt-workflow-enhancement-2026-01-17.md
#
# Tests:
#   Phase 1: _wt_overview() function
#   Phase 2: pick wt delete/refresh actions
#
# Usage: ./tests/test-wt-enhancement-unit.zsh
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Test counters
PASS=0
FAIL=0
TOTAL=0

# Test output
TEST_LOG=$(mktemp)

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}WT Enhancement Unit Tests${NC}                              ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

assert_success() {
    local test_name="$1"
    shift
    ((TOTAL++))

    echo -n "  Test $TOTAL: $test_name ... "

    # Run command and capture output
    local output
    output=$("$@" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
        echo "$test_name: PASS" >> "$TEST_LOG"
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo -e "${DIM}    Exit code: $exit_code${NC}"
        echo -e "${DIM}    Output: $output${NC}"
        ((FAIL++))
        echo "$test_name: FAIL (exit $exit_code)" >> "$TEST_LOG"
    fi
}

assert_contains() {
    local test_name="$1"
    local expected="$2"
    shift 2
    ((TOTAL++))

    echo -n "  Test $TOTAL: $test_name ... "

    # Run command and capture output
    local output
    output=$("$@" 2>&1)

    if echo "$output" | grep -q "$expected"; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
        echo "$test_name: PASS" >> "$TEST_LOG"
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo -e "${DIM}    Expected to contain: $expected${NC}"
        echo -e "${DIM}    Actual output: ${output:0:100}...${NC}"
        ((FAIL++))
        echo "$test_name: FAIL (missing '$expected')" >> "$TEST_LOG"
    fi
}

assert_function_exists() {
    local test_name="$1"
    local function_name="$2"
    ((TOTAL++))

    echo -n "  Test $TOTAL: $test_name ... "

    if type "$function_name" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
        echo "$test_name: PASS" >> "$TEST_LOG"
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo -e "${DIM}    Function not found: $function_name${NC}"
        ((FAIL++))
        echo "$test_name: FAIL (function not found)" >> "$TEST_LOG"
    fi
}

print_summary() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}TEST SUMMARY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Total:  $TOTAL tests"
    echo -e "  ${GREEN}Passed: $PASS${NC}"
    echo -e "  ${RED}Failed: $FAIL${NC}"
    echo ""

    if [[ $FAIL -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ ALL TESTS PASSED${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}${BOLD}✗ SOME TESTS FAILED${NC}"
        echo ""
        echo "See log: $TEST_LOG"
        return 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup_test_env() {
    # Find project root - must contain flow.plugin.zsh
    # Start from script location and search upward
    local current_dir="$(cd "$(dirname ${0:A})" && pwd)"

    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/flow.plugin.zsh" ]]; then
            cd "$current_dir"
            source "flow.plugin.zsh" || {
                echo "Failed to source flow.plugin.zsh"
                exit 1
            }

            # Ensure we're in a git repo
            if ! git rev-parse --git-dir &>/dev/null; then
                echo "Not in a git repository"
                exit 1
            fi

            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    echo "Cannot find flow.plugin.zsh in any parent directory"
    exit 1
}

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 TESTS: _wt_overview()
# ══════════════════════════════════════════════════════════════════════════════

test_wt_overview_function() {
    print_section "Phase 1: _wt_overview() Function Tests"

    # Test 1: Function exists
    assert_function_exists "Function _wt_overview exists" "_wt_overview"

    # Test 2: Overview runs without errors
    assert_success "Overview runs without errors" _wt_overview

    # Test 3: Output contains header
    assert_contains "Output contains 🌳 Worktrees header" "🌳 Worktrees" _wt_overview

    # Test 4: Output contains table headers
    assert_contains "Output contains BRANCH column" "BRANCH" _wt_overview
    assert_contains "Output contains STATUS column" "STATUS" _wt_overview
    assert_contains "Output contains SESSION column" "SESSION" _wt_overview
    assert_contains "Output contains PATH column" "PATH" _wt_overview

    # Test 5: Output contains tip
    assert_contains "Output contains tip section" "💡 Tip:" _wt_overview

    # Test 6: Filter support
    assert_success "Overview with filter doesn't error" _wt_overview "flow"
}

test_wt_dispatcher() {
    print_section "Phase 1: wt() Dispatcher Tests"

    # Test 1: wt function exists
    assert_function_exists "Function wt exists" "wt"

    # Test 2: wt with no args calls overview
    assert_contains "wt (no args) calls overview" "🌳 Worktrees" wt

    # Test 3: wt with filter
    assert_contains "wt <filter> works" "🌳 Worktrees" wt flow

    # Test 4: wt help works
    assert_contains "wt help contains usage" "Usage:" wt help

    # Test 5: wt list passes through
    assert_success "wt list passes to git worktree" wt list
}

test_wt_status_icons() {
    print_section "Phase 1: Status Icon Tests"

    # These tests check that status detection logic works
    # Actual icons depend on worktree state

    # Test 1: Overview handles multiple worktrees
    local output=$(wt)
    local count=$(echo "$output" | grep -c "│" 2>/dev/null)
    : ${count:=0}  # Default to 0 if empty
    ((TOTAL++))
    echo -n "  Test $TOTAL: Overview displays worktree rows ... "
    if [[ ${count} -gt 2 ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo -e "${DIM}    Expected multiple rows, got: ${count}${NC}"
        ((FAIL++))
    fi
}

test_wt_session_detection() {
    print_section "Phase 1: Session Detection Tests"

    # Test 1: Session icons are displayed
    # Check for at least one session indicator (🟢, 🟡, or ⚪)
    assert_contains "Output contains session indicators" "[🟢🟡⚪]" wt
}

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 TESTS: pick wt Actions
# ══════════════════════════════════════════════════════════════════════════════

test_pick_wt_functions() {
    print_section "Phase 2: pick wt Action Function Tests"

    # Test 1: Delete function exists
    assert_function_exists "Function _pick_wt_delete exists" "_pick_wt_delete"

    # Test 2: Refresh function exists
    assert_function_exists "Function _pick_wt_refresh exists" "_pick_wt_refresh"
}

test_pick_wt_refresh() {
    print_section "Phase 2: Refresh Action Tests"

    # Test 1: Refresh runs without errors
    assert_success "Refresh action runs" _pick_wt_refresh

    # Test 2: Refresh output contains overview
    assert_contains "Refresh shows overview" "🌳 Worktrees" _pick_wt_refresh

    # Test 3: Refresh output contains refresh message
    assert_contains "Refresh shows refresh message" "Refreshing" _pick_wt_refresh
}

test_pick_function_integration() {
    print_section "Phase 2: pick() Integration Tests"

    # Test 1: pick function exists
    assert_function_exists "Function pick exists" "pick"

    # Test 2: pick help mentions worktree actions
    assert_contains "pick help has worktree section" "WORKTREE" pick --help
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    print_header

    echo "Setting up test environment..."
    setup_test_env
    echo -e "${GREEN}✓ Environment ready${NC}"

    # Run all test suites
    test_wt_overview_function
    test_wt_dispatcher
    test_wt_status_icons
    test_wt_session_detection
    test_pick_wt_functions
    test_pick_wt_refresh
    test_pick_function_integration

    # Print summary
    print_summary

    # Cleanup
    rm -f "$TEST_LOG"
}

main "$@"
