#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Phase 3 Tests: Secret Management (Bitwarden Integration)
# ══════════════════════════════════════════════════════════════════════════════

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_start() {
  echo -e "\n${BLUE}Testing:${NC} $1"
}

test_pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_FAILED++))
}

test_skip() {
  echo -e "${YELLOW}⊘${NC} $1"
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════"
echo " Phase 3 Secret Management Tests"
echo "═══════════════════════════════════════════════════════════════"

# Load plugin
SCRIPT_DIR="${0:A:h}"
PLUGIN_ROOT="${SCRIPT_DIR:h}"

echo "Loading plugin from: $PLUGIN_ROOT"
source "$PLUGIN_ROOT/flow.plugin.zsh"

# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE
# ══════════════════════════════════════════════════════════════════════════════

# Test 1: dot version shows Phase 3
test_start "Version shows Phase 3"
VERSION_OUTPUT=$(dot version 2>&1)
if echo "$VERSION_OUTPUT" | grep -q "v1.2.0 (Phase 3 - Secret Management)"; then
  test_pass "Version is v1.2.0 (Phase 3)"
else
  test_fail "Version should be v1.2.0 (Phase 3), got: $VERSION_OUTPUT"
fi

# Test 2: dot help shows Phase 3 as complete
test_start "Help shows Phase 3 as complete"
HELP_OUTPUT=$(dot help 2>&1)
if echo "$HELP_OUTPUT" | grep -q "✓ Phase 3: Secret management"; then
  test_pass "Phase 3 marked as complete in help"
else
  test_fail "Phase 3 should be marked complete"
fi

# Test 3: dot help includes secret commands
test_start "Help includes secret management commands"
if echo "$HELP_OUTPUT" | grep -q "dot unlock"; then
  test_pass "dot unlock listed in help"
else
  test_fail "dot unlock not found in help"
fi

if echo "$HELP_OUTPUT" | grep -q "dot secret NAME"; then
  test_pass "dot secret NAME listed in help"
else
  test_fail "dot secret NAME not found in help"
fi

if echo "$HELP_OUTPUT" | grep -q "dot secret list"; then
  test_pass "dot secret list listed in help"
else
  test_fail "dot secret list not found in help"
fi

# Test 4: Check if _dot_unlock function exists
test_start "Function _dot_unlock exists"
if typeset -f _dot_unlock >/dev/null; then
  test_pass "_dot_unlock function defined"
else
  test_fail "_dot_unlock function not found"
fi

# Test 5: Check if _dot_secret function exists
test_start "Function _dot_secret exists"
if typeset -f _dot_secret >/dev/null; then
  test_pass "_dot_secret function defined"
else
  test_fail "_dot_secret function not found"
fi

# Test 6: Check if _dot_secret_list function exists
test_start "Function _dot_secret_list exists"
if typeset -f _dot_secret_list >/dev/null; then
  test_pass "_dot_secret_list function defined"
else
  test_fail "_dot_secret_list function not found"
fi

# Test 7: Check if _dot_security_init function exists
test_start "Function _dot_security_init exists"
if typeset -f _dot_security_init >/dev/null; then
  test_pass "_dot_security_init function defined"
else
  test_fail "_dot_security_init function not found"
fi

# Test 8: Check if _dot_security_check_bw_session function exists
test_start "Function _dot_security_check_bw_session exists"
if typeset -f _dot_security_check_bw_session >/dev/null; then
  test_pass "_dot_security_check_bw_session function defined"
else
  test_fail "_dot_security_check_bw_session function not found"
fi

# Test 9: Check HISTIGNORE is set
test_start "HISTIGNORE includes Bitwarden commands"
if [[ -n "$HISTIGNORE" ]] && [[ "$HISTIGNORE" =~ "bw unlock" ]]; then
  test_pass "HISTIGNORE includes bw unlock"
else
  test_fail "HISTIGNORE should include bw unlock patterns"
fi

# Test 10: dot unlock without bw should show error
test_start "dot unlock without Bitwarden CLI shows install message"
if ! command -v bw &>/dev/null; then
  UNLOCK_OUTPUT=$(dot unlock 2>&1)
  if echo "$UNLOCK_OUTPUT" | grep -q "brew install bitwarden-cli"; then
    test_pass "Shows install instructions when bw not found"
  else
    test_fail "Should show install instructions"
  fi
else
  test_skip "Bitwarden CLI is installed, skipping no-tool test"
fi

# Test 11: dot secret without arguments shows usage
test_start "dot secret without arguments shows usage"
SECRET_OUTPUT=$(dot secret 2>&1)
if echo "$SECRET_OUTPUT" | grep -q "Usage: dot secret <name>"; then
  test_pass "Shows usage message"
else
  test_fail "Should show usage message"
fi

# Test 12: dot secret list without session shows error
test_start "dot secret list without session shows error"
unset BW_SESSION
if command -v bw &>/dev/null; then
  LIST_OUTPUT=$(dot secret list 2>&1)
  if echo "$LIST_OUTPUT" | grep -q "vault is locked"; then
    test_pass "Shows locked vault error"
  else
    test_fail "Should show locked vault error"
  fi
else
  test_skip "Bitwarden CLI not installed"
fi

# Test 13: _dot_bw_session_valid returns false without session
test_start "_dot_bw_session_valid returns false without BW_SESSION"
unset BW_SESSION
if _dot_bw_session_valid; then
  test_fail "Should return false when BW_SESSION not set"
else
  test_pass "Returns false when session not active"
fi

# Test 14: Check documentation file exists
test_start "SECRET-MANAGEMENT.md documentation exists"
if [[ -f "$PLUGIN_ROOT/docs/SECRET-MANAGEMENT.md" ]]; then
  test_pass "Documentation file exists"
else
  test_fail "Documentation file not found"
fi

# Test 15: Documentation includes template examples
test_start "Documentation includes chezmoi template examples"
if [[ -f "$PLUGIN_ROOT/docs/SECRET-MANAGEMENT.md" ]]; then
  DOC_CONTENT=$(cat "$PLUGIN_ROOT/docs/SECRET-MANAGEMENT.md")
  if echo "$DOC_CONTENT" | grep -q "bitwarden \"item\""; then
    test_pass "Documentation includes template syntax"
  else
    test_fail "Documentation should include template examples"
  fi
else
  test_skip "Documentation file not found"
fi

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Test Results"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
