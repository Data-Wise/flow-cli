#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: OBS Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate obs dispatcher functionality
# Coverage: Function existence, help output, version, unknown commands
#
# Test Categories:
#   1. Function Existence (4 tests)
#   2. Help Output (2 tests)
#   3. Help Content (4 tests)
#   4. Version (1 test)
#   5. Unknown Command (1 test)
#
# Created: 2026-02-16
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP / CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/dispatchers/obs.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/obs.zsh" ]]; then
            PROJECT_ROOT="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/obs.zsh" ]]; then
            PROJECT_ROOT="$PWD/.."
        fi
    fi

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/dispatchers/obs.zsh" ]]; then
        echo "ERROR: Cannot find project root — run from project directory"
        exit 1
    fi

    # Source core (for color helpers) and the dispatcher
    source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null
    source "$PROJECT_ROOT/lib/dispatchers/obs.zsh" 2>/dev/null
}

cleanup() {
    reset_mocks
}
trap cleanup EXIT

setup

# ══════════════════════════════════════════════════════════════════════════════
# 1. FUNCTION EXISTENCE TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_suite_start "OBS Dispatcher Tests"

echo "${YELLOW}Function Existence${RESET}"
echo "────────────────────────────────────────"

test_case "obs function is defined"
assert_function_exists "obs" && test_pass

test_case "obs_help function is defined"
assert_function_exists "obs_help" && test_pass

test_case "obs_version function is defined"
assert_function_exists "obs_version" && test_pass

test_case "obs_vaults function is defined"
assert_function_exists "obs_vaults" && test_pass

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 2. HELP TESTS
# ══════════════════════════════════════════════════════════════════════════════

echo "${YELLOW}Help Tests${RESET}"
echo "────────────────────────────────────────"

test_case "obs help shows usage"
local output_help=$(obs help 2>&1)
assert_not_contains "$output_help" "command not found"
assert_contains "$output_help" "Obsidian Vault Manager" && test_pass

test_case "obs help --all shows full help"
local output_help_all=$(obs help --all 2>&1)
assert_not_contains "$output_help_all" "command not found"
assert_contains "$output_help_all" "VAULT COMMANDS" && test_pass

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 3. HELP CONTENT TESTS
# ══════════════════════════════════════════════════════════════════════════════

echo "${YELLOW}Help Content${RESET}"
echo "────────────────────────────────────────"

test_case "help shows stats command"
assert_contains "$output_help_all" "stats" && test_pass

test_case "help shows discover command"
assert_contains "$output_help_all" "discover" && test_pass

test_case "help shows analyze command"
assert_contains "$output_help_all" "analyze" && test_pass

test_case "help shows AI features section"
assert_contains "$output_help_all" "AI FEATURES" && test_pass

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 4. VERSION TESTS
# ══════════════════════════════════════════════════════════════════════════════

echo "${YELLOW}Version${RESET}"
echo "────────────────────────────────────────"

test_case "obs version shows version"
local output_version=$(obs version 2>&1)
assert_not_contains "$output_version" "command not found"
assert_contains "$output_version" "version" && test_pass

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 5. UNKNOWN COMMAND TESTS
# ══════════════════════════════════════════════════════════════════════════════

echo "${YELLOW}Unknown Command${RESET}"
echo "────────────────────────────────────────"

test_case "obs unknown-cmd shows error"
local output_unknown=$(obs unknown-xyz-command 2>&1)
assert_not_contains "$output_unknown" "command not found"
assert_contains "$output_unknown" "Unknown command" && test_pass

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

cleanup
test_suite_end
exit $?
