#!/usr/bin/env zsh
# dogfood-teach-map.zsh - Dogfooding test for teach map
#
# Sources flow.plugin.zsh and verifies all teach map functions
# loaded correctly: _teach_map, _teach_map_detect_tools,
# dispatcher routing, output structure, and help cross-reference.
#
# Usage: zsh tests/dogfood-teach-map.zsh

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
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:200}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  Teach Map - Dogfood Test${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ============================================================================
# LOAD PLUGIN
# ============================================================================

echo "${CYAN}Loading flow.plugin.zsh...${RESET}"
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Plugin failed to load${RESET}"
    exit 1
}
echo "${GREEN}Plugin loaded (v$FLOW_VERSION)${RESET}"
echo ""

# ============================================================================
# SECTION 1: Core Functions Exist
# ============================================================================

echo "${CYAN}--- Section 1: Core Functions ---${RESET}"

run_test "_teach_map exists" '
    typeset -f _teach_map >/dev/null 2>&1 || return 1
'

run_test "_teach_map_detect_tools exists" '
    typeset -f _teach_map_detect_tools >/dev/null 2>&1 || return 1
'

run_test "teach dispatcher function exists" '
    typeset -f teach >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 2: Tool Detection Behavior
# ============================================================================

echo "${CYAN}--- Section 2: Tool Detection ---${RESET}"

run_test "_teach_map_detect_tools sets flow=1" '
    _teach_map_detect_tools
    [[ "${_TEACH_MAP_TOOLS[flow]}" == "1" ]] || return 1
'

run_test "_teach_map_detect_tools sets scholar to 0 or 1" '
    _teach_map_detect_tools
    [[ "${_TEACH_MAP_TOOLS[scholar]}" == "0" || "${_TEACH_MAP_TOOLS[scholar]}" == "1" ]] || return 1
'

run_test "_teach_map_detect_tools sets craft to 0 or 1" '
    _teach_map_detect_tools
    [[ "${_TEACH_MAP_TOOLS[craft]}" == "0" || "${_TEACH_MAP_TOOLS[craft]}" == "1" ]] || return 1
'

run_test "Scholar detection matches filesystem" '
    _teach_map_detect_tools
    local expected=0
    [[ -d "${HOME}/.claude/plugins/scholar" ]] && expected=1
    [[ "${_TEACH_MAP_TOOLS[scholar]}" == "$expected" ]] || return 1
'

run_test "Craft detection matches filesystem" '
    _teach_map_detect_tools
    local expected=0
    [[ -d "${HOME}/.claude/plugins/craft" ]] && expected=1
    [[ "${_TEACH_MAP_TOOLS[craft]}" == "$expected" ]] || return 1
'

echo ""

# ============================================================================
# SECTION 3: Dispatcher Routing
# ============================================================================

echo "${CYAN}--- Section 3: Dispatcher Routing ---${RESET}"

run_test "teach map routes without error" '
    local output
    output=$(teach map 2>&1)
    ! echo "$output" | grep -q "Unknown command" || return 1
'

run_test "teach map exits with code 0" '
    teach map >/dev/null 2>&1
    [[ $? -eq 0 ]] || return 1
'

run_test "teach map output contains header" '
    local output
    output=$(teach map 2>&1)
    echo "$output" | grep -q "teach map -- Teaching Ecosystem" || return 1
'

echo ""

# ============================================================================
# SECTION 4: Output Structure
# ============================================================================

echo "${CYAN}--- Section 4: Output Structure ---${RESET}"

run_test "Output contains box-drawing characters" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "╭─" || return 1
    echo "$output" | grep -q "╰─" || return 1
'

run_test "Output contains SETUP & CONFIGURATION phase" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "SETUP & CONFIGURATION" || return 1
'

run_test "Output contains CONTENT GENERATION phase" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "CONTENT GENERATION" || return 1
'

run_test "Output contains VALIDATION & QUALITY phase" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "VALIDATION & QUALITY" || return 1
'

run_test "Output contains DEPLOYMENT phase" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "DEPLOYMENT" || return 1
'

run_test "Output contains SEMESTER TRACKING phase" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "SEMESTER TRACKING" || return 1
'

run_test "Output contains Tools header" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "Tools:.*flow-cli" || return 1
'

run_test "Output contains footer tips" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "Slash commands" || return 1
    echo "$output" | grep -q "For usage details" || return 1
'

echo ""

# ============================================================================
# SECTION 5: Command Completeness
# ============================================================================

echo "${CYAN}--- Section 5: Command Completeness ---${RESET}"

run_test "All setup commands present" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "teach init" || return 1
    echo "$output" | grep -q "teach config" || return 1
    echo "$output" | grep -q "teach doctor" || return 1
    echo "$output" | grep -q "teach hooks" || return 1
    echo "$output" | grep -q "teach plan" || return 1
    echo "$output" | grep -q "teach templates" || return 1
    echo "$output" | grep -q "teach macros" || return 1
    echo "$output" | grep -q "teach prompt" || return 1
    echo "$output" | grep -q "teach style" || return 1
'

run_test "All Scholar content commands present" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "teach lecture" || return 1
    echo "$output" | grep -q "teach slides" || return 1
    echo "$output" | grep -q "teach exam" || return 1
    echo "$output" | grep -q "teach quiz" || return 1
    echo "$output" | grep -q "teach assignment" || return 1
    echo "$output" | grep -q "teach syllabus" || return 1
    echo "$output" | grep -q "teach rubric" || return 1
    echo "$output" | grep -q "teach feedback" || return 1
    echo "$output" | grep -q "teach demo" || return 1
'

run_test "All validation commands present" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "teach validate" || return 1
    echo "$output" | grep -q "teach analyze" || return 1
    echo "$output" | grep -q "teach profiles" || return 1
    echo "$output" | grep -q "teach cache" || return 1
    echo "$output" | grep -q "teach clean" || return 1
'

run_test "All deployment commands present" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "teach deploy" || return 1
    echo "$output" | grep -q "/craft:site:publish" || return 1
    echo "$output" | grep -q "/craft:site:build" || return 1
    echo "$output" | grep -q "/craft:site:deploy" || return 1
'

run_test "All semester tracking commands present" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "teach status" || return 1
    echo "$output" | grep -q "teach week" || return 1
    echo "$output" | grep -q "teach backup" || return 1
    echo "$output" | grep -q "teach archive" || return 1
    echo "$output" | grep -q "/craft:site:progress" || return 1
'

echo ""

# ============================================================================
# SECTION 6: Badge System
# ============================================================================

echo "${CYAN}--- Section 6: Badge System ---${RESET}"

run_test "Output contains [flow-cli] badge" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "\[flow-cli\]" || return 1
'

run_test "Output contains [scholar] badge" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "\[scholar\]" || return 1
'

run_test "Output contains [craft] badge" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "\[craft\]" || return 1
'

run_test "Slash commands reference Scholar" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "/scholar:teaching:validate" || return 1
'

run_test "Slash commands reference Craft" '
    local output
    output=$(_teach_map 2>&1)
    echo "$output" | grep -q "/craft:site:check" || return 1
'

echo ""

# ============================================================================
# SECTION 7: Help Integration
# ============================================================================

echo "${CYAN}--- Section 7: Help Integration ---${RESET}"

run_test "teach help 'See also' references teach map" '
    local output
    output=$(teach help 2>&1)
    echo "$output" | grep -q "teach map" || return 1
'

run_test "teach help still works correctly" '
    local output
    output=$(teach help 2>&1)
    echo "$output" | grep -q "Teaching Workflow Commands" || return 1
'

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN dogfood tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
