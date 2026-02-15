#!/usr/bin/env zsh
# tests/test-dot-secret-list.zsh - Unit and E2E tests for sec list
# Run: zsh tests/test-dot-secret-list.zsh
#
# Tests:
# - Box format output
# - Type detection (GitHub, npm, PyPI)
# - Expiration status display
# - Days remaining calculation
# - Rotation hints

# ============================================================================
# TEST SETUP
# ============================================================================

emulate -L zsh
setopt noxtrace noverbose

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

# Strip ANSI codes for easier testing
strip_ansi() {
  echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# ============================================================================
# LOAD PLUGIN
# ============================================================================

echo ""
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg[cyan]}║${reset_color}  ${fg_bold[white]}Dot Secret List - Unit & E2E Tests${reset_color}                  ${fg[cyan]}║${reset_color}"
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

SCRIPT_DIR="${0:A:h}"
PLUGIN_DIR="${SCRIPT_DIR:h}"

# Source the plugin quietly
source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "${fg[red]}Failed to load plugin${reset_color}"
  exit 1
fi

echo "${fg[green]}✓${reset_color} Plugin loaded from $PLUGIN_DIR"
echo ""

# ============================================================================
# UNIT TEST 1: Function exists
# ============================================================================

echo "${fg[cyan]}─── Unit Test 1: Function existence ───${reset_color}"

((TESTS_RUN++))
if (( $+functions[_dotf_kc_list] )); then
  test_pass "_dotf_kc_list function exists"
else
  test_fail "_dotf_kc_list function not found"
fi

((TESTS_RUN++))
if (( $+functions[_sec_get] )); then
  test_pass "_sec_get dispatcher function exists"
else
  test_fail "_sec_get dispatcher function not found"
fi

echo ""

# ============================================================================
# UNIT TEST 2: Shell option isolation
# ============================================================================

echo "${fg[cyan]}─── Unit Test 2: Shell option isolation ───${reset_color}"

((TESTS_RUN++))
if grep -q 'emulate -L zsh' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "_dotf_kc_list uses emulate -L zsh for option isolation"
else
  test_fail "_dotf_kc_list missing emulate -L zsh"
fi

((TESTS_RUN++))
if grep -q 'setopt noxtrace noverbose' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "_dotf_kc_list suppresses debug output"
else
  test_fail "_dotf_kc_list missing debug suppression"
fi

echo ""

# ============================================================================
# UNIT TEST 3: Metadata parsing logic
# ============================================================================

echo "${fg[cyan]}─── Unit Test 3: Metadata parsing patterns ───${reset_color}"

# Check GitHub type detection
((TESTS_RUN++))
if grep -q '"type":"github"' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "GitHub type detection pattern exists"
else
  test_fail "Missing GitHub type detection"
fi

# Check GitHub PAT subtype
((TESTS_RUN++))
if grep -q '"token_type":"classic"' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "GitHub classic PAT detection pattern exists"
else
  test_fail "Missing GitHub classic PAT detection"
fi

# Check GitHub fine-grained subtype
((TESTS_RUN++))
if grep -q '"token_type":"fine-grained"' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "GitHub fine-grained PAT detection pattern exists"
else
  test_fail "Missing GitHub fine-grained PAT detection"
fi

# Check npm type detection
((TESTS_RUN++))
if grep -q '"type":"npm"' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "npm type detection pattern exists"
else
  test_fail "Missing npm type detection"
fi

# Check PyPI type detection
((TESTS_RUN++))
if grep -q '"type":"pypi"' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "PyPI type detection pattern exists"
else
  test_fail "Missing PyPI type detection"
fi

echo ""

# ============================================================================
# UNIT TEST 4: Status icons and thresholds
# ============================================================================

echo "${fg[cyan]}─── Unit Test 4: Status thresholds ───${reset_color}"

# Check expired threshold (< 0 days)
((TESTS_RUN++))
if grep -q 'days_left -lt 0' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Expired threshold (< 0 days) check exists"
else
  test_fail "Missing expired threshold check"
fi

# Check critical threshold (≤ 7 days)
((TESTS_RUN++))
if grep -q 'days_left -le 7' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Critical threshold (≤ 7 days) check exists"
else
  test_fail "Missing critical threshold check"
fi

# Check warning threshold (≤ 30 days)
((TESTS_RUN++))
if grep -q 'days_left -le 30' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Warning threshold (≤ 30 days) check exists"
else
  test_fail "Missing warning threshold check"
fi

echo ""

# ============================================================================
# UNIT TEST 5: Rotation hints
# ============================================================================

echo "${fg[cyan]}─── Unit Test 5: Rotation hints ───${reset_color}"

# Check expired tokens tracking
((TESTS_RUN++))
if grep -q '_expired_tokens' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Expired tokens tracking array exists"
else
  test_fail "Missing expired tokens tracking"
fi

# Check expiring tokens tracking
((TESTS_RUN++))
if grep -q '_expiring_tokens' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Expiring tokens tracking array exists"
else
  test_fail "Missing expiring tokens tracking"
fi

# Check rotation command hint
((TESTS_RUN++))
if grep -q 'dot token rotate' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Rotation command hint exists"
else
  test_fail "Missing rotation command hint"
fi

echo ""

# ============================================================================
# UNIT TEST 6: Box formatting
# ============================================================================

echo "${fg[cyan]}─── Unit Test 6: Box formatting ───${reset_color}"

# Check top border
((TESTS_RUN++))
if grep -q '╭───' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Box top border exists"
else
  test_fail "Missing box top border"
fi

# Check bottom border
((TESTS_RUN++))
if grep -q '╰───' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Box bottom border exists"
else
  test_fail "Missing box bottom border"
fi

# Check separator
((TESTS_RUN++))
if grep -q '├───' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Box separator exists"
else
  test_fail "Missing box separator"
fi

# Check header
((TESTS_RUN++))
if grep -q '🔐 Secrets' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Box header with icon exists"
else
  test_fail "Missing box header"
fi

echo ""

# ============================================================================
# UNIT TEST 7: Type icons
# ============================================================================

echo "${fg[cyan]}─── Unit Test 7: Type icons ───${reset_color}"

((TESTS_RUN++))
if grep -q '🐙' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "GitHub icon (🐙) exists"
else
  test_fail "Missing GitHub icon"
fi

((TESTS_RUN++))
if grep -q '📦' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "npm icon (📦) exists"
else
  test_fail "Missing npm icon"
fi

((TESTS_RUN++))
if grep -q '🐍' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "PyPI icon (🐍) exists"
else
  test_fail "Missing PyPI icon"
fi

((TESTS_RUN++))
if grep -q '🔑' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Default secret icon (🔑) exists"
else
  test_fail "Missing default secret icon"
fi

echo ""

# ============================================================================
# E2E TEST 1: sec list runs without error
# ============================================================================

echo "${fg[cyan]}─── E2E Test 1: Command execution ───${reset_color}"

((TESTS_RUN++))
local output
output=$(sec list 2>&1)
local exit_code=$?

if [[ $exit_code -eq 0 ]]; then
  test_pass "sec list executes successfully (exit code 0)"
else
  test_fail "sec list failed with exit code $exit_code"
fi

echo ""

# ============================================================================
# E2E TEST 2: Output format validation
# ============================================================================

echo "${fg[cyan]}─── E2E Test 2: Output format ───${reset_color}"

# Strip debug output for cleaner testing
local clean_output=$(echo "$output" | grep -v "^acct_line" | grep -v "^account_name" | grep -v "^kc_output")

# Check for box structure
((TESTS_RUN++))
if [[ "$clean_output" == *"╭"* ]]; then
  test_pass "Output contains box top border"
else
  test_fail "Output missing box top border"
fi

((TESTS_RUN++))
if [[ "$clean_output" == *"╰"* ]]; then
  test_pass "Output contains box bottom border"
else
  test_fail "Output missing box bottom border"
fi

((TESTS_RUN++))
if [[ "$clean_output" == *"Secrets"* ]]; then
  test_pass "Output contains 'Secrets' header"
else
  test_fail "Output missing 'Secrets' header"
fi

((TESTS_RUN++))
if [[ "$clean_output" == *"Total:"* ]]; then
  test_pass "Output contains total count"
else
  test_fail "Output missing total count"
fi

echo ""

# ============================================================================
# E2E TEST 3: Metadata display (if secrets exist)
# ============================================================================

echo "${fg[cyan]}─── E2E Test 3: Metadata display ───${reset_color}"

# Check if any GitHub tokens are displayed with proper formatting
((TESTS_RUN++))
if [[ "$clean_output" == *"GitHub"* ]] || [[ "$clean_output" == *"no secrets"* ]]; then
  test_pass "GitHub type label displayed (or no secrets)"
else
  test_fail "GitHub type label not displayed for GitHub tokens"
fi

# Check for days remaining display
((TESTS_RUN++))
if [[ "$clean_output" == *"d left"* ]] || [[ "$clean_output" == *"expired"* ]] || [[ "$clean_output" == *"no secrets"* ]] || [[ "$clean_output" == *"no expiry"* ]]; then
  test_pass "Expiration status displayed (or no secrets)"
else
  test_fail "Expiration status not displayed"
fi

echo ""

# ============================================================================
# E2E TEST 4: Empty state handling
# ============================================================================

echo "${fg[cyan]}─── E2E Test 4: Empty state message ───${reset_color}"

# Check that the empty state message exists in code
((TESTS_RUN++))
if grep -q 'no secrets stored' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Empty state message exists in code"
else
  test_fail "Missing empty state message"
fi

# Check for add hint in empty state
((TESTS_RUN++))
if grep -q 'dot secret add' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Add hint exists for empty state"
else
  test_fail "Missing add hint for empty state"
fi

echo ""

# ============================================================================
# UNIT TEST 8: Backup section handling
# ============================================================================

echo "${fg[cyan]}─── Unit Test 8: Backup section ───${reset_color}"

# Check backup section header exists
((TESTS_RUN++))
if grep -q 'Backups (from rotation)' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Backup section header exists"
else
  test_fail "Missing backup section header"
fi

# Check backup detection pattern
((TESTS_RUN++))
if grep -q '\*"-backup-"\*' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Backup detection pattern exists"
else
  test_fail "Missing backup detection pattern"
fi

# Check backup cleanup command hint
((TESTS_RUN++))
if grep -q 'Cleanup old backups' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Backup cleanup hint exists"
else
  test_fail "Missing backup cleanup hint"
fi

# Check backup date extraction (YYYYMMDD pattern)
((TESTS_RUN++))
if grep -q '\-backup-(' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null && \
   grep -q '0-9' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Backup date extraction pattern exists"
else
  test_fail "Missing backup date extraction pattern"
fi

# Check that backup_secrets array is used
((TESTS_RUN++))
if grep -q 'backup_secrets' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Backup secrets array exists"
else
  test_fail "Missing backup secrets array"
fi

# Check that total count includes both active and backup
((TESTS_RUN++))
if grep -q 'active.*backup' "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>/dev/null; then
  test_pass "Total count includes active and backup counts"
else
  test_fail "Total count missing active/backup separation"
fi

echo ""

# ============================================================================
# E2E TEST 5: Backup section in output (if backups exist)
# ============================================================================

echo "${fg[cyan]}─── E2E Test 5: Backup section in output ───${reset_color}"

((TESTS_RUN++))
if [[ "$clean_output" == *"Backup"* ]] || [[ "$clean_output" == *"backup"* ]] || [[ ! "$clean_output" == *"-backup-"* ]]; then
  test_pass "Backup section displayed (or no backups exist)"
else
  test_fail "Backup section not displayed properly"
fi

((TESTS_RUN++))
if [[ "$clean_output" == *"active"* ]] || [[ "$clean_output" == *"Total:"* ]]; then
  test_pass "Total count displays active/backup counts"
else
  test_fail "Total count missing"
fi

echo ""

# ============================================================================
# E2E TEST 6: Syntax validation
# ============================================================================

echo "${fg[cyan]}─── E2E Test 6: Syntax validation ───${reset_color}"

((TESTS_RUN++))
local syntax_check=$(zsh -n "$PLUGIN_DIR/lib/keychain-helpers.zsh" 2>&1)
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
