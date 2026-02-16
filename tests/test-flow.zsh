#!/usr/bin/env zsh
# Test script for flow command (main dispatcher)
# Tests: flow help, flow version, subcommand routing
# Generated: 2025-12-31

# ============================================================================
# SETUP
# ============================================================================

# Resolve project root at top level (${0:A} doesn't work inside functions)
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

setup() {
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
    trap "rm -rf '$TEST_ROOT'" EXIT
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app; do
        echo "## Status: active\n## Progress: 50" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    echo ""
}

cleanup() {
    reset_mocks
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_flow_exists() {
    test_case "flow command exists and responds"

    if type flow &>/dev/null; then
        local output=$(flow --help 2>&1 || true)
        assert_not_contains "$output" "command not found" && test_pass
    else
        test_fail "flow command not found"
    fi
}

test_flow_help_exists() {
    test_case "_flow_help function exists"

    if type _flow_help &>/dev/null; then
        test_pass
    else
        test_fail "_flow_help not found"
    fi
}

# ============================================================================
# TESTS: Help system
# ============================================================================

test_flow_help_runs() {
    test_case "flow help runs without error"

    local output=$(flow help 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 || return 1
    assert_not_contains "$output" "command not found" || return 1
    test_pass
}

test_flow_no_args_shows_help() {
    test_case "flow (no args) shows help"

    local output=$(flow 2>&1)

    if [[ "$output" == *"FLOW"* || "$output" == *"Usage"* ]]; then
        test_pass
    else
        test_fail "Should show help when called without args"
    fi
}

test_flow_help_flag() {
    test_case "flow --help runs"

    local output=$(flow --help 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 || return 1
    assert_not_contains "$output" "command not found" || return 1
    test_pass
}

test_flow_h_flag() {
    test_case "flow -h runs"

    local output=$(flow -h 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 || return 1
    assert_not_contains "$output" "command not found" || return 1
    test_pass
}

test_flow_help_shows_commands() {
    test_case "flow help shows available commands"

    local output=$(flow help 2>&1)

    if [[ "$output" == *"work"* && "$output" == *"pick"* && "$output" == *"dash"* ]]; then
        test_pass
    else
        test_fail "Help should list main commands"
    fi
}

test_flow_help_list_flag() {
    test_case "flow help --list runs"

    local output=$(flow help --list 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 || return 1
    assert_not_contains "$output" "command not found" || return 1
    test_pass
}

# ============================================================================
# TESTS: Version
# ============================================================================

test_flow_version_runs() {
    test_case "flow version runs"

    local output=$(flow version 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 || return 1
    assert_not_contains "$output" "command not found" || return 1
    test_pass
}

test_flow_version_shows_version() {
    test_case "flow version shows version number"

    local output=$(flow version 2>&1)

    if [[ "$output" == *"flow-cli"* && "$output" == *"v"* ]]; then
        test_pass
    else
        test_fail "Should show version like 'flow-cli vX.X.X'"
    fi
}

test_flow_version_flag() {
    test_case "flow --version runs"

    local output=$(flow --version 2>&1)

    if [[ "$output" == *"flow-cli"* ]]; then
        test_pass
    else
        test_fail "Should show version"
    fi
}

test_flow_v_flag() {
    test_case "flow -v runs"

    local output=$(flow -v 2>&1)

    if [[ "$output" == *"flow-cli"* ]]; then
        test_pass
    else
        test_fail "Should show version"
    fi
}

# ============================================================================
# TESTS: Subcommand routing
# ============================================================================

test_flow_work_routes() {
    test_case "flow work routes to work command"

    # Check that it routes (work may error without project, but that's ok)
    local output=$(flow work nonexistent_project 2>&1)

    # Should either work or show work's error
    if [[ "$output" == *"not found"* || "$output" == *"Project"* || "$output" != *"Unknown command"* ]]; then
        test_pass
    else
        test_fail "Should route to work command"
    fi
}

test_flow_dash_routes() {
    test_case "flow dash routes to dash command"

    local output=$(flow dash 2>&1)

    if [[ "$output" == *"DASHBOARD"* || "$output" == *"━"* ]]; then
        test_pass
    else
        test_fail "Should route to dash command"
    fi
}

test_flow_doctor_routes() {
    test_case "flow doctor routes to doctor command"

    local output=$(flow doctor 2>&1)

    if [[ "$output" == *"Health"* || "$output" == *"health"* || "$output" == *"🩺"* ]]; then
        test_pass
    else
        test_fail "Should route to doctor command"
    fi
}

test_flow_js_routes() {
    test_case "flow js routes to js command"

    local output=$(flow js 2>&1)

    if [[ "$output" == *"JUST START"* || "$output" == *"🚀"* ]]; then
        test_pass
    else
        test_fail "Should route to js command"
    fi
}

test_flow_start_routes() {
    test_case "flow start routes to js command"

    local output=$(flow start 2>&1)

    if [[ "$output" == *"JUST START"* || "$output" == *"🚀"* ]]; then
        test_pass
    else
        test_fail "Should route to js command"
    fi
}

test_flow_next_routes() {
    test_case "flow next routes to next command"

    local output=$(flow next 2>&1)

    if [[ "$output" == *"NEXT"* || "$output" == *"🎯"* ]]; then
        test_pass
    else
        test_fail "Should route to next command"
    fi
}

test_flow_stuck_routes() {
    test_case "flow stuck routes to stuck command"

    local output=$(flow stuck 2>&1)

    if [[ "$output" == *"STUCK"* || "$output" == *"🤔"* || "$output" == *"block"* ]]; then
        test_pass
    else
        test_fail "Should route to stuck command"
    fi
}

# ============================================================================
# TESTS: Unknown command handling
# ============================================================================

test_flow_unknown_command() {
    test_case "flow handles unknown command"

    local output=$(flow unknownxyz123 2>&1)
    local exit_code=$?

    # Check for "Unknown command" message (exit code may vary in subshell)
    if [[ "$output" == *"Unknown command"* || "$output" == *"unknown"* ]]; then
        test_pass
    else
        test_fail "Should show 'Unknown command' message"
    fi
}

test_flow_unknown_suggests_help() {
    test_case "flow unknown command suggests help"

    local output=$(flow unknownxyz123 2>&1)

    if [[ "$output" == *"flow help"* ]]; then
        test_pass
    else
        test_fail "Should suggest 'flow help'"
    fi
}

# ============================================================================
# TESTS: Aliases
# ============================================================================

test_flow_pick_alias() {
    test_case "flow pp routes to pick"

    # pp should be aliased to pick
    local output=$(flow pp help 2>&1)

    # Should route to pick help
    if [[ "$output" == *"pick"* || "$output" == *"PICK"* ]]; then
        test_pass
    else
        test_fail "Should route pp to pick"
    fi
}

test_flow_dashboard_alias() {
    test_case "flow dashboard routes to dash"

    local output=$(flow dashboard 2>&1)

    if [[ "$output" == *"DASHBOARD"* || "$output" == *"━"* ]]; then
        test_pass
    else
        test_fail "Should route dashboard to dash"
    fi
}

test_flow_finish_aliases() {
    test_case "flow fin routes to finish"

    local output=$(flow fin 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 || return 1
    test_pass
}

test_flow_health_alias() {
    test_case "flow health routes to doctor"

    local output=$(flow health 2>&1)

    if [[ "$output" == *"Health"* || "$output" == *"health"* || "$output" == *"🩺"* ]]; then
        test_pass
    else
        test_fail "Should route health to doctor"
    fi
}

# ============================================================================
# TESTS: Context-aware actions
# ============================================================================

test_flow_test_exists() {
    test_case "flow test subcommand exists"

    local output=$(flow test --help 2>&1)
    local exit_code=$?

    # Should either show help or run (not "Unknown command")
    if [[ "$output" != *"Unknown command"* ]]; then
        test_pass
    else
        test_fail "flow test should be recognized"
    fi
}

test_flow_build_exists() {
    test_case "flow build subcommand exists"

    local output=$(flow build --help 2>&1)
    local exit_code=$?

    if [[ "$output" != *"Unknown command"* ]]; then
        test_pass
    else
        test_fail "flow build should be recognized"
    fi
}

test_flow_sync_exists() {
    test_case "flow sync subcommand exists"

    local output=$(flow sync 2>&1)
    local exit_code=$?

    assert_not_contains "$output" "command not found" || return 1
    if [[ "$output" != *"Unknown command"* ]]; then
        test_pass
    else
        test_fail "flow sync should be recognized"
    fi
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_flow_help_no_errors() {
    test_case "flow help has no error patterns"

    local output=$(flow help 2>&1)

    if [[ "$output" != *"command not found"* && "$output" != *"syntax error"* ]]; then
        test_pass
    else
        test_fail "Output contains error patterns"
    fi
}

test_flow_uses_colors() {
    test_case "flow help uses color formatting"

    local output=$(flow help 2>&1)

    # Check for ANSI color codes
    if [[ "$output" == *$'\033['* || "$output" == *$'\e['* ]]; then
        test_pass
    else
        test_fail "Should use color formatting"
    fi
}

# ============================================================================
# TESTS: FLOW_VERSION variable
# ============================================================================

test_flow_version_var_defined() {
    test_case "FLOW_VERSION variable is defined"

    if [[ -n "$FLOW_VERSION" ]]; then
        test_pass
    else
        test_fail "FLOW_VERSION not defined"
    fi
}

test_flow_version_format() {
    test_case "FLOW_VERSION follows semver format"

    if [[ "$FLOW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        test_pass
    else
        test_fail "Should be like X.Y.Z, got: $FLOW_VERSION"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Flow Command Tests"

    setup

    echo "${CYAN}--- Command existence tests ---${RESET}"
    test_flow_exists
    test_flow_help_exists

    echo ""
    echo "${CYAN}--- Help system tests ---${RESET}"
    test_flow_help_runs
    test_flow_no_args_shows_help
    test_flow_help_flag
    test_flow_h_flag
    test_flow_help_shows_commands
    test_flow_help_list_flag

    echo ""
    echo "${CYAN}--- Version tests ---${RESET}"
    test_flow_version_runs
    test_flow_version_shows_version
    test_flow_version_flag
    test_flow_v_flag

    echo ""
    echo "${CYAN}--- Subcommand routing tests ---${RESET}"
    test_flow_work_routes
    test_flow_dash_routes
    test_flow_doctor_routes
    test_flow_js_routes
    test_flow_start_routes
    test_flow_next_routes
    test_flow_stuck_routes

    echo ""
    echo "${CYAN}--- Unknown command tests ---${RESET}"
    test_flow_unknown_command
    test_flow_unknown_suggests_help

    echo ""
    echo "${CYAN}--- Alias tests ---${RESET}"
    test_flow_pick_alias
    test_flow_dashboard_alias
    test_flow_finish_aliases
    test_flow_health_alias

    echo ""
    echo "${CYAN}--- Context-aware action tests ---${RESET}"
    test_flow_test_exists
    test_flow_build_exists
    test_flow_sync_exists

    echo ""
    echo "${CYAN}--- Output quality tests ---${RESET}"
    test_flow_help_no_errors
    test_flow_uses_colors

    echo ""
    echo "${CYAN}--- Version variable tests ---${RESET}"
    test_flow_version_var_defined
    test_flow_version_format

    cleanup
    test_suite_end
    exit $?
}

main "$@"
