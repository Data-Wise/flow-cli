#!/usr/bin/env zsh
# tests/test-keychain-default.zsh - Backend configuration tests
# Tests for the Keychain Default Phase 1 feature

# ============================================================================
# TEST SETUP
# ============================================================================

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Source the plugin
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$PROJECT_ROOT/flow.plugin.zsh"

# ============================================================================
# TEST HELPERS
# ============================================================================

test_pass() {
  ((TEST_COUNT++))
  ((PASS_COUNT++))
  echo "${GREEN}✓${NC} $1"
}

test_fail() {
  ((TEST_COUNT++))
  ((FAIL_COUNT++))
  echo "${RED}✗${NC} $1"
  [[ -n "$2" ]] && echo "  Expected: $2"
  [[ -n "$3" ]] && echo "  Got:      $3"
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "$actual" == "$expected" ]]; then
    test_pass "$message"
  else
    test_fail "$message" "$expected" "$actual"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    test_pass "$message"
  else
    test_fail "$message" "contains '$needle'" "not found"
  fi
}

# ============================================================================
# TEST: Backend Configuration
# ============================================================================

echo ""
echo "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo "${YELLOW} Test Suite: Keychain Default Phase 1 ${NC}"
echo "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo "${YELLOW}── Backend Configuration ──${NC}"

# Test 1: Default backend is keychain
unset FLOW_SECRET_BACKEND
local result=$(_dotf_secret_backend)
assert_eq "$result" "keychain" "Default backend is 'keychain'"

# Test 2: Keychain backend via env var
export FLOW_SECRET_BACKEND="keychain"
result=$(_dotf_secret_backend)
assert_eq "$result" "keychain" "FLOW_SECRET_BACKEND=keychain returns 'keychain'"

# Test 3: Bitwarden backend via env var
export FLOW_SECRET_BACKEND="bitwarden"
result=$(_dotf_secret_backend)
assert_eq "$result" "bitwarden" "FLOW_SECRET_BACKEND=bitwarden returns 'bitwarden'"

# Test 4: Both backend via env var
export FLOW_SECRET_BACKEND="both"
result=$(_dotf_secret_backend)
assert_eq "$result" "both" "FLOW_SECRET_BACKEND=both returns 'both'"

# Test 5: Invalid backend falls back to keychain
export FLOW_SECRET_BACKEND="invalid"
# Capture just the last line (the actual return value)
result=$(_dotf_secret_backend 2>/dev/null | tail -1)
assert_eq "$result" "keychain" "Invalid backend falls back to 'keychain'"

# Reset
unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST: Helper Functions
# ============================================================================

echo ""
echo "${YELLOW}── Helper Functions ──${NC}"

# Test 6: _dotf_secret_needs_bitwarden with keychain backend
unset FLOW_SECRET_BACKEND
if _dotf_secret_needs_bitwarden; then
  test_fail "keychain backend should not need Bitwarden"
else
  test_pass "keychain backend does not need Bitwarden"
fi

# Test 7: _dotf_secret_needs_bitwarden with bitwarden backend
export FLOW_SECRET_BACKEND="bitwarden"
if _dotf_secret_needs_bitwarden; then
  test_pass "bitwarden backend needs Bitwarden"
else
  test_fail "bitwarden backend should need Bitwarden"
fi

# Test 8: _dotf_secret_needs_bitwarden with both backend
export FLOW_SECRET_BACKEND="both"
if _dotf_secret_needs_bitwarden; then
  test_pass "both backend needs Bitwarden"
else
  test_fail "both backend should need Bitwarden"
fi

# Test 9: _dotf_secret_uses_keychain with keychain backend
unset FLOW_SECRET_BACKEND
if _dotf_secret_uses_keychain; then
  test_pass "keychain backend uses Keychain"
else
  test_fail "keychain backend should use Keychain"
fi

# Test 10: _dotf_secret_uses_keychain with bitwarden backend
export FLOW_SECRET_BACKEND="bitwarden"
if _dotf_secret_uses_keychain; then
  test_fail "bitwarden backend should not use Keychain"
else
  test_pass "bitwarden backend does not use Keychain"
fi

# Test 11: _dotf_secret_uses_keychain with both backend
export FLOW_SECRET_BACKEND="both"
if _dotf_secret_uses_keychain; then
  test_pass "both backend uses Keychain"
else
  test_fail "both backend should use Keychain"
fi

# Reset
unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST: Status Command
# ============================================================================

echo ""
echo "${YELLOW}── Status Command ──${NC}"

# Test 12: Status command exists
if type _sec_status &>/dev/null; then
  test_pass "_sec_status function exists"
else
  test_fail "_sec_status function should exist"
fi

# Test 13: Status output contains backend info
unset FLOW_SECRET_BACKEND
local status_output=$(_sec_status 2>/dev/null)
assert_contains "$status_output" "keychain" "Status shows keychain backend"

# Test 14: Status output contains configuration
assert_contains "$status_output" "Configuration" "Status shows configuration section"

# ============================================================================
# TEST: Sync Command
# ============================================================================

echo ""
echo "${YELLOW}── Sync Command ──${NC}"

# Test 15: Sync function exists
if type _sec_sync &>/dev/null; then
  test_pass "_sec_sync function exists"
else
  test_fail "_sec_sync function should exist"
fi

# Test 16: Sync help exists
local sync_help=$(_sec_sync_help 2>/dev/null)
assert_contains "$sync_help" "sync" "Sync help mentions sync"

# ============================================================================
# TEST: Command Routing
# ============================================================================

echo ""
echo "${YELLOW}── Command Routing ──${NC}"

# Test 17: sec dispatches correctly
if type _sec_get &>/dev/null; then
  test_pass "_sec_get dispatcher exists"
else
  test_fail "_sec_get dispatcher should exist"
fi

# Test 18: Help includes status command
local help_output=$(_dotf_kc_help 2>/dev/null)
assert_contains "$help_output" "status" "Help mentions status command"

# Test 19: Help includes sync command
assert_contains "$help_output" "sync" "Help mentions sync command"

# Test 20: Help includes backend configuration
assert_contains "$help_output" "FLOW_SECRET_BACKEND" "Help mentions backend configuration"

# ============================================================================
# RESULTS
# ============================================================================

echo ""
echo "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo "Results: ${PASS_COUNT}/${TEST_COUNT} passed"
if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "${GREEN}All tests passed!${NC}"
else
  echo "${RED}${FAIL_COUNT} tests failed${NC}"
fi
echo "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Clean up
unset FLOW_SECRET_BACKEND

# Exit with appropriate code
[[ $FAIL_COUNT -eq 0 ]]
