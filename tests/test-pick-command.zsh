#!/usr/bin/env zsh
# test-pick-command.zsh - Automated tests for pick command
# Run with: zsh tests/test-pick-command.zsh
#
# Tests the pick command's functionality including:
# - Basic project listing
# - Direct jump
# - Category filtering
# - Worktree mode
# - Session indicators
# - Frecency sorting
# - Edge cases

# Don't use set -e - we want to continue after failures

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

assert_function_exists() {
  local func_name="$1"

  if (( $+functions[$func_name] )); then
    return 0
  else
    test_fail "Function '$func_name' should exist"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"

  if [[ -f "$file" ]]; then
    return 0
  else
    test_fail "File should exist: $file"
    return 1
  fi
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  PICK COMMAND TEST SUITE"
echo "═══════════════════════════════════════════════════════════════"
echo ""

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

# Create temporary test environment
TEST_PROJECTS_ROOT="/tmp/flow-test-projects-$$"
export FLOW_PROJECTS_ROOT="$TEST_PROJECTS_ROOT"

# Cleanup on exit
cleanup() {
  rm -rf "$TEST_PROJECTS_ROOT" 2>/dev/null
}
trap cleanup EXIT

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

echo ""
echo "── Function Existence ──"

test_start "pick function exists"
if assert_function_exists "pick"; then
  test_pass
fi

test_start "_proj_find function exists"
if assert_function_exists "_proj_find"; then
  test_pass
fi

test_start "_proj_list_all function exists"
if assert_function_exists "_proj_list_all"; then
  test_pass
fi

test_start "_proj_list_worktrees function exists"
if assert_function_exists "_proj_list_worktrees"; then
  test_pass
fi

test_start "_proj_frecency_score function exists"
if assert_function_exists "_proj_frecency_score"; then
  test_pass
fi

test_start "_proj_get_claude_session_status function exists"
if assert_function_exists "_proj_get_claude_session_status"; then
  test_pass
fi

# ============================================================================
# HELPER FUNCTION TESTS
# ============================================================================

echo ""
echo "── Helper Functions ──"

# Test frecency scoring
test_start "_proj_frecency_score returns 0 for timestamp=0"
score=$(_proj_frecency_score 0)
if assert_equals "$score" "0" "Zero timestamp should return 0"; then
  test_pass
fi

test_start "_proj_frecency_score returns 1000 for very recent (< 1h)"
# Current time = very recent = 1000 points
current_time=$(date +%s)
score=$(_proj_frecency_score $current_time)
if assert_equals "$score" "1000" "Current timestamp should return 1000"; then
  test_pass
fi

test_start "_proj_frecency_score returns high for < 24h"
# 12 hours ago = 43200 seconds
twelve_hours_ago=$(($(date +%s) - 43200))
score=$(_proj_frecency_score $twelve_hours_ago)
if [[ $score -gt 500 && $score -lt 1000 ]]; then
  test_pass
else
  test_fail "12h score should be 500-1000, got: $score"
fi

test_start "_proj_frecency_score returns low for old (> 7 days)"
# 30 days ago
thirty_days_ago=$(($(date +%s) - 2592000))
score=$(_proj_frecency_score $thirty_days_ago)
if [[ $score -lt 100 ]]; then
  test_pass
else
  test_fail "30 day score should be < 100, got: $score"
fi

# ============================================================================
# PROJECT DETECTION TESTS
# ============================================================================

echo ""
echo "── Project Detection ──"

# Setup test projects
mkdir -p "$TEST_PROJECTS_ROOT/dev-tools/flow-cli"
(cd "$TEST_PROJECTS_ROOT/dev-tools/flow-cli" && git init >/dev/null 2>&1)

mkdir -p "$TEST_PROJECTS_ROOT/dev-tools/aiterm"
(cd "$TEST_PROJECTS_ROOT/dev-tools/aiterm" && git init >/dev/null 2>&1)

mkdir -p "$TEST_PROJECTS_ROOT/r-packages/active/mediationverse"
(cd "$TEST_PROJECTS_ROOT/r-packages/active/mediationverse" && git init >/dev/null 2>&1)

test_start "_proj_find finds exact match (case-insensitive)"
result=$(_proj_find "flow-cli")
if assert_contains "$result" "flow-cli"; then
  test_pass
fi

test_start "_proj_find finds fuzzy match"
result=$(_proj_find "flow")
if assert_contains "$result" "flow-cli"; then
  test_pass
fi

test_start "_proj_find returns empty for no match"
result=$(_proj_find "nonexistent-project-xyz")
if [[ -z "$result" ]]; then
  test_pass
else
  test_fail "Should return empty for no match, got: $result"
fi

test_start "_proj_find prioritizes exact over fuzzy"
# Create another project with "flow" in name
mkdir -p "$TEST_PROJECTS_ROOT/dev-tools/workflow-tool"
(cd "$TEST_PROJECTS_ROOT/dev-tools/workflow-tool" && git init >/dev/null 2>&1)

result=$(_proj_find "flow-cli")
if assert_contains "$result" "/flow-cli"; then
  if assert_not_contains "$result" "/workflow-tool"; then
    test_pass
  fi
fi

# ============================================================================
# PROJECT LISTING TESTS
# ============================================================================

echo ""
echo "── Project Listing ──"

test_start "_proj_list_all returns projects"
result=$(_proj_list_all)
if [[ -n "$result" ]]; then
  test_pass
else
  test_fail "Should return projects list"
fi

test_start "_proj_list_all includes created projects"
result=$(_proj_list_all)
if assert_contains "$result" "flow-cli"; then
  if assert_contains "$result" "aiterm"; then
    if assert_contains "$result" "mediationverse"; then
      test_pass
    fi
  fi
fi

test_start "_proj_list_all output format is pipe-separated"
result=$(_proj_list_all | head -1)
# Format: name|type|icon|dir|session_status
field_count=$(echo "$result" | awk -F'|' '{print NF}')
if [[ $field_count -ge 4 ]]; then
  test_pass
else
  test_fail "Expected 4+ fields, got: $field_count"
fi

test_start "_proj_list_all filters by category (dev)"
result=$(_proj_list_all "dev")
if assert_contains "$result" "flow-cli"; then
  if assert_contains "$result" "aiterm"; then
    if assert_not_contains "$result" "mediationverse"; then
      test_pass
    fi
  fi
fi

test_start "_proj_list_all filters by category (r)"
result=$(_proj_list_all "r")
if assert_contains "$result" "mediationverse"; then
  if assert_not_contains "$result" "flow-cli"; then
    test_pass
  fi
fi

# ============================================================================
# SESSION STATUS TESTS
# ============================================================================

echo ""
echo "── Session Status ──"

test_start "_proj_get_claude_session_status returns empty for no session"
result=$(_proj_get_claude_session_status "$TEST_PROJECTS_ROOT/dev-tools/flow-cli")
if [[ -z "$result" ]]; then
  test_pass
else
  test_fail "Should return empty for no session, got: $result"
fi

test_start "_proj_get_claude_session_status detects recent session"
# Create .claude directory with recent file
mkdir -p "$TEST_PROJECTS_ROOT/dev-tools/flow-cli/.claude"
touch "$TEST_PROJECTS_ROOT/dev-tools/flow-cli/.claude/test-session.json"

result=$(_proj_get_claude_session_status "$TEST_PROJECTS_ROOT/dev-tools/flow-cli")
if assert_contains "$result" "🟢"; then
  test_pass
fi

test_start "_proj_get_claude_session_status shows time for recent"
result=$(_proj_get_claude_session_status "$TEST_PROJECTS_ROOT/dev-tools/flow-cli")
# Should contain time indicator (Xh, Xm, or "now")
if [[ "$result" == *"🟢"* ]] && [[ "$result" =~ (now|[0-9]+[hm]) ]]; then
  test_pass
else
  test_fail "Should show time indicator, got: $result"
fi

test_start "_proj_get_claude_session_status detects old session"
# Create old session file (> 24h)
old_file="$TEST_PROJECTS_ROOT/dev-tools/aiterm/.claude/old-session.json"
mkdir -p "$(dirname "$old_file")"
touch -t 202301010000 "$old_file" 2>/dev/null || touch "$old_file"

result=$(_proj_get_claude_session_status "$TEST_PROJECTS_ROOT/dev-tools/aiterm")
if assert_contains "$result" "🟡"; then
  test_pass
fi

# ============================================================================
# WORKTREE TESTS
# ============================================================================

echo ""
echo "── Worktree Detection ──"

# Setup test worktree directory (clean start)
WORKTREE_DIR="/tmp/flow-test-worktrees-$$"
rm -rf "$WORKTREE_DIR" 2>/dev/null
export FLOW_WORKTREE_DIR="$WORKTREE_DIR"
mkdir -p "$WORKTREE_DIR"

# Re-source pick.zsh to pick up new FLOW_WORKTREE_DIR
# (PROJ_WORKTREE_DIR is set at source time, not runtime)
source "$PLUGIN_FILE" 2>/dev/null

test_start "_proj_list_worktrees returns empty for no worktrees"
result=$(_proj_list_worktrees)
if [[ -z "$result" ]]; then
  test_pass
else
  test_fail "Should return empty for no worktrees (got: '${result:0:50}')"
fi

test_start "_proj_list_worktrees detects worktrees"
# Create mock worktree structure
mkdir -p "$WORKTREE_DIR/flow-cli/feature-cache"
(cd "$WORKTREE_DIR/flow-cli/feature-cache" && git init >/dev/null 2>&1)

result=$(_proj_list_worktrees)
# Debug: Show what we got
if [[ -z "$result" ]]; then
  test_fail "No output from _proj_list_worktrees (expected: flow-cli (feature-cache))"
elif assert_contains "$result" "flow-cli (feature-cache)"; then
  test_pass
else
  test_fail "Wrong output (got: '${result:0:50}', expected: 'flow-cli (feature-cache)')"
fi

test_start "_proj_list_worktrees filters by project"
mkdir -p "$WORKTREE_DIR/aiterm/feature-test"
(cd "$WORKTREE_DIR/aiterm/feature-test" && git init >/dev/null 2>&1)

result=$(_proj_list_worktrees "flow")
if assert_contains "$result" "flow-cli"; then
  if assert_not_contains "$result" "aiterm"; then
    test_pass
  fi
fi

test_start "_proj_list_worktrees output includes worktree icon"
result=$(_proj_list_worktrees | head -1)
if assert_contains "$result" "🌳"; then
  test_pass
fi

# ============================================================================
# PICK COMMAND INVOCATION TESTS
# ============================================================================

echo ""
echo "── Pick Command Invocation ──"

test_start "pick help displays help text"
result=$(pick help 2>&1)
# Strip ANSI codes for matching
result_clean=$(echo "$result" | sed 's/\x1b\[[0-9;]*m//g')
if assert_contains "$result_clean" "PICK - Interactive Project Picker"; then
  if assert_contains "$result_clean" "USAGE"; then
    test_pass
  fi
fi

test_start "pick --help displays help text"
result=$(pick --help 2>&1)
# Strip ANSI codes for matching
result_clean=$(echo "$result" | sed 's/\x1b\[[0-9;]*m//g')
if assert_contains "$result_clean" "PICK - Interactive Project Picker"; then
  test_pass
fi

test_start "pick handles invalid category"
result=$(pick invalid-category-xyz 2>&1)
# Should show "No project matching" error message
if assert_contains "$result" "No project matching"; then
  test_pass
fi

# ============================================================================
# EDGE CASES
# ============================================================================

echo ""
echo "── Edge Cases ──"

test_start "pick handles missing fzf gracefully"
# Temporarily hide fzf (save and restore PATH)
OLD_PATH="$PATH"
export PATH="/tmp/empty-path-$$"
result=$(pick 2>&1)
export PATH="$OLD_PATH"
if assert_contains "$result" "fzf required"; then
  test_pass
fi

test_start "_proj_find handles empty query"
result=$(_proj_find "")
# Empty query matches everything (returns first project)
if [[ -n "$result" ]]; then
  test_pass
else
  test_fail "Empty query should match first project (fuzzy match)"
fi

test_start "_proj_list_all handles nonexistent category"
result=$(_proj_list_all "nonexistent-category-xyz")
if [[ -z "$result" ]]; then
  test_pass
else
  test_fail "Should return empty for nonexistent category"
fi

test_start "_proj_get_session_mtime handles missing directory"
result=$(_proj_get_session_mtime "/nonexistent/path")
if assert_equals "$result" "0"; then
  test_pass
fi

test_start "_proj_frecency_score handles negative timestamp"
score=$(_proj_frecency_score -1000)
# Should handle gracefully (not crash)
if [[ -n "$score" ]]; then
  test_pass
else
  test_fail "Should handle negative timestamp"
fi

# ============================================================================
# ALIAS TESTS
# ============================================================================

echo ""
echo "── Aliases ──"

test_start "pickr alias exists"
if alias pickr >/dev/null 2>&1; then
  test_pass
else
  test_fail "pickr alias should exist"
fi

test_start "pickdev alias exists"
if alias pickdev >/dev/null 2>&1; then
  test_pass
else
  test_fail "pickdev alias should exist"
fi

test_start "pickwt alias exists"
if alias pickwt >/dev/null 2>&1; then
  test_pass
else
  test_fail "pickwt alias should exist"
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
  echo ""
  exit 0
else
  echo "${RED}✗ SOME TESTS FAILED${RESET}"
  echo ""
  exit 1
fi
