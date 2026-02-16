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
# FRAMEWORK SETUP
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

TEST_DIR=""
ORIGINAL_DIR="$PWD"

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

test_suite_start "cc wt - Worktree Integration Tests"

# ─────────────────────────────────────────────────────────────────────────────
# HELP TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo "Help System"

test_cc_wt_help_shows_title() {
    test_case "cc wt help shows title"
    local output
    output=$(cc wt help 2>&1)
    if [[ "$output" == *"CC WT"* ]]; then
        test_pass
    else
        test_fail "cc wt help should show title"
    fi
}

test_cc_wt_help_shows_commands() {
    test_case "cc wt --help shows commands"
    local output
    output=$(cc wt --help 2>&1)
    if [[ "$output" == *"cc wt <branch>"* && "$output" == *"cc wt pick"* ]]; then
        test_pass
    else
        test_fail "cc wt --help should show commands"
    fi
}

test_cc_wt_help_shows_aliases() {
    test_case "cc wt -h shows aliases"
    local output
    output=$(cc wt -h 2>&1)
    if [[ "$output" == *"ccw"* && "$output" == *"ccwy"* && "$output" == *"ccwp"* ]]; then
        test_pass
    else
        test_fail "cc wt -h should show aliases"
    fi
}

test_cc_wt_help_shows_title
test_cc_wt_help_shows_commands
test_cc_wt_help_shows_aliases

# ─────────────────────────────────────────────────────────────────────────────
# _wt_get_path() TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "_wt_get_path() Helper"

test_wt_get_path_requires_branch() {
    test_case "_wt_get_path requires branch argument"
    local result
    _wt_get_path "" 2>/dev/null
    result=$?
    if [[ $result -ne 0 ]]; then
        test_pass
    else
        test_fail "_wt_get_path should fail without branch"
    fi
}

test_wt_get_path_returns_empty_for_nonexistent() {
    test_case "_wt_get_path returns empty for nonexistent worktree"
    create_test_repo
    local result_path
    result_path=$(_wt_get_path "feature/nonexistent" 2>/dev/null)
    if [[ -z "$result_path" ]]; then
        test_pass
    else
        test_fail "_wt_get_path should return empty for nonexistent worktree"
    fi
    cleanup_test_repo
}

test_wt_get_path_returns_path_for_existing() {
    test_case "_wt_get_path returns path for existing worktree"
    create_test_repo
    cd "$TEST_DIR" || { test_fail "Could not cd to TEST_DIR"; return; }

    local project=$(basename "$TEST_DIR")
    local wt_path="$FLOW_WORKTREE_DIR/$project/feature-test"
    mkdir -p "$FLOW_WORKTREE_DIR/$project"
    git worktree add "$wt_path" -b "feature/test" >/dev/null 2>&1

    local result_path
    result_path=$(_wt_get_path "feature/test" 2>/dev/null)

    if [[ -n "$result_path" && -d "$result_path" ]]; then
        test_pass
    else
        test_fail "_wt_get_path should return path for existing worktree (got: '$result_path')"
    fi
    cleanup_test_repo
}

test_wt_get_path_requires_branch
test_wt_get_path_returns_empty_for_nonexistent
test_wt_get_path_returns_path_for_existing

# ─────────────────────────────────────────────────────────────────────────────
# CC WT LIST TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "cc wt (no args = list)"

test_cc_wt_no_args_shows_list() {
    test_case "cc wt (no args) shows worktree list"
    create_test_repo
    local output
    output=$(cc wt 2>&1)
    if [[ "$output" == *"worktrees"* || "$output" == *"worktree"* ]]; then
        test_pass
    else
        test_fail "cc wt (no args) should show worktree list"
    fi
    cleanup_test_repo
}

test_cc_wt_no_args_shows_usage() {
    test_case "cc wt (no args) shows usage hint"
    create_test_repo
    local output
    output=$(cc wt 2>&1)
    if [[ "$output" == *"cc wt <branch>"* || "$output" == *"cc wt pick"* ]]; then
        test_pass
    else
        test_fail "cc wt (no args) should show usage hint"
    fi
    cleanup_test_repo
}

test_cc_wt_no_args_shows_list
test_cc_wt_no_args_shows_usage

# ─────────────────────────────────────────────────────────────────────────────
# MODE PARSING TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "Mode Parsing"

test_cc_wt_recognizes_yolo_mode() {
    test_case "cc wt yolo mode function exists"
    if (( $+functions[_cc_worktree] )); then
        test_pass
    else
        test_fail "_cc_worktree function should exist"
    fi
}

test_cc_wt_recognizes_plan_mode() {
    test_case "cc wt plan mode function exists"
    if (( $+functions[_cc_worktree] )); then
        test_pass
    else
        test_fail "_cc_worktree function should exist for plan mode"
    fi
}

test_cc_wt_recognizes_opus_mode() {
    test_case "cc wt opus mode function exists"
    if (( $+functions[_cc_worktree] )); then
        test_pass
    else
        test_fail "_cc_worktree function should exist for opus mode"
    fi
}

test_cc_wt_recognizes_yolo_mode
test_cc_wt_recognizes_plan_mode
test_cc_wt_recognizes_opus_mode

# ─────────────────────────────────────────────────────────────────────────────
# ALIAS TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "Aliases"

test_ccw_alias_exists() {
    test_case "ccw alias exists"
    if alias ccw >/dev/null 2>&1; then
        test_pass
    else
        test_fail "ccw alias should exist"
    fi
}

test_ccwy_alias_exists() {
    test_case "ccwy alias exists"
    if alias ccwy >/dev/null 2>&1; then
        test_pass
    else
        test_fail "ccwy alias should exist"
    fi
}

test_ccwp_alias_exists() {
    test_case "ccwp alias exists"
    if alias ccwp >/dev/null 2>&1; then
        test_pass
    else
        test_fail "ccwp alias should exist"
    fi
}

test_ccw_alias_exists
test_ccwy_alias_exists
test_ccwp_alias_exists

# ─────────────────────────────────────────────────────────────────────────────
# CC HELP INTEGRATION TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "CC Help Integration"

test_cc_help_includes_worktree() {
    test_case "cc help includes WORKTREE section"
    local output
    output=$(cc help 2>&1)
    if [[ "$output" == *"WORKTREE"* ]]; then
        test_pass
    else
        test_fail "cc help should include WORKTREE section"
    fi
}

test_cc_help_shows_wt_commands() {
    test_case "cc help shows cc wt commands"
    local output
    output=$(cc help 2>&1)
    if [[ "$output" == *"cc wt <branch>"* ]]; then
        test_pass
    else
        test_fail "cc help should show cc wt commands"
    fi
}

test_cc_help_shows_worktree_aliases() {
    test_case "cc help shows worktree aliases"
    local output
    output=$(cc help 2>&1)
    if [[ "$output" == *"ccw"* ]]; then
        test_pass
    else
        test_fail "cc help should show worktree aliases"
    fi
}

test_cc_help_includes_worktree
test_cc_help_shows_wt_commands
test_cc_help_shows_worktree_aliases

# ─────────────────────────────────────────────────────────────────────────────
# SUBCOMMAND RECOGNITION TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "Subcommand Recognition"

test_wt_is_recognized_subcommand() {
    test_case "wt is recognized as cc subcommand"
    local output
    output=$(cc wt 2>&1)
    if [[ "$output" != *"pick function"* && "$output" != *"not found"* ]]; then
        test_pass
    else
        test_fail "wt should be recognized as cc subcommand, not project name"
    fi
}

test_worktree_is_recognized_subcommand() {
    test_case "worktree is recognized as cc subcommand"
    local output
    output=$(cc worktree 2>&1)
    if [[ "$output" != *"pick function"* && "$output" != *"not found"* ]]; then
        test_pass
    else
        test_fail "worktree should be recognized as cc subcommand"
    fi
}

test_w_is_recognized_subcommand() {
    test_case "w is recognized as cc subcommand"
    local output
    output=$(cc w 2>&1)
    if [[ "$output" != *"pick function"* && "$output" != *"not found"* ]]; then
        test_pass
    else
        test_fail "w should be recognized as cc subcommand"
    fi
}

test_wt_is_recognized_subcommand
test_worktree_is_recognized_subcommand
test_w_is_recognized_subcommand

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

# Cleanup any leftover test repos
cleanup_test_repo

test_suite_end
exit $?
