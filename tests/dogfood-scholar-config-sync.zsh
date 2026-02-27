#!/usr/bin/env zsh
# dogfood-scholar-config-sync.zsh - Structural dogfood tests for Scholar Config Sync (#423)
#
# Verifies that all Scholar Config Sync components are properly wired:
# - New commands appear in help output
# - Config injection code exists in teach-dispatcher
# - Doctor function exists and is wired
# - Build command handles all new Scholar subcommands
# - Documentation references all new commands
# - Tests exist for all new functionality
#
# Usage: zsh tests/dogfood-scholar-config-sync.zsh

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
echo "${CYAN}  Scholar Config Sync (#423) - Dogfood Test${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ============================================================================
# LOAD PLUGIN
# ============================================================================

echo "${CYAN}Loading flow.plugin.zsh...${RESET}"
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "${PROJECT_ROOT}/flow.plugin.zsh" 2>/dev/null

echo ""
echo "${CYAN}── Code Structure ──${RESET}"

# ============================================================================
# CODE STRUCTURE CHECKS
# ============================================================================

# 1. Config injection code exists in teach-dispatcher
run_test "Config injection block in teach-dispatcher" '
    grep -q "Config injection.*Scholar Config Sync" "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh"
'

# 2. _teach_find_config call in injection block
run_test "_teach_find_config wired for injection" '
    grep -q "_teach_find_config" "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh"
'

# 3. --config flag appended
run_test "--config flag in command assembly" '
    grep -q "\-\-config" "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh"
'

# 4. Stale config warning in preflight
run_test "Stale config warning in _teach_preflight" '
    grep -q "_flow_config_changed" "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh"
'

# 5. Legacy deprecation warning
run_test "Legacy deprecation warning exists" '
    grep -q "Deprecated.*teaching-style.local.md" "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh"
'

# 6. Doctor config sync function
run_test "_teach_doctor_config_sync function exists" '
    grep -q "_teach_doctor_config_sync" "$PROJECT_ROOT/lib/dispatchers/teach-doctor-impl.zsh"
'

# 7. Doctor wired into quick mode
run_test "Doctor config sync in quick mode" '
    # Should appear BEFORE the full mode gate
    local line_sync=$(grep -n "_teach_doctor_config_sync" "$PROJECT_ROOT/lib/dispatchers/teach-doctor-impl.zsh" | head -1 | cut -d: -f1)
    local line_full=$(grep -n "Full mode checks" "$PROJECT_ROOT/lib/dispatchers/teach-doctor-impl.zsh" | head -1 | cut -d: -f1)
    [[ -n "$line_sync" && -n "$line_full" && $line_sync -lt $line_full ]]
'

echo ""
echo "${CYAN}── Command Routing ──${RESET}"

# ============================================================================
# COMMAND ROUTING CHECKS
# ============================================================================

# 8. Config subcommands in dispatcher case statement
for subcmd in check diff show scaffold; do
    run_test "teach config $subcmd routed" "
        grep -q '$subcmd)' \"\$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh\"
    "
done

# 9. New wrapper commands in dispatcher
for cmd in solution sync validate-r; do
    run_test "teach $cmd in dispatcher case" "
        grep -q '${cmd})' \"\$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh\"
    "
done

# 10. New commands in _teach_build_command mapping
for cmd in solution sync validate-r config; do
    run_test "$cmd in _teach_build_command" "
        grep -q '${cmd}).*scholar_cmd=' \"\$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh\"
    "
done

echo ""
echo "${CYAN}── Function Loading ──${RESET}"

# ============================================================================
# FUNCTION LOADING CHECKS
# ============================================================================

# 11. Functions are loaded after sourcing plugin
run_test "_teach_find_config loaded" '
    typeset -f _teach_find_config >/dev/null 2>&1
'

run_test "_flow_config_hash loaded" '
    typeset -f _flow_config_hash >/dev/null 2>&1
'

run_test "_flow_config_changed loaded" '
    typeset -f _flow_config_changed >/dev/null 2>&1
'

run_test "_teach_build_command loaded" '
    typeset -f _teach_build_command >/dev/null 2>&1
'

run_test "_teach_doctor_config_sync loaded" '
    typeset -f _teach_doctor_config_sync >/dev/null 2>&1
'

run_test "teach function loaded" '
    typeset -f teach >/dev/null 2>&1
'

echo ""
echo "${CYAN}── Help Output ──${RESET}"

# ============================================================================
# HELP OUTPUT CHECKS
# ============================================================================

help_output=$(_teach_dispatcher_help 2>&1)

for entry in "config check" "config diff" "config show" "config scaffold" "solution" "sync" "validate-r"; do
    run_test "Help includes '$entry'" "
        echo \"\$help_output\" | grep -q '$entry'
    "
done

# New shortcuts in help
for alias_entry in "sol=solution" "vr=validate-r"; do
    run_test "Help shows shortcut $alias_entry" "
        echo \"\$help_output\" | grep -q '$(echo $alias_entry | cut -d= -f1)'
    "
done

echo ""
echo "${CYAN}── Documentation ──${RESET}"

# ============================================================================
# DOCUMENTATION CHECKS
# ============================================================================

run_test "CLAUDE.md lists new subcommands" '
    grep -q "teach solution" "$PROJECT_ROOT/CLAUDE.md" &&
    grep -q "teach sync" "$PROJECT_ROOT/CLAUDE.md" &&
    grep -q "teach validate-r" "$PROJECT_ROOT/CLAUDE.md"
'

run_test "QUICK-REFERENCE includes config commands" '
    grep -q "config check" "$PROJECT_ROOT/docs/help/QUICK-REFERENCE.md"
'

run_test "MASTER-DISPATCHER-GUIDE includes new commands" '
    grep -q "solution" "$PROJECT_ROOT/docs/reference/MASTER-DISPATCHER-GUIDE.md" &&
    grep -q "validate-r" "$PROJECT_ROOT/docs/reference/MASTER-DISPATCHER-GUIDE.md"
'

run_test "SCHOLAR-INTEGRATION-GUIDE exists" '
    [[ -f "$PROJECT_ROOT/docs/guides/SCHOLAR-INTEGRATION-GUIDE.md" ]]
'

run_test "TEACHING-SYSTEM-ARCHITECTURE has Config Sync section" '
    grep -q "Config Sync" "$PROJECT_ROOT/docs/guides/TEACHING-SYSTEM-ARCHITECTURE.md"
'

echo ""
echo "${CYAN}── Test Coverage ──${RESET}"

# ============================================================================
# TEST COVERAGE CHECKS
# ============================================================================

run_test "Unit tests exist (test-scholar-config-sync.zsh)" '
    [[ -f "$PROJECT_ROOT/tests/test-scholar-config-sync.zsh" ]]
'

run_test "E2E tests exist (e2e-scholar-config-sync.zsh)" '
    [[ -f "$PROJECT_ROOT/tests/e2e-scholar-config-sync.zsh" ]]
'

run_test "Tests in run-all.sh" '
    grep -q "test-scholar-config-sync" "$PROJECT_ROOT/tests/run-all.sh"
'

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}  ✅ All $TESTS_PASSED dogfood checks passed${RESET}"
    exit 0
else
    echo "${RED}  ❌ $TESTS_FAILED failures out of $TESTS_RUN checks${RESET}"
    exit 1
fi
