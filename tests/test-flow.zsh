#!/usr/bin/env zsh
# Test script for flow command (main dispatcher)
# Tests: flow help, flow version, subcommand routing
# Generated: 2025-12-31

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
    if [[ -z "$project_root" || ! -f "$project_root/commands/flow.zsh" ]]; then
        if [[ -f "$PWD/commands/flow.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/flow.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi
    if [[ -z "$project_root" || ! -f "$project_root/commands/flow.zsh" ]]; then
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

test_flow_exists() {
    log_test "flow command exists"

    if type flow &>/dev/null; then
        pass
    else
        fail "flow command not found"
    fi
}

test_flow_help_exists() {
    log_test "_flow_help function exists"

    if type _flow_help &>/dev/null; then
        pass
    else
        fail "_flow_help not found"
    fi
}

# ============================================================================
# TESTS: Help system
# ============================================================================

test_flow_help_runs() {
    log_test "flow help runs without error"

    local output=$(flow help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_flow_no_args_shows_help() {
    log_test "flow (no args) shows help"

    local output=$(flow 2>&1)

    if [[ "$output" == *"FLOW"* || "$output" == *"Usage"* ]]; then
        pass
    else
        fail "Should show help when called without args"
    fi
}

test_flow_help_flag() {
    log_test "flow --help runs"

    local output=$(flow --help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_flow_h_flag() {
    log_test "flow -h runs"

    local output=$(flow -h 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_flow_help_shows_commands() {
    log_test "flow help shows available commands"

    local output=$(flow help 2>&1)

    if [[ "$output" == *"work"* && "$output" == *"pick"* && "$output" == *"dash"* ]]; then
        pass
    else
        fail "Help should list main commands"
    fi
}

test_flow_help_list_flag() {
    log_test "flow help --list runs"

    local output=$(flow help --list 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: Version
# ============================================================================

test_flow_version_runs() {
    log_test "flow version runs"

    local output=$(flow version 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_flow_version_shows_version() {
    log_test "flow version shows version number"

    local output=$(flow version 2>&1)

    if [[ "$output" == *"flow-cli"* && "$output" == *"v"* ]]; then
        pass
    else
        fail "Should show version like 'flow-cli vX.X.X'"
    fi
}

test_flow_version_flag() {
    log_test "flow --version runs"

    local output=$(flow --version 2>&1)

    if [[ "$output" == *"flow-cli"* ]]; then
        pass
    else
        fail "Should show version"
    fi
}

test_flow_v_flag() {
    log_test "flow -v runs"

    local output=$(flow -v 2>&1)

    if [[ "$output" == *"flow-cli"* ]]; then
        pass
    else
        fail "Should show version"
    fi
}

# ============================================================================
# TESTS: Subcommand routing
# ============================================================================

test_flow_work_routes() {
    log_test "flow work routes to work command"

    # Check that it routes (work may error without project, but that's ok)
    local output=$(flow work nonexistent_project 2>&1)

    # Should either work or show work's error
    if [[ "$output" == *"not found"* || "$output" == *"Project"* || "$output" != *"Unknown command"* ]]; then
        pass
    else
        fail "Should route to work command"
    fi
}

test_flow_dash_routes() {
    log_test "flow dash routes to dash command"

    local output=$(flow dash 2>&1)

    if [[ "$output" == *"DASHBOARD"* || "$output" == *"━"* ]]; then
        pass
    else
        fail "Should route to dash command"
    fi
}

test_flow_doctor_routes() {
    log_test "flow doctor routes to doctor command"

    local output=$(flow doctor 2>&1)

    if [[ "$output" == *"Health"* || "$output" == *"health"* || "$output" == *"🩺"* ]]; then
        pass
    else
        fail "Should route to doctor command"
    fi
}

test_flow_js_routes() {
    log_test "flow js routes to js command"

    local output=$(flow js 2>&1)

    if [[ "$output" == *"JUST START"* || "$output" == *"🚀"* ]]; then
        pass
    else
        fail "Should route to js command"
    fi
}

test_flow_start_routes() {
    log_test "flow start routes to js command"

    local output=$(flow start 2>&1)

    if [[ "$output" == *"JUST START"* || "$output" == *"🚀"* ]]; then
        pass
    else
        fail "Should route to js command"
    fi
}

test_flow_next_routes() {
    log_test "flow next routes to next command"

    local output=$(flow next 2>&1)

    if [[ "$output" == *"NEXT"* || "$output" == *"🎯"* ]]; then
        pass
    else
        fail "Should route to next command"
    fi
}

test_flow_stuck_routes() {
    log_test "flow stuck routes to stuck command"

    local output=$(flow stuck 2>&1)

    if [[ "$output" == *"STUCK"* || "$output" == *"🤔"* || "$output" == *"block"* ]]; then
        pass
    else
        fail "Should route to stuck command"
    fi
}

# ============================================================================
# TESTS: Unknown command handling
# ============================================================================

test_flow_unknown_command() {
    log_test "flow handles unknown command"

    local output=$(flow unknownxyz123 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 1 && "$output" == *"Unknown command"* ]]; then
        pass
    else
        fail "Should show 'Unknown command' and exit 1"
    fi
}

test_flow_unknown_suggests_help() {
    log_test "flow unknown command suggests help"

    local output=$(flow unknownxyz123 2>&1)

    if [[ "$output" == *"flow help"* ]]; then
        pass
    else
        fail "Should suggest 'flow help'"
    fi
}

# ============================================================================
# TESTS: Aliases
# ============================================================================

test_flow_pick_alias() {
    log_test "flow pp routes to pick"

    # pp should be aliased to pick
    local output=$(flow pp help 2>&1)

    # Should route to pick help
    if [[ "$output" == *"pick"* || "$output" == *"PICK"* ]]; then
        pass
    else
        fail "Should route pp to pick"
    fi
}

test_flow_dashboard_alias() {
    log_test "flow dashboard routes to dash"

    local output=$(flow dashboard 2>&1)

    if [[ "$output" == *"DASHBOARD"* || "$output" == *"━"* ]]; then
        pass
    else
        fail "Should route dashboard to dash"
    fi
}

test_flow_finish_aliases() {
    log_test "flow fin routes to finish"

    local output=$(flow fin 2>&1)
    local exit_code=$?

    # Should route to finish (may succeed or fail based on state, that's ok)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

test_flow_health_alias() {
    log_test "flow health routes to doctor"

    local output=$(flow health 2>&1)

    if [[ "$output" == *"Health"* || "$output" == *"health"* || "$output" == *"🩺"* ]]; then
        pass
    else
        fail "Should route health to doctor"
    fi
}

# ============================================================================
# TESTS: Context-aware actions
# ============================================================================

test_flow_test_exists() {
    log_test "flow test subcommand exists"

    local output=$(flow test --help 2>&1)
    local exit_code=$?

    # Should either show help or run (not "Unknown command")
    if [[ "$output" != *"Unknown command"* ]]; then
        pass
    else
        fail "flow test should be recognized"
    fi
}

test_flow_build_exists() {
    log_test "flow build subcommand exists"

    local output=$(flow build --help 2>&1)
    local exit_code=$?

    if [[ "$output" != *"Unknown command"* ]]; then
        pass
    else
        fail "flow build should be recognized"
    fi
}

test_flow_sync_exists() {
    log_test "flow sync subcommand exists"

    local output=$(flow sync 2>&1)
    local exit_code=$?

    if [[ "$output" != *"Unknown command"* ]]; then
        pass
    else
        fail "flow sync should be recognized"
    fi
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_flow_help_no_errors() {
    log_test "flow help has no error patterns"

    local output=$(flow help 2>&1)

    if [[ "$output" != *"command not found"* && "$output" != *"syntax error"* ]]; then
        pass
    else
        fail "Output contains error patterns"
    fi
}

test_flow_uses_colors() {
    log_test "flow help uses color formatting"

    local output=$(flow help 2>&1)

    # Check for ANSI color codes
    if [[ "$output" == *$'\033['* || "$output" == *$'\e['* ]]; then
        pass
    else
        fail "Should use color formatting"
    fi
}

# ============================================================================
# TESTS: FLOW_VERSION variable
# ============================================================================

test_flow_version_var_defined() {
    log_test "FLOW_VERSION variable is defined"

    if [[ -n "$FLOW_VERSION" ]]; then
        pass
    else
        fail "FLOW_VERSION not defined"
    fi
}

test_flow_version_format() {
    log_test "FLOW_VERSION follows semver format"

    if [[ "$FLOW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        pass
    else
        fail "Should be like X.Y.Z, got: $FLOW_VERSION"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Flow Command Tests${NC}"
    echo "${YELLOW}========================================${NC}"

    setup

    echo "${CYAN}--- Command existence tests ---${NC}"
    test_flow_exists
    test_flow_help_exists

    echo ""
    echo "${CYAN}--- Help system tests ---${NC}"
    test_flow_help_runs
    test_flow_no_args_shows_help
    test_flow_help_flag
    test_flow_h_flag
    test_flow_help_shows_commands
    test_flow_help_list_flag

    echo ""
    echo "${CYAN}--- Version tests ---${NC}"
    test_flow_version_runs
    test_flow_version_shows_version
    test_flow_version_flag
    test_flow_v_flag

    echo ""
    echo "${CYAN}--- Subcommand routing tests ---${NC}"
    test_flow_work_routes
    test_flow_dash_routes
    test_flow_doctor_routes
    test_flow_js_routes
    test_flow_start_routes
    test_flow_next_routes
    test_flow_stuck_routes

    echo ""
    echo "${CYAN}--- Unknown command tests ---${NC}"
    test_flow_unknown_command
    test_flow_unknown_suggests_help

    echo ""
    echo "${CYAN}--- Alias tests ---${NC}"
    test_flow_pick_alias
    test_flow_dashboard_alias
    test_flow_finish_aliases
    test_flow_health_alias

    echo ""
    echo "${CYAN}--- Context-aware action tests ---${NC}"
    test_flow_test_exists
    test_flow_build_exists
    test_flow_sync_exists

    echo ""
    echo "${CYAN}--- Output quality tests ---${NC}"
    test_flow_help_no_errors
    test_flow_uses_colors

    echo ""
    echo "${CYAN}--- Version variable tests ---${NC}"
    test_flow_version_var_defined
    test_flow_version_format

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
