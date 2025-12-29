#!/usr/bin/env zsh
# Test script for wt (worktree) dispatcher
# Tests: wt help, wt list, wt create, wt move, wt remove

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    local project_root=""

    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/wt-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/wt-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/wt-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/wt-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Clear any existing wt alias/function before sourcing
    unalias wt 2>/dev/null || true
    unfunction wt 2>/dev/null || true

    # Source wt dispatcher
    source "$project_root/lib/dispatchers/wt-dispatcher.zsh"

    echo "  Loaded: wt-dispatcher.zsh"
    echo ""
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Save original directory
ORIG_DIR="$PWD"

# Create a temporary git repo for testing
# Sets TEST_DIR and changes to it
create_test_repo() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || return 1
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test"
    git commit --allow-empty -m "Initial commit" --quiet
    git checkout -b dev --quiet
    git checkout main --quiet 2>/dev/null || git checkout -b main --quiet
}

cleanup_test_repo() {
    cd "$ORIG_DIR"
    [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
    TEST_DIR=""
}

# ============================================================================
# TESTS: wt help
# ============================================================================

test_wt_help_shows_output() {
    log_test "wt help shows output"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"Git Worktree Management"* ]]; then
        pass
    else
        fail "Expected 'Git Worktree Management' in output"
    fi
}

test_wt_help_shows_commands() {
    log_test "wt help shows commands"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"wt list"* && "$output" == *"wt create"* ]]; then
        pass
    else
        fail "Expected wt commands in output"
    fi
}

test_wt_help_shows_most_common() {
    log_test "wt help shows MOST COMMON section"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"MOST COMMON"* ]]; then
        pass
    else
        fail "Expected MOST COMMON section in output"
    fi
}

test_wt_help_shows_configuration() {
    log_test "wt help shows configuration"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"FLOW_WORKTREE_DIR"* ]]; then
        pass
    else
        fail "Expected FLOW_WORKTREE_DIR in output"
    fi
}

test_wt_help_shows_passthrough_tip() {
    log_test "wt help shows passthrough tip"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"pass through to git worktree"* ]]; then
        pass
    else
        fail "Expected passthrough tip in output"
    fi
}

# ============================================================================
# TESTS: wt list
# ============================================================================

test_wt_list_works_in_repo() {
    log_test "wt list works in git repo"
    create_test_repo

    wt list >/dev/null 2>&1
    local result=$?

    if [[ $result -eq 0 ]]; then
        pass
    else
        fail "wt list should work in git repo"
    fi
    cleanup_test_repo
}

test_wt_list_alias_works() {
    log_test "wt ls alias works"
    create_test_repo

    wt ls >/dev/null 2>&1
    local result=$?

    if [[ $result -eq 0 ]]; then
        pass
    else
        fail "wt ls should work"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: wt create
# ============================================================================

test_wt_create_requires_branch() {
    log_test "wt create requires branch name"
    create_test_repo

    local output result
    output=$(wt create 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Branch name required"* ]]; then
        pass
    else
        fail "Expected error for missing branch name"
    fi
    cleanup_test_repo
}

test_wt_create_shows_usage() {
    log_test "wt create shows usage on error"
    create_test_repo

    local output=$(wt create 2>&1)

    if [[ "$output" == *"Usage: wt create"* ]]; then
        pass
    else
        fail "Expected usage in error output"
    fi
    cleanup_test_repo
}

test_wt_create_requires_git_repo() {
    log_test "wt create requires git repo"
    local old_dir="$PWD"
    cd /tmp

    local output result
    output=$(wt create feature/test 2>&1)
    result=$?

    cd "$old_dir"

    if [[ $result -ne 0 && "$output" == *"Not in a git repository"* ]]; then
        pass
    else
        fail "Expected error outside git repo"
    fi
}

# ============================================================================
# TESTS: wt move
# ============================================================================

test_wt_move_rejects_main() {
    log_test "wt move rejects main branch"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(wt move 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Cannot move protected branch"* ]]; then
        pass
    else
        fail "Expected error for main branch"
    fi
    cleanup_test_repo
}

test_wt_move_rejects_dev() {
    log_test "wt move rejects dev branch"
    create_test_repo
    git checkout dev --quiet 2>/dev/null

    local output result
    output=$(wt move 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Cannot move protected branch"* ]]; then
        pass
    else
        fail "Expected error for dev branch"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: wt remove
# ============================================================================

test_wt_remove_requires_path() {
    log_test "wt remove requires path"
    create_test_repo

    local output result
    output=$(wt remove 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Worktree path required"* ]]; then
        pass
    else
        fail "Expected error for missing path"
    fi
    cleanup_test_repo
}

test_wt_remove_shows_worktrees() {
    log_test "wt remove shows current worktrees"
    create_test_repo

    local output=$(wt remove 2>&1)

    if [[ "$output" == *"Current worktrees"* ]]; then
        pass
    else
        fail "Expected worktree list in error output"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: wt clean
# ============================================================================

test_wt_clean_works() {
    log_test "wt clean works"
    create_test_repo

    local output result
    output=$(wt clean 2>&1)
    result=$?

    if [[ $result -eq 0 && "$output" == *"Pruned"* ]]; then
        pass
    else
        fail "wt clean should work and show success"
    fi
    cleanup_test_repo
}

test_wt_prune_alias_works() {
    log_test "wt prune alias works"
    create_test_repo

    local output result
    output=$(wt prune 2>&1)
    result=$?

    # prune passes through to git worktree prune
    if [[ $result -eq 0 ]]; then
        pass
    else
        fail "wt prune should work"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: Passthrough
# ============================================================================

test_wt_passthrough_works() {
    log_test "wt passthrough to git worktree"
    create_test_repo

    # Unknown command should passthrough
    local output=$(wt lock --help 2>&1)

    # Should show git worktree lock help (or error from git)
    if [[ "$output" == *"worktree"* || "$output" == *"lock"* ]]; then
        pass
    else
        fail "Expected passthrough to git worktree"
    fi
    cleanup_test_repo
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo "${YELLOW}║${NC}  WT (Worktree) Dispatcher Tests                            ${YELLOW}║${NC}"
    echo "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"

    setup

    echo "${YELLOW}── wt help ──${NC}"
    test_wt_help_shows_output
    test_wt_help_shows_commands
    test_wt_help_shows_most_common
    test_wt_help_shows_configuration
    test_wt_help_shows_passthrough_tip

    echo ""
    echo "${YELLOW}── wt list ──${NC}"
    test_wt_list_works_in_repo
    test_wt_list_alias_works

    echo ""
    echo "${YELLOW}── wt create ──${NC}"
    test_wt_create_requires_branch
    test_wt_create_shows_usage
    test_wt_create_requires_git_repo

    echo ""
    echo "${YELLOW}── wt move ──${NC}"
    test_wt_move_rejects_main
    test_wt_move_rejects_dev

    echo ""
    echo "${YELLOW}── wt remove ──${NC}"
    test_wt_remove_requires_path
    test_wt_remove_shows_worktrees

    echo ""
    echo "${YELLOW}── wt clean ──${NC}"
    test_wt_clean_works
    test_wt_prune_alias_works

    echo ""
    echo "${YELLOW}── Passthrough ──${NC}"
    test_wt_passthrough_works

    # Summary
    echo ""
    echo "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo "Results: ${GREEN}$TESTS_PASSED passed${NC}, ${RED}$TESTS_FAILED failed${NC}"
    echo "${YELLOW}════════════════════════════════════════════════════════════${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
