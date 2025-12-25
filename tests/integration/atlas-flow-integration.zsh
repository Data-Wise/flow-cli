#!/usr/bin/env zsh
# tests/integration/atlas-flow-integration.zsh
# Integration tests for atlas + flow-cli coordination
#
# Run: ./tests/integration/atlas-flow-integration.zsh

set -e

# ============================================================================
# TEST SETUP
# ============================================================================

TEST_DIR=$(mktemp -d)
ATLAS_HOME="$TEST_DIR/.atlas"
FLOW_DATA_DIR="$TEST_DIR/.flow/data"
TEST_PROJECT="$TEST_DIR/test-project"

export ATLAS_HOME FLOW_DATA_DIR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# TEST UTILITIES
# ============================================================================

log_test() {
  echo -e "\n${YELLOW}TEST:${NC} $1"
  ((TESTS_RUN++))
}

pass() {
  echo -e "  ${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
}

fail() {
  echo -e "  ${RED}✗ FAIL${NC}: $1"
  ((TESTS_FAILED++))
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$msg"
  else
    fail "$msg (expected: '$expected', got: '$actual')"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$msg"
  else
    fail "$msg (expected to contain: '$needle')"
  fi
}

assert_file_exists() {
  local file="$1"
  local msg="$2"
  if [[ -f "$file" ]]; then
    pass "$msg"
  else
    fail "$msg (file not found: $file)"
  fi
}

assert_command_exists() {
  local cmd="$1"
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd command exists"
    return 0
  else
    fail "$cmd command not found"
    return 1
  fi
}

cleanup() {
  echo -e "\n${YELLOW}Cleaning up...${NC}"
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  ATLAS + FLOW-CLI INTEGRATION TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check for atlas
log_test "Pre-flight: Check atlas installation"
if assert_command_exists "atlas"; then
  ATLAS_VERSION=$(atlas -v 2>/dev/null || echo "unknown")
  echo "  Atlas version: $ATLAS_VERSION"
else
  echo -e "${RED}ERROR: atlas not installed. Install with: npm install -g @data-wise/atlas${NC}"
  exit 1
fi

# Check for flow-cli functions (source if needed)
log_test "Pre-flight: Check flow-cli functions"
if type _flow_has_atlas &>/dev/null; then
  pass "flow-cli functions loaded"
else
  # Try to source flow.plugin.zsh
  FLOW_CLI_DIR="${0:a:h:h:h}"  # Go up 3 levels from this script
  if [[ -f "$FLOW_CLI_DIR/flow.plugin.zsh" ]]; then
    source "$FLOW_CLI_DIR/flow.plugin.zsh"
    pass "flow-cli functions sourced from $FLOW_CLI_DIR"
  else
    fail "flow-cli functions not available"
    echo -e "${RED}ERROR: Could not find flow.plugin.zsh${NC}"
    exit 1
  fi
fi

# ============================================================================
# SETUP TEST ENVIRONMENT
# ============================================================================

log_test "Setup: Create test directories"
mkdir -p "$ATLAS_HOME" "$FLOW_DATA_DIR" "$TEST_PROJECT"
pass "Created test directories"

log_test "Setup: Create test project with .STATUS"
cat > "$TEST_PROJECT/.STATUS" << 'EOF'
# test-project

## Status: Active
## Phase: Testing
## Focus: Integration tests

## Recent Activity
- Testing atlas + flow-cli integration
EOF
pass "Created test project .STATUS"

# Initialize atlas
log_test "Setup: Initialize atlas"
cd "$TEST_PROJECT"
atlas init --global 2>/dev/null || true
pass "Atlas initialized"

# Register test project
log_test "Setup: Register test project"
atlas project add "$TEST_PROJECT" 2>/dev/null
pass "Test project registered"

# ============================================================================
# TEST: PROJECT OPERATIONS
# ============================================================================

log_test "Project: List projects via atlas"
PROJECTS=$(atlas project list --format=names 2>/dev/null)
assert_contains "$PROJECTS" "test-project" "Project appears in list"

log_test "Project: Get project via _flow_get_project"
PROJECT_INFO=$(_flow_get_project "test-project" 2>/dev/null)
assert_contains "$PROJECT_INFO" "test-project" "Project info returned"

log_test "Project: --format=shell output is eval-able"
if eval "$PROJECT_INFO" 2>/dev/null; then
  assert_equals "test-project" "$name" "Project name parsed correctly"
else
  fail "Could not eval project info"
fi

# ============================================================================
# TEST: SESSION OPERATIONS
# ============================================================================

log_test "Session: Start session via atlas"
atlas session start "test-project" 2>/dev/null
SESSION_STATUS=$(atlas session status --format=json 2>/dev/null || echo "{}")
assert_contains "$SESSION_STATUS" "test-project" "Session started with project"

log_test "Session: _flow_session_start works"
# End current session first
atlas session end 2>/dev/null || true
_flow_session_start "test-project"
SESSION_STATUS=$(atlas session status --format=json 2>/dev/null || echo "{}")
assert_contains "$SESSION_STATUS" "test-project" "Session started via flow bridge"

log_test "Session: End session via atlas"
atlas session end "test complete" 2>/dev/null
SESSION_STATUS=$(atlas session status --format=json 2>/dev/null || echo "{}")
if [[ "$SESSION_STATUS" == *"No active"* ]] || [[ -z $(echo "$SESSION_STATUS" | grep '"project"') ]]; then
  pass "Session ended correctly"
else
  fail "Session still active after end"
fi

# ============================================================================
# TEST: CAPTURE OPERATIONS
# ============================================================================

log_test "Capture: Quick capture via atlas"
atlas catch "Test idea from integration test" 2>/dev/null
INBOX=$(atlas inbox 2>/dev/null)
assert_contains "$INBOX" "Test idea" "Capture appears in inbox"

log_test "Capture: _flow_catch works"
_flow_catch "Another test idea"
INBOX=$(atlas inbox 2>/dev/null)
assert_contains "$INBOX" "Another test" "Capture via flow bridge works"

log_test "Capture: _flow_inbox returns items"
INBOX_RESULT=$(_flow_inbox 2>/dev/null)
if [[ -n "$INBOX_RESULT" ]]; then
  pass "Inbox returns items"
else
  fail "Inbox empty or failed"
fi

# ============================================================================
# TEST: CONTEXT OPERATIONS
# ============================================================================

log_test "Context: Where command via atlas"
atlas session start "test-project" 2>/dev/null
WHERE=$(atlas where 2>/dev/null)
assert_contains "$WHERE" "test-project" "Where shows current project"

log_test "Context: _flow_where works"
WHERE_FLOW=$(_flow_where 2>/dev/null)
if [[ -n "$WHERE_FLOW" ]]; then
  pass "_flow_where returns context"
else
  fail "_flow_where failed"
fi

log_test "Context: Breadcrumb via atlas"
atlas crumb "Test breadcrumb" 2>/dev/null
TRAIL=$(atlas trail 2>/dev/null)
assert_contains "$TRAIL" "Test breadcrumb" "Breadcrumb appears in trail"

log_test "Context: _flow_crumb works"
_flow_crumb "Flow breadcrumb test"
TRAIL=$(atlas trail 2>/dev/null)
assert_contains "$TRAIL" "Flow breadcrumb" "Breadcrumb via flow bridge works"

# End session
atlas session end 2>/dev/null || true

# ============================================================================
# TEST: FALLBACK OPERATIONS
# ============================================================================

log_test "Fallback: Operations work without atlas"
# Temporarily hide atlas
REAL_PATH="$PATH"
export PATH="/usr/bin:/bin"
unset _FLOW_ATLAS_AVAILABLE

# Test fallback capture
_flow_catch "Fallback test capture"
assert_file_exists "$FLOW_DATA_DIR/inbox.md" "Fallback inbox file created"

if grep -q "Fallback test" "$FLOW_DATA_DIR/inbox.md" 2>/dev/null; then
  pass "Fallback capture saved to file"
else
  fail "Fallback capture not saved"
fi

# Restore PATH
export PATH="$REAL_PATH"
_flow_refresh_atlas

# ============================================================================
# TEST: OUTPUT FORMAT COMPATIBILITY
# ============================================================================

log_test "Format: --format=json works"
JSON_OUTPUT=$(atlas project list --format=json 2>/dev/null)
if echo "$JSON_OUTPUT" | python3 -m json.tool &>/dev/null; then
  pass "JSON output is valid"
else
  fail "JSON output is invalid"
fi

log_test "Format: --format=names produces clean list"
NAMES_OUTPUT=$(atlas project list --format=names 2>/dev/null)
# Check it's one name per line, no JSON brackets
if [[ "$NAMES_OUTPUT" != *"["* ]] && [[ "$NAMES_OUTPUT" != *"{"* ]]; then
  pass "Names output is clean"
else
  fail "Names output contains JSON artifacts"
fi

log_test "Format: --format=shell is eval-able"
SHELL_OUTPUT=$(atlas project show test-project --format=shell 2>/dev/null)
if eval "$SHELL_OUTPUT" 2>/dev/null && [[ -n "$name" ]]; then
  pass "Shell output is eval-able"
else
  fail "Shell output cannot be evaled"
fi

# ============================================================================
# TEST SUMMARY
# ============================================================================

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  TEST SUMMARY${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Tests run:    $TESTS_RUN"
echo -e "  ${GREEN}Passed:       $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed:       $TESTS_FAILED${NC}"
echo ""

if (( TESTS_FAILED > 0 )); then
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
