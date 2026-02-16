#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: G Feature Workflow
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Test g dispatcher feature workflow
# Tests: g feature, g promote, g release, workflow guard
#
# Created: 2026-02-16
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${RESET}"

    local project_root="$PROJECT_ROOT"

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/g-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/g-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/g-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/g-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${RESET}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Clear any existing g alias/function before sourcing
    unalias g 2>/dev/null || true
    unfunction g 2>/dev/null || true

    # Source g dispatcher
    source "$project_root/lib/dispatchers/g-dispatcher.zsh"

    echo "  Loaded: g-dispatcher.zsh"
    echo ""
}

cleanup() {
    cleanup_test_repo
    reset_mocks
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
# TESTS: g feature help
# ============================================================================

test_g_feature_help_shows_output() {
    test_case "g feature help shows output"
    local output=$(g feature help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"Feature branch workflow"* ]]; then
        test_pass
    else
        test_fail "Expected 'Feature branch workflow' in output"
    fi
}

test_g_feature_help_shows_commands() {
    test_case "g feature help shows commands"
    local output=$(g feature help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"g feature start"* && "$output" == *"g feature sync"* ]]; then
        test_pass
    else
        test_fail "Expected feature commands in output"
    fi
}

test_g_feature_help_shows_workflow() {
    test_case "g feature help shows workflow diagram"
    local output=$(g feature help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"feature/*"* && "$output" == *"dev"* && "$output" == *"main"* ]]; then
        test_pass
    else
        test_fail "Expected workflow diagram in output"
    fi
}

# ============================================================================
# TESTS: g feature start
# ============================================================================

test_g_feature_start_requires_name() {
    test_case "g feature start requires name"
    local output result
    output=$(g feature start 2>&1)
    result=$?
    if [[ $result -ne 0 && "$output" == *"Feature name required"* ]]; then
        test_pass
    else
        test_fail "Expected error message for missing name"
    fi
}

test_g_feature_start_creates_branch() {
    test_case "g feature start creates branch"
    create_test_repo
    git checkout dev --quiet 2>/dev/null

    g feature start test-feature >/dev/null 2>&1
    local branch=$(git branch --show-current)

    if [[ "$branch" == "feature/test-feature" ]]; then
        test_pass
    else
        test_fail "Expected branch 'feature/test-feature', got '$branch'"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g feature list
# ============================================================================

test_g_feature_list_shows_branches() {
    test_case "g feature list shows branch headers"
    create_test_repo

    local output=$(g feature list 2>&1)
    assert_not_contains "$output" "command not found"

    if [[ "$output" == *"Feature branches"* && "$output" == *"Hotfix branches"* ]]; then
        test_pass
    else
        test_fail "Expected branch headers in output"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g promote
# ============================================================================

test_g_promote_requires_feature_branch() {
    test_case "g promote requires feature branch"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(g promote 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Not on a promotable branch"* ]]; then
        test_pass
    else
        test_fail "Expected error on main branch"
    fi
    cleanup_test_repo
}

test_g_promote_accepts_feature_branch() {
    test_case "g promote accepts feature/* branch"
    create_test_repo
    git checkout -b feature/test --quiet

    # Just test validation, not actual gh command
    local output=$(g promote 2>&1)

    # Should NOT contain "Not on a promotable branch"
    if [[ "$output" != *"Not on a promotable branch"* ]]; then
        test_pass
    else
        test_fail "Should accept feature/* branch"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g release
# ============================================================================

test_g_release_requires_dev_branch() {
    test_case "g release requires dev branch"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(g release 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Must be on 'dev' branch"* ]]; then
        test_pass
    else
        test_fail "Expected error on main branch"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: Workflow Guard
# ============================================================================

test_workflow_guard_blocks_main() {
    test_case "workflow guard blocks main"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(_g_check_workflow 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"blocked"* ]]; then
        test_pass
    else
        test_fail "Expected block message on main"
    fi
    cleanup_test_repo
}

test_workflow_guard_blocks_dev() {
    test_case "workflow guard blocks dev"
    create_test_repo
    git checkout dev --quiet 2>/dev/null

    local output result
    output=$(_g_check_workflow 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"blocked"* ]]; then
        test_pass
    else
        test_fail "Expected block message on dev"
    fi
    cleanup_test_repo
}

test_workflow_guard_allows_feature() {
    test_case "workflow guard allows feature/*"
    create_test_repo
    git checkout -b feature/test --quiet

    _g_check_workflow >/dev/null 2>&1
    local result=$?

    if [[ $result -eq 0 ]]; then
        test_pass
    else
        test_fail "Should allow feature/* branches"
    fi
    cleanup_test_repo
}

test_workflow_guard_allows_hotfix() {
    test_case "workflow guard allows hotfix/*"
    create_test_repo
    git checkout -b hotfix/urgent --quiet

    _g_check_workflow >/dev/null 2>&1
    local result=$?

    if [[ $result -eq 0 ]]; then
        test_pass
    else
        test_fail "Should allow hotfix/* branches"
    fi
    cleanup_test_repo
}

test_workflow_guard_shows_override() {
    test_case "workflow guard shows override command"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output=$(_g_check_workflow 2>&1)

    if [[ "$output" == *"GIT_WORKFLOW_SKIP"* ]]; then
        test_pass
    else
        test_fail "Expected override command in output"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g help includes feature workflow
# ============================================================================

test_g_help_includes_feature_workflow() {
    test_case "g help includes FEATURE WORKFLOW section"
    local output=$(g help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"FEATURE WORKFLOW"* ]]; then
        test_pass
    else
        test_fail "Expected FEATURE WORKFLOW section in g help"
    fi
}

test_g_help_shows_promote_release() {
    test_case "g help shows promote and release"
    local output=$(g help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"g promote"* && "$output" == *"g release"* ]]; then
        test_pass
    else
        test_fail "Expected promote and release in g help"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "G Feature Workflow Tests"

    setup

    echo "${YELLOW}── g feature help ──${RESET}"
    test_g_feature_help_shows_output
    test_g_feature_help_shows_commands
    test_g_feature_help_shows_workflow

    echo ""
    echo "${YELLOW}── g feature start ──${RESET}"
    test_g_feature_start_requires_name
    test_g_feature_start_creates_branch

    echo ""
    echo "${YELLOW}── g feature list ──${RESET}"
    test_g_feature_list_shows_branches

    echo ""
    echo "${YELLOW}── g promote ──${RESET}"
    test_g_promote_requires_feature_branch
    test_g_promote_accepts_feature_branch

    echo ""
    echo "${YELLOW}── g release ──${RESET}"
    test_g_release_requires_dev_branch

    echo ""
    echo "${YELLOW}── Workflow Guard ──${RESET}"
    test_workflow_guard_blocks_main
    test_workflow_guard_blocks_dev
    test_workflow_guard_allows_feature
    test_workflow_guard_allows_hotfix
    test_workflow_guard_shows_override

    echo ""
    echo "${YELLOW}── g help ──${RESET}"
    test_g_help_includes_feature_workflow
    test_g_help_shows_promote_release

    test_suite_end
    exit $?
}

main "$@"
