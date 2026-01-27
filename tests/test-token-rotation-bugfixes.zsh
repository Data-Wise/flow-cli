#!/usr/bin/env zsh
# tests/test-token-rotation-bugfixes.zsh - Unit tests for token rotation bug fixes
# Run: zsh tests/test-token-rotation-bugfixes.zsh
#
# Bug fixes tested:
# 1. Inline comments after backslash breaking line continuation
# 2. User mismatch check too strict when old token expired
# 3. Token name not passed to _dot_token_github during rotation
# 4. Unhelpful "Find token for: unknown" message

# ============================================================================
# TEST SETUP
# ============================================================================

autoload -U colors && colors

typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -ga FAILED_TESTS=()

test_pass() {
  ((TESTS_PASSED++))
  echo "${fg[green]}✓${reset_color} $1"
}

test_fail() {
  ((TESTS_FAILED++))
  FAILED_TESTS+=("$1")
  echo "${fg[red]}✗${reset_color} $1"
  [[ -n "$2" ]] && echo "  ${fg[yellow]}→${reset_color} $2"
}

test_skip() {
  echo "${fg[yellow]}○${reset_color} $1 (skipped)"
}

# ============================================================================
# LOAD PLUGIN
# ============================================================================

echo ""
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg[cyan]}║${reset_color}  ${fg_bold[white]}Token Rotation Bug Fixes - Unit Tests${reset_color}               ${fg[cyan]}║${reset_color}"
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

SCRIPT_DIR="${0:A:h}"
PLUGIN_DIR="${SCRIPT_DIR:h}"

# Source the plugin
source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "${fg[red]}Failed to load plugin${reset_color}"
  exit 1
fi

echo "${fg[green]}✓${reset_color} Plugin loaded from $PLUGIN_DIR"
echo ""

# ============================================================================
# TEST 1: No inline comments after backslash in security commands
# ============================================================================

echo "${fg[cyan]}─── Test 1: Line continuation syntax ───${reset_color}"

# Check the source file for the bug pattern (comments after backslash)
((TESTS_RUN++))
local buggy_pattern=$(grep -n '\\ *#' "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" | \
  grep 'security add-generic-password' -A 5 | \
  grep '\\ *# ' || true)

if [[ -z "$buggy_pattern" ]]; then
  test_pass "No inline comments after backslash in security commands"
else
  test_fail "Found inline comments after backslash" "$buggy_pattern"
fi

# Verify the security command block is properly formatted
((TESTS_RUN++))
local security_block=$(sed -n '/Store in Keychain.*backend uses it/,/2>\/dev\/null$/p' \
  "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null | head -15)

if [[ "$security_block" == *'-U 2>/dev/null'* ]] && \
   [[ "$security_block" != *'# Account'* ]] && \
   [[ "$security_block" != *'# Service'* ]]; then
  test_pass "security add-generic-password block is clean"
else
  test_fail "security command block still has inline comments"
fi

echo ""

# ============================================================================
# TEST 2: User mismatch check allows "unknown" old user
# ============================================================================

echo "${fg[cyan]}─── Test 2: User mismatch logic ───${reset_color}"

# Check that the code skips user check when old_token_user is "unknown"
((TESTS_RUN++))
local mismatch_logic=$(grep -A 2 'old_token_user.*!=.*unknown' \
  "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null)

if [[ "$mismatch_logic" == *'old_token_user.*!=.*"unknown"'* ]] || \
   [[ -n "$(grep 'old_token_user" != "unknown"' "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh")" ]]; then
  test_pass "User mismatch check skips when old token is 'unknown'"
else
  test_fail "User mismatch check does not handle 'unknown' case"
fi

# Verify the info message exists for expired tokens
((TESTS_RUN++))
if grep -q 'Old token was expired - skipping user match check' \
   "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null; then
  test_pass "Info message for expired old token exists"
else
  test_fail "Missing info message for expired old token"
fi

echo ""

# ============================================================================
# TEST 3: _dot_token_github accepts token name argument
# ============================================================================

echo "${fg[cyan]}─── Test 3: Token name parameter passing ───${reset_color}"

# Check that _dot_token_github uses $1 for token_name
((TESTS_RUN++))
local token_name_param=$(grep 'local token_name="\$1"' \
  "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null | head -1 || true)

if [[ -n "$token_name_param" ]]; then
  test_pass "_dot_token_github accepts token name as first argument"
else
  test_fail "_dot_token_github does not accept token name argument"
fi

# Check that _dot_token_rotate passes token_name to wizard
((TESTS_RUN++))
if grep -q '_dot_token_github "\$token_name"' \
   "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null; then
  test_pass "_dot_token_rotate passes token_name to wizard"
else
  test_fail "_dot_token_rotate does not pass token_name to wizard"
fi

# Verify fallback prompt still works (for direct invocation)
((TESTS_RUN++))
local fallback_prompt=$(grep 'Token name \[github-token\]' \
  "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null || true)

if [[ -n "$fallback_prompt" ]]; then
  test_pass "Fallback prompt exists for direct invocation"
else
  test_fail "Missing fallback prompt for direct invocation"
fi

echo ""

# ============================================================================
# TEST 4: Revocation message handles unknown user
# ============================================================================

echo "${fg[cyan]}─── Test 4: Revocation message for unknown user ───${reset_color}"

# Check for conditional message based on old_token_user
((TESTS_RUN++))
if grep -q 'if \[\[ "\$old_token_user" != "unknown" \]\]' \
   "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null; then
  test_pass "Revocation message has conditional for unknown user"
else
  test_fail "Revocation message missing conditional for unknown user"
fi

# Check for helpful message when user is unknown
((TESTS_RUN++))
if grep -q 'Look for any expired/old tokens' \
   "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>/dev/null; then
  test_pass "Helpful message exists for unknown/expired tokens"
else
  test_fail "Missing helpful message for unknown/expired tokens"
fi

echo ""

# ============================================================================
# TEST 5: Function structure validation
# ============================================================================

echo "${fg[cyan]}─── Test 5: Function structure ───${reset_color}"

# Verify _dot_token_rotate exists
((TESTS_RUN++))
if (( $+functions[_dot_token_rotate] )); then
  test_pass "_dot_token_rotate function exists"
else
  test_fail "_dot_token_rotate function not found"
fi

# Verify _dot_token_github exists
((TESTS_RUN++))
if (( $+functions[_dot_token_github] )); then
  test_pass "_dot_token_github function exists"
else
  test_fail "_dot_token_github function not found"
fi

# Verify _dot_kc_add exists (keychain helper)
((TESTS_RUN++))
if (( $+functions[_dot_kc_add] )); then
  test_pass "_dot_kc_add function exists"
else
  test_fail "_dot_kc_add function not found"
fi

echo ""

# ============================================================================
# TEST 6: Syntax validation (no broken line continuations)
# ============================================================================

echo "${fg[cyan]}─── Test 6: Syntax validation ───${reset_color}"

# Check for syntax errors in the dispatcher
((TESTS_RUN++))
local syntax_check=$(zsh -n "$PLUGIN_DIR/lib/dispatchers/dot-dispatcher.zsh" 2>&1)
if [[ -z "$syntax_check" ]]; then
  test_pass "dot-dispatcher.zsh has valid syntax"
else
  test_fail "Syntax error in dot-dispatcher.zsh" "$syntax_check"
fi

# Check keychain helpers too
((TESTS_RUN++))
syntax_check=$(zsh -n "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>&1)
if [[ -z "$syntax_check" ]]; then
  test_pass "keychain-helpers.zsh has valid syntax"
else
  test_fail "Syntax error in keychain-helpers.zsh" "$syntax_check"
fi

echo ""

# ============================================================================
# TEST SUMMARY
# ============================================================================

echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: ${fg[green]}$TESTS_PASSED${reset_color}"
echo "Tests failed: ${fg[red]}$TESTS_FAILED${reset_color}"
echo ""

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
  echo "${fg[red]}Failed tests:${reset_color}"
  for test in "${FAILED_TESTS[@]}"; do
    echo "  - $test"
  done
  echo ""
fi

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${fg[green]}All tests passed!${reset_color}"
  exit 0
else
  echo "${fg[red]}Some tests failed${reset_color}"
  exit 1
fi
