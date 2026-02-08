#!/usr/bin/env zsh
# integration-teach-macros.zsh - Integration tests for teach macros command
# Run with: zsh tests/integration-teach-macros.zsh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Test fixture
DEMO_COURSE="tests/fixtures/demo-course"
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
    echo -n "${CYAN}TEST: $1${RESET} ... "
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    echo "${GREEN}PASS${RESET}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo "${RED}FAIL${RESET}"
    echo "  ${RED}-> $1${RESET}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "==========================================================================="
echo "  TEACH MACROS INTEGRATION TEST SUITE"
echo "==========================================================================="
echo ""
echo "Project: $PROJECT_ROOT"
echo "Fixture: $DEMO_COURSE"
echo ""

cd "$PROJECT_ROOT" || { echo "Failed to cd to project root"; exit 1; }

# Source the plugin
source flow.plugin.zsh 2>/dev/null || {
    echo "${RED}Failed to source flow.plugin.zsh${RESET}"
    exit 1
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

echo "-- Command Availability --"

test_start "teach macros command exists"
if typeset -f _teach_macros >/dev/null 2>&1; then
    test_pass
else
    test_fail "_teach_macros function not found"
fi

test_start "teach macros list subcommand exists"
if typeset -f _teach_macros_list >/dev/null 2>&1; then
    test_pass
else
    test_fail "_teach_macros_list function not found"
fi

test_start "teach macros sync subcommand exists"
if typeset -f _teach_macros_sync >/dev/null 2>&1; then
    test_pass
else
    test_fail "_teach_macros_sync function not found"
fi

test_start "teach macros export subcommand exists"
if typeset -f _teach_macros_export >/dev/null 2>&1; then
    test_pass
else
    test_fail "_teach_macros_export function not found"
fi

echo ""
echo "-- Macro Parsing (Demo Course) --"

# Navigate to demo course for these tests
cd "$PROJECT_ROOT/$DEMO_COURSE" || { echo "Failed to cd to demo course"; exit 1; }

test_start "Config loading from demo course"
if _flow_load_macro_config 2>/dev/null; then
    test_pass
else
    test_fail "Failed to load macro config from demo course"
fi

test_start "Macros parsed from _macros.qmd"
count=$(_flow_macro_count)
if (( count > 0 )); then
    test_pass
else
    test_fail "No macros found (expected > 0)"
fi

test_start "Expected macro count (13 macros)"
if (( count == 13 )); then
    test_pass
else
    test_fail "Expected 13 macros, got $count"
fi

test_start "\\E macro parsed correctly"
expansion=$(_flow_get_macro "E")
if [[ "$expansion" == "\\mathbb{E}" ]]; then
    test_pass
else
    test_fail "Expected \\mathbb{E}, got: $expansion"
fi

test_start "\\Var macro parsed correctly"
expansion=$(_flow_get_macro "Var")
if [[ "$expansion" == "\\text{Var}" ]]; then
    test_pass
else
    test_fail "Expected \\text{Var}, got: $expansion"
fi

test_start "\\Cov macro with 2 args parsed"
expansion=$(_flow_get_macro "Cov")
meta=$(_flow_get_macro_meta "Cov")
args="${meta##*:}"
if [[ "$args" == "2" ]]; then
    test_pass
else
    test_fail "Expected 2 args, got: $args"
fi

test_start "\\indep symbol parsed"
expansion=$(_flow_get_macro "indep")
if [[ -n "$expansion" ]]; then
    test_pass
else
    test_fail "indep macro not found"
fi

echo ""
echo "-- Export Functions --"

test_start "JSON export produces valid structure"
json=$(_flow_export_macros_json)
if [[ "$json" == "{"* && "$json" == *"}" ]]; then
    test_pass
else
    test_fail "JSON doesn't start/end with braces"
fi

test_start "JSON export contains E macro"
if [[ "$json" == *'"E":'* ]]; then
    test_pass
else
    test_fail "E macro not in JSON output"
fi

test_start "MathJax export produces macros block"
mathjax=$(_flow_export_macros_mathjax)
if [[ "$mathjax" == *"macros:"* ]]; then
    test_pass
else
    test_fail "MathJax output missing 'macros:' header"
fi

test_start "LaTeX export produces \\newcommand"
latex=$(_flow_export_macros_latex)
if [[ "$latex" == *"\\newcommand"* ]]; then
    test_pass
else
    test_fail "LaTeX output missing \\newcommand"
fi

test_start "QMD export wraps in tex block"
qmd=$(_flow_export_macros_qmd)
if [[ "$qmd" == *'```{=tex}'* && "$qmd" == *'```'* ]]; then
    test_pass
else
    test_fail "QMD output missing tex block markers"
fi

echo ""
echo "-- Command Output --"

test_start "teach macros list runs without error"
output=$(cd "$PROJECT_ROOT/$DEMO_COURSE" && _teach_macros_list 2>&1)
if [[ $? -eq 0 || "$output" == *"LaTeX Macros"* ]]; then
    test_pass
else
    test_fail "teach macros list failed"
fi

test_start "teach macros list shows macro count"
if [[ "$output" == *"available"* ]]; then
    test_pass
else
    test_fail "Output doesn't show macro count"
fi

test_start "teach macros export --json produces JSON"
json_output=$(cd "$PROJECT_ROOT/$DEMO_COURSE" && _teach_macros_export --json 2>&1)
if [[ "$json_output" == "{"* ]]; then
    test_pass
else
    test_fail "JSON export command failed"
fi

test_start "teach macros help shows usage"
help_output=$(_teach_macros_help 2>&1)
if [[ "$help_output" == *"USAGE"* ]]; then
    test_pass
else
    test_fail "Help doesn't show USAGE section"
fi

echo ""
echo "-- Category Detection --"

test_start "E detected as operator category"
category=$(_macro_detect_category "E")
if [[ "$category" == "operators" ]]; then
    test_pass
else
    test_fail "Expected 'operators', got: $category"
fi

test_start "indep detected as symbols category"
category=$(_macro_detect_category "indep")
if [[ "$category" == "symbols" ]]; then
    test_pass
else
    test_fail "Expected 'symbols', got: $category"
fi

test_start "Normal detected as distributions category"
category=$(_macro_detect_category "Normal")
if [[ "$category" == "distributions" ]]; then
    test_pass
else
    test_fail "Expected 'distributions', got: $category"
fi

test_start "unknown macro defaults to 'other'"
category=$(_macro_detect_category "unknownMacro")
if [[ "$category" == "other" ]]; then
    test_pass
else
    test_fail "Expected 'other', got: $category"
fi

echo ""
echo "-- Sync Command --"

# Ensure cache directory exists
mkdir -p "$PROJECT_ROOT/$DEMO_COURSE/.flow/macros" 2>/dev/null

test_start "teach macros sync creates registry file"
(cd "$PROJECT_ROOT/$DEMO_COURSE" && _teach_macros_sync 2>&1) >/dev/null
if [[ -f "$PROJECT_ROOT/$DEMO_COURSE/.flow/macros/registry.yml" ]]; then
    test_pass
else
    test_fail "Registry file not created"
fi

test_start "Registry file contains macro definitions"
cache_content=$(cat "$PROJECT_ROOT/$DEMO_COURSE/.flow/macros/registry.yml" 2>/dev/null)
if [[ "$cache_content" == *"macros:"* && "$cache_content" == *"E:"* ]]; then
    test_pass
else
    test_fail "Registry file missing expected content"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "==========================================================================="
echo "  TEST SUMMARY"
echo "==========================================================================="
echo ""
echo "  Total:  $TESTS_RUN"
echo "  ${GREEN}Passed: $TESTS_PASSED${RESET}"
echo "  ${RED}Failed: $TESTS_FAILED${RESET}"
echo ""

if (( TESTS_FAILED == 0 )); then
    echo "${GREEN}ALL TESTS PASSED${RESET}"
    exit 0
else
    echo "${RED}SOME TESTS FAILED${RESET}"
    exit 1
fi
