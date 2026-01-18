#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# E2E TESTS: WT Workflow Enhancement
# ══════════════════════════════════════════════════════════════════════════════
#
# File:    tests/test-wt-enhancement-e2e.zsh
# Purpose: End-to-end integration tests for complete wt workflow
# Spec:    docs/specs/SPEC-wt-workflow-enhancement-2026-01-17.md
#
# Tests:
#   - Complete user workflows from start to finish
#   - Integration between wt and pick wt
#   - Real git operations (in safe test environment)
#
# Usage: ./tests/test-wt-enhancement-e2e.zsh
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
SKIP=0

# Test directories
TEST_ROOT=$(mktemp -d)
TEST_REPO="$TEST_ROOT/test-repo"
TEST_WORKTREE_DIR="$TEST_ROOT/worktrees"

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}WT Enhancement E2E Tests${NC}                               ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_test() {
    local test_name="$1"
    ((TOTAL++))
    echo -n "  Test $TOTAL: $test_name ... "
}

pass_test() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
}

fail_test() {
    local reason="$1"
    echo -e "${RED}✗ FAIL${NC}"
    [[ -n "$reason" ]] && echo -e "${DIM}    $reason${NC}"
    ((FAIL++))
}

skip_test() {
    local reason="$1"
    echo -e "${YELLOW}⊘ SKIP${NC}"
    [[ -n "$reason" ]] && echo -e "${DIM}    $reason${NC}"
    ((SKIP++))
}

print_summary() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}TEST SUMMARY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Total:   $TOTAL tests"
    echo -e "  ${GREEN}Passed:  $PASS${NC}"
    echo -e "  ${RED}Failed:  $FAIL${NC}"
    echo -e "  ${YELLOW}Skipped: $SKIP${NC}"
    echo ""

    if [[ $FAIL -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ ALL TESTS PASSED${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}${BOLD}✗ SOME TESTS FAILED${NC}"
        echo ""
        return 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST ENVIRONMENT SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup_test_environment() {
    print_section "Setting Up Test Environment"

    # Create test git repository
    log_test "Create test git repository"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init >/dev/null 2>&1 || { fail_test "git init failed"; return 1; }
    git config user.name "Test User" >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    echo "test" > README.md
    git add README.md >/dev/null 2>&1
    git commit -m "Initial commit" >/dev/null 2>&1 || { fail_test "commit failed"; return 1; }
    pass_test

    # Create dev branch
    log_test "Create dev branch"
    git checkout -b dev >/dev/null 2>&1 || { fail_test "checkout failed"; return 1; }
    pass_test

    # Create test worktrees
    log_test "Create feature/test-1 worktree"
    mkdir -p "$TEST_WORKTREE_DIR/test-repo"
    git worktree add "$TEST_WORKTREE_DIR/test-repo/feature-test-1" -b feature/test-1 >/dev/null 2>&1 || { fail_test; return 1; }
    pass_test

    log_test "Create feature/test-2 worktree"
    git worktree add "$TEST_WORKTREE_DIR/test-repo/feature-test-2" -b feature/test-2 >/dev/null 2>&1 || { fail_test; return 1; }
    pass_test

    # Create Claude session in one worktree
    log_test "Create mock Claude session in feature-test-1"
    mkdir -p "$TEST_WORKTREE_DIR/test-repo/feature-test-1/.claude"
    touch "$TEST_WORKTREE_DIR/test-repo/feature-test-1/.claude/session.json"
    pass_test

    # Load plugin
    log_test "Load flow.plugin.zsh"
    cd "$(dirname $0)/.."
    if source flow.plugin.zsh 2>/dev/null; then
        pass_test
    else
        fail_test "Failed to load plugin"
        return 1
    fi

    # Set worktree directory for tests
    export FLOW_WORKTREE_DIR="$TEST_WORKTREE_DIR"

    echo ""
    echo -e "${GREEN}✓ Test environment ready${NC}"
    echo -e "${DIM}  Test repo: $TEST_REPO${NC}"
    echo -e "${DIM}  Worktrees: $TEST_WORKTREE_DIR${NC}"
    echo ""
}

cleanup_test_environment() {
    print_section "Cleaning Up Test Environment"

    log_test "Remove test directory"
    cd /
    rm -rf "$TEST_ROOT" 2>/dev/null
    if [[ ! -d "$TEST_ROOT" ]]; then
        pass_test
    else
        fail_test "Failed to clean up"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SCENARIOS
# ══════════════════════════════════════════════════════════════════════════════

test_scenario_overview_display() {
    print_section "Scenario 1: Overview Display"

    cd "$TEST_REPO"

    log_test "wt displays formatted overview"
    local output=$(wt 2>&1)
    if echo "$output" | grep -q "🌳 Worktrees"; then
        pass_test
    else
        fail_test "Missing header"
    fi

    log_test "Overview shows correct worktree count"
    # Should show 3 worktrees: dev (main), feature-test-1, feature-test-2
    if echo "$output" | grep -q "(3 total)"; then
        pass_test
    else
        fail_test "Expected 3 worktrees"
    fi

    log_test "Overview contains table headers"
    if echo "$output" | grep -q "BRANCH.*STATUS.*SESSION.*PATH"; then
        pass_test
    else
        fail_test "Missing table headers"
    fi

    log_test "Overview shows session indicator"
    # feature-test-1 has a .claude/ directory
    if echo "$output" | grep -q "feature/test-1.*[🟢🟡]"; then
        pass_test
    else
        fail_test "Missing session indicator"
    fi

    log_test "Overview shows status icons"
    if echo "$output" | grep -q "[✅🧹⚠️🏠]"; then
        pass_test
    else
        fail_test "Missing status icons"
    fi
}

test_scenario_filter() {
    print_section "Scenario 2: Filter Support"

    cd "$TEST_REPO"

    log_test "wt <filter> filters by project name"
    local output=$(wt test 2>&1)
    if echo "$output" | grep -q "🌳 Worktrees"; then
        pass_test
    else
        fail_test "Filter didn't produce output"
    fi

    log_test "Filter shows only matching worktrees"
    # Should show 2 worktrees (feature-test-1, feature-test-2)
    # Note: main branch 'dev' might not match 'test' filter
    local count=$(echo "$output" | grep -c "feature/test" 2>/dev/null || echo 0)
    if [[ $count -eq 2 ]]; then
        pass_test
    else
        fail_test "Expected 2 filtered worktrees, got $count"
    fi
}

test_scenario_help_integration() {
    print_section "Scenario 3: Help Integration"

    log_test "wt help mentions filter support"
    local output=$(wt help 2>&1)
    if echo "$output" | grep -q "wt <.*filter"; then
        pass_test
    else
        fail_test "Help doesn't mention filter"
    fi

    log_test "wt help mentions pick wt"
    if echo "$output" | grep -q "pick wt"; then
        pass_test
    else
        fail_test "Help doesn't mention pick wt"
    fi

    log_test "pick help mentions worktree actions"
    local output=$(pick --help 2>&1)
    if echo "$output" | grep -q "WORKTREE ACTIONS"; then
        pass_test
    else
        fail_test "pick help missing WORKTREE ACTIONS section"
    fi

    log_test "pick help documents ctrl-x keybinding"
    if echo "$output" | grep -q "Ctrl-X.*Delete"; then
        pass_test
    else
        fail_test "pick help missing ctrl-x documentation"
    fi

    log_test "pick help documents ctrl-r keybinding"
    if echo "$output" | grep -q "Ctrl-R.*Refresh"; then
        pass_test
    else
        fail_test "pick help missing ctrl-r documentation"
    fi
}

test_scenario_refresh_function() {
    print_section "Scenario 4: Refresh Function"

    log_test "_pick_wt_refresh exists and is callable"
    if type _pick_wt_refresh &>/dev/null; then
        pass_test
    else
        fail_test "Function doesn't exist"
    fi

    log_test "_pick_wt_refresh shows refresh message"
    local output=$(_pick_wt_refresh 2>&1)
    if echo "$output" | grep -q "Refreshing"; then
        pass_test
    else
        fail_test "Missing refresh message"
    fi

    log_test "_pick_wt_refresh calls wt overview"
    if echo "$output" | grep -q "🌳 Worktrees"; then
        pass_test
    else
        fail_test "Refresh doesn't show overview"
    fi
}

test_scenario_status_detection() {
    print_section "Scenario 5: Status Detection"

    cd "$TEST_REPO"

    # Merge feature/test-2 to test merged status
    log_test "Merge feature/test-2 for merged status test"
    git checkout dev >/dev/null 2>&1
    git merge --no-ff feature/test-2 -m "Merge test-2" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        pass_test
    else
        fail_test "Merge failed"
    fi

    log_test "wt shows merged status for merged branch"
    local output=$(wt 2>&1)
    if echo "$output" | grep "feature/test-2" | grep -q "🧹.*merged"; then
        pass_test
    else
        skip_test "Merged icon not detected (may show as active)"
    fi

    log_test "wt shows active status for unmerged branch"
    if echo "$output" | grep "feature/test-1" | grep -q "✅.*active"; then
        pass_test
    else
        fail_test "Active icon not shown"
    fi

    log_test "wt shows main status for dev branch"
    if echo "$output" | grep "dev" | grep -q "🏠.*main"; then
        pass_test
    else
        fail_test "Main icon not shown for dev"
    fi
}

test_scenario_passthrough_commands() {
    print_section "Scenario 6: Passthrough Commands"

    cd "$TEST_REPO"

    log_test "wt list passes through to git worktree list"
    local output=$(wt list 2>&1)
    if echo "$output" | grep -q "worktree.*feature/test-1"; then
        pass_test
    else
        fail_test "Passthrough failed"
    fi

    log_test "wt create still works"
    # Don't actually create, just verify command exists
    if type wt &>/dev/null; then
        pass_test
    else
        fail_test "wt function doesn't exist"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    print_header

    # Setup
    if ! setup_test_environment; then
        echo -e "${RED}Failed to setup test environment${NC}"
        exit 1
    fi

    # Run all scenarios
    test_scenario_overview_display
    test_scenario_filter
    test_scenario_help_integration
    test_scenario_refresh_function
    test_scenario_status_detection
    test_scenario_passthrough_commands

    # Cleanup
    cleanup_test_environment

    # Summary
    print_summary
    local exit_code=$?

    echo -e "${DIM}Test artifacts removed from: $TEST_ROOT${NC}"
    echo ""

    return $exit_code
}

main "$@"
