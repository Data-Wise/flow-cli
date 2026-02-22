#!/usr/bin/env zsh
# e2e-atlas-bridge.zsh - End-to-end tests for Atlas bridge (at command)
#
# Tests the full at() command path including:
# - Help display (always local, never passed to Atlas)
# - Fallback behavior without Atlas (catch, inbox, where, crumb)
# - Warm-path install messages
# - Unknown command handling
# - Capture roundtrip (catch -> inbox)
# - Breadcrumb roundtrip (crumb -> trail file)
#
# Usage: zsh tests/e2e-atlas-bridge.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  ${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ $rc -eq 77 ]]; then
        echo "${YELLOW}SKIP${RESET}"
    else
        echo "${RED}FAIL${RESET}"
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:300}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  E2E: Atlas Bridge (at command)${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Load plugin with Atlas disabled (test fallback paths)
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
FLOW_ATLAS_ENABLED=no
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Failed to load plugin${RESET}"
    exit 1
}

# Prevent interactive prompts
exec < /dev/null

# Create isolated test environment
TEST_DATA_DIR=$(mktemp -d)
ORIGINAL_DATA_DIR="$FLOW_DATA_DIR"
FLOW_DATA_DIR="$TEST_DATA_DIR"

cleanup() {
    FLOW_DATA_DIR="$ORIGINAL_DATA_DIR"
    rm -rf "$TEST_DATA_DIR"
}
trap cleanup EXIT

# ============================================================================
# SECTION 1: Help Display (always local)
# ============================================================================

echo "${CYAN}--- Section 1: Help Display ---${RESET}"

run_test "at help shows styled help page" '
    local output
    output=$(at help 2>&1)
    [[ "$output" == *"Atlas Project Intelligence"* ]] || { echo "Missing title"; return 1; }
'

run_test "at help shows MOST COMMON section" '
    local output
    output=$(at help 2>&1)
    [[ "$output" == *"MOST COMMON"* ]] || { echo "Missing MOST COMMON"; return 1; }
'

run_test "at help shows all category sections" '
    local output
    output=$(at help 2>&1)
    [[ "$output" == *"SESSION"* ]] || { echo "Missing SESSION"; return 1; }
    [[ "$output" == *"CAPTURE"* ]] || { echo "Missing CAPTURE"; return 1; }
    [[ "$output" == *"CONTEXT"* ]] || { echo "Missing CONTEXT"; return 1; }
    [[ "$output" == *"PROJECT"* ]] || { echo "Missing PROJECT"; return 1; }
'

run_test "at --help shows same page as at help" '
    local h1 h2
    h1=$(at help 2>&1 | head -5)
    h2=$(at --help 2>&1 | head -5)
    [[ "$h1" == "$h2" ]] || { echo "Mismatch"; return 1; }
'

run_test "at -h shows same page as at help" '
    local h1 h2
    h1=$(at help 2>&1 | head -5)
    h2=$(at -h 2>&1 | head -5)
    [[ "$h1" == "$h2" ]] || { echo "Mismatch"; return 1; }
'

run_test "at (no args) shows help" '
    local output
    output=$(at 2>&1)
    [[ "$output" == *"Atlas Project Intelligence"* ]] || { echo "No help on bare at"; return 1; }
'

echo ""

# ============================================================================
# SECTION 2: Fallback Behavior (without Atlas)
# ============================================================================

echo "${CYAN}--- Section 2: Fallback Commands ---${RESET}"

run_test "at catch captures text to inbox" '
    local output
    output=$(at catch "E2E test capture item" 2>&1)
    [[ "$output" == *"Captured"* ]] || { echo "No confirmation: $output"; return 1; }
'

run_test "at c (alias) captures text" '
    local output
    output=$(at c "E2E alias capture" 2>&1)
    [[ "$output" == *"Captured"* ]] || { echo "No confirmation: $output"; return 1; }
'

run_test "at inbox shows captured items" '
    local output
    output=$(at inbox 2>&1)
    # Should show something (either items or empty inbox message)
    [[ -n "$output" ]] || { echo "Empty output"; return 1; }
'

run_test "at i (alias) shows inbox" '
    local output
    output=$(at i 2>&1)
    [[ -n "$output" ]] || { echo "Empty output"; return 1; }
'

run_test "at where shows context info" '
    local output
    output=$(at where 2>&1)
    # Should produce some output (project name or no-session message)
    [[ -n "$output" ]] || { echo "Empty output"; return 1; }
'

run_test "at w (alias) shows context" '
    local output
    output=$(at w 2>&1)
    [[ -n "$output" ]] || { echo "Empty output"; return 1; }
'

run_test "at crumb leaves breadcrumb" '
    local output
    output=$(at crumb "E2E test breadcrumb" 2>&1)
    local rc=$?
    [[ "$output" == *"Breadcrumb"* ]] || [[ "$output" == *"breadcrumb"* ]] || [[ $rc -eq 0 ]] || { echo "Failed (rc=$rc): $output"; return 1; }
'

run_test "at b (alias) leaves breadcrumb" '
    local output
    output=$(at b "E2E alias breadcrumb" 2>&1)
    local rc=$?
    [[ "$output" == *"Breadcrumb"* ]] || [[ "$output" == *"breadcrumb"* ]] || [[ $rc -eq 0 ]] || { echo "Failed (rc=$rc): $output"; return 1; }
'

echo ""

# ============================================================================
# SECTION 3: Warm-path Install Messages
# ============================================================================

echo "${CYAN}--- Section 3: Warm-path Without Atlas ---${RESET}"

warm_commands=(stats plan park unpark parked dash dashboard focus triage trail)

for cmd in "${warm_commands[@]}"; do
    run_test "at $cmd shows install message" "
        local output
        output=\$(at $cmd 2>&1)
        [[ \"\$output\" == *\"requires Atlas CLI\"* ]] || { echo \"Missing install msg: \$output\"; return 1; }
    "
done

echo ""

# ============================================================================
# SECTION 4: Unknown Command Handling
# ============================================================================

echo "${CYAN}--- Section 4: Unknown Commands ---${RESET}"

run_test "Unknown command lists available fallbacks" '
    local output
    output=$(at nonexistent_cmd 2>&1)
    [[ "$output" == *"catch, inbox, where, crumb"* ]] || { echo "Missing fallback list: $output"; return 1; }
'

run_test "Unknown command suggests install" '
    local output
    output=$(at nonexistent_cmd 2>&1)
    [[ "$output" == *"npm i -g"* ]] || [[ "$output" == *"brew install"* ]] || { echo "Missing install hint"; return 1; }
'

run_test "Unknown command suggests at help" '
    local output
    output=$(at nonexistent_cmd 2>&1)
    [[ "$output" == *"at help"* ]] || { echo "Missing help hint"; return 1; }
'

echo ""

# ============================================================================
# SECTION 5: Capture Roundtrip
# ============================================================================

echo "${CYAN}--- Section 5: Capture Roundtrip ---${RESET}"

run_test "catch -> inbox roundtrip works" '
    local tmp_data=$(mktemp -d)
    local orig="$FLOW_DATA_DIR"
    FLOW_DATA_DIR="$tmp_data"

    # Capture something
    at catch "Roundtrip test item XYZ" 2>/dev/null

    # Check inbox file exists and contains item
    if [[ -f "$tmp_data/inbox.md" ]]; then
        grep -q "Roundtrip test item XYZ" "$tmp_data/inbox.md" || { echo "Item not in inbox.md"; FLOW_DATA_DIR="$orig"; rm -rf "$tmp_data"; return 1; }
    elif ls "$tmp_data"/*.md 2>/dev/null | head -1 | xargs grep -q "Roundtrip test item XYZ" 2>/dev/null; then
        : # Found in some md file
    else
        echo "Capture not persisted"
        FLOW_DATA_DIR="$orig"
        rm -rf "$tmp_data"
        return 1
    fi

    FLOW_DATA_DIR="$orig"
    rm -rf "$tmp_data"
'

run_test "Multiple captures are preserved" '
    local tmp_data=$(mktemp -d)
    local orig="$FLOW_DATA_DIR"
    FLOW_DATA_DIR="$tmp_data"

    at catch "First item AAA" 2>/dev/null
    at catch "Second item BBB" 2>/dev/null
    at catch "Third item CCC" 2>/dev/null

    local count=0
    for item in "First item AAA" "Second item BBB" "Third item CCC"; do
        if grep -r "$item" "$tmp_data" &>/dev/null; then
            count=$((count + 1))
        fi
    done

    FLOW_DATA_DIR="$orig"
    rm -rf "$tmp_data"

    (( count >= 3 )) || { echo "Only $count/3 items found"; return 1; }
'

echo ""

# ============================================================================
# SECTION 6: Doctor Integration
# ============================================================================

echo "${CYAN}--- Section 6: Doctor Integration ---${RESET}"

run_test "doctor command references Atlas" '
    # Verify doctor.zsh source contains Atlas checks
    grep -qi "atlas" "$PROJECT_ROOT/commands/doctor.zsh" || { echo "No Atlas in doctor.zsh"; return 1; }
'

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "${RED}  FAIL: $TESTS_PASSED/$TESTS_RUN passed ($TESTS_FAILED failed)${RESET}"
else
    echo "${GREEN}  PASS: $TESTS_PASSED/$TESTS_RUN passed${RESET}"
fi
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

[[ $TESTS_FAILED -eq 0 ]]
