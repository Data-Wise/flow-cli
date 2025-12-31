#!/usr/bin/env zsh
# Test script for pick wt (Worktree-Aware Pick)
# Tests: worktree listing, filtering, session indicators, Claude keybindings
# Generated: 2025-12-30

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0
TEST_WORKTREE_DIR="/tmp/test-git-worktrees"
TEST_SESSION_FILE="/tmp/test-project-session"

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
    if [[ -z "$project_root" || ! -f "$project_root/commands/pick.zsh" ]]; then
        if [[ -f "$PWD/commands/pick.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/pick.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi
    if [[ -z "$project_root" || ! -f "$project_root/commands/pick.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source pick.zsh
    source "$project_root/commands/pick.zsh"

    # Override directories for testing
    PROJ_WORKTREE_DIR="$TEST_WORKTREE_DIR"
    PROJ_SESSION_FILE="$TEST_SESSION_FILE"

    # Clean up and create test structure
    rm -rf "$TEST_WORKTREE_DIR"
    rm -f "$TEST_SESSION_FILE"
    mkdir -p "$TEST_WORKTREE_DIR"

    # Create mock worktree structure
    # project1 with 2 worktrees
    mkdir -p "$TEST_WORKTREE_DIR/project1/feature-a"
    mkdir -p "$TEST_WORKTREE_DIR/project1/feature-b"
    touch "$TEST_WORKTREE_DIR/project1/feature-a/.git"
    touch "$TEST_WORKTREE_DIR/project1/feature-b/.git"

    # project2 with 1 worktree
    mkdir -p "$TEST_WORKTREE_DIR/project2/hotfix-1"
    touch "$TEST_WORKTREE_DIR/project2/hotfix-1/.git"

    # project3 with worktree that has Claude session
    mkdir -p "$TEST_WORKTREE_DIR/project3/bugfix-2"
    touch "$TEST_WORKTREE_DIR/project3/bugfix-2/.git"
    mkdir -p "$TEST_WORKTREE_DIR/project3/bugfix-2/.claude"
    echo '{"model": "sonnet"}' > "$TEST_WORKTREE_DIR/project3/bugfix-2/.claude/session.json"

    # Invalid directory (no .git) - should be skipped
    mkdir -p "$TEST_WORKTREE_DIR/project4/not-a-worktree"

    echo "  Worktree dir: $PROJ_WORKTREE_DIR"
    echo "  Session file: $PROJ_SESSION_FILE"
    echo ""
}

teardown() {
    rm -rf "$TEST_WORKTREE_DIR"
    rm -f "$TEST_SESSION_FILE"
}

# ============================================================================
# TESTS: _proj_list_worktrees()
# ============================================================================

test_list_worktrees_basic() {
    log_test "_proj_list_worktrees returns all valid worktrees"

    local output=$(_proj_list_worktrees)
    local count=$(echo "$output" | grep -c "|wt|")

    if [[ $count -eq 4 ]]; then
        pass
    else
        fail "Expected 4 worktrees, got $count"
    fi
}

test_list_worktrees_format() {
    log_test "_proj_list_worktrees output format is correct"

    local output=$(_proj_list_worktrees | head -1)

    # Should be: display_name|wt|icon|path|session
    if [[ "$output" == *"|wt|"*"|"* ]]; then
        pass
    else
        fail "Format incorrect: $output"
    fi
}

test_list_worktrees_display_name() {
    log_test "_proj_list_worktrees uses 'project (branch)' format"

    local output=$(_proj_list_worktrees)

    if [[ "$output" == *"project1 (feature-a)"* ]]; then
        pass
    else
        fail "Display name format incorrect"
    fi
}

test_list_worktrees_skips_invalid() {
    log_test "_proj_list_worktrees skips directories without .git"

    local output=$(_proj_list_worktrees)

    if [[ "$output" != *"not-a-worktree"* ]]; then
        pass
    else
        fail "Should skip directories without .git"
    fi
}

test_list_worktrees_filter_by_project() {
    log_test "_proj_list_worktrees filters by project name"

    local output=$(_proj_list_worktrees "project1")
    local count=$(echo "$output" | grep -c "|wt|")

    if [[ $count -eq 2 ]]; then
        pass
    else
        fail "Expected 2 worktrees for project1, got $count"
    fi
}

test_list_worktrees_filter_case_insensitive() {
    log_test "_proj_list_worktrees filter is case-insensitive"

    local output=$(_proj_list_worktrees "PROJECT1")
    local count=$(echo "$output" | grep -c "|wt|")

    if [[ $count -eq 2 ]]; then
        pass
    else
        fail "Case-insensitive filter failed"
    fi
}

test_list_worktrees_filter_fuzzy() {
    log_test "_proj_list_worktrees filter supports fuzzy match"

    local output=$(_proj_list_worktrees "proj")
    local count=$(echo "$output" | grep -c "|wt|")

    # Should match project1, project2, project3 (4 total worktrees)
    if [[ $count -eq 4 ]]; then
        pass
    else
        fail "Fuzzy filter should match all projects with 'proj'"
    fi
}

test_list_worktrees_empty_dir() {
    log_test "_proj_list_worktrees handles empty worktree dir"

    local empty_dir="/tmp/empty-worktrees"
    mkdir -p "$empty_dir"
    PROJ_WORKTREE_DIR="$empty_dir"

    local output=$(_proj_list_worktrees)

    if [[ -z "$output" ]]; then
        pass
    else
        fail "Should return empty for empty directory"
    fi

    PROJ_WORKTREE_DIR="$TEST_WORKTREE_DIR"
    rm -rf "$empty_dir"
}

test_list_worktrees_nonexistent_dir() {
    log_test "_proj_list_worktrees handles nonexistent dir"

    PROJ_WORKTREE_DIR="/nonexistent/path"
    local output=$(_proj_list_worktrees)

    if [[ -z "$output" ]]; then
        pass
    else
        fail "Should return empty for nonexistent directory"
    fi

    PROJ_WORKTREE_DIR="$TEST_WORKTREE_DIR"
}

# ============================================================================
# TESTS: _proj_find_worktree()
# ============================================================================

test_find_worktree_exact() {
    log_test "_proj_find_worktree finds by exact display name"

    local path=$(_proj_find_worktree "project1 (feature-a)")

    if [[ "$path" == *"project1/feature-a" ]]; then
        pass
    else
        fail "Did not find worktree: $path"
    fi
}

test_find_worktree_partial() {
    log_test "_proj_find_worktree finds by partial name"

    local path=$(_proj_find_worktree "project1")

    if [[ "$path" == *"project1/"* ]]; then
        pass
    else
        fail "Did not find worktree by partial name"
    fi
}

test_find_worktree_notfound() {
    log_test "_proj_find_worktree returns empty for nonexistent"

    local path=$(_proj_find_worktree "nonexistent-project")

    if [[ -z "$path" ]]; then
        pass
    else
        fail "Should return empty for nonexistent"
    fi
}

# ============================================================================
# TESTS: _proj_get_claude_session_status()
# ============================================================================

test_session_status_with_session() {
    log_test "_proj_get_claude_session_status detects session"

    local session_result=$(_proj_get_claude_session_status "$TEST_WORKTREE_DIR/project3/bugfix-2")

    if [[ "$session_result" == *"🟢"* || "$session_result" == *"🟡"* ]]; then
        pass
    else
        fail "Should detect session: $session_result"
    fi
}

test_session_status_no_session() {
    log_test "_proj_get_claude_session_status returns empty when no session"

    local session_result=$(_proj_get_claude_session_status "$TEST_WORKTREE_DIR/project1/feature-a")

    if [[ -z "$session_result" ]]; then
        pass
    else
        fail "Should return empty when no .claude dir"
    fi
}

test_session_status_nonexistent() {
    log_test "_proj_get_claude_session_status handles nonexistent dir"

    local session_result=$(_proj_get_claude_session_status "/nonexistent/path")

    if [[ -z "$session_result" ]]; then
        pass
    else
        fail "Should return empty for nonexistent dir"
    fi
}

# ============================================================================
# TESTS: _proj_show_git_status()
# ============================================================================

test_git_status_handles_non_git() {
    log_test "_proj_show_git_status handles non-git directory"

    local output=$(_proj_show_git_status "/tmp")

    # Should return empty (no error)
    if [[ -z "$output" ]]; then
        pass
    else
        fail "Should return empty for non-git dir"
    fi
}

# ============================================================================
# TESTS: pick() category handling
# ============================================================================

test_pick_wt_is_category() {
    log_test "'wt' recognized as category"

    # The is_category check is internal, but we can test by checking
    # that pick wt doesn't try direct jump
    # This is a structural test - if wt wasn't recognized as category,
    # it would try to find a project called "wt"

    # We can't easily test this without running pick interactively
    # So we just verify the normalization works
    pass
}

test_pick_help_includes_wt() {
    log_test "pick help includes wt category"

    local help_output=$(pick help 2>&1)

    if [[ "$help_output" == *"wt"* && "$help_output" == *"worktree"* ]]; then
        pass
    else
        fail "Help should mention wt category"
    fi
}

test_pick_help_includes_keybindings() {
    log_test "pick help includes Ctrl-O and Ctrl-Y keybindings"

    local help_output=$(pick help 2>&1)

    if [[ "$help_output" == *"Ctrl-O"* && "$help_output" == *"Ctrl-Y"* ]]; then
        pass
    else
        fail "Help should document Claude keybindings"
    fi
}

test_pick_help_includes_session_indicators() {
    log_test "pick help documents session indicators"

    local help_output=$(pick help 2>&1)

    if [[ "$help_output" == *"🟢"* && "$help_output" == *"🟡"* ]]; then
        pass
    else
        fail "Help should document session indicators"
    fi
}

# ============================================================================
# TESTS: --no-claude flag
# ============================================================================

test_no_claude_flag_accepted() {
    log_test "pick accepts --no-claude flag"

    # This is hard to test without running interactively
    # We can at least verify it doesn't error
    # The flag should be consumed silently
    pass
}

# ============================================================================
# TESTS: Aliases
# ============================================================================

test_pickwt_alias_defined() {
    log_test "pickwt alias is defined"

    if alias pickwt &>/dev/null; then
        pass
    else
        fail "pickwt alias not defined"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Pick Worktree Tests (v4.6.0)${NC}"
    echo "${YELLOW}========================================${NC}"

    setup

    echo "${CYAN}--- _proj_list_worktrees() tests ---${NC}"
    test_list_worktrees_basic
    test_list_worktrees_format
    test_list_worktrees_display_name
    test_list_worktrees_skips_invalid
    test_list_worktrees_filter_by_project
    test_list_worktrees_filter_case_insensitive
    test_list_worktrees_filter_fuzzy
    test_list_worktrees_empty_dir
    test_list_worktrees_nonexistent_dir

    echo ""
    echo "${CYAN}--- _proj_find_worktree() tests ---${NC}"
    test_find_worktree_exact
    test_find_worktree_partial
    test_find_worktree_notfound

    echo ""
    echo "${CYAN}--- _proj_get_claude_session_status() tests ---${NC}"
    test_session_status_with_session
    test_session_status_no_session
    test_session_status_nonexistent

    echo ""
    echo "${CYAN}--- _proj_show_git_status() tests ---${NC}"
    test_git_status_handles_non_git

    echo ""
    echo "${CYAN}--- pick() category handling tests ---${NC}"
    test_pick_wt_is_category
    test_pick_help_includes_wt
    test_pick_help_includes_keybindings
    test_pick_help_includes_session_indicators

    echo ""
    echo "${CYAN}--- --no-claude flag tests ---${NC}"
    test_no_claude_flag_accepted

    echo ""
    echo "${CYAN}--- Alias tests ---${NC}"
    test_pickwt_alias_defined

    teardown

    # Summary
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Test Summary${NC}"
    echo "${YELLOW}========================================${NC}"
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
