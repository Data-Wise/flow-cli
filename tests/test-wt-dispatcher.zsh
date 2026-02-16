#!/usr/bin/env zsh
# Test script for wt (worktree) dispatcher
# Tests: wt help, wt list, wt create, wt move, wt remove

# ============================================================================
# SHARED FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP & CLEANUP
# ============================================================================

ORIG_DIR="$PWD"

setup() {
    local project_root="$PROJECT_ROOT"

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/wt-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/wt-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/wt-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/wt-dispatcher.zsh" ]]; then
        echo "ERROR: Cannot find project root - run from project directory"
        exit 1
    fi

    # Clear any existing wt alias/function before sourcing
    unalias wt 2>/dev/null || true
    unfunction wt 2>/dev/null || true

    # Source wt dispatcher
    source "$project_root/lib/dispatchers/wt-dispatcher.zsh"
}

cleanup() {
    cleanup_test_repo
    reset_mocks
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

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
    test_case "wt help shows output"
    local output=$(wt help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"Git Worktree Management"* ]]; then
        test_pass
    else
        test_fail "Expected 'Git Worktree Management' in output"
    fi
}

test_wt_help_shows_commands() {
    test_case "wt help shows commands"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"wt list"* && "$output" == *"wt create"* ]]; then
        test_pass
    else
        test_fail "Expected wt commands in output"
    fi
}

test_wt_help_shows_most_common() {
    test_case "wt help shows MOST COMMON section"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"MOST COMMON"* ]]; then
        test_pass
    else
        test_fail "Expected MOST COMMON section in output"
    fi
}

test_wt_help_shows_configuration() {
    test_case "wt help shows configuration"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"FLOW_WORKTREE_DIR"* ]]; then
        test_pass
    else
        test_fail "Expected FLOW_WORKTREE_DIR in output"
    fi
}

test_wt_help_shows_passthrough_tip() {
    test_case "wt help shows passthrough tip"
    local output=$(wt help 2>&1)
    if [[ "$output" == *"pass through to git worktree"* ]]; then
        test_pass
    else
        test_fail "Expected passthrough tip in output"
    fi
}

# ============================================================================
# TESTS: wt list
# ============================================================================

test_wt_list_works_in_repo() {
    test_case "wt list works in git repo"
    create_test_repo

    local output
    output=$(wt list 2>&1)
    local result=$?

    assert_not_contains "$output" "command not found"
    if [[ $result -eq 0 ]]; then
        test_pass
    else
        test_fail "wt list should work in git repo"
    fi
    cleanup_test_repo
}

test_wt_list_alias_works() {
    test_case "wt ls alias works"
    create_test_repo

    local output
    output=$(wt ls 2>&1)
    local result=$?

    assert_not_contains "$output" "command not found"
    if [[ $result -eq 0 ]]; then
        test_pass
    else
        test_fail "wt ls should work"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: wt create
# ============================================================================

test_wt_create_requires_branch() {
    test_case "wt create requires branch name"
    create_test_repo

    local output result
    output=$(wt create 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Branch name required"* ]]; then
        test_pass
    else
        test_fail "Expected error for missing branch name"
    fi
    cleanup_test_repo
}

test_wt_create_shows_usage() {
    test_case "wt create shows usage on error"
    create_test_repo

    local output=$(wt create 2>&1)

    if [[ "$output" == *"Usage: wt create"* ]]; then
        test_pass
    else
        test_fail "Expected usage in error output"
    fi
    cleanup_test_repo
}

test_wt_create_requires_git_repo() {
    test_case "wt create requires git repo"
    local old_dir="$PWD"
    cd /tmp

    local output result
    output=$(wt create feature/test 2>&1)
    result=$?

    cd "$old_dir"

    if [[ $result -ne 0 && "$output" == *"Not in a git repository"* ]]; then
        test_pass
    else
        test_fail "Expected error outside git repo"
    fi
}

# ============================================================================
# TESTS: wt move
# ============================================================================

test_wt_move_rejects_main() {
    test_case "wt move rejects main branch"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(wt move 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Cannot move protected branch"* ]]; then
        test_pass
    else
        test_fail "Expected error for main branch"
    fi
    cleanup_test_repo
}

test_wt_move_rejects_dev() {
    test_case "wt move rejects dev branch"
    create_test_repo
    git checkout dev --quiet 2>/dev/null

    local output result
    output=$(wt move 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Cannot move protected branch"* ]]; then
        test_pass
    else
        test_fail "Expected error for dev branch"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: wt remove
# ============================================================================

test_wt_remove_requires_path() {
    test_case "wt remove requires path"
    create_test_repo

    local output result
    output=$(wt remove 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Worktree path required"* ]]; then
        test_pass
    else
        test_fail "Expected error for missing path"
    fi
    cleanup_test_repo
}

test_wt_remove_shows_worktrees() {
    test_case "wt remove shows current worktrees"
    create_test_repo

    local output=$(wt remove 2>&1)

    if [[ "$output" == *"Current worktrees"* ]]; then
        test_pass
    else
        test_fail "Expected worktree list in error output"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: wt clean
# ============================================================================

test_wt_clean_works() {
    test_case "wt clean works"
    create_test_repo

    local output result
    output=$(wt clean 2>&1)
    result=$?

    if [[ $result -eq 0 && "$output" == *"Pruned"* ]]; then
        test_pass
    else
        test_fail "wt clean should work and show success"
    fi
    cleanup_test_repo
}

test_wt_prune_alias_works() {
    test_case "wt prune alias works"
    create_test_repo

    local output result
    output=$(wt prune 2>&1)
    result=$?

    assert_not_contains "$output" "command not found"
    # prune passes through to git worktree prune
    if [[ $result -eq 0 ]]; then
        test_pass
    else
        test_fail "wt prune should work"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: Passthrough
# ============================================================================

test_wt_passthrough_works() {
    test_case "wt passthrough to git worktree"
    create_test_repo

    # Unknown command should passthrough
    local output=$(wt lock --help 2>&1)

    # Should show git worktree lock help (or error from git)
    if [[ "$output" == *"worktree"* || "$output" == *"lock"* ]]; then
        test_pass
    else
        test_fail "Expected passthrough to git worktree"
    fi
    cleanup_test_repo
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "WT (Worktree) Dispatcher Tests"

    setup

    echo "${YELLOW}── wt help ──${RESET}"
    test_wt_help_shows_output
    test_wt_help_shows_commands
    test_wt_help_shows_most_common
    test_wt_help_shows_configuration
    test_wt_help_shows_passthrough_tip

    echo ""
    echo "${YELLOW}── wt list ──${RESET}"
    test_wt_list_works_in_repo
    test_wt_list_alias_works

    echo ""
    echo "${YELLOW}── wt create ──${RESET}"
    test_wt_create_requires_branch
    test_wt_create_shows_usage
    test_wt_create_requires_git_repo

    echo ""
    echo "${YELLOW}── wt move ──${RESET}"
    test_wt_move_rejects_main
    test_wt_move_rejects_dev

    echo ""
    echo "${YELLOW}── wt remove ──${RESET}"
    test_wt_remove_requires_path
    test_wt_remove_shows_worktrees

    echo ""
    echo "${YELLOW}── wt clean ──${RESET}"
    test_wt_clean_works
    test_wt_prune_alias_works

    echo ""
    echo "${YELLOW}── Passthrough ──${RESET}"
    test_wt_passthrough_works

    test_suite_end
    exit $?
}

main "$@"
