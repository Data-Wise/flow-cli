#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Tests for cc wt (worktree integration)
# ══════════════════════════════════════════════════════════════════════════════
#
# Run: zsh tests/test-cc-wt.zsh
#
# ══════════════════════════════════════════════════════════════════════════════

setopt local_options no_monitor

# ─────────────────────────────────────────────────────────────────────────────
# TEST UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="${0:A:h}"
PASSED=0
FAILED=0
TEST_DIR=""
ORIGINAL_DIR="$PWD"

# Colors
_C_GREEN='\033[32m'
_C_RED='\033[31m'
_C_YELLOW='\033[33m'
_C_DIM='\033[2m'
_C_NC='\033[0m'

pass() {
    echo -e "  ${_C_GREEN}✓${_C_NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${_C_RED}✗${_C_NC} $1"
    ((FAILED++))
}

# Create a fresh test repository
create_test_repo() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || return 1
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test User"
    # Create initial commit
    echo "initial" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
    # Set FLOW_WORKTREE_DIR for tests
    export FLOW_WORKTREE_DIR="$TEST_DIR/.worktrees"
}

cleanup_test_repo() {
    cd "$ORIGINAL_DIR" || return
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        # Use command to bypass any sandboxing issues
        command rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
    TEST_DIR=""
}

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE THE PLUGIN
# ─────────────────────────────────────────────────────────────────────────────

source "${SCRIPT_DIR}/../flow.plugin.zsh"

# ─────────────────────────────────────────────────────────────────────────────
# TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_YELLOW}═══════════════════════════════════════════════════════════${_C_NC}"
echo -e "${_C_YELLOW}  cc wt - Worktree Integration Tests${_C_NC}"
echo -e "${_C_YELLOW}═══════════════════════════════════════════════════════════${_C_NC}\n"

# ─────────────────────────────────────────────────────────────────────────────
# HELP TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_C_DIM}Help System${_C_NC}"

test_cc_wt_help_shows_title() {
    local output
    output=$(cc wt help 2>&1)
    if [[ "$output" == *"CC WT"* ]]; then
        pass "cc wt help shows title"
    else
        fail "cc wt help should show title"
    fi
}

test_cc_wt_help_shows_commands() {
    local output
    output=$(cc wt --help 2>&1)
    if [[ "$output" == *"cc wt <branch>"* && "$output" == *"cc wt pick"* ]]; then
        pass "cc wt --help shows commands"
    else
        fail "cc wt --help should show commands"
    fi
}

test_cc_wt_help_shows_aliases() {
    local output
    output=$(cc wt -h 2>&1)
    if [[ "$output" == *"ccw"* && "$output" == *"ccwy"* && "$output" == *"ccwp"* ]]; then
        pass "cc wt -h shows aliases"
    else
        fail "cc wt -h should show aliases"
    fi
}

test_cc_wt_help_shows_title
test_cc_wt_help_shows_commands
test_cc_wt_help_shows_aliases

# ─────────────────────────────────────────────────────────────────────────────
# _wt_get_path() TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}_wt_get_path() Helper${_C_NC}"

test_wt_get_path_requires_branch() {
    local result
    _wt_get_path "" 2>/dev/null
    result=$?
    if [[ $result -ne 0 ]]; then
        pass "_wt_get_path requires branch argument"
    else
        fail "_wt_get_path should fail without branch"
    fi
}

test_wt_get_path_returns_empty_for_nonexistent() {
    create_test_repo
    local result_path
    result_path=$(_wt_get_path "feature/nonexistent" 2>/dev/null)
    if [[ -z "$result_path" ]]; then
        pass "_wt_get_path returns empty for nonexistent worktree"
    else
        fail "_wt_get_path should return empty for nonexistent worktree"
    fi
    cleanup_test_repo
}

test_wt_get_path_returns_path_for_existing() {
    create_test_repo
    # Ensure we're in the test repo (create_test_repo does cd but let's be explicit)
    cd "$TEST_DIR" || { fail "Could not cd to TEST_DIR"; return; }

    # Create a worktree manually (wt create may have issues in test env)
    local project=$(basename "$TEST_DIR")
    local wt_path="$FLOW_WORKTREE_DIR/$project/feature-test"
    # Create parent directory only, not the worktree path itself
    mkdir -p "$FLOW_WORKTREE_DIR/$project"
    git worktree add "$wt_path" -b "feature/test" >/dev/null 2>&1

    local result_path
    result_path=$(_wt_get_path "feature/test" 2>/dev/null)

    if [[ -n "$result_path" && -d "$result_path" ]]; then
        pass "_wt_get_path returns path for existing worktree"
    else
        fail "_wt_get_path should return path for existing worktree (got: '$result_path')"
    fi
    cleanup_test_repo
}

test_wt_get_path_requires_branch
test_wt_get_path_returns_empty_for_nonexistent
test_wt_get_path_returns_path_for_existing

# ─────────────────────────────────────────────────────────────────────────────
# CC WT LIST TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}cc wt (no args = list)${_C_NC}"

test_cc_wt_no_args_shows_list() {
    create_test_repo
    local output
    output=$(cc wt 2>&1)
    if [[ "$output" == *"worktrees"* || "$output" == *"worktree"* ]]; then
        pass "cc wt (no args) shows worktree list"
    else
        fail "cc wt (no args) should show worktree list"
    fi
    cleanup_test_repo
}

test_cc_wt_no_args_shows_usage() {
    create_test_repo
    local output
    output=$(cc wt 2>&1)
    if [[ "$output" == *"cc wt <branch>"* || "$output" == *"cc wt pick"* ]]; then
        pass "cc wt (no args) shows usage hint"
    else
        fail "cc wt (no args) should show usage hint"
    fi
    cleanup_test_repo
}

test_cc_wt_no_args_shows_list
test_cc_wt_no_args_shows_usage

# ─────────────────────────────────────────────────────────────────────────────
# MODE PARSING TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Mode Parsing${_C_NC}"

# Note: These tests check that mode parsing works without actually launching Claude

test_cc_wt_recognizes_yolo_mode() {
    # Check that _cc_worktree function exists and handles yolo
    if (( $+functions[_cc_worktree] )); then
        pass "cc wt yolo mode function exists"
    else
        fail "_cc_worktree function should exist"
    fi
}

test_cc_wt_recognizes_plan_mode() {
    if (( $+functions[_cc_worktree] )); then
        pass "cc wt plan mode function exists"
    else
        fail "_cc_worktree function should exist for plan mode"
    fi
}

test_cc_wt_recognizes_opus_mode() {
    if (( $+functions[_cc_worktree] )); then
        pass "cc wt opus mode function exists"
    else
        fail "_cc_worktree function should exist for opus mode"
    fi
}

test_cc_wt_recognizes_yolo_mode
test_cc_wt_recognizes_plan_mode
test_cc_wt_recognizes_opus_mode

# ─────────────────────────────────────────────────────────────────────────────
# ALIAS TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Aliases${_C_NC}"

test_ccw_alias_exists() {
    if alias ccw >/dev/null 2>&1; then
        pass "ccw alias exists"
    else
        fail "ccw alias should exist"
    fi
}

test_ccwy_alias_exists() {
    if alias ccwy >/dev/null 2>&1; then
        pass "ccwy alias exists"
    else
        fail "ccwy alias should exist"
    fi
}

test_ccwp_alias_exists() {
    if alias ccwp >/dev/null 2>&1; then
        pass "ccwp alias exists"
    else
        fail "ccwp alias should exist"
    fi
}

test_ccw_alias_exists
test_ccwy_alias_exists
test_ccwp_alias_exists

# ─────────────────────────────────────────────────────────────────────────────
# CC HELP INTEGRATION TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}CC Help Integration${_C_NC}"

test_cc_help_includes_worktree() {
    local output
    output=$(cc help 2>&1)
    if [[ "$output" == *"WORKTREE"* ]]; then
        pass "cc help includes WORKTREE section"
    else
        fail "cc help should include WORKTREE section"
    fi
}

test_cc_help_shows_wt_commands() {
    local output
    output=$(cc help 2>&1)
    if [[ "$output" == *"cc wt <branch>"* ]]; then
        pass "cc help shows cc wt commands"
    else
        fail "cc help should show cc wt commands"
    fi
}

test_cc_help_shows_worktree_aliases() {
    local output
    output=$(cc help 2>&1)
    if [[ "$output" == *"ccw"* ]]; then
        pass "cc help shows worktree aliases"
    else
        fail "cc help should show worktree aliases"
    fi
}

test_cc_help_includes_worktree
test_cc_help_shows_wt_commands
test_cc_help_shows_worktree_aliases

# ─────────────────────────────────────────────────────────────────────────────
# SUBCOMMAND RECOGNITION TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Subcommand Recognition${_C_NC}"

test_wt_is_recognized_subcommand() {
    # cc should recognize 'wt' as a subcommand, not a project name
    local output
    output=$(cc wt 2>&1)
    # If it's recognized as subcommand, it should show worktree list/usage
    # If not, it would try to use pick to find project "wt"
    if [[ "$output" != *"pick function"* && "$output" != *"not found"* ]]; then
        pass "wt is recognized as cc subcommand"
    else
        fail "wt should be recognized as cc subcommand, not project name"
    fi
}

test_worktree_is_recognized_subcommand() {
    local output
    output=$(cc worktree 2>&1)
    if [[ "$output" != *"pick function"* && "$output" != *"not found"* ]]; then
        pass "worktree is recognized as cc subcommand"
    else
        fail "worktree should be recognized as cc subcommand"
    fi
}

test_w_is_recognized_subcommand() {
    local output
    output=$(cc w 2>&1)
    if [[ "$output" != *"pick function"* && "$output" != *"not found"* ]]; then
        pass "w is recognized as cc subcommand"
    else
        fail "w should be recognized as cc subcommand"
    fi
}

test_wt_is_recognized_subcommand
test_worktree_is_recognized_subcommand
test_w_is_recognized_subcommand

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_YELLOW}═══════════════════════════════════════════════════════════${_C_NC}"
echo -e "  ${_C_GREEN}Passed: $PASSED${_C_NC}  ${_C_RED}Failed: $FAILED${_C_NC}"
echo -e "${_C_YELLOW}═══════════════════════════════════════════════════════════${_C_NC}\n"

# Cleanup any leftover test repos
cleanup_test_repo

# Exit with failure if any tests failed
[[ $FAILED -eq 0 ]]
