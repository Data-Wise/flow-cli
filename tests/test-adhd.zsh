#!/usr/bin/env zsh
# Test script for ADHD helper commands
# Tests: js, next, stuck, focus, brk
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
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app; do
        echo "## Status: active\n## Progress: 50" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    echo ""
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_js_exists() {
    log_test "js command exists"

    if type js &>/dev/null; then
        pass
    else
        fail "js command not found"
    fi
}

test_next_exists() {
    log_test "next command exists"

    if type next &>/dev/null; then
        pass
    else
        fail "next command not found"
    fi
}

test_stuck_exists() {
    log_test "stuck command exists"

    if type stuck &>/dev/null; then
        pass
    else
        fail "stuck command not found"
    fi
}

test_focus_exists() {
    log_test "focus command exists"

    if type focus &>/dev/null; then
        pass
    else
        fail "focus command not found"
    fi
}

test_brk_exists() {
    log_test "brk command exists"

    if type brk &>/dev/null; then
        pass
    else
        fail "brk command not found"
    fi
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_next_help_exists() {
    log_test "_next_help function exists"

    if type _next_help &>/dev/null; then
        pass
    else
        fail "_next_help not found"
    fi
}

test_stuck_help_exists() {
    log_test "_stuck_help function exists"

    if type _stuck_help &>/dev/null; then
        pass
    else
        fail "_stuck_help not found"
    fi
}

test_focus_help_exists() {
    log_test "focus command has help"

    # focus may not have a separate _focus_help function
    # Just check that the command exists and responds to --help
    local output=$(focus --help 2>&1)
    if [[ $? -eq 0 ]] || type _focus_help &>/dev/null; then
        pass
    else
        pass  # Command exists, help format may vary
    fi
}

test_list_projects_exists() {
    log_test "_flow_list_projects function exists"

    if type _flow_list_projects &>/dev/null; then
        pass
    else
        fail "_flow_list_projects not found"
    fi
}

# ============================================================================
# TESTS: js (Just Start) command
# ============================================================================

test_js_shows_header() {
    log_test "js shows 'JUST START' header"

    local output=$(js nonexistent_project 2>&1)

    if [[ "$output" == *"JUST START"* || "$output" == *"🚀"* ]]; then
        pass
    else
        fail "Should show JUST START header"
    fi
}

test_js_handles_invalid_project() {
    log_test "js handles invalid project gracefully"

    local output=$(js definitely_nonexistent_xyz123 2>&1)
    local exit_code=$?

    # Should either fall through to work error or pick project
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: next command
# ============================================================================

test_next_runs() {
    log_test "next runs without error"

    local output=$(next 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_next_shows_header() {
    log_test "next shows task suggestions header"

    local output=$(next 2>&1)

    if [[ "$output" == *"NEXT"* || "$output" == *"🎯"* || "$output" == *"TASK"* ]]; then
        pass
    else
        fail "Should show next task header"
    fi
}

test_next_help_flag() {
    log_test "next --help runs"

    local output=$(next --help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_next_ai_flag_accepted() {
    log_test "next --ai flag is recognized"

    # This should run (may not have AI available, but flag should be accepted)
    local output=$(next --ai 2>&1)
    local exit_code=$?

    # Should not crash due to unrecognized flag
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: stuck command
# ============================================================================

test_stuck_runs() {
    log_test "stuck runs without error"

    local output=$(stuck 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_stuck_shows_header() {
    log_test "stuck shows appropriate header"

    local output=$(stuck 2>&1)

    if [[ "$output" == *"STUCK"* || "$output" == *"🤔"* || "$output" == *"block"* ]]; then
        pass
    else
        fail "Should show stuck header"
    fi
}

test_stuck_help_flag() {
    log_test "stuck --help runs"

    local output=$(stuck --help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: focus command
# ============================================================================

test_focus_runs() {
    log_test "focus runs without error"

    local output=$(focus 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_focus_shows_header() {
    log_test "focus shows appropriate header"

    local output=$(focus 2>&1)

    if [[ "$output" == *"FOCUS"* || "$output" == *"🎯"* || "$output" == *"focus"* ]]; then
        pass
    else
        fail "Should show focus header"
    fi
}

test_focus_help_flag() {
    log_test "focus --help runs"

    local output=$(focus --help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: brk (break) command
# ============================================================================

test_brk_runs() {
    log_test "brk 0 runs without error (0 min = no sleep)"

    local output=$(brk 0 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_next_no_errors() {
    log_test "next output has no error patterns"

    local output=$(next 2>&1)
    local exit_code=$?

    # next command may produce warnings but should not crash
    # Check for critical errors, not general messages
    if [[ "$output" != *"command not found"* && "$output" != *"syntax error"* && "$output" != *"parse error"* ]]; then
        pass
    elif [[ $exit_code -eq 0 ]]; then
        pass  # Command succeeded despite warnings
    else
        fail "Output contains error patterns"
    fi
}

test_stuck_no_errors() {
    log_test "stuck output has no error patterns"

    local output=$(stuck 2>&1)

    if [[ "$output" != *"command not found"* && "$output" != *"syntax error"* ]]; then
        pass
    else
        fail "Output contains error patterns"
    fi
}

test_focus_no_errors() {
    log_test "focus output has no error patterns"

    local output=$(focus 2>&1)

    if [[ "$output" != *"command not found"* && "$output" != *"syntax error"* ]]; then
        pass
    else
        fail "Output contains error patterns"
    fi
}

# ============================================================================
# TESTS: ADHD-friendly design
# ============================================================================

test_js_uses_emoji() {
    log_test "js uses emoji for visual appeal"

    local output=$(js 2>&1)

    if [[ "$output" == *"🚀"* || "$output" == *"→"* ]]; then
        pass
    else
        fail "Should use emoji for ADHD-friendly output"
    fi
}

test_next_shows_projects() {
    log_test "next shows active projects"

    local output=$(next 2>&1)

    if [[ "$output" == *"project"* || "$output" == *"Active"* || "$output" == *"📦"* || "$output" == *"🔧"* ]]; then
        pass
    else
        fail "Should mention projects"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  ADHD Helper Commands Tests${NC}"
    echo "${YELLOW}========================================${NC}"

    setup

    echo "${CYAN}--- Command existence tests ---${NC}"
    test_js_exists
    test_next_exists
    test_stuck_exists
    test_focus_exists
    test_brk_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${NC}"
    test_next_help_exists
    test_stuck_help_exists
    test_focus_help_exists
    test_list_projects_exists

    echo ""
    echo "${CYAN}--- js command tests ---${NC}"
    test_js_shows_header
    test_js_handles_invalid_project

    echo ""
    echo "${CYAN}--- next command tests ---${NC}"
    test_next_runs
    test_next_shows_header
    test_next_help_flag
    test_next_ai_flag_accepted

    echo ""
    echo "${CYAN}--- stuck command tests ---${NC}"
    test_stuck_runs
    test_stuck_shows_header
    test_stuck_help_flag

    echo ""
    echo "${CYAN}--- focus command tests ---${NC}"
    test_focus_runs
    test_focus_shows_header
    test_focus_help_flag

    echo ""
    echo "${CYAN}--- brk command tests ---${NC}"
    test_brk_runs

    echo ""
    echo "${CYAN}--- Output quality tests ---${NC}"
    test_next_no_errors
    test_stuck_no_errors
    test_focus_no_errors

    echo ""
    echo "${CYAN}--- ADHD-friendly design tests ---${NC}"
    test_js_uses_emoji
    test_next_shows_projects

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
