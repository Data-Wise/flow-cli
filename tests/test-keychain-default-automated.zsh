#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# AUTOMATED TEST SUITE - KEYCHAIN DEFAULT PHASE 1
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: CI-ready automated tests for the Keychain Default feature.
#          No user interaction required.
#
# Usage: ./tests/test-keychain-default-automated.zsh
#
# What it tests:
#   - Backend configuration (FLOW_SECRET_BACKEND)
#   - Helper functions (_dotf_secret_backend, _dotf_secret_needs_bitwarden, etc.)
#   - Status command (sec status)
#   - Sync command structure (sec sync --help)
#   - Token workflow routing (conditional Bitwarden checks)
#   - Documentation updates
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed
#
# ══════════════════════════════════════════════════════════════════════════════

set -o pipefail

# ============================================================================
# SETUP
# ============================================================================

PLUGIN_DIR="${0:A:h:h}"
TEST_DIR="${0:A:h}"
LOG_DIR="${TEST_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/keychain-default-automated-${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
SKIP=0
TOTAL=0

# Source the plugin
source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

log() {
    echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"
}

test_pass() {
    ((TOTAL++))
    ((PASS++))
    echo -e "  ${GREEN}✓${NC} $1"
    log "PASS: $1"
}

test_fail() {
    ((TOTAL++))
    ((FAIL++))
    echo -e "  ${RED}✗${NC} $1"
    log "FAIL: $1"
    [[ -n "$2" ]] && echo -e "    ${DIM}Expected: $2${NC}" && log "  Expected: $2"
    [[ -n "$3" ]] && echo -e "    ${DIM}Got:      $3${NC}" && log "  Got: $3"
}

test_skip() {
    ((TOTAL++))
    ((SKIP++))
    echo -e "  ${YELLOW}○${NC} $1 (skipped)"
    log "SKIP: $1"
}

section() {
    echo ""
    echo -e "${CYAN}━━━ $1 ━━━${NC}"
    log "=== $1 ==="
}

assert_eq() {
    local actual="$1"
    local expected="$2"
    local message="$3"

    if [[ "$actual" == "$expected" ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message" "$expected" "$actual"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message" "contains '$needle'" "not found in output"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message" "should not contain '$needle'" "found in output"
        return 1
    fi
}

assert_function_exists() {
    local fn="$1"
    local message="${2:-Function $fn exists}"

    if type "$fn" &>/dev/null; then
        test_pass "$message"
        return 0
    else
        test_fail "$message" "function defined" "function not found"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [[ "$actual" -eq "$expected" ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message" "exit code $expected" "exit code $actual"
        return 1
    fi
}

# ============================================================================
# BANNER
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${BOLD}KEYCHAIN DEFAULT PHASE 1 - AUTOMATED TEST SUITE${NC}             ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}  ${DIM}CI-ready tests for backend configuration feature${NC}            ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo -e "${DIM}Log: $LOG_FILE${NC}"

log "Starting automated tests for Keychain Default Phase 1"
log "Plugin directory: $PLUGIN_DIR"

# ============================================================================
# TEST GROUP 1: FUNCTION EXISTENCE
# ============================================================================

section "1. Function Existence"

assert_function_exists "_dotf_secret_backend" "Backend configuration function exists"
assert_function_exists "_dotf_secret_needs_bitwarden" "Bitwarden check helper exists"
assert_function_exists "_dotf_secret_uses_keychain" "Keychain check helper exists"
assert_function_exists "_sec_status" "Status command function exists"
assert_function_exists "_sec_sync" "Sync command function exists"
assert_function_exists "_sec_sync_status" "Sync status function exists"
assert_function_exists "_sec_sync_to_bitwarden" "Sync to Bitwarden function exists"
assert_function_exists "_sec_sync_from_bitwarden" "Sync from Bitwarden function exists"
assert_function_exists "_sec_sync_help" "Sync help function exists"
assert_function_exists "_sec_count_keychain" "Keychain count helper exists"

# ============================================================================
# TEST GROUP 2: DEFAULT BACKEND CONFIGURATION
# ============================================================================

section "2. Default Backend Configuration"

# Save current value
SAVED_BACKEND="$FLOW_SECRET_BACKEND"

# Test: Default is keychain
unset FLOW_SECRET_BACKEND
result=$(_dotf_secret_backend 2>/dev/null)
assert_eq "$result" "keychain" "Default backend is 'keychain'"

# Test: Keychain does not need Bitwarden
unset FLOW_SECRET_BACKEND
if _dotf_secret_needs_bitwarden 2>/dev/null; then
    test_fail "Default backend should not need Bitwarden"
else
    test_pass "Default backend does not require Bitwarden"
fi

# Test: Keychain uses Keychain (tautology check)
unset FLOW_SECRET_BACKEND
if _dotf_secret_uses_keychain 2>/dev/null; then
    test_pass "Default backend uses Keychain"
else
    test_fail "Default backend should use Keychain"
fi

# Restore
[[ -n "$SAVED_BACKEND" ]] && export FLOW_SECRET_BACKEND="$SAVED_BACKEND" || unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 3: EXPLICIT BACKEND CONFIGURATION
# ============================================================================

section "3. Explicit Backend Configuration"

# Test: Keychain explicit
export FLOW_SECRET_BACKEND="keychain"
result=$(_dotf_secret_backend 2>/dev/null)
assert_eq "$result" "keychain" "FLOW_SECRET_BACKEND=keychain works"

# Test: Bitwarden explicit
export FLOW_SECRET_BACKEND="bitwarden"
result=$(_dotf_secret_backend 2>/dev/null)
assert_eq "$result" "bitwarden" "FLOW_SECRET_BACKEND=bitwarden works"

# Test: Both explicit
export FLOW_SECRET_BACKEND="both"
result=$(_dotf_secret_backend 2>/dev/null)
assert_eq "$result" "both" "FLOW_SECRET_BACKEND=both works"

# Test: Invalid falls back to keychain
export FLOW_SECRET_BACKEND="invalid_value"
result=$(_dotf_secret_backend 2>/dev/null | tail -1)
assert_eq "$result" "keychain" "Invalid backend falls back to 'keychain'"

# Restore
unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 4: HELPER FUNCTION BEHAVIOR
# ============================================================================

section "4. Helper Function Behavior Matrix"

# Test matrix for _dotf_secret_needs_bitwarden
for backend in keychain bitwarden both; do
    export FLOW_SECRET_BACKEND="$backend"
    if _dotf_secret_needs_bitwarden 2>/dev/null; then
        needs_bw="yes"
    else
        needs_bw="no"
    fi

    case "$backend" in
        keychain)
            [[ "$needs_bw" == "no" ]] && test_pass "keychain: needs_bitwarden=no" || test_fail "keychain: needs_bitwarden should be no"
            ;;
        bitwarden)
            [[ "$needs_bw" == "yes" ]] && test_pass "bitwarden: needs_bitwarden=yes" || test_fail "bitwarden: needs_bitwarden should be yes"
            ;;
        both)
            [[ "$needs_bw" == "yes" ]] && test_pass "both: needs_bitwarden=yes" || test_fail "both: needs_bitwarden should be yes"
            ;;
    esac
done

# Test matrix for _dotf_secret_uses_keychain
for backend in keychain bitwarden both; do
    export FLOW_SECRET_BACKEND="$backend"
    if _dotf_secret_uses_keychain 2>/dev/null; then
        uses_kc="yes"
    else
        uses_kc="no"
    fi

    case "$backend" in
        keychain)
            [[ "$uses_kc" == "yes" ]] && test_pass "keychain: uses_keychain=yes" || test_fail "keychain: uses_keychain should be yes"
            ;;
        bitwarden)
            [[ "$uses_kc" == "no" ]] && test_pass "bitwarden: uses_keychain=no" || test_fail "bitwarden: uses_keychain should be no"
            ;;
        both)
            [[ "$uses_kc" == "yes" ]] && test_pass "both: uses_keychain=yes" || test_fail "both: uses_keychain should be yes"
            ;;
    esac
done

unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 5: STATUS COMMAND
# ============================================================================

section "5. Status Command"

# Test: Status output contains backend info
unset FLOW_SECRET_BACKEND
status_output=$(_sec_status 2>/dev/null)
assert_contains "$status_output" "keychain" "Status shows 'keychain' backend"
assert_contains "$status_output" "Backend" "Status has 'Backend' section"
assert_contains "$status_output" "Configuration" "Status has 'Configuration' section"
assert_contains "$status_output" "Keychain" "Status shows Keychain info"

# Test: Status with bitwarden backend
export FLOW_SECRET_BACKEND="bitwarden"
status_output=$(_sec_status 2>/dev/null)
assert_contains "$status_output" "bitwarden" "Status shows 'bitwarden' when configured"
assert_contains "$status_output" "legacy" "Status mentions 'legacy mode'"
unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 6: SYNC COMMAND STRUCTURE
# ============================================================================

section "6. Sync Command Structure"

# Test: Sync help exists and is useful
sync_help=$(_sec_sync_help 2>/dev/null)
assert_contains "$sync_help" "sync" "Sync help mentions 'sync'"
assert_contains "$sync_help" "--status" "Sync help mentions '--status'"
assert_contains "$sync_help" "--to-bw" "Sync help mentions '--to-bw'"
assert_contains "$sync_help" "--from-bw" "Sync help mentions '--from-bw'"

# Test: Sync status runs without error (when BW locked)
unset BW_SESSION
sync_status_output=$(_sec_sync_status 2>/dev/null)
assert_contains "$sync_status_output" "Bitwarden" "Sync status mentions Bitwarden"

# ============================================================================
# TEST GROUP 7: HELP TEXT
# ============================================================================

section "7. Help Text Updates"

# Test: Main help includes new commands
help_output=$(_dotf_kc_help 2>/dev/null)
assert_contains "$help_output" "status" "Help mentions 'status' command"
assert_contains "$help_output" "sync" "Help mentions 'sync' command"
assert_contains "$help_output" "FLOW_SECRET_BACKEND" "Help mentions FLOW_SECRET_BACKEND"

# ============================================================================
# TEST GROUP 8: COMMAND ROUTING
# ============================================================================

section "8. Command Routing"

# Test: sec status routes correctly
unset FLOW_SECRET_BACKEND
output=$(zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' && sec status 2>&1" 2>/dev/null | head -5)
assert_contains "$output" "Backend" "sec status routes to status function"
assert_not_contains "$output" "Tutorial" "sec status does not trigger tutorial"

# Test: sec sync --help routes correctly
output=$(zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' && sec sync --help 2>&1" 2>/dev/null | head -5)
assert_contains "$output" "sync" "sec sync --help shows sync help"

# ============================================================================
# TEST GROUP 9: FILE STRUCTURE
# ============================================================================

section "9. File Structure"

# Test: Spec file exists
if [[ -f "$PLUGIN_DIR/docs/specs/SPEC-keychain-default-phase-1-2026-01-24.md" ]]; then
    test_pass "Spec file exists"
else
    test_fail "Spec file should exist"
fi

# Test: REFCARD updated
refcard_content=$(cat "$PLUGIN_DIR/docs/reference/REFCARD-TOKEN-SECRETS.md" 2>/dev/null)
assert_contains "$refcard_content" "Backend Configuration" "REFCARD has Backend Configuration section"
assert_contains "$refcard_content" "sec status" "REFCARD documents status command"
assert_contains "$refcard_content" "sec sync" "REFCARD documents sync command"

# ============================================================================
# TEST GROUP 10: INTEGRATION SANITY
# ============================================================================

section "10. Integration Sanity Checks"

# Test: Plugin loads without errors
load_output=$(zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' 2>&1 && echo 'LOAD_OK'" 2>/dev/null)
assert_contains "$load_output" "LOAD_OK" "Plugin loads without fatal errors"

# Test: dot command exists after load
if zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' && type dots &>/dev/null" 2>/dev/null; then
    test_pass "dots command available after load"
else
    test_fail "dots command should be available"
fi

# Test: _DOT_KEYCHAIN_SERVICE constant defined
if [[ -n "$_DOT_KEYCHAIN_SERVICE" ]]; then
    test_pass "Keychain service constant defined: $_DOT_KEYCHAIN_SERVICE"
else
    test_fail "Keychain service constant should be defined"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}RESULTS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $PASS"
echo -e "  ${RED}Failed:${NC}  $FAIL"
echo -e "  ${YELLOW}Skipped:${NC} $SKIP"
echo -e "  ${BOLD}Total:${NC}   $TOTAL"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    log "SUMMARY: All $TOTAL tests passed"
    exit 0
else
    echo -e "${RED}$FAIL test(s) failed${NC}"
    log "SUMMARY: $FAIL/$TOTAL tests failed"
    exit 1
fi
