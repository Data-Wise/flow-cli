#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Tests for g feature prune
# ══════════════════════════════════════════════════════════════════════════════
#
# Run: zsh tests/test-g-feature-prune.zsh
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
    # Create dev branch
    git checkout -b dev --quiet
    git checkout main --quiet 2>/dev/null || git checkout master --quiet 2>/dev/null
}

cleanup_test_repo() {
    cd "$ORIGINAL_DIR" || return
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
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
echo -e "${_C_YELLOW}  g feature prune - Tests${_C_NC}"
echo -e "${_C_YELLOW}═══════════════════════════════════════════════════════════${_C_NC}\n"

# ─────────────────────────────────────────────────────────────────────────────
# HELP TESTS
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_C_DIM}Help System${_C_NC}"

test_prune_help_shows_usage() {
    local output
    output=$(g feature prune --help 2>&1)
    if [[ "$output" == *"Clean up merged feature branches"* ]]; then
        pass "prune --help shows description"
    else
        fail "prune --help should show description"
    fi
}

test_prune_help_shows_options() {
    local output
    output=$(g feature prune -h 2>&1)
    if [[ "$output" == *"--all"* && "$output" == *"--dry-run"* ]]; then
        pass "prune -h shows options"
    else
        fail "prune -h should show --all and --dry-run options"
    fi
}

test_prune_help_shows_safety() {
    local output
    output=$(g feature prune --help 2>&1)
    if [[ "$output" == *"SAFE BY DEFAULT"* ]]; then
        pass "prune --help shows safety info"
    else
        fail "prune --help should show safety info"
    fi
}

test_prune_help_shows_usage
test_prune_help_shows_options
test_prune_help_shows_safety

# ─────────────────────────────────────────────────────────────────────────────
# NO BRANCHES TO PRUNE
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}No Branches to Prune${_C_NC}"

test_prune_no_branches() {
    create_test_repo
    local output
    output=$(g feature prune 2>&1)
    local result=$?
    if [[ "$output" == *"No merged feature branches to prune"* ]]; then
        pass "prune with no feature branches shows clean message"
    else
        fail "prune should show 'no merged' message when no feature branches exist"
    fi
    cleanup_test_repo
}

test_prune_all_no_branches() {
    create_test_repo
    local output
    output=$(g feature prune --all 2>&1)
    if [[ "$output" == *"No merged feature branches"* && "$output" == *"No merged remote branches"* ]]; then
        pass "prune --all with no branches shows clean messages"
    else
        fail "prune --all should show clean messages for both local and remote"
    fi
    cleanup_test_repo
}

test_prune_no_branches
test_prune_all_no_branches

# ─────────────────────────────────────────────────────────────────────────────
# MERGED BRANCH DETECTION
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Merged Branch Detection${_C_NC}"

test_prune_detects_merged_branch() {
    create_test_repo
    # Create and merge a feature branch
    git checkout -b feature/test-prune --quiet
    echo "feature" > feature.txt
    git add feature.txt
    git commit --quiet -m "Feature commit"
    git checkout dev --quiet
    git merge feature/test-prune --quiet --no-edit

    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" == *"feature/test-prune"* ]]; then
        pass "prune detects merged feature branch"
    else
        fail "prune should detect merged feature/test-prune branch"
    fi
    cleanup_test_repo
}

test_prune_ignores_unmerged_branch() {
    create_test_repo
    # Create feature branch but don't merge it
    git checkout -b feature/unmerged --quiet
    echo "unmerged" > unmerged.txt
    git add unmerged.txt
    git commit --quiet -m "Unmerged commit"
    git checkout dev --quiet

    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" != *"feature/unmerged"* ]]; then
        pass "prune ignores unmerged feature branch"
    else
        fail "prune should NOT detect unmerged feature branch"
    fi
    cleanup_test_repo
}

test_prune_detects_merged_branch
test_prune_ignores_unmerged_branch

# ─────────────────────────────────────────────────────────────────────────────
# PROTECTED BRANCHES
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Protected Branches${_C_NC}"

test_prune_never_deletes_main() {
    create_test_repo
    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" != *"main"* || "$output" == *"No merged"* ]]; then
        pass "prune never lists main for deletion"
    else
        fail "prune should never list main for deletion"
    fi
    cleanup_test_repo
}

test_prune_never_deletes_dev() {
    create_test_repo
    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" != *"Merged branches"*"dev"* ]]; then
        pass "prune never lists dev for deletion"
    else
        fail "prune should never list dev for deletion"
    fi
    cleanup_test_repo
}

test_prune_never_deletes_main
test_prune_never_deletes_dev

# ─────────────────────────────────────────────────────────────────────────────
# DRY RUN MODE
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Dry Run Mode${_C_NC}"

test_prune_dry_run_no_delete() {
    create_test_repo
    # Create and merge a feature branch
    git checkout -b feature/dry-run-test --quiet
    echo "test" > test.txt
    git add test.txt
    git commit --quiet -m "Test commit"
    git checkout dev --quiet
    git merge feature/dry-run-test --quiet --no-edit

    # Run dry-run
    g feature prune --dry-run >/dev/null 2>&1

    # Check branch still exists
    if git show-ref --verify --quiet refs/heads/feature/dry-run-test; then
        pass "prune --dry-run does not delete branches"
    else
        fail "prune --dry-run should NOT delete branches"
    fi
    cleanup_test_repo
}

test_prune_dry_run_shows_message() {
    create_test_repo
    git checkout -b feature/msg-test --quiet
    echo "x" > x.txt
    git add x.txt
    git commit --quiet -m "x"
    git checkout dev --quiet
    git merge feature/msg-test --quiet --no-edit

    local output
    output=$(g feature prune -n 2>&1)
    if [[ "$output" == *"Dry run"* ]]; then
        pass "prune -n shows dry run message"
    else
        fail "prune -n should show 'Dry run' message"
    fi
    cleanup_test_repo
}

test_prune_dry_run_no_delete
test_prune_dry_run_shows_message

# ─────────────────────────────────────────────────────────────────────────────
# ACTUAL DELETION
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Actual Deletion${_C_NC}"

test_prune_deletes_merged_branch() {
    create_test_repo
    # Create and merge a feature branch
    git checkout -b feature/to-delete --quiet
    echo "delete" > delete.txt
    git add delete.txt
    git commit --quiet -m "Delete commit"
    git checkout dev --quiet
    git merge feature/to-delete --quiet --no-edit

    # Run prune
    g feature prune >/dev/null 2>&1

    # Check branch is deleted
    if ! git show-ref --verify --quiet refs/heads/feature/to-delete; then
        pass "prune deletes merged feature branch"
    else
        fail "prune should delete merged feature/to-delete branch"
    fi
    cleanup_test_repo
}

test_prune_reports_deleted_count() {
    create_test_repo
    # Create and merge two feature branches
    git checkout -b feature/one --quiet
    echo "one" > one.txt
    git add one.txt
    git commit --quiet -m "One"
    git checkout dev --quiet
    git merge feature/one --quiet --no-edit

    git checkout -b feature/two --quiet
    echo "two" > two.txt
    git add two.txt
    git commit --quiet -m "Two"
    git checkout dev --quiet
    git merge feature/two --quiet --no-edit

    local output
    output=$(g feature prune 2>&1)
    if [[ "$output" == *"Deleted 2"* ]]; then
        pass "prune reports correct deleted count"
    else
        fail "prune should report 'Deleted 2' branches"
    fi
    cleanup_test_repo
}

test_prune_deletes_merged_branch
test_prune_reports_deleted_count

# ─────────────────────────────────────────────────────────────────────────────
# BRANCH TYPES
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Branch Types${_C_NC}"

test_prune_handles_bugfix_branches() {
    create_test_repo
    git checkout -b bugfix/test-bug --quiet
    echo "bug" > bug.txt
    git add bug.txt
    git commit --quiet -m "Bug"
    git checkout dev --quiet
    git merge bugfix/test-bug --quiet --no-edit

    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" == *"bugfix/test-bug"* ]]; then
        pass "prune detects merged bugfix branch"
    else
        fail "prune should detect merged bugfix/test-bug branch"
    fi
    cleanup_test_repo
}

test_prune_handles_hotfix_branches() {
    create_test_repo
    git checkout -b hotfix/urgent --quiet
    echo "fix" > fix.txt
    git add fix.txt
    git commit --quiet -m "Fix"
    git checkout dev --quiet
    git merge hotfix/urgent --quiet --no-edit

    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" == *"hotfix/urgent"* ]]; then
        pass "prune detects merged hotfix branch"
    else
        fail "prune should detect merged hotfix/urgent branch"
    fi
    cleanup_test_repo
}

test_prune_ignores_other_branches() {
    create_test_repo
    git checkout -b random/branch --quiet
    echo "random" > random.txt
    git add random.txt
    git commit --quiet -m "Random"
    git checkout dev --quiet
    git merge random/branch --quiet --no-edit

    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" != *"random/branch"* ]]; then
        pass "prune ignores non-feature/bugfix/hotfix branches"
    else
        fail "prune should ignore random/branch"
    fi
    cleanup_test_repo
}

test_prune_handles_bugfix_branches
test_prune_handles_hotfix_branches
test_prune_ignores_other_branches

# ─────────────────────────────────────────────────────────────────────────────
# CURRENT BRANCH PROTECTION
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Current Branch Protection${_C_NC}"

test_prune_never_deletes_current_branch() {
    create_test_repo
    git checkout -b feature/current --quiet
    echo "current" > current.txt
    git add current.txt
    git commit --quiet -m "Current"
    # Merge to dev but stay on feature branch
    git checkout dev --quiet
    git merge feature/current --quiet --no-edit
    git checkout feature/current --quiet

    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" != *"feature/current"* || "$output" == *"No merged"* ]]; then
        pass "prune never lists current branch for deletion"
    else
        fail "prune should never list current branch (feature/current) for deletion"
    fi
    cleanup_test_repo
}

test_prune_never_deletes_current_branch

# ─────────────────────────────────────────────────────────────────────────────
# ERROR HANDLING
# ─────────────────────────────────────────────────────────────────────────────

echo -e "\n${_C_DIM}Error Handling${_C_NC}"

test_prune_unknown_option() {
    local output result
    output=$(g feature prune --unknown 2>&1)
    result=$?
    if [[ $result -ne 0 && "$output" == *"Unknown option"* ]]; then
        pass "prune rejects unknown options"
    else
        fail "prune should reject unknown options with error"
    fi
}

test_prune_unknown_option

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
