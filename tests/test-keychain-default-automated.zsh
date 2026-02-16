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

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

PLUGIN_DIR="$PROJECT_ROOT"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/keychain-default-automated-${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

# Source the plugin
source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

log() {
    echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"
}

log "Starting automated tests for Keychain Default Phase 1"
log "Plugin directory: $PLUGIN_DIR"

# ============================================================================
# START SUITE
# ============================================================================

test_suite_start "KEYCHAIN DEFAULT PHASE 1 - AUTOMATED TEST SUITE"

# ============================================================================
# TEST GROUP 1: FUNCTION EXISTENCE
# ============================================================================

echo "${CYAN}━━━ 1. Function Existence ━━━${RESET}"

test_case "Backend configuration function exists"
assert_function_exists "_dotf_secret_backend" && test_pass

test_case "Bitwarden check helper exists"
assert_function_exists "_dotf_secret_needs_bitwarden" && test_pass

test_case "Keychain check helper exists"
assert_function_exists "_dotf_secret_uses_keychain" && test_pass

test_case "Status command function exists"
assert_function_exists "_sec_status" && test_pass

test_case "Sync command function exists"
assert_function_exists "_sec_sync" && test_pass

test_case "Sync status function exists"
assert_function_exists "_sec_sync_status" && test_pass

test_case "Sync to Bitwarden function exists"
assert_function_exists "_sec_sync_to_bitwarden" && test_pass

test_case "Sync from Bitwarden function exists"
assert_function_exists "_sec_sync_from_bitwarden" && test_pass

test_case "Sync help function exists"
assert_function_exists "_sec_sync_help" && test_pass

test_case "Keychain count helper exists"
assert_function_exists "_sec_count_keychain" && test_pass

# ============================================================================
# TEST GROUP 2: DEFAULT BACKEND CONFIGURATION
# ============================================================================

echo ""
echo "${CYAN}━━━ 2. Default Backend Configuration ━━━${RESET}"

# Save current value
SAVED_BACKEND="$FLOW_SECRET_BACKEND"

# Test: Default is keychain
unset FLOW_SECRET_BACKEND
result=$(_dotf_secret_backend 2>/dev/null)
test_case "Default backend is 'keychain'"
assert_equals "$result" "keychain" && test_pass

# Test: Keychain does not need Bitwarden
unset FLOW_SECRET_BACKEND
test_case "Default backend does not require Bitwarden"
if _dotf_secret_needs_bitwarden 2>/dev/null; then
    test_fail "Default backend should not need Bitwarden"
else
    test_pass
fi

# Test: Keychain uses Keychain (tautology check)
unset FLOW_SECRET_BACKEND
test_case "Default backend uses Keychain"
if _dotf_secret_uses_keychain 2>/dev/null; then
    test_pass
else
    test_fail "Default backend should use Keychain"
fi

# Restore
[[ -n "$SAVED_BACKEND" ]] && export FLOW_SECRET_BACKEND="$SAVED_BACKEND" || unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 3: EXPLICIT BACKEND CONFIGURATION
# ============================================================================

echo ""
echo "${CYAN}━━━ 3. Explicit Backend Configuration ━━━${RESET}"

# Test: Keychain explicit
export FLOW_SECRET_BACKEND="keychain"
result=$(_dotf_secret_backend 2>/dev/null)
test_case "FLOW_SECRET_BACKEND=keychain works"
assert_equals "$result" "keychain" && test_pass

# Test: Bitwarden explicit
export FLOW_SECRET_BACKEND="bitwarden"
result=$(_dotf_secret_backend 2>/dev/null)
test_case "FLOW_SECRET_BACKEND=bitwarden works"
assert_equals "$result" "bitwarden" && test_pass

# Test: Both explicit
export FLOW_SECRET_BACKEND="both"
result=$(_dotf_secret_backend 2>/dev/null)
test_case "FLOW_SECRET_BACKEND=both works"
assert_equals "$result" "both" && test_pass

# Test: Invalid falls back to keychain
export FLOW_SECRET_BACKEND="invalid_value"
result=$(_dotf_secret_backend 2>/dev/null | tail -1)
test_case "Invalid backend falls back to 'keychain'"
assert_equals "$result" "keychain" && test_pass

# Restore
unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 4: HELPER FUNCTION BEHAVIOR
# ============================================================================

echo ""
echo "${CYAN}━━━ 4. Helper Function Behavior Matrix ━━━${RESET}"

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
            test_case "keychain: needs_bitwarden=no"
            [[ "$needs_bw" == "no" ]] && test_pass || test_fail "keychain: needs_bitwarden should be no"
            ;;
        bitwarden)
            test_case "bitwarden: needs_bitwarden=yes"
            [[ "$needs_bw" == "yes" ]] && test_pass || test_fail "bitwarden: needs_bitwarden should be yes"
            ;;
        both)
            test_case "both: needs_bitwarden=yes"
            [[ "$needs_bw" == "yes" ]] && test_pass || test_fail "both: needs_bitwarden should be yes"
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
            test_case "keychain: uses_keychain=yes"
            [[ "$uses_kc" == "yes" ]] && test_pass || test_fail "keychain: uses_keychain should be yes"
            ;;
        bitwarden)
            test_case "bitwarden: uses_keychain=no"
            [[ "$uses_kc" == "no" ]] && test_pass || test_fail "bitwarden: uses_keychain should be no"
            ;;
        both)
            test_case "both: uses_keychain=yes"
            [[ "$uses_kc" == "yes" ]] && test_pass || test_fail "both: uses_keychain should be yes"
            ;;
    esac
done

unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 5: STATUS COMMAND
# ============================================================================

echo ""
echo "${CYAN}━━━ 5. Status Command ━━━${RESET}"

# Test: Status output contains backend info
unset FLOW_SECRET_BACKEND
status_output=$(_sec_status 2>/dev/null)

test_case "Status shows 'keychain' backend"
assert_contains "$status_output" "keychain" && test_pass

test_case "Status has 'Backend' section"
assert_contains "$status_output" "Backend" && test_pass

test_case "Status has 'Configuration' section"
assert_contains "$status_output" "Configuration" && test_pass

test_case "Status shows Keychain info"
assert_contains "$status_output" "Keychain" && test_pass

# Test: Status with bitwarden backend
export FLOW_SECRET_BACKEND="bitwarden"
status_output=$(_sec_status 2>/dev/null)

test_case "Status shows 'bitwarden' when configured"
assert_contains "$status_output" "bitwarden" && test_pass

test_case "Status mentions 'legacy mode'"
assert_contains "$status_output" "legacy" && test_pass

unset FLOW_SECRET_BACKEND

# ============================================================================
# TEST GROUP 6: SYNC COMMAND STRUCTURE
# ============================================================================

echo ""
echo "${CYAN}━━━ 6. Sync Command Structure ━━━${RESET}"

# Test: Sync help exists and is useful
sync_help=$(_sec_sync_help 2>/dev/null)

test_case "Sync help mentions 'sync'"
assert_contains "$sync_help" "sync" && test_pass

test_case "Sync help mentions '--status'"
assert_contains "$sync_help" "--status" && test_pass

test_case "Sync help mentions '--to-bw'"
assert_contains "$sync_help" "--to-bw" && test_pass

test_case "Sync help mentions '--from-bw'"
assert_contains "$sync_help" "--from-bw" && test_pass

# Test: Sync status runs without error (when BW locked)
unset BW_SESSION
sync_status_output=$(_sec_sync_status 2>/dev/null)

test_case "Sync status mentions Bitwarden"
assert_contains "$sync_status_output" "Bitwarden" && test_pass

# ============================================================================
# TEST GROUP 7: HELP TEXT
# ============================================================================

echo ""
echo "${CYAN}━━━ 7. Help Text Updates ━━━${RESET}"

# Test: Main help includes new commands
help_output=$(_dotf_kc_help 2>/dev/null)

test_case "Help mentions 'status' command"
assert_contains "$help_output" "status" && test_pass

test_case "Help mentions 'sync' command"
assert_contains "$help_output" "sync" && test_pass

test_case "Help mentions FLOW_SECRET_BACKEND"
assert_contains "$help_output" "FLOW_SECRET_BACKEND" && test_pass

# ============================================================================
# TEST GROUP 8: COMMAND ROUTING
# ============================================================================

echo ""
echo "${CYAN}━━━ 8. Command Routing ━━━${RESET}"

# Test: sec status routes correctly
unset FLOW_SECRET_BACKEND
output=$(zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' && sec status 2>&1" 2>/dev/null | head -5)

test_case "sec status routes to status function"
assert_contains "$output" "Backend" && test_pass

test_case "sec status does not trigger tutorial"
assert_not_contains "$output" "Tutorial" && test_pass

# Test: sec sync --help routes correctly
output=$(zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' && sec sync --help 2>&1" 2>/dev/null | head -5)

test_case "sec sync --help shows sync help"
assert_contains "$output" "sync" && test_pass

# ============================================================================
# TEST GROUP 9: FILE STRUCTURE
# ============================================================================

echo ""
echo "${CYAN}━━━ 9. File Structure ━━━${RESET}"

# Test: Spec file exists
test_case "Spec file exists"
assert_file_exists "$PLUGIN_DIR/docs/specs/SPEC-keychain-default-phase-1-2026-01-24.md" && test_pass

# Test: REFCARD updated
refcard_content=$(cat "$PLUGIN_DIR/docs/reference/REFCARD-TOKEN-SECRETS.md" 2>/dev/null)

test_case "REFCARD has Backend Configuration section"
assert_contains "$refcard_content" "Backend Configuration" && test_pass

test_case "REFCARD documents status command"
assert_contains "$refcard_content" "sec status" && test_pass

test_case "REFCARD documents sync command"
assert_contains "$refcard_content" "sec sync" && test_pass

# ============================================================================
# TEST GROUP 10: INTEGRATION SANITY
# ============================================================================

echo ""
echo "${CYAN}━━━ 10. Integration Sanity Checks ━━━${RESET}"

# Test: Plugin loads without errors
load_output=$(zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' 2>&1 && echo 'LOAD_OK'" 2>/dev/null)

test_case "Plugin loads without fatal errors"
assert_contains "$load_output" "LOAD_OK" && test_pass

# Test: dot command exists after load
test_case "dots command available after load"
if zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh' && type dots &>/dev/null" 2>/dev/null; then
    test_pass
else
    test_fail "dots command should be available"
fi

# Test: _DOT_KEYCHAIN_SERVICE constant defined
test_case "Keychain service constant defined"
if [[ -n "$_DOT_KEYCHAIN_SERVICE" ]]; then
    test_pass
else
    test_fail "Keychain service constant should be defined"
fi

# ============================================================================
# SUMMARY
# ============================================================================

test_suite_end
exit $?
