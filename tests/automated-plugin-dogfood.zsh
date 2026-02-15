#!/usr/bin/env zsh
# automated-plugin-dogfood.zsh - Full plugin load dogfooding test
#
# Sources flow.plugin.zsh and verifies everything loaded correctly:
# - All 12 dispatchers are defined
# - Core commands exist
# - Help functions work for each dispatcher
# - No load errors
#
# Usage: zsh tests/automated-plugin-dogfood.zsh

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
        # Don't count skips as failures
    else
        echo "${RED}FAIL${RESET}"
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:200}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  Full Plugin Dogfood Test${RESET}"
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
# SECTION 1: Plugin metadata
# ============================================================================

echo "${CYAN}--- Section 1: Plugin Metadata ---${RESET}"

run_test "FLOW_PLUGIN_LOADED is set" '
    [[ "$FLOW_PLUGIN_LOADED" == "1" ]] || return 1
'

run_test "FLOW_VERSION is set" '
    [[ -n "$FLOW_VERSION" ]] || return 1
'

run_test "FLOW_PLUGIN_DIR points to project" '
    [[ -d "$FLOW_PLUGIN_DIR" ]] || return 1
    [[ -f "$FLOW_PLUGIN_DIR/flow.plugin.zsh" ]] || return 1
'

run_test "No stderr during plugin load" '
    local errs
    errs=$(FLOW_QUIET=1 source "$PROJECT_ROOT/flow.plugin.zsh" 2>&1 >/dev/null)
    [[ -z "$errs" ]] || { echo "$errs"; return 1; }
'

echo ""

# ============================================================================
# SECTION 2: All 12 dispatchers defined
# ============================================================================

echo "${CYAN}--- Section 2: Dispatcher Functions ---${RESET}"

dispatchers=(g mcp obs qu r cc tm wt dots sec tok teach prompt v)

for disp in "${dispatchers[@]}"; do
    run_test "Dispatcher '$disp' is a function" "
        typeset -f $disp >/dev/null 2>&1 || return 1
    "
done

echo ""

# ============================================================================
# SECTION 3: Core commands defined
# ============================================================================

echo "${CYAN}--- Section 3: Core Command Functions ---${RESET}"

core_commands=(
    work finish hop dash catch js status
    doctor flow_plugin
    win yay
)

for cmd in "${core_commands[@]}"; do
    run_test "Command '$cmd' is a function" "
        typeset -f $cmd >/dev/null 2>&1 || return 1
    "
done

echo ""

# ============================================================================
# SECTION 4: Dispatcher help functions exist and produce output
# ============================================================================

echo "${CYAN}--- Section 4: Dispatcher Help Output ---${RESET}"

# Map dispatchers to their help functions
typeset -A help_fns
help_fns=(
    g     _g_help
    mcp   _mcp_help
    obs   _obs_help
    qu    _qu_help
    r     _r_help
    cc    _cc_help
    tm    _tm_help
    wt    _wt_help
    dots  _dots_help
    sec   _sec_help
    tok   _tok_help
    teach _teach_dispatcher_help
    prompt _prompt_help
    v     _v_help
)

for disp fn in "${(@kv)help_fns}"; do
    run_test "'$disp help' produces non-empty output" "
        local output
        output=\$($fn 2>&1)
        [[ -n \"\$output\" ]] || return 1
        # Help output should be at least 5 lines
        local lines=\$(echo \"\$output\" | wc -l | tr -d ' ')
        (( lines >= 5 )) || { echo \"Only \$lines lines\"; return 1; }
    "
done

echo ""

# ============================================================================
# SECTION 5: Core library functions loaded
# ============================================================================

echo "${CYAN}--- Section 5: Core Library Functions ---${RESET}"

core_lib_fns=(
    _flow_log_success
    _flow_log_error
    _flow_log_info
    _flow_find_project_root
    _flow_detect_project_type
    _flow_project_name
    _flow_confirm
    _flow_human_size
)

for fn in "${core_lib_fns[@]}"; do
    run_test "Core function '$fn' exists" "
        typeset -f $fn >/dev/null 2>&1 || return 1
    "
done

echo ""

# ============================================================================
# SECTION 6: flow doctor basic invocation
# ============================================================================

echo "${CYAN}--- Section 6: Flow Doctor ---${RESET}"

run_test "flow doctor produces output" '
    local output
    output=$(flow_doctor 2>&1 | head -20)
    [[ -n "$output" ]] || return 1
'

run_test "flow doctor --help produces help" '
    local output
    output=$(flow_doctor --help 2>&1)
    [[ "$output" == *"doctor"* ]] || [[ "$output" == *"health"* ]] || [[ "$output" == *"USAGE"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 7: Plugin system loaded
# ============================================================================

echo "${CYAN}--- Section 7: Plugin System ---${RESET}"

run_test "Plugin init function ran" '
    typeset -f _flow_plugin_init >/dev/null 2>&1 || return 1
'

run_test "_FLOW_PLUGINS associative array exists" '
    [[ "${(t)_FLOW_PLUGINS}" == *association* ]] || return 1
'

run_test "flow plugin list runs without error" '
    local output
    output=$(flow_plugin list 2>&1)
    local rc=$?
    # rc=0 is pass; also accept if it just lists (even empty)
    [[ $rc -eq 0 ]] || return 1
'

run_test "flow plugin help produces output" '
    local output
    output=$(flow_plugin help 2>&1)
    [[ "$output" == *"plugin"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 8: No shadowed path variables in loaded functions
# ============================================================================

echo "${CYAN}--- Section 8: Runtime Safety ---${RESET}"

run_test "External commands accessible after plugin load" '
    # If $path was shadowed during load, these would fail
    command -v ls >/dev/null 2>&1 || return 1
    command -v grep >/dev/null 2>&1 || return 1
    command -v git >/dev/null 2>&1 || return 1
'

run_test "\$path array is intact (not shadowed)" '
    # $path should be an array, not a scalar
    [[ "${(t)path}" == *array* ]] || return 1
    # Should have multiple entries
    (( ${#path[@]} > 1 )) || return 1
'

run_test "\$fpath array is intact" '
    [[ "${(t)fpath}" == *array* ]] || return 1
    (( ${#fpath[@]} > 1 )) || return 1
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
