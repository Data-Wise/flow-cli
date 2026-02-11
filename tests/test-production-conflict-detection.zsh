#!/usr/bin/env zsh
# Test script for _git_detect_production_conflicts()
# Validates that conflict detection ignores merge commits (fixes #372)
# Generated: 2026-02-10

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

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

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Source only git-helpers (avoid full plugin load for unit tests)
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true

# We need _git_detect_production_conflicts available
# Source git-helpers directly
source "$PROJECT_ROOT/lib/git-helpers.zsh" 2>/dev/null || {
    echo "${RED}ERROR: Cannot source git-helpers.zsh${NC}"
    exit 1
}

# Create a temporary directory for test repos
TEST_TMPDIR=$(mktemp -d)
trap "rm -rf '$TEST_TMPDIR'" EXIT INT TERM

# ============================================================================
# HELPER: create a test repo with draft + production branches
# ============================================================================

_create_test_repo() {
    local repo_dir="$TEST_TMPDIR/$1"
    mkdir -p "$repo_dir"
    cd "$repo_dir"

    git init --initial-branch=main -q
    git config user.email "test@test.com"
    git config user.name "Test"

    # Initial commit on main (production)
    echo "initial" > file.txt
    git add file.txt
    git commit -m "initial commit" -q

    # Create draft branch
    git checkout -b draft -q

    echo "$repo_dir"
}

_create_bare_remote() {
    local remote_dir="$TEST_TMPDIR/$1-remote"
    git clone --bare "$TEST_TMPDIR/$1" "$remote_dir" -q 2>/dev/null
    cd "$TEST_TMPDIR/$1"
    git remote remove origin 2>/dev/null
    git remote add origin "$remote_dir"
    git push origin --all -q 2>/dev/null
}

# ============================================================================
# TESTS
# ============================================================================

echo ""
echo "${YELLOW}═══════════════════════════════════════════════${NC}"
echo "${YELLOW}  Production Conflict Detection Tests (#372)${NC}"
echo "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""

# --------------------------------------------------------------------------
# Test 1: Both branches at same commit → returns 0
# --------------------------------------------------------------------------
log_test "both branches at same commit → no conflict"

repo=$(_create_test_repo "test1")
_create_bare_remote "test1"
cd "$repo"
git checkout draft -q

_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    pass
else
    fail "expected 0, got non-zero"
fi

# --------------------------------------------------------------------------
# Test 2: Draft ahead, production unchanged → returns 0
# --------------------------------------------------------------------------
log_test "draft ahead, production unchanged → no conflict"

repo=$(_create_test_repo "test2")
cd "$repo"
git checkout draft -q
echo "draft change" > draft-file.txt
git add draft-file.txt
git commit -m "draft: add content" -q
_create_bare_remote "test2"
cd "$repo"

_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    pass
else
    fail "expected 0, got non-zero"
fi

# --------------------------------------------------------------------------
# Test 3: Production has real content commits → returns 1
# --------------------------------------------------------------------------
log_test "production has real content commits → conflict detected"

repo=$(_create_test_repo "test3")
cd "$repo"
# Draft has its own work (so it's NOT an ancestor of production)
echo "draft work" > draft-work.txt
git add draft-work.txt
git commit -m "feat: draft work" -q
# Production gets a hotfix independently
git checkout main -q
echo "hotfix" > hotfix.txt
git add hotfix.txt
git commit -m "hotfix: urgent fix on production" -q
git checkout draft -q
_create_bare_remote "test3"
cd "$repo"

_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 1 ]]; then
    pass
else
    fail "expected 1 (conflict), got 0"
fi

# --------------------------------------------------------------------------
# Test 4: Production has only merge commits (--no-ff) → returns 0
# This is the core #372 fix: merge commits should NOT trigger false positive
# --------------------------------------------------------------------------
log_test "production has only --no-ff merge commits → no conflict (core #372 fix)"

repo=$(_create_test_repo "test4")
cd "$repo"

# Add a commit on draft
echo "feature" > feature.txt
git add feature.txt
git commit -m "feat: add feature" -q

# Merge draft into main with --no-ff (simulates teach deploy --direct)
git checkout main -q
git merge draft --no-ff --no-edit -q

# Go back to draft
git checkout draft -q
_create_bare_remote "test4"
cd "$repo"

_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    pass
else
    fail "expected 0, got non-zero (false positive from merge commit)"
fi

# --------------------------------------------------------------------------
# Test 5: Draft already merged into production (is-ancestor fast path) → returns 0
# --------------------------------------------------------------------------
log_test "draft is ancestor of production → no conflict (fast path)"

repo=$(_create_test_repo "test5")
cd "$repo"

echo "work" > work.txt
git add work.txt
git commit -m "feat: work" -q

git checkout main -q
git merge draft --no-ff --no-edit -q

# Draft is now an ancestor of main — fast path should return 0
git checkout draft -q
_create_bare_remote "test5"
cd "$repo"

_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    pass
else
    fail "expected 0, got non-zero"
fi

# --------------------------------------------------------------------------
# Test 6: After back-merge, detection returns 0
# Simulates the auto back-merge that keeps branches in sync
# --------------------------------------------------------------------------
log_test "after back-merge sync → no conflict"

repo=$(_create_test_repo "test6")
cd "$repo"

# Draft adds a feature
echo "new content" > feature.txt
git add feature.txt
git commit -m "feat: new content" -q

# Deploy: merge draft → main (no-ff)
git checkout main -q
git merge draft --no-ff --no-edit -q

# Back-merge: merge main → draft (ff-only, simulates auto back-merge)
git checkout draft -q
git merge main --ff-only -q

_create_bare_remote "test6"
cd "$repo"

_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    pass
else
    fail "expected 0, got non-zero"
fi

# --------------------------------------------------------------------------
# Test 7: Multiple --no-ff merges accumulated → still returns 0
# Simulates STAT-545 scenario with 60+ merge commits
# --------------------------------------------------------------------------
log_test "multiple accumulated --no-ff merge commits → no conflict"

repo=$(_create_test_repo "test7")
cd "$repo"

# Simulate 5 deploy cycles (each creates a --no-ff merge commit)
for i in {1..5}; do
    git checkout draft -q
    echo "content-$i" > "file-$i.txt"
    git add "file-$i.txt"
    git commit -m "feat: iteration $i" -q

    git checkout main -q
    git merge draft --no-ff --no-edit -q
done

git checkout draft -q
_create_bare_remote "test7"
cd "$repo"

_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    pass
else
    fail "expected 0, got non-zero (false positive from accumulated merges)"
fi

# ============================================================================
# RESULTS
# ============================================================================

echo ""
echo "${YELLOW}═══════════════════════════════════════════════${NC}"
echo "  Results: ${GREEN}$TESTS_PASSED passed${NC}, ${RED}$TESTS_FAILED failed${NC}"
echo "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
