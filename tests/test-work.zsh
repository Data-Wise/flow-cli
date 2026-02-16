#!/usr/bin/env zsh
# Test script for work command and session management
# Tests: work, finish, hop, session tracking, context display, project detection
# Rewritten: 2026-02-16 (behavioral assertions via test-framework.zsh)

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh" || {
    echo "ERROR: Cannot source test-framework.zsh"
    exit 1
}

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find project root (expected flow.plugin.zsh at $PROJECT_ROOT)"
        exit 1
    fi

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "ERROR: Plugin failed to load"
        exit 1
    }

    # Close stdin to prevent interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app; do
        printf "## Status: active\n## Progress: 50\n" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    # Mock fzf availability (prevent interactive blocking)
    create_mock "_flow_has_fzf" "return 1"
    # Mock editor (prevent launching real editors)
    create_mock "_flow_open_editor" "return 0"
}

cleanup() {
    reset_mocks
    [[ -n "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}

# ============================================================================
# TESTS: Environment
# ============================================================================

test_flow_projects_root_defined() {
    test_case "FLOW_PROJECTS_ROOT is defined"
    assert_not_empty "$FLOW_PROJECTS_ROOT" "FLOW_PROJECTS_ROOT should be set" && test_pass
}

test_flow_projects_root_exists() {
    test_case "FLOW_PROJECTS_ROOT directory exists"
    assert_dir_exists "$FLOW_PROJECTS_ROOT" && test_pass
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_work_exists() {
    test_case "work command exists"
    assert_function_exists "work" && test_pass
}

test_finish_exists() {
    test_case "finish command exists"
    assert_function_exists "finish" && test_pass
}

test_hop_exists() {
    test_case "hop command exists"
    assert_function_exists "hop" && test_pass
}

test_why_exists() {
    test_case "why command exists"
    assert_function_exists "why" && test_pass
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_show_work_context_exists() {
    test_case "_flow_show_work_context function exists"
    assert_function_exists "_flow_show_work_context" && test_pass
}

test_open_editor_exists() {
    test_case "_flow_open_editor function exists"
    assert_function_exists "_flow_open_editor" && test_pass
}

test_session_start_exists() {
    test_case "_flow_session_start function exists"
    assert_function_exists "_flow_session_start" && test_pass
}

test_session_end_exists() {
    test_case "_flow_session_end function exists"
    assert_function_exists "_flow_session_end" && test_pass
}

# ============================================================================
# TESTS: Core utility functions
# ============================================================================

test_find_project_root_exists() {
    test_case "_flow_find_project_root function exists"
    assert_function_exists "_flow_find_project_root" && test_pass
}

test_get_project_exists() {
    test_case "_flow_get_project function exists"
    assert_function_exists "_flow_get_project" && test_pass
}

test_project_name_exists() {
    test_case "_flow_project_name function exists"
    assert_function_exists "_flow_project_name" && test_pass
}

test_pick_project_exists() {
    test_case "_flow_pick_project function exists"
    assert_function_exists "_flow_pick_project" && test_pass
}

test_detect_project_type_exists() {
    test_case "_flow_detect_project_type function exists"
    assert_function_exists "_flow_detect_project_type" && test_pass
}

test_project_icon_exists() {
    test_case "_flow_project_icon function exists"
    assert_function_exists "_flow_project_icon" && test_pass
}

# ============================================================================
# TESTS: work command behavior
# ============================================================================

test_work_no_args_shows_error() {
    test_case "work (no args, no fzf) exits with error"

    local output
    output=$(work 2>&1)
    local exit_code=$?

    # Without fzf and not in a project dir, should fail with exit 1
    assert_exit_code "$exit_code" 1 "work with no args and no fzf should exit 1" && test_pass
}

test_work_invalid_project() {
    test_case "work with invalid project shows 'not found' error"

    local output
    output=$(work nonexistent_project_xyz 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 1 "work with invalid project should exit 1" || return
    assert_contains "$output" "not found" "Should mention project not found" && test_pass
}

# ============================================================================
# TESTS: finish command behavior
# ============================================================================

test_finish_no_session_exits_cleanly() {
    test_case "finish when not in session exits cleanly"

    local output
    output=$(finish 2>&1)
    local exit_code=$?

    # finish outside a session should exit 0 (no-op) and not produce error output
    assert_exit_code "$exit_code" 0 "finish outside session should exit 0" || return
    assert_not_contains "$output" "command not found" "Should not show 'command not found'" && \
    assert_not_contains "$output" "syntax error" "Should not show syntax errors" && test_pass
}

# ============================================================================
# TESTS: hop command behavior
# ============================================================================

test_hop_no_args_shows_usage() {
    test_case "hop without args shows usage or exits with error"

    local output
    output=$(hop 2>&1)
    local exit_code=$?

    # Without fzf, hop should exit 1 (usage/error)
    assert_exit_code "$exit_code" 1 "hop with no args and no fzf should exit 1" && test_pass
}

# ============================================================================
# TESTS: why command behavior
# ============================================================================

test_why_exits_zero() {
    test_case "why command exits with code 0"

    local output
    output=$(why 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "why should exit 0" && test_pass
}

# ============================================================================
# TESTS: Context display
# ============================================================================

test_show_context_exits_zero() {
    test_case "_flow_show_work_context exits with code 0"

    local output
    output=$(_flow_show_work_context "test-project" "/tmp" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "_flow_show_work_context should exit 0" && test_pass
}

test_show_context_includes_project_name() {
    test_case "_flow_show_work_context includes project name in output"

    local output
    output=$(_flow_show_work_context "my-test-project" "/tmp" 2>&1)

    assert_contains "$output" "my-test-project" "Output should contain the project name" && test_pass
}

# ============================================================================
# TESTS: Project detection
# ============================================================================

test_find_project_root_in_git() {
    test_case "_flow_find_project_root finds git root in a real repo"

    # flow-cli itself is a git repo
    cd "$PROJECT_ROOT" 2>/dev/null
    local root
    root=$(_flow_find_project_root 2>/dev/null)

    assert_not_empty "$root" "Should return a project root path" || return
    assert_dir_exists "$root" "Returned root should be an existing directory" && test_pass
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

main() {
    test_suite_start "Work Command Tests"

    setup

    echo "${CYAN}--- Environment ---${RESET}"
    test_flow_projects_root_defined
    test_flow_projects_root_exists

    echo ""
    echo "${CYAN}--- Command existence ---${RESET}"
    test_work_exists
    test_finish_exists
    test_hop_exists
    test_why_exists

    echo ""
    echo "${CYAN}--- Helper functions ---${RESET}"
    test_show_work_context_exists
    test_open_editor_exists
    test_session_start_exists
    test_session_end_exists

    echo ""
    echo "${CYAN}--- Core utility functions ---${RESET}"
    test_find_project_root_exists
    test_get_project_exists
    test_project_name_exists
    test_pick_project_exists
    test_detect_project_type_exists
    test_project_icon_exists

    echo ""
    echo "${CYAN}--- work command behavior ---${RESET}"
    test_work_no_args_shows_error
    test_work_invalid_project

    echo ""
    echo "${CYAN}--- finish command ---${RESET}"
    test_finish_no_session_exits_cleanly

    echo ""
    echo "${CYAN}--- hop command ---${RESET}"
    test_hop_no_args_shows_usage

    echo ""
    echo "${CYAN}--- why command ---${RESET}"
    test_why_exits_zero

    echo ""
    echo "${CYAN}--- Context display ---${RESET}"
    test_show_context_exits_zero
    test_show_context_includes_project_name

    echo ""
    echo "${CYAN}--- Project detection ---${RESET}"
    test_find_project_root_in_git

    # Cleanup
    cleanup

    # Summary (from framework)
    test_suite_end
    exit $?
}

main "$@"
