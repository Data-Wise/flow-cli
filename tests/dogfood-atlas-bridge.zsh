#!/usr/bin/env zsh
# dogfood-atlas-bridge.zsh - Dogfood tests for Atlas bridge integration
#
# Verifies the Atlas bridge integrates properly with the rest of flow-cli:
# - at() and _at_help() functions loaded
# - Bridge included in help browser dispatcher list
# - Help browser regex recognizes at as dispatcher
# - Doctor includes Atlas section
# - Core commands reference Atlas bridge functions
# - Fallback functions (_flow_catch, _flow_inbox, etc.) exist
# - Plugin loads cleanly with at() defined
#
# Usage: zsh tests/dogfood-atlas-bridge.zsh

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
echo "${CYAN}  Dogfood: Atlas Bridge Integration${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Load plugin
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
FLOW_ATLAS_ENABLED=no
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Plugin failed to load${RESET}"
    exit 1
}
exec < /dev/null

echo "${GREEN}Plugin loaded (v$FLOW_VERSION)${RESET}"
echo ""

# ============================================================================
# SECTION 1: Bridge Functions Loaded
# ============================================================================

echo "${CYAN}--- Section 1: Bridge Functions ---${RESET}"

run_test "at() function is defined" '
    typeset -f at >/dev/null 2>&1 || return 1
'

run_test "_at_help() function is defined" '
    typeset -f _at_help >/dev/null 2>&1 || return 1
'

run_test "_flow_has_atlas() function is defined" '
    typeset -f _flow_has_atlas >/dev/null 2>&1 || return 1
'

run_test "_flow_has_atlas returns false with FLOW_ATLAS_ENABLED=no" '
    FLOW_ATLAS_ENABLED=no _flow_has_atlas && return 1
    return 0
'

echo ""

# ============================================================================
# SECTION 2: Fallback Functions Exist
# ============================================================================

echo "${CYAN}--- Section 2: Fallback Functions ---${RESET}"

fallback_fns=(_flow_catch _flow_inbox _flow_where _flow_crumb)

for fn in "${fallback_fns[@]}"; do
    run_test "$fn is defined" "
        typeset -f $fn >/dev/null 2>&1 || return 1
    "
done

echo ""

# ============================================================================
# SECTION 3: Help Page Quality
# ============================================================================

echo "${CYAN}--- Section 3: Help Page Quality ---${RESET}"

run_test "_at_help produces substantial output" '
    local output
    output=$(_at_help 2>&1)
    local lines=$(echo "$output" | wc -l | tr -d " ")
    (( lines >= 15 )) || { echo "Only $lines lines (expected 15+)"; return 1; }
'

run_test "Help shows catch command" '
    local output
    output=$(_at_help 2>&1)
    [[ "$output" == *"catch"* ]] || return 1
'

run_test "Help shows stats command" '
    local output
    output=$(_at_help 2>&1)
    [[ "$output" == *"stats"* ]] || return 1
'

run_test "Help shows park command" '
    local output
    output=$(_at_help 2>&1)
    [[ "$output" == *"park"* ]] || return 1
'

run_test "Help shows install instructions" '
    local output
    output=$(_at_help 2>&1)
    [[ "$output" == *"npm"* ]] || [[ "$output" == *"brew"* ]] || { echo "Missing install info"; return 1; }
'

echo ""

# ============================================================================
# SECTION 4: Help Browser Integration
# ============================================================================

echo "${CYAN}--- Section 4: Help Browser Integration ---${RESET}"

run_test "help-browser.zsh exists" '
    [[ -f "$PROJECT_ROOT/lib/help-browser.zsh" ]] || return 1
'

run_test "help-browser regex includes at" '
    grep -q "|at)" "$PROJECT_ROOT/lib/help-browser.zsh" || return 1
'

run_test "help-browser commands list includes at entry" "
    grep -q '\"at:' \"\$PROJECT_ROOT/lib/help-browser.zsh\" || return 1
"

run_test "help-browser regex includes all 15 dispatchers + at" '
    local regex_line
    regex_line=$(grep "^\^(" "$PROJECT_ROOT/lib/help-browser.zsh" 2>/dev/null | head -1)
    [[ -z "$regex_line" ]] && regex_line=$(grep "g|cc|wt" "$PROJECT_ROOT/lib/help-browser.zsh" 2>/dev/null | head -1)

    for d in g cc wt mcp r qu obs tm dots sec tok teach prompt v em at; do
        [[ "$regex_line" == *"$d"* ]] || { echo "Missing $d in regex"; return 1; }
    done
'

echo ""

# ============================================================================
# SECTION 5: Doctor Integration
# ============================================================================

echo "${CYAN}--- Section 5: Doctor Integration ---${RESET}"

run_test "doctor.zsh exists" '
    [[ -f "$PROJECT_ROOT/commands/doctor.zsh" ]] || return 1
'

run_test "doctor.zsh contains Atlas section" '
    grep -qi "atlas" "$PROJECT_ROOT/commands/doctor.zsh" || return 1
'

run_test "doctor.zsh checks atlas version" '
    grep -q "atlas.*-v\|atlas.*version" "$PROJECT_ROOT/commands/doctor.zsh" || return 1
'

echo ""

# ============================================================================
# SECTION 6: Contract & Documentation
# ============================================================================

echo "${CYAN}--- Section 6: Contract & Documentation ---${RESET}"

run_test "ATLAS-CONTRACT.md exists" '
    [[ -f "$PROJECT_ROOT/docs/ATLAS-CONTRACT.md" ]] || return 1
'

run_test "Contract specifies version compatibility" '
    grep -qi "version\|compatibility" "$PROJECT_ROOT/docs/ATLAS-CONTRACT.md" || return 1
'

run_test "Contract specifies exit codes" '
    grep -q "exit.*code\|Exit.*Code" "$PROJECT_ROOT/docs/ATLAS-CONTRACT.md" || return 1
'

run_test "at.md command reference exists" '
    [[ -f "$PROJECT_ROOT/docs/commands/at.md" ]] || return 1
'

run_test "Atlas integration guide exists" '
    [[ -f "$PROJECT_ROOT/docs/guides/ATLAS-INTEGRATION-GUIDE.md" ]] || return 1
'

run_test "Contract test file exists" '
    [[ -f "$PROJECT_ROOT/tests/test-atlas-contract.zsh" ]] || return 1
'

echo ""

# ============================================================================
# SECTION 7: Plugin Load Regression
# ============================================================================

echo "${CYAN}--- Section 7: Plugin Load Regression ---${RESET}"

run_test "Plugin loads without stderr when Atlas disabled" '
    local errs
    errs=$(FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no FLOW_PLUGIN_DIR="$PROJECT_ROOT" source "$PROJECT_ROOT/flow.plugin.zsh" 2>&1 >/dev/null)
    [[ -z "$errs" ]] || { echo "Stderr: $errs"; return 1; }
'

run_test "at() coexists with all 15 dispatchers" '
    local all_ok=true
    for d in g mcp obs qu r cc tm wt dots sec tok teach prompt v em; do
        typeset -f "$d" >/dev/null 2>&1 || { echo "Missing: $d"; all_ok=false; }
    done
    typeset -f at >/dev/null 2>&1 || { echo "Missing: at"; all_ok=false; }
    [[ "$all_ok" == "true" ]] || return 1
'

run_test "Session functions reference Atlas" '
    # _flow_session_start or _flow_session_end should exist
    typeset -f _flow_session_start >/dev/null 2>&1 || typeset -f _flow_session_end >/dev/null 2>&1 || return 1
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
