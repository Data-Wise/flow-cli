#!/usr/bin/env zsh
# test-flat-worktree-detection.zsh - Tests for flat worktree detection
# Run with: zsh tests/test-flat-worktree-detection.zsh
#
# Tests the hybrid worktree detection algorithm that handles both:
# - FLAT worktrees: ~/.git-worktrees/project-branch/ (level-1 .git FILE)
# - HIERARCHICAL worktrees: ~/.git-worktrees/project/branch/ (level-2 .git)

# Preserve PATH
typeset -g ORIGINAL_PATH="$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
  # Restore PATH before each test
  PATH="$ORIGINAL_PATH"
  echo -n "${CYAN}TEST: $1${RESET} ... "
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
  echo "${GREEN}✓ PASS${RESET}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  echo "${RED}✗ FAIL${RESET}"
  echo "  ${RED}→ $1${RESET}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values should be equal}"

  if [[ "$actual" == "$expected" ]]; then
    return 0
  else
    test_fail "$message (expected: '$expected', got: '$actual')"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should contain substring}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (expected to contain: '$needle')"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should NOT contain substring}"

  if [[ "$haystack" != *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (should not contain: '$needle')"
    return 1
  fi
}

assert_not_empty() {
  local value="$1"
  local message="${2:-Should not be empty}"

  if [[ -n "$value" ]]; then
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

assert_empty() {
  local value="$1"
  local message="${2:-Should be empty}"

  if [[ -z "$value" ]]; then
    return 0
  else
    test_fail "$message (got: '$value')"
    return 1
  fi
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  FLAT WORKTREE DETECTION TEST SUITE"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Create isolated test environment FIRST
TEST_WORKTREE_DIR="/tmp/flow-test-flat-wt-$$"
rm -rf "$TEST_WORKTREE_DIR" 2>/dev/null
export FLOW_WORKTREE_DIR="$TEST_WORKTREE_DIR"
mkdir -p "$TEST_WORKTREE_DIR"

# Source the plugin
SCRIPT_DIR="${0:h}"
PLUGIN_FILE="${SCRIPT_DIR}/../flow.plugin.zsh"

test_start "Plugin loads without errors"
if source "$PLUGIN_FILE" 2>/dev/null; then
  test_pass
else
  test_fail "Plugin failed to load"
  exit 1
fi

# Override PROJ_WORKTREE_DIR directly (it's set from FLOW_WORKTREE_DIR at source time)
PROJ_WORKTREE_DIR="$TEST_WORKTREE_DIR"

# Cleanup on exit
cleanup() {
  rm -rf "$TEST_WORKTREE_DIR" 2>/dev/null
}
trap cleanup EXIT

# ============================================================================
# HELPER: Create mock worktrees
# ============================================================================

# Create a FLAT worktree (level-1 .git file)
create_flat_worktree() {
  local name="$1"
  local project="$2"
  local branch="$3"

  mkdir -p "$TEST_WORKTREE_DIR/$name"
  # Create .git FILE with gitdir pointer (mimics real worktree)
  echo "gitdir: /fake/path/to/$project/.git/worktrees/$branch" > "$TEST_WORKTREE_DIR/$name/.git"
}

# Create a HIERARCHICAL worktree (level-2 .git directory)
create_hierarchical_worktree() {
  local project="$1"
  local branch="$2"

  mkdir -p "$TEST_WORKTREE_DIR/$project/$branch"
  # Create .git DIRECTORY (real git init)
  (cd "$TEST_WORKTREE_DIR/$project/$branch" && git init >/dev/null 2>&1)
}

# ============================================================================
# FLAT WORKTREE DETECTION TESTS
# ============================================================================

echo ""
echo "── Flat Worktree Detection ──"

test_start "_proj_list_worktrees detects flat worktree with .git FILE"
create_flat_worktree "scholar-github-actions" "scholar" "scholar-github-actions"
result=$(_proj_list_worktrees)
if assert_contains "$result" "scholar"; then
  test_pass
fi

test_start "_proj_list_worktrees parses project name from gitdir"
# Already created above - check the display name format
if assert_contains "$result" "scholar (scholar-github-actions)"; then
  test_pass
fi

test_start "_proj_list_worktrees includes correct path for flat worktree"
if assert_contains "$result" "$TEST_WORKTREE_DIR/scholar-github-actions"; then
  test_pass
fi

test_start "_proj_list_worktrees includes worktree icon for flat worktree"
if assert_contains "$result" "🌳"; then
  test_pass
fi

test_start "_proj_find_worktree finds flat worktree by project name"
path=$(_proj_find_worktree "scholar")
if assert_equals "$path" "$TEST_WORKTREE_DIR/scholar-github-actions"; then
  test_pass
fi

test_start "_proj_find_worktree finds flat worktree by branch name"
path=$(_proj_find_worktree "scholar-github-actions")
if assert_equals "$path" "$TEST_WORKTREE_DIR/scholar-github-actions"; then
  test_pass
fi

test_start "_proj_find_worktree finds flat worktree by display name"
path=$(_proj_find_worktree "scholar (scholar-github-actions)")
if assert_equals "$path" "$TEST_WORKTREE_DIR/scholar-github-actions"; then
  test_pass
fi

# ============================================================================
# PROJECT FILTER TESTS (FLAT)
# ============================================================================

echo ""
echo "── Flat Worktree Filtering ──"

test_start "_proj_list_worktrees filters flat worktrees by project name"
# Create another flat worktree
create_flat_worktree "nexus-feature-x" "nexus" "feature-x"

result=$(_proj_list_worktrees "scholar")
if assert_contains "$result" "scholar"; then
  if assert_not_contains "$result" "nexus"; then
    test_pass
  fi
fi

test_start "_proj_list_worktrees shows all flat worktrees without filter"
result=$(_proj_list_worktrees)
if assert_contains "$result" "scholar"; then
  if assert_contains "$result" "nexus"; then
    test_pass
  fi
fi

# ============================================================================
# HIERARCHICAL WORKTREE TESTS (REGRESSION)
# ============================================================================

echo ""
echo "── Hierarchical Worktree Detection (Regression) ──"

test_start "_proj_list_worktrees still detects hierarchical worktrees"
create_hierarchical_worktree "scribe" "quarto-v115"
result=$(_proj_list_worktrees)
if assert_contains "$result" "scribe (quarto-v115)"; then
  test_pass
fi

test_start "_proj_list_worktrees includes correct path for hierarchical worktree"
if assert_contains "$result" "$TEST_WORKTREE_DIR/scribe/quarto-v115"; then
  test_pass
fi

test_start "_proj_find_worktree finds hierarchical worktree"
path=$(_proj_find_worktree "scribe")
if assert_equals "$path" "$TEST_WORKTREE_DIR/scribe/quarto-v115"; then
  test_pass
fi

test_start "_proj_list_worktrees filters hierarchical worktrees"
create_hierarchical_worktree "rmediation" "feature-cache"
result=$(_proj_list_worktrees "scribe")
if assert_contains "$result" "scribe"; then
  if assert_not_contains "$result" "rmediation"; then
    test_pass
  fi
fi

# ============================================================================
# MIXED ENVIRONMENT TESTS
# ============================================================================

echo ""
echo "── Mixed Environment (Flat + Hierarchical) ──"

test_start "_proj_list_worktrees lists both flat and hierarchical"
result=$(_proj_list_worktrees)
flat_found=0
hierarchical_found=0
[[ "$result" == *"scholar (scholar-github-actions)"* ]] && flat_found=1
[[ "$result" == *"scribe (quarto-v115)"* ]] && hierarchical_found=1

if [[ $flat_found -eq 1 && $hierarchical_found -eq 1 ]]; then
  test_pass
else
  test_fail "Should contain both flat and hierarchical (flat=$flat_found, hier=$hierarchical_found)"
fi

test_start "Total worktrees count is correct"
# We created: scholar-github-actions (flat), nexus-feature-x (flat),
#             scribe/quarto-v115 (hier), rmediation/feature-cache (hier)
count=$(echo "$result" | grep -c "🌳")
if [[ $count -eq 4 ]]; then
  test_pass
else
  test_fail "Expected 4 worktrees, got $count"
fi

# ============================================================================
# EDGE CASES
# ============================================================================

echo ""
echo "── Edge Cases ──"

test_start "Handles empty .git file gracefully"
mkdir -p "$TEST_WORKTREE_DIR/empty-git-test"
touch "$TEST_WORKTREE_DIR/empty-git-test/.git"  # Empty file
result=$(_proj_list_worktrees 2>&1)
# Should not crash, just skip this entry
if [[ $? -eq 0 ]]; then
  if assert_not_contains "$result" "empty-git-test"; then
    test_pass
  fi
fi

test_start "Handles malformed gitdir line gracefully"
mkdir -p "$TEST_WORKTREE_DIR/malformed-git-test"
echo "not-a-gitdir-line" > "$TEST_WORKTREE_DIR/malformed-git-test/.git"
result=$(_proj_list_worktrees 2>&1)
# Should not crash, just skip this entry
if [[ $? -eq 0 ]]; then
  if assert_not_contains "$result" "malformed-git-test"; then
    test_pass
  fi
fi

test_start "Skips directories with .git DIRECTORY at level-1 (not worktree)"
mkdir -p "$TEST_WORKTREE_DIR/regular-repo-test/.git"  # .git as directory
result=$(_proj_list_worktrees 2>&1)
# Should not detect this as a worktree (it's a regular repo)
if assert_not_contains "$result" "regular-repo-test"; then
  test_pass
fi

test_start "Handles gitdir path without expected pattern (fallback)"
mkdir -p "$TEST_WORKTREE_DIR/weird-gitdir-test"
echo "gitdir: /some/unexpected/path/format" > "$TEST_WORKTREE_DIR/weird-gitdir-test/.git"
result=$(_proj_list_worktrees 2>&1)
# Should use fallback (directory name)
if assert_contains "$result" "weird-gitdir-test (weird-gitdir-test)"; then
  test_pass
fi

test_start "Empty worktree directory returns empty list"
# Clean environment
rm -rf "$TEST_WORKTREE_DIR"/*
result=$(_proj_list_worktrees)
if assert_empty "$result"; then
  test_pass
fi

test_start "_proj_find_worktree returns empty for nonexistent worktree"
path=$(_proj_find_worktree "nonexistent-worktree-xyz")
if assert_empty "$path"; then
  test_pass
fi

# ============================================================================
# CASE SENSITIVITY TESTS
# ============================================================================

echo ""
echo "── Case Sensitivity ──"

test_start "_proj_list_worktrees filter is case-insensitive"
# Recreate test worktrees (after PATH is restored by test_start)
create_flat_worktree "Scholar-Test" "Scholar" "Test"
result=$(_proj_list_worktrees "scholar")
if assert_contains "$result" "Scholar"; then
  test_pass
fi

test_start "_proj_list_worktrees filter works with uppercase"
result=$(_proj_list_worktrees "SCHOLAR")
if assert_contains "$result" "Scholar"; then
  test_pass
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Total:  $TESTS_RUN"
echo "  ${GREEN}Passed: $TESTS_PASSED${RESET}"
echo "  ${RED}Failed: $TESTS_FAILED${RESET}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${GREEN}✓ ALL TESTS PASSED${RESET}"
  exit 0
else
  echo "${RED}✗ SOME TESTS FAILED${RESET}"
  exit 1
fi
