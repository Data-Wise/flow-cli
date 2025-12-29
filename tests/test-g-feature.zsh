#!/usr/bin/env zsh
# Test script for g dispatcher feature workflow
# Tests: g feature, g promote, g release, workflow guard

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

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/g-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/g-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/g-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/g-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
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
    log_test "g feature help shows output"
    local output=$(g feature help 2>&1)
    if [[ "$output" == *"Feature branch workflow"* ]]; then
        pass
    else
        fail "Expected 'Feature branch workflow' in output"
    fi
}

test_g_feature_help_shows_commands() {
    log_test "g feature help shows commands"
    local output=$(g feature help 2>&1)
    if [[ "$output" == *"g feature start"* && "$output" == *"g feature sync"* ]]; then
        pass
    else
        fail "Expected feature commands in output"
    fi
}

test_g_feature_help_shows_workflow() {
    log_test "g feature help shows workflow diagram"
    local output=$(g feature help 2>&1)
    if [[ "$output" == *"feature/*"* && "$output" == *"dev"* && "$output" == *"main"* ]]; then
        pass
    else
        fail "Expected workflow diagram in output"
    fi
}

# ============================================================================
# TESTS: g feature start
# ============================================================================

test_g_feature_start_requires_name() {
    log_test "g feature start requires name"
    local output result
    output=$(g feature start 2>&1)
    result=$?
    if [[ $result -ne 0 && "$output" == *"Feature name required"* ]]; then
        pass
    else
        fail "Expected error message for missing name"
    fi
}

test_g_feature_start_creates_branch() {
    log_test "g feature start creates branch"
    create_test_repo
    git checkout dev --quiet 2>/dev/null

    g feature start test-feature >/dev/null 2>&1
    local branch=$(git branch --show-current)

    if [[ "$branch" == "feature/test-feature" ]]; then
        pass
    else
        fail "Expected branch 'feature/test-feature', got '$branch'"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g feature list
# ============================================================================

test_g_feature_list_shows_branches() {
    log_test "g feature list shows branch headers"
    create_test_repo

    local output=$(g feature list 2>&1)

    if [[ "$output" == *"Feature branches"* && "$output" == *"Hotfix branches"* ]]; then
        pass
    else
        fail "Expected branch headers in output"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g promote
# ============================================================================

test_g_promote_requires_feature_branch() {
    log_test "g promote requires feature branch"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(g promote 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Not on a promotable branch"* ]]; then
        pass
    else
        fail "Expected error on main branch"
    fi
    cleanup_test_repo
}

test_g_promote_accepts_feature_branch() {
    log_test "g promote accepts feature/* branch"
    create_test_repo
    git checkout -b feature/test --quiet

    # Just test validation, not actual gh command
    local output=$(g promote 2>&1)

    # Should NOT contain "Not on a promotable branch"
    if [[ "$output" != *"Not on a promotable branch"* ]]; then
        pass
    else
        fail "Should accept feature/* branch"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g release
# ============================================================================

test_g_release_requires_dev_branch() {
    log_test "g release requires dev branch"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(g release 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"Must be on 'dev' branch"* ]]; then
        pass
    else
        fail "Expected error on main branch"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: Workflow Guard
# ============================================================================

test_workflow_guard_blocks_main() {
    log_test "workflow guard blocks main"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output result
    output=$(_g_check_workflow 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"blocked"* ]]; then
        pass
    else
        fail "Expected block message on main"
    fi
    cleanup_test_repo
}

test_workflow_guard_blocks_dev() {
    log_test "workflow guard blocks dev"
    create_test_repo
    git checkout dev --quiet 2>/dev/null

    local output result
    output=$(_g_check_workflow 2>&1)
    result=$?

    if [[ $result -ne 0 && "$output" == *"blocked"* ]]; then
        pass
    else
        fail "Expected block message on dev"
    fi
    cleanup_test_repo
}

test_workflow_guard_allows_feature() {
    log_test "workflow guard allows feature/*"
    create_test_repo
    git checkout -b feature/test --quiet

    _g_check_workflow >/dev/null 2>&1
    local result=$?

    if [[ $result -eq 0 ]]; then
        pass
    else
        fail "Should allow feature/* branches"
    fi
    cleanup_test_repo
}

test_workflow_guard_allows_hotfix() {
    log_test "workflow guard allows hotfix/*"
    create_test_repo
    git checkout -b hotfix/urgent --quiet

    _g_check_workflow >/dev/null 2>&1
    local result=$?

    if [[ $result -eq 0 ]]; then
        pass
    else
        fail "Should allow hotfix/* branches"
    fi
    cleanup_test_repo
}

test_workflow_guard_shows_override() {
    log_test "workflow guard shows override command"
    create_test_repo
    git checkout main --quiet 2>/dev/null

    local output=$(_g_check_workflow 2>&1)

    if [[ "$output" == *"GIT_WORKFLOW_SKIP"* ]]; then
        pass
    else
        fail "Expected override command in output"
    fi
    cleanup_test_repo
}

# ============================================================================
# TESTS: g help includes feature workflow
# ============================================================================

test_g_help_includes_feature_workflow() {
    log_test "g help includes FEATURE WORKFLOW section"
    local output=$(g help 2>&1)
    if [[ "$output" == *"FEATURE WORKFLOW"* ]]; then
        pass
    else
        fail "Expected FEATURE WORKFLOW section in g help"
    fi
}

test_g_help_shows_promote_release() {
    log_test "g help shows promote and release"
    local output=$(g help 2>&1)
    if [[ "$output" == *"g promote"* && "$output" == *"g release"* ]]; then
        pass
    else
        fail "Expected promote and release in g help"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo "${YELLOW}║${NC}  G Feature Workflow Tests                                   ${YELLOW}║${NC}"
    echo "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"

    setup

    echo "${YELLOW}── g feature help ──${NC}"
    test_g_feature_help_shows_output
    test_g_feature_help_shows_commands
    test_g_feature_help_shows_workflow

    echo ""
    echo "${YELLOW}── g feature start ──${NC}"
    test_g_feature_start_requires_name
    test_g_feature_start_creates_branch

    echo ""
    echo "${YELLOW}── g feature list ──${NC}"
    test_g_feature_list_shows_branches

    echo ""
    echo "${YELLOW}── g promote ──${NC}"
    test_g_promote_requires_feature_branch
    test_g_promote_accepts_feature_branch

    echo ""
    echo "${YELLOW}── g release ──${NC}"
    test_g_release_requires_dev_branch

    echo ""
    echo "${YELLOW}── Workflow Guard ──${NC}"
    test_workflow_guard_blocks_main
    test_workflow_guard_blocks_dev
    test_workflow_guard_allows_feature
    test_workflow_guard_allows_hotfix
    test_workflow_guard_shows_override

    echo ""
    echo "${YELLOW}── g help ──${NC}"
    test_g_help_includes_feature_workflow
    test_g_help_shows_promote_release

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
