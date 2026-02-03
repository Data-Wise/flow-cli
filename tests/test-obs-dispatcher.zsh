#!/usr/bin/env zsh
# Test script for obs dispatcher
# Tests: help, function existence, version command

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    local project_root=""

    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/obs.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/obs.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/obs.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/obs.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source obs dispatcher
    source "$project_root/lib/dispatchers/obs.zsh"

    echo "  Loaded: obs.zsh"
    echo ""
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_obs_function_exists() {
    log_test "obs function is defined"

    if (( $+functions[obs] )); then
        pass
    else
        fail "obs function not defined"
    fi
}

test_obs_help_function_exists() {
    log_test "obs_help function is defined"

    if (( $+functions[obs_help] )); then
        pass
    else
        fail "obs_help function not defined"
    fi
}

test_obs_version_function_exists() {
    log_test "obs_version function is defined"

    if (( $+functions[obs_version] )); then
        pass
    else
        fail "obs_version function not defined"
    fi
}

test_obs_vaults_function_exists() {
    log_test "obs_vaults function is defined"

    if (( $+functions[obs_vaults] )); then
        pass
    else
        fail "obs_vaults function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_obs_help() {
    log_test "obs help shows usage"

    local output=$(obs help 2>&1)

    if echo "$output" | grep -q "Obsidian Vault Manager"; then
        pass
    else
        fail "Help header not found"
    fi
}

test_obs_help_all() {
    log_test "obs help --all shows full help"

    local output=$(obs help --all 2>&1)

    if echo "$output" | grep -q "VAULT COMMANDS"; then
        pass
    else
        fail "--all flag doesn't show full help"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_stats() {
    log_test "help shows stats command"

    local output=$(obs help --all 2>&1)

    if echo "$output" | grep -q "stats"; then
        pass
    else
        fail "stats not in help"
    fi
}

test_help_shows_discover() {
    log_test "help shows discover command"

    local output=$(obs help --all 2>&1)

    if echo "$output" | grep -q "discover"; then
        pass
    else
        fail "discover not in help"
    fi
}

test_help_shows_analyze() {
    log_test "help shows analyze command"

    local output=$(obs help --all 2>&1)

    if echo "$output" | grep -q "analyze"; then
        pass
    else
        fail "analyze not in help"
    fi
}

test_help_shows_ai() {
    log_test "help shows ai command"

    local output=$(obs help --all 2>&1)

    if echo "$output" | grep -q "AI FEATURES"; then
        pass
    else
        fail "ai section not in help"
    fi
}

# ============================================================================
# VERSION TESTS
# ============================================================================

test_version_command() {
    log_test "obs version shows version"

    local output=$(obs version 2>&1)

    if echo "$output" | grep -q "version"; then
        pass
    else
        fail "Version not shown"
    fi
}

# ============================================================================
# UNKNOWN COMMAND TESTS
# ============================================================================

test_unknown_command() {
    log_test "obs unknown-cmd shows error"

    local output=$(obs unknown-xyz-command 2>&1)

    if echo "$output" | grep -q "Unknown command"; then
        pass
    else
        fail "Unknown command error not shown"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  OBS Dispatcher Tests                                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Function Existence Tests${NC}"
    echo "────────────────────────────────────────"
    test_obs_function_exists
    test_obs_help_function_exists
    test_obs_version_function_exists
    test_obs_vaults_function_exists
    echo ""

    echo "${YELLOW}Help Tests${NC}"
    echo "────────────────────────────────────────"
    test_obs_help
    test_obs_help_all
    echo ""

    echo "${YELLOW}Help Content Tests${NC}"
    echo "────────────────────────────────────────"
    test_help_shows_stats
    test_help_shows_discover
    test_help_shows_analyze
    test_help_shows_ai
    echo ""

    echo "${YELLOW}Version Tests${NC}"
    echo "────────────────────────────────────────"
    test_version_command
    echo ""

    echo "${YELLOW}Unknown Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_unknown_command
    echo ""

    echo "════════════════════════════════════════"
    echo "${CYAN}Summary${NC}"
    echo "────────────────────────────────────────"
    echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
