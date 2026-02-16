#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# E2E Tests for cc wt (Worktree + Claude Integration)
# ══════════════════════════════════════════════════════════════════════════════
#
# Run: zsh tests/test-cc-wt-e2e.zsh
#
# These tests create REAL worktrees and verify the full workflow.
# They do NOT launch Claude (that would be truly e2e but impractical).
#
# ══════════════════════════════════════════════════════════════════════════════

setopt local_options no_monitor

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# ─────────────────────────────────────────────────────────────────────────────
# TEST HELPERS
# ─────────────────────────────────────────────────────────────────────────────

TEST_DIR=""
ORIGINAL_DIR="$PWD"

info() {
    echo "    ℹ $1"
}

# Create a fresh test repository with proper git setup
create_test_repo() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || return 1
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test User"
    # Create initial commit (required for worktrees)
    echo "# Test Project" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
    # Set FLOW_WORKTREE_DIR for tests
    export FLOW_WORKTREE_DIR="$TEST_DIR/.worktrees"
    info "Created test repo at $TEST_DIR"
}

cleanup_test_repo() {
    cd "$ORIGINAL_DIR" || return
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        # Remove all worktrees first (git requirement)
        git -C "$TEST_DIR" worktree list --porcelain 2>/dev/null | \
            grep "^worktree " | cut -d' ' -f2 | \
            while read wt; do
                [[ "$wt" != "$TEST_DIR" ]] && git -C "$TEST_DIR" worktree remove --force "$wt" 2>/dev/null
            done
        command rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
    TEST_DIR=""
}
trap cleanup_test_repo EXIT

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE THE PLUGIN
# ─────────────────────────────────────────────────────────────────────────────

source "${SCRIPT_DIR}/../flow.plugin.zsh"

# ─────────────────────────────────────────────────────────────────────────────
# E2E TESTS
# ─────────────────────────────────────────────────────────────────────────────

test_suite_start "cc wt E2E Tests"

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Full workflow - create worktree via cc wt
# ─────────────────────────────────────────────────────────────────────────────

test_cc_wt_creates_worktree_if_not_exists() {
    create_test_repo

    # Mock claude command to just echo instead of running
    claude() { echo "MOCK_CLAUDE_CALLED with args: $*"; }

    # Capture output (won't actually launch claude due to mock)
    local output
    output=$(_cc_worktree "feature/new-feature" 2>&1)

    # Check if worktree was created
    local wt_path="$FLOW_WORKTREE_DIR/$(basename $TEST_DIR)/feature-new-feature"

    test_case "cc wt creates worktree when it doesn't exist"
    if [[ -d "$wt_path" ]]; then
        test_pass
    else
        test_fail "Expected: $wt_path"
    fi

    # Check the worktree is a valid git worktree
    test_case "Created worktree is a valid git worktree"
    if git -C "$wt_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Created worktree should be valid git repo"
    fi

    # Check the branch exists
    test_case "Feature branch was created"
    if git -C "$TEST_DIR" show-ref --verify --quiet "refs/heads/feature/new-feature"; then
        test_pass
    else
        test_fail "Feature branch should be created"
    fi

    cleanup_test_repo
}

test_cc_wt_uses_existing_worktree() {
    create_test_repo

    # Create worktree manually first
    local project=$(basename "$TEST_DIR")
    local wt_path="$FLOW_WORKTREE_DIR/$project/feature-existing"
    mkdir -p "$FLOW_WORKTREE_DIR/$project"
    git worktree add "$wt_path" -b "feature/existing" >/dev/null 2>&1

    # Add a marker file to the worktree
    echo "marker" > "$wt_path/.test-marker"

    # Mock claude
    claude() { echo "MOCK_CLAUDE"; }

    # Run cc wt - should use existing, not recreate
    _cc_worktree "feature/existing" 2>&1

    # Marker should still exist (worktree wasn't recreated)
    test_case "cc wt uses existing worktree (doesn't recreate)"
    if [[ -f "$wt_path/.test-marker" ]]; then
        test_pass
    else
        test_fail "cc wt should use existing worktree, not recreate"
    fi

    cleanup_test_repo
}

test_cc_wt_creates_worktree_dir_structure() {
    create_test_repo

    # Mock claude
    claude() { echo "MOCK"; }

    _cc_worktree "feature/deeply/nested/branch" 2>&1

    local project=$(basename "$TEST_DIR")
    local expected_path="$FLOW_WORKTREE_DIR/$project/feature-deeply-nested-branch"

    test_case "Worktree path handles nested branch names (slashes to dashes)"
    if [[ -d "$expected_path" ]]; then
        test_pass
    else
        test_fail "Expected: $expected_path"
    fi

    cleanup_test_repo
}

test_cc_wt_creates_worktree_if_not_exists
test_cc_wt_uses_existing_worktree
test_cc_wt_creates_worktree_dir_structure

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Mode chaining
# ─────────────────────────────────────────────────────────────────────────────

test_cc_wt_yolo_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "yolo" "feature/yolo-test" 2>&1

    test_case "cc wt yolo passes --dangerously-skip-permissions"
    if [[ "$captured_args" == *"--dangerously-skip-permissions"* ]]; then
        test_pass
    else
        test_fail "Got: $captured_args"
    fi

    cleanup_test_repo
}

test_cc_wt_plan_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "plan" "feature/plan-test" 2>&1

    test_case "cc wt plan passes --permission-mode plan"
    if [[ "$captured_args" == *"--permission-mode"* && "$captured_args" == *"plan"* ]]; then
        test_pass
    else
        test_fail "Got: $captured_args"
    fi

    cleanup_test_repo
}

test_cc_wt_opus_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "opus" "feature/opus-test" 2>&1

    test_case "cc wt opus passes --model opus"
    if [[ "$captured_args" == *"--model"* && "$captured_args" == *"opus"* ]]; then
        test_pass
    else
        test_fail "Got: $captured_args"
    fi

    cleanup_test_repo
}

test_cc_wt_haiku_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "haiku" "feature/haiku-test" 2>&1

    test_case "cc wt haiku passes --model haiku"
    if [[ "$captured_args" == *"--model"* && "$captured_args" == *"haiku"* ]]; then
        test_pass
    else
        test_fail "Got: $captured_args"
    fi

    cleanup_test_repo
}

test_cc_wt_yolo_passes_correct_flags
test_cc_wt_plan_passes_correct_flags
test_cc_wt_opus_passes_correct_flags
test_cc_wt_haiku_passes_correct_flags

# ─────────────────────────────────────────────────────────────────────────────
# TEST: _wt_get_path helper function
# ─────────────────────────────────────────────────────────────────────────────

test_wt_get_path_returns_correct_path() {
    create_test_repo

    # Create a worktree
    local project=$(basename "$TEST_DIR")
    local expected_path="$FLOW_WORKTREE_DIR/$project/feature-test"
    mkdir -p "$FLOW_WORKTREE_DIR/$project"
    git worktree add "$expected_path" -b "feature/test" >/dev/null 2>&1

    local result_path
    result_path=$(_wt_get_path "feature/test")

    test_case "_wt_get_path returns exact expected path"
    if [[ "$result_path" == "$expected_path" ]]; then
        test_pass
    else
        test_fail "Expected: $expected_path, Got: $result_path"
    fi

    cleanup_test_repo
}

test_wt_get_path_handles_slash_conversion() {
    create_test_repo

    local project=$(basename "$TEST_DIR")
    local expected_path="$FLOW_WORKTREE_DIR/$project/feature-multi-part-name"
    mkdir -p "$FLOW_WORKTREE_DIR/$project"
    git worktree add "$expected_path" -b "feature/multi/part/name" >/dev/null 2>&1

    local result_path
    result_path=$(_wt_get_path "feature/multi/part/name")

    test_case "_wt_get_path converts slashes to dashes correctly"
    if [[ "$result_path" == "$expected_path" ]]; then
        test_pass
    else
        test_fail "Expected: $expected_path, Got: $result_path"
    fi

    cleanup_test_repo
}

test_wt_get_path_returns_correct_path
test_wt_get_path_handles_slash_conversion

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Error handling
# ─────────────────────────────────────────────────────────────────────────────

test_cc_wt_handles_non_git_directory() {
    local non_git_dir=$(mktemp -d)
    cd "$non_git_dir"

    local output
    output=$(_cc_worktree "feature/test" 2>&1)
    local exit_code=$?

    test_case "cc wt handles non-git directory gracefully"
    if [[ $exit_code -ne 0 ]] || [[ "$output" == *"git"* ]] || [[ "$output" == *"repository"* ]] || [[ "$output" == *"Failed"* ]]; then
        test_pass
    else
        test_fail "Output: $output"
    fi

    cd "$ORIGINAL_DIR"
    command rm -rf "$non_git_dir"
}

test_cc_wt_no_branch_shows_list() {
    create_test_repo

    local output
    output=$(_cc_worktree 2>&1)

    # Should show worktree list and usage hint
    test_case "cc wt with no args shows worktree list/usage"
    if [[ "$output" == *"worktree"* ]] || [[ "$output" == *"Usage"* ]] || [[ "$output" == *"cc wt"* ]]; then
        test_pass
    else
        test_fail "Output: $output"
    fi

    cleanup_test_repo
}

test_cc_wt_handles_non_git_directory
test_cc_wt_no_branch_shows_list

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Alias integration
# ─────────────────────────────────────────────────────────────────────────────

test_ccw_alias_expands_correctly() {
    local alias_def=$(alias ccw 2>/dev/null)

    test_case "ccw alias expands to 'cc wt'"
    if [[ "$alias_def" == *"cc wt"* ]]; then
        test_pass
    else
        test_fail "Got: $alias_def"
    fi
}

test_ccwy_alias_expands_correctly() {
    local alias_def=$(alias ccwy 2>/dev/null)

    test_case "ccwy alias expands to 'cc wt yolo'"
    if [[ "$alias_def" == *"cc wt yolo"* ]]; then
        test_pass
    else
        test_fail "Got: $alias_def"
    fi
}

test_ccwp_alias_expands_correctly() {
    local alias_def=$(alias ccwp 2>/dev/null)

    test_case "ccwp alias expands to 'cc wt pick'"
    if [[ "$alias_def" == *"cc wt pick"* ]]; then
        test_pass
    else
        test_fail "Got: $alias_def"
    fi
}

test_ccw_alias_expands_correctly
test_ccwy_alias_expands_correctly
test_ccwp_alias_expands_correctly

# ─────────────────────────────────────────────────────────────────────────────
# TEST: cc dispatcher routing
# ─────────────────────────────────────────────────────────────────────────────

test_cc_routes_wt_correctly() {
    create_test_repo

    # Mock _cc_worktree to verify it's called
    local worktree_called=false
    _cc_worktree() { worktree_called=true; }

    cc wt 2>/dev/null

    test_case "cc routes 'wt' to _cc_worktree"
    if [[ "$worktree_called" == "true" ]]; then
        test_pass
    else
        test_fail "cc should route 'wt' to _cc_worktree"
    fi

    cleanup_test_repo
}

test_cc_routes_worktree_correctly() {
    create_test_repo

    local worktree_called=false
    _cc_worktree() { worktree_called=true; }

    cc worktree 2>/dev/null

    test_case "cc routes 'worktree' to _cc_worktree"
    if [[ "$worktree_called" == "true" ]]; then
        test_pass
    else
        test_fail "cc should route 'worktree' to _cc_worktree"
    fi

    cleanup_test_repo
}

test_cc_routes_w_correctly() {
    create_test_repo

    local worktree_called=false
    _cc_worktree() { worktree_called=true; }

    cc w 2>/dev/null

    test_case "cc routes 'w' to _cc_worktree"
    if [[ "$worktree_called" == "true" ]]; then
        test_pass
    else
        test_fail "cc should route 'w' to _cc_worktree"
    fi

    cleanup_test_repo
}

test_cc_routes_wt_correctly
test_cc_routes_worktree_correctly
test_cc_routes_w_correctly

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

# Final cleanup
cleanup_test_repo

test_suite_end
exit $?
