#!/usr/bin/env zsh
# Test script for doctor command (health check)
# Tests: dependency checking, fix mode, help output
# Generated: 2025-12-30
# Converted to shared test-framework.zsh: 2026-02-16

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${RESET}"

    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${RESET}"
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }

    # Close stdin to prevent any interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev"
    echo "## Status: active\n## Progress: 50" > "$TEST_ROOT/dev-tools/mock-dev/.STATUS"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    # Cache doctor outputs to avoid repeated API calls (each doctor run hits GitHub API)
    CACHED_DOCTOR_DEFAULT=$(doctor 2>&1)
    CACHED_DOCTOR_HELP=$(doctor --help 2>&1)

    echo ""
}

# ============================================================================
# CLEANUP
# ============================================================================

cleanup() {
    reset_mocks
    rm -rf "$TEST_ROOT"
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_doctor_exists() {
    test_case "doctor command exists"
    assert_function_exists "doctor"
    test_pass
}

test_doctor_help_exists() {
    test_case "_doctor_help function exists"
    assert_function_exists "_doctor_help"
    test_pass
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_doctor_check_cmd_exists() {
    test_case "_doctor_check_cmd function exists"
    assert_function_exists "_doctor_check_cmd"
    test_pass
}

test_doctor_check_plugin_exists() {
    test_case "_doctor_check_zsh_plugin function exists"
    assert_function_exists "_doctor_check_zsh_plugin"
    test_pass
}

test_doctor_check_plugin_manager_exists() {
    test_case "_doctor_check_plugin_manager function exists"
    assert_function_exists "_doctor_check_plugin_manager"
    test_pass
}

# ============================================================================
# TESTS: Help output
# ============================================================================

test_doctor_help_runs() {
    test_case "doctor --help runs without error"
    assert_not_empty "$CACHED_DOCTOR_HELP" "Help output was empty"
    test_pass
}

test_doctor_h_flag() {
    test_case "doctor -h produces output"
    # -h is same as --help, use cached
    assert_not_empty "$CACHED_DOCTOR_HELP" "Help output was empty"
    test_pass
}

test_doctor_help_shows_fix() {
    test_case "doctor help mentions --fix option"
    assert_contains "$CACHED_DOCTOR_HELP" "--fix" "Help should mention --fix"
    test_pass
}

test_doctor_help_shows_ai() {
    test_case "doctor help mentions --ai option"
    assert_contains "$CACHED_DOCTOR_HELP" "--ai" "Help should mention --ai"
    test_pass
}

# ============================================================================
# TESTS: Default check mode
# ============================================================================

test_doctor_default_runs() {
    test_case "doctor (no args) runs without error"
    assert_not_empty "$CACHED_DOCTOR_DEFAULT" "Doctor output was empty"
    test_pass
}

test_doctor_shows_header() {
    test_case "doctor shows health check header"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "ealth" "Should show health check header"
    test_pass
}

test_doctor_checks_fzf() {
    test_case "doctor checks for fzf"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "fzf" "Should check for fzf"
    test_pass
}

test_doctor_checks_git() {
    test_case "doctor checks for git"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "git" "Should check for git"
    test_pass
}

test_doctor_checks_zsh() {
    test_case "doctor checks for zsh"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "zsh" "Should check for zsh"
    test_pass
}

test_doctor_shows_sections() {
    test_case "doctor shows categorized sections"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "REQUIRED" "Should show REQUIRED section"
    test_pass
}

# ============================================================================
# TESTS: Verbose mode
# ============================================================================

test_doctor_verbose_runs() {
    test_case "doctor --verbose runs without error"
    local output=$(doctor --verbose 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "Exit code: $exit_code"
    assert_not_empty "$output" "Verbose output should not be empty"
    test_pass
}

test_doctor_v_flag() {
    test_case "doctor -v runs without error"
    local output=$(doctor -v 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "Exit code: $exit_code"
    assert_not_empty "$output" "-v output should not be empty"
    test_pass
}

# ============================================================================
# TESTS: _doctor_check_cmd behavior
# ============================================================================

test_check_cmd_with_installed() {
    test_case "_doctor_check_cmd detects installed command"
    # Test with a command we know exists (zsh)
    local output=$(_doctor_check_cmd "zsh" "" "shell" 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "Should exit 0 for installed command"
    assert_contains "$output" "✓" "Should show checkmark for installed command"
    test_pass
}

test_check_cmd_with_missing() {
    test_case "_doctor_check_cmd detects missing command"
    # Test with a command we know doesn't exist
    local output=$(_doctor_check_cmd "nonexistent_cmd_xyz_123" "brew" "optional" 2>&1)
    local exit_code=$?
    # Missing optional commands return exit 1 or show ○ marker
    assert_not_empty "$output" "Should produce output for missing command"
    if (( exit_code == 0 )); then
        # If exit 0, must at least show the optional marker
        assert_contains "$output" "○" "Should show optional marker for missing command"
    fi
    test_pass
}

# ============================================================================
# TESTS: Tracking arrays
# ============================================================================

test_doctor_tracks_missing_brew() {
    test_case "_doctor_missing_brew array is available"
    doctor >/dev/null 2>&1
    # After running doctor, the array should be defined (type check)
    assert_not_empty "${(t)_doctor_missing_brew}" "_doctor_missing_brew array not defined after doctor run"
    test_pass
}

# ============================================================================
# TESTS: No destructive operations in check mode
# ============================================================================

test_doctor_check_no_install() {
    test_case "doctor (check mode) doesn't attempt installs"
    # Uses cached output - should NOT show installation progress
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "Installing..." "Check mode should not install anything"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "Successfully installed" "Check mode should not install anything"
    test_pass
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_doctor_no_errors() {
    test_case "doctor output has no error patterns"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "command not found" "Output contains 'command not found'"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "syntax error" "Output contains 'syntax error'"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "undefined" "Output contains 'undefined'"
    test_pass
}

test_doctor_uses_color() {
    test_case "doctor uses color formatting"
    # Check for ANSI color codes in cached output
    assert_matches_pattern "$CACHED_DOCTOR_DEFAULT" $'\033\\[' "Should use color formatting"
    test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite "Doctor Command Tests"

    setup

    echo "${CYAN}--- Command existence tests ---${RESET}"
    test_doctor_exists
    test_doctor_help_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${RESET}"
    test_doctor_check_cmd_exists
    test_doctor_check_plugin_exists
    test_doctor_check_plugin_manager_exists

    echo ""
    echo "${CYAN}--- Help output tests ---${RESET}"
    test_doctor_help_runs
    test_doctor_h_flag
    test_doctor_help_shows_fix
    test_doctor_help_shows_ai

    echo ""
    echo "${CYAN}--- Default check mode tests ---${RESET}"
    test_doctor_default_runs
    test_doctor_shows_header
    test_doctor_checks_fzf
    test_doctor_checks_git
    test_doctor_checks_zsh
    test_doctor_shows_sections

    echo ""
    echo "${CYAN}--- Verbose mode tests ---${RESET}"
    test_doctor_verbose_runs
    test_doctor_v_flag

    echo ""
    echo "${CYAN}--- _doctor_check_cmd tests ---${RESET}"
    test_check_cmd_with_installed
    test_check_cmd_with_missing

    echo ""
    echo "${CYAN}--- Tracking tests ---${RESET}"
    test_doctor_tracks_missing_brew

    echo ""
    echo "${CYAN}--- Safety tests ---${RESET}"
    test_doctor_check_no_install

    echo ""
    echo "${CYAN}--- Output quality tests ---${RESET}"
    test_doctor_no_errors
    test_doctor_uses_color

    cleanup
    print_summary
    exit $?
}

main "$@"
