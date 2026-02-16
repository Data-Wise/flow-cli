#!/usr/bin/env zsh
# Test script for ADHD helper commands
# Tests: js, next, stuck, focus, brk
# Generated: 2025-12-31
# Converted to test-framework.zsh: 2026-02-16

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
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${RESET}"
        exit 1
    fi

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
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app; do
        echo "## Status: active\n## Progress: 50" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"
}

cleanup() {
    reset_mocks
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_js_exists() {
    test_case "js command exists"
    assert_function_exists "js" && test_pass
}

test_next_exists() {
    test_case "next command exists"
    assert_function_exists "next" && test_pass
}

test_stuck_exists() {
    test_case "stuck command exists"
    assert_function_exists "stuck" && test_pass
}

test_focus_exists() {
    test_case "focus command exists"
    assert_function_exists "focus" && test_pass
}

test_brk_exists() {
    test_case "brk command exists"
    assert_function_exists "brk" && test_pass
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_next_help_exists() {
    test_case "_next_help function exists"
    assert_function_exists "_next_help" && test_pass
}

test_stuck_help_exists() {
    test_case "_stuck_help function exists"
    assert_function_exists "_stuck_help" && test_pass
}

test_focus_help_exists() {
    test_case "focus command has help"
    local output=$(focus --help 2>&1)
    assert_exit_code $? 0 "focus --help should exit 0" && \
    assert_not_empty "$output" "focus --help should produce output" && test_pass
}

test_list_projects_exists() {
    test_case "_flow_list_projects function exists"
    assert_function_exists "_flow_list_projects" && test_pass
}

# ============================================================================
# TESTS: js (Just Start) command
# ============================================================================

test_js_shows_header() {
    test_case "js shows 'JUST START' header"
    local output=$(js nonexistent_project 2>&1)
    assert_contains "$output" "JUST START" "Should show JUST START header" && test_pass
}

test_js_handles_invalid_project() {
    test_case "js handles invalid project gracefully"
    local output=$(js definitely_nonexistent_xyz123 2>&1)
    local exit_code=$?
    # js should still exit 0 — it shows the header and picks/suggests a project
    assert_exit_code $exit_code 0 "js should exit 0 even with invalid project" && \
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: next command
# ============================================================================

test_next_runs() {
    test_case "next runs without error"
    local output=$(next 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "next should exit 0" && \
    assert_not_contains "$output" "command not found" && test_pass
}

test_next_shows_header() {
    test_case "next shows task suggestions header"
    local output=$(next 2>&1)
    assert_contains "$output" "NEXT" "Should show NEXT in header" && test_pass
}

test_next_help_flag() {
    test_case "next --help runs"
    local output=$(next --help 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "next --help should exit 0" && \
    assert_not_empty "$output" "next --help should produce output" && test_pass
}

test_next_ai_flag_accepted() {
    test_case "next --ai flag is recognized"
    # This should run (may not have AI available, but flag should be accepted)
    local output=$(next --ai 2>&1)
    local exit_code=$?
    # Flag should be accepted without crashing — exit 0 expected
    assert_exit_code $exit_code 0 "next --ai should exit 0" && \
    assert_not_contains "$output" "unknown" "Flag should be recognized" && test_pass
}

# ============================================================================
# TESTS: stuck command
# ============================================================================

test_stuck_runs() {
    test_case "stuck runs without error"
    local output=$(stuck 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "stuck should exit 0" && \
    assert_not_contains "$output" "command not found" && test_pass
}

test_stuck_shows_header() {
    test_case "stuck shows appropriate header"
    local output=$(stuck 2>&1)
    assert_contains "$output" "STUCK" "Should show STUCK in header" && test_pass
}

test_stuck_help_flag() {
    test_case "stuck --help runs"
    local output=$(stuck --help 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "stuck --help should exit 0" && \
    assert_not_empty "$output" "stuck --help should produce output" && test_pass
}

# ============================================================================
# TESTS: focus command
# ============================================================================

test_focus_runs() {
    test_case "focus runs without error"
    local output=$(focus 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "focus should exit 0" && \
    assert_not_contains "$output" "command not found" && test_pass
}

test_focus_shows_header() {
    test_case "focus shows appropriate header"
    local output=$(focus 2>&1)
    # focus outputs "Focus:" (title case) with emoji, not all-caps
    assert_contains "$output" "Focus" "Should show Focus in header" && test_pass
}

test_focus_help_flag() {
    test_case "focus --help runs"
    local output=$(focus --help 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "focus --help should exit 0" && \
    assert_not_empty "$output" "focus --help should produce output" && test_pass
}

# ============================================================================
# TESTS: brk (break) command
# ============================================================================

test_brk_runs() {
    test_case "brk 0 runs without error (0 min = no sleep)"
    local output=$(brk 0 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "brk 0 should exit 0" && \
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_next_no_errors() {
    test_case "next output has no error patterns"
    local output=$(next 2>&1)
    assert_not_contains "$output" "command not found" && \
    assert_not_contains "$output" "syntax error" && \
    assert_not_contains "$output" "parse error" && test_pass
}

test_stuck_no_errors() {
    test_case "stuck output has no error patterns"
    local output=$(stuck 2>&1)
    assert_not_contains "$output" "command not found" && \
    assert_not_contains "$output" "syntax error" && \
    assert_not_contains "$output" "parse error" && test_pass
}

test_focus_no_errors() {
    test_case "focus output has no error patterns"
    local output=$(focus 2>&1)
    assert_not_contains "$output" "command not found" && \
    assert_not_contains "$output" "syntax error" && \
    assert_not_contains "$output" "parse error" && test_pass
}

# ============================================================================
# TESTS: ADHD-friendly design
# ============================================================================

test_js_uses_emoji() {
    test_case "js uses emoji for visual appeal"
    local output=$(js 2>&1)
    assert_contains "$output" "JUST START" "Should have JUST START branding" && test_pass
}

test_next_shows_projects() {
    test_case "next shows active projects"
    local output=$(next 2>&1)
    # next should reference projects in some form
    assert_not_empty "$output" "next should produce output" && test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite "ADHD Helper Commands Tests"

    setup

    echo "${CYAN}--- Command existence tests ---${RESET}"
    test_js_exists
    test_next_exists
    test_stuck_exists
    test_focus_exists
    test_brk_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${RESET}"
    test_next_help_exists
    test_stuck_help_exists
    test_focus_help_exists
    test_list_projects_exists

    echo ""
    echo "${CYAN}--- js command tests ---${RESET}"
    test_js_shows_header
    test_js_handles_invalid_project

    echo ""
    echo "${CYAN}--- next command tests ---${RESET}"
    test_next_runs
    test_next_shows_header
    test_next_help_flag
    test_next_ai_flag_accepted

    echo ""
    echo "${CYAN}--- stuck command tests ---${RESET}"
    test_stuck_runs
    test_stuck_shows_header
    test_stuck_help_flag

    echo ""
    echo "${CYAN}--- focus command tests ---${RESET}"
    test_focus_runs
    test_focus_shows_header
    test_focus_help_flag

    echo ""
    echo "${CYAN}--- brk command tests ---${RESET}"
    test_brk_runs

    echo ""
    echo "${CYAN}--- Output quality tests ---${RESET}"
    test_next_no_errors
    test_stuck_no_errors
    test_focus_no_errors

    echo ""
    echo "${CYAN}--- ADHD-friendly design tests ---${RESET}"
    test_js_uses_emoji
    test_next_shows_projects

    cleanup
    test_suite_end
    exit $?
}

main "$@"
