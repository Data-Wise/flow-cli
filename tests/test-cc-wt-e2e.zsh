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

# ─────────────────────────────────────────────────────────────────────────────
# TEST UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="${0:A:h}"
PASSED=0
FAILED=0
SKIPPED=0
TEST_DIR=""
ORIGINAL_DIR="$PWD"

# Colors
_C_GREEN='\033[32m'
_C_RED='\033[31m'
_C_YELLOW='\033[33m'
_C_BLUE='\033[34m'
_C_DIM='\033[2m'
_C_BOLD='\033[1m'
_C_NC='\033[0m'

pass() {
    echo -e "  ${_C_GREEN}✓${_C_NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${_C_RED}✗${_C_NC} $1"
    [[ -n "$2" ]] && echo -e "    ${_C_DIM}$2${_C_NC}"
    ((FAILED++))
}

skip() {
    echo -e "  ${_C_YELLOW}○${_C_NC} $1 (skipped)"
    ((SKIPPED++))
}

info() {
    echo -e "  ${_C_DIM}ℹ $1${_C_NC}"
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

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE THE PLUGIN
# ─────────────────────────────────────────────────────────────────────────────

source "${SCRIPT_DIR}/../flow.plugin.zsh"

# ─────────────────────────────────────────────────────────────────────────────
# E2E TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_BOLD}╔═══════════════════════════════════════════════════════════╗${_C_NC}"
echo -e "${_C_BOLD}║ ${_C_BLUE}cc wt E2E Tests${_C_NC}${_C_BOLD}                                          ║${_C_NC}"
echo -e "${_C_BOLD}╚═══════════════════════════════════════════════════════════╝${_C_NC}\n"

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Full workflow - create worktree via cc wt
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_C_DIM}Full Workflow: Create Worktree${_C_NC}"

test_cc_wt_creates_worktree_if_not_exists() {
    create_test_repo

    # Mock claude command to just echo instead of running
    claude() { echo "MOCK_CLAUDE_CALLED with args: $*"; }

    # Capture output (won't actually launch claude due to mock)
    local output
    output=$(_cc_worktree "feature/new-feature" 2>&1)

    # Check if worktree was created
    local wt_path="$FLOW_WORKTREE_DIR/$(basename $TEST_DIR)/feature-new-feature"
    if [[ -d "$wt_path" ]]; then
        pass "cc wt creates worktree when it doesn't exist"
    else
        fail "cc wt should create worktree" "Expected: $wt_path"
    fi

    # Check the worktree is a valid git worktree
    if git -C "$wt_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        pass "Created worktree is a valid git worktree"
    else
        fail "Created worktree should be valid git repo"
    fi

    # Check the branch exists
    if git -C "$TEST_DIR" show-ref --verify --quiet "refs/heads/feature/new-feature"; then
        pass "Feature branch was created"
    else
        fail "Feature branch should be created"
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
    if [[ -f "$wt_path/.test-marker" ]]; then
        pass "cc wt uses existing worktree (doesn't recreate)"
    else
        fail "cc wt should use existing worktree, not recreate"
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

    if [[ -d "$expected_path" ]]; then
        pass "Worktree path handles nested branch names (slashes → dashes)"
    else
        fail "Should create worktree for nested branch" "Expected: $expected_path"
    fi

    cleanup_test_repo
}

test_cc_wt_creates_worktree_if_not_exists
test_cc_wt_uses_existing_worktree
test_cc_wt_creates_worktree_dir_structure

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Mode chaining
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Mode Chaining${_C_NC}"

test_cc_wt_yolo_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "yolo" "feature/yolo-test" 2>&1

    if [[ "$captured_args" == *"--dangerously-skip-permissions"* ]]; then
        pass "cc wt yolo passes --dangerously-skip-permissions"
    else
        fail "cc wt yolo should pass permission skip flag" "Got: $captured_args"
    fi

    cleanup_test_repo
}

test_cc_wt_plan_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "plan" "feature/plan-test" 2>&1

    if [[ "$captured_args" == *"--permission-mode"* && "$captured_args" == *"plan"* ]]; then
        pass "cc wt plan passes --permission-mode plan"
    else
        fail "cc wt plan should pass plan mode flag" "Got: $captured_args"
    fi

    cleanup_test_repo
}

test_cc_wt_opus_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "opus" "feature/opus-test" 2>&1

    if [[ "$captured_args" == *"--model"* && "$captured_args" == *"opus"* ]]; then
        pass "cc wt opus passes --model opus"
    else
        fail "cc wt opus should pass opus model flag" "Got: $captured_args"
    fi

    cleanup_test_repo
}

test_cc_wt_haiku_passes_correct_flags() {
    create_test_repo

    local captured_args=""
    claude() { captured_args="$*"; }

    _cc_worktree "haiku" "feature/haiku-test" 2>&1

    if [[ "$captured_args" == *"--model"* && "$captured_args" == *"haiku"* ]]; then
        pass "cc wt haiku passes --model haiku"
    else
        fail "cc wt haiku should pass haiku model flag" "Got: $captured_args"
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

echo -e "\n${_C_DIM}_wt_get_path() E2E${_C_NC}"

test_wt_get_path_returns_correct_path() {
    create_test_repo

    # Create a worktree
    local project=$(basename "$TEST_DIR")
    local expected_path="$FLOW_WORKTREE_DIR/$project/feature-test"
    mkdir -p "$FLOW_WORKTREE_DIR/$project"
    git worktree add "$expected_path" -b "feature/test" >/dev/null 2>&1

    local result_path
    result_path=$(_wt_get_path "feature/test")

    if [[ "$result_path" == "$expected_path" ]]; then
        pass "_wt_get_path returns exact expected path"
    else
        fail "_wt_get_path path mismatch" "Expected: $expected_path, Got: $result_path"
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

    if [[ "$result_path" == "$expected_path" ]]; then
        pass "_wt_get_path converts slashes to dashes correctly"
    else
        fail "_wt_get_path slash conversion failed" "Expected: $expected_path, Got: $result_path"
    fi

    cleanup_test_repo
}

test_wt_get_path_returns_correct_path
test_wt_get_path_handles_slash_conversion

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Error handling
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Error Handling${_C_NC}"

test_cc_wt_handles_non_git_directory() {
    local non_git_dir=$(mktemp -d)
    cd "$non_git_dir"

    local output
    output=$(_cc_worktree "feature/test" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]] || [[ "$output" == *"git"* ]] || [[ "$output" == *"repository"* ]] || [[ "$output" == *"Failed"* ]]; then
        pass "cc wt handles non-git directory gracefully"
    else
        fail "cc wt should fail in non-git directory" "Output: $output"
    fi

    cd "$ORIGINAL_DIR"
    command rm -rf "$non_git_dir"
}

test_cc_wt_no_branch_shows_list() {
    create_test_repo

    local output
    output=$(_cc_worktree 2>&1)

    # Should show worktree list and usage hint
    if [[ "$output" == *"worktree"* ]] || [[ "$output" == *"Usage"* ]] || [[ "$output" == *"cc wt"* ]]; then
        pass "cc wt with no args shows worktree list/usage"
    else
        fail "cc wt with no args should show list/usage" "Output: $output"
    fi

    cleanup_test_repo
}

test_cc_wt_handles_non_git_directory
test_cc_wt_no_branch_shows_list

# ─────────────────────────────────────────────────────────────────────────────
# TEST: Alias integration
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Alias Integration${_C_NC}"

test_ccw_alias_expands_correctly() {
    local alias_def=$(alias ccw 2>/dev/null)
    if [[ "$alias_def" == *"cc wt"* ]]; then
        pass "ccw alias expands to 'cc wt'"
    else
        fail "ccw should expand to 'cc wt'" "Got: $alias_def"
    fi
}

test_ccwy_alias_expands_correctly() {
    local alias_def=$(alias ccwy 2>/dev/null)
    if [[ "$alias_def" == *"cc wt yolo"* ]]; then
        pass "ccwy alias expands to 'cc wt yolo'"
    else
        fail "ccwy should expand to 'cc wt yolo'" "Got: $alias_def"
    fi
}

test_ccwp_alias_expands_correctly() {
    local alias_def=$(alias ccwp 2>/dev/null)
    if [[ "$alias_def" == *"cc wt pick"* ]]; then
        pass "ccwp alias expands to 'cc wt pick'"
    else
        fail "ccwp should expand to 'cc wt pick'" "Got: $alias_def"
    fi
}

test_ccw_alias_expands_correctly
test_ccwy_alias_expands_correctly
test_ccwp_alias_expands_correctly

# ─────────────────────────────────────────────────────────────────────────────
# TEST: cc dispatcher routing
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Dispatcher Routing${_C_NC}"

test_cc_routes_wt_correctly() {
    create_test_repo

    # Mock _cc_worktree to verify it's called
    local worktree_called=false
    _cc_worktree() { worktree_called=true; }

    cc wt 2>/dev/null

    if [[ "$worktree_called" == "true" ]]; then
        pass "cc routes 'wt' to _cc_worktree"
    else
        fail "cc should route 'wt' to _cc_worktree"
    fi

    cleanup_test_repo
}

test_cc_routes_worktree_correctly() {
    create_test_repo

    local worktree_called=false
    _cc_worktree() { worktree_called=true; }

    cc worktree 2>/dev/null

    if [[ "$worktree_called" == "true" ]]; then
        pass "cc routes 'worktree' to _cc_worktree"
    else
        fail "cc should route 'worktree' to _cc_worktree"
    fi

    cleanup_test_repo
}

test_cc_routes_w_correctly() {
    create_test_repo

    local worktree_called=false
    _cc_worktree() { worktree_called=true; }

    cc w 2>/dev/null

    if [[ "$worktree_called" == "true" ]]; then
        pass "cc routes 'w' to _cc_worktree"
    else
        fail "cc should route 'w' to _cc_worktree"
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

echo -e "\n${_C_BOLD}╔═══════════════════════════════════════════════════════════╗${_C_NC}"
echo -e "${_C_BOLD}║${_C_NC} ${_C_GREEN}Passed: $PASSED${_C_NC}  ${_C_RED}Failed: $FAILED${_C_NC}  ${_C_YELLOW}Skipped: $SKIPPED${_C_NC}            ${_C_BOLD}║${_C_NC}"
echo -e "${_C_BOLD}╚═══════════════════════════════════════════════════════════╝${_C_NC}\n"

# Exit with failure if any tests failed
[[ $FAILED -eq 0 ]]
