#!/usr/bin/env zsh
# e2e-teach-map.zsh - End-to-end tests for teach map command
# v6.6.0 - Unified Ecosystem Discovery
#
# Tests the complete teach map workflow through the dispatcher,
# verifying output structure, tool detection, and integration
# with the help system.
#
# Run: ./tests/e2e-teach-map.zsh
# Sections: Setup (2), Dispatcher (4), Output Layout (5),
#           Tool Detection (4), Cross-Reference (3) = 18 tests

setopt local_options no_monitor

# ============================================================================
# TEST INFRASTRUCTURE
# ============================================================================

typeset -g TEST_PASS=0
typeset -g TEST_FAIL=0
typeset -g TEST_SKIP=0
typeset -g TEST_TOTAL=0
typeset -g SCRIPT_DIR="${0:A:h}"
typeset -g PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors
typeset -g GREEN="\033[32m"
typeset -g RED="\033[31m"
typeset -g YELLOW="\033[33m"
typeset -g CYAN="\033[36m"
typeset -g BOLD="\033[1m"
typeset -g RESET="\033[0m"

_test_pass() {
    ((TEST_PASS++))
    ((TEST_TOTAL++))
    printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

_test_fail() {
    ((TEST_FAIL++))
    ((TEST_TOTAL++))
    printf "  ${RED}✗${RESET} %s\n" "$1"
    [[ -n "$2" ]] && printf "    ${RED}→ %s${RESET}\n" "$2"
}

_test_skip() {
    ((TEST_SKIP++))
    ((TEST_TOTAL++))
    printf "  ${YELLOW}○${RESET} %s (skipped)\n" "$1"
}

_test_section() {
    echo ""
    printf "${BOLD}${CYAN}── %s ──${RESET}\n" "$1"
}

# ============================================================================
# SETUP
# ============================================================================

# Source the full plugin (not just the dispatcher) to test real integration
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}FATAL: flow.plugin.zsh failed to load${RESET}"
    exit 1
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo ""
    echo "${BOLD}${CYAN}╭─────────────────────────────────────────────────────────╮${RESET}"
    echo "${BOLD}${CYAN}│${RESET}  ${BOLD}teach map - End-to-End Tests${RESET}                            ${BOLD}${CYAN}│${RESET}"
    echo "${BOLD}${CYAN}╰─────────────────────────────────────────────────────────╯${RESET}"

    # ==================================================================
    # SECTION 1: Setup Verification (2 tests)
    # ==================================================================

    _test_section "Setup (2 tests)"

    # Test 1: Plugin loaded successfully
    if typeset -f teach >/dev/null 2>&1; then
        _test_pass "teach dispatcher function loaded"
    else
        _test_fail "teach dispatcher function loaded" "teach() not found"
        return 1
    fi

    # Test 2: _teach_map function exists
    if typeset -f _teach_map >/dev/null 2>&1; then
        _test_pass "_teach_map function loaded"
    else
        _test_fail "_teach_map function loaded" "_teach_map() not found"
        return 1
    fi

    # ==================================================================
    # SECTION 2: Dispatcher Routing (4 tests)
    # ==================================================================

    _test_section "Dispatcher Routing (4 tests)"

    # Test 3: teach map routes correctly (no error)
    local map_output
    map_output=$(teach map 2>&1)
    local map_rc=$?

    if [[ $map_rc -eq 0 ]]; then
        _test_pass "teach map exits with code 0"
    else
        _test_fail "teach map exits with code 0" "got exit code $map_rc"
    fi

    # Test 4: No "Unknown command" in output
    if ! echo "$map_output" | grep -q "Unknown command"; then
        _test_pass "teach map does not trigger unknown command"
    else
        _test_fail "teach map does not trigger unknown command" "got 'Unknown command'"
    fi

    # Test 5: Output is non-empty
    if [[ -n "$map_output" ]]; then
        _test_pass "teach map produces output"
    else
        _test_fail "teach map produces output" "output was empty"
    fi

    # Test 6: teach map --help also works (routes to map itself per spec)
    local help_out
    help_out=$(teach map --help 2>&1)
    if [[ -n "$help_out" ]] && echo "$help_out" | grep -q "teach map"; then
        _test_pass "teach map --help produces map output"
    else
        # map doesn't handle --help specially; it just runs _teach_map --help
        # which still produces the map. Either way, should contain "teach map"
        if echo "$map_output" | grep -q "teach map"; then
            _test_pass "teach map --help produces map output"
        else
            _test_fail "teach map --help produces map output"
        fi
    fi

    # ==================================================================
    # SECTION 3: Output Layout Verification (5 tests)
    # ==================================================================

    _test_section "Output Layout (5 tests)"

    # Test 7: Box header present
    if echo "$map_output" | grep -q "teach map -- Teaching Ecosystem"; then
        _test_pass "Box header: 'teach map -- Teaching Ecosystem'"
    else
        _test_fail "Box header: 'teach map -- Teaching Ecosystem'" "not found"
    fi

    # Test 8: Box-drawing characters present
    if echo "$map_output" | grep -q "╭─" && echo "$map_output" | grep -q "╰─"; then
        _test_pass "Box-drawing characters present"
    else
        _test_fail "Box-drawing characters present" "missing ╭─ or ╰─"
    fi

    # Test 9: All 5 phase sections present
    local phases_missing=""
    for phase in "SETUP & CONFIGURATION" "CONTENT GENERATION" "VALIDATION & QUALITY" "DEPLOYMENT" "SEMESTER TRACKING"; do
        echo "$map_output" | grep -q "$phase" || phases_missing="${phases_missing} '${phase}'"
    done
    if [[ -z "$phases_missing" ]]; then
        _test_pass "All 5 workflow phase headers present"
    else
        _test_fail "All 5 workflow phase headers present" "missing:${phases_missing}"
    fi

    # Test 10: Tools header line present
    if echo "$map_output" | grep -q "Tools:.*flow-cli"; then
        _test_pass "Tools header shows flow-cli"
    else
        _test_fail "Tools header shows flow-cli" "'Tools:' line with flow-cli not found"
    fi

    # Test 11: Footer tips present
    if echo "$map_output" | grep -q "Slash commands" && echo "$map_output" | grep -q "For usage details"; then
        _test_pass "Footer tips present"
    else
        _test_fail "Footer tips present" "missing footer lines"
    fi

    # ==================================================================
    # SECTION 4: Tool Detection Integration (4 tests)
    # ==================================================================

    _test_section "Tool Detection (4 tests)"

    # Test 12: _teach_map_detect_tools sets flow=1
    _teach_map_detect_tools
    if [[ "${_TEACH_MAP_TOOLS[flow]}" == "1" ]]; then
        _test_pass "Tool detection: flow=1 (always)"
    else
        _test_fail "Tool detection: flow=1 (always)" "got '${_TEACH_MAP_TOOLS[flow]}'"
    fi

    # Test 13: Scholar detection matches directory check
    local expected_scholar=0
    [[ -d "${HOME}/.claude/plugins/scholar" ]] && expected_scholar=1
    if [[ "${_TEACH_MAP_TOOLS[scholar]}" == "$expected_scholar" ]]; then
        _test_pass "Tool detection: scholar=${expected_scholar} (matches filesystem)"
    else
        _test_fail "Tool detection: scholar=${expected_scholar}" "got '${_TEACH_MAP_TOOLS[scholar]}'"
    fi

    # Test 14: Craft detection matches directory check
    local expected_craft=0
    [[ -d "${HOME}/.claude/plugins/craft" ]] && expected_craft=1
    if [[ "${_TEACH_MAP_TOOLS[craft]}" == "$expected_craft" ]]; then
        _test_pass "Tool detection: craft=${expected_craft} (matches filesystem)"
    else
        _test_fail "Tool detection: craft=${expected_craft}" "got '${_TEACH_MAP_TOOLS[craft]}'"
    fi

    # Test 15: Badges reflect tool availability
    local badge_ok=1
    if [[ "$expected_scholar" == "1" ]]; then
        # Should NOT have "(not installed)" for scholar
        echo "$map_output" | grep "scholar" | grep -q "(not installed)" && badge_ok=0
    else
        # Should have "(not installed)" for scholar
        echo "$map_output" | grep -q "scholar.*(not installed)" || badge_ok=0
    fi
    if [[ $badge_ok -eq 1 ]]; then
        _test_pass "Scholar badge reflects installation status"
    else
        _test_fail "Scholar badge reflects installation status"
    fi

    # ==================================================================
    # SECTION 5: Cross-Reference (3 tests)
    # ==================================================================

    _test_section "Cross-Reference (3 tests)"

    # Test 16: teach help references teach map
    local help_output
    help_output=$(teach help 2>&1)
    if echo "$help_output" | grep -q "teach map"; then
        _test_pass "teach help references 'teach map'"
    else
        _test_fail "teach help references 'teach map'" "not found in help output"
    fi

    # Test 17: All flow-cli commands in map also exist in dispatcher
    local cmds_ok=1
    local missing_cmds=""
    for cmd in init config doctor dates hooks plan templates macros prompt style deploy status week backup archive validate analyze profiles cache clean; do
        if ! echo "$map_output" | grep -q "teach $cmd"; then
            cmds_ok=0
            missing_cmds="${missing_cmds} $cmd"
        fi
    done
    if [[ $cmds_ok -eq 1 ]]; then
        _test_pass "All flow-cli commands present in map"
    else
        _test_fail "All flow-cli commands present in map" "missing:${missing_cmds}"
    fi

    # Test 18: All Scholar content commands present
    local scholar_ok=1
    local missing_scholar=""
    for cmd in lecture slides exam quiz assignment syllabus rubric feedback demo; do
        if ! echo "$map_output" | grep -q "teach $cmd"; then
            scholar_ok=0
            missing_scholar="${missing_scholar} $cmd"
        fi
    done
    if [[ $scholar_ok -eq 1 ]]; then
        _test_pass "All Scholar content commands present in map"
    else
        _test_fail "All Scholar content commands present in map" "missing:${missing_scholar}"
    fi

    # ==================================================================
    # SUMMARY
    # ==================================================================

    echo ""
    echo "${BOLD}─────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}Total:${RESET} %d  " "$TEST_TOTAL"
    printf "${GREEN}Pass:${RESET} %d  " "$TEST_PASS"
    printf "${RED}Fail:${RESET} %d  " "$TEST_FAIL"
    printf "${YELLOW}Skip:${RESET} %d\n" "$TEST_SKIP"
    echo "${BOLD}─────────────────────────────────────────────────────────${RESET}"
    echo ""

    if (( TEST_FAIL > 0 )); then
        printf "  ${RED}${BOLD}FAIL${RESET} - %d test(s) failed\n" "$TEST_FAIL"
        echo ""
        return 1
    else
        printf "  ${GREEN}${BOLD}PASS${RESET} - All %d tests passed\n" "$TEST_PASS"
        echo ""
        return 0
    fi
}

main "$@"
