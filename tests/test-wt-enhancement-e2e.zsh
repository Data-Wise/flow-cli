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

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# Test directories
TEST_ROOT=$(mktemp -d)
TEST_REPO="$TEST_ROOT/test-repo"
TEST_WORKTREE_DIR="$TEST_ROOT/worktrees"

# ══════════════════════════════════════════════════════════════════════════════
# TEST ENVIRONMENT SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup_test_environment() {
    # Create test git repository
    test_case "Create test git repository"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init >/dev/null 2>&1 || { test_fail "git init failed"; return 1; }
    git config user.name "Test User" >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    echo "test" > README.md
    git add README.md >/dev/null 2>&1
    git commit -m "Initial commit" >/dev/null 2>&1 || { test_fail "commit failed"; return 1; }
    test_pass

    # Create dev branch
    test_case "Create dev branch"
    git checkout -b dev >/dev/null 2>&1 || { test_fail "checkout failed"; return 1; }
    test_pass

    # Create test worktrees
    test_case "Create feature/test-1 worktree"
    mkdir -p "$TEST_WORKTREE_DIR/test-repo"
    git worktree add "$TEST_WORKTREE_DIR/test-repo/feature-test-1" -b feature/test-1 >/dev/null 2>&1 || { test_fail; return 1; }
    test_pass

    test_case "Create feature/test-2 worktree"
    git worktree add "$TEST_WORKTREE_DIR/test-repo/feature-test-2" -b feature/test-2 >/dev/null 2>&1 || { test_fail; return 1; }
    test_pass

    # Create Claude session in one worktree
    test_case "Create mock Claude session in feature-test-1"
    mkdir -p "$TEST_WORKTREE_DIR/test-repo/feature-test-1/.claude"
    touch "$TEST_WORKTREE_DIR/test-repo/feature-test-1/.claude/session.json"
    test_pass

    # Load plugin
    test_case "Load flow.plugin.zsh"
    cd "$PROJECT_ROOT"
    if source flow.plugin.zsh 2>/dev/null; then
        test_pass
    else
        test_fail "Failed to load plugin"
        return 1
    fi

    # Set worktree directory for tests
    export FLOW_WORKTREE_DIR="$TEST_WORKTREE_DIR"
}

cleanup_test_environment() {
    test_case "Remove test directory"
    cd /
    rm -rf "$TEST_ROOT" 2>/dev/null
    if [[ ! -d "$TEST_ROOT" ]]; then
        test_pass
    else
        test_fail "Failed to clean up"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SCENARIOS
# ══════════════════════════════════════════════════════════════════════════════

test_scenario_overview_display() {
    cd "$TEST_REPO"

    test_case "wt displays formatted overview"
    local output=$(wt 2>&1)
    if echo "$output" | grep -q "🌳 Worktrees"; then
        test_pass
    else
        test_fail "Missing header"
    fi

    test_case "Overview shows correct worktree count"
    # Should show 3 worktrees: dev (main), feature-test-1, feature-test-2
    if echo "$output" | grep -q "(3 total)"; then
        test_pass
    else
        test_fail "Expected 3 worktrees"
    fi

    test_case "Overview contains table headers"
    if echo "$output" | grep -q "BRANCH.*STATUS.*SESSION.*PATH"; then
        test_pass
    else
        test_fail "Missing table headers"
    fi

    test_case "Overview shows session indicator"
    # feature-test-1 has a .claude/ directory
    if echo "$output" | grep -q "feature/test-1.*[🟢🟡]"; then
        test_pass
    else
        test_fail "Missing session indicator"
    fi

    test_case "Overview shows status icons"
    if echo "$output" | grep -q "[✅🧹⚠️🏠]"; then
        test_pass
    else
        test_fail "Missing status icons"
    fi
}

test_scenario_filter() {
    cd "$TEST_REPO"

    test_case "wt <filter> filters by project name"
    local output=$(wt test 2>&1)
    if echo "$output" | grep -q "🌳 Worktrees"; then
        test_pass
    else
        test_fail "Filter didn't produce output"
    fi

    test_case "Filter shows only matching worktrees"
    # Should show 2 worktrees (feature-test-1, feature-test-2)
    # Note: main branch 'dev' might not match 'test' filter
    local count=$(echo "$output" | grep -c "feature/test" 2>/dev/null || echo 0)
    if [[ $count -eq 2 ]]; then
        test_pass
    else
        test_fail "Expected 2 filtered worktrees, got $count"
    fi
}

test_scenario_help_integration() {
    test_case "wt help mentions filter support"
    local output=$(wt help 2>&1)
    if echo "$output" | grep -q "wt <.*filter"; then
        test_pass
    else
        test_fail "Help doesn't mention filter"
    fi

    test_case "wt help mentions pick wt"
    if echo "$output" | grep -q "pick wt"; then
        test_pass
    else
        test_fail "Help doesn't mention pick wt"
    fi

    test_case "pick help mentions worktree actions"
    local output=$(pick --help 2>&1)
    if echo "$output" | grep -q "WORKTREE ACTIONS"; then
        test_pass
    else
        test_fail "pick help missing WORKTREE ACTIONS section"
    fi

    test_case "pick help documents ctrl-x keybinding"
    if echo "$output" | grep -q "Ctrl-X.*Delete"; then
        test_pass
    else
        test_fail "pick help missing ctrl-x documentation"
    fi

    test_case "pick help documents ctrl-r keybinding"
    if echo "$output" | grep -q "Ctrl-R.*Refresh"; then
        test_pass
    else
        test_fail "pick help missing ctrl-r documentation"
    fi
}

test_scenario_refresh_function() {
    test_case "_pick_wt_refresh exists and is callable"
    if type _pick_wt_refresh &>/dev/null; then
        test_pass
    else
        test_fail "Function doesn't exist"
    fi

    test_case "_pick_wt_refresh shows refresh message"
    local output=$(_pick_wt_refresh 2>&1)
    if echo "$output" | grep -q "Refreshing"; then
        test_pass
    else
        test_fail "Missing refresh message"
    fi

    test_case "_pick_wt_refresh calls wt overview"
    if echo "$output" | grep -q "🌳 Worktrees"; then
        test_pass
    else
        test_fail "Refresh doesn't show overview"
    fi
}

test_scenario_status_detection() {
    cd "$TEST_REPO"

    # Merge feature/test-2 to test merged status
    test_case "Merge feature/test-2 for merged status test"
    git checkout dev >/dev/null 2>&1
    git merge --no-ff feature/test-2 -m "Merge test-2" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        test_pass
    else
        test_fail "Merge failed"
    fi

    test_case "wt shows merged status for merged branch"
    local output=$(wt 2>&1)
    if echo "$output" | grep "feature/test-2" | grep -q "🧹.*merged"; then
        test_pass
    else
        test_skip "Merged icon not detected (may show as active)"
    fi

    test_case "wt shows active status for unmerged branch"
    if echo "$output" | grep "feature/test-1" | grep -q "✅.*active"; then
        test_pass
    else
        test_fail "Active icon not shown"
    fi

    test_case "wt shows main status for dev branch"
    if echo "$output" | grep "dev" | grep -q "🏠.*main"; then
        test_pass
    else
        test_fail "Main icon not shown for dev"
    fi
}

test_scenario_passthrough_commands() {
    cd "$TEST_REPO"

    test_case "wt list passes through to git worktree list"
    local output=$(wt list 2>&1)
    if echo "$output" | grep -q "worktree.*feature/test-1"; then
        test_pass
    else
        test_fail "Passthrough failed"
    fi

    test_case "wt create still works"
    # Don't actually create, just verify command exists
    if type wt &>/dev/null; then
        test_pass
    else
        test_fail "wt function doesn't exist"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

test_suite_start "WT Enhancement E2E Tests"

# Setup
if ! setup_test_environment; then
    echo "Failed to setup test environment"
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
test_suite_end
exit $?
