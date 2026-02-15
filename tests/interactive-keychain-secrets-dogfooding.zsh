#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOGFOODING TEST: macOS Keychain Secrets (v5.5.0)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Test the complete macOS Keychain secret management feature
#
# Features Tested:
#   - sec add <name>     - Store secret in Keychain
#   - sec <name>         - Retrieve secret (Touch ID)
#   - sec get <name>     - Explicit get
#   - sec list           - List all secrets
#   - sec delete <name>  - Remove secret
#   - sec help           - Show help
#
# Usage: ./tests/interactive-keychain-secrets-dogfooding.zsh
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Emojis
CHECK='✅'
CROSS='❌'
KEY='🔑'
LOCK='🔐'
APPLE='🍎'
ROCKET='🚀'
WARN='⚠️'
INFO='ℹ️'
FINGER='👆'

# Test state
SCRIPT_DIR="${0:A:h}"
PASSED=0
FAILED=0
SKIPPED=0
TEST_SECRET_NAME="flow-cli-dogfood-test-$$"
TEST_SECRET_VALUE="secret-value-$(date +%s)"

# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${LOCK}  ${BOLD}macOS Keychain Secrets - Dogfooding Test${NC}                   ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     ${DIM}v5.5.0 - Touch ID / Apple Watch / Instant Access${NC}           ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${KEY} ${BOLD}$title${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────┘${NC}"
}

print_test() {
    local name="$1"
    echo -e "\n${MAGENTA}▶${NC} ${BOLD}$name${NC}"
}

pass() {
    echo -e "  ${GREEN}${CHECK} PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${RED}${CROSS} FAIL${NC}: $1"
    ((FAILED++))
}

skip() {
    echo -e "  ${YELLOW}${WARN} SKIP${NC}: $1"
    ((SKIPPED++))
}

info() {
    echo -e "  ${DIM}${INFO} $1${NC}"
}

prompt_continue() {
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

cleanup_test_secret() {
    # Silently remove test secret if it exists
    security delete-generic-password \
        -a "$TEST_SECRET_NAME" \
        -s "flow-cli-secrets" &>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

print_banner

echo -e "${BLUE}Loading flow-cli...${NC}"
source "$SCRIPT_DIR/../flow.plugin.zsh" 2>/dev/null || {
    echo -e "${RED}Failed to source flow.plugin.zsh${NC}"
    exit 1
}
echo -e "${GREEN}${CHECK} Plugin loaded${NC}"

# Cleanup any leftover test secrets
cleanup_test_secret

echo ""
echo -e "${YELLOW}${FINGER} This test will interact with your macOS Keychain${NC}"
echo -e "${DIM}   Touch ID prompts may appear during testing${NC}"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# TEST 1: Functions Exist
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 1: Function Availability"

print_test "Check _dotf_kc_add exists"
if type _dotf_kc_add &>/dev/null; then
    pass "_dotf_kc_add is defined"
else
    fail "_dotf_kc_add not found"
fi

print_test "Check _dotf_kc_get exists"
if type _dotf_kc_get &>/dev/null; then
    pass "_dotf_kc_get is defined"
else
    fail "_dotf_kc_get not found"
fi

print_test "Check _dotf_kc_list exists"
if type _dotf_kc_list &>/dev/null; then
    pass "_dotf_kc_list is defined"
else
    fail "_dotf_kc_list not found"
fi

print_test "Check _dotf_kc_delete exists"
if type _dotf_kc_delete &>/dev/null; then
    pass "_dotf_kc_delete is defined"
else
    fail "_dotf_kc_delete not found"
fi

print_test "Check _sec router exists"
if type _sec &>/dev/null; then
    pass "_sec router is defined"
else
    fail "_sec router not found"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 2: Help Command
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 2: Help System"

print_test "sec help"
echo -e "${DIM}Running: sec help${NC}"
echo ""
sec help 2>&1 | head -15
echo ""

if sec help 2>&1 | grep -q "Keychain"; then
    pass "Help mentions Keychain"
else
    fail "Help doesn't mention Keychain"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 3: Add Secret (Automated)
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 3: Add Secret (Automated)"

print_test "Add test secret directly via security command"
info "Using: security add-generic-password"
info "Secret name: $TEST_SECRET_NAME"
info "Secret value: $TEST_SECRET_VALUE"

if security add-generic-password \
    -a "$TEST_SECRET_NAME" \
    -s "flow-cli-secrets" \
    -w "$TEST_SECRET_VALUE" \
    -U 2>/dev/null; then
    pass "Secret added to Keychain"
else
    fail "Failed to add secret"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 4: Get Secret
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 4: Retrieve Secret"

print_test "sec get $TEST_SECRET_NAME"
echo -e "${DIM}Running: sec get $TEST_SECRET_NAME${NC}"
echo -e "${YELLOW}${FINGER} Touch ID may prompt now...${NC}"

retrieved=$(sec get "$TEST_SECRET_NAME" 2>&1)
exit_code=$?

echo ""
info "Retrieved value: ${retrieved:0:20}..."
info "Exit code: $exit_code"

if [[ $exit_code -eq 0 && "$retrieved" == "$TEST_SECRET_VALUE" ]]; then
    pass "Secret retrieved correctly"
else
    fail "Secret mismatch or retrieval failed"
    echo -e "  ${DIM}Expected: $TEST_SECRET_VALUE${NC}"
    echo -e "  ${DIM}Got: $retrieved${NC}"
fi

print_test "sec $TEST_SECRET_NAME (shortcut)"
echo -e "${DIM}Running: sec $TEST_SECRET_NAME${NC}"

shortcut_result=$(sec "$TEST_SECRET_NAME" 2>&1)
if [[ "$shortcut_result" == "$TEST_SECRET_VALUE" ]]; then
    pass "Shortcut syntax works"
else
    fail "Shortcut syntax failed"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 5: List Secrets
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 5: List Secrets"

print_test "sec list"
echo -e "${DIM}Running: sec list${NC}"
echo ""
sec list 2>&1
echo ""

if sec list 2>&1 | grep -q "$TEST_SECRET_NAME"; then
    pass "Test secret appears in list"
else
    fail "Test secret not found in list"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 6: Delete Secret
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 6: Delete Secret"

print_test "sec delete $TEST_SECRET_NAME"
echo -e "${DIM}Running: sec delete $TEST_SECRET_NAME${NC}"
echo ""

delete_output=$(sec delete "$TEST_SECRET_NAME" 2>&1)
delete_code=$?

echo "$delete_output"
echo ""

if [[ $delete_code -eq 0 ]]; then
    pass "Secret deleted successfully"
else
    fail "Failed to delete secret"
fi

print_test "Verify secret is gone"
if sec get "$TEST_SECRET_NAME" 2>&1 | grep -q "not found"; then
    pass "Secret confirmed deleted"
else
    fail "Secret still exists after delete"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 7: Error Handling
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 7: Error Handling"

print_test "Get non-existent secret"
echo -e "${DIM}Running: sec get nonexistent-secret-xyz${NC}"

error_output=$(sec get "nonexistent-secret-xyz" 2>&1)
error_code=$?

if [[ $error_code -ne 0 ]]; then
    pass "Returns error for non-existent secret"
else
    fail "Should return error for non-existent secret"
fi

if echo "$error_output" | grep -qi "not found"; then
    pass "Error message mentions 'not found'"
else
    fail "Error message should mention 'not found'"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 8: Interactive Add (Manual)
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 8: Interactive Add (Manual)"

echo ""
echo -e "${YELLOW}This test requires manual input.${NC}"
echo -e "${DIM}You will be prompted to enter a secret value.${NC}"
echo ""
echo -e "Would you like to test interactive add? [y/N]"
read -r do_interactive

if [[ "$do_interactive" == [yY]* ]]; then
    print_test "sec add test-interactive-$$"
    echo -e "${DIM}Running: sec add test-interactive-$$${NC}"
    echo -e "${YELLOW}Enter any test value when prompted...${NC}"
    echo ""

    sec add "test-interactive-$$"
    add_code=$?

    if [[ $add_code -eq 0 ]]; then
        pass "Interactive add completed"

        # Cleanup
        sec delete "test-interactive-$$" &>/dev/null
        info "Cleaned up test secret"
    else
        fail "Interactive add failed"
    fi
else
    skip "Interactive add test (user skipped)"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 9: Script Usage Pattern
# ══════════════════════════════════════════════════════════════════════════════

print_section "Test 9: Script Usage Pattern"

print_test "Export pattern: TOKEN=\$(sec <name>)"

# Add a temp secret for this test
security add-generic-password \
    -a "test-export-pattern-$$" \
    -s "flow-cli-secrets" \
    -w "my-test-token-123" \
    -U 2>/dev/null

# Test the export pattern
TOKEN=$(sec "test-export-pattern-$$" 2>/dev/null)

if [[ "$TOKEN" == "my-test-token-123" ]]; then
    pass "Export pattern works correctly"
    info "TOKEN variable contains expected value"
else
    fail "Export pattern failed"
fi

# Cleanup
security delete-generic-password \
    -a "test-export-pattern-$$" \
    -s "flow-cli-secrets" &>/dev/null

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${ROCKET}  ${BOLD}TEST SUMMARY${NC}                                                ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed${NC}: $PASSED"
echo -e "  ${RED}Failed${NC}: $FAILED"
echo -e "  ${YELLOW}Skipped${NC}: $SKIPPED"
echo ""

# Final cleanup
cleanup_test_secret

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}${CHECK} All automated tests passed!${NC}"
    echo ""
    echo -e "${DIM}The macOS Keychain secret management feature is working correctly.${NC}"
    echo -e "${DIM}Key benefits:${NC}"
    echo -e "${DIM}  ${APPLE} Touch ID / Apple Watch authentication${NC}"
    echo -e "${DIM}  ${KEY} Instant access (no unlock step)${NC}"
    echo -e "${DIM}  ${LOCK} Auto-locks with screen lock${NC}"
    echo ""
    echo -e "${YELLOW}Does everything look correct? [y/n]${NC}"
    read -r final_response
    if [[ "$final_response" == [yY]* ]]; then
        echo -e "${GREEN}${ROCKET} v5.5.0 Keychain Secrets feature verified!${NC}"
    else
        echo -e "${YELLOW}Please report any issues.${NC}"
    fi
else
    echo -e "${RED}${CROSS} Some tests failed. Please investigate.${NC}"
    exit 1
fi

echo ""
