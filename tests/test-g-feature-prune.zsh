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
# FRAMEWORK SETUP
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

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

test_suite_start "g feature prune - Tests"

# ─────────────────────────────────────────────────────────────────────────────
# HELP TESTS
# ─────────────────────────────────────────────────────────────────────────────

test_prune_help_shows_usage() {
    test_case "prune --help shows description"
    local output
    output=$(g feature prune --help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"Clean up merged feature branches"* ]]; then
        test_pass
    else
        test_fail "prune --help should show description"
    fi
}

test_prune_help_shows_options() {
    test_case "prune -h shows options"
    local output
    output=$(g feature prune -h 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"--all"* && "$output" == *"--dry-run"* ]]; then
        test_pass
    else
        test_fail "prune -h should show --all and --dry-run options"
    fi
}

test_prune_help_shows_safety() {
    test_case "prune --help shows safety info"
    local output
    output=$(g feature prune --help 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"SAFE BY DEFAULT"* ]]; then
        test_pass
    else
        test_fail "prune --help should show safety info"
    fi
}

test_prune_help_shows_usage
test_prune_help_shows_options
test_prune_help_shows_safety

# ─────────────────────────────────────────────────────────────────────────────
# NO BRANCHES TO PRUNE
# ─────────────────────────────────────────────────────────────────────────────

test_prune_no_branches() {
    test_case "prune with no feature branches shows clean message"
    create_test_repo
    local output
    output=$(g feature prune 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"No merged feature branches to prune"* ]]; then
        test_pass
    else
        test_fail "prune should show 'no merged' message when no feature branches exist"
    fi
    cleanup_test_repo
}

test_prune_all_no_branches() {
    test_case "prune --all with no branches shows clean messages"
    create_test_repo
    local output
    output=$(g feature prune --all 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"No merged feature branches"* && "$output" == *"No merged remote branches"* ]]; then
        test_pass
    else
        test_fail "prune --all should show clean messages for both local and remote"
    fi
    cleanup_test_repo
}

test_prune_no_branches
test_prune_all_no_branches

# ─────────────────────────────────────────────────────────────────────────────
# MERGED BRANCH DETECTION
# ─────────────────────────────────────────────────────────────────────────────

test_prune_detects_merged_branch() {
    test_case "prune detects merged feature branch"
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
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"feature/test-prune"* ]]; then
        test_pass
    else
        test_fail "prune should detect merged feature/test-prune branch"
    fi
    cleanup_test_repo
}

test_prune_ignores_unmerged_branch() {
    test_case "prune ignores unmerged feature branch"
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
        test_pass
    else
        test_fail "prune should NOT detect unmerged feature branch"
    fi
    cleanup_test_repo
}

test_prune_detects_merged_branch
test_prune_ignores_unmerged_branch

# ─────────────────────────────────────────────────────────────────────────────
# PROTECTED BRANCHES
# ─────────────────────────────────────────────────────────────────────────────

test_prune_never_deletes_main() {
    test_case "prune never lists main for deletion"
    create_test_repo
    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" != *"main"* || "$output" == *"No merged"* ]]; then
        test_pass
    else
        test_fail "prune should never list main for deletion"
    fi
    cleanup_test_repo
}

test_prune_never_deletes_dev() {
    test_case "prune never lists dev for deletion"
    create_test_repo
    local output
    output=$(g feature prune --dry-run 2>&1)
    if [[ "$output" != *"Merged branches"*"dev"* ]]; then
        test_pass
    else
        test_fail "prune should never list dev for deletion"
    fi
    cleanup_test_repo
}

test_prune_never_deletes_main
test_prune_never_deletes_dev

# ─────────────────────────────────────────────────────────────────────────────
# DRY RUN MODE
# ─────────────────────────────────────────────────────────────────────────────

test_prune_dry_run_no_delete() {
    test_case "prune --dry-run does not delete branches"
    create_test_repo
    # Create and merge a feature branch
    git checkout -b feature/dry-run-test --quiet
    echo "test" > test.txt
    git add test.txt
    git commit --quiet -m "Test commit"
    git checkout dev --quiet
    git merge feature/dry-run-test --quiet --no-edit

    # Run dry-run
    local output
    output=$(g feature prune --dry-run 2>&1)
    assert_not_contains "$output" "command not found"

    # Check branch still exists
    if git show-ref --verify --quiet refs/heads/feature/dry-run-test; then
        test_pass
    else
        test_fail "prune --dry-run should NOT delete branches"
    fi
    cleanup_test_repo
}

test_prune_dry_run_shows_message() {
    test_case "prune -n shows dry run message"
    create_test_repo
    git checkout -b feature/msg-test --quiet
    echo "x" > x.txt
    git add x.txt
    git commit --quiet -m "x"
    git checkout dev --quiet
    git merge feature/msg-test --quiet --no-edit

    local output
    output=$(g feature prune -n 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"Dry run"* ]]; then
        test_pass
    else
        test_fail "prune -n should show 'Dry run' message"
    fi
    cleanup_test_repo
}

test_prune_dry_run_no_delete
test_prune_dry_run_shows_message

# ─────────────────────────────────────────────────────────────────────────────
# ACTUAL DELETION
# ─────────────────────────────────────────────────────────────────────────────

test_prune_deletes_merged_branch() {
    test_case "prune deletes merged feature branch"
    create_test_repo
    # Create and merge a feature branch
    git checkout -b feature/to-delete --quiet
    echo "delete" > delete.txt
    git add delete.txt
    git commit --quiet -m "Delete commit"
    git checkout dev --quiet
    git merge feature/to-delete --quiet --no-edit

    # Run prune
    local output
    output=$(g feature prune 2>&1)
    assert_not_contains "$output" "command not found"

    # Check branch is deleted
    if ! git show-ref --verify --quiet refs/heads/feature/to-delete; then
        test_pass
    else
        test_fail "prune should delete merged feature/to-delete branch"
    fi
    cleanup_test_repo
}

test_prune_reports_deleted_count() {
    test_case "prune reports correct deleted count"
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
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"Deleted 2"* ]]; then
        test_pass
    else
        test_fail "prune should report 'Deleted 2' branches"
    fi
    cleanup_test_repo
}

test_prune_deletes_merged_branch
test_prune_reports_deleted_count

# ─────────────────────────────────────────────────────────────────────────────
# BRANCH TYPES
# ─────────────────────────────────────────────────────────────────────────────

test_prune_handles_bugfix_branches() {
    test_case "prune detects merged bugfix branch"
    create_test_repo
    git checkout -b bugfix/test-bug --quiet
    echo "bug" > bug.txt
    git add bug.txt
    git commit --quiet -m "Bug"
    git checkout dev --quiet
    git merge bugfix/test-bug --quiet --no-edit

    local output
    output=$(g feature prune --dry-run 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"bugfix/test-bug"* ]]; then
        test_pass
    else
        test_fail "prune should detect merged bugfix/test-bug branch"
    fi
    cleanup_test_repo
}

test_prune_handles_hotfix_branches() {
    test_case "prune detects merged hotfix branch"
    create_test_repo
    git checkout -b hotfix/urgent --quiet
    echo "fix" > fix.txt
    git add fix.txt
    git commit --quiet -m "Fix"
    git checkout dev --quiet
    git merge hotfix/urgent --quiet --no-edit

    local output
    output=$(g feature prune --dry-run 2>&1)
    assert_not_contains "$output" "command not found"
    if [[ "$output" == *"hotfix/urgent"* ]]; then
        test_pass
    else
        test_fail "prune should detect merged hotfix/urgent branch"
    fi
    cleanup_test_repo
}

test_prune_ignores_other_branches() {
    test_case "prune ignores non-feature/bugfix/hotfix branches"
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
        test_pass
    else
        test_fail "prune should ignore random/branch"
    fi
    cleanup_test_repo
}

test_prune_handles_bugfix_branches
test_prune_handles_hotfix_branches
test_prune_ignores_other_branches

# ─────────────────────────────────────────────────────────────────────────────
# CURRENT BRANCH PROTECTION
# ─────────────────────────────────────────────────────────────────────────────

test_prune_never_deletes_current_branch() {
    test_case "prune never lists current branch for deletion"
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
        test_pass
    else
        test_fail "prune should never list current branch (feature/current) for deletion"
    fi
    cleanup_test_repo
}

test_prune_never_deletes_current_branch

# ─────────────────────────────────────────────────────────────────────────────
# ERROR HANDLING
# ─────────────────────────────────────────────────────────────────────────────

test_prune_unknown_option() {
    test_case "prune rejects unknown options"
    local output result
    output=$(g feature prune --unknown 2>&1)
    result=$?
    if [[ $result -ne 0 && "$output" == *"Unknown option"* ]]; then
        test_pass
    else
        test_fail "prune should reject unknown options with error"
    fi
}

test_prune_unknown_option

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

# Cleanup any leftover test repos
cleanup_test_repo

test_suite_end
exit $?
