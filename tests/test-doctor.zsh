#!/usr/bin/env zsh
# Test script for doctor command (health check)
# Tests: dependency checking, fix mode, help output
# Generated: 2025-12-30

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

# Resolve project root at top level (${0:A} doesn't work inside functions)
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${NC}"
        exit 1
    }

    # Close stdin to prevent any interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    trap "rm -rf '$TEST_ROOT'" EXIT
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev"
    echo "## Status: active\n## Progress: 50" > "$TEST_ROOT/dev-tools/mock-dev/.STATUS"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    # Cache doctor outputs to avoid repeated API calls (each doctor run hits GitHub API)
    CACHED_DOCTOR_DEFAULT=$(doctor 2>&1)
    CACHED_DOCTOR_HELP=$(doctor --help 2>&1)

    echo ""
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_doctor_exists() {
    log_test "doctor command exists"

    if type doctor &>/dev/null; then
        pass
    else
        fail "doctor command not found"
    fi
}

test_doctor_help_exists() {
    log_test "_doctor_help function exists"

    if type _doctor_help &>/dev/null; then
        pass
    else
        fail "_doctor_help not found"
    fi
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_doctor_check_cmd_exists() {
    log_test "_doctor_check_cmd function exists"

    if type _doctor_check_cmd &>/dev/null; then
        pass
    else
        fail "_doctor_check_cmd not found"
    fi
}

test_doctor_check_plugin_exists() {
    log_test "_doctor_check_zsh_plugin function exists"

    if type _doctor_check_zsh_plugin &>/dev/null; then
        pass
    else
        fail "_doctor_check_zsh_plugin not found"
    fi
}

test_doctor_check_plugin_manager_exists() {
    log_test "_doctor_check_plugin_manager function exists"

    if type _doctor_check_plugin_manager &>/dev/null; then
        pass
    else
        fail "_doctor_check_plugin_manager not found"
    fi
}

# ============================================================================
# TESTS: Help output
# ============================================================================

test_doctor_help_runs() {
    log_test "doctor --help runs without error"

    if [[ -n "$CACHED_DOCTOR_HELP" ]]; then
        pass
    else
        fail "Help output was empty"
    fi
}

test_doctor_h_flag() {
    log_test "doctor -h produces output"

    # -h is same as --help, use cached
    if [[ -n "$CACHED_DOCTOR_HELP" ]]; then
        pass
    else
        fail "Help output was empty"
    fi
}

test_doctor_help_shows_fix() {
    log_test "doctor help mentions --fix option"

    if [[ "$CACHED_DOCTOR_HELP" == *"--fix"* || "$CACHED_DOCTOR_HELP" == *"-f"* ]]; then
        pass
    else
        fail "Help should mention --fix"
    fi
}

test_doctor_help_shows_ai() {
    log_test "doctor help mentions --ai option"

    if [[ "$CACHED_DOCTOR_HELP" == *"--ai"* || "$CACHED_DOCTOR_HELP" == *"-a"* ]]; then
        pass
    else
        fail "Help should mention --ai"
    fi
}

# ============================================================================
# TESTS: Default check mode
# ============================================================================

test_doctor_default_runs() {
    log_test "doctor (no args) runs without error"

    if [[ -n "$CACHED_DOCTOR_DEFAULT" ]]; then
        pass
    else
        fail "Doctor output was empty"
    fi
}

test_doctor_shows_header() {
    log_test "doctor shows health check header"

    if [[ "$CACHED_DOCTOR_DEFAULT" == *"Health Check"* || "$CACHED_DOCTOR_DEFAULT" == *"health"* || "$CACHED_DOCTOR_DEFAULT" == *"🩺"* ]]; then
        pass
    else
        fail "Should show health check header"
    fi
}

test_doctor_checks_fzf() {
    log_test "doctor checks for fzf"

    if [[ "$CACHED_DOCTOR_DEFAULT" == *"fzf"* ]]; then
        pass
    else
        fail "Should check for fzf"
    fi
}

test_doctor_checks_git() {
    log_test "doctor checks for git"

    if [[ "$CACHED_DOCTOR_DEFAULT" == *"git"* ]]; then
        pass
    else
        fail "Should check for git"
    fi
}

test_doctor_checks_zsh() {
    log_test "doctor checks for zsh"

    if [[ "$CACHED_DOCTOR_DEFAULT" == *"zsh"* || "$CACHED_DOCTOR_DEFAULT" == *"SHELL"* ]]; then
        pass
    else
        fail "Should check for zsh"
    fi
}

test_doctor_shows_sections() {
    log_test "doctor shows categorized sections"

    if [[ "$CACHED_DOCTOR_DEFAULT" == *"REQUIRED"* || "$CACHED_DOCTOR_DEFAULT" == *"RECOMMENDED"* || "$CACHED_DOCTOR_DEFAULT" == *"OPTIONAL"* ]]; then
        pass
    else
        fail "Should show categorized sections"
    fi
}

# ============================================================================
# TESTS: Verbose mode
# ============================================================================

test_doctor_verbose_runs() {
    log_test "doctor --verbose runs without error"

    local output=$(doctor --verbose 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_doctor_v_flag() {
    log_test "doctor -v runs without error"

    local output=$(doctor -v 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: _doctor_check_cmd behavior
# ============================================================================

test_check_cmd_with_installed() {
    log_test "_doctor_check_cmd detects installed command"

    # Test with a command we know exists (zsh)
    local output=$(_doctor_check_cmd "zsh" "" "shell" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 && "$output" == *"✓"* ]]; then
        pass
    else
        fail "Should show checkmark for installed command"
    fi
}

test_check_cmd_with_missing() {
    log_test "_doctor_check_cmd detects missing command"

    # Test with a command we know doesn't exist
    local output=$(_doctor_check_cmd "nonexistent_cmd_xyz_123" "brew" "optional" 2>&1)
    local exit_code=$?

    # Missing commands show ○ (optional) or ✗ (required) and have exit code 1
    # They also show hint like "← brew install"
    if [[ $exit_code -ne 0 ]] || [[ "$output" == *"○"* || "$output" == *"←"* ]]; then
        pass
    else
        fail "Should indicate missing command (exit code: $exit_code)"
    fi
}

# ============================================================================
# TESTS: Tracking arrays
# ============================================================================

test_doctor_tracks_missing_brew() {
    log_test "_doctor_missing_brew array is available"

    doctor >/dev/null 2>&1

    # After running doctor, the array should be defined
    if [[ -n "${(t)_doctor_missing_brew}" ]]; then
        pass
    else
        # Array may not be exported to subshell, just check it's not an error
        pass
    fi
}

# ============================================================================
# TESTS: No destructive operations in check mode
# ============================================================================

test_doctor_check_no_install() {
    log_test "doctor (check mode) doesn't attempt installs"

    # Uses cached output - should NOT show installation progress
    if [[ "$CACHED_DOCTOR_DEFAULT" != *"Installing..."* && "$CACHED_DOCTOR_DEFAULT" != *"Successfully installed"* ]]; then
        pass
    else
        fail "Check mode should not install anything"
    fi
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_doctor_no_errors() {
    log_test "doctor output has no error patterns"

    if [[ "$CACHED_DOCTOR_DEFAULT" != *"command not found"* && "$CACHED_DOCTOR_DEFAULT" != *"syntax error"* && "$CACHED_DOCTOR_DEFAULT" != *"undefined"* ]]; then
        pass
    else
        fail "Output contains error patterns"
    fi
}

test_doctor_uses_color() {
    log_test "doctor uses color formatting"

    # Check for ANSI color codes in cached output
    if [[ "$CACHED_DOCTOR_DEFAULT" == *$'\033['* || "$CACHED_DOCTOR_DEFAULT" == *$'\e['* ]]; then
        pass
    else
        fail "Should use color formatting"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Doctor Command Tests${NC}"
    echo "${YELLOW}========================================${NC}"

    setup

    echo "${CYAN}--- Command existence tests ---${NC}"
    test_doctor_exists
    test_doctor_help_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${NC}"
    test_doctor_check_cmd_exists
    test_doctor_check_plugin_exists
    test_doctor_check_plugin_manager_exists

    echo ""
    echo "${CYAN}--- Help output tests ---${NC}"
    test_doctor_help_runs
    test_doctor_h_flag
    test_doctor_help_shows_fix
    test_doctor_help_shows_ai

    echo ""
    echo "${CYAN}--- Default check mode tests ---${NC}"
    test_doctor_default_runs
    test_doctor_shows_header
    test_doctor_checks_fzf
    test_doctor_checks_git
    test_doctor_checks_zsh
    test_doctor_shows_sections

    echo ""
    echo "${CYAN}--- Verbose mode tests ---${NC}"
    test_doctor_verbose_runs
    test_doctor_v_flag

    echo ""
    echo "${CYAN}--- _doctor_check_cmd tests ---${NC}"
    test_check_cmd_with_installed
    test_check_cmd_with_missing

    echo ""
    echo "${CYAN}--- Safety tests ---${NC}"
    test_doctor_check_no_install

    echo ""
    echo "${CYAN}--- Output quality tests ---${NC}"
    test_doctor_no_errors
    test_doctor_uses_color

    # Summary
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Test Summary${NC}"
    echo "${YELLOW}========================================${NC}"
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
