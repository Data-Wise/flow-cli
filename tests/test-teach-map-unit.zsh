#!/usr/bin/env zsh
# test-teach-map-unit.zsh - Unit tests for teach map command
# v6.6.0 - Unified Ecosystem Discovery

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Test framework
PASS=0
FAIL=0
SKIP=0

_test_pass() { ((PASS++)); echo "  ✅ $1"; }
_test_fail() { ((FAIL++)); echo "  ❌ $1: $2"; }
_test_skip() { ((SKIP++)); echo "  ⏭️  $1 (skipped)"; }

# Minimal colors for non-interactive
typeset -gA FLOW_COLORS
FLOW_COLORS[info]=""
FLOW_COLORS[success]=""
FLOW_COLORS[error]=""
FLOW_COLORS[warn]=""
FLOW_COLORS[dim]=""
FLOW_COLORS[bold]=""
FLOW_COLORS[reset]=""
FLOW_COLORS[prompt]=""
FLOW_COLORS[muted]=""

# Source core + dispatcher (suppress output)
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true

# Source just the teach dispatcher
source "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh" 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach map - Unit Tests                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. OUTPUT STRUCTURE (4 tests)
# ============================================================================

echo "── Output Structure ──"

# Test 1: _teach_map produces output (non-empty)
output=$(_teach_map 2>&1)
if [[ -n "$output" ]]; then
    _test_pass "teach map produces non-empty output"
else
    _test_fail "teach map produces non-empty output" "output was empty"
fi

# Test 2: Output contains the box header
if echo "$output" | grep -q "teach map -- Teaching Ecosystem"; then
    _test_pass "output contains box header 'teach map -- Teaching Ecosystem'"
else
    _test_fail "output contains box header 'teach map -- Teaching Ecosystem'" "header not found"
fi

# Test 3: Output contains all 5 phase headers
local phases_ok=1
local missing_phases=""
for phase in "SETUP & CONFIGURATION" "CONTENT GENERATION" "VALIDATION & QUALITY" "DEPLOYMENT" "SEMESTER TRACKING"; do
    if ! echo "$output" | grep -q "$phase"; then
        phases_ok=0
        missing_phases="${missing_phases} '${phase}'"
    fi
done
if [[ $phases_ok -eq 1 ]]; then
    _test_pass "output contains all 5 phase headers"
else
    _test_fail "output contains all 5 phase headers" "missing:${missing_phases}"
fi

# Test 4: Output contains the footer tips
if echo "$output" | grep -q "Slash commands" && echo "$output" | grep -q "For usage details"; then
    _test_pass "output contains footer tips"
else
    _test_fail "output contains footer tips" "'Slash commands' or 'For usage details' not found"
fi

# ============================================================================
# 2. FLOW-CLI COMMANDS PRESENT (4 tests)
# ============================================================================

echo ""
echo "── Flow-CLI Commands ──"

# Test 5: Output contains core flow-cli setup commands
if echo "$output" | grep -q "teach init" && echo "$output" | grep -q "teach config" && echo "$output" | grep -q "teach doctor"; then
    _test_pass "output contains teach init, teach config, teach doctor"
else
    _test_fail "output contains teach init, teach config, teach doctor" "one or more missing"
fi

# Test 6: Output contains teach deploy
if echo "$output" | grep -q "teach deploy"; then
    _test_pass "output contains teach deploy"
else
    _test_fail "output contains teach deploy" "teach deploy not found"
fi

# Test 7: Output contains teach status and teach week
if echo "$output" | grep -q "teach status" && echo "$output" | grep -q "teach week"; then
    _test_pass "output contains teach status and teach week"
else
    _test_fail "output contains teach status and teach week" "one or both missing"
fi

# Test 8: Output contains [flow-cli] badge
if echo "$output" | grep -q "\[flow-cli\]"; then
    _test_pass "output contains [flow-cli] badge"
else
    _test_fail "output contains [flow-cli] badge" "[flow-cli] badge not found"
fi

# ============================================================================
# 3. SCHOLAR COMMANDS PRESENT (3 tests)
# ============================================================================

echo ""
echo "── Scholar Commands ──"

# Test 9: Output contains Scholar content commands
if echo "$output" | grep -q "teach lecture" && echo "$output" | grep -q "teach exam" && echo "$output" | grep -q "teach slides"; then
    _test_pass "output contains teach lecture, teach exam, teach slides"
else
    _test_fail "output contains teach lecture, teach exam, teach slides" "one or more missing"
fi

# Test 10: Output contains teach syllabus, teach rubric, teach feedback
if echo "$output" | grep -q "teach syllabus" && echo "$output" | grep -q "teach rubric" && echo "$output" | grep -q "teach feedback"; then
    _test_pass "output contains teach syllabus, teach rubric, teach feedback"
else
    _test_fail "output contains teach syllabus, teach rubric, teach feedback" "one or more missing"
fi

# Test 11: Output contains [scholar] badge text
if echo "$output" | grep -q "\[scholar\]"; then
    _test_pass "output contains [scholar] badge"
else
    _test_fail "output contains [scholar] badge" "[scholar] badge not found"
fi

# ============================================================================
# 4. CRAFT COMMANDS PRESENT (3 tests)
# ============================================================================

echo ""
echo "── Craft Commands ──"

# Test 12: Output contains Craft slash commands for publishing
if echo "$output" | grep -q "/craft:site:publish" && echo "$output" | grep -q "/craft:site:build"; then
    _test_pass "output contains /craft:site:publish and /craft:site:build"
else
    _test_fail "output contains /craft:site:publish and /craft:site:build" "one or both missing"
fi

# Test 13: Output contains Craft slash commands for checking and progress
if echo "$output" | grep -q "/craft:site:check" && echo "$output" | grep -q "/craft:site:progress"; then
    _test_pass "output contains /craft:site:check and /craft:site:progress"
else
    _test_fail "output contains /craft:site:check and /craft:site:progress" "one or both missing"
fi

# Test 14: Output contains [craft] badge text
if echo "$output" | grep -q "\[craft\]"; then
    _test_pass "output contains [craft] badge"
else
    _test_fail "output contains [craft] badge" "[craft] badge not found"
fi

# ============================================================================
# 5. TOOL DETECTION (3 tests)
# ============================================================================

echo ""
echo "── Tool Detection ──"

# Test 15: _teach_map_detect_tools sets flow to 1
_teach_map_detect_tools
if [[ "${_TEACH_MAP_TOOLS[flow]}" == "1" ]]; then
    _test_pass "_teach_map_detect_tools sets flow=1"
else
    _test_fail "_teach_map_detect_tools sets flow=1" "got '${_TEACH_MAP_TOOLS[flow]}'"
fi

# Test 16: scholar is a valid value (0 or 1)
if [[ "${_TEACH_MAP_TOOLS[scholar]}" == "0" || "${_TEACH_MAP_TOOLS[scholar]}" == "1" ]]; then
    _test_pass "_TEACH_MAP_TOOLS[scholar] is valid (${_TEACH_MAP_TOOLS[scholar]})"
else
    _test_fail "_TEACH_MAP_TOOLS[scholar] is valid" "got '${_TEACH_MAP_TOOLS[scholar]}'"
fi

# Test 17: craft is a valid value (0 or 1)
if [[ "${_TEACH_MAP_TOOLS[craft]}" == "0" || "${_TEACH_MAP_TOOLS[craft]}" == "1" ]]; then
    _test_pass "_TEACH_MAP_TOOLS[craft] is valid (${_TEACH_MAP_TOOLS[craft]})"
else
    _test_fail "_TEACH_MAP_TOOLS[craft] is valid" "got '${_TEACH_MAP_TOOLS[craft]}'"
fi

# ============================================================================
# 6. DISPATCHER ROUTING (2 tests)
# ============================================================================

echo ""
echo "── Dispatcher Routing ──"

# Test 18: teach map doesn't trigger the unknown command error
route_output=$(teach map 2>&1)
if ! echo "$route_output" | grep -q "Unknown command: map"; then
    _test_pass "teach map does not trigger unknown command error"
else
    _test_fail "teach map does not trigger unknown command error" "got 'Unknown command: map'"
fi

# Test 19: teach map produces output containing "teach map"
if echo "$route_output" | grep -q "teach map"; then
    _test_pass "teach map route produces output containing 'teach map'"
else
    _test_fail "teach map route produces output containing 'teach map'" "'teach map' not found in routed output"
fi

# ============================================================================
# 7. HELP CROSS-REFERENCE (1 test)
# ============================================================================

echo ""
echo "── Help Cross-Reference ──"

# Test 20: _teach_dispatcher_help mentions teach map in See also
help_output=$(_teach_dispatcher_help 2>&1)
if echo "$help_output" | grep -q "See also" && echo "$help_output" | grep -q "teach map"; then
    _test_pass "teach help 'See also' references teach map"
else
    _test_fail "teach help 'See also' references teach map" "teach map not found in See also section"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Passed: $PASS | Failed: $FAIL | Skipped: $SKIP"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
