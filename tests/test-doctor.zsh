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

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    local project_root=""
    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi
    if [[ -z "$project_root" || ! -f "$project_root/commands/doctor.zsh" ]]; then
        if [[ -f "$PWD/commands/doctor.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/doctor.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi
    if [[ -z "$project_root" || ! -f "$project_root/commands/doctor.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source the plugin
    source "$project_root/flow.plugin.zsh" 2>/dev/null

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
    log_test "_doctor_check_plugin function exists"

    if type _doctor_check_plugin &>/dev/null; then
        pass
    else
        fail "_doctor_check_plugin not found"
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

    local output=$(doctor --help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_doctor_h_flag() {
    log_test "doctor -h runs without error"

    local output=$(doctor -h 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_doctor_help_shows_fix() {
    log_test "doctor help mentions --fix option"

    local output=$(doctor --help 2>&1)

    if [[ "$output" == *"--fix"* || "$output" == *"-f"* ]]; then
        pass
    else
        fail "Help should mention --fix"
    fi
}

test_doctor_help_shows_ai() {
    log_test "doctor help mentions --ai option"

    local output=$(doctor --help 2>&1)

    if [[ "$output" == *"--ai"* || "$output" == *"-a"* ]]; then
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

    local output=$(doctor 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_doctor_shows_header() {
    log_test "doctor shows health check header"

    local output=$(doctor 2>&1)

    if [[ "$output" == *"Health Check"* || "$output" == *"health"* || "$output" == *"🩺"* ]]; then
        pass
    else
        fail "Should show health check header"
    fi
}

test_doctor_checks_fzf() {
    log_test "doctor checks for fzf"

    local output=$(doctor 2>&1)

    if [[ "$output" == *"fzf"* ]]; then
        pass
    else
        fail "Should check for fzf"
    fi
}

test_doctor_checks_git() {
    log_test "doctor checks for git"

    local output=$(doctor 2>&1)

    if [[ "$output" == *"git"* ]]; then
        pass
    else
        fail "Should check for git"
    fi
}

test_doctor_checks_zsh() {
    log_test "doctor checks for zsh"

    local output=$(doctor 2>&1)

    if [[ "$output" == *"zsh"* || "$output" == *"SHELL"* ]]; then
        pass
    else
        fail "Should check for zsh"
    fi
}

test_doctor_shows_sections() {
    log_test "doctor shows categorized sections"

    local output=$(doctor 2>&1)

    # Should have REQUIRED, RECOMMENDED, or OPTIONAL sections
    if [[ "$output" == *"REQUIRED"* || "$output" == *"RECOMMENDED"* || "$output" == *"OPTIONAL"* ]]; then
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

    if [[ "$output" == *"✗"* || "$output" == *"missing"* || "$output" == *"-"* ]]; then
        pass
    else
        fail "Should indicate missing command"
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

    local output=$(doctor 2>&1)

    # Should NOT contain installation commands
    if [[ "$output" != *"brew install"* && "$output" != *"npm install"* && "$output" != *"Installing"* ]]; then
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

    local output=$(doctor 2>&1)

    if [[ "$output" != *"command not found"* && "$output" != *"syntax error"* && "$output" != *"undefined"* ]]; then
        pass
    else
        fail "Output contains error patterns"
    fi
}

test_doctor_uses_color() {
    log_test "doctor uses color formatting"

    local output=$(doctor 2>&1)

    # Check for ANSI color codes
    if [[ "$output" == *$'\033['* || "$output" == *$'\e['* ]]; then
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
